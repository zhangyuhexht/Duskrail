extends CanvasLayer
class_name HUD

const SpeedGaugeScript = preload("res://src/ui/speed_gauge.gd")

var speed_gauge
var task_label: Label
var toast_label: Label
var mission_bar: ProgressBar
var task_panel: PanelContainer
var dash_panel: PanelContainer
var hover_panel: PanelContainer
var hover_label: Label
var _hover_visible := false
var _toast_time := 0.0
var walk_crosshair: Control

func _ready() -> void:
	_build()

func _build() -> void:

	var panel := PanelContainer.new()
	dash_panel = panel
	panel.name = "DashPanel"
	panel.anchor_left = 0.0
	panel.anchor_top = 1.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 16
	panel.offset_top = -368
	panel.offset_right = 354
	panel.offset_bottom = -16
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.035, 0.047, 0.062, 0.58)
	sb.border_color = Color(0.62, 0.5, 0.31, 0.52)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 10
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	panel.add_child(vb)

	speed_gauge = SpeedGaugeScript.new()
	speed_gauge.custom_minimum_size = Vector2(300, 300)
	speed_gauge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_gauge.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(speed_gauge)


	var top := Label.new()
	top.name = "TopInfo"
	top.position = Vector2(22, 16)
	top.add_theme_font_size_override("font_size", 15)
	top.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	top.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	top.add_theme_constant_override("outline_size", 5)
	add_child(top)


	task_panel = PanelContainer.new()
	task_panel.anchor_left = 0.0
	task_panel.anchor_top = 0.0
	task_panel.offset_left = 18
	task_panel.offset_top = 108
	task_panel.offset_right = 360
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color(0.06, 0.1, 0.14, 0.66)
	tsb.border_color = Color(0.3, 0.55, 0.62, 0.7)
	tsb.set_border_width_all(1)
	tsb.set_corner_radius_all(8)
	tsb.content_margin_left = 14
	tsb.content_margin_right = 14
	tsb.content_margin_top = 10
	tsb.content_margin_bottom = 10
	task_panel.add_theme_stylebox_override("panel", tsb)
	task_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	task_panel.visible = false
	add_child(task_panel)
	var tvb := VBoxContainer.new()
	tvb.add_theme_constant_override("separation", 9)
	task_panel.add_child(tvb)
	task_label = Label.new()
	task_label.add_theme_font_size_override("font_size", 14)
	task_label.add_theme_color_override("font_color", Color(0.88, 0.95, 0.98))
	task_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	task_label.custom_minimum_size = Vector2(310, 0)
	tvb.add_child(task_label)
	mission_bar = _make_bar(Color(0.42, 0.8, 0.95))
	mission_bar.custom_minimum_size = Vector2(310, 14)
	mission_bar.visible = false
	tvb.add_child(mission_bar)


	toast_label = Label.new()
	toast_label.anchor_left = 0.5
	toast_label.anchor_right = 0.5
	toast_label.anchor_top = 0.0
	toast_label.offset_top = 84
	toast_label.offset_left = -300
	toast_label.offset_right = 300
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 22)
	toast_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	toast_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	toast_label.add_theme_constant_override("outline_size", 8)
	toast_label.modulate.a = 0.0
	add_child(toast_label)

	hover_panel = PanelContainer.new()
	hover_panel.name = "HoverTip"
	hover_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_panel.visible = false
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color(0.035, 0.045, 0.06, 0.93)
	hsb.border_color = Color(0.42, 0.7, 0.9, 0.75)
	hsb.set_border_width_all(1)
	hsb.set_corner_radius_all(8)
	hsb.content_margin_left = 12
	hsb.content_margin_right = 12
	hsb.content_margin_top = 8
	hsb.content_margin_bottom = 8
	hover_panel.add_theme_stylebox_override("panel", hsb)
	add_child(hover_panel)
	hover_label = Label.new()
	hover_label.add_theme_font_size_override("font_size", 13)
	hover_label.add_theme_color_override("font_color", Color(0.93, 0.96, 1.0))
	hover_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hover_label.custom_minimum_size = Vector2(240, 0)
	hover_panel.add_child(hover_label)

	# First-person walking reticle. Hidden while seated or in third person.
	walk_crosshair = Control.new()
	walk_crosshair.name = "WalkCrosshair"
	walk_crosshair.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	walk_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	walk_crosshair.visible = false
	add_child(walk_crosshair)
	var cross_center := CenterContainer.new()
	cross_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cross_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	walk_crosshair.add_child(cross_center)
	var cross_box := Control.new()
	cross_box.custom_minimum_size = Vector2(22, 22)
	cross_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cross_center.add_child(cross_box)
	var cross_pieces := [
		[Vector2(10, 0), Vector2(2, 7)],
		[Vector2(10, 15), Vector2(2, 7)],
		[Vector2(0, 10), Vector2(7, 2)],
		[Vector2(15, 10), Vector2(7, 2)],
		[Vector2(9, 9), Vector2(4, 4)],
	]
	for piece: Array in cross_pieces:
		var p0: Vector2 = piece[0]
		var p1: Vector2 = piece[1]
		var shadow := ColorRect.new()
		shadow.color = Color(0, 0, 0, 0.70)
		shadow.position = p0 - Vector2(1, 1)
		shadow.size = p1 + Vector2(2, 2)
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cross_box.add_child(shadow)
		var line := ColorRect.new()
		line.color = Color(1, 1, 1, 0.92)
		line.position = p0
		line.size = p1
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cross_box.add_child(line)


func set_walk_crosshair(on: bool) -> void:
	if walk_crosshair != null:
		walk_crosshair.visible = on


func _make_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(180, 12)
	bar.max_value = 100.0
	bar.value = 0.0
	var fg := StyleBoxFlat.new()
	fg.bg_color = color
	fg.set_corner_radius_all(6)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.16, 0.19, 0.23, 0.9)
	bg.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("fill", fg)
	bar.add_theme_stylebox_override("background", bg)
	return bar

func _row(label: String, control: Control) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	var l := Label.new()
	l.text = label
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(0.62, 0.7, 0.78))
	l.custom_minimum_size = Vector2(34, 0)
	hb.add_child(l)
	hb.add_child(control)
	return hb

func toast(text: String, duration := 3.5) -> void:
	if toast_label == null:
		return
	toast_label.text = text
	toast_label.modulate.a = 1.0
	_toast_time = duration


func set_task_text(text: String) -> void:
	if task_label != null:
		task_label.text = text
	if task_panel != null:
		task_panel.visible = text.strip_edges() != ""

func set_progress(value: float, visible: bool) -> void:
	if mission_bar == null:
		return
	mission_bar.visible = visible
	if visible:
		mission_bar.value = clampf(value, 0.0, 1.0) * 100.0


func set_dash_visible(value: bool) -> void:
	if dash_panel != null:
		dash_panel.visible = value


func show_device_hover(title: String, description: String) -> void:
	if hover_panel == null:
		return
	_hover_visible = title.strip_edges() != ""
	hover_panel.visible = _hover_visible
	if _hover_visible:
		hover_label.text = title if description == "" else "%s\n%s" %[title, description]
		_place_hover()


func _place_hover() -> void:
	if hover_panel == null or not _hover_visible:
		return
	var vp := get_viewport()
	var mouse := vp.get_mouse_position() if vp != null else Vector2.ZERO
	var screen := vp.get_visible_rect().size if vp != null else Vector2(1280, 720)
	var tip := hover_panel.get_combined_minimum_size()
	var pos := mouse + Vector2(18, 18)
	pos.x = clampf(pos.x, 8.0, maxf(8.0, screen.x - tip.x - 8.0))
	pos.y = clampf(pos.y, 8.0, maxf(8.0, screen.y - tip.y - 8.0))
	hover_panel.position = pos

func update(train: Train, route: Route, extra := "", status := "") -> void:
	if train == null:
		return
	var gear_color := Color(0.38, 0.95, 0.62)
	if train.gear <= Train.GEAR_P1:
		gear_color = Color(1.0, 0.58, 0.36)
	elif train.gear == Train.GEAR_N:
		gear_color = Color(0.78, 0.84, 0.9)
	if speed_gauge != null:
		speed_gauge.set_values(train.speed_kmh(), train.gear_name(), gear_color)
	var top := get_node_or_null("TopInfo") as Label
	if top:
		var next_txt := ""
		if route != null:
			next_txt = "里程 %.2f km / %.2f km" %[train.distance / 1000.0, route.total / 1000.0]
		top.text = "%s   |   %s   |   %.0f km/h   |   %s   |   FPS %d%s" %[
			train.service_name, next_txt, train.speed_kmh(), train.gear_name(),
			Engine.get_frames_per_second(), extra
		]

func _process(delta: float) -> void:
	if _hover_visible:
		_place_hover()
	if _toast_time > 0.0:
		_toast_time -= delta
		if _toast_time <= 0.0:
			toast_label.modulate.a = maxf(0.0, toast_label.modulate.a - delta * 2.0)
	elif toast_label and toast_label.modulate.a > 0.0:
		toast_label.modulate.a = maxf(0.0, toast_label.modulate.a - delta * 1.2)
