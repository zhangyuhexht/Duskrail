extends Node3D

# Lightweight moving traffic and pedestrians for the procedural towns and
# cities. Everything is built from shared primitive meshes so a city adds only
# a few dozen draw calls and remains usable on integrated graphics.

const CAR_COLORS := [
	Color(0.58, 0.14, 0.11), Color(0.82, 0.82, 0.80), Color(0.13, 0.20, 0.30),
	Color(0.18, 0.25, 0.22), Color(0.64, 0.48, 0.18), Color(0.28, 0.29, 0.31),
]
const COAT_COLORS := [
	Color(0.12, 0.18, 0.27), Color(0.35, 0.16, 0.14), Color(0.18, 0.22, 0.20),
	Color(0.44, 0.38, 0.27), Color(0.24, 0.25, 0.28), Color(0.52, 0.28, 0.22),
]

var _route: Route
var _center := Vector3.ZERO
var _pad_h := 0.0
var _radius := 300.0
var _block := 54.0
var _road_w := 8.0
var _lanes: Array = []
var _walks: Array = []
var _cars: Array = []
var _peds: Array = []
var _time := 0.0
var _car_mesh: BoxMesh
var _cabin_mesh: BoxMesh
var _wheel_mesh: BoxMesh
var _body_mesh: BoxMesh
var _torso_mesh: BoxMesh
var _head_mesh: SphereMesh
var _car_mats: Array = []
var _coat_mats: Array = []
var _skin_mats: Array = []
var _head_mat: StandardMaterial3D


static func attach(parent: Node3D, route: Route, site: Dictionary, block: float,
		road_w: float) -> Node3D:
	var s = load("res://src/world/street_life.gd").new()
	s.name = "StreetLife"
	parent.add_child(s)
	s._setup(route, site, block, road_w)
	return s


func _setup(route: Route, site: Dictionary, block: float, road_w: float) -> void:
	_route = route
	_center = site.get("center", Vector3.ZERO)
	_pad_h = float(site.get("height", 0.0))
	_radius = float(site.get("radius", 300.0))
	_block = maxf(24.0, block)
	_road_w = maxf(4.0, road_w)
	_build_shared()
	_build_lanes()
	_spawn_cars()
	_spawn_peds()
	set_process(true)


func _build_shared() -> void:
	_car_mesh = BoxMesh.new()
	_car_mesh.size = Vector3(1.82, 0.56, 4.0)
	_cabin_mesh = BoxMesh.new()
	_cabin_mesh.size = Vector3(1.58, 0.48, 2.0)
	_wheel_mesh = BoxMesh.new()
	_wheel_mesh.size = Vector3(0.20, 0.46, 0.46)
	_body_mesh = BoxMesh.new()
	_body_mesh.size = Vector3(0.38, 0.62, 0.24)
	_torso_mesh = BoxMesh.new()
	_torso_mesh.size = Vector3(0.30, 0.38, 0.20)
	_head_mesh = SphereMesh.new()
	_head_mesh.radius = 0.105
	_head_mesh.height = 0.21
	_head_mesh.radial_segments = 8
	_head_mesh.rings = 5
	for c: Color in CAR_COLORS:
		_car_mats.append(Gfx.paint(c, 0.25, 0.45, 0.75))
	for c: Color in COAT_COLORS:
		_coat_mats.append(Gfx.paint(c, 0.55, 0.08, 0.15))
	_skin_mats = [
		Gfx.paint(Color(0.82, 0.66, 0.51), 0.6, 0.02, 0.12),
		Gfx.paint(Color(0.68, 0.51, 0.38), 0.6, 0.02, 0.12),
		Gfx.paint(Color(0.54, 0.39, 0.29), 0.6, 0.02, 0.12),
	]
	_head_mat = _skin_mats[0]


func _near_rail(p: Vector3) -> bool:
	if _route == null:
		return false
	var d := _route.nearest_dist(p)
	return _route.position_at(d).distance_to(p) < 24.0


func _lane_ok(a: Vector3, b: Vector3) -> bool:
	for k in range(5):
		var p := a.lerp(b, float(k) / 4.0)
		if _near_rail(p):
			return false
	return true


func _build_lanes() -> void:
	var grid := int(_radius / _block)
	for gz in range(-grid, grid + 1):
		if absi(gz) % 3 != 0:
			continue
		for side: float in [-1.0, 1.0]:
			var z := _center.z + float(gz) * _block + side * _road_w * 0.24
			if absf(z - _center.z) > _radius - 25.0:
				continue
			var a := Vector3(_center.x - _radius * 0.82, _pad_h + 0.07, z)
			var b := Vector3(_center.x + _radius * 0.82, _pad_h + 0.07, z)
			if not _lane_ok(a, b):
				continue
			_lanes.append({"a": a, "b": b, "dir": 1.0 if side > 0.0 else -1.0,
					"angle": PI * 0.5 if side < 0.0 else -PI * 0.5})
	for gx in range(-grid, grid + 1):
		if absi(gx) % 3 != 0:
			continue
		for side: float in [-1.0, 1.0]:
			var x := _center.x + float(gx) * _block + side * _road_w * 0.24
			if absf(x - _center.x) > _radius - 25.0:
				continue
			var a := Vector3(x, _pad_h + 0.07, _center.z - _radius * 0.82)
			var b := Vector3(x, _pad_h + 0.07, _center.z + _radius * 0.82)
			if not _lane_ok(a, b):
				continue
			_lanes.append({"a": a, "b": b, "dir": 1.0 if side < 0.0 else -1.0,
					"angle": 0.0 if side > 0.0 else PI})
	# Pedestrian paths are offset from the same roads onto the sidewalk.
	for gz in range(-grid, grid + 1):
		if absi(gz) % 3 != 0:
			continue
		for side: float in [-1.0, 1.0]:
			var z := _center.z + float(gz) * _block + side * (_road_w * 0.5 + 1.35)
			if absf(z - _center.z) > _radius - 22.0:
				continue
			var a := Vector3(_center.x - _radius * 0.62, _pad_h + 0.11, z)
			var b := Vector3(_center.x + _radius * 0.62, _pad_h + 0.11, z)
			if _lane_ok(a, b):
				_walks.append({"a": a, "b": b, "angle": PI * 0.5 if side < 0.0 else -PI * 0.5})
	for gx in range(-grid, grid + 1):
		if absi(gx) % 3 != 0:
			continue
		for side: float in [-1.0, 1.0]:
			var x := _center.x + float(gx) * _block + side * (_road_w * 0.5 + 1.35)
			if absf(x - _center.x) > _radius - 22.0:
				continue
			var a := Vector3(x, _pad_h + 0.11, _center.z - _radius * 0.62)
			var b := Vector3(x, _pad_h + 0.11, _center.z + _radius * 0.62)
			if _lane_ok(a, b):
				_walks.append({"a": a, "b": b, "angle": 0.0 if side > 0.0 else PI})


func _spawn_cars() -> void:
	if _lanes.is_empty():
		return
	var count := 4
	match Config.quality:
		Config.Quality.MEDIUM:
			count = 7
		Config.Quality.HIGH:
			count = 11
		Config.Quality.ULTRA:
			count = 15
	if _radius < 300.0:
		count = maxi(2, int(count * 0.5))
	for i in range(count):
		var lane_i := i % _lanes.size()
		var lane: Dictionary = _lanes[lane_i]
		var car := Node3D.new()
		car.name = "Car%d" %i
		var body := MeshInstance3D.new()
		body.mesh = _car_mesh
		body.material_override = _car_mats[i % _car_mats.size()]
		body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		car.add_child(body)
		var cabin := MeshInstance3D.new()
		cabin.mesh = _cabin_mesh
		cabin.material_override = Gfx.glass(Color(0.07, 0.12, 0.16), 0.08, 0.55)
		cabin.position = Vector3(0, 0.46, -0.18)
		cabin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		car.add_child(cabin)
		for wx: float in [-0.76, 0.76]:
			for wz: float in [-1.25, 1.25]:
				var wheel := MeshInstance3D.new()
				wheel.mesh = _wheel_mesh
				wheel.material_override = Gfx.metal(Color(0.035, 0.035, 0.04), 0.85, 0.1)
				wheel.position = Vector3(wx, -0.20, wz)
				wheel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				car.add_child(wheel)
		add_child(car)
		var u := fmod(float(i) * 0.137 + 0.11, 1.0)
		_cars.append({"node": car, "lane": lane_i, "u": u,
				"speed": 6.5 + float(i % 5) * 1.4})


func _spawn_peds() -> void:
	if _walks.is_empty():
		return
	var count := 4
	match Config.quality:
		Config.Quality.MEDIUM:
			count = 8
		Config.Quality.HIGH:
			count = 12
		Config.Quality.ULTRA:
			count = 17
	if _radius < 300.0:
		count = maxi(2, int(count * 0.5))
	for i in range(count):
		var walk_i := i % _walks.size()
		var ped := Node3D.new()
		ped.name = "Pedestrian%d" %i
		var torso := MeshInstance3D.new()
		torso.mesh = _body_mesh
		torso.material_override = _coat_mats[i % _coat_mats.size()]
		torso.position = Vector3(0, 0.62, 0)
		torso.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ped.add_child(torso)
		var hips := MeshInstance3D.new()
		hips.mesh = _torso_mesh
		hips.material_override = _coat_mats[(i + 2) % _coat_mats.size()]
		hips.position = Vector3(0, 0.25, 0)
		hips.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ped.add_child(hips)
		var head := MeshInstance3D.new()
		head.mesh = _head_mesh
		head.material_override = _skin_mats[i % _skin_mats.size()]
		head.position = Vector3(0, 1.03, 0)
		head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ped.add_child(head)
		add_child(ped)
		_peds.append({"node": ped, "walk": walk_i,
				"u": fmod(float(i) * 0.219 + 0.07, 1.0),
				"speed": 0.75 + float(i % 4) * 0.22,
				"phase": float(i) * 0.9, "dir": 1.0 if i % 2 == 0 else -1.0})


func _process(delta: float) -> void:
	_time += delta
	for car: Dictionary in _cars:
		var lane: Dictionary = _lanes[int(car["lane"])]
		var a: Vector3 = lane["a"]
		var b: Vector3 = lane["b"]
		var seg_len := maxf(2.0, b.distance_to(a))
		var u := float(car["u"]) + float(car["speed"]) * delta / seg_len
		if u > 1.0:
			u -= 1.0
		car["u"] = u
		var pos := a.lerp(b, u)
		var node := car["node"] as Node3D
		node.position = pos
		node.rotation.y = float(lane["angle"])
	for ped: Dictionary in _peds:
		var walk: Dictionary = _walks[int(ped["walk"])]
		var a: Vector3 = walk["a"]
		var b: Vector3 = walk["b"]
		var seg_len := maxf(2.0, b.distance_to(a))
		var u := float(ped["u"]) + float(ped["dir"]) * float(ped["speed"]) * delta / seg_len
		if u > 1.0:
			u = 1.0
			ped["dir"] = -1.0
		elif u < 0.0:
			u = 0.0
			ped["dir"] = 1.0
		ped["u"] = u
		var pos := a.lerp(b, u)
		pos.y += sin(_time * 7.0 + float(ped["phase"])) * 0.025
		var node := ped["node"] as Node3D
		node.position = pos
		node.rotation.y = float(walk["angle"]) if float(ped["dir"]) > 0.0 else float(walk["angle"]) + PI
