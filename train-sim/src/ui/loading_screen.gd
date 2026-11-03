extends CanvasLayer
class_name LoadingScreen

const Brand = preload("res://src/core/brand.gd")


const TIPS := [
	"正在生成线路、地形与城镇…",
	"正在架设接触网与信号机…",
	"正在编组 HXD1 货运列车…",
	"正在准备驾驶室与动态天气…",
]
const TEXT_MAIN := Color(0.957, 0.965, 0.976)
const TEXT_DIM := Color(0.620, 0.640, 0.680)
const TEXT_MUTED := Color(0.430, 0.450, 0.490)
const ACCENT := Color(0.204, 0.510, 1.0)
const BRAND_ORANGE := Color(1.0, 0.455, 0.145)

var root: Control
var bar: ProgressBar
var status_label: Label
var percent_label: Label
var spinner: Control
var rail: Control
var _target := 0.0
var _shown := 0.0
var _tip_index := 0
var _tip_clock := 0.0
var _tip_label: Label


class Spinner extends Control:
	var angle := 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(22, 22)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(delta: float) -> void:
		angle += delta * 3.4
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 2.0
		draw_arc(c, r, angle, angle + PI * 1.45, 28, Color(0.204, 0.510, 1.0), 2.2, true)


class LoadingRail extends Control:
	var phase := 0.0

	func _ready() -> void:
		set_process(true)
		custom_minimum_size = Vector2(0, 120)

	func _process(delta: float) -> void:
		phase += delta * 42.0
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var mid := h * 0.55
		draw_line(Vector2(40, mid), Vector2(w - 40, mid), Color(0.24, 0.26, 0.30), 2.0)
		draw_line(Vector2(40, mid + 5), Vector2(w - 40, mid + 5), Color(0.14, 0.15, 0.18), 1.0)
		var count := int(maxf(1.0, (w - 80) / 34.0))
		for i in range(count):
			var x := 40.0 + float(i) * 34.0 + fmod(phase, 34.0) * 0.25
			draw_line(Vector2(x, mid - 8), Vector2(x, mid + 13), Color(0.20, 0.22, 0.26), 1.0)
		var train_x := 40.0 + fmod(phase * 1.4, maxf(1.0, w - 160.0))
		draw_rect(Rect2(train_x, mid - 22, 74, 18), Color(0.94, 0.40, 0.12))
		draw_rect(Rect2(train_x + 8, mid - 30, 27, 9), Color(1.0, 0.52, 0.18))
		draw_rect(Rect2(train_x + 48, mid - 24, 18, 10), Color(0.17, 0.19, 0.23))
		draw_circle(Vector2(train_x + 18, mid + 1), 3.0, Color(0.07, 0.08, 0.09))
		draw_circle(Vector2(train_x + 56, mid + 1), 3.0, Color(0.07, 0.08, 0.09))
		draw_circle(Vector2(train_x + 75, mid - 2), 2.0, Color(0.55, 0.75, 1.0, 0.9))


func _ready() -> void:
	layer = 70
	root = Control.new()
	root.name = "LoadingRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var base := ColorRect.new()
	base.color = Color(0.032, 0.035, 0.042, 1.0)
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(base)

	var glow := TextureRect.new()
	glow.texture = _radial_texture(
			Color(0.17, 0.38, 0.90, 0.16),
			Color(0.10, 0.22, 0.58, 0.04),
			Color(0.04, 0.10, 0.28, 0.0))
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(glow)

	var brand_row := HBoxContainer.new()
	brand_row.position = Vector2(104, 94)
	brand_row.add_theme_constant_override("separation", 13)
	root.add_child(brand_row)

	var logo := PanelContainer.new()
	logo.custom_minimum_size = Vector2(42, 42)
	var logo_sb := StyleBoxFlat.new()
	logo_sb.bg_color = BRAND_ORANGE
	logo_sb.border_color = Color(1.0, 0.78, 0.58, 0.28)
	logo_sb.set_border_width_all(1)
	logo_sb.set_corner_radius_all(13)
	logo_sb.shadow_color = Color(1.0, 0.30, 0.06, 0.22)
	logo_sb.shadow_size = 12
	logo_sb.shadow_offset = Vector2(0, 5)
	logo.add_theme_stylebox_override("panel", logo_sb)
	brand_row.add_child(logo)
	var logo_center := CenterContainer.new()
	logo_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.add_child(logo_center)
	logo_center.add_child(MiuixIcon.new("rail", Color(1, 1, 1, 0.98), 22))

	var brand_col := VBoxContainer.new()
	brand_col.alignment = BoxContainer.ALIGNMENT_CENTER
	brand_col.add_theme_constant_override("separation", 1)
	brand_row.add_child(brand_col)
	var brand_en := Label.new()
	brand_en.text = Brand.NAME_EN
	brand_en.add_theme_font_override("font", Brand.wordmark_font())
	brand_en.add_theme_font_size_override("font_size", 15)
	brand_en.add_theme_color_override("font_color", TEXT_MAIN)
	brand_col.add_child(brand_en)
	var brand_cn := Label.new()
	brand_cn.text = "%s  ·  %s" %[Brand.NAME_CN, Brand.TAGLINE_CN]
	brand_cn.add_theme_font_size_override("font_size", 10)
	brand_cn.add_theme_color_override("font_color", TEXT_MUTED)
	brand_col.add_child(brand_cn)

	var title := Label.new()
	title.text = "正在进入驾驶室"
	title.position = Vector2(104, 162)
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", TEXT_MAIN)
	root.add_child(title)

	var sub := Label.new()
	sub.text = "线路、城镇与列车正在准备中"
	sub.position = Vector2(108, 224)
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_color_override("font_color", TEXT_DIM)
	root.add_child(sub)

	var panel := PanelContainer.new()
	panel.position = Vector2(104, 296)
	panel.custom_minimum_size = Vector2(700, 184)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.065, 0.068, 0.078, 0.96)
	style.border_color = Color(0, 0, 0, 0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(28)
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.0
	style.corner_detail = 20
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 20
	style.shadow_offset = Vector2(0, 9)
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	box.add_child(head)
	spinner = Spinner.new()
	head.add_child(spinner)
	status_label = Label.new()
	status_label.text = "正在准备世界"
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", TEXT_DIM)
	head.add_child(status_label)
	percent_label = Label.new()
	percent_label.text = "0%"
	percent_label.custom_minimum_size = Vector2(48, 0)
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	percent_label.add_theme_font_override("font", Brand.display_font())
	percent_label.add_theme_font_size_override("font_size", 14)
	percent_label.add_theme_color_override("font_color", Color(0.62, 0.78, 1.0))
	head.add_child(percent_label)

	bar = ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 0.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(648, 6)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ACCENT
	fill.set_corner_radius_all(3)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(1.0, 1.0, 1.0, 0.075)
	background.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", background)
	box.add_child(bar)

	_tip_label = Label.new()
	_tip_label.text = TIPS[0]
	_tip_label.add_theme_font_size_override("font_size", 12)
	_tip_label.add_theme_color_override("font_color", TEXT_MUTED)
	box.add_child(_tip_label)

	var tip := Label.new()
	tip.text = "首次进入可能需要几十秒，请稍候"
	tip.add_theme_font_size_override("font_size", 11)
	tip.add_theme_color_override("font_color", Color(0.33, 0.35, 0.39))
	box.add_child(tip)

	rail = LoadingRail.new()
	rail.name = "LoadingRail"
	rail.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	rail.offset_left = 64
	rail.offset_right = -64
	rail.offset_top = -150
	rail.offset_bottom = -20
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(rail)

	var ver := Label.new()
	ver.text = "%s  v%s" %[Brand.NAME_EN, Brand.VERSION]
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.offset_left = -300.0
	ver.offset_top = -42.0
	ver.offset_right = -104.0
	ver.offset_bottom = -16.0
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ver.add_theme_font_override("font", Brand.display_font())
	ver.add_theme_font_size_override("font_size", 12)
	ver.add_theme_color_override("font_color", TEXT_MUTED)
	root.add_child(ver)

	root.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(root, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE)
	set_process(true)


func _radial_texture(center: Color, mid: Color, edge: Color) -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.48, 1.0])
	grad.colors = PackedColorArray([center, mid, edge])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 512
	tex.height = 512
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex


func _process(delta: float) -> void:
	_shown = lerpf(_shown, _target, clampf(delta * 3.0, 0.0, 1.0))
	bar.value = _shown * 100.0
	percent_label.text = "%d%%" %int(round(_shown * 100.0))
	_tip_clock += delta
	if _tip_clock > 4.0:
		_tip_clock = 0.0
		_tip_index = (_tip_index + 1) % TIPS.size()
		_tip_label.text = TIPS[_tip_index]


func set_progress(value: float, text: String = "") -> void:
	_target = clampf(value, 0.0, 1.0)
	if _target >= 0.999:
		_shown = 1.0
		bar.value = 100.0
		percent_label.text = "100%"
	if text != "":
		status_label.text = text


func close() -> void:
	var tw := create_tween()
	tw.tween_property(root, "modulate:a", 0.0, 0.42).set_trans(Tween.TRANS_SINE)
	await tw.finished
	queue_free()
