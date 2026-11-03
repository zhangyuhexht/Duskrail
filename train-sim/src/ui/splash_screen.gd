extends CanvasLayer
class_name SplashScreen


signal finished

const Brand = preload("res://src/core/brand.gd")
const SplashFXScript = preload("res://src/ui/splash_fx.gd")
const SpinnerScript = preload("res://src/ui/miuix_spinner.gd")
const STUDIO_LOGO = preload("res://src/ui/assets/studio_avatar.jpg")

const TEXT_MAIN := Color(0.957, 0.965, 0.976)
const TEXT_DIM := Color(0.680, 0.700, 0.740)
const TEXT_MUTED := Color(0.440, 0.460, 0.500)
const ACCENT := Color(0.204, 0.510, 1.0)
const BRAND_ORANGE := Color(1.0, 0.455, 0.145)
const STUDIO_NAME := "zhangyuhexht studio"
const STUDIO_HOLD := 1.25
const LOADING_TIME := 4.8

var _done := false
var _fading := false
var _phase := "boot"
var _fade: ColorRect
var _bg: MenuBackground
var _fx
var _logo_layer: Control
var _studio_logo: TextureRect
var _studio_name: HBoxContainer
var _studio_letters: Array = []
var _studio_underline: ColorRect
var _title_layer: Control
var _wordmark: Label3D
var _wordmark_view: SubViewport
var _title_rule: ColorRect
var _subline: HBoxContainer
var _loading_layer: Control


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_base()
	_build_logo_phase()
	_build_title_phase()
	_build_loading()
	_build_fade()
	_run_sequence()


func _build_base() -> void:
	var base := ColorRect.new()
	base.color = Color(0.0, 0.0, 0.0, 1.0)
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)

	_bg = MenuBackground.new()
	_bg.name = "SplashBackground"
	_bg.modulate.a = 0.0
	add_child(_bg)

	_fx = SplashFXScript.new()
	_fx.name = "SplashFX"
	_fx.modulate.a = 0.0
	add_child(_fx)

	var vignette := TextureRect.new()
	vignette.texture = _radial_texture(
			Color(0, 0, 0, 0.0),
			Color(0, 0, 0, 0.05),
			Color(0, 0, 0, 0.62))
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)


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


func _build_logo_phase() -> void:
	_logo_layer = Control.new()
	_logo_layer.name = "StudioIntro"
	_logo_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_logo_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_logo_layer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -70.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo_layer.add_child(center)

	var stack := Control.new()
	stack.custom_minimum_size = Vector2(560, 430)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(stack)

	var glow := TextureRect.new()
	glow.texture = _radial_texture(
			Color(0.10, 0.52, 0.95, 0.30),
			Color(0.06, 0.22, 0.55, 0.08),
			Color(0.0, 0.0, 0.0, 0.0))
	glow.position = Vector2(0, -65)
	glow.size = Vector2(520, 520)
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(glow)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(box)

	_studio_logo = TextureRect.new()
	_studio_logo.texture = STUDIO_LOGO
	_studio_logo.custom_minimum_size = Vector2(280, 280)
	_studio_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_studio_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_studio_logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_studio_logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_studio_logo.modulate.a = 0.0
	_studio_logo.scale = Vector2(0.92, 0.92)
	_studio_logo.pivot_offset = Vector2(140, 140)
	_studio_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_studio_logo)

	var name_gap := Control.new()
	name_gap.custom_minimum_size = Vector2(0, 2)
	box.add_child(name_gap)

	_studio_name = HBoxContainer.new()
	_studio_name.alignment = BoxContainer.ALIGNMENT_CENTER
	_studio_name.add_theme_constant_override("separation", 1)
	_studio_name.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_studio_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_studio_name)

	var font := Brand.display_font()
	var studio_start := STUDIO_NAME.find("studio")
	for i in range(STUDIO_NAME.length()):
		var ch := STUDIO_NAME.substr(i, 1)
		var width := 6.0
		if ch != " ":
			width = maxf(5.0, font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 42).x + 1.0)
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(width, 56)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.modulate.a = 0.0
		var letter := Label.new()
		letter.text = ch
		letter.add_theme_font_override("font", font)
		letter.add_theme_font_size_override("font_size", 42)
		letter.add_theme_color_override("font_color",
				BRAND_ORANGE if i >= studio_start else Color(0.86, 0.89, 0.94))
		letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		letter.size = Vector2(width, 50)
		letter.position = Vector2(0, 3)
		letter.pivot_offset = Vector2(width * 0.5, 25.0)
		letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(letter)
		_studio_name.add_child(holder)
		_studio_letters.append({"holder": holder, "label": letter})

	var underline_gap := Control.new()
	underline_gap.custom_minimum_size = Vector2(0, 8)
	box.add_child(underline_gap)

	_studio_underline = ColorRect.new()
	_studio_underline.color = BRAND_ORANGE
	_studio_underline.custom_minimum_size = Vector2(0, 2)
	_studio_underline.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_studio_underline.modulate.a = 0.0
	_studio_underline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_studio_underline)


func _build_title_phase() -> void:
	_title_layer = Control.new()
	_title_layer.name = "GameTitle"
	_title_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_layer.modulate.a = 0.0
	_title_layer.visible = false
	_title_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title_layer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -70.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_layer.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(box)

	_wordmark_view = SubViewport.new()
	_wordmark_view.size = Vector2i(1600, 240)
	_wordmark_view.transparent_bg = true
	_wordmark_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.15
	camera.position = Vector3(0, 0, 3.0)
	camera.current = true
	_wordmark_view.add_child(camera)

	_wordmark = Label3D.new()
	_wordmark.text = Brand.NAME_EN
	_wordmark.font = Brand.wordmark_font()
	_wordmark.font_size = 128
	_wordmark.pixel_size = 0.0062
	_wordmark.width = 1000.0
	_wordmark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wordmark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_wordmark.modulate = Color(0.965, 0.972, 0.985, 1.0)
	_wordmark.outline_modulate = Color(0.0, 0.0, 0.0, 0.72)
	_wordmark.outline_size = 18
	_wordmark.no_depth_test = true
	_wordmark.double_sided = false
	_wordmark.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_wordmark.rotation_degrees = Vector3(10.0, -125.0, 0.0)
	_wordmark_view.add_child(_wordmark)

	var view := SubViewportContainer.new()
	view.custom_minimum_size = Vector2(1280, 192)
	view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	view.stretch = true
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(_wordmark_view)
	box.add_child(view)

	var rule_gap := Control.new()
	rule_gap.custom_minimum_size = Vector2(0, 8)
	box.add_child(rule_gap)

	_title_rule = ColorRect.new()
	_title_rule.color = BRAND_ORANGE
	_title_rule.custom_minimum_size = Vector2(0, 3)
	_title_rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_title_rule.modulate.a = 0.0
	_title_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_title_rule)

	var sub_gap := Control.new()
	sub_gap.custom_minimum_size = Vector2(0, 10)
	box.add_child(sub_gap)

	_subline = HBoxContainer.new()
	_subline.alignment = BoxContainer.ALIGNMENT_CENTER
	_subline.add_theme_constant_override("separation", 11)
	_subline.modulate.a = 0.0
	_subline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_subline)

	var cn := Label.new()
	cn.text = Brand.NAME_CN
	cn.add_theme_font_size_override("font_size", 20)
	cn.add_theme_color_override("font_color", TEXT_DIM)
	_subline.add_child(cn)

	var slash := Label.new()
	slash.text = "/"
	slash.add_theme_font_size_override("font_size", 14)
	slash.add_theme_color_override("font_color", TEXT_MUTED)
	_subline.add_child(slash)

	var en := Label.new()
	en.text = Brand.TAGLINE_CN
	en.add_theme_font_override("font", Brand.cjk_font())
	en.add_theme_font_size_override("font_size", 13)
	en.add_theme_color_override("font_color", TEXT_MUTED)
	_subline.add_child(en)


func _build_loading() -> void:
	_loading_layer = Control.new()
	_loading_layer.name = "LoadingOverlay"
	_loading_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading_layer.modulate.a = 0.0
	_loading_layer.visible = false
	_loading_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_loading_layer)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	row.offset_left = 104.0
	row.offset_top = -66.0
	row.offset_right = 420.0
	row.offset_bottom = -36.0
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_layer.add_child(row)

	var spinner = SpinnerScript.new(Color(0.55, 0.75, 1.0), 20.0)
	row.add_child(spinner)

	var label := Label.new()
	label.text = "Loading"
	label.add_theme_font_override("font", Brand.display_font())
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.82))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var skip := Label.new()
	skip.text = "按任意键跳过"
	skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip.offset_left = -300.0
	skip.offset_top = -62.0
	skip.offset_right = -104.0
	skip.offset_bottom = -40.0
	skip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skip.add_theme_font_size_override("font_size", 11)
	skip.add_theme_color_override("font_color", TEXT_MUTED)
	_loading_layer.add_child(skip)

	var ver := Label.new()
	ver.text = "%s  v%s" %[Brand.NAME_EN, Brand.VERSION]
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.offset_left = -300.0
	ver.offset_top = -36.0
	ver.offset_right = -104.0
	ver.offset_bottom = -16.0
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ver.add_theme_font_override("font", Brand.display_font())
	ver.add_theme_font_size_override("font_size", 10)
	ver.add_theme_color_override("font_color", Color(0.34, 0.37, 0.42))
	_loading_layer.add_child(ver)


func _build_fade() -> void:
	_fade = ColorRect.new()
	_fade.color = Color(0.0, 0.0, 0.0, 1.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func _run_sequence() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.15).timeout
	_phase = "logo"
	print("[splash] logo reveal")
	var reveal := create_tween().set_parallel(true)
	reveal.tween_property(_fade, "color:a", 0.0, 0.45)
	reveal.tween_property(_studio_logo, "modulate:a", 1.0, 0.55)
	reveal.tween_property(_studio_logo, "scale", Vector2.ONE, 0.75) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await reveal.finished
	print("[splash] studio name")
	await _reveal_studio_name()
	var underline := create_tween()
	underline.tween_property(_studio_underline, "custom_minimum_size:x", 420.0, 0.55) \
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	underline.parallel().tween_property(_studio_underline, "modulate:a", 1.0, 0.30)
	await underline.finished
	print("[splash] hold")
	await get_tree().create_timer(STUDIO_HOLD).timeout
	var out := create_tween()
	out.tween_property(_logo_layer, "modulate:a", 0.0, 0.55)
	await out.finished
	var cover := create_tween()
	cover.tween_property(_fade, "color:a", 1.0, 0.22)
	await cover.finished
	print("[splash] title phase")
	_logo_layer.visible = false
	_start_title_phase()


func _reveal_studio_name() -> void:
	var base_pos := Vector2(0, 3)
	var total := 0.0
	for i in range(_studio_letters.size()):
		var item: Dictionary = _studio_letters[i]
		var holder: Control = item["holder"]
		var letter: Label = item["label"]
		var style := i % 6
		var start_pos := base_pos
		var start_scale := Vector2.ONE
		var start_rot := 0.0
		var trans := Tween.TRANS_BACK
		match style:
			0:
				start_pos = base_pos + Vector2(0, 28)
				start_scale = Vector2(0.55, 0.55)
				start_rot = -0.18
			1:
				start_pos = base_pos - Vector2(0, 28)
				start_scale = Vector2(0.55, 0.55)
				start_rot = 0.18
			2:
				start_pos = base_pos + Vector2(-48, 0)
				start_scale = Vector2(0.82, 0.82)
				start_rot = -0.28
			3:
				start_pos = base_pos + Vector2(48, 0)
				start_scale = Vector2(0.82, 0.82)
				start_rot = 0.28
			4:
				start_scale = Vector2(0.18, 0.18)
				start_rot = -0.55
			5:
				start_scale = Vector2(0.04, 1.0)
				start_rot = 0.35
				trans = Tween.TRANS_CUBIC
		letter.position = start_pos
		letter.scale = start_scale
		letter.rotation = start_rot
		holder.modulate.a = 0.0
		var delay := 0.045 * float(i)
		var duration := 0.52
		var tw := create_tween()
		tw.tween_interval(delay)
		tw.tween_property(holder, "modulate:a", 1.0, 0.20)
		tw.parallel().tween_property(letter, "position", base_pos, duration) \
				.set_trans(trans).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(letter, "scale", Vector2.ONE, duration) \
				.set_trans(trans).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(letter, "rotation", 0.0, duration) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		total = maxf(total, delay + duration)
	await get_tree().create_timer(total + 0.05).timeout


func _start_title_phase() -> void:
	_phase = "title"
	_title_layer.visible = true
	_loading_layer.visible = true
	_title_layer.modulate.a = 0.0
	_loading_layer.modulate.a = 0.0
	_bg.modulate.a = 0.0
	_fx.modulate.a = 0.0
	_wordmark.rotation_degrees = Vector3(10.0, -125.0, 0.0)
	_title_rule.custom_minimum_size = Vector2(0, 3)
	_title_rule.modulate.a = 0.0
	_subline.modulate.a = 0.0

	var reveal := create_tween().set_parallel(true)
	reveal.tween_property(_fade, "color:a", 0.0, 0.45)
	reveal.tween_property(_bg, "modulate:a", 1.0, 0.85)
	reveal.tween_property(_fx, "modulate:a", 1.0, 0.85)
	reveal.tween_property(_title_layer, "modulate:a", 1.0, 0.55)

	var word := create_tween()
	word.tween_property(_wordmark, "rotation_degrees", Vector3.ZERO, 1.5) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var rule := create_tween()
	rule.tween_interval(0.15)
	rule.tween_property(_title_rule, "modulate:a", 1.0, 0.20)
	rule.parallel().tween_property(_title_rule, "custom_minimum_size:x", 260.0, 1.0) \
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	var sub := create_tween()
	sub.tween_interval(0.55)
	sub.tween_property(_subline, "modulate:a", 1.0, 0.45)

	var loading := create_tween()
	loading.tween_interval(0.45)
	loading.tween_property(_loading_layer, "modulate:a", 1.0, 0.40)

	var burst := create_tween()
	burst.tween_interval(0.35)
	burst.tween_callback(func() -> void:
		if _fx != null:
			_fx.burst())

	await get_tree().create_timer(LOADING_TIME).timeout
	_begin_exit(0.50)


func _unhandled_input(event: InputEvent) -> void:
	if _done or _fading or _phase != "title":
		return
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed():
			get_viewport().set_input_as_handled()
			_begin_exit(0.22)


func _begin_exit(duration: float) -> void:
	if _done or _fading:
		return
	_fading = true
	print("[splash] exit")
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, duration)
	tw.tween_callback(_complete)


func _complete() -> void:
	if _done:
		return
	_done = true
	print("[splash] complete")
	finished.emit()
	queue_free()


func skip_warning() -> void:
	# The photosensitivity notice moved to the Windows installer.
	pass
