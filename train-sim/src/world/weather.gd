extends Node3D
class_name WeatherSystem


var env: Environment
var sun: DirectionalLight3D
var train: Train

var kind := "clear"
var label := "晴朗"
var intensity := 0.0
var target_intensity := 0.0
var wetness := 0.0
var light_scale := 1.0
var rain_amount := 0.0
var snow_amount := 0.0
var tunnel := false

var rain: GPUParticles3D
var snow: GPUParticles3D
var _cycle := 150.0
var _rng := RandomNumberGenerator.new()


func setup(p_env: Environment, p_sun: DirectionalLight3D, p_train: Train) -> void:
	env = p_env
	sun = p_sun
	train = p_train
	_rng.seed = 90317
	rain = _make_rain()
	snow = _make_snow()
	set_weather("clear", true)


func _make_rain() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Rain"
	p.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	p.amount = 1150
	p.lifetime = 1.15
	p.preprocess = 1.1
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-120, -60, -120), Vector3(240, 120, 240))
	var quad := QuadMesh.new()
	quad.size = Vector2(0.034, 0.92)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.62, 0.75, 0.94, 0.58)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.disable_receive_shadows = true
	quad.material = mat
	p.draw_pass_1 = quad
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(72, 26, 72)
	pm.direction = Vector3(0.06, -1.0, 0.03)
	pm.spread = 3.0
	pm.initial_velocity_min = 19.0
	pm.initial_velocity_max = 29.0
	pm.gravity = Vector3(0, -9.8, 0)
	pm.scale_min = 0.75
	pm.scale_max = 1.25
	p.process_material = pm
	add_child(p)
	p.emitting = false
	return p


func _make_snow() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Snow"
	p.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	p.amount = 720
	p.lifetime = 9.0
	p.preprocess = 4.0
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-120, -60, -120), Vector3(240, 120, 240))
	var quad := QuadMesh.new()
	quad.size = Vector2(0.075, 0.075)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.92, 0.96, 1.0, 0.82)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.disable_receive_shadows = true
	quad.material = mat
	p.draw_pass_1 = quad
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(68, 24, 68)
	pm.direction = Vector3(0.18, -1.0, 0.08)
	pm.spread = 22.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 2.6
	pm.gravity = Vector3(0.5, -0.8, 0.3)
	pm.scale_min = 0.55
	pm.scale_max = 1.35
	p.process_material = pm
	add_child(p)
	p.emitting = false
	return p


func set_weather(w: String, instant := false) -> void:
	kind = w
	label = _label_for(w)
	target_intensity = 0.0 if w == "clear" or w == "cloudy" else 1.0
	if instant:
		intensity = target_intensity
		wetness = target_intensity if w == "rain" else 0.0
		_apply_visuals()


func cycle_weather() -> void:
	var order := ["clear", "cloudy", "rain", "fog", "snow"]
	var i := order.find(kind)
	set_weather(order [(i + 1) % order.size()])


func _label_for(w: String) -> String:
	match w:
		"rain":
			return "降雨"
		"fog":
			return "浓雾"
		"snow":
			return "降雪"
		"cloudy":
			return "多云"
		_:
			return "晴朗"


func update(delta: float) -> void:
	if env == null:
		return
	_cycle -= delta
	if _cycle <= 0.0:
		_cycle = _rng.randf_range(170.0, 300.0)
		var pool := ["clear", "clear", "cloudy", "rain", "rain", "fog", "snow"]
		set_weather(pool [_rng.randi_range(0, pool.size() - 1)])
	intensity = move_toward(intensity, target_intensity, delta * 0.09)
	var wet_target := 0.0
	if kind == "rain":
		wet_target = intensity
	elif kind == "fog" or kind == "snow":
		wet_target = intensity * 0.35
	wetness = move_toward(wetness, wet_target, delta * 0.035)
	rain_amount = intensity if kind == "rain" and not tunnel else 0.0
	snow_amount = intensity if kind == "snow" and not tunnel else 0.0
	light_scale = 1.0
	if kind == "rain":
		light_scale = 1.0 - intensity * 0.42
	elif kind == "fog":
		light_scale = 1.0 - intensity * 0.28
	elif kind == "snow":
		light_scale = 1.0 - intensity * 0.16
	elif kind == "cloudy":
		light_scale = 0.88
	_apply_visuals()
	var cam := get_viewport().get_camera_3d()
	var anchor := Vector3.ZERO
	if cam != null:
		anchor = cam.global_position
	elif train != null:
		anchor = train.head_position()
	rain.global_position = anchor + Vector3(0, 20, 0)
	snow.global_position = anchor + Vector3(0, 18, 0)


func _apply_visuals() -> void:
	if rain != null:
		rain.emitting = rain_amount > 0.04
		rain.visible = rain_amount > 0.02
		rain.amount_ratio = clampf(rain_amount, 0.0, 1.0)
	if snow != null:
		snow.emitting = snow_amount > 0.04
		snow.visible = snow_amount > 0.02
		snow.amount_ratio = clampf(snow_amount, 0.0, 1.0)
	var fog := 0.0007
	if kind == "rain":
		fog = 0.0007 + intensity * 0.0018
	elif kind == "fog":
		fog = 0.0007 + intensity * 0.0062
	elif kind == "snow":
		fog = 0.0007 + intensity * 0.0020
	elif kind == "cloudy":
		fog = 0.0010
	env.fog_density = fog
	env.fog_light_color = Color(0.64, 0.69, 0.76).lerp(Color(0.48, 0.54, 0.63), intensity)
	env.fog_sky_affect = 0.2 + intensity * 0.42
	env.adjustment_saturation = 1.0 - intensity * 0.22
