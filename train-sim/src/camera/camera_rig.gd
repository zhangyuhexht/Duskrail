extends Node3D
class_name CameraRig



enum Mode {CAB, CHASE, FREE, TOWER, WALK}

var mode: Mode = Mode.CHASE
var train: Train
var route: Route
var camera: Camera3D
var terrain: Terrain

const WALK_EYE := 1.7
var _walk_pos := Vector3.ZERO
var _walk_vel := Vector3.ZERO
var _bob := 0.0
var _bob_phase := 0.0
var _jump_vel := 0.0
var _grounded := true
var _cab_walk := false
var _on_foot := false
var _cab_seat := 0
var _train_walk := false
var _walk_vehicle := -1
var _last_walk_xf := Transform3D()
var _last_walk_vehicle := -2
var _last_walk_valid := false

var stations: Array = []

var _chase_pos := Vector3.ZERO
var _chase_look := Vector3.ZERO
var _free_speed := 30.0
var _mouse_look := false
var _look_yaw := 0.0
var _look_pitch := -0.25
var _cab_look_yaw := 0.0
var _cab_look_pitch := 0.0
var _cab_bob := 0.0
var _cab_hidden: Array = []
var _tower_index := 0


var _dragging := false
var _returning := false
var _orbit_yaw := 0.0
var _orbit_pitch := 0.0
var _zoom := 1.0
var _cab_zooming := false
var _cab_zoom := 0.0

const ORBIT_SENS := 0.0042
const PITCH_MIN := -0.3
const PITCH_MAX := 1.18

func setup(p_train: Train, p_route: Route) -> void:
	train = p_train
	route = p_route
	camera = Camera3D.new()
	camera.name = "MainCamera"
	camera.fov = clampf(UserSettings.fov, 45.0, 100.0)
	camera.near = 0.12
	camera.far = 52000.0
	camera.current = true
	# The rig is driven per rendered frame in _process; interpolating the camera
	# itself would add a one-tick lag and reintroduce view shake.
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(camera)
	_chase_pos = _desired_chase()
	_chase_look = _chase_pivot()

func set_mode(m: Mode, from_cab := false) -> void:
	var prev := mode
	if prev == Mode.CAB and m != Mode.CAB:
		_restore_cab_visibility()
	mode = m
	if m != Mode.WALK:
		_cab_walk = false
	if m != Mode.CAB:
		_on_foot = false
		_train_walk = false
		_walk_vehicle = -1
	elif prev != Mode.CAB:
		_cab_seat = 0
	camera.far = 14000.0 if m == Mode.CAB else 52000.0
	camera.cull_mask = (camera.cull_mask & ~(1 << 1)) if m == Mode.CAB else 0xFFFFF
	_orbit_yaw = 0.0
	_orbit_pitch = 0.0
	_returning = false
	_dragging = false
	_cab_zooming = false
	_cab_zoom = 0.0
	if m != Mode.CAB and camera != null:
		camera.fov = clampf(UserSettings.fov, 45.0, 100.0)
	if m == Mode.FREE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_apply_free_transform()
	elif m == Mode.CAB:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_apply_cab_visibility()
	elif m == Mode.WALK:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if prev != Mode.WALK:
			if from_cab:
				spawn_in_cab()
			else:
				spawn_on_foot()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func cycle_mode() -> void:
	if mode == Mode.WALK or _on_foot:
		return
	# The player-facing camera has exactly two views: chase and cab. Tower,
	# free and on-foot modes remain internal QA/debug helpers only.
	var order := [Mode.CHASE, Mode.CAB]
	var i := order.find(mode)
	if i < 0:
		set_mode(Mode.CHASE)
		return
	set_mode(order [(i + 1) % order.size()])


func set_orbit(yaw: float, pitch: float, zoom: float) -> void:
	_orbit_yaw = yaw
	_orbit_pitch = clampf(pitch, PITCH_MIN, PITCH_MAX)
	_zoom = clampf(zoom, 0.20, 3.2)
	_returning = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed and(mode == Mode.CHASE or mode == Mode.TOWER):
				_dragging = true
				_returning = false
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			elif not mb.pressed and _dragging:
				_dragging = false

				if mode != Mode.FREE:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif mb.button_index == MOUSE_BUTTON_MIDDLE and mode == Mode.CAB:
			_cab_zooming = mb.pressed
			get_viewport().set_input_as_handled()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clampf(_zoom * 0.88, 0.20, 3.2)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clampf(_zoom * 1.14, 0.20, 3.2)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var sens := UserSettings.mouse_sensitivity
		var pitch_sign := -1.0 if UserSettings.invert_look_y else 1.0
		if _dragging and(mode == Mode.CHASE or mode == Mode.TOWER):
			_orbit_yaw -= mm.relative.x * ORBIT_SENS * sens
			_orbit_pitch = clampf(_orbit_pitch + mm.relative.y * ORBIT_SENS * sens * pitch_sign, PITCH_MIN, PITCH_MAX)
		elif mode == Mode.FREE:
			_look_yaw -= mm.relative.x * 0.0025 * sens
			_look_pitch = clampf(_look_pitch + mm.relative.y * 0.0025 * sens * pitch_sign, -1.45, 1.45)
		elif mode == Mode.CAB and _on_foot:
			_look_yaw -= mm.relative.x * 0.0025 * sens
			_look_pitch = clampf(_look_pitch + mm.relative.y * 0.0025 * sens * pitch_sign, -1.35, 1.35)
		elif mode == Mode.CAB:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				_cab_look_yaw = clampf(_cab_look_yaw - mm.relative.x * 0.002 * sens, -1.2, 1.2)
				_cab_look_pitch = clampf(_cab_look_pitch - mm.relative.y * 0.002 * sens * pitch_sign, -0.6, 0.6)
		elif mode == Mode.WALK:
			_look_yaw -= mm.relative.x * 0.0025 * sens
			_look_pitch = clampf(_look_pitch + mm.relative.y * 0.0025 * sens * pitch_sign, -1.35, 1.35)

func _process(delta: float) -> void:
	if train == null:
		return

	if _dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_dragging = false
		if mode != Mode.FREE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if not _dragging and Input.is_action_just_pressed("camera_reset"):
		if mode == Mode.CAB:
			_cab_look_yaw = 0.0
			_cab_look_pitch = 0.0
		else:
			_returning = true
	if _returning and not _dragging:
		var t := clampf(delta * 4.5, 0.0, 1.0)
		_orbit_yaw = lerpf(_orbit_yaw, 0.0, t)
		_orbit_pitch = lerpf(_orbit_pitch, 0.0, t)
		_zoom = lerpf(_zoom, 1.0, t)
		if absf(_orbit_yaw) < 0.002 and absf(_orbit_pitch) < 0.002 and absf(_zoom - 1.0) < 0.002:
			_orbit_yaw = 0.0
			_orbit_pitch = 0.0
			_zoom = 1.0
			_returning = false
	match mode:
		Mode.CAB:
			if _on_foot:
				_update_walk(delta)
			else:
				_update_cab(delta)
		Mode.CHASE:
			_update_chase(delta)
		Mode.FREE:
			_update_free(delta)
		Mode.WALK:
			_update_walk(delta)
		Mode.TOWER:
			_update_tower(delta)

func _cab_keep(nm: String) -> bool:
	if nm.begins_with("Dev") or nm.begins_with("Cab"):
		return true
	for p in ["Steam", "Backhead", "Firebox"]:
		if nm.begins_with(p):
			return true
	return false


func _apply_cab_visibility() -> void:
	_restore_cab_visibility()
	if train == null:
		return
	var cv: Vehicle = null
	for v in train.vehicles:
		if v.cab_anchor != Vector3.ZERO:
			cv = v
			break
	if cv == null:
		cv = train.vehicles[0] if not train.vehicles.is_empty() else null
	for v in train.vehicles:
		for node in v.body_root().get_children():
			if node is MeshInstance3D:
				_cab_hidden.append([node, node.visible])
				node.visible = v == cv and _cab_keep(String(node.name))


func _restore_cab_visibility() -> void:
	for item in _cab_hidden:
		if item[0] != null and is_instance_valid(item[0]):
			item[0].visible = bool(item[1])
	_cab_hidden.clear()

func _update_cab(delta: float) -> void:
	var base := train.cab_position_interpolated()
	if _cab_seat == 1:
		var cv := _cab_vehicle()
		if cv != null:
			var meta := _cab_walk_meta(cv)
			base = cv.get_global_transform_interpolated() * Vector3(
					float(meta["seat_x2"]), float(meta["floor"]) + 1.7, float(meta["seat_z"]))
	var fr := route.frame_at(train.visual_distance() - 6.0)
	var look := fr.basis.z * -1.0
	if train.reverser < 0:
		look = - look
	var right := fr.basis.x if train.reverser >= 0 else - fr.basis.x
	var dir: Vector3 = Basis(Vector3.UP, _cab_look_yaw) * Basis(right, _cab_look_pitch) * look
	_cab_bob += delta * (0.9 + absf(train.speed) * 0.075)
	var amp := clampf(absf(train.speed) / 24.0, 0.0, 1.0) * 0.011
	base += right * sin(_cab_bob) * amp + Vector3.UP * sin(_cab_bob * 2.0) * amp * 0.55
	camera.global_position = base

	# Smooth interior zoom, ETS2 style: hold MMB to pull the FOV in, release
	# to ease back. The 0.18 s ramp keeps it from snapping between frames.
	if _cab_zooming and not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		_cab_zooming = false
	_cab_zoom = move_toward(_cab_zoom, 1.0 if _cab_zooming else 0.0, delta / 0.18)
	var base_fov := clampf(UserSettings.fov, 45.0, 100.0)
	var zoom_fov := maxf(24.0, base_fov * 0.50)
	camera.fov = lerpf(base_fov, zoom_fov, smoothstep(0.0, 1.0, _cab_zoom))

	camera.look_at(camera.global_position + dir * 60.0 - Vector3.UP * 3.0)

func _chase_pivot() -> Vector3:
	# Frame the middle of the leading locomotive, not the nose/coupler.
	if train != null and not train.vehicles.is_empty():
		var lead: Vehicle = train.vehicles[0]
		if lead != null and is_instance_valid(lead):
			if lead.is_inside_tree():
				return lead.get_global_transform_interpolated().origin + Vector3.UP * 2.1
			return lead.global_transform.origin + Vector3.UP * 2.1
	return train.head_position_visual() + Vector3.UP * 2.1


func _update_chase(_delta: float) -> void:
	# The chase camera is rigidly attached to the same interpolated vehicle
	# transform as the rendered train. Mixing a route-interpolated target with
	# a smoothed vehicle target produced relative one-frame jitter.
	_chase_pos = _desired_chase()
	camera.global_position = _chase_pos
	_chase_look = _chase_pivot()
	camera.look_at(_chase_look)

func _desired_chase() -> Vector3:
	var pivot := _chase_pivot()
	if train != null and not train.vehicles.is_empty():
		var lead: Vehicle = train.vehicles[0]
		if lead != null and is_instance_valid(lead) and lead.is_inside_tree():
			var xf := lead.get_global_transform_interpolated()
			var off := xf.basis.z * 22.0 + xf.basis.x * 11.0 + Vector3.UP * 7.0
			return pivot + _orbit_dir(off) *(off.length() * _zoom)
	var lead_len := 20.0
	if train != null and not train.vehicles.is_empty():
		lead_len = train.vehicles[0].length
	var fr := route.frame_at(train.visual_distance() - lead_len * 0.5)
	var off := fr.basis.z * 22.0 + fr.basis.x * 11.0 + Vector3.UP * 7.0
	return pivot + _orbit_dir(off) *(off.length() * _zoom)


func _orbit_dir(off: Vector3) -> Vector3:
	var dir := off.normalized()
	if absf(_orbit_yaw) > 0.0001:
		dir = Basis(Vector3.UP, _orbit_yaw) * dir
	if absf(_orbit_pitch) > 0.0001:
		var right := dir.cross(Vector3.UP)
		if right.length_squared() < 0.0001:
			right = Vector3.RIGHT
		dir = Basis(right.normalized(), _orbit_pitch) * dir
	return dir

func _update_free(delta: float) -> void:
	var basis := Basis(Vector3.UP, _look_yaw) * Basis(Vector3.RIGHT, _look_pitch)
	var dir := basis.z
	var move := Vector3.ZERO
	var right := - basis.x
	if Input.is_action_pressed("gear_up"):
		move += dir
	if Input.is_action_pressed("gear_down"):
		move -= dir
	if Input.is_action_pressed("doors_toggle"):
		move -= right
	if Input.is_action_pressed("lights_toggle"):
		move += right
	var mult := 1.0
	if Input.is_key_pressed(KEY_SHIFT):
		mult = 4.0
	camera.global_position += move * _free_speed * mult * delta
	var target := camera.global_position + dir * 10.0
	camera.look_at(target)

func _apply_free_transform() -> void:
	var fr := route.frame_at(train.distance)
	camera.global_position = train.head_position() + Vector3.UP * 12.0 + fr.basis.x * 25.0
	_look_yaw = atan2(- fr.basis.z.x, - fr.basis.z.z) + PI
	_look_pitch = -0.25

func set_tower_index(i: int) -> void:
	_tower_index = i

func _update_tower(_delta: float) -> void:

	var offsets := [420.0, -180.0, 900.0]
	var off: float = offsets [_tower_index %offsets.size()]
	var d := train.visual_distance() + off
	var fr := route.frame_at(d)
	var pivot := train.head_position_visual() + Vector3.UP * 1.8
	var base := route.position_at(d) + fr.basis.x * -9.0 + Vector3.UP * 5.0
	if absf(_orbit_yaw) > 0.0001 or absf(_orbit_pitch) > 0.0001 or absf(_zoom - 1.0) > 0.0001:
		var dir := _orbit_dir(base - pivot)
		camera.global_position = pivot + dir * maxf((base - pivot).length() * _zoom, 10.0)
	else:
		camera.global_position = base
	camera.look_at(pivot)


func set_terrain(t: Terrain) -> void:
	terrain = t

func apply_user_settings() -> void:
	if camera != null and is_instance_valid(camera):
		camera.fov = clampf(UserSettings.fov, 45.0, 100.0)


func _ground_at(x: float, z: float) -> float:
	if terrain != null:
		return terrain.height_at(x, z)
	return 0.0


func _in_structure_span(d: float, span: Vector2) -> bool:
	if route == null:
		return false
	var rel := route.wrap_dist(d - span.x)
	return rel <= route.wrap_dist(span.y - span.x)


func _structure_at_dist(d: float) -> Dictionary:
	if route == null:
		return {}
	var rp := route.position_at(d)
	for t: Dictionary in Config.TUNNELS:
		if _in_structure_span(d, Config.tunnel_span(route, t)):
			return {"y": rp.y - 0.85, "half": 3.0, "kind": "tunnel", "center": rp}
	for b: Dictionary in Config.BRIDGES:
		if _in_structure_span(d, Config.bridge_span(route, b)):
			return {"y": rp.y - 0.15, "half": 1.75, "kind": "bridge", "center": rp}
	for v: Dictionary in Config.VIADUCTS:
		if _in_structure_span(d, Config.viaduct_span(route, v)):
			return {"y": rp.y - 0.16, "half": 2.25, "kind": "viaduct", "center": rp}
	return {}


func _structure_at(p: Vector3) -> Dictionary:
	if route == null:
		return {}
	var d := route.nearest_dist(p)
	var rp := route.position_at(d)
	if Vector2(p.x - rp.x, p.z - rp.z).length() > 4.5:
		return {}
	return _structure_at_dist(d)


func _cab_vehicle() -> Vehicle:
	if train == null:
		return null
	return train._cab_vehicle()


func _cab_walk_meta(cv: Vehicle) -> Dictionary:
	var floor_y := float(cv.get_meta("walk_floor", cv.cab_anchor.y - 1.7))
	var front := float(cv.get_meta("walk_front", cv.cab_anchor.z - 2.6))
	var back := float(cv.get_meta("walk_back", cv.cab_anchor.z + 2.4))
	var half := float(cv.get_meta("walk_half", 1.36))
	var door_z := float(cv.get_meta("walk_door_z", back - 0.8))
	var door_half := float(cv.get_meta("walk_door_half", 0.46))
	var seat_x := float(cv.get_meta("walk_seat_x", cv.cab_anchor.x))
	var seat_z := float(cv.get_meta("walk_seat_z", cv.cab_anchor.z))
	var seat_x2 := float(cv.get_meta("walk_seat_x2", seat_x + 1.4))
	var desk_z := float(cv.get_meta("walk_desk_z", seat_z - 1.32))
	return {
		"floor": floor_y, "front": front, "back": back,
		"half": half, "door_z": door_z, "door_half": door_half,
		"seat_x": seat_x, "seat_z": seat_z, "seat_x2": seat_x2,
		"desk_z": desk_z,
	}


func spawn_in_cab() -> void:
	if train == null or route == null:
		return
	var cv := _cab_vehicle()
	if cv == null:
		spawn_on_foot()
		return
	var meta := _cab_walk_meta(cv)
	var xf := cv.global_transform
	var floor_y := float(meta["floor"])
	_walk_pos = xf * Vector3(-0.12, floor_y + 0.01, float(meta["seat_z"]) + 0.95)
	_walk_vel = Vector3.ZERO
	_jump_vel = 0.0
	_grounded = true
	_cab_walk = true
	_last_walk_valid = false
	look_toward(xf * Vector3(0.0, floor_y + 1.45, float(meta["front"]) + 0.9))


func enter_cab_walk() -> bool:
	if mode != Mode.CAB or train == null:
		return false
	var cv := _cab_vehicle()
	if cv == null:
		return false
	var meta := _cab_walk_meta(cv)
	var xf := cv.global_transform
	var floor_y := float(meta["floor"])
	var spawn_x := float(meta["seat_x2"]) if _cab_seat == 1 else -0.12
	_walk_pos = xf * Vector3(spawn_x, floor_y + 0.01, float(meta["seat_z"]) + 0.95)
	_walk_vel = Vector3.ZERO
	_jump_vel = 0.0
	_grounded = true
	_cab_walk = true
	_on_foot = true
	_train_walk = true
	_walk_vehicle = train.vehicles.find(cv)
	_last_walk_valid = false
	_restore_cab_visibility()
	camera.cull_mask = 0xFFFFF
	camera.far = 52000.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	look_toward(xf * Vector3(spawn_x, floor_y + 1.45, float(meta["front"]) + 0.9))
	return true


func sit_down(seat := 0) -> bool:
	if mode != Mode.CAB or train == null:
		return false
	_cab_walk = false
	_on_foot = false
	_train_walk = false
	_walk_vehicle = -1
	_last_walk_valid = false
	_cab_seat = clampi(seat, 0, 1)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	camera.cull_mask = camera.cull_mask & ~(1 << 1)
	camera.far = 14000.0
	_apply_cab_visibility()
	return true


func nearest_cab_seat() -> int:
	if mode != Mode.CAB or train == null:
		return -1
	var cv := _cab_vehicle()
	if cv == null:
		return -1
	if not _cab_walk:
		return 0 if can_board() else -1
	var use_v := cv
	if _train_walk:
		if _walk_vehicle < 0 or _walk_vehicle >= train.vehicles.size():
			return -1
		use_v = train.vehicles[_walk_vehicle]
		if use_v.kind != "loco":
			return -1
	var meta := _cab_walk_meta(use_v)
	var local := use_v.global_transform.affine_inverse() * _walk_pos
	var d0 := Vector2(local.x - float(meta["seat_x"]), local.z - float(meta["seat_z"])).length()
	var d1 := Vector2(local.x - float(meta["seat_x2"]), local.z - float(meta["seat_z"])).length()
	if minf(d0, d1) > 1.15:
		return -1
	return 0 if d0 <= d1 else 1


func _cab_walk_step() -> void:
	if not _cab_walk:
		return
	var cv := _cab_vehicle()
	if cv == null:
		_cab_walk = false
		return
	var meta := _cab_walk_meta(cv)
	var xf := cv.get_global_transform_interpolated()
	var local := xf.affine_inverse() * _walk_pos
	local.z = clampf(local.z, float(meta["front"]), float(meta["back"]))
	var half := float(meta["half"])
	var door_z := float(meta["door_z"])
	var door_half := float(meta["door_half"])
	var exit_side := 0
	if train != null and train.doors_open:
		exit_side = train.door_open_side
	var in_door := absf(local.z - door_z) <= door_half - 0.06
	var side := int(signf(local.x))
	if exit_side != 0 and side == exit_side and in_door and absf(local.x) > half - 0.02:
		# Walk through the open doorway; once clear of the wall the player
		# switches to the normal platform/ground surface.
		if absf(local.x) > half + 0.18:
			_cab_walk = false
			_walk_pos = xf * local
			_restore_cab_visibility()
			camera.cull_mask = 0xFFFFF
			camera.far = 52000.0
			return
	else:
		local.x = clampf(local.x, -half, half)
		local = _resolve_cab_obstacles(local, meta)
		local.x = clampf(local.x, -half, half)
		local.z = clampf(local.z, float(meta["front"]), float(meta["back"]))
	_walk_pos = xf * local


func _walk_gap_for(dir: int, xf: Transform3D, front: float, back: float) -> float:
	if train == null:
		return 0.0
	var ni := _walk_vehicle + dir
	if ni < 0 or ni >= train.vehicles.size():
		return 0.0
	var cur: Vehicle = train.vehicles[_walk_vehicle]
	var nv: Vehicle = train.vehicles[ni]
	if cur == null or nv == null or not nv.has_meta("train_walk"):
		return 0.0
	var door_owner: Vehicle = cur if dir > 0 else nv
	var door := door_owner.find_child("EndDoorRear", true, false) as Node3D
	if door != null and door.visible:
		return 0.0
	var nfloor := float(nv.get_meta("train_walk_floor", 1.2))
	var nz := float(nv.get_meta("train_walk_front", -nv.length * 0.5 + 0.1)) if dir > 0 \
			else float(nv.get_meta("train_walk_back", nv.length * 0.5 - 0.1))
	var target_world := nv.get_global_transform_interpolated() * Vector3(0.0, nfloor, nz)
	var target_local := xf.affine_inverse() * target_world
	var gap := (target_local.z - back) if dir > 0 else (front - target_local.z)
	if gap < 0.03 or gap > 3.5:
		return 0.0
	return gap


func _train_walk_step() -> void:
	if not _train_walk or train == null:
		return
	if _walk_vehicle < 0 or _walk_vehicle >= train.vehicles.size():
		_train_walk = false
		return
	var v: Vehicle = train.vehicles[_walk_vehicle]
	if v == null or not v.has_meta("train_walk"):
		_train_walk = false
		return
	var xf := v.get_global_transform_interpolated()
	var local := xf.affine_inverse() * _walk_pos
	var floor_y := float(v.get_meta("train_walk_floor", 1.2))
	var front := float(v.get_meta("train_walk_front", -v.length * 0.5 + 0.1))
	var back := float(v.get_meta("train_walk_back", v.length * 0.5 - 0.1))
	var half := float(v.get_meta("train_walk_half", 1.2))
	var gap_next := _walk_gap_for(1, xf, front, back)
	var gap_prev := _walk_gap_for(-1, xf, front, back)
	local.y = floor_y
	if v.kind == "loco":
		var cz0 := float(v.get_meta("train_walk_corridor_z0", -3.65))
		var cz1 := float(v.get_meta("train_walk_corridor_z1", 6.85))
		var cx := float(v.get_meta("train_walk_corridor_x", 0.24))
		if local.z < cz0:
			local.x = clampf(local.x, -1.12, 1.12)
			local = _resolve_cab_obstacles(local, _cab_walk_meta(v))
		elif local.z < cz1:
			local.x = clampf(local.x, cx, 1.32)
		else:
			local.x = clampf(local.x, -1.12, 1.32)
		# Funnel the player through the two narrow bulkhead doorways
		# instead of letting them clip through the partition edges.
		if absf(local.z - cz0) < 0.45:
			local.x = clampf(local.x, 0.36, 1.10)
		if absf(local.z - cz1) < 0.45:
			local.x = clampf(local.x, 0.36, 1.14)
		local.z = clampf(local.z, front - gap_prev, back + gap_next)
		if local.z > back:
			# In the rear doorway / bellows the passage narrows to the
			# doorway width.
			local.x = clampf(local.x, -0.48, 0.48)
		if local.z < cz0 and train.doors_open:
			var meta := _cab_walk_meta(v)
			var door_z := float(meta["door_z"])
			if absf(local.z - door_z) <= 0.60 and absf(local.x) > 1.10:
				_train_walk = false
				_cab_walk = false
				_on_foot = true
				_walk_pos = xf * local
				_restore_cab_visibility()
				camera.cull_mask = 0xFFFFF
				camera.far = 52000.0
				return
	else:
		local.z = clampf(local.z, front - gap_prev, back + gap_next)
		var door_z := v.length * 0.5 - 2.3
		var side := train.door_open_side
		var near_door := train.doors_open and side != 0 \
				and absf(absf(local.z) - door_z) < 0.75
		if near_door:
			# The side doorway is only open on the platform side. Let the
			# player step out through it and fall onto the platform.
			if side > 0:
				local.x = clampf(local.x, -half, 1.62)
			else:
				local.x = clampf(local.x, -1.62, half)
			if signf(local.x) == float(side) and absf(local.x) > 1.52:
				_train_walk = false
				_cab_walk = false
				_on_foot = true
				_walk_vehicle = -1
				_walk_pos = xf * local
				_restore_cab_visibility()
				camera.cull_mask = 0xFFFFF
				camera.far = 52000.0
				return
		else:
			local.x = clampf(local.x, -half, half)
	if v.kind == "loco" and local.z > back - 0.35 and absf(local.x) > 0.52:
		# The rear cab doorway is only half a metre wide. Do not let the
		# player slide through the solid part of the rear wall.
		local.z = minf(local.z, back - 0.05)
	_walk_pos = xf * local
	if gap_next > 0.0 and local.z >= back + gap_next - 0.01:
		if _enter_adjacent_vehicle(1):
			return
		local.z = back
		_walk_pos = xf * local
	elif gap_prev > 0.0 and local.z <= front - gap_prev + 0.01:
		if _enter_adjacent_vehicle(-1):
			return
		local.z = front
		_walk_pos = xf * local


func _enter_adjacent_vehicle(dir: int) -> bool:
	var ni := _walk_vehicle + dir
	if ni < 0 or ni >= train.vehicles.size():
		return false
	var cur: Vehicle = train.vehicles[_walk_vehicle]
	# EndDoorRear belongs to the connection between this car and the next
	# one. Moving forward must therefore inspect the previous car's rear
	# door, not this car's always-open front doorway.
	var door_owner: Vehicle = cur if dir > 0 else train.vehicles[ni]
	var door := door_owner.find_child("EndDoorRear", true, false) as Node3D
	if door != null and door.visible:
		return false
	var nv: Vehicle = train.vehicles[ni]
	if nv == null or not nv.has_meta("train_walk"):
		return false
	var nxf := nv.get_global_transform_interpolated()
	var nlocal := nxf.affine_inverse() * _walk_pos
	var nfloor := float(nv.get_meta("train_walk_floor", 1.2))
	var nhalf := float(nv.get_meta("train_walk_half", 1.2))
	if dir > 0:
		nlocal.z = float(nv.get_meta("train_walk_front", -nv.length * 0.5 + 0.1))
	else:
		nlocal.z = float(nv.get_meta("train_walk_back", nv.length * 0.5 - 0.1))
	nlocal.y = nfloor
	nlocal.x = clampf(nlocal.x, -nhalf, nhalf)
	_walk_vehicle = ni
	_walk_pos = nxf * nlocal
	return true


func _push_local_box(local: Vector3, cx: float, cz: float,
		hx: float, hz: float, radius: float) -> Vector3:
	var dx := local.x - cx
	var dz := local.z - cz
	var px := hx + radius - absf(dx)
	var pz := hz + radius - absf(dz)
	if px <= 0.0 or pz <= 0.0:
		return local
	if px < pz:
		var sx := 1.0 if dx >= 0.0 else -1.0
		local.x = cx + (hx + radius) * sx
	else:
		var sz := 1.0 if dz >= 0.0 else -1.0
		local.z = cz + (hz + radius) * sz
	return local


func _resolve_cab_obstacles(local: Vector3, meta: Dictionary) -> Vector3:
	# Seats and the dashboard are solid while walking around the cab.
	var r := 0.24
	local = _push_local_box(local, float(meta["seat_x"]), float(meta["seat_z"]), 0.34, 0.50, r)
	local = _push_local_box(local, float(meta["seat_x2"]), float(meta["seat_z"]), 0.34, 0.50, r)
	local = _push_local_box(local, -0.2, float(meta["desk_z"]), 1.45, 0.55, r)
	return local


func _platform_at(p: Vector3) -> Dictionary:
	if route == null or stations.is_empty():
		return {}
	var d := route.nearest_dist(p)
	var fr := route.frame_at(d)
	var rel := p - fr.origin
	for st: Dictionary in stations:
		var half_len := float(st.get("platform_len", 220.0)) * 0.5
		if absf(route.wrap_dist(d - float(st.get("dist", 0.0)))) > half_len:
			continue
		var side := signf(float(st.get("side", 1.0)))
		var lat := rel.dot(fr.basis.x) * side
		var lat_c := float(st.get("platform_lat", 4.6))
		var half_w := float(st.get("platform_half", 2.9))
		if lat >= lat_c - half_w - 0.30 and lat <= lat_c + half_w + 0.30:
			return {
				"y": fr.origin.y + float(st.get("platform_top", 1.1)),
				"lat": lat, "edge": lat_c - half_w, "lat_c": lat_c,
				"side": side, "frame": fr, "dist": d, "station": st,
			}
		# Freight yards have a separate raised concrete apron. It is not a
		# station platform, but it needs a walkable top too.
		var yard_lat := float(st.get("yard_lat", 0.0))
		var yard_half := float(st.get("yard_half", 0.0))
		if yard_lat > 0.0 and yard_half > 0.0:
			var yard_len := float(st.get("yard_len", 100.0))
			if absf(route.wrap_dist(d - float(st.get("dist", 0.0)))) <= yard_len * 0.5:
				if lat >= yard_lat - yard_half - 0.30 and lat <= yard_lat + yard_half + 0.30:
					return {
						"y": fr.origin.y + float(st.get("yard_top", 0.26)),
						"lat": lat, "edge": yard_lat - yard_half, "lat_c": yard_lat,
						"side": side, "frame": fr, "dist": d, "station": st,
					}
	return {}


func _resolve_world_collisions(prev_xz: Vector2) -> void:
	_resolve_platform_face(prev_xz)
	_resolve_train_collision()


func _resolve_platform_face(prev_xz: Vector2) -> void:
	var platform := _platform_at(_walk_pos)
	if platform.is_empty():
		return
	var top := float(platform["y"])
	if _walk_pos.y >= top - 0.12:
		return
	# The platform side wall is solid when approaching from the track below.
	_walk_pos.x = prev_xz.x
	_walk_pos.z = prev_xz.y


func _resolve_train_collision() -> void:
	if train == null:
		return
	var cab_v := _cab_vehicle()
	for v in train.vehicles:
		if v == null or not is_instance_valid(v) or not v.is_inside_tree():
			continue
		var xf := v.global_transform
		var local := xf.affine_inverse() * _walk_pos
		var feet := local.y
		var head := feet + WALK_EYE
		var skip_body := false
		if v == cab_v:
			var meta := _cab_walk_meta(v)
			if train.doors_open and train.door_open_side != 0 \
					and signf(local.x) == float(train.door_open_side) \
					and absf(local.z - float(meta["door_z"])) <= float(meta["door_half"]):
				skip_body = true
		if not skip_body and head > 1.02 and feet < 4.0:
			local = _push_local_box(local, 0.0, 0.0,
					v.width * 0.5 + 0.02, v.length * 0.5 + 0.1, 0.28)
		if feet < 1.08 and head > 0.3:
			# Side skirt / underframe.
			local = _push_local_box(local, 0.0, 0.0,
					v.width * 0.5 + 0.01, v.length * 0.5 - 0.25, 0.28)
		if feet < 1.08 and head > 0.0:
			var bz := v.bogie_spacing * 0.5
			for zz: float in [-bz, bz]:
				local = _push_local_box(local, 0.0, zz, 1.18, 2.1, 0.28)
		_walk_pos = xf * local


func spawn_on_foot() -> void:
	if train == null or route == null:
		return
	_cab_walk = false
	_jump_vel = 0.0
	_grounded = true
	var base := train.cab_position()
	var fr := route.frame_at(train.distance)
	var structure := _structure_at_dist(train.distance)
	if not structure.is_empty():
		# Never drop the player through a bridge deck or into the mountain
		# above a tunnel. Spawn on the structure's walking surface, a little
		# ahead of the train so the body does not fill the camera.
		var half := float(structure["half"])
		var side := minf(1.6, half * 0.72)
		var spawn_d := train.distance + 6.0
		var spawn_fr := route.frame_at(spawn_d)
		var spawn_center := route.position_at(spawn_d)
		if _structure_at_dist(spawn_d).is_empty():
			spawn_d = train.distance - 6.0
			spawn_fr = route.frame_at(spawn_d)
			spawn_center = route.position_at(spawn_d)
			if _structure_at_dist(spawn_d).is_empty():
				spawn_fr = fr
				spawn_center = route.position_at(train.distance)
		_walk_pos = spawn_center + spawn_fr.basis.x * side
		_walk_pos.y = float(structure["y"])
	else:
		_walk_pos = base + fr.basis.x * 5.0
		_walk_pos.y = _ground_at(_walk_pos.x, _walk_pos.z)
	_walk_vel = Vector3.ZERO
	look_toward(base)


func look_toward(p: Vector3) -> void:
	var d := p - (_walk_pos + Vector3.UP * WALK_EYE)
	if d.length_squared() < 0.0001:
		return
	var n := d.normalized()
	_look_yaw = atan2(n.x, n.z)
	_look_pitch = clampf(- asin(clampf(n.y, -1.0, 1.0)), -1.35, 1.35)


func place_walk(p: Vector3) -> void:
	_walk_pos = p
	_cab_walk = false
	_jump_vel = 0.0
	_grounded = true
	var platform := _platform_at(_walk_pos)
	var structure := _structure_at(_walk_pos)
	if not platform.is_empty():
		_walk_pos.y = float(platform["y"])
	elif not structure.is_empty() and absf(_walk_pos.y - float(structure["y"])) <= 3.0:
		_walk_pos.y = float(structure["y"])
	else:
		_walk_pos.y = _ground_at(p.x, p.z)
	_walk_vel = Vector3.ZERO


func _board_candidate() -> Dictionary:
	if train == null:
		return {}
	if absf(train.speed) > 0.6 or not train.doors_open:
		return {}
	var side := train.door_open_side
	var best := {}
	var best_d := 2.4
	for i in range(train.vehicles.size()):
		var v: Vehicle = train.vehicles[i]
		if v == null or not is_instance_valid(v) or not v.has_meta("train_walk"):
			continue
		var local := v.global_transform.affine_inverse() * _walk_pos
		if absf(local.x) < v.width * 0.5 - 0.12:
			continue
		if side != 0 and signf(local.x) != float(side):
			continue
		var door_zs: Array[float] = []
		if v.kind == "loco":
			door_zs.append(float(_cab_walk_meta(v)["door_z"]))
			door_zs.append(float(v.get_meta("train_walk_back", v.length * 0.5 - 0.5)))
		elif v.kind == "coach" or v.kind == "baggage":
			var dz := v.length * 0.5 - 2.3
			door_zs.append(-dz)
			door_zs.append(dz)
		for door_z: float in door_zs:
			var dist := Vector2(maxf(0.0, absf(local.x) - v.width * 0.5),
					local.z - door_z).length()
			if dist < best_d:
				best_d = dist
				best = {"index": i, "z": door_z, "vehicle": v}
	return best


func can_board() -> bool:
	return not _board_candidate().is_empty()


func try_board() -> bool:
	var cand := _board_candidate()
	if cand.is_empty():
		return false
	var idx := int(cand["index"])
	var v: Vehicle = cand["vehicle"]
	var z := float(cand["z"])
	var cab_door_z := float(_cab_walk_meta(v)["door_z"]) if v.kind == "loco" else INF
	set_mode(Mode.CAB)
	if v.kind == "loco" and absf(z - cab_door_z) < 0.1:
		sit_down(0)
		return true
	_train_walk = true
	_on_foot = true
	_cab_walk = false
	_walk_vehicle = idx
	var floor_y := float(v.get_meta("train_walk_floor", 1.2))
	var front := float(v.get_meta("train_walk_front", -v.length * 0.5 + 0.2))
	var back := float(v.get_meta("train_walk_back", v.length * 0.5 - 0.2))
	z = clampf(z, front + 0.25, back - 0.25)
	var board_xf := v.get_global_transform_interpolated()
	_walk_pos = board_xf * Vector3(0.0, floor_y, z)
	_walk_vel = Vector3.ZERO
	_jump_vel = 0.0
	_grounded = true
	_last_walk_valid = false
	_restore_cab_visibility()
	camera.cull_mask = 0xFFFFF
	camera.far = 52000.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	look_toward(board_xf * Vector3(0.0, floor_y + 1.4, 0.0))
	return true


func _update_walk(delta: float) -> void:
	# Keep the walker attached to the car frame. Without this, a moving
	# train slides out from under the player between frames.
	var moving_v: Vehicle = null
	if _train_walk and train != null \
			and _walk_vehicle >= 0 and _walk_vehicle < train.vehicles.size():
		moving_v = train.vehicles[_walk_vehicle]
	elif _cab_walk:
		moving_v = _cab_vehicle()
	if moving_v != null:
		var cur := moving_v.get_global_transform_interpolated()
		if _last_walk_valid and _last_walk_vehicle == _walk_vehicle:
			_walk_pos = (cur * _last_walk_xf.affine_inverse()) * _walk_pos
		_last_walk_xf = cur
		_last_walk_vehicle = _walk_vehicle
		_last_walk_valid = true
	else:
		_last_walk_valid = false
	var yaw_basis := Basis(Vector3.UP, _look_yaw)
	var fwd := yaw_basis.z
	# The camera looks along +basis.z after look_at(); with Y up, the
	# on-screen right is therefore -basis.x, not +basis.x.
	var right := - yaw_basis.x
	var move := Vector3.ZERO
	if Input.is_action_pressed("gear_up"):
		move += fwd
	if Input.is_action_pressed("gear_down"):
		move -= fwd
	if Input.is_action_pressed("doors_toggle"):
		move -= right
	if Input.is_action_pressed("lights_toggle"):
		move += right
	var speed := 8.6 if Input.is_key_pressed(KEY_SHIFT) else 4.2
	var target := Vector3.ZERO
	if move.length_squared() > 0.0001:
		target = move.normalized() * speed
	_walk_vel = _walk_vel.lerp(target, clampf(delta * 11.0, 0.0, 1.0))
	var prev_xz := Vector2(_walk_pos.x, _walk_pos.z)
	_walk_pos += _walk_vel * delta
	if _train_walk:
		_train_walk_step()
	elif _cab_walk:
		_cab_walk_step()
	if not _cab_walk and not _train_walk:
		_resolve_world_collisions(prev_xz)

	var surface_y := _ground_at(_walk_pos.x, _walk_pos.z)
	if _train_walk and _walk_vehicle >= 0 and _walk_vehicle < train.vehicles.size():
		var tv := train.vehicles[_walk_vehicle]
		surface_y = (tv.get_global_transform_interpolated() * Vector3(0.0, float(tv.get_meta("train_walk_floor", 1.2)), 0.0)).y
	elif _cab_walk:
		var cv := _cab_vehicle()
		if cv != null:
			var meta := _cab_walk_meta(cv)
			surface_y = (cv.get_global_transform_interpolated() * Vector3(0.0, float(meta["floor"]), 0.0)).y
	else:
		var platform := _platform_at(_walk_pos)
		if not platform.is_empty():
			surface_y = float(platform["y"])
		else:
			var structure := _structure_at(_walk_pos)
			if not structure.is_empty():
				var deck_y := float(structure["y"])
				if absf(_walk_pos.y - deck_y) <= 3.0:
					# Stay on the bridge deck or tunnel floor instead of
					# falling to the water/mountain below; clamp at the
					# walkable width.
					var center: Vector3 = structure["center"]
					var lateral := Vector3(_walk_pos.x - center.x, 0.0, _walk_pos.z - center.z)
					var half := float(structure["half"])
					if lateral.length() > half:
						lateral = lateral.normalized() * half
						_walk_pos.x = center.x + lateral.x
						_walk_pos.z = center.z + lateral.z
					surface_y = deck_y

	# Space jumps while on foot; the cab ceiling is high enough for a small hop.
	if _grounded and Input.is_action_just_pressed("jump"):
		_jump_vel = 4.6
		_grounded = false
	if not _grounded:
		_jump_vel -= 15.5 * delta
		_walk_pos.y += _jump_vel * delta
		if _walk_pos.y <= surface_y:
			_walk_pos.y = surface_y
			_jump_vel = 0.0
			_grounded = true
	else:
		if _walk_pos.y - surface_y > 0.55:
			# Walked off a platform or bridge edge: fall instead of gliding
			# down through the air.
			_grounded = false
			_jump_vel = 0.0
		else:
			_walk_pos.y = lerpf(_walk_pos.y, surface_y, clampf(delta * 14.0, 0.0, 1.0))
			if absf(_walk_pos.y - surface_y) < 0.01:
				_walk_pos.y = surface_y
	var hspeed := Vector2(_walk_vel.x, _walk_vel.z).length()
	_bob_phase += hspeed * delta * 1.9
	_bob = sin(_bob_phase) * 0.045 * clampf(hspeed / 4.6, 0.0, 1.4)
	var dir := (yaw_basis * Basis(Vector3.RIGHT, _look_pitch)).z
	var eye := _walk_pos + Vector3.UP * (WALK_EYE + _bob)
	camera.global_position = eye
	camera.look_at(eye + dir * 10.0)