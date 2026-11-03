extends Node3D

# Low-poly seated passengers plus a complete, visible alighting/boarding flow.
# Passengers are cosmetic: they walk from their seat to the open platform-side
# door, disappear onto the platform, and new passengers walk in and sit down.
# The simulation stays behind Train.physics, so this never affects the driving
# model or the player's walking collision.

const SEAT_X := [-1.18, -0.72, 0.72, 1.18]
const SEAT_ROWS := 9
const SEAT_STEP := 2.2

var _train: Train
var _vehicle: Vehicle
var _floor := 1.2
var _half_len := 12.0
var _seat_nodes: Array = []
var _occupied: Array = []
var _walkers: Array = []
var _pool: Array = []
var _cycle_active := false
var _cycle_done := false
var _spawn_timer := 0.0
var _pending: Array = []
var _door_side := 0
var _speed := 1.15
var _body_seated: BoxMesh
var _body_standing: BoxMesh
var _head_mesh: SphereMesh
var _shoulder_mesh: BoxMesh
var _coat_mats: Array = []
var _skin_mats: Array = []
var _next_pax := 0


static func attach(v: Vehicle) -> Node3D:
	if v == null or v.kind != "coach":
		return null
	var p = load("res://src/train/passenger_flow.gd").new()
	p.name = "PassengerFlow"
	v.add_child(p)
	p._setup(v)
	return p


func _setup(v: Vehicle) -> void:
	_vehicle = v
	_floor = float(v.get_meta("train_walk_floor", 1.2))
	_half_len = v.length * 0.5
	_train = v.get_parent() as Train
	_body_seated = BoxMesh.new()
	_body_seated.size = Vector3(0.42, 0.56, 0.28)
	_body_standing = BoxMesh.new()
	_body_standing.size = Vector3(0.42, 1.20, 0.28)
	_head_mesh = SphereMesh.new()
	_head_mesh.radius = 0.105
	_head_mesh.height = 0.21
	_head_mesh.radial_segments = 8
	_head_mesh.rings = 5
	_shoulder_mesh = BoxMesh.new()
	_shoulder_mesh.size = Vector3(0.34, 0.12, 0.24)
	for c: Color in [
		Color(0.10, 0.16, 0.26), Color(0.36, 0.15, 0.13), Color(0.22, 0.24, 0.22),
		Color(0.46, 0.38, 0.25), Color(0.17, 0.20, 0.25), Color(0.55, 0.30, 0.22),
	]:
		_coat_mats.append(Gfx.paint(c, 0.55, 0.06, 0.12))
	for c: Color in [
		Color(0.82, 0.66, 0.51), Color(0.68, 0.51, 0.38), Color(0.54, 0.39, 0.29),
	]:
		_skin_mats.append(Gfx.paint(c, 0.62, 0.02, 0.12))
	var low := Config.quality <= Config.Quality.LOW
	var fill := 0.44 if low else 0.64
	_occupied.resize(SEAT_ROWS * 4)
	_seat_nodes.resize(SEAT_ROWS * 4)
	for seat in range(SEAT_ROWS * 4):
		_occupied[seat] = false
		_seat_nodes[seat] = null
		var node := _new_passenger(seat % _coat_mats.size(), seat % _skin_mats.size())
		var p := _seat_pos(seat)
		node.position = p
		node.visible = false
		_seat_nodes[seat] = node
		if float((seat * 37) % 100) / 100.0 < fill:
			_seat_it(seat, node)
func _new_passenger(coat_i: int, skin_i: int) -> Node3D:
	var node := Node3D.new()
	node.name = "Passenger%03d" %_next_pax
	_next_pax += 1
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = _body_seated
	body.material_override = _coat_mats[coat_i % _coat_mats.size()]
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(body)
	var shoulders := MeshInstance3D.new()
	shoulders.name = "Shoulders"
	shoulders.mesh = _shoulder_mesh
	shoulders.material_override = _coat_mats[coat_i % _coat_mats.size()]
	shoulders.position = Vector3(0, 1.28, 0)
	shoulders.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(shoulders)
	var head := MeshInstance3D.new()
	head.name = "Head"
	head.mesh = _head_mesh
	head.material_override = _skin_mats[skin_i % _skin_mats.size()]
	head.position = Vector3(0, 1.22, 0)
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(head)
	add_child(node)
	return node


func _seat_pos(seat: int) -> Vector3:
	var row := seat / 4
	var col := seat % 4
	return Vector3(SEAT_X[col], _floor + 0.06, -8.8 + float(row) * SEAT_STEP)


func _seat_it(seat: int, node: Node3D) -> void:
	var body := node.get_node("Body") as MeshInstance3D
	var shoulders := node.get_node("Shoulders") as MeshInstance3D
	var head := node.get_node("Head") as MeshInstance3D
	body.mesh = _body_seated
	body.position = Vector3(0, 1.04, 0)
	shoulders.position = Vector3(0, 1.30, 0)
	head.position = Vector3(0, 1.45, 0)
	node.position = _seat_pos(seat)
	node.rotation.y = 0.0
	node.visible = true
	_occupied[seat] = true


func _stand(node: Node3D) -> void:
	var body := node.get_node("Body") as MeshInstance3D
	var shoulders := node.get_node("Shoulders") as MeshInstance3D
	var head := node.get_node("Head") as MeshInstance3D
	body.mesh = _body_standing
	body.position = Vector3(0, 0.68, 0)
	shoulders.position = Vector3(0, 1.28, 0)
	head.position = Vector3(0, 1.47, 0)
	node.visible = true


func _door_z_for(seat: int) -> float:
	var z := -8.8 + float(seat / 4) * SEAT_STEP
	return (0.5 * _half_len - 2.3) * (1.0 if z >= 0.0 else -1.0)


func _alight_path(seat: int, side: int) -> Array:
	var p := _seat_pos(seat)
	var z := p.z
	var dz := _door_z_for(seat)
	var x := signf(p.x) * 0.52
	return [
		Vector3(p.x, p.y, z),
		Vector3(x, p.y, z),
		Vector3(0.0, p.y, z),
		Vector3(0.0, p.y, dz),
		Vector3(side * 1.18, p.y, dz),
		Vector3(side * 1.72, p.y, dz),
	]


func _board_path(seat: int, side: int) -> Array:
	var p := _seat_pos(seat)
	var dz := _door_z_for(seat)
	var x := signf(p.x) * 0.52
	return [
		Vector3(side * 1.72, p.y, dz),
		Vector3(side * 1.18, p.y, dz),
		Vector3(0.0, p.y, dz),
		Vector3(0.0, p.y, p.z),
		Vector3(x, p.y, p.z),
		Vector3(p.x, p.y, p.z),
	]


func _begin_cycle() -> void:
	if _train == null:
		return
	if not _train.doors_open or _train.door_open_side == 0 or absf(_train.speed) > 0.4:
		return
	_cycle_active = true
	_cycle_done = false
	_pending.clear()
	_door_side = _train.door_open_side
	var alight_count := 2 if Config.quality <= Config.Quality.LOW else 4
	var board_count := alight_count
	var candidates: Array = []
	var vacant: Array = []
	for seat in range(SEAT_ROWS * 4):
		if _occupied[seat]:
			candidates.append(seat)
		else:
			vacant.append(seat)
	candidates.shuffle()
	vacant.shuffle()
	for i in range(mini(alight_count, candidates.size())):
		_pending.append({"kind": "alight", "seat": int(candidates[i])})
	for i in range(mini(board_count, vacant.size())):
		_pending.append({"kind": "board", "seat": int(vacant[i])})
	_spawn_timer = 0.35


func _spawn_pending() -> void:
	if _pending.is_empty():
		return
	var item: Dictionary = _pending.pop_front()
	var seat := int(item["seat"])
	if String(item["kind"]) == "alight":
		var node := _seat_nodes[seat] as Node3D
		if node == null or not _occupied[seat]:
			return
		_occupied[seat] = false
		_seat_nodes[seat] = null
		_stand(node)
		_walkers.append({"node": node, "path": _alight_path(seat, _door_side),
				"point": 1, "seat": seat, "kind": "alight", "speed": _speed})
	else:
		var node := _take_pooled()
		_stand(node)
		var path := _board_path(seat, _door_side)
		node.position = path[0]
		_walkers.append({"node": node, "path": path, "point": 1, "seat": seat,
				"kind": "board", "speed": _speed})


func _take_pooled() -> Node3D:
	if not _pool.is_empty():
		var n := _pool.pop_back() as Node3D
		n.visible = true
		return n
	return _new_passenger(randi() % _coat_mats.size(), randi() % _skin_mats.size())


func _finish_cycle_if_idle() -> void:
	if not _cycle_active:
		return
	if not _pending.is_empty() or not _walkers.is_empty():
		return
	_cycle_active = false
	_cycle_done = true


func _process(delta: float) -> void:
	if _train == null:
		return
	var doors_now := _train.doors_open and _train.door_open_side != 0 \
			and absf(_train.speed) < 0.4
	if not doors_now:
		_cycle_done = false
		if _cycle_active:
			for w: Dictionary in _walkers:
				var n := w["node"] as Node3D
				if n != null:
					n.visible = false
					_pool.append(n)
			_walkers.clear()
			_pending.clear()
			_cycle_active = false
		return
	if not _cycle_active and not _cycle_done:
		_begin_cycle()
	if not _cycle_active:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and not _pending.is_empty():
		_spawn_pending()
		_spawn_timer = 0.55
	for wi in range(_walkers.size() - 1, -1, -1):
		var w: Dictionary = _walkers[wi]
		var node := w["node"] as Node3D
		var path: Array = w["path"]
		var point := int(w["point"])
		if node == null or point >= path.size():
			_walkers.remove_at(wi)
			continue
		var target: Vector3 = path[point]
		var d := node.position.distance_to(target)
		var step := float(w["speed"]) * delta
		if d <= step:
			node.position = target
			w["point"] = point + 1
			if int(w["point"]) >= path.size():
				if String(w["kind"]) == "board":
					var seat := int(w["seat"])
					_seat_nodes[seat] = node
					_seat_it(seat, node)
				else:
					node.visible = false
					_pool.append(node)
				_walkers.remove_at(wi)
		else:
			var dir := (target - node.position).normalized()
			node.position += dir * step
			node.rotation.y = atan2(dir.x, dir.z)
	_finish_cycle_if_idle()
