extends Node3D
class_name Game


signal request_menu
signal request_restart


static var hidden_parts := {}

static var probe_forward := false

const NEAR_SIZE := 24000.0
const NEAR_DIV := 900
const OUTER_SIZE := 48000.0
const OUTER_DIV := 220
const TERRAIN_CENTER := Vector2(0.0, 0.0)
const TuningPanelScript = preload("res://src/ui/tuning_panel.gd")
const ConsistPanelScript = preload("res://src/ui/consist_panel.gd")
const AutopilotPanelScript = preload("res://src/ui/autopilot_panel.gd")

const STATION_ANCHORS := [
	Vector3(-2600, 28, 0),
	Vector3(820, 16, -2220),
	Vector3(-220, 84, 2220),
	Vector3(2660, 38, 1200),
	Vector3(-1840, 26, -1200),
	Vector3(1820, 20, -1940),
]


const CAREER_ALL_OWNED := ["container", "hopper"]
const CAREER_LEVEL_XP := [0, 900, 2400, 4800, 8200, 12500]
const CAREER_CATALOG := [
	{"id": "container", "name": "HXD1 集装箱货列", "kind": "container", "price": 0, "level": 1,
		"desc": "HXD1 电力机车 + 8 辆集装箱平车"},
	{"id": "hopper", "name": "HXD1 空车货列", "kind": "hopper", "price": 0, "level": 1,
		"desc": "HXD1 电力机车 + 8 辆空敞车"},
	{"id": "passenger", "name": "HXD1 旅客列车", "kind": "passenger", "price": 48000, "level": 3,
		"desc": "HXD1 电力机车 + 6 节 25T 载客车厢"},
]

# Hand-authored jobs shown in the mission centre. Quick jobs remain random;
# these presets are stable, have a fixed train type and are also used by QA.
const PRESET_MISSIONS := [
	{"id": "p1", "title": "山川港集装箱", "number": "X1001", "kind": "container",
		"cargo": "集装箱", "unit": "t", "loaded": true, "weight": 760.0,
		"origin": 0, "dest": 1, "limit": 85.0, "load_time": 24.0,
		"unload_time": 18.0, "reward": 7200.0, "time_limit": 2400.0},
	{"id": "p2", "title": "临江空车回送", "number": "X1002", "kind": "hopper",
		"cargo": "空车皮", "unit": "t", "loaded": false, "weight": 300.0,
		"origin": 1, "dest": 2, "limit": 90.0, "load_time": 8.0,
		"unload_time": 7.0, "reward": 5200.0, "time_limit": 2100.0},
	{"id": "p3", "title": "青川城际旅客", "number": "K1003", "kind": "passenger",
		"cargo": "旅客", "unit": "人", "loaded": true, "weight": 708.0,
		"origin": 2, "dest": 3, "limit": 120.0, "load_time": 30.0,
		"unload_time": 28.0, "reward": 9800.0, "time_limit": 1800.0},
	{"id": "p4", "title": "雁归建材专列", "number": "X1004", "kind": "container",
		"cargo": "集装箱", "unit": "t", "loaded": true, "weight": 760.0,
		"origin": 3, "dest": 4, "limit": 80.0, "load_time": 24.0,
		"unload_time": 18.0, "reward": 5600.0, "time_limit": 2200.0},
	{"id": "p5", "title": "青石—云溪小运转", "number": "K1005", "kind": "passenger",
		"cargo": "旅客", "unit": "人", "loaded": true, "weight": 708.0,
		"origin": 4, "dest": 5, "limit": 100.0, "load_time": 24.0,
		"unload_time": 22.0, "reward": 6200.0, "time_limit": 1500.0},
	{"id": "p6", "title": "云溪—石门空车", "number": "X1006", "kind": "hopper",
		"cargo": "空车皮", "unit": "t", "loaded": false, "weight": 300.0,
		"origin": 5, "dest": 6, "limit": 80.0, "load_time": 8.0,
		"unload_time": 7.0, "reward": 3600.0, "time_limit": 1500.0},
	{"id": "p7", "title": "石门—山川环线集装箱", "number": "X1007", "kind": "container",
		"cargo": "集装箱", "unit": "t", "loaded": true, "weight": 760.0,
		"origin": 6, "dest": 0, "limit": 85.0, "load_time": 24.0,
		"unload_time": 18.0, "reward": 7800.0, "time_limit": 2400.0},
	{"id": "p8", "title": "山川—青川直通旅客", "number": "K1008", "kind": "passenger",
		"cargo": "旅客", "unit": "人", "loaded": true, "weight": 708.0,
		"origin": 0, "dest": 2, "limit": 120.0, "load_time": 30.0,
		"unload_time": 28.0, "reward": 11000.0, "time_limit": 2400.0},
]

const RIVER := [
	Vector2(2496.0, -656.0),
	Vector2(1984.0, -336.0),
	Vector2(1440.0, 0.0),
	Vector2(922.0, 362.0),
	Vector2(410.0, 666.0),
	Vector2(-186.0, 934.0),
	Vector2(-851.0, 1168.0),
	Vector2(-1517.0, 1379.0),
	Vector2(-2291.0, 1590.0),
]

var route: Route
var terrain: Terrain
var railway: Railway
var train: Train
var rig: CameraRig
var hud: HUD
var mission: MissionSystem
var audio: TrainAudio
var weather: WeatherSystem
var map_view: MapView
var ai_train: Train
var tasks_cache: Array = []
var siding: Dictionary = {}
var siding_latched := false
var sidings: Array = []
var selected_siding := -1
var active_siding := -1
var mission_siding: Dictionary = {}
var autopilot := false
var autopilot_target := -1
var autopilot_stop := 0.0
var _autopilot_accum := 0.0
var autopilot_verbose := false
var autopilot_panel
var paused := false
var _ai_horn_cooldown := 0.0
var station_data: Array = []
var settlement_sites: Array = []
var settlements: Array = []
var hall_spots: Array = []
var hall_gates: Array = []
var hall_belts: Array = []
var hall_ticket_until := 0.0
var coffee_until := 0.0
var free_drive := false
var _free_resume_job: Dictionary = {}
var station_lights: Array [OmniLight3D] = []
var reflection_probe: ReflectionProbe
var _probe_accum := 0.0
var lakes: Array = []
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var world_env: WorldEnvironment
var sky_mat: ShaderMaterial
var postfx_mat: ShaderMaterial
var time_of_day := 9.4
var stats := {}
var start_kind := "container"
var engine_id := "standard"
var skin_id := "classic"
var transmission_id := "balanced"
var part_ids: Array[String] = []
var mode := "open"
var career: Dictionary = {}
var current_job: Dictionary = {}
var career_panel: CareerPanel
var tuning_panel
var consist_panel
var custom_cars: Array[String] = []
var custom_loco_count := 1
var custom_loaded := true
var _consist_return := "pause"
var start_distance := -1.0
var _pending_career_result: Dictionary = {}

var train_def: TrainDef
var startup: TrainStartup
var interaction: CabInteraction
var dev_panel: DevPanel
var pause_menu: PauseMenu
var _hover_text := ""
var slot_id := ""
var slot_name := "存档"
var initial_state: Dictionary = {}
var _autosave_accum := 0.0
var _map_paused := false
var _prev_mission_phase := -1
var _time_accum := 0.0
static var startup_test := false
static var show_dev := false
static var open_map_at_start := false
static var forced_weather := ""
var _overspeed_toast := 0.0

signal build_progress(value: float, text: String)
signal build_finished
var async_build := false

func _exit_tree() -> void:
	Vehicles.clear_bogie_templates()


func _ready() -> void:
	if async_build:
		_run_async_build()
		return
	var stage_t := Time.get_ticks_msec()
	var t0 := Time.get_ticks_msec()
	_setup_environment()
	print("[stage] %s %d ms" %["_setup_environment()", Time.get_ticks_msec() - stage_t]); stage_t = Time.get_ticks_msec()
	_build_route()
	print("[stage] %s %d ms" %["_build_route()", Time.get_ticks_msec() - stage_t]); stage_t = Time.get_ticks_msec()
	if not _skip("terrain"):
		_build_terrain()
	print("[stage] terrain %d ms" %[Time.get_ticks_msec() - stage_t]); stage_t = Time.get_ticks_msec()
	if not _skip("railway"):
		_build_railway()
	print("[stage] railway %d ms" %[Time.get_ticks_msec() - stage_t]); stage_t = Time.get_ticks_msec()
	if not _skip("vegetation"):
		_build_vegetation()
	print("[stage] %s %d ms" %["_build_vegetation()", Time.get_ticks_msec() - stage_t]); stage_t = Time.get_ticks_msec()
	if not _skip("stations") and not _wants_test_mode():
		_build_stations()
	print("[stage] %s %d ms" %["_build_stations()", Time.get_ticks_msec() - stage_t]); stage_t = Time.get_ticks_msec()
	if not _wants_test_mode():
		_setup_siding()
	print("[stage] siding %d ms" %[Time.get_ticks_msec() - stage_t]); stage_t = Time.get_ticks_msec()
	if not _skip("railway") and not _skip("signals") and not _wants_test_mode():
		railway.build_signals(station_data)
	_prepare_mode_state()
	if not _skip("train"):
		_build_train()
	print("[stage] %s %d ms" %["_build_train()", Time.get_ticks_msec() - stage_t]); stage_t = Time.get_ticks_msec()
	_setup_weather()
	_setup_audio()
	_setup_camera()
	_setup_hud()
	_setup_mission()
	_setup_map()
	_setup_debug()
	_setup_pause()
	_setup_postfx()
	print("[stage] %s %d ms" %["_setup_postfx()", Time.get_ticks_msec() - stage_t]); stage_t = Time.get_ticks_msec()
	_apply_time()
	if startup != null and not startup_test and initial_state.is_empty() and not UserSettings.cold_start:
		startup.prepare_for_service()
	if not initial_state.is_empty():
		apply_save_data(initial_state)
	stats ["build_ms"] = Time.get_ticks_msec() - t0
	print("[game] 世界生成完成 %.1f 秒 | 线路 %.2f km | 车辆 %d | 隐藏=%s" %[
		float(stats ["build_ms"]) / 1000.0, route.total / 1000.0,
		train.vehicles.size() if train != null else 0, str(hidden_parts.keys())
	])
	if train != null:
		print("[game] head=%s  stationA=%s  stationB=%s" %[
			train.head_position(), position_at_station(0), position_at_station(1)
		])
	if probe_forward:
		await get_tree().process_frame
		await get_tree().process_frame
		await _probe_forward_view()
	if startup_test and startup != null:
		await _run_startup_test()
	if open_map_at_start and map_view != null:
		open_full_map()


func _emit_build(value: float, text: String) -> void:
	build_progress.emit(clampf(value, 0.0, 1.0), text)


func _run_async_build() -> void:
	var t0 := Time.get_ticks_msec()
	var stage_t := t0
	_emit_build(0.01, "正在准备世界")
	await get_tree().process_frame
	_setup_environment()
	_emit_build(0.04, "正在生成环线")
	await get_tree().process_frame
	_build_route()
	print("[stage] route %d ms" %[Time.get_ticks_msec() - stage_t]); stage_t = Time.get_ticks_msec()
	await get_tree().process_frame

	if not _skip("terrain"):
		_emit_build(0.08, "正在铺设地形基础")
		_prepare_terrain()
		print("[stage] terrain-prep %d ms" %[Time.get_ticks_msec() - stage_t]); stage_t = Time.get_ticks_msec()
		await get_tree().process_frame
		var terrain_cb := func(p: float) -> void:
			_emit_build(0.10 + 0.34 * p, "正在生成地形网格")
		var near: MeshInstance3D = await terrain.build_mesh_async(NEAR_SIZE, _near_divisions(), Gfx.terrain(), TERRAIN_CENTER, terrain_cb)
		terrain.add_child(near)
		_emit_build(0.46, "正在生成远景地形")
		await get_tree().process_frame
		var outer_cb := func(p: float) -> void:
			_emit_build(0.46 + 0.04 * p, "正在生成远景地形")
		var outer: MeshInstance3D = await terrain.build_outer_mesh_async(NEAR_SIZE, OUTER_SIZE, _outer_divisions(), Gfx.terrain(), outer_cb)
		terrain.add_child(outer)
		terrain.add_child(terrain.build_water(30.0, Gfx.water()))
		for l: Dictionary in lakes:
			terrain.add_child(terrain.build_lake(l ["center"], float(l ["radius"]), float(l ["level"]), Gfx.water()))
		_finish_terrain_stats()
		print("[stage] terrain-mesh %d ms" %[Time.get_ticks_msec() - stage_t]); stage_t = Time.get_ticks_msec()

	_emit_build(0.50, "正在铺设轨道")
	await get_tree().process_frame
	if not _skip("railway"):
		railway = Railway.new()
		railway.name = "Railway"
		add_child(railway)
		railway.setup(route)
		railway.terrain = terrain
		await railway.build_track(3.0, true)
		_emit_build(0.54, "正在架设接触网")
		await get_tree().process_frame
		await railway.build_catenary(55.0, true)
		if not _wants_test_mode():
			railway.build_tunnels()
			railway.build_bridges()
			railway.build_viaducts()
		stats ["track_km"] = route.total / 1000.0
	print("[stage] railway %d ms" %[Time.get_ticks_msec() - stage_t]); stage_t = Time.get_ticks_msec()
	await get_tree().process_frame

	_emit_build(0.59, "正在种植树木")
	await get_tree().process_frame
	if not _skip("vegetation"):
		await _build_vegetation(true)
	print("[stage] vegetation %d ms" %[Time.get_ticks_msec() - stage_t]); stage_t = Time.get_ticks_msec()
	await get_tree().process_frame

	_emit_build(0.64, "正在建设车站与城镇")
	await get_tree().process_frame
	if not _skip("stations") and not _wants_test_mode():
		await _build_stations_async()
	print("[stage] stations %d ms" %[Time.get_ticks_msec() - stage_t]); stage_t = Time.get_ticks_msec()

	_emit_build(0.83, "正在布置站场")
	await get_tree().process_frame
	if not _wants_test_mode():
		_setup_siding()
	if not _skip("railway") and not _skip("signals") and not _wants_test_mode():
		railway.build_signals(station_data)

	_emit_build(0.87, "正在编组列车")
	await get_tree().process_frame
	_prepare_mode_state()
	if not _skip("train"):
		_build_train()
	print("[stage] train %d ms" %[Time.get_ticks_msec() - stage_t]); stage_t = Time.get_ticks_msec()

	_emit_build(0.91, "正在准备天空与音效")
	await get_tree().process_frame
	_setup_weather()
	_setup_audio()
	_setup_camera()
	_setup_hud()
	_setup_mission()
	_setup_map()
	_setup_debug()
	_setup_pause()
	_setup_postfx()
	print("[stage] ui/weather %d ms" %[Time.get_ticks_msec() - stage_t]); stage_t = Time.get_ticks_msec()
	_apply_time()
	if startup != null and not startup_test and initial_state.is_empty() and not UserSettings.cold_start:
		startup.prepare_for_service()
	if not initial_state.is_empty():
		apply_save_data(initial_state)
	stats ["build_ms"] = Time.get_ticks_msec() - t0
	print("[game] 世界生成完成 %.1f 秒 | 线路 %.2f km | 车辆 %d" %[
		float(stats ["build_ms"]) / 1000.0, route.total / 1000.0,
		train.vehicles.size() if train != null else 0
	])
	if open_map_at_start and map_view != null:
		open_full_map()
	_emit_build(1.0, "准备完成")
	await get_tree().process_frame
	build_finished.emit()


func _build_stations_async() -> void:
	station_data.clear()
	var total := maxi(1, Config.STATIONS.size())
	for i in range(Config.STATIONS.size()):
		var info: Dictionary = Config.STATIONS [i]
		var d := Config.station_dist(route, i)
		var side := float(info.get("settlement_side", -1.0 if i % 2 == 0 else 1.0))
		var stop := route.wrap_dist(d + 55.0)
		var freight := bool(info.get("freight", false))
		var station := {
			"name": info ["name"],
			"dist": d,
			"stop": stop,
			"side": side,
			"freight": freight,
			"settlement": String(info.get("settlement", "halt")),
			"population": int(info.get("population", 0)),
			"branch": bool(info.get("branch", false)),
			"index": i,
		}
		station_data.append(station)
		var platform_len := float(info.get("platform_len", 220.0))
		var settlement := String(station["settlement"])
		if settlement == "city":
			platform_len = maxf(platform_len, 420.0)
		elif settlement == "town":
			platform_len = maxf(platform_len, 300.0)
		else:
			platform_len = maxf(platform_len, 240.0)
		station ["platform_len"] = platform_len
		station ["platform_lat"] = 4.6
		station ["platform_top"] = 1.02 if freight else 1.1
		station ["platform_half"] = 2.9
		station ["hall_lat_in"] = 10.0
		station ["hall_lat_out"] = 26.0
		station ["hall_half"] = 19.0
		station ["hall_entry_half"] = 4.8
		station ["hall_top"] = float(station ["platform_top"])
		if freight:
			# The goods yard sits opposite the passenger platform, next to
			# the sidings, so it does not collide with the station hall.
			station ["yard_lat"] = -17.0
			station ["yard_half"] = 6.5
			station ["yard_len"] = clampf(platform_len * 0.65, 80.0, 150.0)
			station ["yard_top"] = 0.26
		await _build_station(d, info ["name"], side, freight, platform_len, settlement, i, true)
		_build_stop_mark(stop, side, info ["name"])
		if freight:
			station_data [i] ["hoist"] = _build_freight_yard(d, -side, info ["name"], platform_len)
		if String(station ["settlement"]) != "halt":
			await _build_settlement(station, true)
		_emit_build(0.64 + 0.18 * float(i + 1) / float(total), "正在建设 %s" %info ["name"])
		await get_tree().process_frame


func _setup_debug() -> void:
	dev_panel = DevPanel.new()
	dev_panel.name = "DevPanel"
	add_child(dev_panel)
	dev_panel.setup(self)
	dev_panel.visible = show_dev
	if train != null and rig != null:
		interaction = CabInteraction.new()
		interaction.name = "CabInteraction"
		add_child(interaction)
		interaction.setup(train, rig.camera, _on_device_action, func(t): hud.toast(t, 2.2))
		interaction.hover_changed.connect(_on_hover_changed)

func _on_hover_changed(_id: String, text: String, description: String = "") -> void:
	_hover_text = text
	if hud != null:
		hud.show_device_hover(text, description)


func _on_device_action(id: String, value: float) -> String:
	if startup == null:
		return ""
	if id == "doors":
		return _toggle_doors()
	if id == "cab_door_left":
		return _toggle_cab_door(-1)
	if id == "cab_door_right":
		return _toggle_cab_door(1)
	if id == "autopilot":
		open_autopilot()
		return ""
	if id == "high_beam":
		_toggle_high_beam()
		return ""
	var msg := startup.press(id, value)
	if id == "horn" and audio != null:
		audio.blast()
	return msg


func _try(_label: String, msg: String) -> void:
	if msg.begins_with("✗") and hud != null:
		hud.toast(msg, 2.4)


func _update_startup_visuals(delta: float) -> void:
	if train == null or startup == null:
		return
	var want := 0.0 if startup.panto_up else 1.3
	for v in train.vehicles:
		for p in v.pantographs:
			var arm := p.get_node_or_null("PantographArm")
			if arm is Node3D:
				arm.rotation.x = lerpf(arm.rotation.x, want, clampf(delta * 1.8, 0.0, 1.0))
		var lamp := v.find_child("CabLight", true, false)
		if lamp is OmniLight3D:
			lamp.visible = startup.cab_light_on and startup.instruments_live()
	var cv := train._cab_vehicle()
	if cv != null:
		var wp := cv.cab_parts.get("wiper") as Node3D
		if wp != null:
			var target := 0.62 * sin(Time.get_ticks_msec() * 0.0042) if startup.wiper_on else 0.0
			wp.rotation.z = lerpf(wp.rotation.z, target, clampf(delta * 10.0, 0.0, 1.0))


func _run_startup_test() -> void:
	print("[startup-test] 初始：%s" %startup.state_name())
	print("[startup-test] 联锁测试（未升弓就闭合主断）：%s" %startup.press("vcb"))
	print("[startup-test]   状态=%s（应为 故障）" %startup.state_name())
	print("[startup-test] 复位：%s" %startup.press("reset"))
	print("[startup-test] 主电源：%s" %startup.press("battery"))
	await get_tree().create_timer(0.3).timeout
	print("[startup-test]   状态=%s | 受电弓=%s | 主断=%s | 停放制动=%s | hint=%s" %[
		startup.state_name(), str(startup.panto_up), str(startup.vcb_on),
		"施加" if startup.park_brake else "缓解", startup.hint()])

	var waited := 0.0
	while train.doors_open and waited < 120.0:
		await get_tree().create_timer(0.5).timeout
		waited += 0.5
	print("[startup-test] 乘降结束等待 %.1f s，车门=%s" %[waited, "开" if train.doors_open else "关"])

	waited = 0.0
	while train.brake_cylinder > 0.2 and waited < 20.0:
		await get_tree().create_timer(0.5).timeout
		waited += 0.5
	print("[startup-test] 制动缓解完成（管压 %.2f bar）" %train.brake_cylinder)
	print("[startup-test] 牵引：%s" %startup.set_thrust(0.25))
	await get_tree().create_timer(8.0).timeout
	print("[startup-test] 起步 8 s 后：状态=%s 速度=%.2f km/h 牵引力=%.0f kN" %[
		startup.state_name(), train.speed * 3.6, train.tractive_force_n / 1000.0])
	print("[startup-test] 结束：状态=%s 牵引许可=%s" %[startup.state_name(), str(startup.can_traction())])
	get_tree().quit()


func _probe_forward_view() -> void:
	if rig != null and rig.mode != CameraRig.Mode.CAB:
		rig.set_mode(CameraRig.Mode.CAB)
		await get_tree().process_frame
		await get_tree().process_frame
	var cam: Camera3D = rig.camera if rig != null else null
	var eye: Vector3 = train.cab_position()
	var fwd: Vector3 =(- train.cab_basis().z).normalized()
	if cam != null and cam.is_inside_tree():
		eye = cam.global_position
		fwd =(- cam.global_transform.basis.z).normalized()
	print("[probe] cam=%s  eye=(%.2f, %.2f, %.2f)  fwd=(%.3f, %.3f, %.3f)  reverser=%.0f  cab_veh=%d" %[
		str(cam != null), eye.x, eye.y, eye.z, fwd.x, fwd.y, fwd.z, train.reverser,
		train.vehicles.find(train._cab_vehicle()) if train._cab_vehicle() != null else -1
	])
	var hits := []
	for n: Node in get_tree().root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var inv := mi.global_transform.affine_inverse()
		var lo := inv * eye
		var ld :=(inv.basis * fwd).normalized()
		var d := _ray_box(lo, ld, mi.get_aabb())
		if d < 0.0 or d > 20.0:
			continue
		hits.append({"n": mi, "d": d, "lp": lo + ld * d})
	hits.sort_custom(func(x, y): return float(x ["d"]) < float(y ["d"]))
	for h in hits:
		var mi: MeshInstance3D = h ["n"]
		var par := mi.get_parent()
		var lp: Vector3 = h ["lp"]
		var ab := mi.get_aabb()
		var mat_name := "-"
		if mi.material_override is StandardMaterial3D:
			var c: Color =(mi.material_override as StandardMaterial3D).albedo_color
			mat_name = "(%.2f,%.2f,%.2f,a%.2f)" %[c.r, c.g, c.b, c.a]
		print("  %6.2fm  %-22s parent=%-14s hit=(%.2f,%.2f,%.2f)  aabb=%s pos=%s mat=%s" %[
			h ["d"], mi.name, par.name if par != null else "-", lp.x, lp.y, lp.z,
			ab.size, ab.position, mat_name
		])
	print("[probe] 视线命中 %d 个网格（20m 内）" %hits.size())
	for i in range(train.vehicles.size()):
		var vv: Vehicle = train.vehicles [i]
		var gp := vv.global_position
		print("[probe] veh%d %-10s pos=(%.1f, %.1f, %.1f) flip=%s" %[
			i, vv.name, gp.x, gp.y, gp.z, str(vv.flip_model)])


func _ray_box(o: Vector3, d: Vector3, box: AABB) -> float:
	var tmin := -1000000000.0
	var tmax := 1000000000.0
	for i in range(3):
		var oi := o [i]
		var di := d [i]
		var bmin := box.position [i]
		var bmax := box.position [i] + box.size [i]
		if absf(di) < 0.000001:
			if oi < bmin or oi > bmax:
				return -1.0
		else:
			var t1 :=(bmin - oi) / di
			var t2 :=(bmax - oi) / di
			if t1 > t2:
				var tmp := t1
				t1 = t2
				t2 = tmp
			tmin = maxf(tmin, t1)
			tmax = minf(tmax, t2)
			if tmin > tmax:
				return -1.0
	if tmax < 0.0:
		return -1.0
	return maxf(tmin, 0.0)

func _skip(part: String) -> bool:
	return hidden_parts.has(part)


func _near_divisions() -> int:
	if Config.quality <= Config.Quality.LOW:
		return 540
	if Config.quality == Config.Quality.MEDIUM:
		return 720
	return NEAR_DIV


func _outer_divisions() -> int:
	if Config.quality <= Config.Quality.LOW:
		return 138
	if Config.quality == Config.Quality.MEDIUM:
		return 184
	return OUTER_DIV

func position_at_station(i: int) -> Vector3:
	if route == null:
		return Vector3.ZERO
	if i >= 0 and i < station_data.size():
		return route.position_at(float(station_data [i] ["dist"]))
	return route.position_at(Config.station_dist(route, i))



func _setup_environment() -> void:
	world_env = WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	sky.sky_material = _sky_material()
	sky.radiance_size = Sky.RADIANCE_SIZE_512
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 5.5
	env.ssao_enabled = true
	env.ssao_radius = 1.5
	env.ssao_intensity = 1.0
	env.ssao_power = 1.6
	env.ssil_enabled = true
	env.ssil_intensity = 0.5
	env.glow_enabled = true
	env.glow_intensity = 0.32
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 1.15
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.7, 0.77, 0.86)
	env.fog_light_energy = 1.0
	env.fog_density = 0.0016
	env.fog_sky_affect = 0.25
	env.fog_aerial_perspective = 0.4
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.04
	env.volumetric_fog_enabled = false
	env.volumetric_fog_density = 0.012
	env.volumetric_fog_albedo = Color(0.86, 0.9, 0.97)
	env.volumetric_fog_emission = Color(0.0, 0.0, 0.0)
	env.volumetric_fog_emission_energy = 0.0
	env.volumetric_fog_anisotropy = 0.35
	env.volumetric_fog_length = 96.0
	env.volumetric_fog_detail_spread = 1.5
	env.volumetric_fog_gi_inject = 0.0
	env.volumetric_fog_ambient_inject = 0.1
	env.volumetric_fog_sky_affect = 1.0
	env.volumetric_fog_temporal_reprojection_enabled = true
	env.ssr_enabled = false
	env.ssr_max_steps = 48
	env.ssr_fade_in = 0.12
	env.ssr_fade_out = 0.85
	env.ssr_depth_tolerance = 0.12
	world_env.environment = env
	add_child(world_env)

	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = 1.3
	sun.light_color = Color(1.0, 0.97, 0.92)
	sun.light_angular_distance = 0.4
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 410.0
	sun.directional_shadow_blend_splits = true
	sun.shadow_blur = 1.15
	sun.shadow_bias = 0.08
	sun.shadow_normal_bias = 3.2
	sun.light_volumetric_fog_energy = 1.6
	add_child(sun)
	moon = DirectionalLight3D.new()
	moon.name = "Moon"
	moon.light_energy = 0.0
	moon.light_color = Color(0.55, 0.68, 1.0)
	moon.light_angular_distance = 0.5
	moon.shadow_enabled = false
	moon.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(moon)
	reflection_probe = ReflectionProbe.new()
	reflection_probe.name = "TrainReflectionProbe"
	reflection_probe.size = Vector3(90, 44, 90)
	reflection_probe.origin_offset = Vector3(0, 5, 0)
	reflection_probe.box_projection = true
	reflection_probe.interior = false
	reflection_probe.enable_shadows = true
	reflection_probe.max_distance = 240.0
	reflection_probe.update_mode = ReflectionProbe.UPDATE_ONCE
	add_child(reflection_probe)
	_configure_quality()


func apply_quality() -> void:
	_configure_quality()


func _configure_quality() -> void:
	if world_env == null or world_env.environment == null or sun == null:
		return
	var q := Config.quality
	var low := q == Config.Quality.LOW
	var env := world_env.environment
	# Low is deliberately a "integrated GPU / safe fps" preset: no screen
	# space effects, no bloom, no depth fog and no realtime sun shadows.
	env.ssao_enabled = q >= Config.Quality.MEDIUM
	env.ssao_radius = 1.5
	env.ssao_intensity = 1.3 if q >= Config.Quality.ULTRA else 1.0
	env.ssao_power = 1.6
	env.ssil_enabled = q >= Config.Quality.HIGH
	env.ssil_intensity = 0.5
	env.glow_enabled = q >= Config.Quality.MEDIUM
	env.glow_intensity = 0.42 if q >= Config.Quality.ULTRA else 0.32
	env.glow_bloom = 0.0 if low else 0.06
	env.fog_enabled = not low
	env.fog_density = 0.0007 if q >= Config.Quality.HIGH else 0.0011
	env.volumetric_fog_enabled = q >= Config.Quality.ULTRA
	env.volumetric_fog_density = 0.008
	env.ssr_enabled = q >= Config.Quality.HIGH
	if env.sky != null:
		env.sky.radiance_size = Sky.RADIANCE_SIZE_256 if low else Sky.RADIANCE_SIZE_512
	sun.light_volumetric_fog_energy = 1.6 if q >= Config.Quality.ULTRA else 0.0
	sun.shadow_enabled = q >= Config.Quality.MEDIUM
	sun.shadow_blur = 0.9 if q >= Config.Quality.MEDIUM else 1.4
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if q >= Config.Quality.HIGH else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 410.0 if q >= Config.Quality.HIGH else (185.0 if q >= Config.Quality.MEDIUM else 110.0)
	var vp := get_viewport()
	if vp == null:
		return
	vp.positional_shadow_atlas_size = 1024 if low else (2048 if q == Config.Quality.MEDIUM else 4096)
	vp.positional_shadow_atlas_16_bits = low or q == Config.Quality.MEDIUM
	if Upscaling.is_temporal(UserSettings.upscaler):
		# DLSS / FSR 2.2 already handle anti-aliasing during upscaling.
		vp.msaa_3d = Viewport.MSAA_DISABLED
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		return
	# Quality never changes the 3D render scale; the upscaler owns that.
	# Lower presets drop expensive lighting/reflection effects instead.
	match q:
		Config.Quality.LOW:
			vp.msaa_3d = Viewport.MSAA_DISABLED
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		Config.Quality.MEDIUM:
			vp.msaa_3d = Viewport.MSAA_DISABLED
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		Config.Quality.HIGH:
			vp.msaa_3d = Viewport.MSAA_2X
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		_:
			vp.msaa_3d = Viewport.MSAA_4X
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED


func _sky_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = "\nshader_type sky;\n\nuniform vec3 sky_top : source_color = vec3(0.13, 0.32, 0.72);\nuniform vec3 sky_horizon : source_color = vec3(0.70, 0.78, 0.86);\nuniform vec3 ground_color : source_color = vec3(0.40, 0.43, 0.44);\nuniform vec3 sun_tint : source_color = vec3(1.0, 0.93, 0.80);\nuniform vec3 cloud_hi : source_color = vec3(1.0, 0.99, 0.98);\nuniform vec3 cloud_lo : source_color = vec3(0.52, 0.57, 0.66);\nuniform float cloud_coverage = 0.50;\nuniform float cloud_softness = 0.22;\nuniform float cloud_scale = 2.6;\nuniform float cloud_opacity = 0.85;\nuniform float sun_energy = 0.8;\nuniform vec3 moon_dir = vec3(0.0, 0.5, 0.5);\nuniform float moon_energy = 0.0;\nuniform float star_energy = 0.0;\n\nfloat hash(vec2 p) {\n\treturn fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);\n}\n\nfloat vnoise(vec2 p) {\n\tvec2 i = floor(p);\n\tvec2 f = fract(p);\n\tf = f * f * (3.0 - 2.0 * f);\n\tfloat a = hash(i);\n\tfloat b = hash(i + vec2(1.0, 0.0));\n\tfloat c = hash(i + vec2(0.0, 1.0));\n\tfloat d = hash(i + vec2(1.0, 1.0));\n\treturn mix(mix(a, b, f.x), mix(c, d, f.x), f.y);\n}\n\nfloat fbm(vec2 p) {\n\tfloat v = 0.0;\n\tfloat amp = 0.5;\n\tfor (int i = 0; i < 5; i++) {\n\t\tv += amp * vnoise(p);\n\t\tp *= 2.03;\n\t\tamp *= 0.5;\n\t}\n\treturn v;\n}\n\nvoid sky() {\n\tfloat h = EYEDIR.y;\n\tvec3 col = mix(sky_horizon, sky_top, pow(clamp(h, 0.0, 1.0), 0.62));\n\t// 太阳\n\tif (h > 0.0 && star_energy > 0.001) {\n\t\tvec2 sp = EYEDIR.xz / max(h, 0.002);\n\t\tvec2 cell = floor(sp * 58.0);\n\t\tvec2 f = fract(sp * 58.0) - 0.5;\n\t\tfloat star = step(0.972, hash(cell)) * smoothstep(0.28, 0.02, length(f));\n\t\tfloat tw = 0.58 + 0.42 * sin(TIME * 1.7 + hash(cell + 7.0) * 23.0);\n\t\tcol += vec3(0.78, 0.88, 1.0) * star * tw * star_energy * smoothstep(0.0, 0.10, h);\n\t}\n\tfloat sd = clamp(dot(EYEDIR, normalize(LIGHT0_DIRECTION)), 0.0, 1.0);\n\tcol += sun_tint * (pow(sd, 1200.0) * 5.0 + pow(sd, 14.0) * 0.10) * sun_energy;\n\tfloat md = clamp(dot(EYEDIR, normalize(moon_dir)), 0.0, 1.0);\n\tcol += vec3(0.62, 0.74, 1.0) * (pow(md, 900.0) * 3.4 + pow(md, 24.0) * 0.08) * moon_energy;\n\tif (h > 0.002 && cloud_opacity > 0.001) {\n\t\tvec2 uv = EYEDIR.xz / max(h, 0.002) * 0.34;\n\t\tfloat n = fbm(uv * cloud_scale);\n\t\tfloat cover = smoothstep(cloud_coverage, cloud_coverage + cloud_softness, n);\n\t\tfloat fade = smoothstep(0.0, 0.16, h) * (1.0 - smoothstep(0.55, 1.0, h) * 0.35);\n\t\tfloat shade = fbm(uv * cloud_scale * 2.3 + vec2(3.7, 1.9));\n\t\tvec3 cc = mix(cloud_lo, cloud_hi, clamp(shade * 1.35, 0.0, 1.0));\n\t\tcol = mix(col, cc, cover * fade * cloud_opacity);\n\t} else {\n\t\tcol = mix(sky_horizon, ground_color, smoothstep(0.0, -0.10, h));\n\t}\n\tCOLOR = col;\n}\n"




























































	sky_mat = ShaderMaterial.new()
	sky_mat.shader = sh
	return sky_mat

func _apply_time() -> void:
	var t := clampf((time_of_day - 5.0) / 14.0, -0.2, 1.2)
	var elev := sin(clampf(t, 0.0, 1.0) * PI) * 66.0
	var azim := -100.0 + clampf(t, 0.0, 1.0) * 200.0
	sun.rotation_degrees = Vector3(- maxf(elev, -8.0), azim, 0.0)
	var day := clampf(sin(clampf(t, 0.0, 1.0) * PI) * 1.15, 0.0, 1.0)
	var warm := clampf(1.0 - minf(t, 1.0 - t) * 4.2, 0.0, 1.0) * day
	var weather_light := weather.light_scale if weather != null else 1.0
	sun.light_energy = (0.02 + day * 1.4) * weather_light

	var sun_tint := Color(0.7, 0.78, 1.0).lerp(Color(1.0, 0.97, 0.9), day)
	sun_tint = sun_tint.lerp(Color(1.0, 0.74, 0.46), warm * 0.8)
	sun.light_color = sun_tint
	if moon != null:
		moon.rotation_degrees = Vector3(- 42.0, azim + 180.0, 0.0)
		moon.light_energy = (1.0 - day) * 0.46
	var env := world_env.environment
	env.ambient_light_energy = (0.11 + day * 0.91) * (0.72 + 0.28 * weather_light)
	env.fog_light_color = Color(0.7, 0.77, 0.86).lerp(Color(0.12, 0.15, 0.24), 1.0 - day)
	env.adjustment_brightness = 0.7 + 0.34 * day
	if sky_mat != null:
		var top := Color(0.035, 0.055, 0.115).lerp(Color(0.13, 0.32, 0.72), day)
		var hor := Color(0.075, 0.09, 0.15).lerp(Color(0.7, 0.78, 0.86), day)
		hor = hor.lerp(Color(0.96, 0.62, 0.34), warm * 0.75)
		top = top.lerp(Color(0.28, 0.24, 0.44), warm * 0.35)
		sky_mat.set_shader_parameter("sky_top", top)
		sky_mat.set_shader_parameter("sky_horizon", hor)
		sky_mat.set_shader_parameter("ground_color", Color(0.05, 0.055, 0.065).lerp(Color(0.4, 0.43, 0.44), day))
		sky_mat.set_shader_parameter("cloud_hi", Color(0.3, 0.33, 0.42).lerp(Color(1.0, 0.99, 0.98), day).lerp(Color(1.0, 0.8, 0.62), warm * 0.6))
		sky_mat.set_shader_parameter("cloud_lo", Color(0.14, 0.16, 0.22).lerp(Color(0.52, 0.57, 0.66), day).lerp(Color(0.72, 0.46, 0.34), warm * 0.5))
		sky_mat.set_shader_parameter("sun_energy", 0.12 + 0.78 * day)
		var sun_glow := Color(1.0, 0.93, 0.8).lerp(Color(1.0, 0.62, 0.36), warm)
		sky_mat.set_shader_parameter("sun_tint", sun_glow)
		sky_mat.set_shader_parameter("star_energy", pow(1.0 - day, 1.7) * 1.35)
		sky_mat.set_shader_parameter("moon_energy", (1.0 - day) * 1.1)
		if moon != null:
			sky_mat.set_shader_parameter("moon_dir", - moon.global_transform.basis.z.normalized())
		if weather != null:
			var wi := weather.intensity
			match weather.kind:
				"rain":
					sky_mat.set_shader_parameter("sky_top", Color(0.22, 0.27, 0.33).lerp(Color(0.4, 0.44, 0.48), day))
					sky_mat.set_shader_parameter("sky_horizon", Color(0.38, 0.42, 0.46).lerp(Color(0.62, 0.66, 0.68), day))
					sky_mat.set_shader_parameter("cloud_coverage", 0.22 + wi * 0.2)
					sky_mat.set_shader_parameter("cloud_opacity", 0.92)
					sky_mat.set_shader_parameter("cloud_hi", Color(0.52, 0.56, 0.59))
					sky_mat.set_shader_parameter("cloud_lo", Color(0.26, 0.29, 0.32))
					sky_mat.set_shader_parameter("sun_energy", 0.04)
				"fog":
					sky_mat.set_shader_parameter("cloud_coverage", 0.18)
					sky_mat.set_shader_parameter("cloud_opacity", 1.0)
					sky_mat.set_shader_parameter("cloud_hi", Color(0.58, 0.62, 0.65))
					sky_mat.set_shader_parameter("cloud_lo", Color(0.35, 0.38, 0.4))
				"snow":
					sky_mat.set_shader_parameter("sky_top", Color(0.48, 0.54, 0.62).lerp(Color(0.66, 0.72, 0.78), day))
					sky_mat.set_shader_parameter("sky_horizon", Color(0.62, 0.66, 0.7).lerp(Color(0.8, 0.84, 0.86), day))
					sky_mat.set_shader_parameter("cloud_coverage", 0.2)
					sky_mat.set_shader_parameter("cloud_opacity", 1.0)
				"cloudy":
					sky_mat.set_shader_parameter("cloud_coverage", 0.35)
					sky_mat.set_shader_parameter("cloud_opacity", 0.9)
					sky_mat.set_shader_parameter("cloud_hi", Color(0.66, 0.69, 0.72))
					sky_mat.set_shader_parameter("cloud_lo", Color(0.38, 0.41, 0.44))
		if Config.quality <= Config.Quality.LOW:
			# Skip the five-octave cloud fbm on integrated GPUs.
			sky_mat.set_shader_parameter("cloud_opacity", 0.0)
	for s: Settlement in settlements:
		if is_instance_valid(s):
			s.set_night(1.0 - day)
	var station_energy := 4.2 if Config.quality <= Config.Quality.LOW else 5.5
	for pl: OmniLight3D in station_lights:
		if is_instance_valid(pl):
			pl.light_energy = station_energy * (1.0 - day)



func _wants_test_mode() -> bool:
	return String(initial_state.get("mode", "open")) == "test"


func _build_route() -> void:
	route = Route.new()
	if _wants_test_mode():
		route.build_cyclic(Config.test_track(), 0.90, 0.35)
	else:
		route.build_cyclic(Config.route_loop(), 1.0, 0.35)

func _build_terrain() -> void:
	_prepare_terrain()
	_build_terrain_surface()
	_finish_terrain_stats()


func _prepare_terrain() -> void:
	terrain = Terrain.new()
	terrain.name = "Terrain"
	add_child(terrain)
	terrain.setup()
	terrain.add_corridor(route, 9.0)
	if _wants_test_mode():
		settlement_sites.clear()
		lakes.clear()
		return
	terrain.add_river(PackedVector2Array(RIVER), 6.0, 34.0, 300.0)
	for t: Dictionary in Config.TUNNELS:
		terrain.add_tunnel(route, Config.tunnel_span(route, t), float(t.get("height", 36.0)))
	for b: Dictionary in Config.BRIDGES:
		terrain.add_bridge(route, Config.bridge_span(route, b))
	for v: Dictionary in Config.VIADUCTS:
		terrain.add_viaduct(route, Config.viaduct_span(route, v), float(v.get("height", 22.0)))

	settlement_sites.clear()
	for i in range(Config.STATIONS.size()):
		var info: Dictionary = Config.STATIONS [i]
		var kind := String(info.get("settlement", "halt"))
		if kind == "halt":
			continue
		var d := Config.station_dist(route, i)
		var fr := route.frame_at(d)
		var side := float(info.get("settlement_side", -1.0))
		var offset := float(info.get("urban_offset", 520.0 if kind == "city" else 255.0))
		var center := fr.origin + fr.basis.x * side * offset
		var pad_h := fr.origin.y - 1.0
		var radius := float(info.get("urban_radius", 360.0 if kind == "city" else 150.0))
		var blend := 300.0 if kind == "city" else 130.0
		terrain.add_pad(center, radius, blend, pad_h)
		print("[settlement] %s %s center=%s h=%.1f r=%.0f" %[info ["name"], kind, center, pad_h, radius])
		settlement_sites.append({
			"name": info ["name"].replace("站", ""),
			"kind": kind,
			"center": center,
			"height": pad_h,
			"radius": radius,
			"side": side,
			"station": i,
			"population": int(info.get("population", 0)),
		})
		if i == 2:
			# A second, lower urban district sits under the long city viaduct.
			# The railway is then visibly elevated above real streets instead
			# of running through a flat painted backdrop.
			var vf := route.frame_at(route.total * 0.44)
			var vside := 1.0
			var vcenter := vf.origin + vf.basis.x * (vside * 240.0)
			var vpad_h := vf.origin.y - 18.0
			terrain.add_pad(vcenter, 700.0, 280.0, vpad_h)
			print("[settlement] 青川高架城 city center=%s h=%.1f r=700" %[vcenter, vpad_h])
			settlement_sites.append({
				"name": "青川高架城",
				"kind": "city",
				"center": vcenter,
				"height": vpad_h,
				"radius": 700.0,
				"side": vside,
				"station": i,
				"population": 96000,
			})

	lakes.clear()
	for lake_spec: Dictionary in [
		{"name": "山川湖", "station": 0, "side": 1.0, "offset": 360.0, "radius": 310.0},
		{"name": "青川镜湖", "station": 2, "side": 1.0, "offset": 460.0, "radius": 330.0},
		{"name": "青石湖", "station": 4, "side": 1.0, "offset": 340.0, "radius": 300.0},
		{"name": "云梦泽", "frac": 0.44, "side": 1.0, "offset": 520.0, "radius": 390.0},
		{"name": "雁归湾", "station": 3, "side": -1.0, "offset": 420.0, "radius": 320.0},
	]:
		var fr: Transform3D
		if lake_spec.has("frac"):
			fr = route.frame_at(route.total * float(lake_spec ["frac"]))
		else:
			var idx := int(lake_spec ["station"])
			fr = route.frame_at(Config.station_dist(route, idx))
		var c := fr.origin + fr.basis.x * float(lake_spec ["side"]) * float(lake_spec ["offset"])
		var level := terrain.height_at(c.x, c.z) - 4.0
		terrain.add_lake(Vector2(c.x, c.z), float(lake_spec ["radius"]), level, 110.0)
		lakes.append({"name": lake_spec ["name"], "center": Vector2(c.x, c.z), "level": level, "radius": float(lake_spec ["radius"])})


func _build_terrain_surface() -> void:
	var mat := Gfx.terrain()
	var near := terrain.build_mesh(NEAR_SIZE, _near_divisions(), mat, TERRAIN_CENTER)
	terrain.add_child(near)
	var outer := terrain.build_outer_mesh(NEAR_SIZE, OUTER_SIZE, _outer_divisions(), mat)
	terrain.add_child(outer)
	var water := terrain.build_water(30.0, Gfx.water())
	terrain.add_child(water)
	for l: Dictionary in lakes:
		var lm := terrain.build_lake(l ["center"], float(l ["radius"]), float(l ["level"]), Gfx.water())
		terrain.add_child(lm)


func _finish_terrain_stats() -> void:
	stats ["settlements"] = settlement_sites.size()
	stats ["lakes"] = lakes.size()


func _build_railway() -> void:
	railway = Railway.new()
	railway.name = "Railway"
	add_child(railway)
	railway.setup(route)
	railway.terrain = terrain
	railway.build_track(3.0)
	railway.build_catenary(55.0)
	if not _wants_test_mode():
		railway.build_tunnels()
		railway.build_bridges()
		railway.build_viaducts()
	stats ["track_km"] = route.total / 1000.0

func _build_vegetation(yield_frames := false) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261017
	var conifer := _conifer_mesh(false)
	var broadleaf := _broadleaf_mesh(false)
	var conifer_far := _conifer_mesh(true)
	var broadleaf_far := _broadleaf_mesh(true)
	var near := {"conifer": [], "broadleaf": []}
	var far := {"conifer": [], "broadleaf": []}
	var station_meta := []
	for i in range(Config.STATIONS.size()):
		station_meta.append({
			"d": Config.station_dist(route, i),
			"side": float(Config.STATIONS[i].get("settlement_side", -1.0 if i % 2 == 0 else 1.0)),
		})
	var count := 50000
	match Config.quality:
		Config.Quality.LOW:
			count = 5000
		Config.Quality.MEDIUM:
			count = 30000
		Config.Quality.HIGH:
			count = 50000
		_:
			count = 70000
	var tree_range := 1800.0
	var near_range := 120.0
	if Config.quality <= Config.Quality.LOW:
		# Low quality keeps a single, closer tree layer instead of paying for
		# distant forest overdraw.
		tree_range = 700.0
		near_range = 700.0
	for i in range(count):
		var d := rng.randf() * route.total
		var lateral :=(14.0 + pow(rng.randf(), 1.2) * tree_range) *(1.0 if rng.randf() < 0.5 else -1.0)
		var xf := route.frame_at(d)
		var pos := xf.origin + xf.basis.x * lateral
		var y := terrain.height_at(pos.x, pos.z)
		var n := _terrain_normal(roundi(pos.x), roundi(pos.z))
		if n.y < 0.62:
			continue
		if y < 2.0:
			continue
		# Settlement side stays clear of trees; the opposite side of the
		# track gets a wooded belt so stations do not sit in a bare field.
		var pad_scale := 0.72
		for meta: Dictionary in station_meta:
			if absf(_signed_delta(float(meta["d"]), d)) < 1400.0:
				if lateral * float(meta["side"]) < 0.0:
					pad_scale = 0.35
				break
		if terrain.inside_pad(pos.x, pos.z, pad_scale):
			continue
		if terrain.inside_water(pos.x, pos.z):
			continue
		var key := "conifer" if rng.randf() < 0.62 else "broadleaf"
		var s := 0.75 + rng.randf() * 0.85
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s *(0.85 + rng.randf() * 0.5), s))
		var item := Transform3D(basis, Vector3(pos.x, y - 0.45, pos.z))
		if absf(lateral) < near_range:
			near [key].append(item)
		else:
			far [key].append(item)
		if yield_frames and i % 320 == 0:
			await get_tree().process_frame
	# A denser wooded belt on the empty side of each station.
	var belt_count := 320
	if Config.quality <= Config.Quality.LOW:
		belt_count = 90
	elif Config.quality == Config.Quality.MEDIUM:
		belt_count = 180
	for si in range(Config.STATIONS.size()):
		var sd := Config.station_dist(route, si)
		var side := float(Config.STATIONS[si].get("settlement_side", -1.0 if si % 2 == 0 else 1.0))
		for k in range(belt_count):
			var dd := route.wrap_dist(sd + rng.randf_range(-650.0, 650.0))
			var lateral := -side * (55.0 + rng.randf() * 300.0)
			var xf := route.frame_at(dd)
			var pos := xf.origin + xf.basis.x * lateral
			var y := terrain.height_at(pos.x, pos.z)
			var n := _terrain_normal(roundi(pos.x), roundi(pos.z))
			if n.y < 0.72 or y < 2.0:
				continue
			if terrain.inside_water(pos.x, pos.z):
				continue
			if terrain.inside_pad(pos.x, pos.z, 0.35):
				continue
			var key := "conifer" if rng.randf() < 0.58 else "broadleaf"
			var s := 0.85 + rng.randf() * 1.0
			var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * (0.85 + rng.randf() * 0.5), s))
			var item := Transform3D(basis, Vector3(pos.x, y - 0.45, pos.z))
			if absf(lateral) < near_range:
				near [key].append(item)
			else:
				far [key].append(item)
	var total_placed := 0
	for is_near in [true, false]:
		if not is_near and Config.quality <= Config.Quality.LOW:
			# On low-end integrated GPUs the distant tree layer is a lot of
			# overdraw for very little screen coverage; keep only the near belt.
			continue
		var group: Dictionary = near if is_near else far
		for key in group.keys():
			var arr: Array = group [key]
			if arr.is_empty():
				continue
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = (conifer if is_near else conifer_far) if key == "conifer" else (broadleaf if is_near else broadleaf_far)
			mm.instance_count = arr.size()
			for j in range(arr.size()):
				mm.set_instance_transform(j, arr [j])
			var inst := MultiMeshInstance3D.new()
			inst.name = "Trees_%s_%s" %[key, "near" if is_near else "far"]
			inst.multimesh = mm
			inst.material_override = _tree_material(key == "conifer")
			inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON \
					if is_near and Config.quality >= Config.Quality.MEDIUM \
					else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(inst)
			total_placed += arr.size()
	stats ["trees"] = total_placed

func _terrain_normal(x: float, z: float) -> Vector3:
	var e := 6.0
	var hl := terrain.height_at(x - e, z)
	var hr := terrain.height_at(x + e, z)
	var hd := terrain.height_at(x, z - e)
	var hu := terrain.height_at(x, z + e)
	return Vector3(hl - hr, 2.0 * e, hd - hu).normalized()

func _conifer_mesh(far := false) -> ArrayMesh:
	var items := []
	items.append([Forge.lathe(PackedVector2Array([
		Vector2(0.56, -0.65), Vector2(0.40, 0.0), Vector2(0.30, 1.4),
		Vector2(0.18, 4.9), Vector2(0.08, 6.5)
	]), 8, true), Transform3D()])
	var needle := Forge.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.34, 0.14), Vector2(0.3, 0.5), Vector2(0.16, 1.0), Vector2(0.0, 1.6)
	]), 5, true)
	var whorls := 4 if far else 6
	var branches := 4
	for i in range(whorls):
		var t := float(i) / float(maxi(1, whorls - 1))
		var y := 2.55 + t * 3.65
		var base_r := 2.35 * (1.0 - t * 0.6)
		for b in range(branches):
			var a := TAU * float(b) / float(branches) + float(i) * 0.77 + 0.2
			var length := base_r * (0.82 + 0.16 * sin(float(i) * 2.1 + float(b) * 1.7))
			var start := Vector3(0, y, 0)
			var dir := Vector3(cos(a), -0.13 - float(b %2) * 0.06, sin(a)).normalized()
			var tip := start + dir * length
			items.append_array(Forge.tube_between(start, tip, 0.035, 5))
			var steps := [0.3] if far else [0.15, 0.55]
			for k in steps:
				var basis := Forge.basis_from_y(dir).scaled(Vector3(0.82, length / 1.6, 0.82))
				items.append([needle, Transform3D(basis, start + dir * (length * float(k) + 0.06))])
	var leader_len := 1.4 if far else 1.9
	items.append([needle, Transform3D(Forge.basis_from_y(Vector3.UP).scaled(Vector3(0.8, leader_len / 1.6, 0.8)), Vector3(0, 5.1, 0))])
	return Forge.merge_all(items)


func _broadleaf_mesh(far := false) -> ArrayMesh:
	var items := []
	var trunk := Forge.lathe(PackedVector2Array([
		Vector2(0.92, -0.70), Vector2(0.72, 0.0), Vector2(0.54, 1.7),
		Vector2(0.34, 4.3), Vector2(0.18, 5.9)
	]), 9, true)
	items.append([trunk, Transform3D()])
	if far:
		for i in range(1):
			var canopy := SphereMesh.new()
			canopy.radius = 2.75
			canopy.height = canopy.radius * 1.55
			canopy.radial_segments = 6
			canopy.rings = 3
			items.append([canopy, Transform3D(Basis().scaled(Vector3(1.0, 0.82, 1.0)), Vector3(0, 4.55, 0))])
			var lobe := SphereMesh.new()
			lobe.radius = 1.55
			lobe.height = 2.3
			lobe.radial_segments = 6
			lobe.rings = 3
			items.append([lobe, Transform3D(Basis().scaled(Vector3(1.0, 0.78, 1.0)), Vector3(0.65, 5.2, 0.2))])
		return Forge.merge_all(items)
	var limbs := 4
	var tips: Array = []
	for i in range(limbs):
		var a := TAU * float(i) / float(limbs) + 0.25
		var mid := Vector3(cos(a) * 0.8, 3.8 + float(i %2) * 0.35, sin(a) * 0.8)
		var tip := Vector3(cos(a) * 1.9, 5.15 + float(i %3) * 0.28, sin(a) * 1.9)
		items.append_array(Forge.tube_between(Vector3(0, 3.15, 0), mid, 0.14, 7))
		items.append_array(Forge.tube_between(mid, tip, 0.1, 6))
		var side_a := a + 0.62
		var side_tip := Vector3(cos(side_a) * 2.55, 4.8 + float(i %2) * 0.4, sin(side_a) * 2.55)
		items.append_array(Forge.tube_between(mid.lerp(tip, 0.45), side_tip, 0.065, 6))
		tips.append(tip)
	for i in range(limbs):
		var ball := SphereMesh.new()
		ball.radius = 1.35 + 0.18 * sin(float(i) * 2.0)
		ball.height = ball.radius * 1.5
		ball.radial_segments = 8
		ball.rings = 3
		var p: Vector3 = tips [i]
		items.append([ball, Transform3D(Basis().scaled(Vector3(1.0, 0.72, 1.0)), p + Vector3(0, 0.12, 0))])
	var center := SphereMesh.new()
	center.radius = 2.1
	center.height = 2.5
	center.radial_segments = 9
	center.rings = 4
	items.append([center, Transform3D(Basis().scaled(Vector3(1.0, 0.72, 1.0)), Vector3(0, 5.45, 0))])
	var crown := SphereMesh.new()
	crown.radius = 1.5
	crown.height = 2.2
	crown.radial_segments = 8
	crown.rings = 3
	items.append([crown, Transform3D(Basis().scaled(Vector3(1.0, 0.7, 1.0)), Vector3(0, 6.2, 0))])
	return Forge.merge_all(items)


func _tree_material(conifer: bool) -> Material:
	return Gfx.tree(conifer)



func _build_stations() -> void:
	station_data.clear()
	for i in range(Config.STATIONS.size()):
		var info: Dictionary = Config.STATIONS [i]
		var d := Config.station_dist(route, i)
		var side := float(info.get("settlement_side", -1.0 if i % 2 == 0 else 1.0))
		var stop := route.wrap_dist(d + 55.0)
		var freight := bool(info.get("freight", false))
		var station := {
			"name": info ["name"],
			"dist": d,
			"stop": stop,
			"side": side,
			"freight": freight,
			"settlement": String(info.get("settlement", "halt")),
			"population": int(info.get("population", 0)),
			"branch": bool(info.get("branch", false)),
			"index": i,
		}
		station_data.append(station)
		var platform_len := float(info.get("platform_len", 220.0))
		var settlement := String(station["settlement"])
		if settlement == "city":
			platform_len = maxf(platform_len, 420.0)
		elif settlement == "town":
			platform_len = maxf(platform_len, 300.0)
		else:
			platform_len = maxf(platform_len, 240.0)
		station ["platform_len"] = platform_len
		station ["platform_lat"] = 4.6
		station ["platform_top"] = 1.02 if freight else 1.1
		station ["platform_half"] = 2.9
		station ["hall_lat_in"] = 10.0
		station ["hall_lat_out"] = 26.0
		station ["hall_half"] = 19.0
		station ["hall_entry_half"] = 4.8
		station ["hall_top"] = float(station ["platform_top"])
		if freight:
			# The goods yard sits opposite the passenger platform, next to
			# the sidings, so it does not collide with the station hall.
			station ["yard_lat"] = -17.0
			station ["yard_half"] = 6.5
			station ["yard_len"] = clampf(platform_len * 0.65, 80.0, 150.0)
			station ["yard_top"] = 0.26
		_build_station(d, info ["name"], side, freight, platform_len, settlement, i)
		_build_stop_mark(stop, side, info ["name"])
		if freight:
			station_data [i] ["hoist"] = _build_freight_yard(d, -side, info ["name"], platform_len)
		if String(station ["settlement"]) != "halt":
			_build_settlement(station)


func _build_settlement(station: Dictionary, yield_frames := false) -> void:
	var idx := int(station.get("index", -1))
	for site: Dictionary in settlement_sites:
		if int(site.get("station", -1)) == idx:
			var s: Settlement
			if yield_frames:
				s = await Settlement.build_async(self, route, site)
			else:
				s = Settlement.build(self, route, site)
			settlements.append(s)

func _build_stop_mark(dist: float, side: float, station_name := "") -> void:
	var group := Node3D.new()
	group.name = "StopMark"
	railway.add_child(group)
	var xf := route.frame_at(dist)
	var b := xf.basis.orthonormalized()
	var sb := b * Basis(Vector3.UP, -side * PI * 0.5)
	var base := xf.origin + b.x *(side * 4.6) + Vector3.UP * 1.02
	var post := MeshInstance3D.new()
	post.mesh = Forge.cylinder(0.075, 3.0, 8, 0.0, true, true)
	post.material_override = Gfx.metal(Color(0.42, 0.44, 0.46), 0.5, 0.6)
	post.transform = Transform3D(Basis(), base + Vector3.UP * 1.5)
	group.add_child(post)
	var board := MeshInstance3D.new()
	board.mesh = Forge.box(Vector3(1.9, 0.62, 0.08))
	board.material_override = Gfx.paint(Color(0.1, 0.16, 0.3), 0.5, 0.3, 0.4)
	board.transform = Transform3D(sb, base + Vector3.UP * 3.15)
	group.add_child(board)
	var label := Label3D.new()
	label.text = "停车位置"
	label.font_size = 120
	label.pixel_size = 0.004
	label.modulate = Color(1.0, 0.95, 0.85)
	label.outline_size = 14
	label.outline_modulate = Color(0.05, 0.08, 0.14)
	label.transform = Transform3D(sb, base + Vector3.UP * 3.15 + sb.z * 0.06)
	group.add_child(label)

	var mark := MeshInstance3D.new()
	mark.mesh = Forge.box(Vector3(3.4, 0.03, 0.34))
	mark.material_override = Gfx.paint(Color(0.95, 0.9, 0.32), 0.5, 0.05, 0.3)
	mark.transform = Transform3D(b, xf.origin + b.x *(side * 5.4) + Vector3.UP * 1.04)
	group.add_child(mark)



func _build_freight_yard(dist: float, side: float, station_name: String, platform_len: float) -> Node3D:
	var xf := route.frame_at(dist)
	var b := xf.basis.orthonormalized()
	var root := Node3D.new()
	root.name = "FreightYard_" + station_name
	root.transform = Transform3D(b, xf.origin)
	add_child(root)

	var yard_x := side * 17.0
	var yard_len := clampf(platform_len * 0.65, 80.0, 150.0)
	var concrete := Gfx.noise_surface(Color(0.24, 0.245, 0.23), 0.94, 0.15, 0.35)
	var frame := Gfx.paint(Color(0.55, 0.24, 0.12), 0.58, 0.35, 0.25)

	var apron := MeshInstance3D.new()
	apron.name = "FreightApron"
	apron.mesh = Forge.box(Vector3(13.0, 0.16, yard_len))
	apron.material_override = concrete
	apron.position = Vector3(yard_x, 0.18, 0)
	root.add_child(apron)
	var edge_wall := MeshInstance3D.new()
	edge_wall.name = "YardRetainingWall"
	edge_wall.mesh = Forge.box(Vector3(0.36, 0.95, yard_len))
	edge_wall.material_override = Gfx.noise_surface(Color(0.42, 0.42, 0.40), 0.9, 0.1, 0.3)
	edge_wall.position = Vector3(side * 9.55, 0.55, 0)
	root.add_child(edge_wall)

	var blue_items := []
	var rust_items := []
	for row in range(3):
		for col in range(3):
			if (row + col) % 3 == 1:
				continue
			var cx := side * (12.2 + float(row) * 3.0)
			var cz := (float(col) - 1.0) * 13.0
			var height := 2 if (row + col) % 3 == 0 else 1
			for level in range(height):
				var item := [Forge.box(Vector3(2.45, 2.55, 6.05)),
						Transform3D(Basis(), Vector3(cx, 1.54 + float(level) * 2.62, cz))]
				if (row + col) % 2 == 0:
					blue_items.append(item)
				else:
					rust_items.append(item)
	var stacks_a := MeshInstance3D.new()
	stacks_a.name = "YardContainersA"
	stacks_a.mesh = Forge.merge_all(blue_items)
	stacks_a.material_override = Gfx.paint(Color(0.20, 0.38, 0.58), 0.62, 0.25, 0.28)
	root.add_child(stacks_a)
	var stacks_b := MeshInstance3D.new()
	stacks_b.name = "YardContainersB"
	stacks_b.mesh = Forge.merge_all(rust_items)
	stacks_b.material_override = Gfx.paint(Color(0.45, 0.27, 0.18), 0.65, 0.2, 0.25)
	root.add_child(stacks_b)

	var steel_items := []
	for lx: float in [10.8, 23.2]:
		steel_items.append([Forge.box(Vector3(0.48, 9.8, 0.48)),
				Transform3D(Basis(), Vector3(side * lx, 5.0, 0))])
	steel_items.append([Forge.box(Vector3(12.4, 0.75, 1.0)),
			Transform3D(Basis(), Vector3(yard_x, 9.75, 0))])
	var gantry := MeshInstance3D.new()
	gantry.name = "YardGantry"
	gantry.mesh = Forge.merge_all(steel_items)
	gantry.material_override = frame
	root.add_child(gantry)

	var hoist := Node3D.new()
	hoist.name = "Hoist"
	hoist.position = Vector3(yard_x, 6.3, 0)
	hoist.set_meta("yard_x", yard_x)
	root.add_child(hoist)
	var trolley := MeshInstance3D.new()
	trolley.mesh = Forge.box(Vector3(1.8, 0.45, 1.1))
	trolley.material_override = Gfx.metal(Color(0.3, 0.32, 0.34), 0.5, 0.7)
	hoist.add_child(trolley)
	for rx: float in [-0.65, 0.65]:
		var rope := MeshInstance3D.new()
		rope.mesh = Forge.box(Vector3(0.05, 2.2, 0.05))
		rope.position = Vector3(rx, -1.15, 0)
		hoist.add_child(rope)
	var load := MeshInstance3D.new()
	load.mesh = Forge.box(Vector3(2.45, 2.55, 6.05))
	load.material_override = Gfx.paint(Color(0.20, 0.38, 0.58), 0.62, 0.25, 0.28)
	load.position = Vector3(0, -3.65, 0)
	hoist.add_child(load)
	return hoist


func _platform_palette(station_index: int, freight: bool, settlement: String) -> Dictionary:
	if freight:
		return {
			"accent": Color(0.66, 0.48, 0.14),
			"surface": Color(0.55, 0.55, 0.52),
			"glow": Color(1.0, 0.74, 0.28),
		}
	var branch := station_index >= 0 and station_index < Config.STATIONS.size() \
			and bool(Config.STATIONS[station_index].get("branch", false))
	if branch:
		return {
			"accent": Color(0.10, 0.43, 0.42),
			"surface": Color(0.61, 0.64, 0.62),
			"glow": Color(0.47, 0.92, 0.84),
		}
	if settlement == "city":
		return {
			"accent": Color(0.15, 0.31, 0.50),
			"surface": Color(0.64, 0.65, 0.65),
			"glow": Color(0.58, 0.80, 1.0),
		}
	if settlement == "town":
		return {
			"accent": Color(0.47, 0.22, 0.15),
			"surface": Color(0.65, 0.62, 0.57),
			"glow": Color(1.0, 0.74, 0.50),
		}
	return {
		"accent": Color(0.23, 0.35, 0.28),
		"surface": Color(0.61, 0.61, 0.57),
		"glow": Color(0.66, 0.92, 0.68),
	}


func _build_station(dist: float, station_name: String, side: float, freight := false, platform_len := 220.0,
		settlement := "halt", station_index := -1, yield_frames := false) -> void:
	var group := Node3D.new()
	group.name = "Station_" + station_name
	railway.add_child(group)

	# Keep the platform edge close to the train on every station type.
	# Freight stations used to sit 1.8 m further out, which made a passenger
	# train look like it was stopped far from the platform.
	var lat_c := 4.6
	var half_w := 2.9
	var top := 1.02 if freight else 1.1
	var edge_lat := lat_c - half_w
	var palette := _platform_palette(station_index, freight, settlement)
	var accent_col: Color = palette["accent"]
	var surface_col: Color = palette["surface"]
	var glow_col: Color = palette["glow"]
	var accent_mat := Gfx.paint(accent_col, 0.42, 0.30, 0.42)
	var accent_glow := Gfx.emissive(glow_col, 1.0, accent_col.darkened(0.55))
	var d := dist - platform_len * 0.5


	var frames: Array [Transform3D] = []
	while d <= dist + platform_len * 0.5:
		var xf := route.frame_at(d)
		xf.origin += xf.basis.x *(side * lat_c)
		frames.append(xf)
		d += 6.0
	var prof := PackedVector2Array([
		Vector2(- half_w, 0.0), Vector2(half_w, 0.0), Vector2(half_w, top - 0.14),
		Vector2(half_w - 0.28, top), Vector2(- half_w + 0.28, top), Vector2(- half_w, top - 0.14),
	])
	var plat := MeshInstance3D.new()
	plat.name = "Platform"
	plat.mesh = Forge.loft(prof, frames, true, true)
	plat.material_override = Gfx.noise_surface(surface_col, 0.9, 0.22, 0.18)
	group.add_child(plat)

	var foundation_items := []
	if terrain != null:
		var fd := dist - platform_len * 0.5
		while fd <= dist + platform_len * 0.5:
			var xf := route.frame_at(fd)
			var b := xf.basis.orthonormalized()
			for sd: float in [-1.0, 1.0]:
				var ep := xf.origin + b.x * (side * (lat_c + sd * half_w))
				var g := terrain.height_at(ep.x, ep.z)
				var h := xf.origin.y - g
				if h > 0.04:
					foundation_items.append([Forge.box(Vector3(0.28, h + 0.12, 3.05)),
							Transform3D(Basis(), Vector3(ep.x, g + h * 0.5 - 0.02, ep.z))])
			fd += 3.0
		_add_merged(group, "PlatformFoundation", foundation_items,
				Gfx.noise_surface(Color(0.4, 0.41, 0.4), 0.92, 0.35, 0.2))


	var bnd := []
	var line := []
	var tact := []
	var bumps := []
	var accent_strip := []
	var edge_lights := []
	var platform_joints := []
	d = dist - platform_len * 0.5 + 1.0
	var bi := 0
	while d <= dist + platform_len * 0.5 - 1.0:
		var xf := route.frame_at(d)
		var b := xf.basis.orthonormalized()
		var up := xf.origin + Vector3.UP * top
		bnd.append([Forge.box(Vector3(0.3, 0.03, 1.06)), Transform3D(b, up + b.x *(side *(edge_lat + 0.15)))])
		line.append([Forge.box(Vector3(0.12, 0.03, 1.06)), Transform3D(b, up + b.x *(side *(edge_lat + 0.85)))])
		accent_strip.append([Forge.box(Vector3(0.14, 0.018, 1.04)),
				Transform3D(b, up + b.x *(side *(lat_c + 2.52)) + Vector3.UP * 0.01)])
		if bi % 6 == 0:
			edge_lights.append([Forge.box(Vector3(0.16, 0.032, 0.56)),
					Transform3D(b, up + b.x *(side *(edge_lat + 0.17)) + Vector3.UP * 0.012)])
		if bi % 12 == 0:
			platform_joints.append([Forge.box(Vector3(half_w * 1.82, 0.012, 0.09)),
					Transform3D(b, up + Vector3.UP * 0.009)])
		if not freight:
			tact.append([Forge.box(Vector3(0.36, 0.032, 1.06)), Transform3D(b, up + b.x *(side *(edge_lat + 1.42)))])
			if bi %2 == 0:
				bumps.append([Forge.box(Vector3(0.3, 0.02, 0.16)),
						Transform3D(b, up + b.x *(side *(edge_lat + 1.42)) + Vector3.UP * 0.026)])
		bi += 1
		d += 1.0
	_add_merged(group, "PlatformEdgeStone", bnd, Gfx.paint(Color(0.3, 0.31, 0.32), 0.75, 0.05, 0.2))
	_add_merged(group, "PlatformYellowLine", line, Gfx.paint(Color(0.93, 0.86, 0.26), 0.6, 0.05, 0.3))
	_add_merged(group, "PlatformAccentStrip", accent_strip, accent_mat)
	_add_merged(group, "PlatformEdgeLights", edge_lights, accent_glow)
	_add_merged(group, "PlatformJoints", platform_joints, Gfx.metal(Color(0.42, 0.43, 0.42), 0.7, 0.15))
	if not tact.is_empty():
		_add_merged(group, "TactilePaving", tact, Gfx.paint(Color(0.86, 0.74, 0.22), 0.7, 0.05, 0.2))
		_add_merged(group, "TactileBumps", bumps, Gfx.paint(Color(0.8, 0.68, 0.2), 0.7, 0.05, 0.2))
	if yield_frames:
		await get_tree().process_frame

	var lamp_items := []
	d = dist - platform_len * 0.5 + 12.0
	while d <= dist + platform_len * 0.5 - 12.0:
		var xf := route.frame_at(d)
		var lp := xf.origin + xf.basis.x *(side *(lat_c + 2.75)) + Vector3.UP * top
		lamp_items.append([Forge.cylinder(0.085, 7.4, 8, 0.0, true, true), Transform3D(Basis(), lp)])
		lamp_items.append([Forge.cylinder(0.2, 0.3, 8, 0.0, true, true), Transform3D(Basis(), lp + Vector3.UP * 0.15)])
		for arm: float in([-1.0, 1.0] if not freight else [-1.0]):

			var arm_dir: Vector3 = xf.basis.x *(side * arm)
			lamp_items.append([Forge.box(Vector3(2.3, 0.1, 0.1)),
					Transform3D(xf.basis.orthonormalized(), lp + Vector3.UP * 7.32 + arm_dir * 1.15)])
			lamp_items.append([Forge.box(Vector3(0.6, 0.16, 0.34)),
					Transform3D(xf.basis.orthonormalized(), lp + Vector3.UP * 7.2 + arm_dir * 2.05)])
		d += 22.0
	_add_merged(group, "PlatformLamps", lamp_items, Gfx.metal(Color(0.3, 0.32, 0.34), 0.55, 0.6))
	if yield_frames:
		await get_tree().process_frame
	var station_light_ks: Array = [0.5] if Config.quality <= Config.Quality.LOW else [0.25, 0.5, 0.75]
	for k: float in station_light_ks:
		var ld := dist - platform_len * 0.5 + platform_len * k
		var lf := route.frame_at(ld)
		var sp := lf.origin + lf.basis.x *(side *(lat_c + 2.2)) + Vector3.UP *(top + 6.4)
		var pl := OmniLight3D.new()
		pl.position = sp
		pl.omni_range = 34.0
		pl.light_energy = 0.0
		pl.light_color = Color(1.0, 0.82, 0.55)
		pl.shadow_enabled = false
		group.add_child(pl)
		station_lights.append(pl)

	# Platform identity: small number plates on the rear fence at both ends,
	# plus two hanging name boards under the canopy. None of these are placed
	# across the walking route, so they cannot create a barrier.
	var platform_text := "%s  ·  %s" %[
		station_name, "货场 1 站台" if freight else "1 站台"]
	for e: float in [-0.44, 0.44]:
		var nf := route.frame_at(dist + e * platform_len)
		var nb := nf.basis.orthonormalized() * Basis(Vector3.UP, -side * PI * 0.5)
		var plate := MeshInstance3D.new()
		plate.name = "PlatformNumber_%d_%s" %[station_index, "A" if e < 0.0 else "B"]
		plate.mesh = Forge.box(Vector3(0.92, 0.58, 0.055))
		plate.material_override = accent_mat
		plate.transform = Transform3D(nb,
				nf.origin + nf.basis.x * (side * (lat_c + 2.42)) + Vector3.UP * (top + 1.35))
		group.add_child(plate)
		var plate_label := Label3D.new()
		plate_label.text = "1\n站台"
		plate_label.font_size = 54
		plate_label.pixel_size = 0.0026
		plate_label.modulate = Color(0.96, 0.97, 0.95)
		plate_label.outline_size = 5
		plate_label.outline_modulate = Color(0.04, 0.06, 0.08)
		plate_label.transform = Transform3D(nb, plate.transform.origin + nb.z * 0.038)
		group.add_child(plate_label)
		var plate_label2 := plate_label.duplicate() as Label3D
		plate_label2.transform = Transform3D(nb * Basis(Vector3.UP, PI),
				plate.transform.origin - nb.z * 0.038)
		group.add_child(plate_label2)

	if not freight:
		for e: float in [-0.30, 0.30]:
			var hf := route.frame_at(dist + e * 150.0)
			var hb := hf.basis.orthonormalized() * Basis(Vector3.UP, -side * PI * 0.5)
			var hboard := MeshInstance3D.new()
			hboard.name = "PlatformNameBoard_%d_%s" %[station_index, "A" if e < 0.0 else "B"]
			hboard.mesh = Forge.box(Vector3(3.3, 0.54, 0.08))
			hboard.material_override = Gfx.paint(Color(0.09, 0.13, 0.18), 0.45, 0.35, 0.45)
			hboard.transform = Transform3D(hb,
					hf.origin + hf.basis.x * (side * (lat_c + 0.75)) + Vector3.UP * (top + 3.62))
			group.add_child(hboard)
			var hlabel := Label3D.new()
			hlabel.text = platform_text
			hlabel.font_size = 74
			hlabel.pixel_size = 0.0032
			hlabel.modulate = Color(0.98, 0.96, 0.90)
			hlabel.outline_size = 7
			hlabel.outline_modulate = Color(0.04, 0.06, 0.09)
			hlabel.transform = Transform3D(hb,
					hboard.transform.origin + hb.z * 0.048)
			group.add_child(hlabel)
			var hlabel2 := hlabel.duplicate() as Label3D
			hlabel2.transform = Transform3D(hb * Basis(Vector3.UP, PI),
					hboard.transform.origin - hb.z * 0.048)
			group.add_child(hlabel2)
			for hz: float in [-1.25, 1.25]:
				var hanger := MeshInstance3D.new()
				hanger.mesh = Forge.box(Vector3(0.035, 0.62, 0.035))
				hanger.material_override = Gfx.metal(Color(0.34, 0.36, 0.38), 0.4, 0.7)
				hanger.transform = Transform3D(hb,
						hboard.transform.origin + hb.x * hz + Vector3.UP * 0.58)
				group.add_child(hanger)

	if not freight:
		var can_len := 150.0
		if station_index >= 0 and station_index < Config.STATIONS.size() \
				and bool(Config.STATIONS[station_index].get("branch", false)):
			can_len = 120.0
		elif settlement == "city":
			can_len = 170.0
		elif settlement == "town":
			can_len = 135.0
		var can_lat := lat_c + 0.9
		var roof_frames: Array [Transform3D] = []
		var col_items := []
		var rib_items := []
		var light_items := []
		var fasci := []
		d = dist - can_len * 0.5
		var ri := 0
		while d <= dist + can_len * 0.5:
			var xf := route.frame_at(d)
			var b := xf.basis.orthonormalized()
			roof_frames.append(Transform3D(b, xf.origin + b.x *(side * can_lat) + Vector3.UP *(top + 4.55)))

			if ri %5 == 0:
				var cp := xf.origin + b.x *(side *(can_lat + 1.45)) + Vector3.UP * top
				col_items.append([Forge.cylinder(0.15, 4.55, 10, 0.0, true, true), Transform3D(Basis(), cp + Vector3.UP * 2.28)])
				col_items.append([Forge.box(Vector3(0.46, 0.1, 0.46)), Transform3D(b, cp + Vector3.UP * 0.05)])
				col_items.append([Forge.box(Vector3(0.34, 0.22, 0.34)), Transform3D(b, cp + Vector3.UP * 4.62)])
				col_items.append([Forge.box(Vector3(0.1, 3.15, 0.1)), Transform3D(b, cp + Vector3.UP * 2.3 + b.x *(side * -0.3))])

			if ri %3 == 0:
				var rp := xf.origin + b.x *(side * can_lat) + Vector3.UP *(top + 4.38)
				rib_items.append([Forge.box(Vector3(5.9, 0.13, 0.13)), Transform3D(b, rp)])
				rib_items.append([Forge.box(Vector3(0.1, 0.42, 0.1)), Transform3D(b, rp + b.x *(side * 2.6) + Vector3.UP * 0.2)])
				rib_items.append([Forge.box(Vector3(0.1, 0.42, 0.1)), Transform3D(b, rp - b.x *(side * 2.6) + Vector3.UP * 0.2)])
			if ri %4 == 0:
				light_items.append([Forge.box(Vector3(0.2, 0.045, 1.5)),
						Transform3D(b, xf.origin + b.x *(side *(can_lat - 0.9)) + Vector3.UP *(top + 4.3))])
			d += 1.5
			ri += 1
		var rp2 := PackedVector2Array([
			Vector2(-2.95, -0.07), Vector2(2.95, -0.07), Vector2(2.95, 0.1), Vector2(-2.95, 0.1)
		])
		var roof := MeshInstance3D.new()
		roof.name = "CanopyRoof"
		roof.mesh = Forge.loft(rp2, roof_frames, true, true)
		roof.material_override = Gfx.sheet(Color(0.7, 0.72, 0.74), 0.5, 0.3)
		group.add_child(roof)

		var fi := 0
		for rf: Transform3D in roof_frames:
			if fi %2 == 0:
				fasci.append([Forge.box(Vector3(0.1, 0.46, 3.0)),
						Transform3D(rf.basis, rf.origin - rf.basis.x *(side * 2.95) + Vector3.UP *(-0.02))])
				fasci.append([Forge.box(Vector3(0.1, 0.46, 3.0)),
						Transform3D(rf.basis, rf.origin + rf.basis.x *(side * 2.95) + Vector3.UP *(-0.02))])
			fi += 1
		_add_merged(group, "CanopyFascia", fasci, accent_mat)
		_add_merged(group, "CanopyTruss", rib_items, Gfx.metal(Color(0.5, 0.52, 0.55), 0.5, 0.55))
		_add_merged(group, "CanopyColumns", col_items, Gfx.metal(Color(0.44, 0.46, 0.49), 0.45, 0.7))
		_add_merged(group, "CanopyLights", light_items,
				Gfx.emissive(Color(1.0, 0.96, 0.88), 1.2, Color(0.86, 0.86, 0.84)))
		if yield_frames:
			await get_tree().process_frame

		var seat_items := []
		var seat_legs := []
		var d2 := dist - 52.0
		while d2 <= dist + 52.0:
			var xf := route.frame_at(d2)
			var b := xf.basis.orthonormalized()
			var sp := xf.origin + b.x *(side *(lat_c + 1.0)) + Vector3.UP * top
			for k in range(3):
				seat_items.append([Forge.box(Vector3(0.52, 0.07, 0.62)),
						Transform3D(b, sp + b.z *(float(k) * 0.76 - 0.76) + Vector3.UP * 0.44)])
				seat_items.append([Forge.box(Vector3(0.52, 0.44, 0.07)),
						Transform3D(b, sp + b.z *(float(k) * 0.76 - 0.76) + Vector3.UP * 0.66 + b.x *(side * 0.26))])
			seat_legs.append([Forge.box(Vector3(0.1, 0.42, 2.0)), Transform3D(b, sp - b.x *(side * 0.24) + Vector3.UP * 0.21)])
			seat_legs.append([Forge.box(Vector3(0.1, 0.42, 2.0)), Transform3D(b, sp + b.x *(side * 0.24) + Vector3.UP * 0.21)])

			var tp := xf.origin + b.x *(side *(lat_c + 1.1)) + Vector3.UP * top
			seat_legs.append([Forge.cylinder(0.26, 0.78, 10, 0.0, true, true),
					Transform3D(Basis(), tp + Vector3.UP * 0.39)])
			d2 += 18.0
		_add_merged(group, "PlatformSeats", seat_items, Gfx.paint(Color(0.36, 0.4, 0.46), 0.6, 0.1, 0.3))
		_add_merged(group, "PlatformBins", seat_legs, Gfx.metal(Color(0.34, 0.36, 0.38), 0.5, 0.6))

		# Vending machines and wind screens break up the long rear edge.
		# They are fixed geometry, not animated actors.
		var vend_body := []
		var vend_glow := []
		for vz: float in [-55.0, 55.0]:
			var vf := route.frame_at(dist + vz)
			var vb := vf.basis.orthonormalized()
			var vbase := vf.origin + vb.x * (side * (lat_c + 1.90)) + Vector3.UP * top
			vend_body.append([Forge.box(Vector3(0.72, 1.92, 0.56)),
					Transform3D(vb, vbase + Vector3.UP * 0.96)])
			vend_body.append([Forge.box(Vector3(0.76, 0.10, 0.60)),
					Transform3D(vb, vbase + Vector3.UP * 1.96)])
			vend_glow.append([Forge.box(Vector3(0.035, 1.18, 0.46)),
					Transform3D(vb, vbase - vb.x * (side * 0.30) + Vector3.UP * 1.10)])
		_add_merged(group, "PlatformVending", vend_body, Gfx.paint(Color(0.17, 0.20, 0.23), 0.5, 0.25, 0.35))
		_add_merged(group, "PlatformVendingScreens", vend_glow, accent_glow)

		if settlement == "city" or settlement == "town":
			var screen_glass := Gfx.glass(Color(0.16, 0.24, 0.30), 0.05, 0.22)
			var wind_items := []
			for wz: float in [-platform_len * 0.29, platform_len * 0.29]:
				var wf := route.frame_at(dist + wz)
				var wb := wf.basis.orthonormalized()
				var wp := wf.origin + wb.x * (side * (lat_c + 2.68)) + Vector3.UP * (top + 1.02)
				wind_items.append([Forge.box(Vector3(0.035, 1.55, 4.4)),
						Transform3D(wb, wp)])
				wind_items.append([Forge.box(Vector3(0.055, 0.08, 4.5)),
						Transform3D(wb, wp + Vector3.UP * 0.80)])
				wind_items.append([Forge.box(Vector3(0.055, 0.08, 4.5)),
						Transform3D(wb, wp - Vector3.UP * 0.80)])
			_add_merged(group, "PlatformWindscreens", wind_items, screen_glass)
		if yield_frames:
			await get_tree().process_frame

		var sgn := _station_sign(platform_text, true)
		var sf := route.frame_at(dist)
		var sfb := sf.basis.orthonormalized() * Basis(Vector3.UP, -side * PI * 0.5)
		sgn.transform = Transform3D(sfb,
				sf.origin + sf.basis.x *(side *(lat_c + 0.15)) + Vector3.UP *(top + 3.3))
		group.add_child(sgn)
		if yield_frames:
			await get_tree().process_frame

	if not freight:
		var step_items := []
		var step_edges := []
		var stair_rails := []
		var rail_items := []
		var post_items := []
		var step_h := 0.22
		var step_d := 0.34
		var step_w := half_w * 1.2
		for e: float in [-1.0, 1.0]:
			var xf := route.frame_at(dist + e * platform_len * 0.5)
			var b := xf.basis.orthonormalized()
			var base := xf.origin + b.x * (side * lat_c)
			var count := 4
			while count < 14:
				var probe_z := 0.35 + float(count - 1) * step_d
				var probe := base + b.z * (-e * probe_z)
				var ground := terrain.height_at(probe.x, probe.z) if terrain != null else 0.0
				if top - step_h * float(count) <= ground + 0.05:
					break
				count += 1
			for k in range(count):
				var zoff := 0.35 + float(k) * step_d
				var top_y := top - step_h * float(k + 1)
				var center := base + b.z * (-e * zoff) + Vector3.UP * (top_y - step_h * 0.5)
				step_items.append([Forge.box(Vector3(step_w, step_h, step_d)), Transform3D(b, center)])
				step_edges.append([Forge.box(Vector3(step_w, 0.025, 0.07)),
						Transform3D(b, center + Vector3.UP * (step_h * 0.5 - 0.012)
								+ b.z * (-e * step_d * 0.5))])
			for sd: float in [-1.0, 1.0]:
				var rail_x := side * (lat_c + sd * step_w * 0.5)
				var rail_top := xf.origin + b.x * rail_x + Vector3.UP * (top + 0.82)
				var z_end := 0.35 + float(count - 1) * step_d + step_d * 0.5
				var re := xf.origin + b.x * rail_x + b.z * (-e * z_end)
				var rg := terrain.height_at(re.x, re.z) if terrain != null else 0.0
				var rail_bottom := Vector3(re.x, rg + 0.82, re.z)
				stair_rails.append_array(Forge.tube_between(rail_top, rail_bottom, 0.045, 6))
				stair_rails.append_array(Forge.tube_between(rail_top - Vector3.UP * 0.82, rail_top, 0.035, 6))
				stair_rails.append_array(Forge.tube_between(rail_bottom - Vector3.UP * 0.82, rail_bottom, 0.035, 6))

		var d3 := dist - platform_len * 0.5 + 2.0
		while d3 <= dist + platform_len * 0.5 - 2.0:
			var xf2 := route.frame_at(d3)
			var b2 := xf2.basis.orthonormalized()
			var bp := xf2.origin + b2.x *(side *(lat_c + half_w - 0.3)) + Vector3.UP * top
			if absf(d3 - dist) > 7.0:
				rail_items.append([Forge.box(Vector3(0.06, 0.06, 2.0)), Transform3D(b2, bp + Vector3.UP * 1.02)])
				rail_items.append([Forge.box(Vector3(0.06, 0.06, 2.0)), Transform3D(b2, bp + Vector3.UP * 0.58)])
				post_items.append([Forge.box(Vector3(0.09, 1.1, 0.09)), Transform3D(b2, bp + Vector3.UP * 0.55)])
			d3 += 2.0
		_add_merged(group, "PlatformSteps", step_items, Gfx.noise_surface(Color(0.6, 0.59, 0.57), 0.9, 0.25, 0.2))
		_add_merged(group, "PlatformStepEdges", step_edges, Gfx.paint(Color(0.86, 0.72, 0.2), 0.7, 0.1, 0.3))
		_add_merged(group, "PlatformFence", rail_items, Gfx.metal(Color(0.46, 0.48, 0.5), 0.45, 0.7))
		_add_merged(group, "PlatformFencePosts", post_items, Gfx.metal(Color(0.42, 0.44, 0.46), 0.45, 0.7))
		_add_merged(group, "PlatformStairRails", stair_rails, Gfx.metal(Color(0.46, 0.48, 0.5), 0.45, 0.7))


	if freight:
		var fsgn := _station_sign(platform_text, true)
		var fsf := route.frame_at(dist)
		var fsb := fsf.basis.orthonormalized() * Basis(Vector3.UP, -side * PI * 0.5)
		fsgn.transform = Transform3D(fsb,
				fsf.origin + fsf.basis.x *(side *(lat_c + 0.15)) + Vector3.UP *(top + 3.3))
		group.add_child(fsgn)

	var bdg_frame := route.frame_at(dist)
	var hall_off := 18.0
	var hall_w := 15.6
	var hall_d := 38.0
	var hall_h := 10.6 if settlement == "city" else (9.2 if settlement == "town" else 8.2)
	var hall_floor := bdg_frame.origin.y + top
	var bdg_pos := bdg_frame.origin + bdg_frame.basis.x * (side * hall_off)
	bdg_pos.y = hall_floor
	# Follow the local track gradient as well as its heading, so the floor
	# meets the platform without a step and the forecourt stays flush.
	var bdg_basis := bdg_frame.basis
	var bdg := Node3D.new()
	bdg.name = "StationBuilding"
	bdg.transform = Transform3D(bdg_basis, bdg_pos)
	group.add_child(bdg)

	var wall_mat := Gfx.paint(Color(0.79, 0.77, 0.72), 0.62, 0.05, 0.2)
	var stone_mat := Gfx.paint(Color(0.48, 0.46, 0.43), 0.72, 0.04, 0.2)
	var roof_mat := Gfx.paint(Color(0.30, 0.19, 0.16), 0.68, 0.08, 0.2)
	var trim_mat := Gfx.metal(Color(0.26, 0.28, 0.30), 0.52, 0.52)
	var glass_mat := Gfx.glass(Color(0.12, 0.19, 0.24), 0.05, 0.30)
	var floor_mat := Gfx.noise_surface(Color(0.56, 0.55, 0.52), 0.86, 0.32, 0.2)
	var ceiling_mat := Gfx.interior_panel(Color(0.64, 0.65, 0.64), 0.62)
	var light_mat := Gfx.emissive(Color(1.0, 0.95, 0.84), 1.15, Color(0.72, 0.68, 0.58))
	var inner_x := -side * hall_w * 0.5
	var outer_x := side * hall_w * 0.5
	var entry_half := 4.8

	# Foundation down to the landscape, plus a paved forecourt that reaches
	# the platform edge. This is the terrain transition the old solid box
	# never had: the hall now sits on a visible plinth instead of floating.
	var ground := terrain.height_at(bdg_pos.x, bdg_pos.z) if terrain != null else hall_floor - 2.0
	var drop := maxf(0.45, hall_floor - ground + 0.25)
	_add_merged(bdg, "HallFoundation", [
		[Forge.box(Vector3(hall_w, drop, hall_d)),
			Transform3D(Basis(), Vector3(0, - drop * 0.5, 0))]
	], stone_mat)
	_add_merged(bdg, "HallFloor", [
		[Forge.box(Vector3(hall_w, 0.18, hall_d)),
			Transform3D(Basis(), Vector3(0, -0.09, 0))],
		[Forge.box(Vector3(hall_w - 0.6, 0.025, hall_d - 0.6)),
			Transform3D(Basis(), Vector3(0, 0.02, 0))]
	], floor_mat)
	var court_x := -side * (hall_w * 0.5 + 1.5)
	var court_w := 3.2
	var court_ground := terrain.height_at(
			(bdg_frame.origin + bdg_frame.basis.x * (side * (hall_off - 1.5))).x,
			(bdg_frame.origin + bdg_frame.basis.x * (side * (hall_off - 1.5))).z) if terrain != null else hall_floor - 2.0
	var court_drop := maxf(0.35, hall_floor - court_ground + 0.18)
	_add_merged(bdg, "HallForecourtFoundation", [
		[Forge.box(Vector3(court_w, court_drop, hall_d + 5.0)),
			Transform3D(Basis(), Vector3(court_x, - court_drop * 0.5, 0))]
	], stone_mat)
	_add_merged(bdg, "HallForecourt", [
		[Forge.box(Vector3(court_w + 0.04, 0.12, hall_d + 5.0)),
			Transform3D(Basis(), Vector3(court_x, -0.055, 0))]
	], floor_mat)

	var wall_items := []
	# Rear and end walls.
	wall_items.append([Forge.box(Vector3(0.24, hall_h, hall_d)),
			Transform3D(Basis(), Vector3(outer_x, hall_h * 0.5, 0))])
	for zc: float in [- hall_d * 0.5, hall_d * 0.5]:
		wall_items.append([Forge.box(Vector3(hall_w, hall_h, 0.24)),
				Transform3D(Basis(), Vector3(0, hall_h * 0.5, zc))])
	# Track-side elevation: two glazed bays around the open central entrance.
	var bay_len := hall_d * 0.5 - entry_half
	var bay_z := entry_half + bay_len * 0.5
	for zc: float in [-bay_z, bay_z]:
		wall_items.append([Forge.box(Vector3(0.24, 2.2, bay_len)),
				Transform3D(Basis(), Vector3(inner_x, 1.1, zc))])
		wall_items.append([Forge.box(Vector3(0.24, hall_h - 4.8, bay_len)),
				Transform3D(Basis(), Vector3(inner_x, 4.8 + (hall_h - 4.8) * 0.5, zc))])
		wall_items.append([Forge.box(Vector3(0.045, 2.6, bay_len - 0.3)),
				Transform3D(Basis(), Vector3(inner_x - side * 0.14, 3.5, zc))])
		for mz in range(4):
			var mzz := zc - bay_len * 0.5 + 0.4 + float(mz) * (bay_len - 0.8) / 3.0
			wall_items.append([Forge.box(Vector3(0.08, 2.7, 0.10)),
					Transform3D(Basis(), Vector3(inner_x - side * 0.17, 3.5, mzz))])
	# Entrance header and portal trim.
	wall_items.append([Forge.box(Vector3(0.24, hall_h - 3.9, entry_half * 2.0)),
			Transform3D(Basis(), Vector3(inner_x, 3.9 + (hall_h - 3.9) * 0.5, 0))])
	for zc2: float in [-entry_half, entry_half]:
		wall_items.append([Forge.box(Vector3(0.34, 4.05, 0.18)),
				Transform3D(Basis(), Vector3(inner_x - side * 0.05, 2.025, zc2))])
	wall_items.append([Forge.box(Vector3(0.34, 0.20, entry_half * 2.0 + 0.36)),
			Transform3D(Basis(), Vector3(inner_x - side * 0.05, 4.05, 0))])
	_add_merged(bdg, "HallWalls", wall_items, wall_mat)
	# Low stone plinth around the outside faces.
	var plinth := []
	for zc: float in [- hall_d * 0.5, hall_d * 0.5]:
		plinth.append([Forge.box(Vector3(hall_w + 0.10, 1.05, 0.20)),
				Transform3D(Basis(), Vector3(0, 0.525, zc + signf(zc) * 0.08))])
	plinth.append([Forge.box(Vector3(0.20, 1.05, hall_d + 0.10)),
			Transform3D(Basis(), Vector3(outer_x + side * 0.08, 0.525, 0))])
	_add_merged(bdg, "HallPlinth", plinth, stone_mat)

	# Roof, skylight strip and the canopy over the entrance.
	_add_merged(bdg, "HallRoof", [
		[Forge.box(Vector3(hall_w + 1.4, 0.5, hall_d + 1.6)),
			Transform3D(Basis(), Vector3(0, hall_h + 0.25, 0))],
		[Forge.box(Vector3(hall_w + 1.7, 0.18, hall_d + 1.9)),
			Transform3D(Basis(), Vector3(0, hall_h + 0.58, 0))]
	], roof_mat)
	_add_merged(bdg, "HallSkylight", [
		[Forge.box(Vector3(5.8, 0.08, hall_d * 0.52)),
			Transform3D(Basis(), Vector3(0, hall_h + 0.53, 0))]
	], Gfx.glass(Color(0.20, 0.28, 0.33), 0.08, 0.36))
	var canopy_x := inner_x - side * 1.9
	_add_merged(bdg, "HallCanopy", [
		[Forge.box(Vector3(3.8, 0.24, entry_half * 2.0 + 3.0)),
			Transform3D(Basis(), Vector3(canopy_x, 4.25, 0))],
		[Forge.box(Vector3(3.9, 0.06, entry_half * 2.0 + 3.1)),
			Transform3D(Basis(), Vector3(canopy_x, 4.10, 0))]
	], Gfx.metal(Color(0.31, 0.34, 0.37), 0.46, 0.62))
	var canopy_cols := []
	for cz: float in [-entry_half - 0.9, entry_half + 0.9]:
		canopy_cols.append([Forge.box(Vector3(0.26, 4.15, 0.26)),
				Transform3D(Basis(), Vector3(inner_x - side * 3.55, 2.075, cz))])
	_add_merged(bdg, "HallCanopyColumns", canopy_cols, trim_mat)

	# Interior: columns, ticket counter, benches, information boards and
	# warm ceiling panels. The centre stays clear for walking in from the
	# platform and out through the rear doors.
	var inside := []
	for cx: float in [-4.2, 4.2]:
		for cz: float in [-11.5, 11.5]:
			inside.append([Forge.box(Vector3(0.48, hall_h - 0.5, 0.48)),
					Transform3D(Basis(), Vector3(cx, (hall_h - 0.5) * 0.5, cz))])
	for lz: float in [-12.0, -4.0, 4.0, 12.0]:
		for lx: float in [-2.6, 2.6]:
			inside.append([Forge.box(Vector3(1.25, 0.05, 3.2)),
					Transform3D(Basis(), Vector3(lx, hall_h - 0.30, lz))])
	inside.append([Forge.box(Vector3(0.90, 1.06, 10.5)),
			Transform3D(Basis(), Vector3(outer_x - side * 0.75, 0.53, -8.5))])
	inside.append([Forge.box(Vector3(0.10, 1.05, 10.0)),
			Transform3D(Basis(), Vector3(outer_x - side * 1.40, 1.58, -8.5))])
	for bz: float in [-11.5, 12.5]:
		for k in range(3):
			inside.append([Forge.box(Vector3(4.8, 0.10, 0.56)),
					Transform3D(Basis(), Vector3(-1.0, 0.46, bz + float(k) * 0.76))])
			inside.append([Forge.box(Vector3(4.8, 0.46, 0.08)),
					Transform3D(Basis(), Vector3(-1.0, 0.70, bz + float(k) * 0.76 - 0.28))])
	_add_merged(bdg, "HallInteriorFurniture", inside, Gfx.interior_panel(Color(0.38, 0.40, 0.42), 0.55))
	var ceiling_lights := []
	for lx: float in [-2.6, 2.6]:
		for lz: float in [-12.0, -4.0, 4.0, 12.0]:
			ceiling_lights.append([Forge.box(Vector3(1.20, 0.04, 2.9)),
					Transform3D(Basis(), Vector3(lx, hall_h - 0.36, lz))])
	_add_merged(bdg, "HallCeilingLights", ceiling_lights, light_mat)
	# A setback upper storey and a modest clock tower give the hall a civic
	# silhouette instead of the old single-storey box. Only the exterior is
	# modelled; the ground-floor ticket hall remains the walkable space.
	if settlement != "halt":
		var upper_h := 4.8 if settlement == "city" else 3.5
		var upper_w := hall_w * (0.72 if settlement == "city" else 0.82)
		var upper_d := hall_d * (0.64 if settlement == "city" else 0.76)
		var upper_base := hall_h + 0.28
		_add_merged(bdg, "HallUpperWalls", [
			[Forge.box(Vector3(upper_w, upper_h, upper_d)),
				Transform3D(Basis(), Vector3(0, upper_base + upper_h * 0.5, 0))]
		], wall_mat)
		_add_merged(bdg, "HallUpperCornice", [
			[Forge.box(Vector3(upper_w + 0.8, 0.30, upper_d + 0.8)),
				Transform3D(Basis(), Vector3(0, upper_base + 0.10, 0))],
			[Forge.box(Vector3(upper_w + 0.9, 0.38, upper_d + 0.9)),
				Transform3D(Basis(), Vector3(0, upper_base + upper_h, 0))]
		], trim_mat)
		var upper_glass := []
		for uz: float in [- upper_d * 0.5 - 0.035, upper_d * 0.5 + 0.035]:
			upper_glass.append([Forge.box(Vector3(upper_w * 0.76, upper_h * 0.34, 0.06)),
					Transform3D(Basis(), Vector3(0, upper_base + upper_h * 0.58, uz))])
		for ux: float in [- upper_w * 0.5 - 0.035, upper_w * 0.5 + 0.035]:
			upper_glass.append([Forge.box(Vector3(0.06, upper_h * 0.34, upper_d * 0.72)),
					Transform3D(Basis(), Vector3(ux, upper_base + upper_h * 0.58, 0))])
		_add_merged(bdg, "HallUpperGlazing", upper_glass, glass_mat)
		_add_merged(bdg, "HallUpperRoof", [
			[Forge.box(Vector3(upper_w + 1.2, 0.44, upper_d + 1.2)),
				Transform3D(Basis(), Vector3(0, upper_base + upper_h + 0.22, 0))]
		], roof_mat)
		if settlement == "city":
			var tower_base := upper_base + upper_h + 0.44
			var tower_h := 8.6
			_add_merged(bdg, "HallClockTower", [
				[Forge.box(Vector3(4.8, tower_h, 4.8)),
					Transform3D(Basis(), Vector3(0, tower_base + tower_h * 0.5, 0))],
				[Forge.box(Vector3(5.5, 0.35, 5.5)),
					Transform3D(Basis(), Vector3(0, tower_base + 0.17, 0))]
			], wall_mat)
			_add_merged(bdg, "HallClockTowerGlazing", [
				[Forge.box(Vector3(4.84, 2.2, 0.06)),
					Transform3D(Basis(), Vector3(0, tower_base + tower_h * 0.66, -2.44))],
				[Forge.box(Vector3(4.84, 2.2, 0.06)),
					Transform3D(Basis(), Vector3(0, tower_base + tower_h * 0.66, 2.44))],
				[Forge.box(Vector3(0.06, 2.2, 4.84)),
					Transform3D(Basis(), Vector3(-2.44, tower_base + tower_h * 0.66, 0))],
				[Forge.box(Vector3(0.06, 2.2, 4.84)),
					Transform3D(Basis(), Vector3(2.44, tower_base + tower_h * 0.66, 0))]
			], glass_mat)
			var clock := Gfx.emissive(Color(0.96, 0.94, 0.82), 0.7, Color(0.22, 0.20, 0.16))
			_add_merged(bdg, "HallClockFaces", [
				[Forge.box(Vector3(1.85, 1.85, 0.07)),
					Transform3D(Basis(), Vector3(0, tower_base + tower_h * 0.54, -2.46))],
				[Forge.box(Vector3(1.85, 1.85, 0.07)),
					Transform3D(Basis(), Vector3(0, tower_base + tower_h * 0.54, 2.46))]
			], clock)
			var tower_roof := Forge.lathe(PackedVector2Array([
				Vector2(3.4, 0.0), Vector2(1.8, 1.0), Vector2(0.0, 2.4)
			]), 4, true)
			var roof_mi := MeshInstance3D.new()
			roof_mi.name = "HallClockTowerRoof"
			roof_mi.mesh = tower_roof
			roof_mi.material_override = roof_mat
			roof_mi.position = Vector3(0, tower_base + tower_h, 0)
			roof_mi.rotation.y = deg_to_rad(45.0)
			bdg.add_child(roof_mi)

	# Ticket machines, seating islands, kiosks and information boards keep
	# the hall from reading as an empty concrete room.
	var hall_props := []
	var shop_props := []
	var screen_props := []
	for tz: float in [-10.0, 10.0]:
		hall_props.append([Forge.box(Vector3(0.62, 1.85, 0.62)),
				Transform3D(Basis(), Vector3(inner_x + side * 0.55, 0.93, tz))])
		screen_props.append([Forge.box(Vector3(0.46, 0.42, 0.035)),
				Transform3D(Basis(), Vector3(inner_x + side * 0.86, 1.30, tz))])
	for bz: float in [-7.0, 0.0, 7.0]:
		for bx: float in [-2.7, 2.7]:
			for k in range(2):
				hall_props.append([Forge.box(Vector3(1.8, 0.10, 0.54)),
						Transform3D(Basis(), Vector3(bx, 0.46, bz + float(k) * 0.72))])
				hall_props.append([Forge.box(Vector3(1.8, 0.46, 0.08)),
						Transform3D(Basis(), Vector3(bx, 0.70, bz + float(k) * 0.72 - 0.27))])
	for sz: float in [-15.0, 15.0]:
		shop_props.append([Forge.box(Vector3(2.2, 2.55, 5.2)),
				Transform3D(Basis(), Vector3(outer_x - side * 1.55, 1.28, sz))])
		shop_props.append([Forge.box(Vector3(0.06, 2.05, 4.4)),
				Transform3D(Basis(), Vector3(outer_x - side * 2.70, 1.34, sz))])
		screen_props.append([Forge.box(Vector3(1.4, 0.95, 0.04)),
				Transform3D(Basis(), Vector3(outer_x - side * 2.74, 2.65, sz))])
	for pz: float in [-4.0, 4.0]:
		hall_props.append([Forge.cylinder(0.42, 0.62, 12, 0.0, true, true),
				Transform3D(Basis(), Vector3(-4.6 if pz < 0.0 else 4.6, 0.31, pz))])
		for lx: float in [-0.20, 0.20]:
			hall_props.append([Forge.cylinder(0.035, 0.9, 6, 0.0, true, true),
					Transform3D(Basis(), Vector3(-4.6 + lx if pz < 0.0 else 4.6 + lx, 1.25, pz + lx))])
	_add_merged(bdg, "HallProps", hall_props, Gfx.interior_panel(Color(0.30, 0.32, 0.34), 0.55))
	_add_merged(bdg, "HallKiosks", shop_props, Gfx.interior_panel(Color(0.42, 0.38, 0.32), 0.64))
	_add_merged(bdg, "HallScreens", screen_props, Gfx.emissive(Color(0.24, 0.52, 0.72), 0.75, Color(0.02, 0.04, 0.05)))

	# --- Interactive station hall ---------------------------------------
	# Ticket machine on the platform side of the gates, four ticket gates,
	# two automatic walkways and two coffee kiosks. The gate leaves and the
	# walkway steps are real nodes because they animate; everything else is
	# merged into the hall mesh.
	var gate_steel := Gfx.metal(Color(0.34, 0.37, 0.40), 0.38, 0.78)
	var gate_glass := Gfx.glass(Color(0.13, 0.22, 0.28), 0.055, 0.30)
	var gate_led := Gfx.emissive(Color(0.18, 0.78, 0.46), 1.15, Color(0.01, 0.08, 0.03))
	var ticket_body := Gfx.paint(Color(0.70, 0.73, 0.75), 0.35, 0.18, 0.42)
	var ticket_screen := Gfx.emissive(Color(0.24, 0.56, 0.78), 0.9, Color(0.01, 0.04, 0.06))
	var belt_base := Gfx.metal(Color(0.16, 0.18, 0.20), 0.55, 0.52)
	var belt_step := Gfx.metal(Color(0.34, 0.36, 0.39), 0.42, 0.68)
	var ticket_local := Vector3(inner_x - side * 1.55, 0.0, -entry_half - 1.55)
	var ticket_node := Node3D.new()
	ticket_node.name = "TicketMachine"
	ticket_node.position = ticket_local
	bdg.add_child(ticket_node)
	_add_merged(ticket_node, "TicketMachineBody", [
		[Forge.box(Vector3(0.92, 1.78, 0.58)), Transform3D(Basis(), Vector3(0, 0.89, 0))],
		[Forge.box(Vector3(1.02, 0.10, 0.66)), Transform3D(Basis(), Vector3(0, 1.82, 0))],
		[Forge.box(Vector3(0.58, 0.20, 0.30)), Transform3D(Basis(), Vector3(0, 1.10, 0.18))]
	], ticket_body)
	_add_merged(ticket_node, "TicketMachineScreen", [
		[Forge.box(Vector3(0.05, 0.52, 0.70)),
			Transform3D(Basis(), Vector3(-side * 0.47, 1.18, 0))]
	], ticket_screen)
	var ticket_label := Label3D.new()
	ticket_label.text = "自动售票机\nE 取票"
	ticket_label.font_size = 34
	ticket_label.pixel_size = 0.0028
	ticket_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ticket_label.modulate = Color(0.82, 0.94, 1.0)
	ticket_label.outline_size = 6
	ticket_label.outline_modulate = Color(0.02, 0.04, 0.07)
	ticket_label.position = Vector3(0, 2.16, 0)
	ticket_node.add_child(ticket_label)
	hall_spots.append({
		"type": "ticket", "station": station_index,
		"pos": bdg.to_global(ticket_local + Vector3(-side * 0.55, 1.05, 0)),
		"name": "自动售票机",
	})

	var gate_x := inner_x - side * 0.45
	var gate_index := 0
	var gate_leaf_mesh := Forge.box(Vector3(0.05, 1.34, 0.94))
	var gate_leaf_vframe := Forge.box(Vector3(0.065, 1.34, 0.035))
	var gate_leaf_hframe := Forge.box(Vector3(0.065, 0.035, 0.94))
	for gz: float in [-3.6, -1.2, 1.2, 3.6]:
		var gate := Node3D.new()
		gate.name = "TicketGate%d" %gate_index
		gate.position = Vector3(gate_x, 0, gz)
		bdg.add_child(gate)
		var gate_parts := []
		for pz: float in [-1.08, 1.08]:
			gate_parts.append([Forge.box(Vector3(0.30, 1.62, 0.16)),
				Transform3D(Basis(), Vector3(0, 0.81, pz))])
			gate_parts.append([Forge.box(Vector3(0.52, 0.08, 0.48)),
				Transform3D(Basis(), Vector3(0, 0.04, pz))])
		gate_parts.append([Forge.box(Vector3(0.32, 0.16, 2.34)),
			Transform3D(Basis(), Vector3(0, 1.60, 0))])
		gate_parts.append([Forge.box(Vector3(0.12, 0.05, 1.92)),
			Transform3D(Basis(), Vector3(0, 1.52, 0))])
		_add_merged(gate, "GateFrame", gate_parts, gate_steel)
		_add_merged(gate, "GateLed", [
			[Forge.box(Vector3(0.06, 0.05, 1.88)),
				Transform3D(Basis(), Vector3(-side * 0.17, 1.53, 0))]
		], gate_led)
		for leaf_i in range(2):
			var leaf := MeshInstance3D.new()
			leaf.name = "GateLeaf%d" %leaf_i
			leaf.mesh = gate_leaf_mesh
			leaf.material_override = gate_glass
			leaf.position = Vector3(0, 0.78, -0.49 if leaf_i == 0 else 0.49)
			leaf.set_meta("leaf_base_z", leaf.position.z)
			leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for fz: float in [-0.45, 0.45]:
				var edge := MeshInstance3D.new()
				edge.mesh = gate_leaf_vframe
				edge.material_override = gate_steel
				edge.position = Vector3(0, 0, fz)
				leaf.add_child(edge)
			for fy: float in [-0.66, 0.66]:
				var edge2 := MeshInstance3D.new()
				edge2.mesh = gate_leaf_hframe
				edge2.material_override = gate_steel
				edge2.position = Vector3(0, fy, 0)
				leaf.add_child(edge2)
			gate.add_child(leaf)
		gate.set_meta("gate_open", false)
		gate.set_meta("gate_station", station_index)
		hall_gates.append({
			"node": gate, "station": station_index, "open_until": 0.0,
			"anim": 0.0, "half_w": 1.18, "half_d": 0.30,
		})
		hall_spots.append({
			"type": "gate", "station": station_index,
			"pos": bdg.to_global(Vector3(gate_x, 1.10, gz)),
			"name": "检票闸机",
		})
		gate_index += 1
	var gate_label := Label3D.new()
	gate_label.text = "检票口  E 验票通过"
	gate_label.font_size = 36
	gate_label.pixel_size = 0.0028
	gate_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	gate_label.modulate = Color(0.66, 1.0, 0.78)
	gate_label.outline_size = 6
	gate_label.outline_modulate = Color(0.02, 0.05, 0.04)
	gate_label.position = bdg.to_global(Vector3(gate_x, 2.45, 0))
	group.add_child(gate_label)

	for tz: float in [-10.0, 10.0]:
		hall_spots.append({
			"type": "ticket", "station": station_index,
			"pos": bdg.to_global(Vector3(inner_x + side * 0.95, 1.30, tz)),
			"name": "自动售票机",
		})

	for sz: float in [-15.0, 15.0]:
		hall_spots.append({
			"type": "shop", "station": station_index,
			"pos": bdg.to_global(Vector3(outer_x - side * 3.05, 1.15, sz)),
			"name": "车站咖啡", "price": 15,
		})
		var shop_label := Label3D.new()
		shop_label.text = "咖啡 / 热饮  ¥15\nE 购买"
		shop_label.font_size = 32
		shop_label.pixel_size = 0.0027
		shop_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		shop_label.modulate = Color(1.0, 0.86, 0.55)
		shop_label.outline_size = 6
		shop_label.outline_modulate = Color(0.06, 0.035, 0.01)
		shop_label.position = bdg.to_global(Vector3(outer_x - side * 3.05, 2.75, sz))
		group.add_child(shop_label)

	# Automatic walkways: flat escalator-style belts with moving treads.
	var belt_specs := [
		{"x": outer_x - side * 2.45, "dir": 1.0, "name": "WalkwayA"},
		{"x": outer_x - side * 4.20, "dir": -1.0, "name": "WalkwayB"},
	]
	var belt_step_mesh := Forge.box(Vector3(1.30, 0.045, 0.56))
	for spec: Dictionary in belt_specs:
		var belt := Node3D.new()
		belt.name = String(spec["name"])
		belt.position = Vector3(float(spec["x"]), 0, 0)
		bdg.add_child(belt)
		_add_merged(belt, "WalkwayBase", [
			[Forge.box(Vector3(1.48, 0.16, 16.4)), Transform3D(Basis(), Vector3(0, 0.08, 0))],
			[Forge.box(Vector3(0.10, 0.28, 16.4)), Transform3D(Basis(), Vector3(-0.74, 0.20, 0))],
			[Forge.box(Vector3(0.10, 0.28, 16.4)), Transform3D(Basis(), Vector3(0.74, 0.20, 0))]
		], belt_base)
		_add_merged(belt, "WalkwayRails", [
			[Forge.box(Vector3(0.06, 0.06, 16.0)), Transform3D(Basis(), Vector3(-0.78, 0.55, 0))],
			[Forge.box(Vector3(0.06, 0.06, 16.0)), Transform3D(Basis(), Vector3(0.78, 0.55, 0))],
			[Forge.box(Vector3(0.06, 0.05, 0.06)), Transform3D(Basis(), Vector3(-0.78, 0.31, -8.0))],
			[Forge.box(Vector3(0.06, 0.05, 0.06)), Transform3D(Basis(), Vector3(0.78, 0.31, -8.0))],
			[Forge.box(Vector3(0.06, 0.05, 0.06)), Transform3D(Basis(), Vector3(-0.78, 0.31, 8.0))],
			[Forge.box(Vector3(0.06, 0.05, 0.06)), Transform3D(Basis(), Vector3(0.78, 0.31, 8.0))]
		], gate_steel)
		var steps: Array = []
		for si in range(28):
			var step := MeshInstance3D.new()
			step.name = "Step%d" %si
			step.mesh = belt_step_mesh
			step.material_override = belt_step
			step.position = Vector3(0, 0.115, -8.0 + float(si) * 16.0 / 28.0)
			step.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			belt.add_child(step)
			steps.append(step)
		hall_belts.append({
			"node": belt, "station": station_index, "steps": steps,
			"dir": float(spec["dir"]), "speed": 1.9,
			"half_x": 0.72, "half_z": 8.0, "carry": 1.35,
		})
		var belt_label := Label3D.new()
		belt_label.text = "自动步道  ▶" if float(spec["dir"]) > 0.0 else "◀  自动步道"
		belt_label.font_size = 30
		belt_label.pixel_size = 0.0026
		belt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		belt_label.modulate = Color(0.64, 0.90, 1.0)
		belt_label.outline_size = 5
		belt_label.outline_modulate = Color(0.01, 0.03, 0.06)
		belt_label.position = bdg.to_global(Vector3(float(spec["x"]), 2.05, 0))
		group.add_child(belt_label)

	var depart := MeshInstance3D.new()
	depart.name = "HallDepartureBoard"
	depart.mesh = Forge.box(Vector3(6.6, 0.75, 0.12))
	depart.material_override = Gfx.emissive(Color(0.05, 0.08, 0.12), 0.6, Color(0.01, 0.02, 0.03))
	depart.position = Vector3(0, hall_h - 1.35, 5.8)
	bdg.add_child(depart)
	var depart_label := Label3D.new()
	depart_label.text = "检票口  A1    B2        候车厅  /  售票厅"
	depart_label.font_size = 44
	depart_label.pixel_size = 0.0032
	depart_label.modulate = Color(0.55, 0.92, 0.72)
	depart_label.outline_size = 0
	depart_label.position = Vector3(0, hall_h - 1.35, 5.89)
	bdg.add_child(depart_label)

	var hall_label := Label3D.new()
	hall_label.name = "HallName"
	hall_label.text = station_name
	hall_label.font_size = 92
	hall_label.pixel_size = 0.010
	hall_label.modulate = Color(0.97, 0.95, 0.88)
	hall_label.outline_size = 13
	hall_label.outline_modulate = Color(0.05, 0.07, 0.10)
	hall_label.transform = Transform3D(Basis(), Vector3(outer_x - side * 0.18, 3.5, 2.5))
	hall_label.rotation.y = -side * PI * 0.5
	bdg.add_child(hall_label)
	if station_index >= 0 and station_index < Config.STATIONS.size() \
			and bool(Config.STATIONS[station_index].get("branch", false)):
		var branch_label := Label3D.new()
		branch_label.text = "东环支线"
		branch_label.font_size = 44
		branch_label.pixel_size = 0.0055
		branch_label.modulate = Color(0.48, 0.80, 1.0)
		branch_label.outline_size = 7
		branch_label.outline_modulate = Color(0.04, 0.08, 0.14)
		branch_label.transform = Transform3D(Basis(), Vector3(outer_x - side * 0.18, 2.55, 2.5))
		branch_label.rotation.y = -side * PI * 0.5
		bdg.add_child(branch_label)
	var hall_light := OmniLight3D.new()
	hall_light.position = Vector3(0, hall_h - 1.0, 0)
	hall_light.omni_range = 19.0
	hall_light.light_energy = 1.25 if Config.quality > Config.Quality.LOW else 0.75
	hall_light.light_color = Color(1.0, 0.91, 0.76)
	hall_light.shadow_enabled = false
	bdg.add_child(hall_light)

	var sign_basis := bdg_basis * Basis(Vector3.UP, -side * PI * 0.5)
	var sign := _station_sign(station_name)
	sign.transform = Transform3D(sign_basis,
			bdg_pos + bdg_basis.x * (inner_x - side * 0.30) + Vector3.UP * (hall_h - 1.6))
	group.add_child(sign)

func _add_merged(parent: Node3D, nm: String, items: Array, mat: Material) -> void:
	if items.is_empty():
		return
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = Forge.merge_all(items)
	mi.material_override = mat
	parent.add_child(mi)

func _station_sign(text: String, with_posts := false) -> Node3D:
	var root := Node3D.new()
	root.name = "StationSign"
	var board := MeshInstance3D.new()
	board.mesh = Forge.box(Vector3(7.0, 1.8, 0.18))
	board.material_override = Gfx.paint(Color(0.1, 0.16, 0.28), 0.5, 0.3, 0.4)
	root.add_child(board)
	if with_posts:
		var post_items := []
		for px: float in [-2.55, 2.55]:
			post_items.append([Forge.box(Vector3(0.16, 3.2, 0.16)),
					Transform3D(Basis(), Vector3(px, -1.60, -0.10))])
			post_items.append([Forge.box(Vector3(0.36, 0.10, 0.36)),
					Transform3D(Basis(), Vector3(px, -3.20, -0.10))])
		var posts := MeshInstance3D.new()
		posts.name = "SignPosts"
		posts.mesh = Forge.merge_all(post_items)
		posts.material_override = Gfx.metal(Color(0.32, 0.34, 0.36), 0.5, 0.65)
		root.add_child(posts)
	var label := Label3D.new()
	label.text = text
	label.font_size = 200
	label.pixel_size = 0.0068
	label.modulate = Color(1.0, 0.96, 0.9)
	label.outline_size = 22
	label.outline_modulate = Color(0.05, 0.08, 0.14)
	label.position = Vector3(0, 0, 0.12)
	label.no_depth_test = false
	root.add_child(label)
	var label2 := label.duplicate() as Label3D
	label2.position = Vector3(0, 0, -0.12)
	label2.rotation_degrees = Vector3(0, 180, 0)
	root.add_child(label2)
	return root



func _prepare_mode_state() -> void:
	mode = String(initial_state.get("mode", "open"))
	free_drive = bool(initial_state.get("free_drive", false))
	var is_new := bool(initial_state.get("__new", false))
	if mode == "test":
		career = _default_career()
		career ["money"] = 1000000000
		career ["owned"] = CAREER_ALL_OWNED.duplicate()
		career ["level"] = 6
		career ["xp"] = 12000
		current_job = {}
		start_kind = "test"
		start_distance = 30.0
	elif mode == "open":
		career = initial_state.get("career", {}).duplicate(true)
		if career.is_empty():
			career = _default_career()
		career ["money"] = 1000000000
		career ["owned"] = CAREER_ALL_OWNED.duplicate()
		career ["level"] = maxi(6, int(career.get("level", 1)))
		career ["xp"] = maxi(12000, int(career.get("xp", 0)))
		current_job = {}
		start_kind = String(initial_state.get("train", {}).get("kind", "container"))
		if start_kind == "":
			start_kind = "container"
	else:
		career = initial_state.get("career", {}).duplicate(true)
		if career.is_empty():
			career = _default_career()
		career ["owned"] = career.get("owned", ["electric"])
		career ["money"] = int(career.get("money", 20000))
		career ["xp"] = int(career.get("xp", 0))
		career ["level"] = _level_for_xp(int(career ["xp"]))
		career ["completed"] = int(career.get("completed", 0))
		career ["earnings"] = int(career.get("earnings", 0))
		career ["job_seq"] = int(career.get("job_seq", 1))
		current_job = career.get("current_job", {}).duplicate(true)
		if current_job.is_empty():
			current_job = _make_job(career ["job_seq"] * 977 + 31)
			career ["job_seq"] = int(career ["job_seq"]) + 1
			career ["current_job"] = current_job
			career ["job_finished"] = false
		else:
			_localize_job_cargo(current_job)
			_sanitize_job_indices(current_job)
			career ["current_job"] = current_job
		var last_result = career.get("last_result", {})
		if last_result is Dictionary and not last_result.is_empty():
			_localize_job_cargo(last_result)
			career ["last_result"] = last_result
		start_kind = String(current_job.get("kind", "electric"))
		if is_new and not station_data.is_empty():
			var oi := clampi(int(current_job.get("origin", 0)), 0, station_data.size() - 1)
			start_distance = float(station_data [oi] ["stop"])
	var train_state: Dictionary = initial_state.get("train", {})
	engine_id = String(train_state.get("engine", "standard"))
	skin_id = String(train_state.get("skin", "classic"))
	transmission_id = String(train_state.get("transmission", "balanced"))
	if not Vehicles.LOCO_ENGINES.has(engine_id):
		engine_id = "standard"
	if not Vehicles.LOCO_SKINS.has(skin_id):
		skin_id = "classic"
	if not Vehicles.LOCO_TRANSMISSIONS.has(transmission_id):
		transmission_id = "balanced"
	if mode == "test":
		# Test mode always uses the fixed high-power locomotive package.
		engine_id = "standard"
		skin_id = "classic"
		transmission_id = "balanced"
		part_ids.clear()
	custom_cars.clear()
	custom_loco_count = 1
	custom_loaded = true
	var consist_state: Dictionary = {}
	var raw_consist = train_state.get("consist", {})
	if raw_consist is Dictionary:
		consist_state = raw_consist
	if not consist_state.is_empty():
		custom_loco_count = clampi(int(consist_state.get("locos", 1)), 1, 2)
		custom_loaded = bool(consist_state.get("loaded", true))
		var raw_cars = consist_state.get("cars", [])
		if raw_cars is Array:
			var san := ConsistCatalog.sanitize(raw_cars, custom_loco_count)
			custom_cars.clear()
			for c in san["cars"]:
				custom_cars.append(String(c))
			custom_loco_count = int(san["locos"])
	if start_kind == "custom" and consist_state.is_empty():
		start_kind = "container"
	part_ids.clear()
	var raw_parts = train_state.get("parts", [])
	if raw_parts is Array:
		for p in raw_parts:
			var pid := String(p)
			if Vehicles.LOCO_PARTS.has(pid) and not part_ids.has(pid):
				part_ids.append(pid)
	print("[mode] %s | 资金=%d | 已拥有=%s | 编组=%s | 引擎=%s | 变速箱=%s | 皮肤=%s | 部件=%s" %[
		mode, int(career.get("money", 0)), str(career.get("owned", [])), start_kind,
		engine_id, transmission_id, skin_id, str(part_ids)
	])


func _default_career() -> Dictionary:
	return {
		"money": 20000,
		"owned": ["container", "hopper"],
		"xp": 0,
		"level": 1,
		"completed": 0,
		"earnings": 0,
		"job_seq": 1,
		"current_job": {},
		"job_finished": false,
		"last_result": {},
	}


func _level_for_xp(xp: int) -> int:
	var lvl := 1
	for i in range(CAREER_LEVEL_XP.size()):
		if xp >= int(CAREER_LEVEL_XP [i]):
			lvl = i + 1
	return mini(lvl, CAREER_LEVEL_XP.size())


func _is_vehicle_owned(kind: String) -> bool:
	if mode == "open":
		return true
	var owned: Array = career.get("owned", [])
	if kind in ["hopper", "container", "electric"]:
		return true
	return owned.has(kind)


func _localize_job_cargo(job: Dictionary) -> void:
	match String(job.get("cargo", "")):
		"Container":
			job["cargo"] = "集装箱"
		"Empty cars":
			job["cargo"] = "空车皮"
		"Passengers":
			job["cargo"] = "旅客"

func _sanitize_job_indices(job: Dictionary) -> void:
	if job.is_empty() or station_data.is_empty():
		return
	var n := station_data.size()
	var oi := clampi(int(job.get("origin", 0)), 0, n - 1)
	var di := clampi(int(job.get("dest", (oi + 1) % n)), 0, n - 1)
	if di == oi:
		di = (oi + 1) % n
	job["origin"] = oi
	job["dest"] = di
	if route != null:
		var d0 := Config.station_dist(route, oi)
		var d1 := Config.station_dist(route, di)
		var dist := route.wrap_dist(d1 - d0)
		if dist < 100.0:
			dist += route.total
		job["distance"] = dist


func _make_job(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + 104729
	var n := station_data.size()
	if n < 3:
		return {}
	var origin := rng.randi_range(0, n - 1)
	var ahead := rng.randi_range(2, 5)
	var dest := (origin + ahead) % n
	var kinds := ["container", "hopper"]
	var kind: String = kinds [rng.randi_range(0, kinds.size() - 1)]
	var is_container := kind == "container"
	var cargo := "集装箱" if is_container else "空车皮"
	var weight := 760.0 if is_container else 300.0
	var limit := 85.0 if is_container else 90.0
	var d0 := Config.station_dist(route, origin)
	var d1 := Config.station_dist(route, dest)
	var dist := route.wrap_dist(d1 - d0)
	if dist < 100.0:
		dist += route.total
	var owned := _is_vehicle_owned(kind)
	var pay := int(dist / 1000.0 * 54.0 + weight * 0.55 + 420.0)
	if owned:
		pay = int(float(pay) * 1.2)
	var speed := limit / 3.6
	var time_limit := int(dist / maxf(speed, 10.0) * 1.45 + 210.0)
	return {
		"number": "X%d" %rng.randi_range(1000, 9899),
		"cargo": cargo,
		"unit": "t",
		"kind": kind,
		"loaded": is_container,
		"weight": weight,
		"origin": origin,
		"dest": dest,
		"limit": limit,
		"time_limit": float(time_limit),
		"load_time": 21.0 if is_container else 9.0,
		"unload_time": 18.0 if is_container else 7.0,
		"reward": pay,
		"distance": dist,
		"owned": owned,
		"siding": false,
		"seed": seed_value,
	}


func get_career_offers() -> Array:
	var out: Array = []
	var base := int(career.get("job_seq", 1))
	for i in range(6):
		out.append(_make_job(base * 977 + i * 173 + 31))
	return out


func _preset_job(def: Dictionary) -> Dictionary:
	var job := def.duplicate(true)
	if station_data.is_empty():
		return job
	var n := station_data.size()
	var oi := clampi(int(job.get("origin", 0)), 0, n - 1)
	var di := clampi(int(job.get("dest", (oi + 1) % n)), 0, n - 1)
	if di == oi:
		di = (oi + 1) % n
	job["origin"] = oi
	job["dest"] = di
	var d0 := float(station_data[oi].get("dist", 0.0))
	var d1 := float(station_data[di].get("dist", 0.0))
	var dist := route.wrap_dist(d1 - d0) if route != null else 0.0
	if dist < 100.0 and route != null:
		dist += route.total
	job["distance"] = dist
	var speed := float(job.get("limit", 80.0)) / 3.6
	job["time_limit"] = maxf(float(job.get("time_limit", 1800.0)),
			dist / maxf(speed, 10.0) * 1.35 + 180.0)
	job["reward"] = int(float(job.get("reward", 5000.0)) + dist * 0.04)
	job["owned"] = _is_vehicle_owned(String(job.get("kind", "container")))
	job["siding"] = false
	job["seed"] = 0
	return job


func get_preset_missions() -> Array:
	var out: Array = []
	for def: Dictionary in PRESET_MISSIONS:
		out.append(_preset_job(def))
	return out


func start_preset(index: int) -> void:
	var presets := get_preset_missions()
	if index < 0 or index >= presets.size() or train == null:
		return
	free_drive = false
	_free_resume_job = {}
	current_job = presets[index].duplicate(true)
	if mode == "career":
		career["current_job"] = current_job
		career["job_finished"] = false
	_ensure_career_panel()
	if career_panel != null:
		career_panel.visible = false
	_rebuild_consist(String(current_job.get("kind", "container")), bool(current_job.get("loaded", true)))
	if mission != null:
		mission.single_job = true
		mission.begin_job(current_job, int(career.get("money", 0)), int(career.get("completed", 0)))
		mission.money = int(career.get("money", 0))
		mission.completed = int(career.get("completed", 0))
	var oi := clampi(int(current_job.get("origin", 0)), 0, station_data.size() - 1)
	train.distance = float(station_data[oi]["stop"])
	train.speed = 0.0
	train.brake_cylinder = 4.5
	train.set_gear(Train.GEAR_P3)
	train.doors_open = false
	train.door_open_side = 0
	train.place()
	if startup != null:
		startup.prepare_for_service()
	if hud != null:
		hud.task_panel.visible = true
		hud.set_progress(0.0, false)
		hud.toast("已开始预设任务：%s" %String(current_job.get("title", current_job.get("number", ""))), 3.2)
	_close_career_panel()
	save_now(true)


func start_free_drive() -> void:
	if train == null:
		return
	if not current_job.is_empty() and not free_drive:
		_free_resume_job = current_job.duplicate(true)
	free_drive = true
	if mission != null:
		mission.tasks = []
		mission.task = {}
		mission.index = -1
		mission.phase = MissionSystem.Phase.DONE
		mission.progress = 0.0
		mission.single_job = true
	if hud != null:
		hud.task_panel.visible = false
		hud.set_progress(0.0, false)
		hud.toast("自由驾驶：可在任务中心选择任意车站前往", 3.0)
	if career_panel != null:
		career_panel.refresh()
	save_now(true)


func free_drive_goto(index: int) -> void:
	if train == null or index < 0 or index >= station_data.size():
		return
	free_drive = true
	autopilot = false
	train.distance = float(station_data[index]["stop"])
	train.speed = 0.0
	train.brake_cylinder = 4.5
	train.handbrake = true
	train.doors_open = false
	train.door_open_side = 0
	train.set_gear(Train.GEAR_P3)
	train.place()
	if startup != null:
		startup.prepare_for_service()
	if rig != null:
		rig.set_mode(CameraRig.Mode.CHASE)
	if hud != null:
		hud.toast("已到达 %s，停放制动已施加" %String(station_data[index]["name"]), 2.6)


func resume_current_job() -> void:
	var job := _free_resume_job if not _free_resume_job.is_empty() else current_job
	if job.is_empty():
		return
	free_drive = false
	_free_resume_job = {}
	if mode == "career":
		accept_job(job)
	else:
		var presets := get_preset_missions()
		for i in range(presets.size()):
			if String(presets[i].get("id", "")) == String(job.get("id", "")):
				start_preset(i)
				return


func accept_job(job: Dictionary) -> void:
	if mode != "career" or job.is_empty():
		return
	current_job = job.duplicate(true)
	career ["current_job"] = current_job
	career ["job_finished"] = false
	career ["job_seq"] = int(career.get("job_seq", 1)) + 1
	start_kind = String(current_job.get("kind", "electric"))
	start_distance = -1.0
	_ensure_career_panel()
	if career_panel != null:
		career_panel.visible = false
	var oi := clampi(int(current_job.get("origin", 0)), 0, station_data.size() - 1)
	if mission != null:
		mission.begin_job(current_job, int(career.get("money", 0)), int(career.get("completed", 0)))
	train.distance = float(station_data [oi] ["stop"])
	train.speed = 0.0
	train.brake_cylinder = 4.5
	train.set_gear(Train.GEAR_P3)
	train.place()
	if startup != null:
		startup.prepare_for_service()
	if hud != null:
		hud.toast("已接单：%s → %s" %[
			String(station_data [int(current_job["origin"])] ["name"]),
			String(station_data [int(current_job["dest"])] ["name"])
		], 3.0)
	_close_career_panel()
	save_now(true)


func buy_vehicle(id: String) -> String:
	if mode != "career":
		return "开放模式已解锁全部车辆"
	for v: Dictionary in CAREER_CATALOG:
		if String(v ["id"]) != id:
			continue
		var owned: Array = career.get("owned", [])
		if id in owned or (id == "electric" and owned.has("electric")):
			return "已拥有该车辆"
		var lvl := int(career.get("level", 1))
		if lvl < int(v ["level"]):
			return "需要等级 %d" %int(v ["level"])
		var price := int(v ["price"])
		if int(career.get("money", 0)) < price:
			return "资金不足，需要 ¥%d" %price
		career ["money"] = int(career.get("money", 0)) - price
		owned.append(id)
		career ["owned"] = owned
		if mission != null:
			mission.money = int(career ["money"])
		save_now(true)
		return "已购买：%s" %String(v ["name"])
	return "未找到车辆"


func select_consist(kind: String) -> void:
	if mode != "open":
		return
	start_kind = kind
	_rebuild_consist(kind, true)
	if career_panel != null:
		career_panel.refresh()
	save_now(true)


func apply_custom_consist(cars: Array, locos: int, loaded: bool) -> Dictionary:
	if mode != "open":
		return {"ok": false, "message": "列车编组仅在创造模式可用"}
	if train == null or route == null:
		return {"ok": false, "message": "列车尚未生成"}
	var normalized: Array[String] = []
	for raw in cars:
		normalized.append(String(raw))
	var check := ConsistCatalog.validate(normalized, locos, loaded, engine_id, transmission_id)
	if not bool(check.get("ok", false)):
		return {"ok": false, "message": String(check.get("message", "编组不可用"))}
	var summary := ConsistCatalog.compute(normalized, locos, loaded, engine_id, transmission_id)
	var distance := train.distance
	var speed := train.speed
	var gear := train.gear
	var reverser := train.reverser
	var doors := train.doors_open
	var door_side := train.door_open_side
	var cab_door_only := train.cab_door_only
	var lights := train.head_lights_on
	var high_beam := train.high_beam_on
	var handbrake := train.handbrake
	var brake := train.brake_cylinder
	var startup_state: Dictionary = startup.serialize() if startup != null else {}
	custom_cars = normalized.duplicate()
	custom_loco_count = clampi(locos, 1, 2)
	custom_loaded = loaded
	start_kind = "custom"
	train.service_name = _service_name_for("custom")
	for v in train.vehicles:
		train.remove_child(v)
		v.queue_free()
	train.setup(route, _make_consist("custom", true))
	train.lead_cab_only = true
	train_def = _train_def_for("custom")
	if startup != null:
		startup.def = train_def
		startup.recapture_base()
		if not startup_state.is_empty():
			startup.restore(startup_state)
		startup.apply_physics()
	train.distance = distance
	train.speed = speed
	train.reverser = reverser
	train.set_gear(gear)
	train.doors_open = doors
	train.door_open_side = door_side
	train.cab_door_only = cab_door_only
	train.door_anim = 0.0
	train.set_light_state(lights)
	train.set_high_beam(high_beam)
	train.handbrake = handbrake
	train.brake_cylinder = brake
	train.place()
	if interaction != null:
		interaction.rebuild()
	if career_panel != null:
		career_panel.refresh()
	save_now(true)
	return {
		"ok": true,
		"message": "已应用：%d 台机车 + %d 节车厢 · %.1f / %.0f m" %[
			int(summary["loco_count"]), int(summary["car_count"]),
			float(summary["length"]), float(summary["limit"])],
		"summary": summary,
	}


func _ensure_consist_panel() -> void:
	if consist_panel != null:
		return
	consist_panel = ConsistPanelScript.new()
	consist_panel.name = "ConsistPanel"
	consist_panel.layer = 35
	add_child(consist_panel)
	consist_panel.closed.connect(_on_consist_panel_closed)


func open_consist_panel(from := "pause") -> void:
	if mode != "open":
		if hud != null:
			hud.toast("列车编组仅在创造模式可用", 2.6)
		return
	_ensure_consist_panel()
	_consist_return = from
	if pause_menu != null:
		pause_menu.close()
	if career_panel != null:
		career_panel.visible = false
	paused = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_sync_walk_crosshair()
	consist_panel.open(self, from)


func _on_consist_panel_closed(resume: bool) -> void:
	if consist_panel != null:
		consist_panel.visible = false
	if resume:
		_resume_game()
		if hud != null:
			hud.toast("列车编组已应用", 2.4)
		return
	if _consist_return == "career" and career_panel != null and mode == "open":
		paused = true
		get_tree().paused = true
		career_panel.open(self)
	else:
		paused = true
		get_tree().paused = true
		if pause_menu != null:
			pause_menu.open()


func apply_customization(new_engine: String, new_skin: String, new_transmission := "balanced", new_parts: Array = []) -> String:
	if mode == "test" and (new_engine != engine_id or new_transmission != transmission_id):
		return "测试模式动力已锁定，无法调整发动机或变速箱"
	if not Vehicles.LOCO_ENGINES.has(new_engine):
		return "未知引擎"
	if not Vehicles.LOCO_SKINS.has(new_skin):
		return "未知皮肤"
	if not Vehicles.LOCO_TRANSMISSIONS.has(new_transmission):
		return "未知变速箱"
	var normalized_parts: Array[String] = []
	for p in new_parts:
		var pid := String(p)
		if Vehicles.LOCO_PARTS.has(pid) and not normalized_parts.has(pid):
			normalized_parts.append(pid)
	normalized_parts.sort()
	var current_parts := part_ids.duplicate()
	current_parts.sort()
	if new_engine == engine_id and new_skin == skin_id \
			and new_transmission == transmission_id and current_parts == normalized_parts:
		return "当前已是这套改装"
	if train == null:
		return "列车尚未生成"
	var distance := train.distance
	var speed := train.speed
	var gear := train.gear
	var reverser := train.reverser
	var doors := train.doors_open
	var door_side := train.door_open_side
	var cab_door_only := train.cab_door_only
	var lights := train.head_lights_on
	var high_beam := train.high_beam_on
	var handbrake := train.handbrake
	var brake := train.brake_cylinder
	var startup_state: Dictionary = startup.serialize() if startup != null else {}
	engine_id = new_engine
	skin_id = new_skin
	transmission_id = new_transmission
	part_ids = normalized_parts
	_rebuild_consist(start_kind, true)
	train.distance = distance
	train.speed = speed
	train.reverser = reverser
	train.set_gear(gear)
	train.doors_open = doors
	train.door_open_side = door_side
	train.cab_door_only = cab_door_only
	train.door_anim = 0.0
	train.set_light_state(lights)
	train.set_high_beam(high_beam)
	train.handbrake = handbrake
	train.brake_cylinder = brake
	train.place()
	if startup != null:
		if not startup_state.is_empty():
			startup.restore(startup_state)
		startup.apply_physics()
	save_now(true)
	return "已应用：%s · %s · %s" %[
		String(Vehicles.engine_info(engine_id)["name"]),
		String(Vehicles.transmission_info(transmission_id)["name"]),
		String(Vehicles.skin_info(skin_id)["name"]),
	]

func _ensure_tuning_panel() -> void:
	if tuning_panel != null:
		return
	tuning_panel = TuningPanelScript.new()
	tuning_panel.name = "TuningPanel"
	tuning_panel.layer = 34
	add_child(tuning_panel)
	tuning_panel.closed.connect(close_tuning_panel)

func open_tuning_panel(category := "parts") -> void:
	_ensure_tuning_panel()
	if pause_menu != null:
		pause_menu.close()
	paused = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_sync_walk_crosshair()
	tuning_panel.open(self, category)

func close_tuning_panel() -> void:
	if tuning_panel != null:
		tuning_panel.visible = false
	if pause_menu != null:
		paused = true
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		pause_menu.open()
	else:
		get_tree().paused = false
		paused = false
		_restore_mouse_mode()
	_sync_walk_crosshair()


func _ensure_career_panel() -> void:
	if career_panel != null:
		return
	career_panel = CareerPanel.new()
	career_panel.name = "CareerPanel"
	career_panel.layer = 32
	add_child(career_panel)
	career_panel.closed.connect(_close_career_panel)


func open_career_panel() -> void:
	_ensure_career_panel()
	if pause_menu != null:
		pause_menu.close()
	paused = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_sync_walk_crosshair()
	career_panel.open(self)


func _close_career_panel() -> void:
	if career_panel != null:
		career_panel.visible = false
	get_tree().paused = false
	paused = false
	_restore_mouse_mode()
	_sync_walk_crosshair()


func _on_career_task_finished(_index: int, result: Dictionary) -> void:
	if mode != "career":
		return
	career ["money"] = mission.money if mission != null else int(career.get("money", 0))
	career ["completed"] = mission.completed if mission != null else int(career.get("completed", 0))
	career ["earnings"] = int(career.get("earnings", 0)) + int(result.get("score", 0))
	career ["last_result"] = result
	career ["job_finished"] = true
	var cur_xp := int(career.get("xp", 0)) + int(float(result.get("score", 0)) * 0.45 + float(current_job.get("distance", 0.0)) / 1000.0 * 9.0)
	career ["xp"] = cur_xp
	career ["level"] = _level_for_xp(cur_xp)
	career ["current_job"] = current_job
	save_now(true)
	if hud != null:
		hud.toast("任务完成 · 收入 ¥%d · 经验 +%d" %[int(result.get("score", 0)), cur_xp], 4.0)


func _on_career_all_done() -> void:
	if mode == "career":
		open_career_panel()


func _build_train() -> void:
	train = Train.new()
	train.name = "Train"
	add_child(train)
	train.setup(route, _make_consist(start_kind, true))
	if mode == "test":
		train.test_mode = true
		train.max_tractive_force = 1800000.0
		train.power_knee_kmh = 120.0
		for tv in train.vehicles:
			if tv.kind == "loco":
				tv.tractive_force = 1800000.0
		var min_radius := INF
		var max_grade := 0.0
		var probe := 0.0
		while probe < route.total:
			var curv := route.curvature_at(probe)
			if curv > 0.000001:
				min_radius = minf(min_radius, 1.0 / curv)
			max_grade = maxf(max_grade, absf(route.gradient_at(probe)))
			probe += 10.0
		print("[test-mode] 线路 %.2f km | 最小曲线半径 %.0f m | 最大坡度 %.1f%% | 固定牵引 %.0f kN | 车辆 %d" %[
			route.total / 1000.0, min_radius, tan(max_grade) * 100.0, train.max_tractive_force / 1000.0,
			train.vehicles.size()])
	train.lead_cab_only = start_kind == "custom" or mode == "test"
	train.service_name = _service_name_for(start_kind)
	train.siding = siding
	var start := route.wrap_dist(Config.station_dist(route, 0) + 55.0)
	if not station_data.is_empty():
		start = float(station_data [0] ["stop"])
	if start_distance >= 0.0:
		start = start_distance
	train.distance = start
	train.set_light_state(true)
	train.place()
	train_def = _train_def_for(start_kind)
	startup = TrainStartup.new(train, train_def)
	if mode == "test":
		startup.prepare_for_service()
	print("[startup] %s：冷车状态 → %s" %[train_def.name_cn, startup.hint()])


func _custom_category() -> String:
	return String(ConsistCatalog.compute(custom_cars, custom_loco_count, custom_loaded, engine_id, transmission_id)["category"])


func _train_def_for(kind: String) -> TrainDef:
	if kind == "test":
		return TrainDef.for_kind("electric")
	if kind == "custom":
		var category := _custom_category()
		var summary := ConsistCatalog.compute(custom_cars, custom_loco_count, custom_loaded,
				engine_id, transmission_id)
		var d := TrainDef.custom(category)
		d.pub_cars = int(summary ["car_count"]) + int(summary ["loco_count"])
		d.pub_vmax_kmh = float(summary ["max_speed"])
		d.pub_mass_empty_t = float(summary ["mass_empty"])
		d.pub_mass_loaded_t = float(summary ["mass_now"])
		d.pub_pantograph_cars = int(summary ["loco_count"])
		d.sim_traction_kn_per_motor_car = float(summary ["traction_kn"])
		return d
	return TrainDef.for_kind(kind)


func consist_snapshot() -> Dictionary:
	if start_kind == "test":
		return {
			"cars": ["passenger", "passenger", "container", "container", "hopper"],
			"locos": 1,
			"loaded": true,
		}
	if start_kind == "custom":
		return {
			"cars": custom_cars.duplicate(),
			"locos": custom_loco_count,
			"loaded": custom_loaded,
		}
	var preset_cars: Array[String] = []
	var preset_loaded := true
	if start_kind == "hopper":
		preset_loaded = false
	for i in range(8):
		preset_cars.append("hopper" if start_kind == "hopper" else "container")
	return {
		"cars": preset_cars,
		"locos": 1,
		"loaded": preset_loaded,
	}


func _service_name_for(kind: String) -> String:
	if kind == "test":
		return "TEST 物理测试列车"
	if kind == "custom":
		var cat := _custom_category()
		if cat == "passenger":
			return "K9001 自定义旅客列车"
		if cat == "none":
			return "X9001 自定义单机"
		return "X9001 自定义货物列车"
	match kind:
		"hopper":
			return "X8014 电力空车货列"
		"passenger":
			return "K8012 电力旅客列车"
		_:
			return "X8012 电力集装箱货列"


func _setup_siding() -> void:
	if mode == "test" or _wants_test_mode():
		return
	if station_data.size() < 2 or railway == null:
		return
	sidings.clear()
	selected_siding = -1
	active_siding = -1
	mission_siding = {}
	for def: Dictionary in Config.SIDINGS:
		var idx := int(def["station"])
		if idx < 0 or idx >= station_data.size():
			continue
		var stop := route.wrap_dist(float(station_data[idx]["stop"]))
		var sid := {
			"id": String(def.get("id", "")),
			"name": String(def.get("name", "侧线")),
			"station": idx,
			"stop": stop,
			"in": route.wrap_dist(stop + float(def["begin"])),
			"out": route.wrap_dist(stop + float(def["end"])),
			"blend": float(def["blend"]),
			"offset": float(def["offset"]),
			"sign": String(def.get("sign", "3")),
		}
		sidings.append(sid)
		railway.build_siding(sid)
		_build_siding_mark(sid)
	if not sidings.is_empty():
		mission_siding = sidings[0]
		siding = mission_siding
		stats ["siding_span"] = float(Config.SIDINGS[0]["end"]) - float(Config.SIDINGS[0]["begin"])
	_build_yard_office(2)


func _build_siding_mark(sid: Dictionary) -> void:
	var group := Node3D.new()
	group.name = "SidingStopMark_" + String(sid.get("id", ""))
	railway.add_child(group)
	var d := float(sid ["stop"])
	var xf := route.frame_at(d)
	var off := float(sid ["offset"])
	var pos := xf.origin + xf.basis.x *(off - signf(off) * 3.35)
	var post := MeshInstance3D.new()
	post.mesh = Forge.cylinder(0.07, 2.6, 8, 0.0, true, true)
	post.material_override = Gfx.metal(Color(0.42, 0.44, 0.46), 0.5, 0.6)
	post.transform = Transform3D(Basis(), pos + Vector3.UP * 1.3)
	group.add_child(post)
	var board := MeshInstance3D.new()
	board.mesh = Forge.box(Vector3(1.7, 0.56, 0.07))
	board.material_override = Gfx.paint(Color(0.62, 0.14, 0.1), 0.5, 0.3, 0.4)
	board.transform = Transform3D(xf.basis.orthonormalized(), pos + Vector3.UP * 2.74)
	group.add_child(board)
	var label := Label3D.new()
	label.text = "待避停车"
	label.font_size = 110
	label.pixel_size = 0.004
	label.modulate = Color(1.0, 0.96, 0.88)
	label.outline_size = 14
	label.outline_modulate = Color(0.24, 0.05, 0.04)
	label.transform = Transform3D(xf.basis.orthonormalized(), pos + Vector3.UP * 2.74 + xf.basis.z * 0.06)
	group.add_child(label)

	var mark := MeshInstance3D.new()
	mark.mesh = Forge.box(Vector3(3.2, 0.03, 0.3))
	mark.material_override = Gfx.paint(Color(0.95, 0.9, 0.32), 0.5, 0.05, 0.3)
	mark.transform = Transform3D(xf.basis.orthonormalized(),
			xf.origin + xf.basis.x *(off + 0.4) + Vector3.UP * 1.04)
	group.add_child(mark)


func _build_yard_office(station_index: int) -> void:
	if station_index < 0 or station_index >= station_data.size():
		return
	var station: Dictionary = station_data[station_index]
	var d := float(station["stop"]) - 90.0
	var xf := route.frame_at(d)
	var side := signf(float(Config.SIDINGS[1].get("offset", 4.8)))
	var root := Node3D.new()
	root.name = "YardOffice"
	root.transform = Transform3D(Basis(Vector3.UP, xf.basis.get_euler().y),
			xf.origin + xf.basis.x * (side * 24.0))
	add_child(root)

	var concrete := Gfx.noise_surface(Color(0.32, 0.33, 0.32), 0.94, 0.12, 0.32)
	var wall := Gfx.paint(Color(0.62, 0.64, 0.62), 0.6, 0.08, 0.25)
	var roof_mat := Gfx.metal(Color(0.28, 0.31, 0.34), 0.55, 0.55)
	var glass := Gfx.glass(Color(0.08, 0.12, 0.16), 0.06, 0.38)
	var dark := Gfx.metal(Color(0.12, 0.13, 0.14), 0.55, 0.5)

	var apron := MeshInstance3D.new()
	apron.name = "YardApron"
	apron.mesh = Forge.box(Vector3(18.0, 0.16, 62.0))
	apron.position = Vector3(0, 0.18, 0)
	apron.material_override = concrete
	root.add_child(apron)

	var office := MeshInstance3D.new()
	office.name = "YardOfficeBuilding"
	office.mesh = Forge.box(Vector3(10.0, 4.6, 18.0))
	office.position = Vector3(5.0, 2.3, 0)
	office.material_override = wall
	root.add_child(office)
	var roof := MeshInstance3D.new()
	roof.name = "YardOfficeRoof"
	roof.mesh = Forge.box(Vector3(11.0, 0.55, 19.0))
	roof.position = Vector3(5.0, 4.85, 0)
	roof.material_override = roof_mat
	root.add_child(roof)
	var door := MeshInstance3D.new()
	door.name = "YardOfficeDoor"
	door.mesh = Forge.box(Vector3(0.18, 2.5, 2.0))
	door.position = Vector3(-0.06, 1.25, 0)
	door.material_override = dark
	root.add_child(door)
	var windows := []
	for wz: float in [-6.0, -2.0, 2.0, 6.0]:
		windows.append([Forge.box(Vector3(0.16, 1.35, 2.1)), Transform3D(Basis(), Vector3(-0.07, 3.0, wz))])
	var win_mesh := MeshInstance3D.new()
	win_mesh.name = "YardOfficeWindows"
	win_mesh.mesh = Forge.merge_all(windows)
	win_mesh.material_override = glass
	root.add_child(win_mesh)

	var sign := _station_sign("青川车场")
	sign.scale = Vector3(0.85, 0.85, 0.85)
	sign.transform = Transform3D(Basis(Vector3.UP, -side * PI * 0.5),
			Vector3(-0.12, 5.8, 0.0))
	root.add_child(sign)

	for cz: float in [-20.0, -8.0, 4.0, 16.0]:
		var box := MeshInstance3D.new()
		box.name = "YardContainer"
		box.mesh = Forge.box(Vector3(6.0, 2.6, 2.4))
		box.position = Vector3(-2.0, 1.3, cz)
		var colors := [Color(0.16, 0.30, 0.48), Color(0.55, 0.18, 0.12), Color(0.18, 0.38, 0.22)]
		box.material_override = Gfx.paint(colors[abs(int(cz)) % colors.size()], 0.55, 0.25, 0.2)
		root.add_child(box)

	for lz: float in [-24.0, 24.0]:
		var pole := MeshInstance3D.new()
		pole.name = "YardFloodPole"
		pole.mesh = Forge.cylinder(0.09, 8.0, 8, 0.0, true, true)
		pole.position = Vector3(-4.0, 4.0, lz)
		pole.material_override = Gfx.metal(Color(0.35, 0.37, 0.39), 0.45, 0.65)
		root.add_child(pole)
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(-4.0, 8.2, lz)
		lamp.omni_range = 26.0
		lamp.light_energy = 1.2
		lamp.light_color = Color(1.0, 0.92, 0.78)
		lamp.shadow_enabled = false
		root.add_child(lamp)


func _build_ai_train() -> void:
	if ai_train != null or train == null:
		return
	ai_train = Train.new()
	ai_train.name = "AITrain"
	add_child(ai_train)
	ai_train.layout_reversed = true
	ai_train.ai = true
	ai_train.ai_speed = 30.0
	ai_train.setup(route, _make_consist("container", true))
	ai_train.service_name = "X8250 电力货列"
	ai_train.distance = route.wrap_dist(train.distance + 1500.0)
	ai_train.place()
	ai_train.visible = false
	ai_train.set_light_state(true)


func _make_consist(kind: String, loaded: bool) -> Array:
	if kind == "test":
		# One fixed train exercises all three bogie families: the HXD1 Bo-Bo,
		# 209P passenger bogies, K6 container flat bogies and a K7 hopper bogie.
		var test_consist: Array = []
		test_consist.append(Vehicles.freight_loco("standard", "classic", "balanced", []))
		test_consist.append(Vehicles.passenger_coach())
		test_consist.append(Vehicles.passenger_coach())
		test_consist.append(Vehicles.container_wagon(true))
		test_consist.append(Vehicles.container_wagon(false))
		test_consist.append(Vehicles.hopper_wagon(false))
		return test_consist
	if kind == "custom":
		return ConsistCatalog.build_consist(custom_cars, custom_loco_count, custom_loaded,
				engine_id, skin_id, transmission_id, part_ids)
	var consist: Array = []
	consist.append(Vehicles.freight_loco(engine_id, skin_id, transmission_id, part_ids))
	if kind == "passenger":
		for i in range(6):
			consist.append(Vehicles.passenger_coach())
		return consist
	if kind == "hopper":
		for i in range(8):
			consist.append(Vehicles.hopper_wagon(false))
	else:
		for i in range(8):
			consist.append(Vehicles.container_wagon(true))
	return consist


func _rebuild_consist(kind: String, loaded: bool) -> void:
	if train == null or route == null:
		return
	start_kind = kind
	train.service_name = _service_name_for(kind)
	for v in train.vehicles:
		train.remove_child(v)
		v.queue_free()
	train.setup(route, _make_consist(kind, loaded))
	train.lead_cab_only = kind == "custom"
	train.place()
	train_def = _train_def_for(kind)
	if startup != null:
		startup.def = train_def
		startup.recapture_base()
	if interaction != null:
		interaction.rebuild()
	train.set_light_state(train.head_lights_on)



func _setup_mission() -> void:
	if mode == "test" or _wants_test_mode():
		return
	if train == null or station_data.size() < 2:
		return
	mission = MissionSystem.new()
	mission.name = "Mission"
	add_child(mission)
	mission.message.connect(_on_mission_message)
	mission.task_started.connect(_on_task_started)
	if mode == "career" and not current_job.is_empty() and not free_drive:
		tasks_cache = [current_job]
		mission.single_job = true
	elif mode == "open":
		tasks_cache = []
	else:
		tasks_cache = _default_tasks()
	mission.setup(route, train, station_data, tasks_cache)
	if free_drive:
		mission.tasks = []
		mission.task = {}
		mission.index = -1
		mission.phase = MissionSystem.Phase.DONE
		if hud != null:
			hud.task_panel.visible = false
	if mode == "open":
		mission.money = int(career.get("money", 0))
		mission.completed = int(career.get("completed", 0))
		if hud != null:
			hud.task_panel.visible = false
			hud.set_progress(0.0, false)
		return
	if mode == "career":
		mission.money = int(career.get("money", 0))
		mission.completed = int(career.get("completed", 0))
		mission.task_finished.connect(_on_career_task_finished)
		mission.all_done.connect(_on_career_all_done)
	else:
		mission.money = int(career.get("money", 0))
		mission.completed = int(career.get("completed", 0))
		mission.task_finished.connect(func(_i: int, _r: Dictionary) -> void:
			if slot_id != "":
				save_now(true)
		)


func _default_tasks() -> Array:
	return []


func _train_number(index: int) -> String:
	if index >= 0 and index < tasks_cache.size():
		return String(tasks_cache [index].get("number", "X8012"))
	return "X8012"

func _on_mission_message(text: String) -> void:
	if hud != null:
		hud.toast(text, 3.6)

func _on_task_started(index: int, task: Dictionary) -> void:
	_rebuild_consist(String(task ["kind"]), bool(task ["loaded"]))
	var cargo := String(task ["cargo"])
	var kind := String(task ["kind"])
	var suffix := "动车组" if kind == "emu" else ("旅客列车" if kind == "passenger" else "%s货物列车" %cargo)
	train.service_name = "%s 次 %s" %[String(task ["number"]), suffix]
	if hud != null:
		hud.toast("本务：%s" %train.service_name, 3.2)



func _setup_audio() -> void:
	if train == null:
		return
	audio = TrainAudio.new()
	audio.name = "Audio"
	add_child(audio)
	audio.setup(train)

func _setup_weather() -> void:
	if world_env == null or sun == null or train == null:
		return
	weather = WeatherSystem.new()
	weather.name = "Weather"
	add_child(weather)
	weather.setup(world_env.environment, sun, train)
	if forced_weather != "":
		weather.set_weather(forced_weather, true)


func _update_weather(delta: float) -> void:
	if weather == null or train == null:
		return
	weather.tunnel = _train_in_tunnel()
	weather.update(delta)
	if railway != null:
		railway.set_wetness(weather.wetness)
	if audio != null:
		audio.set_weather(weather.rain_amount, weather.wetness)
		audio.set_environment(weather.tunnel, weather.intensity)
	_overspeed_toast -= delta
	var limit := _line_limit()
	if absf(train.speed_kmh()) > limit + 2.0 and _overspeed_toast <= 0.0:
		_overspeed_toast = 5.0
		if hud != null:
			hud.toast("超速：限速 %d km/h" %int(round(limit)), 2.4)


func _train_in_tunnel() -> bool:
	if route == null or train == null:
		return false
	for t: Dictionary in Config.TUNNELS:
		var span := Config.tunnel_span(route, t)
		var rel := route.wrap_dist(train.distance - span.x)
		if rel <= route.wrap_dist(span.y - span.x):
			return true
	return false


func _line_limit() -> float:
	var limit := 200.0
	if train == null or route == null:
		return limit
	for t: Dictionary in Config.TUNNELS:
		var ts := Config.tunnel_span(route, t)
		var tr := route.wrap_dist(train.distance - ts.x)
		if tr <= route.wrap_dist(ts.y - ts.x):
			limit = 120.0
	for b: Dictionary in Config.BRIDGES:
		var bs := Config.bridge_span(route, b)
		var br := route.wrap_dist(train.distance - bs.x)
		if br <= route.wrap_dist(bs.y - bs.x):
			limit = 200.0
	for st: Dictionary in station_data:
		var to_stop := route.wrap_dist(float(st.get("stop", 0.0)) - train.distance)
		if to_stop > -80.0 and to_stop < 460.0:
			limit = minf(limit, 80.0)
	if mission != null and not mission.task.is_empty():
		limit = minf(limit, float(mission.task.get("limit", 140.0)))
	if autopilot and autopilot_target >= 0:
		var signed := _signed_delta(autopilot_stop, train.distance)
		if signed > -5.0 and signed < 500.0:
			limit = minf(limit, 30.0)
	return limit

func _setup_camera() -> void:
	if train == null:
		return
	rig = CameraRig.new()
	rig.name = "CameraRig"
	add_child(rig)
	rig.setup(train, route)
	rig.set_terrain(terrain)
	rig.stations = station_data
	rig.hall_gates = hall_gates
	rig.set_mode(CameraRig.Mode.CHASE)

func _setup_hud() -> void:
	hud = HUD.new()
	hud.name = "HUD"
	add_child(hud)
	if train != null:
		hud.toast("欢迎驾驶 %s" %train.service_name, 4.0)

func _setup_map() -> void:
	if route == null or train == null:
		return
	map_view = MapView.new()
	map_view.name = "MapView"
	hud.add_child(map_view)
	var sig: Array = []
	if railway != null:
		for s in railway.signals:
			sig.append(float(s ["dist"]))
	map_view.setup(route, station_data, train, ai_train, siding, sig, mission, lakes)
	map_view.mode = MapView.Mode.MINI
	map_view.visible = true
	map_view.full_closed.connect(_on_map_closed)


func _setup_pause() -> void:
	pause_menu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)
	pause_menu.resume.connect(_resume_game)
	pause_menu.career_requested.connect(open_career_panel)
	pause_menu.consist_requested.connect(func() -> void: open_consist_panel("pause"))
	pause_menu.tuning_requested.connect(open_tuning_panel)
	pause_menu.set_consist_available(mode == "open")
	pause_menu.restart.connect(func() -> void: request_restart.emit())
	pause_menu.to_menu.connect(func() -> void: request_menu.emit())
	pause_menu.quit.connect(func() -> void: get_tree().quit())
	pause_menu.save_requested.connect(func() -> void: save_now(false))
	pause_menu.settings_changed.connect(apply_quality)
	pause_menu.settings_changed.connect(func() -> void:
		if rig != null:
			rig.apply_user_settings()
	)


func _setup_postfx() -> void:
	var cl := CanvasLayer.new()
	cl.name = "PostFX"
	cl.layer = 0
	add_child(cl)
	var cr := ColorRect.new()
	cr.name = "Vignette"
	cr.set_anchors_preset(Control.PRESET_FULL_RECT)
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = "\nshader_type canvas_item;\n\nuniform float vignette_strength : hint_range(0.0, 1.0) = 0.38;\nuniform float vignette_power : hint_range(0.5, 4.0) = 2.2;\nuniform float grain_amount : hint_range(0.0, 0.1) = 0.02;\n\nfloat shash(vec2 p) {\n\treturn fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);\n}\n\nvoid fragment() {\n\tvec2 c = SCREEN_UV - vec2(0.5);\n\tfloat d = clamp(dot(c, c) * 2.3, 0.0, 1.0);\n\tfloat dark = vignette_strength * pow(d, vignette_power);\n\tfloat g = (shash(SCREEN_UV * vec2(1920.0, 1080.0) + fract(TIME) * 128.0) - 0.5) * grain_amount;\n\tCOLOR = vec4(vec3(0.0), clamp(dark + g, 0.0, 1.0));\n}\n"
	postfx_mat = ShaderMaterial.new()
	postfx_mat.shader = sh
	cr.material = postfx_mat
	cl.add_child(cr)


func _update_reflection_probe(delta: float) -> void:
	if reflection_probe == null or train == null or paused:
		return
	if Config.quality < Config.Quality.HIGH:
		reflection_probe.visible = false
		return
	reflection_probe.visible = true
	_probe_accum += delta
	if _probe_accum < (1.2 if Config.quality >= Config.Quality.ULTRA else 3.4):
		return
	_probe_accum = 0.0
	reflection_probe.global_position = train.head_position() + Vector3.UP * 7.0
	reflection_probe.update_mode = ReflectionProbe.UPDATE_ONCE


func _update_time_flow(delta: float) -> void:
	if paused or UserSettings.time_flow <= 0:
		return
	var idx := clampi(UserSettings.time_flow, 0, UserSettings.TIME_FLOW_MINUTES.size() - 1)
	var mins := float(UserSettings.TIME_FLOW_MINUTES [idx])
	if mins <= 0.0:
		return
	time_of_day = fposmod(time_of_day + delta * 24.0 / (mins * 60.0), 24.0)
	_time_accum += delta
	if _time_accum >= 0.2:
		_time_accum = 0.0
		_apply_time()


func _toggle_pause() -> void:
	if pause_menu == null:
		return
	if pause_menu.visible:
		_resume_game()
	else:
		paused = true
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_sync_walk_crosshair()
		pause_menu.open()


func _walking_active() -> bool:
	return rig != null and (rig.mode == CameraRig.Mode.WALK
			or rig.mode == CameraRig.Mode.FREE or rig._on_foot or rig._cab_walk)


func _restore_mouse_mode() -> void:
	if get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _walking_active() else Input.MOUSE_MODE_VISIBLE


func _sync_walk_crosshair() -> void:
	if hud != null:
		hud.set_walk_crosshair(_walking_active() and not get_tree().paused)


func _resume_game() -> void:
	get_tree().paused = false
	paused = false
	if pause_menu != null:
		pause_menu.close()
	_restore_mouse_mode()
	_sync_walk_crosshair()


func _update_lane() -> void:
	if train == null:
		return
	var need := mission != null and not mission.task.is_empty() \
			and bool(mission.task.get("siding", false)) \
			and mission.phase != MissionSystem.Phase.DONE
	# A mission that requires the passing loop claims the next entry.
	if need and not mission_siding.is_empty():
		var to_mission := _signed_delta(float(mission_siding["in"]), train.distance)
		if to_mission < 1800.0 and to_mission > -200.0:
			selected_siding = sidings.find(mission_siding)
	# Leave the active siding once its far end is behind us.
	if active_siding >= 0 and active_siding < sidings.size():
		var act: Dictionary = sidings[active_siding]
		if _signed_delta(float(act["out"]), train.distance) < -25.0:
			active_siding = -1
	# Enter the selected siding when its entry switch is close.
	if active_siding < 0 and selected_siding >= 0 and selected_siding < sidings.size():
		var target: Dictionary = sidings[selected_siding]
		var to_in := _signed_delta(float(target["in"]), train.distance)
		if to_in < 1100.0 and to_in > -120.0:
			active_siding = selected_siding
	if active_siding >= 0 and active_siding < sidings.size():
		train.siding = sidings[active_siding]
		train.lane = 1
		siding_latched = true
		if mission_siding.is_empty():
			siding = sidings[active_siding]
	else:
		train.siding = {}
		train.lane = 0
		siding_latched = false
		if not mission_siding.is_empty():
			siding = mission_siding
		elif selected_siding >= 0 and selected_siding < sidings.size():
			siding = sidings[selected_siding]


func _switch_route() -> void:
	if sidings.is_empty():
		return
	if active_siding >= 0:
		if hud != null:
			hud.toast("已在线路上，驶出后再切换进路", 2.0)
		return
	selected_siding += 1
	if selected_siding >= sidings.size():
		selected_siding = -1
	var label := "主线"
	if selected_siding >= 0:
		label = String(sidings[selected_siding]["name"])
	if hud != null:
		hud.toast("进路：%s" % label, 2.2)


func _route_label() -> String:
	if active_siding >= 0 and active_siding < sidings.size():
		return String(sidings[active_siding]["name"])
	if selected_siding >= 0 and selected_siding < sidings.size():
		return String(sidings[selected_siding]["name"]) + "（待进）"
	return "主线"


func start_autopilot(index: int) -> String:
	if train == null or station_data.is_empty():
		return "列车或站点尚未就绪"
	if index < 0 or index >= station_data.size():
		return "无效站点"
	var st: Dictionary = station_data[index]
	autopilot_target = index
	autopilot_stop = float(st["stop"])
	autopilot = true
	_autopilot_accum = 0.0
	if train.reverser == 0:
		train.reverser = 1
	train.doors_open = false
	train.door_open_side = 0
	train.cab_door_only = false
	train.handbrake = false
	train.brake_notch = 0
	train.notch = 0
	if startup != null:
		if startup.park_brake:
			startup.press("park_brake")
		if not startup.panto_up:
			startup.press("panto")
		if not startup.vcb_on:
			startup.press("vcb")
	if autopilot_verbose:
		print("[autopilot] target=%d name=%s stop=%.1f distance=%.1f speed=%.2f" % [
				index, String(st["name"]), autopilot_stop, train.distance, train.speed])
	if hud != null:
		hud.toast("自动驾驶：%s" % String(st["name"]), 2.6)
	return "自动驾驶已设定：%s" % String(st["name"])


func stop_autopilot() -> void:
	autopilot = false
	autopilot_target = -1
	if train != null:
		train.notch = 0
	if hud != null:
		hud.toast("自动驾驶已取消", 1.8)


func _update_autopilot(delta: float) -> void:
	if not autopilot or train == null or autopilot_target < 0:
		return
	if autopilot_target >= station_data.size():
		autopilot = false
		return
	var st: Dictionary = station_data[autopilot_target]
	var stop_d := float(st["stop"])
	var to_stop := route.wrap_dist(stop_d - train.distance)
	var signed := _signed_delta(stop_d, train.distance)
	if absf(signed) < 3.5 and absf(train.speed) < 0.35:
		autopilot = false
		train.notch = 0
		train.brake_notch = 7
		train.handbrake = true
		if startup != null and not startup.park_brake:
			startup.press("park_brake")
		if autopilot_verbose:
			print("[autopilot] ARRIVED name=%s distance=%.1f stop=%.1f signed=%.2f speed=%.2f" % [
					String(st["name"]), train.distance, stop_d, signed, train.speed])
		if hud != null:
			hud.toast("自动驾驶已到达 %s，已施加停放制动" % String(st["name"]), 3.0)
		return
	if signed < 0.0 and signed > -60.0 and absf(train.speed) < 0.35:
		autopilot = false
		train.notch = 0
		train.brake_notch = 7
		train.handbrake = true
		if startup != null and not startup.park_brake:
			startup.press("park_brake")
		if hud != null:
			hud.toast("自动驾驶已停车（略过停车点），已施加停放制动", 3.0)
		return
	if signed < -25.0 and signed > -400.0:
		autopilot = false
		train.notch = 0
		train.brake_notch = 7
		if hud != null:
			hud.toast("已越过停车点，自动驾驶退出", 2.8)
		return
	var line_kmh := _line_limit()
	var stop_kmh := sqrt(maxf(0.0, 2.0 * 0.55 * maxf(0.0, to_stop - 1.0))) * 3.6
	var target_kmh := minf(line_kmh, stop_kmh)
	if signed > -5.0 and signed < 500.0:
		target_kmh = minf(target_kmh, 30.0)
	if signed < 0.0 and signed > -60.0:
		target_kmh = 0.0
	if to_stop < 12.0 and absf(train.speed) < 1.2:
		target_kmh = 0.0
	target_kmh = minf(target_kmh, train.max_speed * 3.6)
	var target_ms := target_kmh / 3.6
	_autopilot_accum += delta
	if _autopilot_accum < 0.2:
		return
	_autopilot_accum = 0.0
	if autopilot_verbose:
		print("[autopilot] speed=%.2f target=%.2f to_stop=%.1f signed=%.1f limit=%.0f notch=%d brake=%d" % [
				train.speed, target_ms, to_stop, signed, line_kmh, train.notch, train.brake_notch])
	var err := target_ms - train.speed
	if err > 0.5:
		train.brake_notch = 0
		train.notch = mini(8, train.notch + 1)
	elif err < -0.25:
		train.notch = maxi(0, train.notch - 2)
		var need := int(ceil(-err / 0.45))
		train.brake_notch = clampi(maxi(need, train.brake_notch + 1), 1, 7)
	else:
		train.brake_notch = maxi(0, train.brake_notch - 1)


func _autopilot_label() -> String:
	if not autopilot or autopilot_target < 0 or autopilot_target >= station_data.size():
		return ""
	return String(station_data[autopilot_target]["name"])


func _ensure_autopilot_panel() -> void:
	if autopilot_panel != null:
		return
	autopilot_panel = AutopilotPanelScript.new()
	autopilot_panel.name = "AutopilotPanel"
	autopilot_panel.layer = 35
	add_child(autopilot_panel)
	autopilot_panel.closed.connect(_on_autopilot_closed)


func open_autopilot() -> void:
	_ensure_autopilot_panel()
	if autopilot_panel == null:
		return
	autopilot_panel.open(self)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_sync_walk_crosshair()


func _on_autopilot_closed() -> void:
	get_tree().paused = false
	if autopilot_panel != null:
		autopilot_panel.visible = false
	_restore_mouse_mode()
	_sync_walk_crosshair()


func _update_ai(delta: float) -> void:
	if train == null or mission == null or siding.is_empty():
		return
	var need :=(not mission.task.is_empty()) and bool(mission.task.get("siding", false)) and mission.phase != MissionSystem.Phase.DONE and not mission.pass_done

	var want := false
	if need:
		var to_stop := _signed_delta(float(siding ["stop"]), train.distance)
		want = to_stop < 1600.0 and to_stop > -600.0
	if want:
		if ai_train == null:
			_build_ai_train()
		if ai_train == null:
			return
		if not ai_train.visible:
			ai_train.distance = route.wrap_dist(train.distance + 1350.0)
			ai_train.place()
			ai_train.visible = true
			if hud != null:
				hud.toast("对向列车接近：%s" %ai_train.service_name, 3.4)
		ai_train.step_ai(delta)
		var rel := _signed_delta(ai_train.distance, train.distance)
		if rel < 220.0 and rel > 0.0 and audio != null and _ai_horn_cooldown <= 0.0:
			audio.blast()
			_ai_horn_cooldown = 6.0
		if rel < -320.0:
			mission.notify_pass_done()
			ai_train.visible = false
	elif ai_train != null and ai_train.visible:
		ai_train.visible = false
	if _ai_horn_cooldown > 0.0:
		_ai_horn_cooldown -= delta


func _signed_delta(a: float, b: float) -> float:
	var d := route.wrap_dist(a - b)
	if d > route.total * 0.5:
		d -= route.total
	return d

func _physics_process(delta: float) -> void:
	if train == null:
		return
	if paused:
		return
	_handle_input(delta)
	_update_lane()
	_update_autopilot(delta)
	_update_ai(delta)
	train.step(delta)

func _handle_input(_delta: float) -> void:
	if map_view != null:
		if map_view.just_closed:
			map_view.just_closed = false
			return
		if Input.is_action_just_pressed("map_toggle"):
			_toggle_map()
			return
		if map_view.is_full():
			return
	var walking := rig != null and (rig.mode == CameraRig.Mode.WALK or rig.mode == CameraRig.Mode.FREE
			or rig._on_foot or rig._cab_walk)
	if not walking:
		if Input.is_action_just_pressed("gear_up"):
			_shift_gear(1)
		if Input.is_action_just_pressed("gear_down"):
			_shift_gear(-1)
		if Input.is_action_just_pressed("doors_toggle"):
			var door_msg := _toggle_doors()
			if door_msg != "" and hud != null:
				hud.toast(door_msg, 2.0)
		if Input.is_action_just_pressed("lights_toggle"):
			_toggle_lights()
		if Input.is_action_just_pressed("switch_route"):
			_switch_route()
	if Input.is_action_just_pressed("sit"):
		_try_sit()
	if Input.is_action_just_pressed("autopilot"):
		open_autopilot()
	if Input.is_action_just_pressed("reverser_cycle") and startup != null:
		_try("方向", startup.press("reverser"))
	if Input.is_action_just_pressed("handbrake") and startup != null:
		_try("停放制动", startup.press("park_brake"))
	if Input.is_action_just_pressed("headlights"):
		_toggle_lights()
	if Input.is_action_just_pressed("high_beam"):
		_toggle_high_beam()
	if Input.is_action_just_pressed("wiper") and startup != null:
		_try("雨刷", startup.press("wiper"))
	if Input.is_action_just_pressed("horn"):
		if startup != null:
			startup.press("horn")
		if audio != null:
			audio.blast()
		hud.toast("呜——", 1.2)
	if Input.is_action_just_pressed("emergency_brake") and not walking:
		_space_action()
	if Input.is_action_just_pressed("camera_next") and rig != null and not walking:
		rig.cycle_mode()
	if Input.is_action_just_pressed("camera_free") and rig != null and not walking:
		rig.set_tower_index(randi() %3)
	if Input.is_action_pressed("sand"):
		train.sanding = true
	else:
		train.sanding = false
	if Input.is_action_just_pressed("weather_cycle") and weather != null:
		weather.cycle_weather()
		if hud != null:
			hud.toast("天气切换：%s" %weather.label, 1.8)
	if Input.is_action_just_pressed("time_scale"):
		time_of_day = fmod(time_of_day + 2.0, 24.0)
		_apply_time()
		hud.toast("时间 %.1f 时" %time_of_day, 1.5)
	if Input.is_action_just_pressed("hud_toggle"):
		hud.visible = not hud.visible
	if Input.is_action_just_pressed("dev_panel") and dev_panel != null:
		dev_panel.toggle()
	if Input.is_action_just_pressed("doors"):
		var door_msg := _toggle_doors()
		if door_msg != "" and hud != null:
			hud.toast(door_msg, 2.0)
	if Input.is_action_just_pressed("map_mode") and map_view != null:
		var map_msg := map_view.cycle_mini_mode()
		if map_msg != "" and hud != null:
			hud.toast(map_msg, 1.2)
	if Input.is_action_just_pressed("screenshot"):
		_save_screenshot()
	if Input.is_action_just_pressed("interact"):
		_handle_interact()
	if Input.is_action_just_pressed("pause"):
		_toggle_pause()


func _space_action() -> void:
	if train == null:
		return
	if train.gear == Train.GEAR_D5:
		train.set_gear(Train.GEAR_N)
		if startup != null:
			startup.on_drive_gear(false)
		hud.toast("档位 N（空挡）", 2.0)
	else:
		train.emergency_brake()
		if startup != null:
			startup.on_drive_gear(false)
		hud.toast("紧急制动 · 档位 P3", 2.4)


func _shift_gear(dir: int) -> void:
	if train == null:
		return
	var next := clampi(train.gear + dir, 0, Train.GEAR_NAMES.size() - 1)
	if next == train.gear:
		hud.toast("已到%s档" %("最高" if dir > 0 else "最低"), 1.2)
		return
	if dir > 0 and next >= Train.GEAR_D1 and startup != null and not startup.can_traction():
		hud.toast("无法挂入动力档：%s" %startup.readiness_text(), 3.2)
		return
	train.set_gear(next)
	if startup != null:
		startup.on_drive_gear(train.gear_is_drive())
	hud.toast("档位 %s  ·  %s" %[train.gear_name(), _gear_desc()], 1.8)


func _gear_desc() -> String:
	match train.gear:
		Train.GEAR_P3:
			return "停车制动 · 最大"
		Train.GEAR_P2:
			return "停车制动 · 中等"
		Train.GEAR_P1:
			return "停车制动 · 轻"
		Train.GEAR_N:
			return "空挡 · 可按地形溜车"
		_:
			return "前进动力 %d 级" %(train.gear - Train.GEAR_D1 + 1)


func _platform_context() -> Dictionary:
	if train == null or route == null or station_data.is_empty():
		return {}
	if absf(train.speed) > 0.5:
		return {}
	# The platform is built along the running line. If the train has been
	# switched into a siding/yard track, its doors do not open onto it.
	if train.lane != 0:
		return {}
	var best := {}
	var best_d := INF
	for st: Dictionary in station_data:
		var half := float(st.get("platform_len", 220.0)) * 0.5
		var d := absf(_signed_delta(train.distance, float(st.get("dist", 0.0))))
		if d <= half + 12.0 and d < best_d:
			best_d = d
			best = st
	return best


func _local_platform_side(st: Dictionary) -> int:
	var side := int(signf(float(st.get("side", 1.0))))
	var cv := train._cab_vehicle() if train != null else null
	if cv == null or route == null:
		return side
	var rf := route.frame_at(train.distance)
	var align := cv.global_transform.basis.x.dot(rf.basis.x)
	return side if align >= 0.0 else -side


func _mark_platform_doors(platform: Dictionary) -> void:
	if train == null or route == null or platform.is_empty():
		return
	var pd := float(platform.get("dist", 0.0))
	var plen := float(platform.get("platform_len", 220.0))
	for v in train.vehicles:
		if v == null:
			continue
		var vd := route.nearest_dist(v.global_transform.origin)
		var delta := absf(_signed_delta(vd, pd))
		v.set_meta("door_platform_ok", delta - v.length * 0.5 <= plen * 0.5 + 12.0)


func _toggle_doors() -> String:
	if train == null:
		return ""
	if autopilot:
		return "✗ 自动驾驶运行中，车门锁定"
	if train.doors_open:
		train.doors_open = false
		train.door_open_side = 0
		train.cab_door_only = false
		return "全列车门关闭"
	var platform := _platform_context()
	if platform.is_empty():
		return "✗ 只有停靠站台时才能开门"
	if not train.handbrake:
		return "✗ 请先施加停放制动"
	train.cab_door_only = false
	train.door_open_side = _local_platform_side(platform)
	_mark_platform_doors(platform)
	train.doors_open = true
	return "站台侧全列车门打开"


func _toggle_cab_door(side: int) -> String:
	if train == null:
		return ""
	if autopilot:
		return "✗ 自动驾驶运行中，车门锁定"
	var platform := _platform_context()
	if platform.is_empty():
		return "✗ 只有停靠站台时才能开门"
	if not train.handbrake:
		return "✗ 请先施加停放制动"
	var local_side := _local_platform_side(platform)
	if side != local_side:
		return "✗ 非站台侧车门禁止打开"
	if train.doors_open and train.door_open_side == side:
		train.doors_open = false
		train.door_open_side = 0
		train.cab_door_only = false
		return "全列该侧车门关闭"
	train.cab_door_only = false
	train.door_open_side = side
	_mark_platform_doors(platform)
	train.doors_open = true
	return "全列该侧车门打开"


func _toggle_lights() -> void:
	if train == null:
		return
	if startup != null:
		var msg := startup.press("headlight")
		if msg != "":
			hud.toast(msg, 1.6)
		train.set_high_beam(false)
		return
	train.set_high_beam(false)
	train.set_light_state(not train.head_lights_on)
	hud.toast("车灯%s" %("开" if train.head_lights_on else "关"), 1.6)


func _toggle_high_beam() -> void:
	if train == null:
		return
	train.set_high_beam(not train.high_beam_on)
	if startup != null and train.high_beam_on:
		startup.headlight_on = true
	hud.toast("远光灯%s" %("开" if train.high_beam_on else "关"), 1.8)


func _toggle_map() -> void:
	if map_view == null:
		return
	if map_view.is_full():
		map_view.close_full()
	else:
		open_full_map()


func open_full_map() -> void:
	if map_view == null:
		return
	map_view.open_full()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if hud != null:
		hud.set_walk_crosshair(false)
	if UserSettings.map_pause:
		_map_paused = true
		paused = true
		get_tree().paused = true


func _on_map_closed() -> void:
	if _map_paused:
		_map_paused = false
		paused = false
		get_tree().paused = false
	_restore_mouse_mode()
	_sync_walk_crosshair()


func _vehicle_status() -> String:
	if train == null:
		return ""
	var parts: Array [String] = []
	if startup != null:
		var sn := startup.state_name()
		if startup.state == TrainStartup.State.DEPARTURE_READY:
			sn = "就绪"
		elif startup.state == TrainStartup.State.RUNNING:
			sn = "运行中"
		parts.append(sn)
	if train.emergency:
		parts.append("紧急制动")
	elif train.gear <= Train.GEAR_P1:
		parts.append("停车制动 %d 级" %train.brake_notch)
	elif train.gear == Train.GEAR_N:
		parts.append("空挡滑行")
	elif startup != null and not startup.can_traction():
		parts.append("动力未接通")
	else:
		parts.append("牵引 %d%%" %int(round(float(train.notch) / 8.0 * 100.0)))
	if train.doors_open:
		parts.append("车门开启")
	if train.handbrake:
		parts.append("停放制动")
	if train.sanding:
		parts.append("撒砂")
	parts.append("坡度 %+.1f%%" %(train.gradient * 100.0))
	return "  ·  ".join(parts)


func get_save_data() -> Dictionary:
	var d := {
		"version": SaveManager.VERSION,
		"mode": mode,
		"free_drive": free_drive,
		"career": career,
		"world": {"time_of_day": time_of_day, "route_length": route.total if route != null else 0.0},
		"train": {},
		"startup": startup.serialize() if startup != null else {},
	}
	if train != null:
		d ["train"] = {
			"distance": train.distance,
			"speed": train.speed,
			"reverser": train.reverser,
			"gear": train.gear,
			"gear_name": train.gear_name(),
			"doors_open": train.doors_open,
			"door_open_side": train.door_open_side,
			"cab_door_only": train.cab_door_only,
			"head_lights_on": train.head_lights_on,
			"high_beam_on": train.high_beam_on,
			"handbrake": train.handbrake,
			"brake_cylinder": train.brake_cylinder,
			"service_name": train.service_name,
			"kind": start_kind,
			"engine": engine_id,
			"transmission": transmission_id,
			"skin": skin_id,
			"parts": part_ids,
			"consist": {
				"locos": custom_loco_count,
				"cars": custom_cars,
				"loaded": custom_loaded,
			},
		}
	if mission != null:
		d ["mission"] = {
			"index": mission.index,
			"phase": int(mission.phase),
			"progress": mission.progress,
			"elapsed": mission.elapsed,
			"overspeed_time": mission.overspeed_time,
			"pass_done": mission.pass_done,
			"score": mission.score_total,
			"money": mission.money,
			"completed": mission.completed,
		}
	return d


func apply_save_data(d: Dictionary) -> void:
	if d.is_empty() or train == null:
		return
	var w: Dictionary = d.get("world", {})
	time_of_day = float(w.get("time_of_day", time_of_day))
	_apply_time()
	if startup != null:
		var s: Dictionary = d.get("startup", {})
		if not s.is_empty():
			startup.restore(s)
	if d.has("mode"):
		mode = String(d ["mode"])
	free_drive = bool(d.get("free_drive", free_drive))
	if d.has("career"):
		career = d ["career"].duplicate(true)
		current_job = career.get("current_job", current_job).duplicate(true)
	var m: Dictionary = d.get("mission", {})
	if mission != null and not m.is_empty() and not free_drive:
		mission.restore_state(m)
	if mission != null and mode == "career":
		mission.money = int(career.get("money", mission.money))
		mission.completed = int(career.get("completed", mission.completed))
	var t: Dictionary = d.get("train", {})
	if not t.is_empty():
		train.distance = route.wrap_dist(float(t.get("distance", train.distance)))
		# Preserve the relative position on the loop when loading a save made
		# on a different route length. Pre-expansion saves had no route_length,
		# so treat open/career saves as the old ~51.85 km map.
		var saved_total := float(w.get("route_length", 0.0))
		if saved_total <= 1.0 and mode != "test":
			saved_total = 51854.0
		if slot_id != "" and saved_total > 1.0 and absf(saved_total - route.total) > 1.0:
			train.distance = route.wrap_dist(train.distance * route.total / saved_total)
		train.speed = float(t.get("speed", 0.0))
		var rev := int(t.get("reverser", 1))
		train.reverser = rev if rev != 0 else 1
		train.set_gear(int(t.get("gear", Train.GEAR_P3)))
		train.doors_open = bool(t.get("doors_open", false))
		train.door_open_side = int(t.get("door_open_side", 0))
		train.cab_door_only = bool(t.get("cab_door_only", false))
		train.door_anim = 0.0
		train.set_light_state(bool(t.get("head_lights_on", true)))
		train.set_high_beam(bool(t.get("high_beam_on", false)))
		train.handbrake = bool(t.get("handbrake", false))
		train.brake_cylinder = float(t.get("brake_cylinder", 0.0))
		if String(t.get("service_name", "")) != "":
			train.service_name = String(t.get("service_name"))
	if startup != null:
		startup.apply_physics()
	train.place()
	_autosave_accum = 0.0
	if mission != null:
		_prev_mission_phase = int(mission.phase)
	if hud != null:
		hud.toast("存档已载入：%s" %slot_name, 2.8)


func save_now(auto := false) -> bool:
	if slot_id == "" or train == null:
		if not auto and hud != null:
			hud.toast("当前没有可用的存档位", 2.2)
		return false
	var ok := SaveManager.write_save(slot_id, slot_name, get_save_data())
	if hud != null:
		hud.toast(("已自动保存" if auto else "游戏已保存") +("" if ok else "失败"), 2.2)
	if ok:
		_autosave_accum = 0.0
		if pause_menu != null and pause_menu.visible:
			pause_menu.flash("已自动保存" if auto else "已保存")
	return ok


func _update_autosave(delta: float) -> void:
	if slot_id == "" or train == null or mission == null:
		return
	var mins := UserSettings.autosave_minutes()
	if mins <= 0:
		return
	_autosave_accum += delta
	if _autosave_accum >= float(mins) * 60.0:
		_autosave_accum = 0.0
		save_now(true)


func _hall_spot_near() -> Dictionary:
	if rig == null or train == null:
		return {}
	if not rig._on_foot and rig.mode != CameraRig.Mode.WALK:
		return {}
	if rig._train_walk or rig._cab_walk:
		return {}
	var best: Dictionary = {}
	var best_d := 2.45
	var p: Vector3 = rig._walk_pos
	for spot: Dictionary in hall_spots:
		var sp: Vector3 = spot.get("pos", Vector3.ZERO)
		var d := Vector2(p.x - sp.x, p.z - sp.z).length()
		if d < best_d and absf(p.y - sp.y) < 2.4:
			best_d = d
			best = spot
	return best


func _open_station_gates(station_index: int, seconds := 8.0) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for gi in range(hall_gates.size()):
		var g: Dictionary = hall_gates[gi]
		if int(g.get("station", -1)) != station_index:
			continue
		g["open_until"] = now + seconds
		var gn := g.get("node") as Node3D
		if gn != null:
			gn.set_meta("gate_open", true)


func _handle_hall_interact() -> bool:
	var spot := _hall_spot_near()
	if spot.is_empty():
		return false
	var now := Time.get_ticks_msec() / 1000.0
	match String(spot.get("type", "")):
		"ticket":
			hall_ticket_until = now + 600.0
			if hud != null:
				hud.toast("已取票：10 分钟内可在检票闸机按 E 验票进站", 3.0)
			return true
		"gate":
			if now > hall_ticket_until:
				if hud != null:
					hud.toast("请先在自动售票机按 E 取票", 2.4)
				return true
			_open_station_gates(int(spot.get("station", -1)), 9.0)
			if hud != null:
				hud.toast("验票通过，闸机已打开", 2.0)
			return true
		"shop":
			var price := int(spot.get("price", 15))
			var money := int(career.get("money", 0))
			if mode != "open" and money < price:
				if hud != null:
					hud.toast("资金不足，热饮需要 ¥%d" %price, 2.2)
				return true
			if mode != "open":
				career["money"] = money - price
				if mission != null:
					mission.money = int(career["money"])
			coffee_until = now + 180.0
			if hud != null:
				hud.toast("购买热咖啡：3 分钟内步行速度 +20%", 2.8)
			return true
	if hud != null:
		hud.toast("这里没有可操作的设备", 1.5)
	return true


func _update_hall_interactables(delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for gi in range(hall_gates.size()):
		var g: Dictionary = hall_gates[gi]
		var node := g.get("node") as Node3D
		if node == null or not is_instance_valid(node):
			continue
		var open_now := now < float(g.get("open_until", 0.0))
		node.set_meta("gate_open", open_now)
		var target := 1.0 if open_now else 0.0
		g["anim"] = move_toward(float(g.get("anim", 0.0)), target, delta * 3.2)
		for child: Node in node.get_children():
			if child is MeshInstance3D and String(child.name).begins_with("GateLeaf"):
				var leaf := child as MeshInstance3D
				var base := float(leaf.get_meta("leaf_base_z", leaf.position.z))
				leaf.position.z = base + signf(base) * float(g["anim"]) * 0.90
	for bi in range(hall_belts.size()):
		var belt: Dictionary = hall_belts[bi]
		var node := belt.get("node") as Node3D
		if node == null or not is_instance_valid(node):
			continue
		var dz := float(belt.get("dir", 1.0)) * float(belt.get("speed", 1.9)) * delta
		for step in belt.get("steps", []):
			var sm := step as MeshInstance3D
			if sm == null:
				continue
			sm.position.z += dz
			if sm.position.z > 8.0:
				sm.position.z -= 16.0
			elif sm.position.z < -8.0:
				sm.position.z += 16.0
		if rig != null and (rig._on_foot or rig.mode == CameraRig.Mode.WALK) \
				and not rig._train_walk and not rig._cab_walk:
			var local := node.global_transform.affine_inverse() * rig._walk_pos
			if absf(local.x) <= float(belt.get("half_x", 0.72)) \
					and absf(local.z) <= float(belt.get("half_z", 8.0)) \
					and local.y > -0.5 and local.y < 1.8:
				rig.walk_push += node.global_transform.basis.z * float(belt.get("dir", 1.0)) * float(belt.get("carry", 1.35))
	if rig != null:
		rig.walk_speed_mul = 1.0
		if now < coffee_until:
			rig.walk_speed_mul = 1.2


func _handle_interact() -> void:
	if rig == null or train == null:
		return
	if (rig._on_foot or rig.mode == CameraRig.Mode.WALK) \
			and not rig._train_walk and not rig._cab_walk and _handle_hall_interact():
		return
	if rig.mode == CameraRig.Mode.WALK:
		if rig.try_board():
			if hud != null:
				hud.toast("已登车", 1.8)
		elif hud != null:
			hud.toast("走近打开的站台侧车门后按 E 登车", 1.6)
	elif rig.mode == CameraRig.Mode.CAB:
		if rig._on_foot:
			if not rig._train_walk and rig.try_board():
				if hud != null:
					hud.toast("已登车", 1.8)
			elif hud != null:
				hud.toast("走到座椅旁按 F 坐下；车门需停靠站台并施加停放制动", 2.2)
			return
		var can_leave_seat := (absf(train.speed) < 0.5 and train.handbrake) \
				or (autopilot and autopilot_target >= 0)
		if not can_leave_seat:
			if absf(train.speed) >= 0.5:
				hud.toast("请先停车，并施加停放制动", 1.8)
			elif hud != null:
				hud.toast("停车后施加停放制动，或先启用自动驾驶", 2.0)
			return
		if rig.enter_cab_walk():
			if hud != null:
				hud.toast("已离开座椅，WASD 行走，F 坐下，E 登车", 2.2)


func _try_sit() -> void:
	if rig == null or train == null:
		return
	if rig.mode != CameraRig.Mode.CAB:
		return
	if not rig._on_foot or (not rig._train_walk and not rig._cab_walk):
		return
	var seat := rig.nearest_cab_seat()
	if seat < 0:
		if hud != null:
			hud.toast("附近没有可坐的座椅", 1.5)
		return
	rig.sit_down(seat)
	if hud != null:
		hud.toast("已坐下" if seat == 0 else "已坐到副驾驶座", 1.6)


func _mode_hint() -> String:
	if rig == null:
		return "V 回正"
	if (rig._on_foot or rig.mode == CameraRig.Mode.WALK) \
			and not rig._train_walk and not rig._cab_walk:
		var spot := _hall_spot_near()
		if not spot.is_empty():
			match String(spot.get("type", "")):
				"ticket":
					return "E 取票"
				"gate":
					return "E 验票通过"
				"shop":
					return "E 购买热饮 ¥%d" %int(spot.get("price", 15))
	match rig.mode:
		CameraRig.Mode.WALK:
			return "E 登车" if rig.can_board() else "WASD 行走  空格跳  Shift 跑  E 登车"
		CameraRig.Mode.CAB:
			if rig._on_foot:
				if rig._train_walk:
					var inside_loco := rig._walk_vehicle >= 0 \
							and rig._walk_vehicle < train.vehicles.size() \
							and train.vehicles[rig._walk_vehicle].kind == "loco"
					if inside_loco:
						return "WASD 行走  空格跳  Shift 跑  F 坐下  P 自动驾驶"
					return "WASD 行走  空格跳  Shift 跑  走到车头可回司机室  P 自动驾驶"
				return "WASD 行走  空格跳  Shift 跑  E 登车"
			return "左键操作  右键观察  P 自动驾驶  E 离开座椅  V 回正"
		_:
			return "C 第一视角  V 回正"


func _save_screenshot() -> void:
	var img := get_viewport().get_texture().get_image()
	var dir := "user://screenshots"
	DirAccess.make_dir_recursive_absolute(dir)
	var path := "%s/shot_%d.png" %[dir, Time.get_unix_time_from_system()]
	var err := img.save_png(path)
	hud.toast("截图已保存 %s" %("成功" if err == OK else "失败"), 2.2)

func _process(delta: float) -> void:
	_update_time_flow(delta)
	_update_weather(delta)
	_update_reflection_probe(delta)
	if startup != null:
		startup.step(delta)
		_update_startup_visuals(delta)
	if interaction != null and rig != null:
		interaction.enabled = rig.mode == CameraRig.Mode.CAB \
				or (rig.mode == CameraRig.Mode.WALK and rig._cab_walk)
	_update_hall_interactables(delta)
	_update_autosave(delta)
	if hud != null and train != null:
		var hint := ""
		if UserSettings.show_hints:
			hint = "   %s" %_mode_hint()
			if _hover_text != "":
				hint = "   [左键] %s   %s" %[_hover_text, hint]
		var route_txt := ""
		if selected_siding >= 0 or active_siding >= 0:
			route_txt = "   进路 %s" % _route_label()
		if autopilot:
			route_txt += "   自动驾驶 %s" % _autopilot_label()
		var extra := "   %.1f 时   %s   限速 %d   M 大地图   F5 地图模式   F1 界面   F3 调试%s%s" %[time_of_day, weather.label if weather != null else "晴朗", int(round(_line_limit())), hint, route_txt]
		hud.update(train, route, extra, _vehicle_status())
		if mission != null:
			hud.set_task_text(mission.hud_text())
			hud.set_progress(mission.progress, mission.show_progress())
			_update_signals()
			_update_loading()
		_update_doors()
		hud.set_dash_visible(not (rig != null and rig.mode == CameraRig.Mode.WALK
				and absf(train.speed) < 0.5))
	_sync_walk_crosshair()


func _update_doors() -> void:
	if train == null or not train.doors_open:
		return
	if absf(train.speed) > 0.5 or not train.handbrake or _platform_context().is_empty():
		train.doors_open = false
		train.door_open_side = 0
		train.cab_door_only = false


func _update_signals() -> void:
	if railway == null or mission == null or train == null:
		return
	if mission.task.is_empty():
		railway.update_signals(train.distance, 0.0, false, ai_train.distance if ai_train != null and ai_train.visible else -1.0, ai_train != null and ai_train.visible)
		return
	var require_stop := mission.phase == MissionSystem.Phase.BRIEFING or mission.phase == MissionSystem.Phase.RUNNING or mission.phase == MissionSystem.Phase.WAITING

	railway.update_signals(train.distance, mission.distance_to_stop(), require_stop, ai_train.distance if ai_train != null and ai_train.visible else -1.0, ai_train != null and ai_train.visible)


func _update_loading() -> void:
	if station_data.is_empty() or mission == null or mission.task.is_empty():
		return
	var active := -1
	if mission.phase == MissionSystem.Phase.LOADING:
		active = int(mission.task ["origin"])
	elif mission.phase == MissionSystem.Phase.UNLOADING:
		active = int(mission.task ["dest"])
	var top_y := 6.3
	for i in range(station_data.size()):
		var h := station_data [i].get("hoist") as Node3D
		if h == null:
			continue
		var load_y := 5.2 if h.has_meta("yard_x") else 2.35

		if h.has_meta("yard_x"):
			h.position.x = float(h.get_meta("yard_x"))
		else:
			h.position.x = train.siding_lateral(float(station_data [i] ["stop"]))
		if i != active:
			h.position.y = top_y
			continue
		var p := clampf(mission.progress, 0.0, 1.0)
		if mission.phase == MissionSystem.Phase.LOADING:
			h.position.y = lerpf(top_y, load_y, p)
		else:
			h.position.y = lerpf(load_y, top_y, p)
