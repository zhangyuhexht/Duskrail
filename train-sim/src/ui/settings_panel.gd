extends CanvasLayer
class_name SettingsPanel

const Brand = preload("res://src/core/brand.gd")

signal changed
signal closed

const CATEGORIES := ["游戏", "画面", "音频", "操作"]
const TEXT_MAIN := Color(0.957, 0.965, 0.976)
const TEXT_DIM := Color(0.620, 0.640, 0.680)
const TEXT_MUTED := Color(0.430, 0.450, 0.490)
const ACCENT := Color(0.204, 0.510, 1.0)
const CARD_BG := Color(0.095, 0.100, 0.112, 0.96)
const CARD_HOVER := Color(0.125, 0.132, 0.146, 0.98)

var _cat := 0
var _panel: PanelContainer
var _content: VBoxContainer
var _header: Label
var _nav: Array[Button] = []
var _nav_group := ButtonGroup.new()

func _ready() -> void:
	layer = 30
	_build()
	visible = false

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

func _style_button(b: Button, primary: bool) -> void:
	var bg := ACCENT if primary else Color(0.12, 0.125, 0.14, 0.96)
	var hover := Color(0.30, 0.58, 1.0) if primary else Color(0.16, 0.165, 0.185, 0.98)
	b.add_theme_stylebox_override("normal", _surface(bg, Color(0, 0, 0, 0), 12, 16, 9))
	b.add_theme_stylebox_override("hover", _surface(hover, Color(0, 0, 0, 0), 12, 16, 9))
	b.add_theme_stylebox_override("pressed", _surface(
			ACCENT.darkened(0.14) if primary else Color(0.10, 0.105, 0.12, 1.0),
			Color(0, 0, 0, 0), 12, 16, 9))
	b.add_theme_stylebox_override("focus", _surface(Color(1, 1, 1, 0.055),
			Color(0, 0, 0, 0), 12, 16, 9))
	b.add_theme_color_override("font_color", Color.WHITE if primary else Color(0.88, 0.90, 0.93))
	b.add_theme_color_override("font_hover_color", Color.WHITE)

func _style_nav(b: Button, selected: bool) -> void:
	var bg := Color(0.12, 0.27, 0.48, 0.96) if selected else Color(1, 1, 1, 0.02)
	b.add_theme_stylebox_override("normal", _surface(bg, Color(0, 0, 0, 0), 14, 16, 9))
	b.add_theme_stylebox_override("hover", _surface(
			Color(0.16, 0.31, 0.54, 0.98) if selected else Color(1, 1, 1, 0.07),
			Color(0, 0, 0, 0), 14, 16, 9))
	b.add_theme_stylebox_override("pressed", _surface(bg, Color(0, 0, 0, 0), 14, 16, 9))
	b.add_theme_stylebox_override("focus", _surface(Color(1, 1, 1, 0.055),
			Color(0, 0, 0, 0), 14, 16, 9))
	b.add_theme_color_override("font_color", Color.WHITE if selected else TEXT_DIM)
	b.add_theme_color_override("font_hover_color", Color.WHITE)

func _style_toggle(b: Button, enabled: bool) -> void:
	var bg := Color(0.12, 0.30, 0.52, 0.96) if enabled else Color(0.10, 0.11, 0.13, 0.96)
	b.add_theme_stylebox_override("normal", _surface(bg, Color(0, 0, 0, 0), 11, 14, 8))
	b.add_theme_stylebox_override("hover", _surface(
			Color(0.16, 0.36, 0.60, 0.98) if enabled else CARD_HOVER,
			Color(0, 0, 0, 0), 11, 14, 8))
	b.add_theme_stylebox_override("pressed", _surface(bg, Color(0, 0, 0, 0), 11, 14, 8))
	b.add_theme_stylebox_override("focus", _surface(Color(1, 1, 1, 0.055),
			Color(0, 0, 0, 0), 11, 14, 8))
	b.text = "开启" if enabled else "关闭"
	b.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0) if enabled else TEXT_DIM)
	b.add_theme_color_override("font_hover_color", Color.WHITE)

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.68)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	_panel = panel
	panel.custom_minimum_size = Vector2(1240, 760)
	var panel_style := _surface(Color(0.052, 0.057, 0.068, 0.97),
			Color(0, 0, 0, 0), 28, 26, 22)
	panel_style.shadow_color = Color(0, 0, 0, 0.38)
	panel_style.shadow_size = 30
	panel_style.shadow_offset = Vector2(0, 12)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	panel.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)
	var title_col := VBoxContainer.new()
	title_col.add_theme_constant_override("separation", 2)
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_col)
	var overline := Label.new()
	overline.text = "%s  /  设置" %Brand.NAME_EN
	overline.add_theme_font_override("font", Brand.cjk_font())
	overline.add_theme_font_size_override("font_size", 10)
	overline.add_theme_color_override("font_color", Color(0.52, 0.64, 0.86))
	title_col.add_child(overline)
	var title := Label.new()
	title.text = "设置"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", TEXT_MAIN)
	title_col.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "游戏、画面、音频与操作"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", TEXT_MUTED)
	title_col.add_child(subtitle)
	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(100, 44)
	close_btn.add_theme_font_size_override("font_size", 15)
	close_btn.focus_mode = Control.FOCUS_ALL
	close_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(close)
	_style_button(close_btn, false)
	header.add_child(close_btn)

	root.add_child(_divider())

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var left_card := PanelContainer.new()
	left_card.custom_minimum_size = Vector2(230, 0)
	var left_style := _surface(Color(0.060, 0.065, 0.076, 0.82),
			Color(0, 0, 0, 0), 20, 14, 14)
	left_style.shadow_color = Color(0, 0, 0, 0.24)
	left_style.shadow_size = 12
	left_style.shadow_offset = Vector2(0, 6)
	left_card.add_theme_stylebox_override("panel", left_style)
	body.add_child(left_card)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left_card.add_child(left)
	for i in range(CATEGORIES.size()):
		var b := Button.new()
		b.text = CATEGORIES[i]
		b.toggle_mode = true
		b.button_group = _nav_group
		b.custom_minimum_size = Vector2(190, 46)
		b.add_theme_font_size_override("font_size", 16)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_select.bind(i))
		_style_nav(b, i == 0)
		left.add_child(b)
		_nav.append(b)
	var left_spacer := Control.new()
	left_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(left_spacer)
	var keys_hint := Label.new()
	keys_hint.text = "行车按键\nW/↑ 升档   S/↓ 降档\nA/← 车门   D/→ 车灯\nR 换向   B 停放制动\nE 互动   C 视角   M 大地图"
	keys_hint.add_theme_font_size_override("font_size", 11)
	keys_hint.add_theme_color_override("font_color", TEXT_MUTED)
	left.add_child(keys_hint)

	var right_card := PanelContainer.new()
	right_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right_style := _surface(Color(0.042, 0.047, 0.057, 0.82),
			Color(0, 0, 0, 0), 20, 20, 16)
	right_style.shadow_color = Color(0, 0, 0, 0.20)
	right_style.shadow_size = 10
	right_card.add_theme_stylebox_override("panel", right_style)
	body.add_child(right_card)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right_card.add_child(right)

	_header = Label.new()
	_header.add_theme_font_size_override("font_size", 22)
	_header.add_theme_color_override("font_color", Color(0.84, 0.91, 1.0))
	right.add_child(_header)
	right.add_child(_divider())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	right.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 8)
	scroll.add_child(_content)

	root.add_child(_divider())
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	footer.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(footer)
	var reset := Button.new()
	reset.text = "恢复默认"
	reset.custom_minimum_size = Vector2(124, 42)
	reset.add_theme_font_size_override("font_size", 14)
	reset.pressed.connect(_on_reset)
	_style_button(reset, false)
	footer.add_child(reset)
	var done := Button.new()
	done.text = "完成"
	done.custom_minimum_size = Vector2(110, 42)
	done.add_theme_font_size_override("font_size", 14)
	done.pressed.connect(close)
	_style_button(done, true)
	footer.add_child(done)

func _divider() -> ColorRect:
	var d := ColorRect.new()
	d.color = Color(1, 1, 1, 0.065)
	d.custom_minimum_size = Vector2(0, 1)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d

func _select(i: int) -> void:
	_cat = clampi(i, 0, CATEGORIES.size() - 1)
	for n in range(_nav.size()):
		_nav[n].button_pressed = n == _cat
		_style_nav(_nav[n], n == _cat)
	_header.text = "%s设置" %CATEGORIES[_cat]
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()
	match _cat:
		0:
			_build_game()
		1:
			_build_video()
		2:
			_build_audio()
		3:
			_build_controls()

func _row(label: String, hint := "", align_right := true) -> VBoxContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _surface(
			Color(1, 1, 1, 0.035), Color(0, 0, 0, 0), 14, 16, 12))
	_content.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	card.add_child(col)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(210, 0)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.add_theme_color_override("font_color", Color(0.80, 0.86, 0.94))
	l.add_theme_font_size_override("font_size", 15)
	row.add_child(l)
	if align_right:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(spacer)
	if hint != "":
		var h := Label.new()
		h.text = hint
		h.add_theme_font_size_override("font_size", 11)
		h.add_theme_color_override("font_color", TEXT_MUTED)
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.custom_minimum_size = Vector2(480, 0)
		col.add_child(h)
	col.set_meta("row", row)
	return col

func _add_option(label: String, items: Array, selected: int, cb: Callable, hint := "") -> OptionButton:
	var col := _row(label, hint)
	var row: HBoxContainer = col.get_meta("row")
	var ob := OptionButton.new()
	for it in items:
		ob.add_item(String(it))
	ob.selected = clampi(selected, 0, maxi(0, items.size() - 1))
	ob.custom_minimum_size = Vector2(260, 38)
	ob.add_theme_font_size_override("font_size", 14)
	ob.add_theme_stylebox_override("normal", _surface(Color(0.10, 0.11, 0.13, 0.96),
			Color(0, 0, 0, 0), 11, 14, 7))
	ob.add_theme_stylebox_override("hover", _surface(CARD_HOVER,
			Color(0, 0, 0, 0), 11, 14, 7))
	ob.add_theme_stylebox_override("pressed", _surface(Color(0.075, 0.08, 0.095, 1.0),
			Color(0, 0, 0, 0), 11, 14, 7))
	ob.add_theme_stylebox_override("focus", _surface(Color(1, 1, 1, 0.055),
			Color(0, 0, 0, 0), 11, 14, 7))
	ob.add_theme_color_override("font_color", Color(0.88, 0.91, 0.95))
	ob.add_theme_color_override("font_hover_color", Color.WHITE)
	ob.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	ob.item_selected.connect(cb)
	row.add_child(ob)
	return ob

func _add_check(label: String, value: bool, cb: Callable, hint := "") -> Button:
	var col := _row(label, hint)
	var row: HBoxContainer = col.get_meta("row")
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = value
	b.custom_minimum_size = Vector2(86, 36)
	b.add_theme_font_size_override("font_size", 13)
	b.focus_mode = Control.FOCUS_ALL
	_style_toggle(b, value)
	b.toggled.connect(func(on: bool) -> void:
		_style_toggle(b, on)
		cb.call(on))
	row.add_child(b)
	return b

func _add_slider(label: String, lo: float, hi: float, step: float, value: float,
		fmt: String, cb: Callable, hint := "") -> HSlider:
	var col := _row(label, hint, false)
	var row: HBoxContainer = col.get_meta("row")
	var slider_row := HBoxContainer.new()
	slider_row.add_theme_constant_override("separation", 10)
	slider_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider_row)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(230, 26)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_theme_stylebox_override("slider", _surface(Color(1, 1, 1, 0.09),
			Color(0, 0, 0, 0), 4, 0, 4))
	s.add_theme_stylebox_override("grabber_area", _surface(ACCENT,
			Color(0, 0, 0, 0), 4, 0, 4))
	s.add_theme_stylebox_override("grabber_area_highlight", _surface(
			ACCENT.lightened(0.12), Color(0, 0, 0, 0), 4, 0, 4))
	slider_row.add_child(s)
	var v := Label.new()
	v.custom_minimum_size = Vector2(58, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	v.add_theme_color_override("font_color", Color(0.70, 0.80, 0.90))
	v.text = _fmt_value(fmt, s.value)
	slider_row.add_child(v)
	s.value_changed.connect(func(x: float) -> void:
		v.text = _fmt_value(fmt, x)
		cb.call(x))
	return s

func _fmt_value(fmt: String, v: float) -> String:
	if fmt.contains("%d"):
		return fmt % int(round(v))
	return fmt % v

func _build_game() -> void:
	_add_option("自动保存频率", ["每 10 分钟", "每 5 分钟", "每 3 分钟", "每 1 分钟"],
			UserSettings.autosave_index,
			func(i: int) -> void:
				UserSettings.autosave_index = i
				_commit(false),
			"游戏进行中按设定间隔自动保存到当前档案")
	_add_check("大地图打开时暂停", UserSettings.map_pause,
			func(b: bool) -> void:
				UserSettings.map_pause = b
				_commit(false),
			"关闭后，打开大地图时列车继续运行")
	_add_check("冷车起动（进阶）", UserSettings.cold_start,
			func(b: bool) -> void:
				UserSettings.cold_start = b
				_commit(false),
			"开启后新存档从全车断电开始；关闭则整备完成直接发车")
	_add_option("时间流速", ["暂停", "慢 · 45 分钟/日", "正常 · 20 分钟/日", "快 · 7 分钟/日"],
			UserSettings.time_flow,
			func(i: int) -> void:
				UserSettings.time_flow = i
				_commit(false),
			"控制昼夜自动更替速度；暂停时可用 T 键手动推进时间")
	_add_check("显示操作提示", UserSettings.show_hints,
			func(b: bool) -> void:
				UserSettings.show_hints = b
				_commit(false),
			"在界面顶部显示当前视角与常用按键提示")

func _build_video() -> void:
	_add_option("画质", ["低", "中", "高", "极致"], UserSettings.quality,
			func(i: int) -> void:
				UserSettings.quality = i
				_commit(true))
	_add_option("显示模式", ["窗口", "全屏", "独占全屏"], UserSettings.window_mode,
			func(i: int) -> void:
				UserSettings.window_mode = i
				_commit(true)
				_select(_cat))
	var res_labels := []
	for r: Vector2i in UserSettings.RESOLUTIONS:
		res_labels.append("%d × %d" %[r.x, r.y])
	var res_opt := _add_option("分辨率", res_labels, UserSettings.resolution,
			func(i: int) -> void:
				UserSettings.resolution = i
				_commit(true))
	res_opt.disabled = UserSettings.window_mode != 0
	_add_check("垂直同步", UserSettings.vsync,
			func(b: bool) -> void:
				UserSettings.vsync = b
				_commit(true))
	var up_modes := Upscaling.available_modes()
	var up_labels := []
	var up_sel := 0
	# On non-RTX GPUs a saved DLSS preference runs as FSR 2.2. Show the mode
	# that is actually active so the dropdown never disagrees with the image.
	var up_active := UserSettings.upscaler
	if Upscaling.is_dlss_mode(up_active) and not Upscaling.dlss_available():
		up_active = Upscaling.Mode.FSR2_QUALITY
	for idx in range(up_modes.size()):
		up_labels.append(Upscaling.label_for(int(up_modes[idx])))
		if int(up_modes[idx]) == up_active:
			up_sel = idx
	_add_option("3D 缩放", up_labels, up_sel,
			func(i: int) -> void:
				UserSettings.upscaler = int(up_modes[clampi(i, 0, up_modes.size() - 1)])
				_commit(true),
			"DLSS 仅支持 RTX 20 系列及以上；其他显卡可选用 FSR 2.2")
	_add_slider("视野（FOV）", 55.0, 85.0, 1.0, UserSettings.fov, "%d°",
			func(v: float) -> void:
				UserSettings.fov = v
				_commit(false),
			"视野越大，画面越广；越小，景物越近")

func _build_audio() -> void:
	_add_slider("主音量", 0.0, 1.0, 0.01, UserSettings.master_volume, "%d%%",
			func(v: float) -> void:
				UserSettings.master_volume = v
				_commit(false),
			"调节所有声音的整体音量")

func _build_controls() -> void:
	_add_slider("视角灵敏度", 0.3, 2.5, 0.05, UserSettings.mouse_sensitivity, "%.2f×",
			func(v: float) -> void:
				UserSettings.mouse_sensitivity = v
				_commit(false),
			"拖动鼠标或右键转向时的灵敏度")
	_add_check("反转视角 Y 轴", UserSettings.invert_look_y,
			func(b: bool) -> void:
				UserSettings.invert_look_y = b
				_commit(false))

func _commit(apply_video: bool) -> void:
	UserSettings.save_settings()
	if apply_video:
		UserSettings.apply_all()
	else:
		Config.quality = UserSettings.quality
		UserSettings.apply_audio()
	changed.emit()

func _on_reset() -> void:
	UserSettings.reset_defaults()
	UserSettings.save_settings()
	UserSettings.apply_all()
	_select(_cat)
	changed.emit()

func _adapt_panel() -> void:
	if _panel == null:
		return
	var vp := get_viewport().get_visible_rect().size
	_panel.custom_minimum_size = Vector2(minf(1240.0, vp.x - 48.0), minf(760.0, vp.y - 48.0))

func open(category := 0) -> void:
	visible = true
	_adapt_panel()
	_select(category)
	if not _nav.is_empty():
		_nav[_cat].grab_focus()

func close() -> void:
	visible = false
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
