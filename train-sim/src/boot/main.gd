extends Node3D



const GAME_NAME := "Duskrail"
const VERSION := "alpha1.9"
const LOADING_SCREEN := preload("res://src/ui/loading_screen.gd")

var shot_path := ""
var shot_frames := 120
var cam_pos := Vector3.INF
var cam_look := Vector3.INF
var cam_mode := ""
var probe_pos := Vector3.INF
var game: Game
var menu: MainMenu
var _pending_slot := ""
var _pending_name := "存档"
var _pending_state: Dictionary = {}
var _pending_new := false
var _splash: SplashScreen
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _loading: LoadingScreen
var _game_build_done := false
var _loading_test := false
var _loading_preview := false

func _ready() -> void:
	_parse_cmdline()
	_report_environment()
	_setup_theme_font()
	_setup_input()
	_migrate_legacy_userdata()
	var legacy_backups := SaveManager.backup_legacy_saves()
	if legacy_backups > 0:
		print("[save] backed up %d legacy save(s) to %s" %[legacy_backups, SaveManager.BACKUP_DIR])
	UserSettings.load_settings()
	if _qa_upscaler >= 0:
		UserSettings.upscaler = _qa_upscaler
	if _qa_quality >= 0:
		UserSettings.quality = _qa_quality
	UserSettings.apply_all()
	_apply_window_settings()
	if _fullscreen_override:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if _mute:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	if _save_test:
		_run_save_test()
		return
	if _seed_save:
		_run_seed_save()
		return
	if _gear_test:
		await _run_gear_test()
		return
	if _settings_test:
		_run_settings_test()
		return
	if _autosave_test:
		await _run_autosave_test()
		return
	if _new_save_test:
		await _run_new_save_test()
		return
	if _map_test:
		await _run_map_test()
		return
	if _load_test:
		await _run_load_test()
		return
	if _consist_load_test:
		await _run_consist_load_test()
		return
	if _consist_ui_test:
		await _run_consist_ui_test()
		return
	if _want_splash():
		_play_splash()
		return
	_after_boot()

func _want_splash() -> bool:
	if _force_splash:
		return true
	if shot_path != "":
		return false
	if mission_test or Game.startup_test or Game.probe_forward:
		return false
	if DisplayServer.get_name() == "headless":
		return false
	if _force_menu or _force_settings or _qa_single or _qa_saves or _qa_new or _qa_confirm:
		return false
	return true

func _play_splash() -> void:
	_splash = SplashScreen.new()
	_splash.name = "Splash"
	add_child(_splash)
	if _skip_splash_warning:
		_splash.skip_warning()
	if shot_path != "":
		_splash.finished.connect(func() -> void: pass)
		var wait := _splash_shot_wait
		if wait < 0.0:
			wait = 5.5
		await get_tree().create_timer(wait).timeout
		await _capture_and_quit()
		return
	_splash.finished.connect(_after_boot)

func _after_boot() -> void:
	if _loading_preview:
		_show_loading("正在生成线路与地形…")
		await get_tree().process_frame
		await get_tree().process_frame
		await _capture_and_quit()
		return
	if _loading_test:
		_pending_state = {}
		_pending_slot = ""
		_pending_name = "加载测试"
		_show_loading("正在加载测试世界")
		await get_tree().process_frame
		await _start_game_async()
		print("[loading-test] built veh=%d mode=%s" %[game.train.vehicles.size() if game != null and game.train != null else 0, game.mode if game != null else "?"])
		await _hide_loading()
		get_tree().quit()
		return
	if _walk_test:
		_pending_state = {}
		_pending_name = "QA Walk"
		_start_game()
		await _run_walk_test()
		return
	if _train_walk_test:
		_pending_state = {}
		_pending_name = "QA Train Walk"
		_start_game()
		await _run_train_walk_test()
		return
	if _legacy_save_test:
		_run_legacy_save_test()
		return
	if _legacy_save_load_test:
		await _run_legacy_save_load_test()
		return
	if _test_mode_test and _qa_new_mode == "":
		_qa_new_mode = "test"
	if _qa_new_mode != "":
		var qid := SaveManager.new_slot_id()
		var qstate := {"__new": true, "version": SaveManager.VERSION, "mode": _qa_new_mode, "world": {"time_of_day": 10.4}}
		SaveManager.write_save(qid, "QA %s" %_qa_new_mode, qstate)
		_pending_slot = qid
		_pending_name = "QA %s" %_qa_new_mode
		_pending_state = qstate
		_pending_new = true
		_start_game()
		if _qa_career_panel and game != null:
			game.open_career_panel()
		if _qa_tuning_panel and game != null:
			game.open_tuning_panel(_qa_tuning_category)
		if _test_mode_test and game != null:
			await _run_test_mode_test()
			return
		if shot_path != "":
			await get_tree().process_frame
			await get_tree().process_frame
			await _capture_and_quit()
		return
	if _want_menu():
		_open_menu()
		if _force_settings and menu != null:
			menu.open_settings(_settings_cat)
		if _qa_single and menu != null:
			menu.show_single()
		if _qa_saves and menu != null:
			menu.show_saves()
		if _qa_new and menu != null:
			menu.show_new_dialog()
		if _qa_confirm and menu != null:
			menu.show_delete_confirm()
	else:
		_start_game()
		if (_force_pause or _pause_settings) and game != null:
			game._toggle_pause()
		if _pause_settings and game != null and game.pause_menu != null:
			game.pause_menu.open_settings()
	if shot_path != "":
		_capture_and_quit()

func _on_menu_play(slot_id: String, save_name: String, state: Dictionary) -> void:
	_pending_slot = slot_id
	_pending_name = save_name
	_pending_state = state
	_pending_new = bool(state.get("__new", false))
	SaveManager.set_last_slot(slot_id)
	_show_loading("正在进入  %s" %save_name)
	await get_tree().process_frame
	await get_tree().process_frame
	if menu != null:
		menu.queue_free()
		menu = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _start_game_async()
	await get_tree().create_timer(0.15).timeout
	await _hide_loading()


func _ensure_fade() -> void:
	if _fade_layer != null:
		return
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 80
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)


func _fade_from_black(duration := 0.7) -> void:
	_ensure_fade()
	_fade_rect.color.a = 1.0
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _show_loading(text: String) -> void:
	if _loading != null:
		_loading.set_progress(0.0, text)
		return
	_loading = LOADING_SCREEN.new()
	_loading.name = "LoadingScreen"
	add_child(_loading)
	_loading.set_progress(0.0, text)


func _set_loading_progress(value: float, text: String) -> void:
	if _loading != null:
		_loading.set_progress(value, text)


func _hide_loading() -> void:
	if _loading == null:
		return
	var old := _loading
	_loading = null
	await old.close()


func _on_game_build_progress(value: float, text: String) -> void:
	_set_loading_progress(value, text)



func _parse_cmdline() -> void:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--shot="):
			shot_path = a.trim_prefix("--shot=")
		elif a.begins_with("--shot-frames="):
			shot_frames = maxi(1, int(a.trim_prefix("--shot-frames=")))
		elif a.begins_with("--cam-pos="):
			cam_pos = _vec3(a.trim_prefix("--cam-pos="))
		elif a.begins_with("--cam-look="):
			cam_look = _vec3(a.trim_prefix("--cam-look="))
		elif a.begins_with("--cam-mode="):
			cam_mode = a.trim_prefix("--cam-mode=")
		elif a.begins_with("--probe="):
			probe_pos = _vec3(a.trim_prefix("--probe="))
		elif a == "--flip":
			Forge.invert_winding = true
		elif a == "--mission-test":
			mission_test = true
		elif a == "--probe-forward":
			Game.probe_forward = true
		elif a == "--startup-test":
			Game.startup_test = true
		elif a == "--show-dev":
			Game.show_dev = true
		elif a.begins_with("--orbit="):
			_orbit = _vec3(a.trim_prefix("--orbit="))
		elif a.begins_with("--time="):
			_pending_time = float(a.trim_prefix("--time="))
		elif a.begins_with("--hide="):
			for part in a.trim_prefix("--hide=").split(","):
				Game.hidden_parts [part.strip_edges()] = true
		elif a == "--fullscreen":
			_fullscreen_override = true
		elif a == "--menu":
			_force_menu = true
		elif a == "--pause":
			_force_pause = true
		elif a == "--settings":
			_force_menu = true
			_force_settings = true
		elif a == "--mute":
			_mute = true
		elif a.begins_with("--weather="):
			Game.forced_weather = a.get_slice("=", 1)
		elif a == "--splash":
			_force_splash = true
		elif a == "--splash-intro":
			_force_splash = true
			_skip_splash_warning = true
		elif a.begins_with("--splash-wait="):
			_splash_shot_wait = float(a.trim_prefix("--splash-wait="))
		elif a == "--single":
			_qa_single = true
		elif a == "--saves":
			_qa_saves = true
		elif a == "--map":
			_qa_map = true
		elif a.begins_with("--new-mode="):
			_qa_new_mode = a.trim_prefix("--new-mode=")
		elif a == "--career-panel":
			_qa_career_panel = true
		elif a == "--tuning-panel":
			_qa_tuning_panel = true
		elif a == "--tuning-preview-test":
			_tuning_preview_test = true
		elif a.begins_with("--tuning-category="):
			_qa_tuning_category = a.trim_prefix("--tuning-category=")
		elif a == "--hide-body":
			_qa_hide_body = true
		elif a == "--hide-car-body":
			_qa_hide_car_body = true
		elif a == "--career-test":
			_qa_career_test = true
		elif a.begins_with("--gear="):
			_qa_gear = a.trim_prefix("--gear=")
		elif a == "--save-test":
			_save_test = true
		elif a == "--load-test":
			_load_test = true
		elif a == "--gear-test":
			_gear_test = true
		elif a == "--seed-save":
			_seed_save = true
		elif a == "--settings-test":
			_settings_test = true
		elif a.begins_with("--settings-cat="):
			_settings_cat = int(a.trim_prefix("--settings-cat="))
		elif a == "--new-save":
			_qa_new = true
		elif a == "--delete-confirm":
			_qa_confirm = true
		elif a == "--autosave-test":
			_autosave_test = true
		elif a == "--loading-preview":
			_loading_preview = true
		elif a == "--loading-test":
			_loading_test = true
		elif a == "--new-save-test":
			_new_save_test = true
		elif a == "--map-test":
			_map_test = true
		elif a == "--pause-settings":
			_pause_settings = true
		elif a.begins_with("--train-pos="):
			_qa_train_pos = float(a.trim_prefix("--train-pos="))
		elif a.begins_with("--switch="):
			_qa_switch = int(a.trim_prefix("--switch="))
		elif a.begins_with("--autopilot-test="):
			_qa_autopilot = int(a.trim_prefix("--autopilot-test="))
		elif a == "--autopilot-panel":
			_qa_autopilot_panel = true
		elif a.begins_with("--speed="):
			_qa_speed = float(a.trim_prefix("--speed="))
		elif a.begins_with("--reverser="):
			_qa_reverser = int(a.trim_prefix("--reverser="))
		elif a.begins_with("--bogie-cam"):
			_qa_bogie_cam = true
			if "=" in a:
				_qa_bogie_side = float(a.get_slice("=", 1))
		elif a.begins_with("--cab-yaw="):
			_qa_cab_yaw = float(a.trim_prefix("--cab-yaw="))
		elif a.begins_with("--cab-pitch="):
			_qa_cab_pitch = float(a.trim_prefix("--cab-pitch="))
		elif a.begins_with("--consist="):
			_qa_consist = a.trim_prefix("--consist=")
		elif a.begins_with("--engine="):
			_qa_engine = a.trim_prefix("--engine=")
		elif a.begins_with("--skin="):
			_qa_skin = a.trim_prefix("--skin=")
		elif a.begins_with("--transmission="):
			_qa_transmission = a.trim_prefix("--transmission=")
		elif a.begins_with("--parts="):
			_qa_parts = a.trim_prefix("--parts=")
		elif a.begins_with("--part-cam="):
			_qa_part_cam = a.trim_prefix("--part-cam=")
		elif a == "--doors-open":
			_qa_doors_open = true
		elif a == "--mini-zoom":
			_qa_mini_zoom = true
		elif a.begins_with("--consist-cars="):
			_qa_consist_cars = a.trim_prefix("--consist-cars=")
		elif a.begins_with("--consist-locos="):
			_qa_consist_locos = int(a.trim_prefix("--consist-locos="))
		elif a == "--consist-empty":
			_qa_consist_loaded = false
		elif a == "--consist-panel":
			_qa_consist_panel = true
		elif a.begins_with("--consist-select="):
			_qa_consist_select = int(a.trim_prefix("--consist-select="))
		elif a == "--consist-load-test":
			_consist_load_test = true
		elif a == "--consist-ui-test":
			_consist_ui_test = true
		elif a == "--test-mode-test":
			_test_mode_test = true
		elif a == "--walk-test":
			_walk_test = true
		elif a == "--train-walk-test":
			_train_walk_test = true
		elif a == "--legacy-save-test":
			_legacy_save_test = true
		elif a == "--legacy-save-load-test":
			_legacy_save_load_test = true
		elif a.begins_with("--upscaler="):
			_qa_upscaler = Upscaling.mode_from_name(a.trim_prefix("--upscaler="))
		elif a.begins_with("--quality="):
			match a.trim_prefix("--quality=").to_lower():
				"low":
					_qa_quality = Config.Quality.LOW
				"medium":
					_qa_quality = Config.Quality.MEDIUM
				"high":
					_qa_quality = Config.Quality.HIGH
				"ultra":
					_qa_quality = Config.Quality.ULTRA

var _pending_time := -1.0
var mission_test := false
var _test_phase := -1
var _orbit := Vector3.INF
var _mute := false
var _fullscreen_override := false
var _force_menu := false
var _force_pause := false
var _force_settings := false
var _force_splash := false
var _skip_splash_warning := false
var _splash_shot_wait := -1.0
var _qa_single := false
var _qa_saves := false
var _qa_map := false
var _qa_gear := ""
var _save_test := false
var _load_test := false
var _gear_test := false
var _seed_save := false
var _settings_test := false
var _settings_cat := 0
var _qa_new := false
var _qa_confirm := false
var _qa_new_mode := ""
var _qa_career_panel := false
var _qa_tuning_panel := false
var _qa_tuning_category := "parts"
var _tuning_preview_test := false
var _qa_hide_body := false
var _qa_hide_car_body := false
var _qa_career_test := false
var _autosave_test := false
var _new_save_test := false
var _map_test := false
var _pause_settings := false
var _qa_train_pos := -1.0
var _qa_speed := -1.0
var _qa_reverser := 0
var _qa_consist := ""
var _qa_engine := ""
var _qa_skin := ""
var _qa_transmission := ""
var _qa_parts := ""
var _qa_bogie_cam := false
var _qa_bogie_side := 1.0
var _qa_part_cam := ""
var _qa_doors_open := false
var _qa_mini_zoom := false
var _qa_consist_cars := ""
var _qa_consist_locos := 1
var _qa_consist_loaded := true
var _qa_consist_panel := false
var _qa_consist_select := -1
var _consist_load_test := false
var _consist_ui_test := false
var _test_mode_test := false
var _walk_test := false
var _train_walk_test := false
var _legacy_save_test := false
var _legacy_save_load_test := false
var _qa_cab_yaw := 0.0
var _qa_cab_pitch := 0.0
var _qa_upscaler := -1
var _qa_quality := -1
var _qa_switch := -1
var _qa_autopilot := -1
var _qa_autopilot_panel := false

func _vec3(s: String) -> Vector3:
	var parts := s.split(",")
	if parts.size() < 3:
		return Vector3.INF
	return Vector3(float(parts [0]), float(parts [1]), float(parts [2]))

func _migrate_legacy_userdata() -> void:
	var old_dir := OS.get_data_dir().path_join("Godot").path_join("app_userdata").path_join("Rail Era")
	var new_dir := OS.get_user_data_dir()
	if old_dir == new_dir or not DirAccess.dir_exists_absolute(old_dir):
		return
	if FileAccess.file_exists(new_dir.path_join("settings.cfg")):
		return
	if DirAccess.dir_exists_absolute(new_dir.path_join("saves")):
		return
	_copy_user_dir(old_dir, new_dir)
	print("[duskrail] migrated user data from legacy folder")

func _copy_user_dir(from: String, to: String) -> void:
	DirAccess.make_dir_recursive_absolute(to)
	var d := DirAccess.open(from)
	if d == null:
		return
	d.list_dir_begin()
	var entry := d.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var src := from.path_join(entry)
			var dst := to.path_join(entry)
			if d.current_is_dir():
				_copy_user_dir(src, dst)
			else:
				DirAccess.copy_absolute(src, dst)
		entry = d.get_next()
	d.list_dir_end()

func _report_environment() -> void:
	print("[duskrail] version=%s  godot=%s" %[VERSION, Engine.get_version_info().get("string", "?")])
	print("[duskrail] display=%s  rendering=%s" %[
		DisplayServer.get_name(),
		ProjectSettings.get_setting("rendering/renderer/rendering_method", "?"),
	])
	print("[duskrail] gpu=%s (%s)" %[
		RenderingServer.get_video_adapter_name(),
		RenderingServer.get_video_adapter_vendor(),
	])


const CJK_FONT_CANDIDATES := [
	"C:/Windows/Fonts/msyh.ttc",
	"C:/Windows/Fonts/msyhbd.ttc",
	"C:/Windows/Fonts/Deng.ttf",
	"C:/Windows/Fonts/simhei.ttf",
	"C:/Windows/Fonts/simsun.ttc",
	"C:/Windows/Fonts/msjh.ttc",
]

func _setup_theme_font() -> void:
	for path in CJK_FONT_CANDIDATES:
		if not FileAccess.file_exists(path):
			continue
		var font := FontFile.new()
		if font.load_dynamic_font(path) == OK:
			ThemeDB.fallback_font = font
			ThemeDB.fallback_font_size = 17
			print("[duskrail] cjk font=%s" %path)
			return
	push_warning("[duskrail] 未找到系统中文字体，界面中文可能显示异常")

func _setup_input() -> void:

	_key("gear_up", [KEY_W, KEY_UP])
	_key("gear_down", [KEY_S, KEY_DOWN])
	_key("doors_toggle", [KEY_A, KEY_LEFT])
	_key("lights_toggle", [KEY_D, KEY_RIGHT])
	_key("emergency_brake", [KEY_SPACE])
	_key("jump", [KEY_SPACE])
	_key("reverser_cycle", [KEY_R])
	_key("horn", [KEY_H])
	_key("wiper", [KEY_J])
	_key("switch_route", [KEY_G])
	_key("weather_cycle", [KEY_Y])
	_key("headlights", [KEY_L])
	_key("high_beam", [KEY_O])
	_key("doors", [KEY_K])
	_key("handbrake", [KEY_B])
	_key("sand", [KEY_X])
	_key("camera_next", [KEY_C])
	_key("camera_free", [KEY_F6])
	_key("camera_reset", [KEY_V])
	_key("interact", [KEY_E])
	_key("sit", [KEY_F])
	_key("autopilot", [KEY_P])
	_key("time_scale", [KEY_T])
	_key("hud_toggle", [KEY_F1])
	_key("dev_panel", [KEY_F3])
	_key("screenshot", [KEY_F12])
	_key("pause", [KEY_ESCAPE])
	_key("map_toggle", [KEY_M])
	_key("map_mode", [KEY_F5])
func _key(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

func _apply_window_settings() -> void:
	var win := get_window()
	win.title = "%s  v%s" %[GAME_NAME, VERSION]

func _want_menu() -> bool:
	if _force_menu:
		return true
	if _qa_single or _qa_saves or _qa_new or _qa_confirm:
		return true
	if shot_path != "":
		return false
	if mission_test or Game.startup_test or Game.probe_forward:
		return false
	if DisplayServer.get_name() == "headless":
		return false
	return true


func _open_menu() -> void:
	if menu != null:
		return
	menu = MainMenu.new()
	menu.name = "MainMenu"
	menu.version = VERSION
	add_child(menu)
	menu.play_requested.connect(_on_menu_play)
	_fade_from_black(0.65)


func _return_to_menu() -> void:
	if game != null:
		game.queue_free()
		game = null
	_pending_state = {}
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_open_menu()


func _restart_game() -> void:
	if game != null:
		game.queue_free()
		game = null
	get_tree().paused = false
	if _pending_slot != "":
		var data := SaveManager.read_save(_pending_slot)
		if not data.is_empty():
			_pending_state = data.get("state", {})
			_pending_name = String(data.get("name", _pending_name))
	_show_loading("正在重新载入  %s" %_pending_name)
	await get_tree().process_frame
	await _start_game_async()
	await get_tree().create_timer(0.15).timeout
	await _hide_loading()


func _make_game() -> Game:
	game = Game.new()
	game.name = "Game"
	game.slot_id = _pending_slot
	game.slot_name = _pending_name
	game.initial_state = _pending_state
	game.request_menu.connect(_return_to_menu)
	game.request_restart.connect(_restart_game)
	return game


func _start_game() -> void:
	if game != null:
		return
	_make_game()
	add_child(game)
	_after_game_started()


func _start_game_async() -> void:
	if game != null:
		return
	_game_build_done = false
	var g := _make_game()
	g.async_build = true
	g.build_progress.connect(_on_game_build_progress)
	g.build_finished.connect(func() -> void: _game_build_done = true)
	add_child(g)
	while not _game_build_done:
		await get_tree().process_frame
	_after_game_started()


func _after_game_started() -> void:
	var active_upscaler := Upscaling.apply_to_root(UserSettings.upscaler)
	print("[upscaling] requested=%s active=%s dlss=%s" %[
		Upscaling.label_for(UserSettings.upscaler),
		Upscaling.label_for(active_upscaler), str(Upscaling.dlss_available())])
	if _qa_switch >= 0 and game != null:
		game.selected_siding = _qa_switch
	if game != null:
		if _qa_autopilot >= 0:
			game.autopilot_verbose = true
			game.start_autopilot(_qa_autopilot)
		if _qa_autopilot_panel:
			game.open_autopilot()
	if _qa_consist != "" and game.train != null:
		game._rebuild_consist(_qa_consist, true)
	if _qa_consist_cars != "" and game != null:
		var cars: Array[String] = []
		if _qa_consist_cars != "none":
			for raw in _qa_consist_cars.split(",", false):
				var id := String(raw).strip_edges()
				if ConsistCatalog.has_car(id):
					cars.append(id)
		var cres: Dictionary = game.apply_custom_consist(cars, _qa_consist_locos, _qa_consist_loaded)
		print("[qa-consist] ok=%s msg=%s vehicles=%d" %[
			str(cres.get("ok", false)), String(cres.get("message", "")),
			game.train.vehicles.size() if game.train != null else -1])
	if _qa_train_pos >= 0.0 and game.train != null:
		game.train.distance = game.route.wrap_dist(_qa_train_pos)
		game.train.place()
	if _qa_reverser != 0 and game.train != null:
		game.train.reverser = 1 if _qa_reverser > 0 else -1
	if _qa_speed >= 0.0 and game.train != null:
		game.train.speed = _qa_speed
		game.train.place()
	if _qa_engine != "" or _qa_skin != "" or _qa_transmission != "" or _qa_parts != "":
		var e := _qa_engine if _qa_engine != "" else game.engine_id
		var s := _qa_skin if _qa_skin != "" else game.skin_id
		var tr := _qa_transmission if _qa_transmission != "" else game.transmission_id
		var pa: Array[String] = []
		var raw_parts = _qa_parts.split(",", false) if _qa_parts != "" else game.part_ids
		for p in raw_parts:
			var pid := String(p).strip_edges()
			if Vehicles.LOCO_PARTS.has(pid) and not pa.has(pid):
				pa.append(pid)
		game.apply_customization(e, s, tr, pa)
	if _qa_hide_body and game.train != null and not game.train.vehicles.is_empty():
		var hide_index := 0
		if _qa_part_cam.begins_with("wagon") and game.train.vehicles.size() > 1:
			hide_index = 1
		for node in game.train.vehicles[hide_index].body_root().get_children():
			if node is Node3D and (String(node.name).begins_with("Bogie") or String(node.name).begins_with("Wheelset")):
				continue
			if node is MeshInstance3D:
				node.visible = false
			elif node is Node3D:
				for sub in node.find_children("*", "MeshInstance3D", true, false):
					sub.visible = false
	if _qa_hide_car_body and game.train != null and game.train.vehicles.size() > 1:
		var cv: Vehicle = game.train.vehicles[1]
		for node in cv.body_root().get_children():
			if node is MeshInstance3D:
				node.visible = false
	if _qa_gear != "" and game.train != null:
		game.train.set_gear(_parse_gear(_qa_gear))
		if game.startup != null:
			game.startup.on_drive_gear(game.train.gear_is_drive())
	if _pending_slot != "" and(_pending_state.is_empty() or _pending_new):
		game.save_now(false)
		_pending_new = false
	if _qa_map and game.map_view != null:
		game.open_full_map()
	if _qa_mini_zoom and game.map_view != null:
		game.map_view.cycle_mini_mode()
	if _qa_consist_panel and game != null:
		game.open_consist_panel("pause")
		if _qa_consist_select >= 0 and game.consist_panel != null:
			game.consist_panel._select_car(_qa_consist_select)
	if _qa_career_panel and game != null:
		game.open_career_panel()
	if _qa_tuning_panel and game != null:
		game.open_tuning_panel(_qa_tuning_category)
	if _tuning_preview_test and game != null:
		await _run_tuning_preview_test()
	if mission_test:
		_run_mission_test()
	if _qa_career_test:
		_run_career_test()


func _run_career_test() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	print("[career-test] start mode=%s job=%s money=%d" %[
		game.mode, str(game.current_job.get("number", "")), int(game.career.get("money", 0))
	])
	if game.mission == null:
		print("[career-test] FAIL no mission")
		get_tree().quit()
		return
	var dest := int(game.current_job.get("dest", 0))
	game.train.distance = float(game.station_data [dest] ["stop"])
	game.train.speed = 0.0
	game.train.place()
	game.mission.phase = MissionSystem.Phase.UNLOADING
	game.mission.progress = 0.99
	game.mission.time_scale_debug = 20.0
	await get_tree().create_timer(2.0).timeout
	await get_tree().process_frame
	var ok := bool(game.career.get("job_finished", false))
	print("[career-test] finished=%s money=%d completed=%d level=%d panel=%s" %[
		ok, int(game.career.get("money", 0)), int(game.career.get("completed", 0)),
		int(game.career.get("level", 1)), str(game.career_panel != null and game.career_panel.visible)
	])
	get_tree().quit()


func _parse_gear(s: String) -> int:
	var key := s.strip_edges().to_upper()
	var idx := Train.GEAR_NAMES.find(key)
	return idx if idx >= 0 else Train.GEAR_P3


func _run_save_test() -> void:
	SaveManager.ensure_dir()
	var prev_last := SaveManager.last_slot()
	var id := "save_qa_%d" %Time.get_ticks_msec()
	var state := {
		"world": {"time_of_day": 10.0},
		"train": {"distance": 321.0, "gear": 5, "gear_name": "D2"},
		"mission": {"index": 1, "score": 42, "money": 42, "completed": 1},
	}
	var wrote := SaveManager.write_save(id, "QA 存档", state)
	var data := SaveManager.read_save(id)
	var found := false
	for s in SaveManager.list_saves():
		if String(s ["id"]) == id:
			found = true
	var sm: Dictionary = data.get("summary", {})
	var ok_read := String(data.get("name", "")) == "QA 存档" and int(sm.get("score", 0)) == 42
	print("[save-test] write=%s read=%s list=%s name=%s score=%d" %[
		str(wrote), str(ok_read), str(found), String(data.get("name", "")), int(sm.get("score", 0))])
	SaveManager.delete_save(id)
	var gone := not FileAccess.file_exists(SaveManager.slot_path(id))
	print("[save-test] delete=%s exists=%s" %[str(gone), str(not gone)])
	SaveManager.set_last_slot(prev_last)
	if not (wrote and ok_read and found and gone):
		push_error("[save-test] FAILED")
		get_tree().quit(1)
		return
	print("[save-test] OK")
	get_tree().quit(0)


func _run_load_test() -> void:
	var state := {
		"world": {"time_of_day": 12.0},
		"train": {"distance": 1234.5, "speed": 0.0, "reverser": 1, "gear": 6,
			"doors_open": false, "head_lights_on": true, "handbrake": false, "brake_cylinder": 0.0},
		"mission": {"index": 2, "phase": 0, "progress": 0.0, "elapsed": 0.0,
			"overspeed_time": 0.0, "pass_done": false, "score": 777, "money": 777, "completed": 7},
		"startup": {"state": 7, "battery_on": true, "cab_active": true, "panto_cmd": true,
			"panto_up": true, "vcb_on": true, "atp_ok": true, "brake_test_ok": true,
			"park_brake": false, "headlight_on": true, "wiper_on": false, "cab_light_on": true},
	}
	_pending_slot = ""
	_pending_name = "QA Load"
	_pending_state = state
	_start_game()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var out := game.get_save_data()
	var t: Dictionary = out.get("train", {})
	var m: Dictionary = out.get("mission", {})
	var ok := absf(float(t.get("distance", 0.0)) - 1234.5) < 0.5 \
		and int(t.get("gear", -1)) == 6 \
		and int(m.get("score", 0)) == 0 \
		and int(m.get("index", -1)) == -1
	print("[load-test] distance=%.1f gear=%s score=%d index=%d -> %s" %[
		float(t.get("distance", 0.0)), String(t.get("gear_name", "?")),
		int(m.get("score", 0)), int(m.get("index", -1)), str(ok)])
	get_tree().quit(0 if ok else 1)


func _run_consist_load_test() -> void:
	var state := {
		"mode": "open",
		"world": {"time_of_day": 12.0},
		"train": {
			"distance": 12000.0, "speed": 0.0, "reverser": 1, "gear": 3,
			"kind": "custom", "engine": "standard", "transmission": "balanced",
			"skin": "classic", "parts": [],
			"consist": {
				"locos": 2,
				"cars": ["water_tank", "flat", "gondola", "reefer"],
				"loaded": true,
			},
		},
	}
	_pending_slot = ""
	_pending_name = "QA Consist"
	_pending_state = state
	_start_game()
	await get_tree().process_frame
	await get_tree().process_frame
	var names: Array[String] = []
	var kinds: Array[String] = []
	var traction := 0.0
	for v in game.train.vehicles:
		names.append(v.name)
		kinds.append(v.kind)
		if v.kind == "loco":
			traction += v.tractive_force
	var ok := game.start_kind == "custom" \
		and game.custom_loco_count == 2 \
		and game.custom_cars.size() == 4 \
		and names.size() == 6 \
		and kinds [0] == "loco" and kinds [1] == "loco" \
		and absf(traction - 840000.0) < 100.0 \
		and game._custom_category() == "freight"
	print("[consist-load-test] kind=%s locos=%d cars=%d vehicles=%s traction=%.0f cat=%s ok=%s" %[
		game.start_kind, game.custom_loco_count, game.custom_cars.size(),
		str(names), traction, game._custom_category(), str(ok)])
	get_tree().quit(0 if ok else 1)


func _run_consist_ui_test() -> void:
	_pending_slot = ""
	_pending_name = "QA Consist UI"
	_pending_state = {}
	_start_game()
	await get_tree().process_frame
	await get_tree().process_frame
	game.open_consist_panel("pause")
	await get_tree().process_frame
	var panel = game.consist_panel
	var ok: bool = panel != null and panel.visible
	var mixed_count := 0
	if panel != null:
		panel._clear_cars()
		panel._add_car("passenger")
		panel._add_car("baggage")
		mixed_count = panel._cars.size()
		panel._add_car("container")
		ok = ok and mixed_count == 2 and panel._cars.size() == 2
		panel._on_loco_toggled(true)
		ok = ok and panel._locos == 2
		panel._apply(true)
		await get_tree().create_timer(0.6).timeout
	var vehicles := game.train.vehicles.size() if game.train != null else -1
	ok = ok and game.start_kind == "custom" and game.custom_loco_count == 2 \
		and game.custom_cars.size() == 2 and vehicles == 4
	print("[consist-ui-test] panel=%s mixed=%d locos=%d cars=%d vehicles=%d kind=%s ok=%s" %[
		str(panel != null), mixed_count if panel != null else -1,
		game.custom_loco_count, game.custom_cars.size(), vehicles, game.start_kind, str(ok)])
	get_tree().quit(0 if ok else 1)


func _body_rect(v: Vehicle) -> PackedVector2Array:
	var xf := v.global_transform
	var right := Vector2(xf.basis.x.x, xf.basis.x.z).normalized()
	var back := Vector2(xf.basis.z.x, xf.basis.z.z).normalized()
	var hx := v.width * 0.5
	var hz := v.length * 0.5
	var c := Vector2(xf.origin.x, xf.origin.z)
	return PackedVector2Array([
		c + right * hx + back * hz,
		c - right * hx + back * hz,
		c - right * hx - back * hz,
		c + right * hx - back * hz,
	])


func _rects_overlap(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	for poly: PackedVector2Array in [a, b]:
		for i in range(poly.size()):
			var p0: Vector2 = poly[i]
			var p1: Vector2 = poly[(i + 1) % poly.size()]
			var axis := Vector2(- (p1.y - p0.y), p1.x - p0.x)
			if axis.length_squared() < 0.000001:
				continue
			var amin := INF
			var amax := - INF
			var bmin := INF
			var bmax := - INF
			for p in a:
				var d := p.dot(axis)
				amin = minf(amin, d)
				amax = maxf(amax, d)
			for p in b:
				var d := p.dot(axis)
				bmin = minf(bmin, d)
				bmax = maxf(bmax, d)
			if amax < bmin - 0.000001 or bmax < amin - 0.000001:
				return false
	return true


func _point_seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var denom := ab.length_squared()
	var t := 0.0 if denom < 0.000001 else clampf((p - a).dot(ab) / denom, 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _rect_gap(a: PackedVector2Array, b: PackedVector2Array) -> float:
	var best := INF
	for p in a:
		for i in range(b.size()):
			best = minf(best, _point_seg_dist(p, b[i], b[(i + 1) % b.size()]))
	for p in b:
		for i in range(a.size()):
			best = minf(best, _point_seg_dist(p, a[i], a[(i + 1) % a.size()]))
	return best


func _run_walk_test() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if game == null or game.train == null or game.rig == null:
		print("[walk-test] FAIL missing game")
		get_tree().quit(1)
		return
	var rig = game.rig
	var t: Train = game.train
	# Bridge spawn must use the deck, not the valley/water below.
	var bridge_center: float = game.route.total * float(Config.BRIDGES[0]["frac"])
	t.distance = bridge_center
	t.place()
	rig.set_mode(CameraRig.Mode.WALK)
	var bridge_rp := game.route.position_at(bridge_center)
	var bridge_ok := absf(rig._walk_pos.y - (bridge_rp.y - 0.15)) < 0.08
	# Tunnel spawn must use the tunnel floor, not the mountain above.
	var tunnel_center: float = game.route.total * float(Config.TUNNELS[0]["frac"])
	t.distance = tunnel_center
	t.place()
	rig.spawn_on_foot()
	var tunnel_rp := game.route.position_at(tunnel_center)
	var tunnel_ok := absf(rig._walk_pos.y - (tunnel_rp.y - 0.85)) < 0.08
	# A must move left (+X when facing +Z), D must move right (-X).
	rig._walk_pos = Vector3.ZERO
	rig._walk_vel = Vector3.ZERO
	rig._look_yaw = 0.0
	Input.action_press("doors_toggle")
	rig._update_walk(0.20)
	Input.action_release("doors_toggle")
	var a_x: float = rig._walk_pos.x
	rig._walk_pos = Vector3.ZERO
	rig._walk_vel = Vector3.ZERO
	Input.action_press("lights_toggle")
	rig._update_walk(0.20)
	Input.action_release("lights_toggle")
	var d_x: float = rig._walk_pos.x
	var dir_ok := a_x > 0.05 and d_x < -0.05
	var space_ok := true
	for test_mode in [CameraRig.Mode.WALK, CameraRig.Mode.FREE]:
		rig.set_mode(test_mode)
		t.emergency = false
		Input.action_press("emergency_brake")
		game._handle_input(0.0)
		Input.action_release("emergency_brake")
		if t.emergency:
			space_ok = false
	# Cab walk: spawn at the seat, then step out through the open platform door.
	t.distance = 55.0
	t.speed = 0.0
	t.handbrake = true
	t.place()
	var station_ctx: Dictionary = game._platform_context()
	var cab_side := game._local_platform_side(station_ctx) if not station_ctx.is_empty() else -1
	t.doors_open = true
	t.door_open_side = cab_side
	t.cab_door_only = false
	rig.set_mode(CameraRig.Mode.WALK, true)
	var cab_ok: bool = rig._cab_walk and rig._walk_pos.distance_to(t.cab_position()) < 7.0
	var cab_exit := false
	var platform_ok := false
	var cv := t._cab_vehicle()
	if cv != null:
		var meta := rig._cab_walk_meta(cv)
		var xf := cv.global_transform
		rig._walk_pos = xf * Vector3(float(cab_side) * (float(meta["half"]) - 0.06),
				float(meta["floor"]) + 0.01, float(meta["door_z"]))
		rig._walk_pos += xf.basis.x * float(cab_side) * 0.32
		rig._cab_walk_step()
		cab_exit = not rig._cab_walk
		platform_ok = not rig._platform_at(rig._walk_pos).is_empty()
	# Walking through an open coach side door must enter the train without
	# jumping or being pushed to the opposite side.
	var side_entry := false
	if not t.vehicles.is_empty():
		var ev: Vehicle = t.vehicles[0]
		var emeta := rig._cab_walk_meta(ev)
		var edz := float(emeta["door_z"])
		var efloor := float(ev.get_meta("train_walk_floor", 1.2))
		t.doors_open = true
		t.door_open_side = 1
		rig._train_walk = false
		rig._cab_walk = false
		rig._walk_vehicle = -1
		rig._on_foot = true
		rig._walk_pos = ev.global_transform * Vector3(1.38, efloor, edz)
		var side_ret: bool = rig._try_enter_open_side_door()
		side_entry = side_ret and rig._train_walk and rig._walk_vehicle == 0
		rig._train_walk = false
		rig._cab_walk = false
		rig._walk_vehicle = -1
	t.doors_open = false
	t.door_open_side = 0
	# Jump must lift the on-foot body off the platform.
	rig._grounded = true
	rig._jump_vel = 0.0
	var jump_y0: float = rig._walk_pos.y
	Input.action_press("jump")
	rig._update_walk(0.02)
	Input.action_release("jump")
	var jump_ok: bool = rig._walk_pos.y > jump_y0 + 0.005 and not rig._grounded
	var platform_col := false
	if not game.station_data.is_empty():
		var st0: Dictionary = game.station_data[0]
		var fr0 := game.route.frame_at(float(st0["stop"]))
		var side0 := float(st0["side"])
		var edge0 := float(st0["platform_lat"]) - float(st0["platform_half"])
		var outside := fr0.origin + fr0.basis.x * side0 * (edge0 - 0.5)
		var inside := fr0.origin + fr0.basis.x * side0 * (edge0 + 0.4)
		rig._walk_pos = inside
		rig._resolve_platform_face(Vector2(outside.x, outside.z))
		platform_col = Vector2(rig._walk_pos.x, rig._walk_pos.z).distance_to(
				Vector2(outside.x, outside.z)) < 0.01
	# Cab seat / dashboard collision and train body collision.
	var seat_ok := false
	var body_ok := false
	var cv2 := t._cab_vehicle()
	if cv2 != null:
		var m2 := rig._cab_walk_meta(cv2)
		var xf2 := cv2.global_transform
		rig._cab_walk = true
		rig._walk_pos = xf2 * Vector3(float(m2["seat_x"]), float(m2["floor"]) + 0.01,
				float(m2["seat_z"]))
		rig._cab_walk_step()
		var la: Vector3 = xf2.affine_inverse() * rig._walk_pos
		seat_ok = absf(la.x - float(m2["seat_x"])) > 0.35 \
				or absf(la.z - float(m2["seat_z"])) > 0.65
		rig._cab_walk = false
		rig._walk_pos = xf2 * Vector3(0.0, 1.2, -6.0)
		rig._resolve_train_collision()
		var lb: Vector3 = xf2.affine_inverse() * rig._walk_pos
		body_ok = absf(lb.x) > 1.5
	# C must not leave first-person walk mode.
	Input.action_press("camera_next")
	game._handle_input(0.0)
	Input.action_release("camera_next")
	var walk_lock: bool = rig.mode == CameraRig.Mode.WALK
	print("[walk-test] bridge=%s tunnel=%s a_x=%.2f d_x=%.2f dir=%s space=%s cab=%s cab_exit=%s platform=%s side_entry=%s jump=%s platform_col=%s seat_col=%s body_col=%s walk_lock=%s ok=%s" %[
		str(bridge_ok), str(tunnel_ok), a_x, d_x, str(dir_ok), str(space_ok),
		str(cab_ok), str(cab_exit), str(platform_ok), str(side_entry), str(jump_ok),
		str(platform_col), str(seat_ok), str(body_ok), str(walk_lock),
		str(bridge_ok and tunnel_ok and dir_ok and space_ok and cab_ok and cab_exit and platform_ok and side_entry and jump_ok and platform_col and seat_ok and body_ok and walk_lock)])
	get_tree().quit(0 if bridge_ok and tunnel_ok and dir_ok and space_ok and cab_ok and cab_exit and platform_ok and side_entry and jump_ok and platform_col and seat_ok and body_ok and walk_lock else 1)


func _run_train_walk_test() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if game == null or game.train == null or game.rig == null:
		print("[train-walk-test] FAIL missing game")
		get_tree().quit(1)
		return
	var t: Train = game.train
	var rig = game.rig
	var enough := t.vehicles.size() >= 3
	var walkable := 0
	for v: Vehicle in t.vehicles:
		if v != null and v.has_meta("train_walk"):
			walkable += 1
	t.handbrake = true
	t.speed = 0.0
	t.place()
	rig.set_mode(CameraRig.Mode.CAB)
	var entered: bool = rig.enter_cab_walk()
	var loco: Vehicle = t.vehicles[0]
	var loco_door := loco.find_child("EndDoorRear", true, false) as Node3D
	var loco_gang := loco.find_child("RearGangway", true, false) as Node3D
	var loco_link := loco_door != null and not loco_door.visible \
			and loco_gang != null and loco_gang.visible
	# Cross from the locomotive into the first coach.
	var floor_y := float(loco.get_meta("train_walk_floor", 1.2))
	rig._walk_vehicle = 0
	rig._walk_pos = loco.global_transform * Vector3(
			0.0, floor_y, float(loco.get_meta("train_walk_back", 9.35)) + 3.0)
	rig._train_walk_step()
	var cross_loco: bool = rig._walk_vehicle == 1
	# Cross two coach boundaries.
	var cross_coach := true
	for idx: int in range(1, t.vehicles.size() - 1):
		var cv: Vehicle = t.vehicles[idx]
		var cf := float(cv.get_meta("train_walk_floor", 1.2))
		rig._walk_vehicle = idx
		rig._walk_pos = cv.global_transform * Vector3(
				0.0, cf, float(cv.get_meta("train_walk_back", 12.0)) + 3.0)
		rig._train_walk_step()
		cross_coach = cross_coach and rig._walk_vehicle == idx + 1
	# The last coach must have a closed rear door and no rear bellows.
	var last: Vehicle = t.vehicles[t.vehicles.size() - 1]
	var last_door := last.find_child("EndDoorRear", true, false) as Node3D
	var last_gang := last.find_child("GangwayRear", true, false) as Node3D
	var last_closed := last_door != null and last_door.visible \
			and (last_gang == null or not last_gang.visible)
	var last_idx := t.vehicles.size() - 1
	rig._walk_vehicle = last_idx
	var lf := float(last.get_meta("train_walk_floor", 1.2))
	rig._walk_pos = last.global_transform * Vector3(
			0.0, lf, float(last.get_meta("train_walk_back", 12.0)) + 3.0)
	rig._train_walk_step()
	var last_blocked: bool = rig._walk_vehicle == last_idx
	# Board through a passenger-coach side door, then step back out.
	var coach: Vehicle = t.vehicles[1]
	var cdoor_z := coach.length * 0.5 - 2.3
	var cfloor := float(coach.get_meta("train_walk_floor", 1.2))
	t.doors_open = true
	t.door_open_side = 1
	rig._walk_pos = coach.global_transform * Vector3(
			coach.width * 0.5 + 1.0, cfloor, cdoor_z)
	var board_ok: bool = rig.can_board() and rig.try_board()
	var entered_coach: bool = board_ok and rig.mode == CameraRig.Mode.CAB \
			and rig._on_foot and rig._walk_vehicle == 1
	rig._walk_pos = coach.global_transform * Vector3(
			1.58, cfloor, cdoor_z)
	rig._train_walk_step()
	var exited_coach: bool = not rig._train_walk and rig._walk_vehicle == -1
	t.doors_open = false
	t.door_open_side = 0
	# The walker must stay attached to a moving car.
	rig._train_walk = true
	rig._walk_vehicle = 1
	rig._on_foot = true
	rig._walk_vel = Vector3.ZERO
	rig._walk_pos = coach.get_global_transform_interpolated() * Vector3(0.0, cfloor, 0.0)
	rig._update_walk(0.0)
	var move_before: Vector3 = coach.get_global_transform_interpolated().affine_inverse() * rig._walk_pos
	t.distance += 12.0
	t.place()
	rig._update_walk(0.016)
	var move_after: Vector3 = coach.get_global_transform_interpolated().affine_inverse() * rig._walk_pos
	var follow_ok: bool = Vector2(move_after.x - move_before.x,
			move_after.z - move_before.z).length() < 0.25
	print("[train-walk-test] follow before=%s after=%s dist=%.1f speed=%.2f" % [
			str(move_before), str(move_after), t.distance, t.speed])
	# Seat 1 must be reachable on foot and usable.
	var cv0 := t._cab_vehicle()
	var seat_ok := false
	if cv0 != null:
		var m := rig._cab_walk_meta(cv0)
		rig._walk_vehicle = 0
		rig._cab_walk = true
		rig._on_foot = true
		rig._walk_pos = cv0.global_transform * Vector3(
				float(m["seat_x2"]), float(m["floor"]), float(m["seat_z"]))
		var nearest := rig.nearest_cab_seat()
		if nearest == 1:
			rig.sit_down(1)
			seat_ok = rig._cab_seat == 1 and not rig._on_foot
	# All side doors must follow the same door_anim, including the cab.
	t.door_anim = 0.0
	t.doors_open = true
	t.door_open_side = 1
	t.cab_door_only = false
	t.update_cab_and_doors(4.0)
	var coach_door_open := false
	var cab_door_open := false
	for l: Node3D in coach.door_leaves:
		var dside := int(l.get_meta("door_side", 0))
		if dside == 1:
			var closed: Vector3 = l.get_meta("closed_pos", l.position)
			coach_door_open = l.position.distance_to(closed) > 0.5
	var loco2: Vehicle = t.vehicles[0]
	for l: Node3D in loco2.door_leaves:
		var dside := int(l.get_meta("door_side", 0))
		if dside == 1:
			var closed: Vector3 = l.get_meta("closed_pos", l.position)
			cab_door_open = l.position.distance_to(closed) > 0.5
	t.doors_open = false
	t.door_open_side = 0
	t.update_cab_and_doors(4.0)
	var coach_door_closed := true
	for l: Node3D in coach.door_leaves:
		var closed: Vector3 = l.get_meta("closed_pos", l.position)
		if l.position.distance_to(closed) > 0.05:
			coach_door_closed = false
	var door_sync: bool = coach_door_open and cab_door_open and coach_door_closed
	# Walk across a real gangway with movement input, not a teleport.
	t.distance = 55.0
	t.place()
	await get_tree().physics_frame
	await get_tree().process_frame
	rig.set_mode(CameraRig.Mode.CAB)
	rig._train_walk = true
	rig._cab_walk = false
	rig._on_foot = true
	rig._walk_vehicle = 1
	rig._walk_vel = Vector3.ZERO
	rig._last_walk_valid = false
	rig._look_yaw = PI
	var wc: Vehicle = t.vehicles[1]
	rig._walk_pos = wc.get_global_transform_interpolated() * Vector3(
			0.0, float(wc.get_meta("train_walk_floor", 1.2)), 5.0)
	Input.action_press("gear_up")
	var prev_walk: Vector3 = rig._walk_pos
	var max_walk_step := 0.0
	for _step: int in range(600):
		rig._update_walk(1.0 / 60.0)
		max_walk_step = maxf(max_walk_step, prev_walk.distance_to(rig._walk_pos))
		prev_walk = rig._walk_pos
	Input.action_release("gear_up")
	rig._walk_vel = Vector3.ZERO
	var walk_local := Vector3.INF
	if rig._walk_vehicle >= 0 and rig._walk_vehicle < t.vehicles.size():
		walk_local = t.vehicles[rig._walk_vehicle].get_global_transform_interpolated().affine_inverse() * rig._walk_pos
	print("[train-walk-test] walk veh=%d local=%s trainwalk=%s onfoot=%s step=%.3f" % [
			rig._walk_vehicle, str(walk_local), str(rig._train_walk), str(rig._on_foot), max_walk_step])
	var walk_cross: bool = rig._walk_vehicle >= 2 and max_walk_step < 0.30
	# Repeat the same crossing while the train is actually rolling.
	t.speed = 10.0
	t.notch = 0
	t.brake_notch = 0
	t.handbrake = false
	rig._walk_vehicle = 1
	rig._train_walk = true
	rig._cab_walk = false
	rig._on_foot = true
	rig._walk_vel = Vector3.ZERO
	rig._last_walk_valid = false
	rig._look_yaw = PI
	rig._walk_pos = wc.get_global_transform_interpolated() * Vector3(
			0.0, float(wc.get_meta("train_walk_floor", 1.2)), 0.0)
	Input.action_press("gear_up")
	var prev_moving: Vector3 = rig._walk_pos
	var max_moving_step := 0.0
	for _mstep: int in range(500):
		t.step(1.0 / 60.0)
		rig._update_walk(1.0 / 60.0)
		max_moving_step = maxf(max_moving_step, prev_moving.distance_to(rig._walk_pos))
		prev_moving = rig._walk_pos
	Input.action_release("gear_up")
	rig._walk_vel = Vector3.ZERO
	t.speed = 0.0
	t.place()
	var moving_cross: bool = rig._walk_vehicle >= 2 and max_moving_step < 0.50
	var ok: bool = enough and walkable >= 3 and entered and loco_link and cross_loco \
			and cross_coach and last_closed and last_blocked and entered_coach \
			and exited_coach and follow_ok and seat_ok and door_sync and walk_cross \
			and moving_cross
	print("[train-walk-test] enough=%s walkable=%d entered=%s loco_link=%s cross_loco=%s cross_coach=%s last_closed=%s last_blocked=%s board=%s exit=%s follow=%s seat=%s doors=%s walk=%s moving=%s ok=%s" % [
			str(enough), walkable, str(entered), str(loco_link), str(cross_loco),
			str(cross_coach), str(last_closed), str(last_blocked), str(entered_coach),
			str(exited_coach), str(follow_ok), str(seat_ok), str(door_sync),
			str(walk_cross), str(moving_cross), str(ok)])
	get_tree().quit(0 if ok else 1)


func _run_legacy_save_test() -> void:
	var id := ""
	var created := false
	for s: Dictionary in SaveManager.list_saves():
		if bool(s.get("legacy", false)):
			id = String(s.get("id", ""))
			break
	if id == "":
		id = "legacy_qa_%d" %Time.get_ticks_msec()
		SaveManager.ensure_dir()
		var cfg := ConfigFile.new()
		cfg.set_value("meta", "name", "Legacy QA")
		cfg.set_value("meta", "timestamp", int(Time.get_unix_time_from_system()))
		cfg.set_value("meta", "version", 2)
		cfg.set_value("meta", "summary", {"distance": 55.0, "gear": "P3"})
		cfg.set_value("state", "data", {
			"mode": "open",
			"world": {"time_of_day": 10.0},
			"train": {"distance": 55.0, "speed": 0.0, "gear_name": "P3"},
		})
		cfg.save(SaveManager.slot_path(id))
		created = true
	var data := SaveManager.read_save(id)
	var before := 0
	var bd := DirAccess.open(SaveManager.BACKUP_DIR)
	if bd != null:
		bd.list_dir_begin()
		var f := bd.get_next()
		while f != "":
			if f.ends_with(".cfg"):
				before += 1
			f = bd.get_next()
		bd.list_dir_end()
	var copied := SaveManager.backup_legacy_saves()
	var after := 0
	bd = DirAccess.open(SaveManager.BACKUP_DIR)
	if bd != null:
		bd.list_dir_begin()
		var f := bd.get_next()
		while f != "":
			if f.ends_with(".cfg"):
				after += 1
			f = bd.get_next()
		bd.list_dir_end()
	var read_ok := not data.is_empty() and int(data.get("version", 0)) < SaveManager.VERSION
	var backup_ok := after > 0 and (copied > 0 or before > 0)
	var ok := read_ok and backup_ok
	print("[legacy-save-test] id=%s version=%d read=%s backup=%d->%d ok=%s" %[
			id, int(data.get("version", 0)) if not data.is_empty() else -1,
			str(read_ok), before, after, str(ok)])
	if created:
		SaveManager.delete_save(id)
		var bp := SaveManager.BACKUP_DIR.path_join("%s_v2.cfg" %id)
		if FileAccess.file_exists(bp):
			DirAccess.remove_absolute(bp)
	get_tree().quit(0 if ok else 1)


func _run_legacy_save_load_test() -> void:
	var legacy_id := ""
	for s: Dictionary in SaveManager.list_saves():
		if bool(s.get("legacy", false)):
			legacy_id = String(s.get("id", ""))
			break
	if legacy_id == "":
		print("[legacy-save-load-test] no legacy save -> false")
		get_tree().quit(1)
		return
	var data := SaveManager.read_save(legacy_id)
	if data.is_empty():
		print("[legacy-save-load-test] read failed -> false")
		get_tree().quit(1)
		return
	_pending_slot = legacy_id
	_pending_name = String(data.get("name", "Legacy"))
	_pending_state = data.get("state", {})
	_pending_new = false
	_start_game()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var ok := game != null and game.train != null
	var dist := game.train.distance if ok else -1.0
	var legacy_state: Dictionary = data.get("state", {})
	var legacy_train: Dictionary = legacy_state.get("train", {})
	var legacy_world: Dictionary = legacy_state.get("world", {})
	var expected := float(legacy_train.get("distance", -1.0))
	var saved_total := float(legacy_world.get("route_length", 0.0))
	if saved_total <= 1.0:
		saved_total = 51854.0
	if game != null and game.route != null:
		expected = expected * game.route.total / saved_total
	ok = ok and absf(dist - expected) < 2.0
	print("[legacy-save-load-test] id=%s version=%d distance=%.1f expected=%.1f ok=%s" %[
			legacy_id, int(data.get("version", 0)), dist, expected, str(ok)])
	get_tree().quit(0 if ok else 1)


func _run_test_mode_test() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if game == null or game.train == null or game.route == null:
		print("[test-mode-test] FAIL missing game")
		get_tree().quit(1)
		return
	var t: Train = game.train
	var r: Route = game.route
	var min_radius := INF
	var min_radius_dist := 0.0
	var max_grade := 0.0
	var max_grade_dist := 0.0
	var d := 0.0
	while d < r.total:
		var curv := r.curvature_at(d)
		if curv > 0.000001:
			var rad := 1.0 / curv
			if rad < min_radius:
				min_radius = rad
				min_radius_dist = d
		var grade := absf(tan(r.gradient_at(d)))
		if grade > max_grade:
			max_grade = grade
			max_grade_dist = d
		d += 5.0
	print("[test-mode-test] mode=%s route=%.2f km min_radius=%.1f m at %.0f m %s max_grade=%.1f%% at %.0f m traction=%.0f kN vehicles=%d" %[
		game.mode, r.total / 1000.0, min_radius, min_radius_dist, str(r.position_at(min_radius_dist)),
		max_grade * 100.0, max_grade_dist, t.max_tractive_force / 1000.0, t.vehicles.size()])
	# Sweep the whole loop with the real test train and check every vehicle
	# body pair for overlap. This catches a curve that is too tight for the
	# 25.5 m coaches before it reaches the player.
	var overlap_pairs := 0
	var min_gap := INF
	var min_gap_at := 0.0
	var sample := 0.0
	while sample < r.total:
		t.distance = sample
		t._place_vehicles(0.0)
		var rects: Array = []
		for v in t.vehicles:
			rects.append(_body_rect(v))
		for i in range(rects.size()):
			for j in range(i + 1, rects.size()):
				var ra: PackedVector2Array = rects[i]
				var rb: PackedVector2Array = rects[j]
				if _rects_overlap(ra, rb):
					overlap_pairs += 1
				else:
					var gap := _rect_gap(ra, rb)
					if gap < min_gap:
						min_gap = gap
						min_gap_at = sample
		sample += 5.0
	var clear_ok := overlap_pairs == 0 and min_gap > 0.02
	print("[test-mode-test] clearance=%.3f m at %.0f m overlaps=%d" %[
		min_gap, min_gap_at, overlap_pairs])
	t.distance = max_grade_dist
	t.place()
	t.speed = 15.0
	t.reverser = 1
	t.emergency = false
	t.handbrake = false
	t.brake_cylinder = 0.0
	t.doors_open = false
	t.set_gear(Train.GEAR_D5)
	var dt := 1.0 / 60.0
	for i in range(300):
		t.step(dt)
	var kmh := t.speed_kmh()
	print("[test-mode-test] climb 5s speed=%.1f km/h accel=%.2f m/s2 grade=%.1f%% dist=%.0f m" %[
		kmh, t.acceleration, t.gradient * 100.0, t.distance])
	# Curve-entry smoothness: run through a known tight curve and record the
	# largest per-tick change of the body roll. A step (instead of an eased
	# transition) would show up as a large spike.
	t.distance = r.wrap_dist(min_radius_dist - 110.0)
	t.speed = 16.0
	t.set_gear(Train.GEAR_N)
	t.handbrake = false
	t.brake_cylinder = 0.0
	t.place()
	var prev_roll := t.vehicles[0].body_roll_dyn
	var max_droll := 0.0
	for i in range(360):
		t.step(dt)
		var v0: Vehicle = t.vehicles[0]
		max_droll = maxf(max_droll, absf(v0.body_roll_dyn - prev_roll))
		prev_roll = v0.body_roll_dyn
	print("[test-mode-test] curve-entry max_droll=%.5f rad roll=%.4f" %[
		max_droll, t.vehicles[0].body_roll_dyn])
	# Default chase camera must be rigidly attached to the interpolated train
	# transform; sample its local offset over several rendered frames.
	game.rig.set_mode(CameraRig.Mode.CHASE)
	for i in range(4):
		await get_tree().process_frame
	var chase_base := Vector3.ZERO
	var chase_dev := 0.0
	for i in range(36):
		await get_tree().process_frame
		var lead: Vehicle = t.vehicles[0]
		# Force one camera update in this frame so the probe sees the same
		# interpolated transform as the renderer, not the previous frame.
		game.rig._update_chase(0.0)
		var xf := lead.get_global_transform_interpolated()
		var local := xf.basis.inverse() * (game.rig.camera.global_position - xf.origin)
		if i == 0:
			chase_base = local
		else:
			chase_dev = maxf(chase_dev, (local - chase_base).length())
	print("[test-mode-test] chase_local_dev=%.4f m" %chase_dev)
	var ok: bool = game.mode == "test" and r.total > 3000.0 \
		and min_radius < 100.0 and max_grade > 0.07 and clear_ok \
		and t.max_tractive_force >= 1700000.0 and kmh > 60.0 \
		and chase_dev < 0.05
	print("[test-mode-test] ok=%s" %str(ok))
	get_tree().quit(0 if ok else 1)


func _run_tuning_preview_test() -> void:
	game.open_tuning_panel("parts")
	await get_tree().process_frame
	var panel = game.tuning_panel
	var ok: bool = panel != null and panel._category == "parts" \
		and panel._category_buttons.has("parts") \
		and not panel._category_buttons.has("power")
	if panel == null:
		print("[tuning-preview-test] panel missing")
		get_tree().quit(1)
		return
	panel._set_category("look")
	ok = ok and panel._category == "look"
	panel._set_category("parts")
	var z0: float = panel._preview_zoom
	panel._zoom_preview(0.9)
	var z1: float = panel._preview_zoom
	var y0: float = panel._preview_yaw
	var p0: float = panel._preview_pitch
	panel._orbit_preview(Vector2(12.0, 10.0))
	var y1: float = panel._preview_yaw
	var p1: float = panel._preview_pitch
	var dist: float = panel._preview_camera.position.distance_to(Vector3(0.0, 2.0, 0.0))
	ok = ok and z1 < z0 and y1 > y0 and p1 > p0 \
		and absf(dist - 24.0 * z1) < 0.05

	# 模拟真实输入：滚轮缩放、右键拖动旋转、松开结束。
	var center: Vector2 = panel._preview_container.get_global_rect().get_center()
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.position = center
	panel._input(wheel)
	var z2: float = panel._preview_zoom
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	press.position = center
	panel._input(press)
	var drag_y0: float = panel._preview_yaw
	var drag_p0: float = panel._preview_pitch
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(10.0, 10.0)
	panel._input(motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_RIGHT
	release.pressed = false
	release.position = center
	panel._input(release)
	ok = ok and z2 < z1 and not panel._preview_dragging \
		and panel._preview_yaw > drag_y0 and panel._preview_pitch > drag_p0
	# Walk mode: camera drops to eye height and can leave the orbit pivot.
	panel._toggle_preview_walk()
	var walk_ok: bool = panel._preview_walk and panel._walk_button.text == "退出行走" \
		and absf(panel._preview_camera.position.y - 1.72) < 0.01
	panel._walk_pos = Vector3(8.0, 1.72, 4.0)
	panel._update_walk_camera()
	var walk_moved: bool = panel._preview_camera.position.distance_to(Vector3(8.0, 1.72, 4.0)) < 0.01
	panel._toggle_preview_walk()
	ok = ok and walk_ok and walk_moved and not panel._preview_walk \
		and panel._walk_button.text == "行走模式"
	print("[tuning-preview-test] category=%s zoom=%.3f->%.3f->%.3f yaw=%.3f->%.3f pitch=%.3f->%.3f dist=%.3f walk=%s ok=%s" %[
		panel._category, z0, z1, z2, y0, y1, p0, p1, dist, str(walk_ok), str(ok)])
	get_tree().quit(0 if ok else 1)


func _run_map_test() -> void:
	_pending_slot = ""
	_pending_state = {}
	_pending_name = "QA Map"
	_start_game()
	await get_tree().process_frame
	await get_tree().process_frame
	UserSettings.map_pause = true
	game.open_full_map()
	var a := get_tree().paused and game.map_view.is_full()
	game.map_view.close_full()
	await get_tree().process_frame
	var b := not get_tree().paused and not game.map_view.is_full()
	UserSettings.map_pause = false
	game.open_full_map()
	var c := not get_tree().paused and game.map_view.is_full()
	game.map_view.close_full()
	var z0: bool = game.map_view.mini_zoom
	var msg := game.map_view.cycle_mini_mode()
	var z1: bool = game.map_view.mini_zoom
	var msg2 := game.map_view.cycle_mini_mode()
	var z2: bool = game.map_view.mini_zoom
	var zoom_ok := z1 != z0 and z2 == z0 and msg != "" and msg2 != "" \
			and game.map_view._xform().get_scale().x > 0.0
	var ok := a and b and c and zoom_ok
	print("[map-test] pause_on_open=%s resume_on_esc=%s continue_when_off=%s zoom=%s -> %s" %[
		str(a), str(b), str(c), str(zoom_ok), str(ok)])
	get_tree().quit(0 if ok else 1)


func _run_new_save_test() -> void:
	SaveManager.ensure_dir()
	var prev_last := SaveManager.last_slot()
	var id := SaveManager.new_slot_id()
	await _on_menu_play(id, "QA 新档", {})
	await get_tree().process_frame
	await get_tree().process_frame
	var exists := FileAccess.file_exists(SaveManager.slot_path(id))
	var data := SaveManager.read_save(id)
	var gear := game.train.gear_name() if game != null and game.train != null else "?"
	var ok := exists and game != null and game.train != null \
		and String(data.get("name", "")) == "QA 新档" and gear == "P3"
	print("[new-save-test] exists=%s name=%s gear=%s ok=%s" %[
		str(exists), String(data.get("name", "")), gear, str(ok)])
	SaveManager.delete_save(id)
	SaveManager.set_last_slot(prev_last)
	get_tree().quit(0 if ok else 1)


func _run_autosave_test() -> void:
	SaveManager.ensure_dir()
	var prev_last := SaveManager.last_slot()
	var id := SaveManager.new_slot_id()
	_pending_slot = id
	_pending_name = "QA 自动保存"
	_pending_state = {}
	UserSettings.autosave_index = 3
	_start_game()
	var path := SaveManager.slot_path(id)
	var t0 := FileAccess.get_modified_time(path)
	game._autosave_accum = maxf(0.0, float(UserSettings.autosave_minutes()) * 60.0 - 2.0)
	print("[autosave-test] slot=%s initial_mtime=%d  interval=%d min  等待触发…" %[
		id, t0, UserSettings.autosave_minutes()])
	await get_tree().create_timer(4.0).timeout
	var t1 := FileAccess.get_modified_time(path)
	var ok := t1 > t0
	print("[autosave-test] mtime %d -> %d  ok=%s" %[t0, t1, str(ok)])
	SaveManager.delete_save(id)
	SaveManager.set_last_slot(prev_last)
	get_tree().quit(0 if ok else 1)


func _run_settings_test() -> void:
	var prev := {
		"quality": UserSettings.quality,
		"autosave_index": UserSettings.autosave_index,
		"map_pause": UserSettings.map_pause,
		"cold_start": UserSettings.cold_start,
		"show_hints": UserSettings.show_hints,
		"fov": UserSettings.fov,
		"mouse_sensitivity": UserSettings.mouse_sensitivity,
		"invert_look_y": UserSettings.invert_look_y,
	}
	UserSettings.quality = Config.Quality.MEDIUM
	UserSettings.autosave_index = 3
	UserSettings.map_pause = false
	UserSettings.cold_start = true
	UserSettings.show_hints = false
	UserSettings.fov = 75.0
	UserSettings.mouse_sensitivity = 1.7
	UserSettings.invert_look_y = true
	UserSettings.save_settings()
	UserSettings.reset_defaults()
	UserSettings.load_settings()
	var ok := UserSettings.quality == Config.Quality.MEDIUM \
		and UserSettings.autosave_index == 3 \
		and UserSettings.autosave_minutes() == 1 \
		and UserSettings.map_pause == false \
		and UserSettings.cold_start == true \
		and UserSettings.show_hints == false \
		and absf(UserSettings.fov - 75.0) < 0.01 \
		and absf(UserSettings.mouse_sensitivity - 1.7) < 0.01 \
		and UserSettings.invert_look_y == true
	print("[settings-test] autosave=%d min=%d map_pause=%s cold=%s hints=%s fov=%.1f sens=%.2f invert=%s -> %s" %[
		UserSettings.autosave_index, UserSettings.autosave_minutes(), str(UserSettings.map_pause),
		str(UserSettings.cold_start), str(UserSettings.show_hints), UserSettings.fov,
		UserSettings.mouse_sensitivity, str(UserSettings.invert_look_y), str(ok)])
	UserSettings.quality = int(prev ["quality"])
	UserSettings.autosave_index = int(prev ["autosave_index"])
	UserSettings.map_pause = bool(prev ["map_pause"])
	UserSettings.cold_start = bool(prev ["cold_start"])
	UserSettings.show_hints = bool(prev ["show_hints"])
	UserSettings.fov = float(prev ["fov"])
	UserSettings.mouse_sensitivity = float(prev ["mouse_sensitivity"])
	UserSettings.invert_look_y = bool(prev ["invert_look_y"])
	UserSettings.save_settings()
	get_tree().quit(0 if ok else 1)


func _run_seed_save() -> void:
	SaveManager.ensure_dir()
	var a := {
		"world": {"time_of_day": 9.6},
		"train": {"distance": 1500.0, "gear": 5, "gear_name": "D2", "speed": 0.0},
		"mission": {"index": 1, "score": 4280, "money": 4280, "completed": 2},
	}
	var b := {
		"world": {"time_of_day": 14.2},
		"train": {"distance": 3320.0, "gear": 7, "gear_name": "D4", "speed": 0.0},
		"mission": {"index": 4, "score": 8870, "money": 8870, "completed": 5},
	}
	var id1 := SaveManager.new_slot_id()
	SaveManager.write_save(id1, "山川—河谷 001", a)
	var id2 := SaveManager.new_slot_id()
	SaveManager.write_save(id2, "煤炭重载 002", b)
	SaveManager.set_last_slot(id1)
	print("[seed-save] %s %s" %[id1, id2])
	get_tree().quit()


func _run_gear_test() -> void:
	_pending_slot = ""
	_pending_state = {}
	_pending_name = "QA Gear"
	_start_game()
	await get_tree().process_frame
	await get_tree().process_frame
	game.train.doors_open = false
	var up: Array [String] = [game.train.gear_name()]
	for i in range(8):
		game._shift_gear(1)
		up.append(game.train.gear_name())
	var down: Array [String] = [game.train.gear_name()]
	for i in range(8):
		game._shift_gear(-1)
		down.append(game.train.gear_name())
	game.train.set_gear(Train.GEAR_D5)
	game._space_action()
	var space_ok := game.train.gear == Train.GEAR_N
	var up_expect: Array [String] = ["P3", "P2", "P1", "N", "D1", "D2", "D3", "D4", "D5"]
	var down_expect: Array [String] = ["D5", "D4", "D3", "D2", "D1", "N", "P1", "P2", "P3"]
	var up_ok := up == up_expect
	var down_ok := down == down_expect
	print("[gear-test] up=%s" % " → ".join(up))
	print("[gear-test] down=%s" % " → ".join(down))
	print("[gear-test] space@D5→%s up_ok=%s down_ok=%s space_ok=%s" %[
		game.train.gear_name(), str(up_ok), str(down_ok), str(space_ok)])
	get_tree().quit(0 if up_ok and down_ok and space_ok else 1)


func _run_mission_test() -> void:
	if game.mission == null:
		print("[mission-test] 任务系统未初始化（缺少车站或列车）")
		get_tree().quit()
		return
	game.mission.time_scale_debug = 60.0
	var start_completed := game.mission.completed
	print("[mission-test] 开始（装卸时间 ×60）已完成=%d 累计分=%d" %[start_completed, game.mission.score_total])
	var guard := 0
	while guard < 60 * 240:
		guard += 1
		await get_tree().process_frame
		var m := game.mission
		if m.phase != _test_phase:
			_test_phase = m.phase
			print("[mission-test] 阶段=%-14s 任务=%d 里程=%.1f 偏差=%+.2f 编组=%d辆/%.0ft 得分=%d" %[
				m.phase_name(), m.index + 1, game.train.distance, m.head_offset(),
				game.train.vehicles.size(), game.train.train_mass_tonnes(), m.score_total
			])
		if m.phase == MissionSystem.Phase.BRIEFING or m.phase == MissionSystem.Phase.RUNNING:
			game.train.distance = m.stop_mark()
			game.train.speed = 0.0
		if m.completed >= start_completed + 8:
			break
	print("[mission-test] 完成：新增任务 %d 个  总分 %d  资金 %d 元" %[
		game.mission.completed - start_completed, game.mission.score_total, game.mission.money
	])
	print("[mission-test] 最后一次结算=%s" %[game.mission.last_result])
	get_tree().quit()



func _capture_and_quit() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[shot] cam_pos=%s cam_look=%s cam_mode=%s orbit=%s qa_pos=%.1f dist=%.1f" %[cam_pos, cam_look, cam_mode, _orbit, _qa_train_pos, game.train.distance if game != null and game.train != null else -1.0])
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	if game != null:
		if _pending_time >= 0.0:
			game.time_of_day = _pending_time
			game._apply_time()
		if cam_mode != "" and game.rig != null:
			match cam_mode:
				"cab":
					game.rig.set_mode(CameraRig.Mode.CAB)
				"chase":
					game.rig.set_mode(CameraRig.Mode.CHASE)
				"free":
					game.rig.set_mode(CameraRig.Mode.FREE)
				"tower":
					game.rig.set_mode(CameraRig.Mode.TOWER)
				"walk":
					game.rig.set_mode(CameraRig.Mode.WALK)
		if cam_mode == "cab" and game.rig != null:
			game.rig._cab_look_yaw = _qa_cab_yaw
			game.rig._cab_look_pitch = _qa_cab_pitch
		if _qa_doors_open and game.train != null:
			game.train.handbrake = true
			game.train.doors_open = true
			game.train.door_anim = 1.0
			var qa_side := 0
			var qa_platform: Dictionary = game._platform_context()
			if not qa_platform.is_empty():
				qa_side = game._local_platform_side(qa_platform)
				game._mark_platform_doors(qa_platform)
			game.train.door_open_side = qa_side
			for qv in game.train.vehicles:
				qv.apply_doors(1.0, qa_side)
		if _orbit != Vector3.INF and game.rig != null:
			game.rig.set_orbit(_orbit.x, _orbit.y, _orbit.z)
		if _qa_bogie_cam and game.train != null and game.train.vehicles.size() > 1:
			var bv: Vehicle = game.train.vehicles[0]
			var bz := bv.bogie_spacing * 0.5
			var bc := Camera3D.new()
			bc.name = "BogieCamera"
			bc.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
			bc.fov = 45.0
			bc.near = 0.15
			bc.far = 40000.0
			add_child(bc)
			bc.global_position = bv.global_transform * Vector3(_qa_bogie_side * 7.0, 0.72, bz)
			bc.look_at(bv.global_transform * Vector3(0, 0.52, bz))
			bc.make_current()
		if _qa_part_cam != "" and game.train != null and not game.train.vehicles.is_empty():
			var pv: Vehicle = game.train.vehicles[0]
			var pc := Camera3D.new()
			pc.name = "PartCamera"
			pc.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
			pc.fov = 42.0
			pc.near = 0.05
			pc.far = 300.0
			add_child(pc)
			var origin := pv.global_transform
			if _qa_part_cam == "mirror":
				var target := origin * Vector3(2.06, 2.94, -8.5)
				pc.global_position = origin * Vector3(6.2, 4.0, -5.2)
				pc.look_at(target)
			elif _qa_part_cam == "bogie":
				var target := origin * Vector3(0.0, 0.62, -6.2)
				pc.global_position = origin * Vector3(7.2, 1.05, -6.2)
				pc.look_at(target)
			elif _qa_part_cam == "bogie3q":
				var bv3: Vehicle = game.train.vehicles[0]
				var bz3 := bv3.bogie_spacing * 0.5
				var target := bv3.global_transform * Vector3(0.0, 0.68, bz3)
				pc.global_position = bv3.global_transform * Vector3(6.4, 2.7, bz3 + 4.4)
				pc.look_at(target)
			elif _qa_part_cam == "bogie3qlow":
				var bv4: Vehicle = game.train.vehicles[0]
				var bz4 := bv4.bogie_spacing * 0.5
				var target := bv4.global_transform * Vector3(0.0, 0.55, bz4)
				pc.global_position = bv4.global_transform * Vector3(5.0, 1.15, bz4 + 3.4)
				pc.look_at(target)
			elif _qa_part_cam == "hxd1-hub":
				var hv: Vehicle = game.train.vehicles[0]
				var hz := - hv.bogie_spacing * 0.5 - 1.35
				var target := hv.global_transform * Vector3(0.72, 0.50, hz)
				pc.global_position = hv.global_transform * Vector3(3.8, 1.35, hz + 2.4)
				pc.look_at(target)
			elif _qa_part_cam == "wagonbogie":
				var wv: Vehicle = game.train.vehicles[1] if game.train.vehicles.size() > 1 else pv
				var wz := - wv.bogie_spacing * 0.5
				var target := wv.global_transform * Vector3(0.0, 0.55, wz)
				pc.global_position = wv.global_transform * Vector3(6.8, 1.35, wz + 1.8)
				pc.look_at(target)
			elif _qa_part_cam == "door":
				var target := origin * Vector3(-1.75, 2.45, -5.55)
				pc.global_position = origin * Vector3(-6.4, 2.9, -3.9)
				pc.look_at(target)
			elif _qa_part_cam == "loco-dash":
				pc.fov = 52.0
				var target := origin * Vector3(-0.55, 2.22, -8.88)
				pc.global_position = origin * Vector3(-0.55, 2.80, -7.80)
				pc.look_at(target)
			elif _qa_part_cam == "station-hall":
				if not game.station_data.is_empty():
					var st: Dictionary = game.station_data[0]
					var hf: Transform3D = game.route.frame_at(float(st["dist"]))
					var hs := signf(float(st.get("side", -1.0)))
					var target := hf.origin + hf.basis.x * (hs * 23.0) + hf.basis.z * (-4.0) + Vector3.UP * 2.4
					pc.global_position = hf.origin + hf.basis.x * (hs * 12.4) + hf.basis.z * 8.0 + Vector3.UP * 2.8
					pc.look_at(target)
			elif _qa_part_cam == "city-viaduct":
				pc.far = 2200.0
				var vd: float = game.route.total * 0.44
				var vf: Transform3D = game.route.frame_at(vd)
				var target := vf.origin + Vector3.UP * 10.0
				pc.global_position = vf.origin + vf.basis.x * 820.0 + vf.basis.z * (-300.0) + Vector3.UP * 135.0
				pc.look_at(target)
			elif _qa_part_cam == "wagonbogieclose":
				var wv: Vehicle = game.train.vehicles[1] if game.train.vehicles.size() > 1 else pv
				var wz := - wv.bogie_spacing * 0.5
				var target := wv.global_transform * Vector3(0.0, 0.55, wz)
				pc.global_position = wv.global_transform * Vector3(4.2, 0.92, wz + 2.0)
				pc.look_at(target)
			elif _qa_part_cam == "wagon-side":
				var wv: Vehicle = game.train.vehicles[1] if game.train.vehicles.size() > 1 else pv
				var target := wv.global_transform * Vector3(0.0, 1.35, 0.0)
				pc.global_position = wv.global_transform * Vector3(13.5, 2.2, 0.0)
				pc.look_at(target)
			elif _qa_part_cam == "wagon-under":
				var wv: Vehicle = game.train.vehicles[1] if game.train.vehicles.size() > 1 else pv
				var target := wv.global_transform * Vector3(0.0, 0.55, -wv.bogie_spacing * 0.5)
				pc.global_position = wv.global_transform * Vector3(6.2, 0.55, -wv.bogie_spacing * 0.5 + 2.4)
				pc.look_at(target)
			elif _qa_part_cam == "coach-side":
				var cv: Vehicle = game.train.vehicles[1] if game.train.vehicles.size() > 1 else pv
				var target := cv.global_transform * Vector3(0.0, 2.6, 0.0)
				pc.global_position = cv.global_transform * Vector3(24.0, 4.8, 0.0)
				pc.look_at(target)
			elif _qa_part_cam == "coach-top":
				var cv: Vehicle = game.train.vehicles[1] if game.train.vehicles.size() > 1 else pv
				var target := cv.global_transform * Vector3(0.0, 3.8, 0.0)
				pc.global_position = cv.global_transform * Vector3(0.0, 38.0, 6.0)
				pc.look_at(target)
			elif _qa_part_cam == "coach-side-left":
				var cv: Vehicle = game.train.vehicles[1] if game.train.vehicles.size() > 1 else pv
				var target := cv.global_transform * Vector3(0.0, 2.6, 0.0)
				pc.global_position = cv.global_transform * Vector3(-24.0, 4.8, 0.0)
				pc.look_at(target)
			elif _qa_part_cam == "coach-side-close":
				var cv: Vehicle = game.train.vehicles[1] if game.train.vehicles.size() > 1 else pv
				var target := cv.global_transform * Vector3(0.0, 2.25, 0.0)
				pc.global_position = cv.global_transform * Vector3(5.4, 2.55, 0.0)
				pc.look_at(target)
				if OS.get_cmdline_user_args().has("--hide-band"):
					for nb: Node in game.train.find_children("WindowBand*", "MeshInstance3D", true, false):
						(nb as MeshInstance3D).visible = false
				if OS.get_cmdline_user_args().has("--hide-interior"):
					for nb: Node in game.train.find_children("Interior*", "MeshInstance3D", true, false):
						(nb as MeshInstance3D).visible = false
				if OS.get_cmdline_user_args().has("--hide-glass"):
					for nb: Node in game.train.find_children("WindowGlass*", "MeshInstance3D", true, false):
						(nb as MeshInstance3D).visible = false
				for probe_px: Vector2 in [Vector2(930, 300), Vector2(960, 300), Vector2(990, 300)]:
					var eye := pc.project_ray_origin(probe_px)
					var dir := pc.project_ray_normal(probe_px)
					var hits: Array = []
					for n: Node in game.train.find_children("*", "MeshInstance3D", true, false):
						var mi := n as MeshInstance3D
						if mi == null or not mi.is_visible_in_tree():
							continue
						var inv := mi.global_transform.affine_inverse()
						var hit: Variant = mi.get_aabb().intersects_ray(inv * eye, (inv.basis * dir).normalized())
						if hit != null:
							var wp := mi.global_transform * (hit as Vector3)
							var mat := ""
							if mi.material_override is StandardMaterial3D:
								mat = str((mi.material_override as StandardMaterial3D).albedo_color)
							hits.append([String(mi.name), eye.distance_to(wp), wp, mat])
					hits.sort_custom(func(a, b): return float(a[1]) < float(b[1]))
					for i in range(mini(8, hits.size())):
						print("[coach-side] px=%s hit %s %.2f at %s %s" % [str(probe_px), hits[i][0], float(hits[i][1]), str(hits[i][2]), hits[i][3]])
			elif _qa_part_cam == "coach-door-close":
				var cv: Vehicle = game.train.vehicles[1] if game.train.vehicles.size() > 1 else pv
				var target := cv.global_transform * Vector3(0.0, 2.15, 10.45)
				pc.global_position = cv.global_transform * Vector3(4.6, 2.45, 9.2)
				pc.look_at(target)
			elif _qa_part_cam == "coach-door-in-left":
				var cv: Vehicle = game.train.vehicles[1] if game.train.vehicles.size() > 1 else pv
				var target := cv.global_transform * Vector3(-2.0, 2.82, 10.45)
				pc.global_position = cv.global_transform * Vector3(0.2, 2.82, 10.45)
				pc.look_at(target)
			elif _qa_part_cam == "coach-door-in-right":
				var cv: Vehicle = game.train.vehicles[1] if game.train.vehicles.size() > 1 else pv
				var target := cv.global_transform * Vector3(2.0, 2.82, 10.45)
				pc.global_position = cv.global_transform * Vector3(-0.2, 2.82, 10.45)
				pc.look_at(target)
			elif _qa_part_cam == "coach-inside":
				var cv: Vehicle = game.train.vehicles[1] if game.train.vehicles.size() > 1 else pv
				var target := cv.global_transform * Vector3(0.0, 1.95, -5.5)
				pc.global_position = cv.global_transform * Vector3(0.0, 2.42, 9.6)
				pc.look_at(target)
			elif _qa_part_cam == "coach-to-loco":
				var cv: Vehicle = game.train.vehicles[1] if game.train.vehicles.size() > 1 else pv
				var target := cv.global_transform * Vector3(0.0, 2.0, -14.0)
				pc.global_position = cv.global_transform * Vector3(0.0, 2.2, -9.2)
				pc.look_at(target)
			elif _qa_part_cam == "coach-window":
				var cv: Vehicle = game.train.vehicles[1] if game.train.vehicles.size() > 1 else pv
				var target := cv.global_transform * Vector3(-1.55, 2.95, 2.2)
				pc.global_position = cv.global_transform * Vector3(0.55, 2.05, -1.2)
				pc.look_at(target)
			elif _qa_part_cam == "coach-floor":
				var cv: Vehicle = game.train.vehicles[1] if game.train.vehicles.size() > 1 else pv
				var target := cv.global_transform * Vector3(0.0, 1.22, 2.0)
				pc.global_position = cv.global_transform * Vector3(0.0, 2.15, 7.5)
				pc.look_at(target)
			elif _qa_part_cam == "coach-sidewall":
				var cv: Vehicle = game.train.vehicles[1] if game.train.vehicles.size() > 1 else pv
				var target := cv.global_transform * Vector3(-1.45, 2.05, 2.0)
				pc.global_position = cv.global_transform * Vector3(0.65, 2.25, 2.0)
				pc.look_at(target)
			elif _qa_part_cam == "baggage-inside":
				var bv: Vehicle = pv
				for qv: Vehicle in game.train.vehicles:
					if qv != null and qv.kind == "baggage":
						bv = qv
						break
				var target := bv.global_transform * Vector3(0.0, 1.9, -5.0)
				pc.global_position = bv.global_transform * Vector3(0.0, 2.5, 9.5)
				pc.look_at(target)
			elif _qa_part_cam == "coach-connection":
				var cv: Vehicle = game.train.vehicles[2] if game.train.vehicles.size() > 2 else pv
				var target := cv.global_transform * Vector3(0.0, 2.35, 12.0)
				pc.global_position = cv.global_transform * Vector3(4.4, 3.0, 14.2)
				pc.look_at(target)
			elif _qa_part_cam == "loco-corridor":
				var lv: Vehicle = game.train.vehicles[0]
				var target := lv.global_transform * Vector3(0.78, 1.95, -3.4)
				pc.global_position = lv.global_transform * Vector3(0.78, 2.25, 5.6)
				pc.look_at(target)
			elif _qa_part_cam == "loco-floor":
				var lv: Vehicle = game.train.vehicles[0]
				var target := lv.global_transform * Vector3(0.60, 1.20, 1.5)
				pc.global_position = lv.global_transform * Vector3(0.60, 2.65, 8.2)
				pc.look_at(target)
			elif _qa_part_cam == "loco-threshold":
				var lv: Vehicle = game.train.vehicles[0]
				var target := lv.global_transform * Vector3(0.75, 1.20, 6.5)
				pc.global_position = lv.global_transform * Vector3(0.75, 3.25, 9.2)
				pc.look_at(target)
			elif _qa_part_cam == "loco-rear-in":
				var lv: Vehicle = game.train.vehicles[0]
				var target := lv.global_transform * Vector3(0.0, 2.05, 9.5)
				pc.global_position = lv.global_transform * Vector3(0.0, 2.45, 4.0)
				pc.look_at(target)
			elif _qa_part_cam == "loco-rear-close":
				var lv: Vehicle = game.train.vehicles[0]
				var target := lv.global_transform * Vector3(0.0, 2.25, 9.55)
				pc.global_position = lv.global_transform * Vector3(4.6, 3.0, 13.8)
				pc.look_at(target)
			elif _qa_part_cam == "skirt-front":
				var target := origin * Vector3(1.55, 0.85, -9.2)
				pc.global_position = origin * Vector3(3.8, 1.15, -13.2)
				pc.look_at(target)
			elif _qa_part_cam == "loco-side":
				var lv: Vehicle = game.train.vehicles[0]
				var target := lv.global_transform * Vector3(0.0, 2.15, -3.4)
				pc.global_position = lv.global_transform * Vector3(9.2, 3.0, -0.6)
				pc.look_at(target)
			elif _qa_part_cam == "loco-rear":
				var lr: Vehicle = game.train.vehicles[0]
				var target := lr.global_transform * Vector3(0.0, 2.55, 10.0)
				pc.global_position = lr.global_transform * Vector3(7.4, 4.3, 15.2)
				pc.look_at(target)
			elif _qa_part_cam == "cabside":
				var target := origin * Vector3(1.55, 2.85, -6.6)
				pc.global_position = origin * Vector3(6.4, 3.3, -6.6)
				pc.look_at(target)
			elif _qa_part_cam == "nose":
				var target := origin * Vector3(0.0, 2.7, -9.6)
				pc.global_position = origin * Vector3(3.6, 3.4, -17.0)
				pc.look_at(target)
			elif _qa_part_cam == "front-corner":
				var target := origin * Vector3(-1.45, 1.9, -7.6)
				pc.global_position = origin * Vector3(-4.8, 2.4, -10.6)
				pc.look_at(target)
			elif _qa_part_cam == "mirrorcab":
				var target := origin * Vector3(-2.05, 2.95, -7.5)
				pc.global_position = origin * Vector3(-0.55, 2.95, -6.5)
				pc.look_at(target)
			elif _qa_part_cam == "mirrorface":
				var target := origin * Vector3(-1.99, 2.95, -7.5)
				pc.global_position = origin * Vector3(-1.85, 3.0, -5.4)
				pc.look_at(target)
			else:
				var target := origin * Vector3(0.0, 0.92, -pv.length * 0.5 - 0.3)
				pc.global_position = origin * Vector3(4.8, 2.1, -pv.length * 0.5 - 3.6)
				pc.look_at(target)
			pc.make_current()
		if cam_mode == "walk" and cam_pos != Vector3.INF and game.rig != null:
			game.rig.place_walk(cam_pos)
			if cam_look != Vector3.INF:
				game.rig.look_toward(cam_look)
		elif cam_pos != Vector3.INF:
			var cam := Camera3D.new()
			cam.name = "ShotCamera"
			cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
			cam.fov = 62.0
			cam.near = 0.5
			cam.far = 40000.0
			add_child(cam)
			cam.global_position = cam_pos
			cam.look_at(cam_look if cam_look != Vector3.INF else Vector3.ZERO)
			cam.make_current()
	if get_tree().paused:
		get_tree().paused = false
		if game != null:
			game.paused = false
	if _force_pause and game != null and game.pause_menu != null:
		game.pause_menu.open()
	var t0 := Time.get_ticks_usec()
	for i in range(shot_frames):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(shot_path)
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0 / float(shot_frames)
	var stat := get_tree().root.get_node_or_null("Main/Game")
	print("[shot] %s err=%d size=%dx%d" %[shot_path, err, img.get_width(), img.get_height()])
	print("[perf] frames=%d avg=%.2f ms (%.1f fps) | fps_counter=%.1f" %[
		shot_frames, ms, 1000.0 / maxf(ms, 0.001), Engine.get_frames_per_second()
	])
	print("[perf] draw_calls=%d objects=%d primitives=%d" %[
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
	])
	if game != null and game.stats.size() > 0:
		print("[perf] world_stats=%s" %[game.stats])
	if probe_pos != Vector3.INF:
		_probe(probe_pos)
	get_tree().quit()


func _probe(p: Vector3) -> void:
	print("[probe] at %s" %p)
	var stack: Array [Node] = [game]
	var found := 0
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf := mi.global_transform
		var aabb := xf * mi.mesh.get_aabb()
		var top := aabb.position.y + aabb.size.y
		var inside_xz := p.x >= aabb.position.x - 1.0 and p.x <= aabb.position.x + aabb.size.x + 1.0 and p.z >= aabb.position.z - 1.0 and p.z <= aabb.position.z + aabb.size.z + 1.0

		if inside_xz and top > p.y - 1.0:
			var path := str(mi.get_path())
			print("  [hit] %s  size=(%.1f, %.1f, %.1f)  top=%.1f  y0=%.1f" %[
				path, aabb.size.x, aabb.size.y, aabb.size.z, top, aabb.position.y
			])
			found += 1
	print("[probe] hits=%d" %found)
