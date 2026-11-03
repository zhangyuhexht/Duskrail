extends Node3D
class_name Train



signal event(kind: String, data: Dictionary)

var route: Route
var vehicles: Array [Vehicle] = []
var service_name := "货运列车"


const GEAR_NAMES := ["P3", "P2", "P1", "N", "D1", "D2", "D3", "D4", "D5"]
const GEAR_P3 := 0
const GEAR_P2 := 1
const GEAR_P1 := 2
const GEAR_N := 3
const GEAR_D1 := 4
const GEAR_D5 := 8
const GEAR_DRIVE_NOTCH := [2, 4, 6, 7, 8]

var distance := 0.0
var _prev_distance := 0.0
var speed := 0.0
var reverser := 1
var gear: int = GEAR_P3
var notch := 0
var brake_notch := 0
var emergency := false
var handbrake := false
var sanding := false
var brake_cylinder := 0.0
var brake_pipe := 5.0


var max_tractive_force := 420000.0
var max_speed := 33.3
var brake_force_max := 0.0
var total_length := 0.0
var mass := 0.0
var head_lights_on := true
var pantograph_up := true


var acceleration := 0.0
var gradient := 0.0
var curve_resistance_n := 0.0
var resistance_n := 0.0
var tractive_force_n := 0.0
var brake_force_n := 0.0
var slip := false
var _vehicle_offsets: Array [float] = []
const VEHICLE_GAP := 0.5
var _wheel_accum := 0.0


var lane := 0
var siding: Dictionary = {}

var ai := false
var ai_speed := 0.0
var layout_reversed := false
var lead_cab_only := false
var test_mode := false

var _sway_noise: FastNoiseLite

var doors_open := false
var door_open_side := 0
var cab_door_only := false
var door_anim := 0.0
var power_knee_kmh := 22.0

func setup(p_route: Route, p_vehicles: Array) -> void:
	route = p_route
	# Smooth, non-repeating lateral sway source. Two octaves give a slow
	# irregular lean instead of a metronome-like sine.
	_sway_noise = FastNoiseLite.new()
	_sway_noise.seed = randi()
	_sway_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_sway_noise.frequency = 1.0
	_sway_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_sway_noise.fractal_octaves = 3
	_sway_noise.fractal_gain = 0.45
	_sway_noise.fractal_lacunarity = 2.1
	vehicles.clear()
	for v in p_vehicles:
		add_child(v)
		vehicles.append(v)
	_recompute_layout()
	_update_end_doors()
	for v in vehicles:
		if v != null:
			v.apply_doors(door_anim if doors_open else 0.0, door_open_side)
	set_light_state(true)


func _update_end_doors() -> void:
	for i in range(vehicles.size()):
		var v: Vehicle = vehicles[i]
		if v == null:
			continue
		var next_ok := i + 1 < vehicles.size() \
				and (vehicles[i + 1].kind == "coach" or vehicles[i + 1].kind == "baggage")
		var prev_ok := i > 0 and (vehicles[i - 1].kind == "coach" \
				or vehicles[i - 1].kind == "baggage" or vehicles[i - 1].kind == "loco")
		if v.kind == "loco":
			var loco_rear := v.find_child("EndDoorRear", true, false) as Node3D
			if loco_rear != null:
				loco_rear.visible = not next_ok
			var loco_gangway := v.find_child("RearGangway", true, false) as Node3D
			if loco_gangway != null:
				loco_gangway.visible = next_ok
			continue
		if v.kind != "coach" and v.kind != "baggage":
			continue
		var rear := v.find_child("EndDoorRear", true, false) as Node3D
		if rear != null:
			rear.visible = not next_ok
		var front := v.find_child("EndDoorFront", true, false) as Node3D
		if front != null:
			front.visible = not prev_ok
		var gangway_rear := v.find_child("GangwayRear", true, false) as Node3D
		if gangway_rear != null:
			gangway_rear.visible = next_ok
		var gangway_front := v.find_child("GangwayFront", true, false) as Node3D
		if gangway_front != null:
			gangway_front.visible = prev_ok

func _recompute_layout() -> void:
	total_length = 0.0
	mass = 0.0
	_vehicle_offsets.clear()
	var offset := 0.0
	var first := true
	for v in vehicles:
		if not first:
			offset += VEHICLE_GAP
		offset += v.length * 0.5
		_vehicle_offsets.append(offset)
		offset += v.length * 0.5
		mass += v.current_mass() * 1000.0
		first = false
	total_length = offset

	var traction := 0.0
	var emu := false
	var vmin := 999.0
	for v in vehicles:
		if v.kind == "loco":
			traction += v.tractive_force
		elif v.kind == "emu":
			traction += 240000.0
			emu = true
		vmin = minf(vmin, float(v.max_speed))
	max_tractive_force = traction if traction > 0.0 else 420000.0
	power_knee_kmh = 150.0 if emu else 22.0
	max_speed = clampf(vmin / 3.6, 8.0, 72.0)

	var brake_rate := 0.0
	for v in vehicles:
		brake_rate += v.brake_force * v.length
	brake_rate = brake_rate / maxf(total_length, 1.0)
	brake_force_max = mass * 0.95 * brake_rate

func train_mass_tonnes() -> float:
	return mass / 1000.0



func set_notch(v: int) -> void:
	notch = clampi(v, -8, 8)
	if notch != 0:
		emergency = false

func set_brake(v: int) -> void:
	brake_notch = clampi(v, 0, 7)
	if brake_notch > 0:
		emergency = false

func gear_name() -> String:
	return GEAR_NAMES [clampi(gear, 0, GEAR_NAMES.size() - 1)]

func gear_is_drive() -> bool:
	return gear >= GEAR_D1

func gear_brake_level() -> int:
	match gear:
		GEAR_P3:
			return 7
		GEAR_P2:
			return 5
		GEAR_P1:
			return 3
		_:
			return 0

func gear_notch_level() -> int:
	if gear < GEAR_D1:
		return 0
	return int(GEAR_DRIVE_NOTCH [clampi(gear - GEAR_D1, 0, GEAR_DRIVE_NOTCH.size() - 1)])

func set_gear(g: int) -> void:
	gear = clampi(g, 0, GEAR_NAMES.size() - 1)
	if gear <= GEAR_P1:
		set_brake(gear_brake_level())
		set_notch(0)
	elif gear == GEAR_N:
		set_brake(0)
		set_notch(0)
		emergency = false
	else:
		set_brake(0)
		set_notch(gear_notch_level())
		if reverser <= 0:
			reverser = 1

func emergency_brake() -> void:
	emergency = true
	brake_notch = 7
	notch = 0
	gear = GEAR_P3

func set_light_state(on: bool) -> void:
	head_lights_on = on
	for v in vehicles:
		var active := on and not bool(v.get_meta("trailing_loco", false))
		for l in v.head_lights:
			if is_instance_valid(l):
				l.visible = active

func set_pantograph(up: bool) -> void:
	pantograph_up = up
	for v in vehicles:
		for p in v.pantographs:
			if is_instance_valid(p):
				var arm := p.get_node_or_null("PantographArm")
				if arm:
					var target := 0.0 if up else -0.62
					arm.position.y = lerpf(arm.position.y, 0.42 + target, 1.0)



func step(delta: float) -> void:
	if route == null or vehicles.is_empty():
		return
	_prev_distance = distance
	_update_brake_pressure(delta)
	var mid := distance
	gradient = route.gradient_at(mid)
	var curv := route.curvature_at(mid)


	tractive_force_n = 0.0
	if reverser != 0 and notch > 0 and not emergency:
		var frac := float(notch) / 8.0
		var v_kmh := absf(speed) * 3.6
		var base_v := power_knee_kmh
		var f := max_tractive_force
		if v_kmh > base_v:
			f = max_tractive_force * base_v / maxf(v_kmh, 1.0)
		tractive_force_n = f * frac

		var mu := 0.60 if test_mode else (0.24 if not _wet() else 0.15)
		if sanding:
			mu += 0.06
		var adhesion_limit := mu * mass * Config.GRAVITY
		if tractive_force_n > adhesion_limit:
			slip = true
			tractive_force_n = adhesion_limit * 0.85
		else:
			slip = false
	elif slip:
		slip = false


	if notch < 0 and not emergency:
		var frac := float(- notch) / 8.0
		brake_force_n = brake_force_max * 0.55 * frac * minf(1.0, absf(speed) / 8.0)
	else:
		brake_force_n = 0.0


	var air := brake_force_max *(brake_cylinder / 4.5)
	if emergency:
		air = brake_force_max
	if handbrake:
		air = maxf(air, brake_force_max * 0.35)
	brake_force_n += air


	var v_abs := absf(speed)
	var tonnes := mass / 1000.0
	var davis := 1.6 + 0.012 * v_abs + 0.00035 * v_abs * v_abs
	resistance_n = davis * tonnes

	curve_resistance_n = 0.0
	if curv > 0.0005:
		var radius := 1.0 / curv
		if radius < 1200.0:
			curve_resistance_n =(650.0 / maxf(radius - 55.0, 40.0)) * tonnes
	resistance_n += curve_resistance_n

	var grade_force := mass * Config.GRAVITY * sin(gradient)


	var drag := brake_force_n + resistance_n
	var drive := tractive_force_n - grade_force
	var force := 0.0
	if absf(speed) > 0.05:
		force = drive - drag * signf(speed)
	elif absf(drive) > drag:
		force = drive - drag * signf(drive)
	else:
		speed = 0.0
	if force != 0.0:
		acceleration = force / mass
		speed += acceleration * delta
	else:
		acceleration = 0.0


	if speed > max_speed:
		speed = minf(speed, max_speed + 0.5)

	if reverser == 0:
		speed = move_toward(speed, 0.0, 8.0 * delta)
	var delta_dist := speed * delta * float(reverser if reverser != 0 else 1)
	distance = route.wrap_dist(distance + delta_dist)
	_place_vehicles(delta)
	_spin(delta_dist)
	update_cab_and_doors(delta)

func _wet() -> bool:
	return _weather_wet

var _weather_wet := false
func set_wet(v: bool) -> void:
	_weather_wet = v

func _update_brake_pressure(delta: float) -> void:
	var target := 0.0
	if emergency:
		target = 4.5
	else:
		target = 4.5 *(float(brake_notch) / 7.0)
	var rate := 1.1 if target > brake_cylinder else 0.75
	brake_cylinder = move_toward(brake_cylinder, target, rate * delta)




func siding_lateral(d: float) -> float:
	if lane != 1 or siding.is_empty():
		return 0.0
	return Config.siding_lateral(route, d, siding)


func pos_at(d: float) -> Vector3:
	var p := route.position_at(d)
	var off := siding_lateral(d)
	if absf(off) > 0.002:
		p += route.frame_at(d).basis.x * off
	return p

func _track_roughness(d: float, seed: float) -> float:
	var r := sin(d * 0.43 + seed) * 0.0045
	r += sin(d * 1.31 + seed * 2.1) * 0.0022
	r += sin(d * 3.77 + seed * 0.7) * 0.0009
	var joint := fposmod(d, 24.0)
	if joint < 1.2:
		r += sin(joint / 1.2 * PI) * 0.0026
	return r


func _step_suspension(v: Vehicle, vi: int, d: float, face: float, curve: float,
		grad: float, speed_abs: float, dt: float) -> void:
	v.ensure_suspension()
	var n := v.susp_y.size()
	if n == 0 or dt <= 0.0:
		return

	var speed_scale := clampf(speed_abs / 14.0, 0.0, 1.0)
	var seed := float(vi) * 1.37
	var body_y := v.body_bounce
	var body_vy := v.body_bounce_v
	var body_acc := 0.0

	for bi in range(n):
		var bz := v.susp_z[bi]
		var rail := _track_roughness(d - face * bz, seed + float(bi) * 2.31) * speed_scale
		var y := v.susp_y[bi]
		var vy := v.susp_vy[bi]
		var f_pri := (rail - y) * v.susp_k_pri - vy * v.susp_c_pri
		var rel := y - body_y
		var rel_v := vy - body_vy
		var f_sec := rel * v.susp_k_sec + rel_v * v.susp_c_sec
		vy += (f_pri - f_sec) / v.susp_mass_bogie * dt
		y += vy * dt
		v.susp_y[bi] = clampf(y, -0.08, 0.08)
		v.susp_vy[bi] = clampf(vy, -1.0, 1.0)
		body_acc += f_sec / v.susp_mass_body

	body_vy = clampf(body_vy + body_acc * dt, -0.4, 0.4)
	body_y = clampf(body_y + body_vy * dt, -0.05, 0.05)
	v.body_bounce = body_y
	v.body_bounce_v = body_vy

	var cross := 0.0
	if _sway_noise != null:
		var sway_x := d * 0.011 + seed * 9.0
		cross = (_sway_noise.get_noise_1d(sway_x) * 0.00135
				+ _sway_noise.get_noise_1d(sway_x * 3.1 + 37.0) * 0.00045) * speed_scale
	# Ease the curvature signal as a vehicle crosses from tangent into a
	# curve; the raw bogie geometry can otherwise step the target roll.
	v.curve_smooth = lerpf(v.curve_smooth, curve, 1.0 - exp(-dt / 0.95))
	var target_roll := clampf(-v.curve_smooth * speed_abs * speed_abs * 0.045, -0.032, 0.032) + cross
	target_roll = clampf(target_roll, -0.04, 0.04)
	var w_roll := TAU * 1.15
	var roll_acc := (target_roll - v.body_roll_dyn) * w_roll * w_roll
	roll_acc -= v.body_roll_v * (2.0 * 0.7 * w_roll)
	v.body_roll_v = clampf(v.body_roll_v + roll_acc * dt, -0.22, 0.22)
	v.body_roll_dyn = clampf(v.body_roll_dyn + v.body_roll_v * dt, -0.05, 0.05)

	# Longitudinal acceleration no longer pitches the carbody. Traction and
	# brake changes should not make the whole train nod fore/aft; only the
	# actual track gradient still tilts it.
	var target_pitch := clampf(-grad * 0.08, -0.03, 0.03)
	var w_pitch := TAU * 2.2
	var pitch_acc := (target_pitch - v.body_pitch_dyn) * w_pitch * w_pitch
	pitch_acc -= v.body_pitch_v * (2.0 * 0.55 * w_pitch)
	v.body_pitch_v = clampf(v.body_pitch_v + pitch_acc * dt, -0.25, 0.25)
	v.body_pitch_dyn = clampf(v.body_pitch_dyn + v.body_pitch_v * dt, -0.05, 0.05)


func _place_vehicles(delta := 0.0) -> void:

	var face := -1.0 if layout_reversed else 1.0
	var speed_abs := absf(speed)
	if ai and ai_speed > 0.0:
		speed_abs = absf(ai_speed)
	var dt := clampf(delta, 0.0, 0.05)
	for i in range(vehicles.size()):
		var v: Vehicle = vehicles [i]
		var d := distance - face * _vehicle_offsets [i]
		var bd := v.bogie_spacing * 0.5
		var pf := pos_at(d + face * bd)
		var pr := pos_at(d - face * bd)
		var center :=(pf + pr) * 0.5
		var fwd :=(pf - pr)
		if fwd.length_squared() < 0.000001:
			fwd = route.tangent_at(d) * face
		fwd = fwd.normalized()
		var up := Vector3.UP - fwd * fwd.dot(Vector3.UP)
		if up.length_squared() < 0.000001:
			up = Vector3.UP
		up = up.normalized()
		var back := - fwd

		var vb := Basis(up.cross(back), up, back)
		if v.flip_model:
			vb = Basis(up, PI) * vb
		var f1 := (route.position_at(d + face * 8.0) - route.position_at(d)).normalized()
		var f2 := (route.position_at(d) - route.position_at(d - face * 8.0)).normalized()
		var curve := f1.signed_angle_to(f2, up)
		if dt <= 0.0:
			v.curve_smooth = curve

		_step_suspension(v, i, d, face, curve, gradient, speed_abs, dt)
		var roll := v.body_roll_dyn
		var pitch := v.body_pitch_dyn
		vb = vb * Basis(Vector3.BACK, roll) * Basis(Vector3.RIGHT, pitch)
		for bi in range(v.bogie_frames.size()):
			var frame_node: Node3D = v.bogie_frames [bi]
			if frame_node == null or not is_instance_valid(frame_node):
				continue
			frame_node.position.y = clampf(v.susp_y[bi] - v.body_bounce, -0.07, 0.07)
			frame_node.rotation.z = -roll * 0.72
			frame_node.rotation.x = -pitch * 0.82
			# Yaw the whole bogie (frame + wheelsets), not just the visible
			# frame. Each bogie follows the local track tangent at its own
			# centre, so the frame and axles stay rigidly bound together.
			var bogie_node := frame_node.get_parent() as Node3D
			if bogie_node != null:
				var local_z := bogie_node.position.z
				var bogie_d := d - face * local_z
				var track_fwd := route.tangent_at(bogie_d) * face
				var body_flat := Vector3(fwd.x, 0.0, fwd.z)
				var track_flat := Vector3(track_fwd.x, 0.0, track_fwd.z)
				if body_flat.length_squared() > 0.000001 and track_flat.length_squared() > 0.000001:
					bogie_node.rotation.y = body_flat.normalized().signed_angle_to(
							track_flat.normalized(), Vector3.UP)
				frame_node.rotation.y = 0.0
			else:
				frame_node.rotation.y = -curve * 4.0
		v.global_transform = Transform3D(vb, center + up * v.body_bounce)

func _spin(delta_dist: float) -> void:
	for v in vehicles:
		v.spin_wheels(delta_dist)




func head_position() -> Vector3:
	if route == null:
		return Vector3.ZERO
	return pos_at(distance)


func visual_distance() -> float:
	# Interpolate between the last two physics positions so camera/view updates
	# in _process match the rendered, physics-interpolated train.
	if route == null:
		return distance
	var dd := distance - _prev_distance
	if route.closed and absf(dd) > route.total * 0.5:
		dd -= signf(dd) * route.total
	return route.wrap_dist(_prev_distance + dd * Engine.get_physics_interpolation_fraction())


func head_position_visual() -> Vector3:
	return pos_at(visual_distance())


func place() -> void:
	for v in vehicles:
		if is_instance_valid(v):
			v.reset_suspension()
	_place_vehicles(0.0)
	_prev_distance = distance
	for v in vehicles:
		if is_instance_valid(v):
			v.reset_physics_interpolation()


func _cab_anchor(v: Vehicle) -> Vector3:
	var anchor := v.cab_anchor
	if anchor == Vector3.ZERO:
		anchor = Vector3(-0.75, 2.52, - v.length * 0.5 + 3.0)
	if reverser < 0 and not v.flip_model and vehicles.size() > 1:
		anchor = Vector3(- anchor.x, anchor.y, - anchor.z)
	return anchor


func cab_position() -> Vector3:
	var v: Vehicle = _cab_vehicle()
	if v == null:
		return head_position()
	return v.global_transform * _cab_anchor(v)


func cab_position_interpolated() -> Vector3:
	var v: Vehicle = _cab_vehicle()
	if v == null:
		return head_position_visual()
	if not v.is_inside_tree():
		return cab_position()
	return v.get_global_transform_interpolated() * _cab_anchor(v)


func cab_basis() -> Basis:
	var v: Vehicle = _cab_vehicle()
	if v == null:
		return Basis()
	return v.global_transform.basis


func step_ai(delta: float) -> void:
	if route == null or vehicles.is_empty():
		return
	_prev_distance = distance
	var dd := ai_speed * delta
	distance = route.wrap_dist(distance - dd)
	_place_vehicles(delta)
	_spin(- dd)


func update_cab_and_doors(delta: float) -> void:
	var target := 1.0 if doors_open else 0.0
	if absf(door_anim - target) > 0.001:
		# Slower plug-door motion: the leaf eases out, then glides along the
		# body side instead of snapping open.
		door_anim = move_toward(door_anim, target, delta * 0.26)
		var cab_v := _cab_vehicle()
		for v in vehicles:
			if v.door_leaves.is_empty():
				continue
			var ratio := door_anim
			if cab_door_only and v != cab_v:
				ratio = 0.0
			v.apply_doors(ratio, door_open_side)
	for cv in vehicles:
		if cv == null or cv.cab_parts.is_empty():
			continue
		var needle: Node3D = cv.cab_parts.get("needle")
		if needle != null:
			var frac := clampf(speed_kmh() / 200.0, 0.0, 1.0)
			needle.rotation.z = deg_to_rad(150.0 - frac * 300.0)
		var lbl: Label3D = cv.cab_parts.get("speed_label")
		if lbl != null:
			lbl.text = "%d" %int(round(speed_kmh()))
		var th: Node3D = cv.cab_parts.get("thrust")
		if th != null:
			th.rotation.x = deg_to_rad(-26.0) + deg_to_rad(float(notch) / 8.0 * 22.0)
		var br: Node3D = cv.cab_parts.get("brake")
		if br != null:
			br.rotation.x = deg_to_rad(-26.0) + deg_to_rad(float(brake_notch) / 7.0 * 22.0)

func _cab_vehicle() -> Vehicle:
		if vehicles.is_empty():
			return null
		if lead_cab_only:
			for v in vehicles:
				if v.cab_anchor != Vector3.ZERO:
					return v
			return vehicles[0]
		var step := -1 if reverser < 0 else 1
		var start := vehicles.size() - 1 if reverser < 0 else 0
		for i in range(start, vehicles.size() if step > 0 else -1, step):
			if vehicles [i].cab_anchor != Vector3.ZERO:
				return vehicles [i]
		return vehicles [start]

func speed_kmh() -> float:
	return absf(speed) * 3.6
