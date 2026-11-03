extends RefCounted
class_name UserSettings


const PATH := "user://settings.cfg"

const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

const AUTOSAVE_MINUTES := [10, 5, 3, 1]
const TIME_FLOW_MINUTES := [0.0, 45.0, 20.0, 7.0]

static var quality: int = Config.Quality.HIGH
static var window_mode: int = 0
static var resolution: int = 1
static var vsync: bool = true
static var upscaler: int = Upscaling.Mode.OFF
static var master_volume: float = 0.85

static var autosave_index: int = 1
static var map_pause: bool = true
static var cold_start: bool = false
static var show_hints: bool = true
static var fov: float = 62.0
static var mouse_sensitivity: float = 1.0
static var invert_look_y: bool = false
static var time_flow: int = 2

static func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	quality = int(cfg.get_value("video", "quality", quality))
	window_mode = int(cfg.get_value("video", "window_mode", window_mode))
	resolution = int(cfg.get_value("video", "resolution", resolution))
	vsync = bool(cfg.get_value("video", "vsync", vsync))
	upscaler = int(cfg.get_value("video", "upscaler", upscaler))
	fov = float(cfg.get_value("video", "fov", fov))
	master_volume = float(cfg.get_value("audio", "master", master_volume))
	autosave_index = int(cfg.get_value("game", "autosave_index", autosave_index))
	map_pause = bool(cfg.get_value("game", "map_pause", map_pause))
	cold_start = bool(cfg.get_value("game", "cold_start", cold_start))
	show_hints = bool(cfg.get_value("game", "show_hints", show_hints))
	mouse_sensitivity = float(cfg.get_value("controls", "mouse_sensitivity", mouse_sensitivity))
	invert_look_y = bool(cfg.get_value("controls", "invert_look_y", invert_look_y))
	time_flow = int(cfg.get_value("game", "time_flow", time_flow))
	_sanitize()

static func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "quality", quality)
	cfg.set_value("video", "window_mode", window_mode)
	cfg.set_value("video", "resolution", resolution)
	cfg.set_value("video", "vsync", vsync)
	cfg.set_value("video", "upscaler", upscaler)
	cfg.set_value("video", "fov", fov)
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("game", "autosave_index", autosave_index)
	cfg.set_value("game", "map_pause", map_pause)
	cfg.set_value("game", "cold_start", cold_start)
	cfg.set_value("game", "show_hints", show_hints)
	cfg.set_value("game", "time_flow", time_flow)
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("controls", "invert_look_y", invert_look_y)
	cfg.save(PATH)

static func reset_defaults() -> void:
	quality = Config.Quality.HIGH
	window_mode = 0
	resolution = 1
	vsync = true
	upscaler = Upscaling.Mode.OFF
	master_volume = 0.85
	autosave_index = 1
	map_pause = true
	cold_start = false
	show_hints = true
	fov = 62.0
	mouse_sensitivity = 1.0
	invert_look_y = false
	time_flow = 2

static func _sanitize() -> void:
	quality = clampi(quality, 0, int(Config.Quality.ULTRA))
	window_mode = clampi(window_mode, 0, 2)
	resolution = clampi(resolution, 0, RESOLUTIONS.size() - 1)
	upscaler = clampi(upscaler, Upscaling.Mode.OFF, Upscaling.Mode.DLAA)
	master_volume = clampf(master_volume, 0.0, 1.0)
	autosave_index = clampi(autosave_index, 0, AUTOSAVE_MINUTES.size() - 1)
	fov = clampf(fov, 45.0, 100.0)
	time_flow = clampi(time_flow, 0, TIME_FLOW_MINUTES.size() - 1)
	mouse_sensitivity = clampf(mouse_sensitivity, 0.3, 2.5)

static func autosave_minutes() -> int:
	return int(AUTOSAVE_MINUTES[clampi(autosave_index, 0, AUTOSAVE_MINUTES.size() - 1)])

static func apply_all() -> void:
	Config.quality = quality
	apply_video()
	apply_audio()

static func apply_video() -> void:
	if DisplayServer.get_name() == "headless":
		return
	apply_vsync()
	match window_mode:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var res: Vector2i = RESOLUTIONS[resolution]
			DisplayServer.window_set_size(res)
			var screen := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
			DisplayServer.window_set_position(Vector2i((screen.x - res.x) / 2, (screen.y - res.y) / 2))
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	Upscaling.apply_to_root(upscaler)

static func apply_vsync() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)

static func apply_audio() -> void:
	var idx := AudioServer.get_bus_index("Master")
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, master_volume <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(master_volume, 0.0001, 1.0)))
