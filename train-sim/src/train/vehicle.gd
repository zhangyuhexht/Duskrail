extends Node3D
class_name Vehicle


var length := 20.0
var width := 3.1
var height := 3.9
var bogie_spacing := 12.6
var wheel_radius := 0.46
var wheels: Array [Node3D] = []
var wheel_radius_map := {}
var pantographs: Array [Node3D] = []
var bogie_frames: Array [Node3D] = []

# CPU suspension state. One vertical DOF per bogie plus body bounce/roll/pitch.
# Packed arrays keep the per-tick path allocation-free.
var susp_y := PackedFloat32Array()
var susp_vy := PackedFloat32Array()
var susp_z := PackedFloat32Array()
var susp_mass_body := 0.0
var susp_mass_bogie := 0.0
var susp_k_sec := 0.0
var susp_c_sec := 0.0
var susp_k_pri := 0.0
var susp_c_pri := 0.0
var body_bounce := 0.0
var body_bounce_v := 0.0
var body_roll_dyn := 0.0
var body_roll_v := 0.0
var body_pitch_dyn := 0.0
var body_pitch_v := 0.0
# Smoothed curvature signal so the body eases into a curve instead of
# taking the raw bogie-geometry step as an instant roll target.
var curve_smooth := 0.0
var head_lights: Array [SpotLight3D] = []
var mass_empty := 20.0
var mass_loaded := 20.0
var loaded := false
var kind := "wagon"
var designation := ""
var max_speed := 120.0
var brake_force := 1.0
var tractive_force := 420000.0

var _body_root: Node3D


var cab_anchor := Vector3.ZERO
var flip_model := false
var cab_parts := {}
var door_leaves: Array [Node3D] = []

func body_root() -> Node3D:
	if _body_root == null:
		_body_root = Node3D.new()
		_body_root.name = "Body"
		add_child(_body_root)
	return _body_root

func attach(node: Node3D) -> Node3D:
	# Readable duplicate names keep Cab*/Dev* parts recognizable to the cab filter.
	body_root().add_child(node, true)
	return node


func part(mesh: Mesh, mat: Material, xf: Transform3D = Transform3D(), name := "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if mat != null:
		mi.material_override = mat
	mi.transform = xf
	if name != "":
		mi.name = name
	attach(mi)
	return mi


func merged(items: Array, mat: Material, name := "") -> MeshInstance3D:
	var mesh := Forge.merge_all(items)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if mat != null:
		mi.material_override = mat
	mi.name = name if name != "" else "MergedPart"
	attach(mi)
	return mi

func add_wheel(node: Node3D, radius: float) -> void:
	wheels.append(node)
	wheel_radius_map [node] = radius


func spin_wheels(distance_delta: float) -> void:
	for w in wheels:
		if not is_instance_valid(w):
			continue
		var r: float = wheel_radius_map.get(w, 0.46)
		if r > 0.01:
			w.rotation.x += distance_delta / r


func apply_doors(ratio: float, open_side := 0) -> void:
	var t := clampf(ratio, 0.0, 1.0)
	var car_at_platform := not has_meta("door_platform_ok") or bool(get_meta("door_platform_ok"))
	for l in door_leaves:
		if not is_instance_valid(l):
			continue
		var leaf_t := t
		if not car_at_platform:
			leaf_t = 0.0
		if open_side != 0 and l.has_meta("door_side") \
				and int(l.get_meta("door_side")) != open_side:
			leaf_t = 0.0
		var base: Vector3 = l.get_meta("closed_pos", l.position)
		var delta: Vector3 = l.get_meta("open_delta", Vector3.ZERO)
		if l.has_meta("plug_slide"):
			# Plug door: first move straight out by the door thickness, then
			# slide along the body side. Closing runs the same path in reverse.
			var out: Vector3 = l.get_meta("slide_out", Vector3.ZERO)
			var side: Vector3 = l.get_meta("slide_side", Vector3.ZERO)
			var out_t := clampf(leaf_t / 0.35, 0.0, 1.0)
			var slide_t := smoothstep(0.35, 1.0, leaf_t)
			l.position = base + out * out_t + side * slide_t
		else:
			l.position = base + delta * leaf_t
			if l.has_meta("hinge_axis"):
				var closed_rot: Vector3 = l.get_meta("closed_rot", Vector3.ZERO)
				var axis: Vector3 = l.get_meta("hinge_axis", Vector3.UP)
				var open_angle: float = l.get_meta("open_angle", 0.0)
				l.rotation = closed_rot + axis * open_angle * leaf_t

func set_loaded(v: bool) -> void:
	loaded = v

func current_mass() -> float:
	return mass_loaded if loaded else mass_empty


func ensure_suspension() -> void:
	var n := bogie_frames.size()
	var m := maxf(current_mass(), 1.0) * 1000.0
	if susp_y.size() != n:
		susp_y.resize(n)
		susp_vy.resize(n)
		susp_z.resize(n)
		for bi in range(n):
			var frame := bogie_frames[bi]
			var parent := frame.get_parent()
			if parent is Node3D:
				susp_z[bi] = (parent as Node3D).position.z
			else:
				susp_z[bi] = frame.position.z
		body_bounce = 0.0
		body_bounce_v = 0.0
		body_roll_dyn = 0.0
		body_roll_v = 0.0
		body_pitch_dyn = 0.0
		body_pitch_v = 0.0
		curve_smooth = 0.0
	if absf(m - susp_mass_body) > 0.5:
		susp_mass_body = m
		susp_mass_bogie = clampf(m * 0.06, 2200.0, 9000.0)
		var w_body := TAU * 1.35
		var w_bogie := TAU * 6.0
		susp_k_sec = 0.5 * m * w_body * w_body
		susp_c_sec = 0.38 * m * w_body
		susp_k_pri = susp_mass_bogie * w_bogie * w_bogie
		susp_c_pri = 2.0 * 0.45 * susp_mass_bogie * w_bogie


func reset_suspension() -> void:
	ensure_suspension()
	for bi in range(susp_y.size()):
		susp_y[bi] = 0.0
		susp_vy[bi] = 0.0
	body_bounce = 0.0
	body_bounce_v = 0.0
	body_roll_dyn = 0.0
	body_roll_v = 0.0
	body_pitch_dyn = 0.0
	body_pitch_v = 0.0
	curve_smooth = 0.0


func coupler_offsets() -> Array:
	return [- length * 0.5, length * 0.5]