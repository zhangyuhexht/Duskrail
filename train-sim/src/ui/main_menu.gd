extends CanvasLayer
class_name MainMenu

const Brand = preload("res://src/core/brand.gd")


signal play_requested(slot_id: String, save_name: String, state: Dictionary)

const ACCENT := Color(0.204, 0.510, 1.0)
const ACCENT_HOVER := Color(0.294, 0.576, 1.0)
const ACCENT_PRESSED := Color(0.137, 0.376, 0.812)
const BRAND_ORANGE := Color(1.0, 0.455, 0.145)
const TEXT_MAIN := Color(0.957, 0.965, 0.976)
const TEXT_DIM := Color(0.620, 0.640, 0.680)
const TEXT_MUTED := Color(0.430, 0.450, 0.490)
const CARD_BG := Color(0.098, 0.105, 0.118, 0.90)
const CARD_HOVER := Color(0.130, 0.140, 0.155, 0.96)
const CARD_PRESSED := Color(0.080, 0.086, 0.097, 0.98)
const LINE_COLOR := Color(1.0, 1.0, 1.0, 0.065)

var version := "0.1.0"

var _box: VBoxContainer
var _panel: PanelContainer
var _menu_wrap: MarginContainer
var _title_block: Control
var _settings: SettingsPanel
var _toast_label: Label
var _toast_time := 0.0
var _title_was_visible := true
var _confirm_dim: ColorRect
var _confirm_center: CenterContainer
var _confirm_text: Label
var _pending_delete := ""
var _pending_delete_name := ""
var _transitioning := false
var _view := "main"
var _view_arg: Variant = null
var _confirm_panel: PanelContainer
var _new_mode := "career"
var _queued_view := ""
var _queued_arg: Variant = null
var _mode_buttons: Dictionary = {}
var _menu_row: HBoxContainer
var _route_card: PanelContainer

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _build() -> void:
	var bg := MenuBackground.new()
	bg.name = "MenuBackground"
	add_child(bg)

	var glow := TextureRect.new()
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
	grad.colors = PackedColorArray([
		Color(0.20, 0.44, 0.95, 0.14),
		Color(0.15, 0.33, 0.76, 0.055),
		Color(0.10, 0.20, 0.50, 0.0),
	])
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.width = 512
	grad_tex.height = 512
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(0.94, 0.5)
	glow.texture = grad_tex
	glow.position = Vector2(-300.0, -190.0)
	glow.size = Vector2(1360.0, 1080.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.13)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	# Cinematic vignette so the landscape falls away at the edges.
	var vignette := TextureRect.new()
	var vgrad := Gradient.new()
	vgrad.offsets = PackedFloat32Array([0.0, 0.58, 1.0])
	vgrad.colors = PackedColorArray([
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.0, 0.0, 0.0, 0.0),
		Color(0.0, 0.0, 0.0, 0.46),
	])
	var vtex := GradientTexture2D.new()
	vtex.gradient = vgrad
	vtex.width = 512
	vtex.height = 512
	vtex.fill = GradientTexture2D.FILL_RADIAL
	vtex.fill_from = Vector2(0.5, 0.5)
	vtex.fill_to = Vector2(1.05, 1.05)
	vignette.texture = vtex
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	_title_block = VBoxContainer.new()
	_title_block.anchor_left = 0.0
	_title_block.anchor_right = 0.0
	_title_block.anchor_top = 0.0
	_title_block.anchor_bottom = 0.0
	_title_block.offset_left = 104.0
	_title_block.offset_top = 100.0
	_title_block.offset_right = 1000.0
	_title_block.offset_bottom = 456.0
	_title_block.add_theme_constant_override("separation", 0)
	add_child(_title_block)
	_build_hero()

	var chip := PanelContainer.new()
	chip.anchor_left = 1.0
	chip.anchor_right = 1.0
	chip.anchor_top = 0.0
	chip.anchor_bottom = 0.0
	chip.offset_left = -248.0
	chip.offset_right = -104.0
	chip.offset_top = 56.0
	chip.offset_bottom = 100.0
	chip.add_theme_stylebox_override("panel",
			_surface(Color(0.075, 0.080, 0.092, 0.76), Color(1, 1, 1, 0.08), 18, 14, 7))
	add_child(chip)
	var chip_label := Label.new()
	chip_label.text = "WINDOWS  ·  v%s" %version
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip_label.add_theme_font_size_override("font_size", 12)
	chip_label.add_theme_color_override("font_color", Color(0.66, 0.68, 0.72))
	chip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(chip_label)

	_menu_wrap = MarginContainer.new()
	_menu_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_wrap.offset_left = 104.0
	_menu_wrap.offset_top = 176.0
	_menu_wrap.offset_right = -104.0
	_menu_wrap.offset_bottom = -64.0
	add_child(_menu_wrap)

	_menu_row = HBoxContainer.new()
	_menu_row.alignment = BoxContainer.ALIGNMENT_END
	_menu_row.add_theme_constant_override("separation", 0)
	_menu_wrap.add_child(_menu_row)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _glass_style())
	_panel.custom_minimum_size = Vector2(470, 0)
	_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_menu_row.add_child(_panel)

	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 12)
	_panel.add_child(_box)

	_route_card = PanelContainer.new()
	_route_card.anchor_left = 0.0
	_route_card.anchor_right = 0.0
	_route_card.anchor_top = 1.0
	_route_card.anchor_bottom = 1.0
	_route_card.offset_left = 104.0
	_route_card.offset_right = 548.0
	_route_card.offset_top = -208.0
	_route_card.offset_bottom = -86.0
	_route_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var route_style := _surface(Color(0.055, 0.065, 0.082, 0.64), Color(1, 1, 1, 0.07), 20, 20, 14)
	route_style.shadow_color = Color(0, 0, 0, 0.26)
	route_style.shadow_size = 18
	route_style.shadow_offset = Vector2(0, 8)
	_route_card.add_theme_stylebox_override("panel", route_style)
	add_child(_route_card)
	var route_box := VBoxContainer.new()
	route_box.add_theme_constant_override("separation", 4)
	_route_card.add_child(route_box)
	var route_head := HBoxContainer.new()
	route_head.add_theme_constant_override("separation", 8)
	route_box.add_child(route_head)
	var route_chip := Label.new()
	route_chip.text = "CURRENT LINE"
	route_chip.add_theme_font_override("font", Brand.display_font())
	route_chip.add_theme_font_size_override("font_size", 10)
	route_chip.add_theme_color_override("font_color", Color(0.48, 0.70, 1.0))
	route_head.add_child(route_chip)
	var route_name := Label.new()
	route_name.text = "山川环线"
	route_name.add_theme_font_size_override("font_size", 19)
	route_name.add_theme_color_override("font_color", TEXT_MAIN)
	route_head.add_child(route_name)
	var route_meta := Label.new()
	route_meta.text = "28.52 km    ·    7 座车站    ·    3 座高架桥    ·    东环支线"
	route_meta.add_theme_font_size_override("font_size", 11)
	route_meta.add_theme_color_override("font_color", TEXT_MUTED)
	route_box.add_child(route_meta)
	var route_hint := Label.new()
	route_hint.text = "黄昏之后，线路上的灯会一盏盏亮起。"
	route_hint.add_theme_font_size_override("font_size", 11)
	route_hint.add_theme_color_override("font_color", Color(0.56, 0.60, 0.66))
	route_box.add_child(route_hint)

	_settings = SettingsPanel.new()
	_settings.name = "SettingsPanel"
	add_child(_settings)
	_settings.closed.connect(_on_settings_closed)

	_toast_label = Label.new()
	_toast_label.anchor_left = 0.5
	_toast_label.anchor_right = 0.5
	_toast_label.anchor_top = 1.0
	_toast_label.anchor_bottom = 1.0
	_toast_label.offset_left = -330.0
	_toast_label.offset_right = 330.0
	_toast_label.offset_top = -128.0
	_toast_label.offset_bottom = -82.0
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 17)
	_toast_label.add_theme_color_override("font_color", Color(0.82, 0.90, 1.0))
	_toast_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.08, 0.95))
	_toast_label.add_theme_constant_override("outline_size", 7)
	_toast_label.modulate.a = 0.0
	add_child(_toast_label)

	var ver := Label.new()
	var vi := Engine.get_version_info()
	ver.text = "v%s   ·   GODOT %d.%d" %[version, int(vi.get("major", 4)), int(vi.get("minor", 0))]
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.offset_left = -360.0
	ver.offset_top = -40.0
	ver.offset_right = -104.0
	ver.offset_bottom = -16.0
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ver.add_theme_font_size_override("font_size", 12)
	ver.add_theme_color_override("font_color", TEXT_MUTED)
	add_child(ver)

	var keys := Label.new()
	keys.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	keys.offset_left = 104.0
	keys.offset_top = -40.0
	keys.offset_right = 520.0
	keys.offset_bottom = -16.0
	keys.text = "Enter 选择    ↑ ↓ 移动    Esc 返回"
	keys.add_theme_font_size_override("font_size", 12)
	keys.add_theme_color_override("font_color", TEXT_MUTED)
	add_child(keys)

	_build_confirm()

	_show_main()

func _build_hero() -> void:
	var brand_row := HBoxContainer.new()
	brand_row.add_theme_constant_override("separation", 16)
	_title_block.add_child(brand_row)

	var logo := PanelContainer.new()
	logo.custom_minimum_size = Vector2(54, 54)
	logo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	logo.add_theme_stylebox_override("panel", _brand_style())
	brand_row.add_child(logo)
	var logo_center := CenterContainer.new()
	logo_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.add_child(logo_center)
	logo_center.add_child(MiuixIcon.new("rail", Color(1, 1, 1, 0.96), 28))

	var brand_col := VBoxContainer.new()
	brand_col.alignment = BoxContainer.ALIGNMENT_CENTER
	brand_col.add_theme_constant_override("separation", 1)
	brand_row.add_child(brand_col)
	var brand_en := Label.new()
	brand_en.text = Brand.STUDIO
	brand_en.add_theme_font_override("font", Brand.display_font())
	brand_en.add_theme_font_size_override("font_size", 13)
	brand_en.add_theme_color_override("font_color", Color(0.80, 0.82, 0.86))
	brand_col.add_child(brand_en)
	var brand_cn := Label.new()
	brand_cn.text = "%s  ·  %s" %[Brand.NAME_CN, Brand.TAGLINE_CN]
	brand_cn.add_theme_font_size_override("font_size", 12)
	brand_cn.add_theme_color_override("font_color", TEXT_MUTED)
	brand_col.add_child(brand_cn)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 28)
	_title_block.add_child(gap)

	var title := Label.new()
	title.text = Brand.NAME_EN
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_override("font", Brand.wordmark_font())
	title.add_theme_font_size_override("font_size", 92)
	title.add_theme_color_override("font_color", TEXT_MAIN)
	title.add_theme_color_override("font_outline_color", Color(0.01, 0.03, 0.06, 0.55))
	title.add_theme_constant_override("outline_size", 3)
	_title_block.add_child(title)

	var title_gap := Control.new()
	title_gap.custom_minimum_size = Vector2(0, 10)
	_title_block.add_child(title_gap)

	var rule_row := HBoxContainer.new()
	rule_row.add_theme_constant_override("separation", 12)
	_title_block.add_child(rule_row)
	var rule := ColorRect.new()
	rule.color = BRAND_ORANGE
	rule.custom_minimum_size = Vector2(32, 3)
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule_row.add_child(rule)
	var rule_text := Label.new()
	rule_text.text = "暮色运输线   /   重载运输作业"
	rule_text.add_theme_font_size_override("font_size", 13)
	rule_text.add_theme_color_override("font_color", Color(0.62, 0.64, 0.69))
	rule_row.add_child(rule_text)

	var tag_gap := Control.new()
	tag_gap.custom_minimum_size = Vector2(0, 9)
	_title_block.add_child(tag_gap)

	var tag := Label.new()
	tag.text = "驾驶重载列车，穿行于暮色中的铁路网。"
	tag.add_theme_font_size_override("font_size", 17)
	tag.add_theme_color_override("font_color", Color(0.70, 0.72, 0.76))
	_title_block.add_child(tag)

	var stats_gap := Control.new()
	stats_gap.custom_minimum_size = Vector2(0, 30)
	_title_block.add_child(stats_gap)
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 10)
	_title_block.add_child(stats_row)
	for spec: Array in [["28.52", "km 环线"], ["7", "座车站"], ["1", "条支线"]]:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(166, 62)
		card.add_theme_stylebox_override("panel",
				_surface(Color(0.055, 0.065, 0.082, 0.58), Color(1, 1, 1, 0.07), 16, 16, 10))
		stats_row.add_child(card)
		var stats_box := VBoxContainer.new()
		stats_box.add_theme_constant_override("separation", 0)
		card.add_child(stats_box)
		var value := Label.new()
		value.text = String(spec[0])
		value.add_theme_font_override("font", Brand.display_font())
		value.add_theme_font_size_override("font_size", 24)
		value.add_theme_color_override("font_color", Color(0.92, 0.95, 0.99))
		stats_box.add_child(value)
		var label := Label.new()
		label.text = String(spec[1])
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", TEXT_MUTED)
		stats_box.add_child(label)

func _build_confirm() -> void:
	_confirm_dim = ColorRect.new()
	_confirm_dim.color = Color(0.0, 0.0, 0.0, 0.66)
	_confirm_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_dim.visible = false
	add_child(_confirm_dim)

	_confirm_center = CenterContainer.new()
	_confirm_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm_center.visible = false
	add_child(_confirm_center)

	_confirm_panel = PanelContainer.new()
	_confirm_panel.custom_minimum_size = Vector2(460, 0)
	_confirm_panel.add_theme_stylebox_override("panel", _panel_style())
	_confirm_center.add_child(_confirm_panel)
	var panel := _confirm_panel

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 9)
	vb.add_child(title_row)
	title_row.add_child(MiuixIcon.new("warn", Color(1.0, 0.64, 0.30, 0.95), 22))
	var title := Label.new()
	title.text = "删除档案"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", TEXT_MAIN)
	title_row.add_child(title)

	var q := Label.new()
	q.text = "是否删除该档案？"
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.add_theme_font_size_override("font_size", 18)
	q.add_theme_color_override("font_color", Color(0.78, 0.84, 0.92))
	vb.add_child(q)

	_confirm_text = Label.new()
	_confirm_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_text.add_theme_font_size_override("font_size", 16)
	_confirm_text.add_theme_color_override("font_color", TEXT_DIM)
	vb.add_child(_confirm_text)

	var button_gap := Control.new()
	button_gap.custom_minimum_size = Vector2(0, 4)
	vb.add_child(button_gap)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row)
	var cancel := _card_button("取消", false)
	cancel.custom_minimum_size = Vector2(160, 50)
	cancel.pressed.connect(_hide_confirm)
	row.add_child(cancel)
	var del := _card_button("删除", true)
	del.custom_minimum_size = Vector2(160, 50)
	_style_danger_filled(del)
	del.pressed.connect(_do_delete)
	row.add_child(del)

func _show_confirm(id: String, save_name: String) -> void:
	_pending_delete = id
	_pending_delete_name = save_name
	_confirm_text.text = save_name
	_confirm_dim.visible = true
	_confirm_center.visible = true
	_confirm_dim.modulate.a = 0.0
	_confirm_panel.pivot_offset = _confirm_panel.size * 0.5
	_confirm_panel.scale = Vector2(0.92, 0.92)
	_confirm_panel.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_confirm_dim, "modulate:a", 1.0, 0.16)
	tw.tween_property(_confirm_panel, "modulate:a", 1.0, 0.18)
	tw.tween_property(_confirm_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _hide_confirm() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_confirm_dim, "modulate:a", 0.0, 0.12)
	tw.tween_property(_confirm_panel, "modulate:a", 0.0, 0.12)
	tw.tween_property(_confirm_panel, "scale", Vector2(0.94, 0.94), 0.12)
	await tw.finished
	_confirm_dim.visible = false
	_confirm_center.visible = false
	_pending_delete = ""

func _do_delete() -> void:
	if _pending_delete == "":
		return
	SaveManager.delete_save(_pending_delete)
	var nm := _pending_delete_name
	_hide_confirm()
	_show_saves()
	_toast("已删除档案：%s" %nm)

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
	sb.anti_aliasing_size = 1.0
	sb.corner_detail = 20
	return sb

func _glass_style() -> StyleBoxFlat:
	var sb := _surface(Color(0.060, 0.063, 0.072, 0.92), Color(1, 1, 1, 0.07), 30, 28, 26)
	sb.shadow_color = Color(0, 0, 0, 0.46)
	sb.shadow_size = 32
	sb.shadow_offset = Vector2(0, 14)
	return sb

func _brand_style() -> StyleBoxFlat:
	var sb := _surface(BRAND_ORANGE, Color(1.0, 0.76, 0.56, 0.38), 16, 0, 0)
	sb.shadow_color = Color(1.0, 0.34, 0.08, 0.30)
	sb.shadow_size = 16
	sb.shadow_offset = Vector2(0, 7)
	return sb

func _panel_style() -> StyleBoxFlat:
	return _glass_style()

func _transparent_panel_style() -> StyleBoxFlat:
	return _surface(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0)

func _apply_panel_chrome() -> void:
	_panel.add_theme_stylebox_override("panel", _glass_style())
	if _route_card != null:
		_route_card.visible = _title_block.visible
	if _title_block.visible:
		_menu_wrap.offset_top = 176.0
		_menu_wrap.offset_bottom = -64.0
		_menu_row.alignment = BoxContainer.ALIGNMENT_END
		_panel.custom_minimum_size = Vector2(470, 0)
		_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
		_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	else:
		_menu_wrap.offset_top = 86.0
		_menu_wrap.offset_bottom = -56.0
		_menu_row.alignment = BoxContainer.ALIGNMENT_CENTER
		_panel.custom_minimum_size = Vector2(680, 0)
		_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

func _style_button(b: Button, danger := false, primary := false) -> void:
	var normal_bg := ACCENT if primary else Color(0.105, 0.110, 0.125, 0.92)
	var hover_bg := ACCENT_HOVER if primary else CARD_HOVER
	var pressed_bg := ACCENT_PRESSED if primary else CARD_PRESSED
	if danger:
		normal_bg = Color(0.22, 0.085, 0.085, 0.72)
		hover_bg = Color(0.28, 0.105, 0.105, 0.86)
		pressed_bg = Color(0.17, 0.060, 0.060, 0.90)
	var normal_border := Color(1, 1, 1, 0.10) if primary else Color(1, 1, 1, 0.065)
	var hover_border := Color(1, 1, 1, 0.22) if primary else Color(1, 1, 1, 0.14)
	if danger:
		normal_border = Color(1.0, 0.42, 0.40, 0.24)
		hover_border = Color(1.0, 0.50, 0.47, 0.52)
	var focus := _surface(Color(1, 1, 1, 0.015),
			Color(1, 1, 1, 0.80) if primary else ACCENT.lightened(0.18), 16, 20, 12)
	focus.set_border_width_all(2)
	b.add_theme_stylebox_override("normal", _surface(normal_bg, normal_border, 16, 20, 16))
	b.add_theme_stylebox_override("hover", _surface(hover_bg, hover_border, 16, 20, 16))
	b.add_theme_stylebox_override("pressed", _surface(pressed_bg, hover_border, 16, 20, 16))
	b.add_theme_stylebox_override("disabled",
			_surface(Color(0.075, 0.079, 0.089, 0.78), Color(1, 1, 1, 0.045), 16, 20, 16))
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_color_override("font_color", Color(1.0, 0.72, 0.69) if danger else (Color.WHITE if primary else TEXT_MAIN))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.84, 0.82) if danger else Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color(1.0, 0.84, 0.82) if danger else Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.38, 0.40, 0.44))

func _style_danger_filled(b: Button) -> void:
	var normal := _surface(Color(0.855, 0.251, 0.235, 0.96), Color(1, 1, 1, 0.14), 16, 20, 14)
	var hover := _surface(Color(0.925, 0.310, 0.290, 1.0), Color(1, 1, 1, 0.22), 16, 20, 14)
	var pressed := _surface(Color(0.720, 0.180, 0.170, 1.0), Color(1, 1, 1, 0.12), 16, 20, 14)
	var focus := _surface(Color(1, 1, 1, 0.02), Color(1, 1, 1, 0.80), 16, 20, 14)
	focus.set_border_width_all(2)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)

func _style_soft_primary(b: Button) -> void:
	b.add_theme_stylebox_override("normal",
			_surface(Color(0.204, 0.510, 1.0, 0.14), Color(0.204, 0.510, 1.0, 0.26), 16, 16, 10))
	b.add_theme_stylebox_override("hover",
			_surface(Color(0.204, 0.510, 1.0, 0.24), Color(0.204, 0.510, 1.0, 0.42), 16, 16, 10))
	b.add_theme_stylebox_override("pressed",
			_surface(Color(0.204, 0.510, 1.0, 0.32), Color(0.204, 0.510, 1.0, 0.50), 16, 16, 10))
	var focus := _surface(Color(0.204, 0.510, 1.0, 0.05), Color(1, 1, 1, 0.78), 16, 16, 10)
	focus.set_border_width_all(2)
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_color_override("font_color", Color(0.66, 0.81, 1.0))
	b.add_theme_color_override("font_hover_color", Color(0.84, 0.91, 1.0))
	b.add_theme_color_override("font_focus_color", Color(0.84, 0.91, 1.0))

func _style_ghost_danger(b: Button) -> void:
	b.add_theme_stylebox_override("normal",
			_surface(Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0), 16, 16, 10))
	b.add_theme_stylebox_override("hover",
			_surface(Color(0.90, 0.28, 0.26, 0.12), Color(1.0, 0.42, 0.40, 0.20), 16, 16, 10))
	b.add_theme_stylebox_override("pressed",
			_surface(Color(0.80, 0.22, 0.20, 0.18), Color(1.0, 0.42, 0.40, 0.28), 16, 16, 10))
	var focus := _surface(Color(1, 1, 1, 0.02), Color(1, 1, 1, 0.70), 16, 16, 10)
	focus.set_border_width_all(2)
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_color_override("font_color", Color(0.98, 0.55, 0.52))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.73, 0.70))
	b.add_theme_color_override("font_focus_color", Color(1.0, 0.73, 0.70))

func _divider() -> ColorRect:
	var d := ColorRect.new()
	d.color = LINE_COLOR
	d.custom_minimum_size = Vector2(0, 1)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d

func _line_edit_style(focused := false) -> StyleBoxFlat:
	var border := ACCENT.lightened(0.12) if focused else Color(1, 1, 1, 0.09)
	var sb := _surface(Color(0.060, 0.063, 0.072, 0.94), border, 16, 18, 12)
	if focused:
		sb.set_border_width_all(2)
	return sb

func _clear() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()

func _header(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.add_theme_font_size_override("font_size", 32)
	l.add_theme_color_override("font_color", TEXT_MAIN)
	_box.add_child(l)
	_box.add_child(_divider())

func _add_button(text: String, cb: Callable, width := 520.0, primary := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 58)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 19)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_button(b, false, primary)
	b.pressed.connect(cb)
	b.mouse_entered.connect(func() -> void: _hover_button(b, true))
	b.mouse_exited.connect(func() -> void: _hover_button(b, false))
	_box.add_child(b)
	return b

func _main_button(title: String, subtitle: String, icon_kind: String, cb: Callable,
		opts: Dictionary = {}) -> Button:
	var primary := bool(opts.get("primary", false))
	var ghost := bool(opts.get("ghost", false))
	var grouped := bool(opts.get("grouped", false))
	var badge := String(opts.get("badge", ""))
	var parent: Container = opts.get("parent", _box) as Container

	var b := Button.new()
	b.text = ""
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		b.custom_minimum_size = Vector2(400, 82)
	elif grouped:
		b.custom_minimum_size = Vector2(400, 72)
	elif ghost:
		b.custom_minimum_size = Vector2(400, 56)
	else:
		b.custom_minimum_size = Vector2(400, 68)
	_style_main_button(b, primary, ghost, grouped)

	var content := MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("margin_left", 18 if ghost else 22)
	content.add_theme_constant_override("margin_right", 18 if ghost else 20)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(content)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(row)

	var icon_color := Color(1, 1, 1, 0.98) if primary else (Color(0.54, 0.56, 0.60) if ghost else Color(0.80, 0.82, 0.86))
	var glyph := MiuixIcon.new(icon_kind, icon_color, 22 if ghost else 24)
	row.add_child(glyph)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texts.add_theme_constant_override("separation", 2)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(texts)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 18 if ghost else (21 if primary else 19))
	title_label.add_theme_color_override("font_color",
			Color(0.64, 0.66, 0.70) if ghost else (Color(1, 1, 1) if primary else TEXT_MAIN))
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(title_label)

	if subtitle != "":
		var sub := Label.new()
		sub.text = subtitle
		sub.add_theme_font_size_override("font_size", 12)
		sub.add_theme_color_override("font_color",
				Color(1, 1, 1, 0.72) if primary else TEXT_DIM)
		sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texts.add_child(sub)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)

	if badge != "":
		var pill := PanelContainer.new()
		pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pill.add_theme_stylebox_override("panel",
				_surface(Color(0.204, 0.510, 1.0, 0.14), Color(0.204, 0.510, 1.0, 0.22), 11, 9, 4))
		var bl := Label.new()
		bl.text = badge
		bl.add_theme_font_size_override("font_size", 11)
		bl.add_theme_color_override("font_color", Color(0.64, 0.79, 1.0))
		bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pill.add_child(bl)
		row.add_child(pill)

	if not ghost:
		var chevron_color := Color(1, 1, 1, 0.76) if primary else Color(0.48, 0.50, 0.55)
		row.add_child(MiuixIcon.new("arrow", chevron_color, 18))

	b.pressed.connect(cb)
	b.mouse_entered.connect(func() -> void: _hover_main_button(b, true))
	b.mouse_exited.connect(func() -> void: _hover_main_button(b, false))
	parent.add_child(b)
	return b

func _main_group() -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := _surface(Color(0.105, 0.110, 0.123, 0.94), Color(0, 0, 0, 0), 28, 0, 0)
	sb.shadow_color = Color(0, 0, 0, 0.24)
	sb.shadow_size = 16
	sb.shadow_offset = Vector2(0, 7)
	sb.anti_aliasing_size = 3.0
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_meta("main_group", true)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	panel.add_child(rows)

	_main_button("设置与音频", "画面、音量、操作与无障碍", "settings", _on_settings,
			{"grouped": true, "parent": rows})
	rows.add_child(_row_divider())
	_main_button("操作说明", "WASD 驾驶 · V 视角 · E 上下车", "warn",
			func() -> void: _toast("WASD 驾驶 · V 切换视角 · E 上下车 · F5 地图模式 · M 大地图"),
			{"grouped": true, "parent": rows})
	return panel

func _row_divider() -> MarginContainer:
	var wrap := MarginContainer.new()
	wrap.add_theme_constant_override("margin_left", 22)
	wrap.add_theme_constant_override("margin_right", 20)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := ColorRect.new()
	line.color = Color(1, 1, 1, 0.055)
	line.custom_minimum_size = Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(line)
	return wrap

func _style_main_button(b: Button, primary: bool, ghost: bool, grouped := false) -> void:
	var normal: StyleBoxFlat
	var hover: StyleBoxFlat
	var pressed: StyleBoxFlat
	if primary:
		normal = _surface(ACCENT, Color(1, 1, 1, 0.12), 26, 0, 0)
		normal.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
		normal.shadow_size = 12
		normal.shadow_offset = Vector2(0, 5)
		hover = _surface(ACCENT_HOVER, Color(1, 1, 1, 0.22), 26, 0, 0)
		hover.shadow_color = Color(0.0, 0.0, 0.0, 0.26)
		hover.shadow_size = 14
		hover.shadow_offset = Vector2(0, 6)
		pressed = _surface(ACCENT_PRESSED, Color(1, 1, 1, 0.10), 26, 0, 0)
	elif grouped or ghost:
		normal = _surface(Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0), 18, 0, 0)
		hover = _surface(Color(1, 1, 1, 0.055), Color(1, 1, 1, 0.0), 18, 0, 0)
		pressed = _surface(Color(1, 1, 1, 0.085), Color(1, 1, 1, 0.0), 18, 0, 0)
	else:
		normal = _surface(CARD_BG, Color(1, 1, 1, 0.065), 26, 0, 0)
		normal.shadow_color = Color(0, 0, 0, 0.20)
		normal.shadow_size = 12
		normal.shadow_offset = Vector2(0, 5)
		hover = _surface(CARD_HOVER, Color(1, 1, 1, 0.15), 26, 0, 0)
		hover.shadow_color = Color(0, 0, 0, 0.26)
		hover.shadow_size = 16
		hover.shadow_offset = Vector2(0, 7)
		pressed = _surface(CARD_PRESSED, Color(1, 1, 1, 0.12), 26, 0, 0)
	var focus := _surface(Color(0.204, 0.510, 1.0, 0.035),
			Color(1, 1, 1, 0.80) if primary else ACCENT.lightened(0.16), 26 if not(grouped or ghost) else 18, 0, 0)
	focus.set_border_width_all(2)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_stylebox_override("disabled", _surface(Color(0.07, 0.074, 0.084, 0.7), Color(1, 1, 1, 0.04), 26, 0, 0))

func _hover_main_button(b: Button, on: bool) -> void:
	if not is_instance_valid(b):
		return
	b.pivot_offset = b.size * 0.5
	var tw := create_tween().set_parallel(true)
	tw.tween_property(b, "scale", Vector2(1.006, 1.006) if on else Vector2.ONE, 0.12)

func _switch_to(view: String, arg: Variant = null) -> void:
	if _transitioning:
		_queued_view = view
		_queued_arg = arg
		return
	_transitioning = true
	_view = view
	_view_arg = arg
	if _panel.visible and not _box.get_children().is_empty():
		var out := create_tween().set_parallel(true)
		out.tween_property(_panel, "modulate:a", 0.0, 0.09)
		out.tween_property(_panel, "scale", Vector2(0.985, 0.985), 0.09)
		out.tween_property(_title_block, "modulate:a", 0.0, 0.09)
		await out.finished
	_build_current()
	_apply_panel_chrome()
	_panel.visible = true
	await get_tree().process_frame
	_panel.pivot_offset = _panel.size * 0.5
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.972, 0.972)
	_title_block.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.2)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_title_block, "modulate:a", 1.0, 0.24)
	await tw.finished
	_animate_items()
	_transitioning = false
	_focus_first()
	if _queued_view != "":
		var qv := _queued_view
		var qa: Variant = _queued_arg
		_queued_view = ""
		_queued_arg = null
		_switch_to(qv, qa)

func _build_current() -> void:
	match _view:
		"single":
			_build_single()
		"saves":
			_build_saves()
		"new":
			_build_new()
		"settings":
			_build_main()
		_:
			_build_main()

func _animate_items() -> void:
	var i := 0
	for c in _box.get_children():
		if c is Button or (c is PanelContainer and c.has_meta("main_group")):
			_animate_in(c, i)
			i += 1
	var cards: Array = []
	for c in find_children("*", "PanelContainer", true, false):
		if c.has_meta("save_card"):
			cards.append(c)
	for j in range(cards.size()):
		_animate_in(cards[j], j)

func _animate_in(c: Control, index: int) -> void:
	c.pivot_offset = c.size * 0.5
	c.modulate.a = 0.0
	c.scale = Vector2(0.96, 0.96)
	var tw := create_tween()
	tw.tween_interval(0.025 * float(index))
	tw.set_parallel(true)
	tw.tween_property(c, "modulate:a", 1.0, 0.18)
	tw.tween_property(c, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _hover_button(b: Button, on: bool) -> void:
	if not is_instance_valid(b):
		return
	b.pivot_offset = b.size * 0.5
	var tw := create_tween()
	tw.tween_property(b, "scale", Vector2(1.02, 1.02) if on else Vector2.ONE, 0.1)

func _show_main() -> void:
	_switch_to("main")

func _section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", TEXT_DIM)
	return label

func _build_main() -> void:
	_panel.custom_minimum_size = Vector2(470, 0)
	_title_block.visible = true
	_clear()
	var last := SaveManager.last_or_latest()
	var data := SaveManager.read_save(last)
	_box.add_child(_section_label("旅程"))
	if data.is_empty():
		_main_button("开始新旅程", "从黄昏中的车站出发，自由驾驶", "play",
				_show_single, {"primary": true})
	else:
		_main_button("继续旅程", "读取最近的存档 · %s" %String(data.get("name", "存档")),
				"play", func() -> void: _play(data), {"primary": true})
	_box.add_child(_section_label("档案"))
	_main_button("新旅程 / 载入存档", "选择线路、模式与存档位置", "folder", _show_single, {})
	_box.add_child(_section_label("系统"))
	_box.add_child(_main_group())
	_main_button("退出游戏", "", "exit", func() -> void: get_tree().quit(), {"ghost": true})

func _show_single() -> void:
	_switch_to("single")

func _build_single() -> void:
	_panel.custom_minimum_size = Vector2(680, 0)
	_title_block.visible = false
	_clear()
	_header("单人游戏")
	var last := SaveManager.last_or_latest()
	var data := SaveManager.read_save(last)
	var cont_text := "继续游戏"
	if data.is_empty():
		cont_text = "继续游戏（暂无存档）"
	var cont := _add_button(cont_text, func() -> void: _play(data), 520.0, true)
	cont.disabled = data.is_empty()
	_add_button("加载存档", _show_saves)
	_add_button("新建存档", _show_new)
	_add_button("返回", _show_main)

func show_single() -> void:
	_show_single()

func _show_saves() -> void:
	_switch_to("saves")

func _build_saves() -> void:
	_panel.custom_minimum_size = Vector2(680, 0)
	_title_block.visible = false
	_clear()
	_header("加载存档")
	var saves := SaveManager.list_saves()
	if saves.is_empty():
		var empty := Label.new()
		empty.text = "暂无存档，请先新建存档。"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_color", TEXT_DIM)
		_box.add_child(empty)
	else:
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(600, 320)
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.follow_focus = true
		_box.add_child(scroll)
		var bar := scroll.get_v_scroll_bar()
		bar.custom_minimum_size = Vector2(6, 0)
		bar.add_theme_stylebox_override("scroll",
				_surface(Color(1, 1, 1, 0.035), Color(0, 0, 0, 0), 3, 1, 1))
		bar.add_theme_stylebox_override("scroll_focus",
				_surface(Color(1, 1, 1, 0.045), Color(0, 0, 0, 0), 3, 1, 1))
		bar.add_theme_stylebox_override("grabber",
				_surface(Color(1, 1, 1, 0.16), Color(0, 0, 0, 0), 3, 1, 1))
		bar.add_theme_stylebox_override("grabber_highlight",
				_surface(Color(0.52, 0.68, 0.94, 0.42), Color(0, 0, 0, 0), 3, 1, 1))
		bar.add_theme_stylebox_override("grabber_pressed",
				_surface(Color(0.204, 0.510, 1.0, 0.60), Color(0, 0, 0, 0), 3, 1, 1))
		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 10)
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(list)
		for s in saves:
			var card := _save_card(s)
			card.set_meta("save_card", true)
			list.add_child(card)
	_add_button("返回", _show_main)

func show_saves() -> void:
	_show_saves()

func _save_card(s: Dictionary) -> Control:
	var card := PanelContainer.new()
	var sb := _surface(Color(0.105, 0.110, 0.124, 0.94), Color(1, 1, 1, 0.055), 22, 18, 16)
	card.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	var glyph := MiuixIcon.new("folder", Color(0.46, 0.69, 0.98, 0.82), 24)
	row.add_child(glyph)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)
	var nm := Label.new()
	nm.text = String(s ["name"])
	nm.add_theme_font_size_override("font_size", 19)
	nm.add_theme_color_override("font_color", TEXT_MAIN)
	info.add_child(nm)
	var sm: Dictionary = s.get("summary", {})
	var save_mode := String(sm.get("mode", "open"))
	var mode_name := "生涯模式" if save_mode == "career" else ("测试模式" if save_mode == "test" else "开放模式")
	var det := Label.new()
	det.text = "%s   ·   %s Lv.%d" %[
		SaveManager.format_time(int(s ["timestamp"])), mode_name, int(sm.get("level", 1))
	]
	det.add_theme_font_size_override("font_size", 12)
	det.add_theme_color_override("font_color", TEXT_DIM)
	info.add_child(det)
	var det2 := Label.new()
	det2.text = "¥%d   ·   完成 %d 单   ·   里程 %.2f km   ·   档位 %s" %[
		int(sm.get("money", 0)), int(sm.get("completed", 0)),
		float(sm.get("distance", 0.0)) / 1000.0, String(sm.get("gear", "P3"))
	]
	det2.add_theme_font_size_override("font_size", 12)
	det2.add_theme_color_override("font_color", TEXT_MUTED)
	info.add_child(det2)
	var load := _card_button("载入", false)
	_style_soft_primary(load)
	load.pressed.connect(func() -> void: _play(SaveManager.read_save(String(s ["id"]))))
	row.add_child(load)
	var del := _card_button("删除", true)
	_style_ghost_danger(del)
	del.pressed.connect(func() -> void: _confirm_delete(String(s ["id"]), String(s ["name"])))
	row.add_child(del)
	return card

func _card_button(text: String, danger: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(92, 40)
	b.add_theme_font_size_override("font_size", 15)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_button(b, danger)
	b.mouse_entered.connect(func() -> void: _hover_button(b, true))
	b.mouse_exited.connect(func() -> void: _hover_button(b, false))
	return b

func _confirm_delete(id: String, save_name: String) -> void:
	_show_confirm(id, save_name)

func show_delete_confirm() -> void:
	_show_saves()
	var saves := SaveManager.list_saves()
	if not saves.is_empty():
		_confirm_delete(String(saves [0] ["id"]), String(saves [0] ["name"]))

func _show_new() -> void:
	_switch_to("new")

func _build_new() -> void:
	_title_block.visible = false
	_clear()
	_panel.custom_minimum_size = Vector2(680, 0)
	_header("新建存档")
	var mode_hint := Label.new()
	mode_hint.text = "选择游戏模式"
	mode_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	mode_hint.add_theme_color_override("font_color", TEXT_DIM)
	mode_hint.add_theme_font_size_override("font_size", 14)
	_box.add_child(mode_hint)
	_mode_buttons.clear()
	_mode_buttons ["career"] = _add_mode_button("career", "生涯模式",
			"快速任务、等级与车辆经营，从一台电力机车起步。")
	_mode_buttons ["open"] = _add_mode_button("open", "开放模式",
			"全部车辆与线路解锁，无限资金，自由驾驶。")
	_mode_buttons ["test"] = _add_mode_button("test", "测试模式",
			"长 S 急弯、95 米 180° 回头弯；专测转向架。")
	_set_new_mode(_new_mode)
	var hint := Label.new()
	hint.text = "档案名称"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hint.add_theme_color_override("font_color", TEXT_DIM)
	hint.add_theme_font_size_override("font_size", 14)
	_box.add_child(hint)
	var name_edit := LineEdit.new()
	name_edit.text = "新档案 %d" %(SaveManager.list_saves().size() + 1)
	name_edit.max_length = 24
	name_edit.custom_minimum_size = Vector2(520, 56)
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_edit.add_theme_font_size_override("font_size", 19)
	name_edit.add_theme_color_override("font_color", TEXT_MAIN)
	name_edit.add_theme_color_override("font_placeholder_color", Color(0.40, 0.42, 0.47))
	name_edit.add_theme_color_override("caret_color", ACCENT.lightened(0.18))
	name_edit.add_theme_stylebox_override("normal", _line_edit_style())
	name_edit.add_theme_stylebox_override("focus", _line_edit_style(true))
	name_edit.add_theme_stylebox_override("read_only", _line_edit_style())
	_box.add_child(name_edit)
	var create := _add_button("创建并开始", func() -> void:
		var nm := name_edit.text.strip_edges()
		if nm == "":
			nm = "新档案"
		var id := SaveManager.new_slot_id()
		var state := {
			"__new": true,
			"version": SaveManager.VERSION,
			"mode": _new_mode,
			"world": {"time_of_day": 9.4},
		}
		SaveManager.write_save(id, nm, state)
		play_requested.emit(id, nm, state)
	, 520.0, true)
	_add_button("返回", _show_single, 520.0)
	name_edit.call_deferred("grab_focus")
	name_edit.text_submitted.connect(func(_t: String) -> void: create.pressed.emit())


func _add_mode_button(mode: String, title: String, desc: String) -> Button:
	var b := Button.new()
	b.text = "%s\n%s" %[title, desc]
	b.custom_minimum_size = Vector2(520, 96)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func() -> void: _set_new_mode(mode))
	_style_button(b)
	_box.add_child(b)
	return b


func _set_new_mode(mode: String) -> void:
	_new_mode = mode
	for key in _mode_buttons.keys():
		var b: Button = _mode_buttons [key]
		var selected := String(key) == mode
		var normal := _surface(Color(0.120, 0.165, 0.255, 0.96) if selected else CARD_BG,
				Color(0.204, 0.510, 1.0, 0.68) if selected else Color(1, 1, 1, 0.065), 20, 22, 16)
		if selected:
			normal.set_border_width_all(2)
		var hover := _surface(Color(0.140, 0.185, 0.285, 0.98) if selected else CARD_HOVER,
				Color(0.278, 0.576, 1.0, 0.82) if selected else Color(1, 1, 1, 0.14), 20, 22, 16)
		var focus := _surface(Color(0.204, 0.510, 1.0, 0.035), ACCENT.lightened(0.18), 20, 22, 16)
		focus.set_border_width_all(2)
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("pressed", normal)
		b.add_theme_stylebox_override("focus", focus)
		b.add_theme_color_override("font_color",
				Color(0.92, 0.94, 0.97) if selected else TEXT_DIM)

func show_new() -> void:
	_show_new()

func show_new_dialog() -> void:
	_show_new()

func _play(data: Dictionary) -> void:
	if data.is_empty():
		_toast("没有可用的存档")
		return
	var id := String(data.get("id", ""))
	var nm := String(data.get("name", "存档"))
	var state: Dictionary = data.get("state", {})
	if id == "":
		_toast("存档已损坏")
		return
	SaveManager.set_last_slot(id)
	play_requested.emit(id, nm, state)

func _on_settings(category := 0) -> void:
	_title_was_visible = _title_block.visible
	_title_block.visible = false
	_panel.visible = false
	_settings.open(category)

func _on_settings_closed() -> void:
	_panel.visible = true
	_title_block.visible = _title_was_visible
	_apply_panel_chrome()
	await get_tree().process_frame
	_panel.pivot_offset = _panel.size * 0.5
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.98, 0.98)
	_title_block.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.2)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_title_block, "modulate:a", 1.0, 0.2)

func open_settings(category := 0) -> void:
	_on_settings(category)

func _focus_first() -> void:
	for c in _box.get_children():
		if c is Button and not(c as Button).disabled:
			(c as Button).grab_focus()
			return

func _toast(text: String) -> void:
	_toast_label.text = text
	_toast_label.modulate.a = 1.0
	_toast_time = 2.6

func _process(delta: float) -> void:
	if _toast_time > 0.0:
		_toast_time -= delta
		if _toast_time <= 0.0:
			_toast_label.modulate.a = maxf(0.0, _toast_label.modulate.a - delta * 2.4)

func _unhandled_input(event: InputEvent) -> void:
	if _confirm_dim != null and _confirm_dim.visible:
		if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_hide_confirm()
		return
	if _settings.visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		if _title_block.visible:
			return
		get_viewport().set_input_as_handled()
		_show_main()
