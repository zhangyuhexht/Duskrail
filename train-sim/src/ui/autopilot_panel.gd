extends CanvasLayer
class_name AutopilotPanel


signal closed

const Brand = preload("res://src/core/brand.gd")

const TEXT_MAIN := Color(0.92, 0.94, 0.97)
const TEXT_DIM := Color(0.66, 0.70, 0.76)
const TEXT_MUTED := Color(0.44, 0.48, 0.54)
const ACCENT := Color(0.24, 0.55, 0.96)

var game
var _panel: PanelContainer
var _list: VBoxContainer
var _status: Label
var _cancel: Button


func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	_build()
	set_process_unhandled_input(true)


func _surface(bg: Color, radius := 14, px := 16, py := 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = Color(0, 0, 0, 0)
	s.set_border_width_all(0)
	s.set_corner_radius_all(radius)
	s.content_margin_left = px
	s.content_margin_right = px
	s.content_margin_top = py
	s.content_margin_bottom = py
	s.anti_aliasing = true
	s.anti_aliasing_size = 2.0
	s.corner_detail = 24
	return s


func _button_style(b: Button, primary := false) -> void:
	var bg := Color(0.16, 0.38, 0.72, 0.98) if primary else Color(1, 1, 1, 0.045)
	var hover := Color(0.23, 0.48, 0.84, 1.0) if primary else Color(1, 1, 1, 0.10)
	b.add_theme_stylebox_override("normal", _surface(bg, 12, 16, 10))
	b.add_theme_stylebox_override("hover", _surface(hover, 12, 16, 10))
	b.add_theme_stylebox_override("pressed", _surface(bg.darkened(0.15), 12, 16, 10))
	b.add_theme_stylebox_override("focus", _surface(Color(1, 1, 1, 0.06), 12, 16, 10))
	b.add_theme_color_override("font_color", Color.WHITE if primary else Color(0.86, 0.90, 0.95))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_font_size_override("font_size", 14)
	b.focus_mode = Control.FOCUS_ALL


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.70)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(620, 680)
	var style := _surface(Color(0.055, 0.060, 0.072, 0.99), 24, 24, 22)
	style.shadow_color = Color(0, 0, 0, 0.40)
	style.shadow_size = 28
	style.shadow_offset = Vector2(0, 12)
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	_panel.add_child(root)

	var overline := Label.new()
	overline.text = "DUSKRAIL  /  AUTOPILOT"
	overline.add_theme_font_override("font", Brand.display_font())
	overline.add_theme_font_size_override("font_size", 10)
	overline.add_theme_color_override("font_color", Color(0.50, 0.66, 0.92))
	root.add_child(overline)

	var title := Label.new()
	title.text = "自动驾驶"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", TEXT_MAIN)
	root.add_child(title)

	var sub := Label.new()
	sub.text = "选择一个站点，列车会自动牵引、减速并在站台停车。"
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", TEXT_DIM)
	root.add_child(sub)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 12)
	_status.add_theme_color_override("font_color", Color(0.55, 0.78, 1.0))
	root.add_child(_status)

	var divider := ColorRect.new()
	divider.color = Color(1, 1, 1, 0.07)
	divider.custom_minimum_size = Vector2(0, 1)
	root.add_child(divider)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 7)
	scroll.add_child(_list)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 10)
	root.add_child(footer)
	_cancel = Button.new()
	_cancel.text = "取消自动驾驶"
	_cancel.custom_minimum_size = Vector2(150, 42)
	_button_style(_cancel, false)
	_cancel.pressed.connect(_on_cancel)
	footer.add_child(_cancel)
	var close := Button.new()
	close.text = "关闭"
	close.custom_minimum_size = Vector2(110, 42)
	_button_style(close, true)
	close.pressed.connect(_close)
	footer.add_child(close)


func open(p_game) -> void:
	game = p_game
	visible = true
	_rebuild()


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	if game == null or game.train == null or game.station_data.is_empty():
		_status.text = "列车或站点尚未就绪"
		_cancel.disabled = true
		return
	_cancel.disabled = not game.autopilot
	if game.autopilot and game.autopilot_target >= 0:
		_status.text = "当前自动驾驶：%s" % game._autopilot_label()
	else:
		_status.text = "当前：手动驾驶"
	for i in range(game.station_data.size()):
		var st: Dictionary = game.station_data[i]
		var forward: float = game.route.wrap_dist(float(st["stop"]) - game.train.distance)
		var b := Button.new()
		var suffix := ""
		if game.autopilot and game.autopilot_target == i:
			suffix = "   ·  当前目标"
		b.text = "%s      %.1f km%s" %[String(st["name"]), forward / 1000.0, suffix]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 38)
		_button_style(b, game.autopilot and game.autopilot_target == i)
		b.pressed.connect(_choose.bind(i))
		_list.add_child(b)


func _choose(index: int) -> void:
	if game != null:
		game.start_autopilot(index)
	_close()


func _on_cancel() -> void:
	if game != null:
		game.stop_autopilot()
	_rebuild()


func _close() -> void:
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("autopilot") \
			or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
