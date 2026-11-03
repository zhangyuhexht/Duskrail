extends CanvasLayer
class_name TuningPanel

const Brand = preload("res://src/core/brand.gd")

signal closed

const TEXT_MAIN := Color(0.957, 0.965, 0.976)
const TEXT_DIM := Color(0.620, 0.640, 0.680)
const TEXT_MUTED := Color(0.430, 0.450, 0.490)
const ACCENT := Color(0.204, 0.510, 1.0)
const CARD_BG := Color(0.095, 0.100, 0.112, 0.96)
const CARD_HOVER := Color(0.125, 0.132, 0.146, 0.98)
const PRESET_PATH := "user://tuning_presets.cfg"
const PRESET_COUNT := 3

var game
var _category := "parts"
var _engine_sel := "standard"
var _skin_sel := "classic"
var _transmission_sel := "balanced"
var _part_sel: Array[String] = []
var _message := ""

var _category_buttons := {}
var _preset_buttons: Array[Button] = []
var _preset_slot := 1
var _status: Label
var _left_title: Label
var _options: VBoxContainer
var _options_scroll: ScrollContainer

var _preview_viewport: SubViewport
var _preview_root: Node3D
var _preview_loco: Node3D
var _preview_camera: Camera3D
var _preview_container: SubViewportContainer
var _preview_yaw := 0.55
var _preview_pitch := 0.26
var _preview_zoom := 1.0
var _preview_dragging := false
var _preview_walk := false
var _walk_pos := Vector3(7.2, 1.72, 8.5)
var _walk_yaw := 0.0
var _walk_pitch := -0.05
var _walk_vel := Vector2.ZERO
var _walk_button: Button
var _preview_hint: Label
var _preview_info_title: Label
var _preview_info_sub: Label

func _ready() -> void:
	layer = 34
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.76)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _surface(Color(0.050, 0.054, 0.064, 0.995), Color(0, 0, 0, 0), 0, 18, 14))
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)

	var title_col := VBoxContainer.new()
	title_col.add_theme_constant_override("separation", 2)
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_col)

	var overline := Label.new()
	overline.text = "%s  /  车辆服务" %Brand.NAME_EN
	overline.add_theme_font_override("font", Brand.cjk_font())
	overline.add_theme_font_size_override("font_size", 10)
	overline.add_theme_color_override("font_color", Color(0.52, 0.64, 0.86))
	title_col.add_child(overline)

	var title := Label.new()
	title.text = "改装车间"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", TEXT_MAIN)
	title_col.add_child(title)

	var close := Button.new()
	close.text = "关闭"
	close.custom_minimum_size = Vector2(100, 46)
	close.add_theme_font_size_override("font_size", 16)
	close.focus_mode = Control.FOCUS_ALL
	close.pressed.connect(_close)
	_style_button(close, false)
	header.add_child(close)

	var categories := HBoxContainer.new()
	categories.add_theme_constant_override("separation", 8)
	root.add_child(categories)
	for item: Array in [["parts", "改装配件"], ["look", "外观涂装"]]:
		var b := Button.new()
		b.text = String(item[1])
		b.custom_minimum_size = Vector2(142, 38)
		b.add_theme_font_size_override("font_size", 15)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(func() -> void: _set_category(String(item[0])))
		_style_category(b)
		categories.add_child(b)
		_category_buttons [String(item[0])] = b

	root.add_child(_divider())

	var body := Control.new()
	body.custom_minimum_size = Vector2(0, 540)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var left := PanelContainer.new()
	left.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	left.offset_left = 18
	left.offset_top = 38
	left.offset_right = 418
	left.offset_bottom = -14
	left.z_index = 3
	var left_style := _surface(Color(0.045, 0.050, 0.060, 0.72), Color(0, 0, 0, 0), 24, 18, 16)
	left_style.shadow_color = Color(0, 0, 0, 0.42)
	left_style.shadow_size = 22
	left_style.shadow_offset = Vector2(0, 10)
	left.add_theme_stylebox_override("panel", left_style)
	body.add_child(left)

	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 10)
	left.add_child(left_box)

	_left_title = Label.new()
	_left_title.text = "改装配件"
	_left_title.add_theme_font_size_override("font_size", 17)
	_left_title.add_theme_color_override("font_color", Color(0.86, 0.90, 0.96))
	left_box.add_child(_left_title)

	_options_scroll = ScrollContainer.new()
	_options_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_options_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_options_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_options_scroll.follow_focus = true
	_options_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	left_box.add_child(_options_scroll)

	_options = VBoxContainer.new()
	_options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_options.add_theme_constant_override("separation", 7)
	_options_scroll.add_child(_options)

	var right := PanelContainer.new()
	right.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	right.add_theme_stylebox_override("panel", _surface(Color(0.060, 0.065, 0.076, 0.98), Color(0, 0, 0, 0), 22, 10, 10))
	body.add_child(right)
	# Keep the floating rail above the full-rect preview in both drawing and input order.
	body.move_child(left, -1)

	var right_box := VBoxContainer.new()
	right_box.add_theme_constant_override("separation", 6)
	right.add_child(right_box)

	var preview_head := HBoxContainer.new()
	preview_head.add_theme_constant_override("separation", 10)
	right_box.add_child(preview_head)
	var bay_label := Label.new()
	bay_label.text = "DUSKRAIL 检修车间  /  3D 预览"
	bay_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bay_label.add_theme_font_override("font", Brand.cjk_font())
	bay_label.add_theme_font_size_override("font_size", 10)
	bay_label.add_theme_color_override("font_color", Color(0.53, 0.64, 0.82))
	preview_head.add_child(bay_label)
	_preview_hint = Label.new()
	_preview_hint.text = "右键拖动旋转 · 滚轮缩放"
	_preview_hint.add_theme_font_size_override("font_size", 10)
	_preview_hint.add_theme_color_override("font_color", TEXT_MUTED)
	preview_head.add_child(_preview_hint)
	_walk_button = Button.new()
	_walk_button.text = "行走模式"
	_walk_button.custom_minimum_size = Vector2(74, 24)
	_walk_button.add_theme_font_size_override("font_size", 10)
	_walk_button.focus_mode = Control.FOCUS_NONE
	_walk_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_walk_button.tooltip_text = "进入车间行走模式：WASD 移动，Shift 加速，鼠标环视。"
	_walk_button.pressed.connect(_toggle_preview_walk)
	_style_preview_button(_walk_button)
	preview_head.add_child(_walk_button)
	var reset_view := Button.new()
	reset_view.text = "复位"
	reset_view.custom_minimum_size = Vector2(46, 24)
	reset_view.add_theme_font_size_override("font_size", 10)
	reset_view.focus_mode = Control.FOCUS_NONE
	reset_view.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	reset_view.pressed.connect(_reset_preview_view)
	_style_preview_button(reset_view)
	preview_head.add_child(reset_view)

	_preview_viewport = SubViewport.new()
	_preview_viewport.size = Vector2i(1440, 810)
	_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_preview_viewport.msaa_3d = Viewport.MSAA_4X
	_preview_viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	_preview_viewport.scaling_3d_scale = 1.3
	_preview_container = SubViewportContainer.new()
	_preview_container.custom_minimum_size = Vector2(800, 520)
	_preview_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview_container.stretch = false
	_preview_container.stretch_shrink = 1
	_preview_container.mouse_filter = Control.MOUSE_FILTER_STOP
	_preview_container.mouse_default_cursor_shape = Control.CURSOR_MOVE
	_preview_container.tooltip_text = "右键拖动旋转 · 滚轮缩放"
	_preview_container.resized.connect(_sync_preview_viewport)
	_preview_container.add_child(_preview_viewport)
	right_box.add_child(_preview_container)

	_build_preview_room()
	_build_preview_info(body)
	_build_presets(root)
	_build_footer(root)

func _build_preview_info(parent: Control) -> void:
	var card := PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	card.offset_left = 438
	card.offset_top = -96
	card.offset_right = 1132
	card.offset_bottom = -20
	card.z_index = 1
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var info_style := _surface(Color(0.035, 0.040, 0.050, 0.72), Color(0, 0, 0, 0), 16, 16, 10)
	info_style.shadow_color = Color(0, 0, 0, 0.30)
	info_style.shadow_size = 14
	info_style.shadow_offset = Vector2(0, 6)
	card.add_theme_stylebox_override("panel", info_style)
	parent.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	_preview_info_title = Label.new()
	_preview_info_title.add_theme_font_size_override("font_size", 17)
	_preview_info_title.add_theme_color_override("font_color", TEXT_MAIN)
	box.add_child(_preview_info_title)
	_preview_info_sub = Label.new()
	_preview_info_sub.add_theme_font_size_override("font_size", 11)
	_preview_info_sub.add_theme_color_override("font_color", TEXT_DIM)
	box.add_child(_preview_info_sub)

func _style_preview_button(b: Button) -> void:
	b.add_theme_stylebox_override("normal", _surface(Color(1, 1, 1, 0.05), Color(0, 0, 0, 0), 8, 10, 3))
	b.add_theme_stylebox_override("hover", _surface(Color(1, 1, 1, 0.10), Color(0, 0, 0, 0), 8, 10, 3))
	b.add_theme_stylebox_override("pressed", _surface(Color(1, 1, 1, 0.14), Color(0, 0, 0, 0), 8, 10, 3))
	b.add_theme_color_override("font_color", Color(0.80, 0.86, 0.94))
	b.add_theme_color_override("font_hover_color", Color.WHITE)

func _reset_preview_view() -> void:
	_preview_yaw = 0.55
	_preview_pitch = 0.26
	_preview_zoom = 1.0
	_preview_dragging = false
	if _preview_walk:
		_toggle_preview_walk()
	else:
		_update_preview_camera()

func _refresh_preview_info() -> void:
	if _preview_info_title == null or _preview_info_sub == null:
		return
	var engine_name := String(Vehicles.engine_info(_engine_sel)["name"])
	engine_name = engine_name.replace("HXD1H ", "").replace("HXD1G ", "").replace("HXD1 ", "")
	_preview_info_title.text = "HXD1  ·  %s" %engine_name
	_preview_info_sub.text = "%s  ·  %s  ·  已加装 %d 项" %[
		String(Vehicles.transmission_info(_transmission_sel)["name"]),
		String(Vehicles.skin_info(_skin_sel)["name"]),
		_part_sel.size(),
	]

func _build_presets(parent: VBoxContainer) -> void:
	parent.add_child(_divider())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var label := Label.new()
	label.text = "配置预设"
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", TEXT_MUTED)
	row.add_child(label)
	for i in range(PRESET_COUNT):
		var b := Button.new()
		b.text = str(i + 1)
		b.custom_minimum_size = Vector2(36, 32)
		b.add_theme_font_size_override("font_size", 13)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(func() -> void:
			_preset_slot = i + 1
			_refresh_preset_buttons())
		_style_button(b, false)
		row.add_child(b)
		_preset_buttons.append(b)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var save := Button.new()
	save.text = "保存预设"
	save.custom_minimum_size = Vector2(104, 32)
	save.add_theme_font_size_override("font_size", 12)
	save.pressed.connect(_save_preset)
	_style_button(save, false)
	row.add_child(save)
	var load := Button.new()
	load.text = "载入预设"
	load.custom_minimum_size = Vector2(104, 32)
	load.add_theme_font_size_override("font_size", 12)
	load.pressed.connect(_load_preset)
	_style_button(load, false)
	row.add_child(load)

func _build_footer(parent: VBoxContainer) -> void:
	parent.add_child(_divider())
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	parent.add_child(footer)
	_status = Label.new()
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 12)
	_status.add_theme_color_override("font_color", TEXT_MUTED)
	footer.add_child(_status)
	var apply := Button.new()
	apply.text = "应用改装"
	apply.custom_minimum_size = Vector2(170, 48)
	apply.add_theme_font_size_override("font_size", 16)
	apply.focus_mode = Control.FOCUS_ALL
	apply.pressed.connect(_apply)
	_style_button(apply, true)
	footer.add_child(apply)

func _build_preview_room() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.038, 0.045)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.64, 0.68)
	env.ambient_light_energy = 1.34
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_preview_viewport.add_child(world_env)

	_preview_root = Node3D.new()
	_preview_root.name = "Garage"
	_preview_viewport.add_child(_preview_root)

	var floor_mat := _room_mat(Color(0.26, 0.27, 0.28), 0.9, 0.05)
	var wall_mat := _room_mat(Color(0.32, 0.34, 0.37), 0.82, 0.08)
	var dark_mat := _room_mat(Color(0.10, 0.11, 0.12), 0.72, 0.2)
	var steel_mat := _room_mat(Color(0.34, 0.36, 0.39), 0.5, 0.7)
	var stripe_mat := _room_mat(Color(0.20, 0.46, 0.86), 0.55, 0.2)

	var floor_mesh := _room_box(Vector3(76.0, 0.22, 46.0), floor_mat, Vector3(0.0, -0.11, 0.0), _preview_root)
	floor_mesh.name = "GarageFloor"
	_room_box(Vector3(76.0, 14.0, 0.3), wall_mat, Vector3(0.0, 7.0, 23.0), _preview_root).name = "BackWall"
	_room_box(Vector3(0.3, 14.0, 46.0), wall_mat, Vector3(-38.0, 7.0, 0.0), _preview_root).name = "LeftWall"
	_room_box(Vector3(0.3, 14.0, 46.0), wall_mat, Vector3(38.0, 7.0, 0.0), _preview_root).name = "RightWall"
	_room_box(Vector3(76.0, 0.3, 46.0), dark_mat, Vector3(0.0, 14.0, 0.0), _preview_root).name = "Ceiling"
	_room_box(Vector3(76.0, 1.4, 0.14), stripe_mat, Vector3(0.0, 1.1, 22.8), _preview_root)
	_room_box(Vector3(26.0, 9.5, 0.16), _room_mat(Color(0.15, 0.20, 0.27), 0.72, 0.3),
			Vector3(0.0, 4.75, 22.78), _preview_root).name = "RollerDoor"
	for side: float in [-1.0, 1.0]:
		_room_box(Vector3(0.86, 0.05, 43.0), steel_mat, Vector3(side * 0.72, 0.035, 0.0), _preview_root)
		for cz: float in [-20.0, -10.0, 0.0, 10.0, 20.0]:
			_room_box(Vector3(0.7, 14.0, 0.7), dark_mat,
					Vector3(side * 37.3, 7.0, cz), _preview_root).name = "Column"
			_room_box(Vector3(0.18, 3.0, 3.4), Gfx.emissive(Color(0.62, 0.78, 1.0), 0.26,
					Color(0.06, 0.10, 0.16)), Vector3(side * 37.78, 8.3, cz), _preview_root)
			_room_box(Vector3(0.24, 0.18, 3.7), steel_mat,
					Vector3(side * 37.72, 9.9, cz), _preview_root)
			_room_box(Vector3(0.24, 0.18, 3.7), steel_mat,
					Vector3(side * 37.72, 6.7, cz), _preview_root)
	for x: float in [-2.9, 2.9]:
		_room_box(Vector3(0.08, 0.025, 41.0), _room_mat(Color(0.74, 0.58, 0.16), 0.75, 0.05),
				Vector3(x, 0.02, 0.0), _preview_root)
	_room_box(Vector3(0.55, 0.80, 0.55), dark_mat, Vector3(-16.0, 0.4, -12.0), _preview_root)
	_room_box(Vector3(0.55, 0.80, 0.55), dark_mat, Vector3(16.0, 0.4, -12.0), _preview_root)

	var crane_mat := _room_mat(Color(0.76, 0.57, 0.10), 0.62, 0.25)
	_room_box(Vector3(72.0, 0.85, 0.85), crane_mat, Vector3(0.0, 12.6, 3.0), _preview_root).name = "CraneBeam"
	_room_box(Vector3(2.6, 1.1, 2.0), dark_mat, Vector3(-22.0, 12.0, 3.0), _preview_root).name = "CraneTrolley"
	_room_box(Vector3(0.12, 3.4, 0.12), steel_mat, Vector3(-22.0, 10.1, 3.0), _preview_root)
	_room_box(Vector3(0.8, 0.5, 0.5), steel_mat, Vector3(-22.0, 8.2, 3.0), _preview_root)

	var sign_label := Label3D.new()
	sign_label.text = "DUSKRAIL  ·  检修车间"
	sign_label.font = Brand.cjk_font()
	sign_label.font_size = 54
	sign_label.pixel_size = 0.012
	sign_label.modulate = Color(0.70, 0.80, 0.94)
	sign_label.outline_size = 10
	sign_label.outline_modulate = Color(0.02, 0.03, 0.05)
	sign_label.position = Vector3(-13.0, 10.6, 22.72)
	sign_label.rotation_degrees = Vector3(0, 180, 0)
	_preview_root.add_child(sign_label)

	for item: Array in [[-27.0, "LOCKER"], [-22.0, "LOCKER"], [26.0, "BENCH"]]:
		var x := float(item[0])
		var cabinet := _room_box(Vector3(3.2, 4.0, 1.6), dark_mat, Vector3(x, 2.0, 22.0), _preview_root)
		cabinet.name = String(item[1])
		_room_box(Vector3(2.9, 0.08, 1.45), steel_mat, Vector3(x, 3.0, 21.2), _preview_root)
	_room_box(Vector3(11.0, 1.1, 2.2), steel_mat, Vector3(22.0, 1.1, 21.8), _preview_root)
	_room_box(Vector3(1.6, 1.1, 12.0), steel_mat, Vector3(-31.0, 1.1, 0.0), _preview_root)

	for item: Array in [[-22.0, -10.0], [0.0, -10.0], [22.0, -10.0],
			[-22.0, 10.0], [0.0, 10.0], [22.0, 10.0]]:
		var x := float(item[0])
		var z := float(item[1])
		_room_box(Vector3(7.2, 0.09, 0.55), Gfx.emissive(Color(1.0, 0.94, 0.82), 1.8, Color(0.75, 0.72, 0.62)),
				Vector3(x, 13.55, z), _preview_root)
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(x, 13.1, z)
		lamp.light_color = Color(1.0, 0.93, 0.82)
		lamp.light_energy = 6.2
		lamp.omni_range = 32.0
		lamp.shadow_enabled = false
		_preview_root.add_child(lamp)

	for spec: Array in [[Vector3(0.0, 6.0, -13.0), 4.6, 30.0], [Vector3(0.0, 5.0, 13.0), 2.8, 26.0]]:
		var fill := OmniLight3D.new()
		fill.position = spec[0]
		fill.light_color = Color(1.0, 0.92, 0.82)
		fill.light_energy = float(spec[1])
		fill.omni_range = float(spec[2])
		fill.shadow_enabled = false
		_preview_root.add_child(fill)

	_preview_camera = Camera3D.new()
	_preview_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_preview_camera.fov = 40.0
	_preview_camera.near = 0.1
	_preview_camera.far = 200.0
	_preview_camera.current = true
	_preview_viewport.add_child(_preview_camera)
	_update_preview_camera()

func _room_box(size: Vector3, mat: Material, pos: Vector3, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = Forge.box(size)
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

func _room_mat(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

func _sync_preview_viewport() -> void:
	if _preview_container == null or _preview_viewport == null:
		return
	var target := Vector2i(maxi(2, roundi(_preview_container.size.x)), maxi(2, roundi(_preview_container.size.y)))
	if _preview_viewport.size != target:
		_preview_viewport.size = target

func _update_preview_camera() -> void:
	if _preview_camera == null:
		return
	var target := Vector3(0.0, 2.0, 0.0)
	var dist := 24.0 * _preview_zoom
	var dir := Vector3(sin(_preview_yaw) * cos(_preview_pitch),
			sin(_preview_pitch), -cos(_preview_yaw) * cos(_preview_pitch))
	_preview_camera.position = target + dir * dist
	_preview_camera.look_at(target)

func _zoom_preview(factor: float) -> void:
	_preview_zoom = clampf(_preview_zoom * factor, 0.45, 1.75)
	_update_preview_camera()


func _orbit_preview(relative: Vector2) -> void:
	# Horizontal drag orbits the bay; vertical drag matches the in-game chase
	# camera (drag down -> look down at the loco).
	_preview_yaw += relative.x * 0.006
	_preview_pitch = clampf(_preview_pitch + relative.y * 0.004, 0.08, 0.84)
	_update_preview_camera()


func _toggle_preview_walk() -> void:
	_preview_walk = not _preview_walk
	_preview_dragging = false
	if _preview_walk:
		_walk_pos = Vector3(7.2, 1.72, 8.5)
		_walk_vel = Vector2.ZERO
		_look_at_preview_center()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if _walk_button != null:
			_walk_button.text = "退出行走"
		if _preview_hint != null:
			_preview_hint.text = "WASD 移动 · Shift 加速 · 鼠标环视 · Esc 退出行走"
		_update_walk_camera()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if _walk_button != null:
			_walk_button.text = "行走模式"
		if _preview_hint != null:
			_preview_hint.text = "右键拖动旋转 · 滚轮缩放"
		_update_preview_camera()


func _look_at_preview_center() -> void:
	var d := Vector3(0.0, 2.0, 0.0) - _walk_pos
	_walk_yaw = atan2(-d.x, -d.z)
	_walk_pitch = clampf(asin(clampf(d.normalized().y, -1.0, 1.0)), -1.2, 1.2)


func _update_walk_camera() -> void:
	if _preview_camera == null:
		return
	var dir := (Basis(Vector3.UP, _walk_yaw) * Basis(Vector3.RIGHT, _walk_pitch)).z
	_preview_camera.position = _walk_pos
	_preview_camera.look_at(_walk_pos + dir * 10.0)


func _process(delta: float) -> void:
	if not visible or not _preview_walk:
		return
	var basis := Basis(Vector3.UP, _walk_yaw)
	var right := - basis.x
	var move := Vector3.ZERO
	if Input.is_action_pressed("gear_up"):
		move += basis.z
	if Input.is_action_pressed("gear_down"):
		move -= basis.z
	if Input.is_action_pressed("doors_toggle"):
		move -= right
	if Input.is_action_pressed("lights_toggle"):
		move += right
	var speed := 7.5 if Input.is_key_pressed(KEY_SHIFT) else 3.6
	var target := Vector2.ZERO
	if move.length_squared() > 0.0001:
		target = Vector2(move.x, move.z).normalized() * speed
	_walk_vel = _walk_vel.lerp(target, clampf(delta * 12.0, 0.0, 1.0))
	_walk_pos.x = clampf(_walk_pos.x + _walk_vel.x * delta, -34.0, 34.0)
	_walk_pos.z = clampf(_walk_pos.z + _walk_vel.y * delta, -20.0, 20.0)
	_update_walk_camera()


func _input(event: InputEvent) -> void:
	if not visible or _preview_container == null:
		return
	if _preview_walk:
		if event is InputEventMouseMotion:
			var wm := event as InputEventMouseMotion
			_walk_yaw -= wm.relative.x * 0.0025
			_walk_pitch = clampf(_walk_pitch - wm.relative.y * 0.0025, -1.25, 1.25)
			_update_walk_camera()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var over := _mouse_over_preview()
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed and over:
				_preview_dragging = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				get_viewport().set_input_as_handled()
			elif not mb.pressed and _preview_dragging:
				_preview_dragging = false
				get_viewport().set_input_as_handled()
		elif mb.pressed and over:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_zoom_preview(0.9)
				get_viewport().set_input_as_handled()
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_preview(1.1)
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _preview_dragging:
		var mm := event as InputEventMouseMotion
		_orbit_preview(mm.relative)
		get_viewport().set_input_as_handled()


func _mouse_over_preview() -> bool:
	if _preview_container == null:
		return false
	var mouse := get_viewport().get_mouse_position()
	if _options_scroll != null and _options_scroll.get_global_rect().has_point(mouse):
		return false
	return _preview_container.get_global_rect().has_point(mouse)


func _refresh_preview() -> void:
	if _preview_root == null:
		return
	if _preview_loco != null and is_instance_valid(_preview_loco):
		_preview_loco.queue_free()
	_preview_loco = Vehicles.freight_loco(_engine_sel, _skin_sel, _transmission_sel, _part_sel)
	_preview_loco.name = "PreviewLoco"
	_preview_loco.position = Vector3.ZERO
	for light in _preview_loco.head_lights:
		if light is Light3D:
			light.light_energy = 0.0
	_preview_root.add_child(_preview_loco)
	if _preview_walk:
		_update_walk_camera()
	else:
		_update_preview_camera()
	_refresh_preview_info()

func _set_category(category: String) -> void:
	_category = category
	_refresh_category_buttons()
	_refresh_options()
	if _options_scroll != null:
		_options_scroll.scroll_vertical = 0

func _refresh_category_buttons() -> void:
	for key in _category_buttons:
		var b: Button = _category_buttons[key]
		_style_category(b, key == _category)

func _refresh_options() -> void:
	if _options == null:
		return
	for c in _options.get_children():
		_options.remove_child(c)
		c.queue_free()

	if _left_title != null:
		match _category:
			"look":
				_left_title.text = "外观涂装"
			_:
				_left_title.text = "改装配件  ·  大件 + 附件"

	var summary := Label.new()
	if _category == "look":
		summary.text = "HXD1  ·  %s" %String(Vehicles.skin_info(_skin_sel)["name"])
	else:
		summary.text = "HXD1  ·  %s  ·  %s" %[
			String(Vehicles.engine_info(_engine_sel)["name"]),
			String(Vehicles.transmission_info(_transmission_sel)["name"]),
		]
	summary.add_theme_font_size_override("font_size", 13)
	summary.add_theme_color_override("font_color", Color(0.68, 0.78, 0.90))
	_options.add_child(summary)

	match _category:
		"look":
			_refresh_look_options()
		_:
			_refresh_part_options()
	_refresh_status()

func _refresh_look_options() -> void:
	_options.add_child(_section("车辆皮肤"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_options.add_child(grid)
	for id: String in Vehicles.LOCO_SKINS:
		grid.add_child(_skin_card(id))


func _refresh_part_options() -> void:
	_options.add_child(_section("大件 · 发动机"))
	if game != null and String(game.mode) == "test":
		var locked := Label.new()
		locked.text = "测试模式固定使用超大功率牵引包，发动机与变速箱已锁定，不可调整。"
		locked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		locked.add_theme_font_size_override("font_size", 13)
		locked.add_theme_color_override("font_color", Color(0.92, 0.66, 0.28))
		_options.add_child(locked)
	else:
		for id: String in Vehicles.LOCO_ENGINES:
			_options.add_child(_engine_row(id))

		_options.add_child(_section("大件 · 传动方式"))
		_options.add_child(_drive_type_row())

		_options.add_child(_section("大件 · 变速箱"))
		for id: String in Vehicles.LOCO_TRANSMISSIONS:
			_options.add_child(_transmission_row(id))

	_options.add_child(_section("附件 · 装饰与照明"))
	var hint := Label.new()
	hint.text = "装饰类小件会改变车体细节与照明，可随时拆装。"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", TEXT_MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_options.add_child(hint)
	for id: String in Vehicles.LOCO_PARTS:
		_options.add_child(_part_row(id))


func _drive_type_row() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 70)
	panel.tooltip_text = "HXD1 采用固定交—直—交电传动，牵引变流器与异步牵引电机不可单独更换。"
	panel.add_theme_stylebox_override("panel", _surface(CARD_BG, Color(0, 0, 0, 0), 16, 0, 0))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	var glyph := MiuixIcon.new("settings", Color(0.62, 0.78, 1.0), 24)
	glyph.custom_minimum_size = Vector2(36, 36)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(glyph)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 1)
	row.add_child(texts)
	_text_label(texts, "交—直—交电传动", 16)
	_text_label(texts, "牵引变流器 + 三相异步牵引电机（HXD1 固定配置）", 11, TEXT_DIM)
	_badge(row, "固定配置", false)
	return panel

func _engine_row(id: String) -> Button:
	var info := Vehicles.engine_info(id)
	var selected := id == _engine_sel
	var b := _option_button(78)
	_style_option(b, selected)
	b.pressed.connect(func() -> void:
		_engine_sel = id
		_message = ""
		_refresh_options()
		_refresh_preview())
	var content := _option_content(b, 20, 18)
	var texts := _option_texts(content)
	_text_label(texts, String(info["name"]), 18)
	_text_label(texts, String(info["desc"]), 12, TEXT_DIM)
	_text_label(texts, Vehicles.engine_summary(id), 11, Color(0.48, 0.62, 0.80))
	_badge(content, "已装备" if game != null and id == String(game.engine_id) else ("已选择" if selected else "选择"), selected)
	return b

func _transmission_row(id: String) -> Button:
	var info := Vehicles.transmission_info(id)
	var selected := id == _transmission_sel
	var b := _option_button(70)
	_style_option(b, selected)
	b.pressed.connect(func() -> void:
		_transmission_sel = id
		_message = ""
		_refresh_options()
		_refresh_preview())
	var content := _option_content(b, 20, 18)
	var texts := _option_texts(content)
	_text_label(texts, String(info["name"]), 17)
	_text_label(texts, String(info["desc"]), 11, TEXT_DIM)
	_text_label(texts, Vehicles.transmission_summary(id), 11, Color(0.48, 0.62, 0.80))
	_badge(content, "已装备" if game != null and id == String(game.transmission_id) else ("已选择" if selected else "选择"), selected)
	return b

func _skin_card(id: String) -> Button:
	var info := Vehicles.skin_info(id)
	var selected := id == _skin_sel
	var b := _option_button(82)
	_style_option(b, selected)
	b.pressed.connect(func() -> void:
		_skin_sel = id
		_message = ""
		_refresh_options()
		_refresh_preview())
	var content := _option_content(b, 14, 14)
	var swatch := PanelContainer.new()
	swatch.custom_minimum_size = Vector2(48, 48)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var swatch_sb := _surface(info["body"], Color(0, 0, 0, 0), 13, 0, 0)
	swatch.add_theme_stylebox_override("panel", swatch_sb)
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(swatch)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swatch.add_child(center)
	var stripe := ColorRect.new()
	stripe.color = info["stripe"]
	stripe.custom_minimum_size = Vector2(32, 4)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(stripe)
	var texts := _option_texts(content)
	_text_label(texts, String(info["name"]), 15)
	_text_label(texts, String(info["desc"]), 10, TEXT_DIM)
	_badge(content, "已装备" if game != null and id == String(game.skin_id) else ("已选择" if selected else ""), selected)
	return b

func _part_row(id: String) -> Button:
	var info := Vehicles.part_info(id)
	var selected := _part_sel.has(id)
	var b := _option_button(64)
	_style_option(b, selected)
	b.pressed.connect(func() -> void:
		if _part_sel.has(id):
			_part_sel.erase(id)
		else:
			_part_sel.append(id)
		_part_sel.sort()
		_message = ""
		_refresh_options()
		_refresh_preview())
	var content := _option_content(b, 18, 16)
	content.add_child(_part_icon_tile(id, selected))
	var texts := _option_texts(content)
	_text_label(texts, String(info.get("name", id)), 16)
	_text_label(texts, String(info.get("desc", "")), 11, TEXT_DIM)
	_badge(content, "已加装" if selected else "未加装", selected)
	return b

func _part_icon(id: String) -> String:
	match id:
		"cab_mirrors":
			return "mirror"
		"front_plow":
			return "plow"
		"roof_horns":
			return "horn"
		_:
			return "light"

func _part_icon_tile(id: String, selected: bool) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(36, 36)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_theme_stylebox_override("panel", _surface(
			Color(0.16, 0.34, 0.60, 0.62) if selected else Color(1, 1, 1, 0.045),
			Color(0, 0, 0, 0), 10, 0, 0))
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(center)
	center.add_child(MiuixIcon.new(_part_icon(id),
			Color(0.86, 0.93, 1.0) if selected else Color(0.56, 0.64, 0.74), 19.0))
	return tile

func _option_button(height: float) -> Button:
	var b := Button.new()
	b.text = ""
	b.custom_minimum_size = Vector2(0, height)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_option(b, false)
	return b

func _option_content(b: Button, margin_l: int, margin_r: int) -> HBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", margin_l)
	margin.add_theme_constant_override("margin_right", margin_r)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	return row

func _option_texts(row: HBoxContainer) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_theme_constant_override("separation", 1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(v)
	return v

func _text_label(parent: VBoxContainer, text: String, size: int, color := TEXT_MAIN) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _badge(parent: HBoxContainer, text: String, selected: bool) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(0.62, 0.78, 1.0) if selected else TEXT_MUTED)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)

func _refresh_preset_buttons() -> void:
	for i in range(_preset_buttons.size()):
		var b := _preset_buttons[i]
		var selected := i + 1 == _preset_slot
		var pbg := Color(0.105, 0.225, 0.42, 0.96) if selected else CARD_BG
		b.add_theme_stylebox_override("normal", _surface(pbg, Color(0, 0, 0, 0), 10, 0, 0))
		b.add_theme_stylebox_override("hover", _surface(
				Color(0.15, 0.29, 0.52, 0.98) if selected else CARD_HOVER,
				Color(0, 0, 0, 0), 10, 0, 0))
		b.add_theme_stylebox_override("pressed", _surface(pbg, Color(0, 0, 0, 0), 10, 0, 0))
		b.add_theme_color_override("font_color", Color.WHITE if selected else Color(0.88, 0.90, 0.93))

func _refresh_status() -> void:
	if _status == null:
		return
	if _message != "":
		_status.text = _message
		return
	var count := _part_sel.size()
	_status.text = "选择改装，然后应用。当前加装部件 %d 个。" %count

func _save_preset() -> void:
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(PRESET_PATH):
		cfg.load(PRESET_PATH)
	var section := "slot_%d" %_preset_slot
	cfg.set_value(section, "engine", _engine_sel)
	cfg.set_value(section, "transmission", _transmission_sel)
	cfg.set_value(section, "skin", _skin_sel)
	cfg.set_value(section, "parts", ",".join(_part_sel))
	cfg.save(PRESET_PATH)
	_message = "已保存到预设 %d" %_preset_slot
	_refresh_status()

func _load_preset() -> void:
	if not FileAccess.file_exists(PRESET_PATH):
		_message = "还没有保存过预设"
		_refresh_status()
		return
	var cfg := ConfigFile.new()
	if cfg.load(PRESET_PATH) != OK:
		_message = "预设文件读取失败"
		_refresh_status()
		return
	var section := "slot_%d" %_preset_slot
	if not cfg.has_section(section):
		_message = "预设 %d 还是空的" %_preset_slot
		_refresh_status()
		return
	var e := String(cfg.get_value(section, "engine", "standard"))
	var t := String(cfg.get_value(section, "transmission", "balanced"))
	var s := String(cfg.get_value(section, "skin", "classic"))
	_engine_sel = e if Vehicles.LOCO_ENGINES.has(e) else "standard"
	_transmission_sel = t if Vehicles.LOCO_TRANSMISSIONS.has(t) else "balanced"
	_skin_sel = s if Vehicles.LOCO_SKINS.has(s) else "classic"
	_part_sel.clear()
	var part_text := String(cfg.get_value(section, "parts", ""))
	for pid in part_text.split(",", false):
		var p := pid.strip_edges()
		if Vehicles.LOCO_PARTS.has(p) and not _part_sel.has(p):
			_part_sel.append(p)
	_part_sel.sort()
	_message = "已载入预设 %d" %_preset_slot
	_refresh_options()
	_refresh_preview()

func _apply() -> void:
	if game == null:
		return
	_message = game.apply_customization(_engine_sel, _skin_sel, _transmission_sel, _part_sel)
	_refresh_options()
	_refresh_preview()

func open(p_game, p_category := "parts") -> void:
	game = p_game
	_engine_sel = game.engine_id
	_skin_sel = game.skin_id
	_transmission_sel = game.transmission_id
	_part_sel = game.part_ids.duplicate()
	_category = p_category if p_category in ["look", "parts"] else "parts"
	_message = ""
	_preview_dragging = false
	_preview_walk = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _walk_button != null:
		_walk_button.text = "行走模式"
	if _preview_hint != null:
		_preview_hint.text = "右键拖动旋转 · 滚轮缩放"
	_refresh_category_buttons()
	_refresh_options()
	_refresh_preview()
	_refresh_preset_buttons()
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().process_frame
	var close := _find_close()
	if close != null:
		close.grab_focus()

func _section(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(0.95, 0.68, 0.38))
	return l

func _divider() -> ColorRect:
	var d := ColorRect.new()
	d.color = Color(1, 1, 1, 0.07)
	d.custom_minimum_size = Vector2(0, 1)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d

func _surface(bg: Color, border: Color, radius: int, pad_x: int, pad_y: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y
	sb.anti_aliasing = true
	sb.anti_aliasing_size = 4.0
	sb.corner_detail = 64
	sb.border_blend = true
	return sb

func _style_option(b: Button, selected: bool) -> void:
	var bg := Color(0.105, 0.225, 0.42, 0.96) if selected else CARD_BG
	var normal := _surface(bg, Color(0, 0, 0, 0), 16, 0, 0)
	var hover := _surface(Color(0.15, 0.29, 0.52, 0.98) if selected else CARD_HOVER,
			Color(0, 0, 0, 0), 16, 0, 0)
	var focus := _surface(Color(1, 1, 1, 0.055), Color(0, 0, 0, 0), 16, 0, 0)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", focus)

func _style_category(b: Button, selected: bool = false) -> void:
	var bg := ACCENT.darkened(0.12) if selected else CARD_BG
	b.add_theme_stylebox_override("normal", _surface(bg, Color(0, 0, 0, 0), 12, 16, 8))
	b.add_theme_stylebox_override("hover", _surface(ACCENT.darkened(0.02) if selected else CARD_HOVER, Color(0, 0, 0, 0), 12, 16, 8))
	b.add_theme_stylebox_override("pressed", _surface(bg, Color(0, 0, 0, 0), 12, 16, 8))
	b.add_theme_color_override("font_color", Color(0.85, 0.90, 0.98) if selected else TEXT_DIM)

func _style_button(b: Button, primary: bool) -> void:
	var bg := ACCENT if primary else Color(0.12, 0.125, 0.14, 0.96)
	var hover := Color(0.30, 0.58, 1.0) if primary else Color(0.16, 0.165, 0.185, 0.98)
	b.add_theme_stylebox_override("normal", _surface(bg, Color(0, 0, 0, 0), 12, 16, 9))
	b.add_theme_stylebox_override("hover", _surface(hover, Color(0, 0, 0, 0), 12, 16, 9))
	b.add_theme_stylebox_override("pressed", _surface(ACCENT.darkened(0.14) if primary else Color(0.10, 0.105, 0.12, 1.0), Color(0, 0, 0, 0), 12, 16, 9))
	var focus := _surface(Color(1, 1, 1, 0.055), Color(0, 0, 0, 0), 12, 16, 9)
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_color_override("font_color", Color.WHITE if primary else Color(0.88, 0.90, 0.93))

func _close() -> void:
	_preview_dragging = false
	_preview_walk = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	closed.emit()

func _find_close() -> Button:
	for c in get_children():
		if c is Control:
			var b := _find_button(c, "关闭")
			if b != null:
				return b
	return null

func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node as Button
	for c in node.get_children():
		var b := _find_button(c, text)
		if b != null:
			return b
	return null

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _preview_walk:
			_toggle_preview_walk()
		else:
			_close()
