extends CanvasLayer
class_name ConsistPanel

const ThumbScript = preload("res://src/ui/consist_thumb.gd")

signal closed(resume: bool)

const TEXT_MAIN := Color(0.95, 0.965, 0.978)
const TEXT_DIM := Color(0.62, 0.66, 0.71)
const TEXT_MUTED := Color(0.44, 0.48, 0.54)
const ACCENT := Color(0.3, 0.62, 1.0)
const GOLD := Color(0.96, 0.7, 0.36)
const CARD_BG := Color(0.075, 0.086, 0.105, 0.98)
const CARD_HOVER := Color(0.11, 0.125, 0.15, 0.99)
const PANEL_BG := Color(0.035, 0.042, 0.055, 0.995)

var game
var _cars: Array[String] = []
var _locos := 1
var _loaded := true
var _selected := -1
var _message := ""

var _status: Label
var _catalog: VBoxContainer
var _catalog_scroll: ScrollContainer
var _strip: HBoxContainer
var _strip_scroll: ScrollContainer
var _info: VBoxContainer
var _length_bar: ProgressBar
var _length_note: Label
var _loco_toggle: CheckButton
var _loco_button: Button
var _loaded_toggle: CheckButton
var _selection_buttons: Array[Button] = []
var _toolbar := {}
var _apply_button: Button


func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.005, 0.008, 0.014, 0.84)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _surface(PANEL_BG, Color(0, 0, 0, 0), 0, 0))
	add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	root.add_child(_build_header())
	root.add_child(_divider())

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	body.add_child(_build_catalog_panel())
	body.add_child(_build_stage_panel())
	body.add_child(_build_info_panel())

	root.add_child(_build_footer())


func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)

	var title_col := VBoxContainer.new()
	title_col.add_theme_constant_override("separation", 1)
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_col)

	var overline := Label.new()
	overline.text = "DUSKRAIL  /  创造模式"
	overline.add_theme_font_size_override("font_size", 10)
	overline.add_theme_color_override("font_color", Color(0.5, 0.65, 0.88))
	title_col.add_child(overline)

	var title := Label.new()
	title.text = "列车编组"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", TEXT_MAIN)
	title_col.add_child(title)

	var sub := Label.new()
	sub.text = "自由搭配车厢 · 双车头重联 · 客运与货运分编"
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", TEXT_DIM)
	title_col.add_child(sub)

	var badge := Label.new()
	badge.text = "创造模式 · 不限车辆"
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_color_override("font_color", GOLD)
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(badge)

	var close := Button.new()
	close.text = "关闭"
	close.custom_minimum_size = Vector2(92, 42)
	close.add_theme_font_size_override("font_size", 15)
	close.pressed.connect(func() -> void: _close(false))
	_style_button(close, false)
	header.add_child(close)
	return header


func _build_catalog_panel() -> Control:
	var panel := _panel_card(Vector2(330, 0))
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title := Label.new()
	title.text = "车厢库"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", TEXT_MAIN)
	box.add_child(title)

	var note := Label.new()
	note.text = "点击添加。客运与货运车厢不能混编。"
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", TEXT_MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)

	_catalog_scroll = ScrollContainer.new()
	_catalog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_catalog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_catalog_scroll.follow_focus = true
	box.add_child(_catalog_scroll)

	_catalog = VBoxContainer.new()
	_catalog.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_catalog.add_theme_constant_override("separation", 7)
	_catalog_scroll.add_child(_catalog)
	_style_scrollbar(_catalog_scroll)
	return panel


func _build_stage_panel() -> Control:
	var panel := _panel_card(Vector2(0, 0))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	box.add_child(top)

	var title := Label.new()
	title.text = "编组台"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", TEXT_MAIN)
	top.add_child(title)

	var hint := Label.new()
	hint.text = "点击车厢选中，可删除或左右移动"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", TEXT_MUTED)
	top.add_child(hint)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)

	_loco_toggle = CheckButton.new()
	_loco_toggle.text = "双车头"
	_loco_toggle.tooltip_text = "在整列车最前面再挂一台同型 HXD1，动力并联，仍由前车操纵。"
	_loco_toggle.add_theme_font_size_override("font_size", 13)
	_loco_toggle.toggled.connect(_on_loco_toggled)
	_loco_toggle.visible = false
	top.add_child(_loco_toggle)

	_loco_button = Button.new()
	_loco_button.text = "＋ 加挂副机车"
	_loco_button.tooltip_text = "在编组最前方再加挂一台同步 HXD1；两台机车共同牵引，仍由主控机车统一操纵。"
	_loco_button.custom_minimum_size = Vector2(156, 38)
	_loco_button.add_theme_font_size_override("font_size", 13)
	_loco_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_loco_button.pressed.connect(func() -> void: _set_loco_count(1 if _locos == 2 else 2))
	_style_soft_primary(_loco_button)
	top.add_child(_loco_button)

	_loaded_toggle = CheckButton.new()
	_loaded_toggle.text = "满载"
	_loaded_toggle.tooltip_text = "按满载计算总重与载重；关闭后按空车计算。"
	_loaded_toggle.add_theme_font_size_override("font_size", 13)
	_loaded_toggle.toggled.connect(_on_loaded_toggled)
	top.add_child(_loaded_toggle)

	_strip_scroll = ScrollContainer.new()
	_strip_scroll.custom_minimum_size = Vector2(0, 198)
	_strip_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_strip_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_strip_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_strip_scroll)

	_strip = HBoxContainer.new()
	_strip.add_theme_constant_override("separation", 7)
	_strip_scroll.add_child(_strip)
	_style_scrollbar(_strip_scroll)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 7)
	box.add_child(toolbar)
	_toolbar ["delete"] = _toolbar_button(toolbar, "删除选中", _remove_selected)
	_toolbar ["left"] = _toolbar_button(toolbar, "左移", func() -> void: _move_selected(-1))
	_toolbar ["right"] = _toolbar_button(toolbar, "右移", func() -> void: _move_selected(1))
	_toolbar ["clear"] = _toolbar_button(toolbar, "清空车厢", _clear_cars)
	var tspace := Control.new()
	tspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(tspace)

	var capacity_row := HBoxContainer.new()
	capacity_row.add_theme_constant_override("separation", 10)
	box.add_child(capacity_row)
	var cap_label := Label.new()
	cap_label.text = "编组长度"
	cap_label.add_theme_font_size_override("font_size", 12)
	cap_label.add_theme_color_override("font_color", TEXT_DIM)
	capacity_row.add_child(cap_label)
	_length_bar = ProgressBar.new()
	_length_bar.custom_minimum_size = Vector2(0, 12)
	_length_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_length_bar.show_percentage = false
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.055, 0.065, 0.082, 0.95)
	bar_bg.set_corner_radius_all(4)
	_length_bar.add_theme_stylebox_override("background", bar_bg)
	capacity_row.add_child(_length_bar)
	_length_note = Label.new()
	_length_note.add_theme_font_size_override("font_size", 12)
	_length_note.add_theme_color_override("font_color", TEXT_DIM)
	capacity_row.add_child(_length_note)

	var rule := Label.new()
	rule.text = "规则：同一列车内不能同时编挂货运车厢和客运车厢；最短可不挂车厢，最长按干线列车限长。"
	rule.add_theme_font_size_override("font_size", 11)
	rule.add_theme_color_override("font_color", TEXT_MUTED)
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(rule)

	var templates := HBoxContainer.new()
	templates.add_theme_constant_override("separation", 6)
	box.add_child(templates)
	var tlabel := Label.new()
	tlabel.text = "快捷模板"
	tlabel.add_theme_font_size_override("font_size", 11)
	tlabel.add_theme_color_override("font_color", TEXT_DIM)
	templates.add_child(tlabel)
	_template_button(templates, "集装箱 20", _repeat("container", 20))
	_template_button(templates, "客运 8", _passenger_template())
	_template_button(templates, "货运混编 20", _mixed_freight_template())
	_template_button(templates, "单机", [])
	return panel


func _build_info_panel() -> Control:
	var panel := _panel_card(Vector2(330, 0))
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title := Label.new()
	title.text = "编组信息"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", TEXT_MAIN)
	box.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_info = VBoxContainer.new()
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info.add_theme_constant_override("separation", 7)
	scroll.add_child(_info)
	return panel


func _build_footer() -> Control:
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 9)
	var status := Label.new()
	status.custom_minimum_size = Vector2(0, 32)
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", GOLD)
	footer.add_child(status)
	_status = status

	var cancel := Button.new()
	cancel.text = "返回"
	cancel.custom_minimum_size = Vector2(104, 42)
	cancel.pressed.connect(func() -> void: _close(false))
	_style_button(cancel, false)
	footer.add_child(cancel)

	_apply_button = Button.new()
	_apply_button.text = "应用并继续"
	_apply_button.custom_minimum_size = Vector2(150, 42)
	_apply_button.pressed.connect(func() -> void: _apply(true))
	_style_button(_apply_button, true)
	footer.add_child(_apply_button)
	return footer


func open(p_game, _from := "pause") -> void:
	game = p_game
	var snap: Dictionary = game.consist_snapshot()
	_cars.clear()
	for c in snap ["cars"]:
		_cars.append(String(c))
	_locos = clampi(int(snap ["locos"]), 1, 2)
	_loaded = bool(snap ["loaded"])
	_selected = -1
	_message = "已载入当前编组，可直接增删车厢。"
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh_all()
	await get_tree().process_frame
	if _catalog_scroll != null:
		_catalog_scroll.scroll_vertical = 0
	if _strip_scroll != null:
		_strip_scroll.scroll_horizontal = 0
	if _apply_button != null:
		_apply_button.grab_focus()


func _refresh_all() -> void:
	_refresh_catalog()
	_refresh_strip()
	_refresh_info()
	_refresh_toolbar()
	_refresh_status()


func _refresh_catalog() -> void:
	if _catalog == null:
		return
	for c in _catalog.get_children():
		_catalog.remove_child(c)
		c.queue_free()
	_catalog.add_child(_section("机车 · 双机重联"))
	_catalog.add_child(_loco_catalog_card())
	_catalog.add_child(_section("客运车厢"))
	for id: String in ["passenger", "baggage"]:
		_catalog.add_child(_catalog_card(id))
	_catalog.add_child(_section("货运车厢"))
	for id: String in ["water_tank", "flat", "gondola", "reefer", "container", "hopper"]:
		_catalog.add_child(_catalog_card(id))
	var tip := Label.new()
	tip.text = "提示：先添加一种车厢即可确定本次编组的客运/货运类别。"
	tip.add_theme_font_size_override("font_size", 11)
	tip.add_theme_color_override("font_color", TEXT_MUTED)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_catalog.add_child(tip)
	if _catalog_scroll != null:
		_style_scrollbar(_catalog_scroll)


func _loco_catalog_card() -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(302, 92)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func() -> void: _set_loco_count(1 if _locos == 2 else 2))
	_style_card(btn, _locos == 2, true)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	var thumb = ThumbScript.new()
	thumb.custom_minimum_size = Vector2(92, 46)
	thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	thumb.setup("loco", true, true)
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(thumb)
	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.add_theme_constant_override("separation", 1)
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(labels)
	var name := Label.new()
	name.text = "HXD1 电力机车"
	name.add_theme_font_size_override("font_size", 14)
	name.add_theme_color_override("font_color", TEXT_MAIN)
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(name)
	var meta := Label.new()
	meta.text = "20.0 m · 138 t · 交—直—交"
	meta.add_theme_font_size_override("font_size", 11)
	meta.add_theme_color_override("font_color", TEXT_DIM)
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(meta)
	var state := Label.new()
	state.text = "已加挂副机车 · 点击摘除" if _locos == 2 else "当前 1 台 · 点击加挂第二台"
	state.add_theme_font_size_override("font_size", 10)
	state.add_theme_color_override("font_color", GOLD if _locos == 2 else Color(0.46, 0.74, 1.0))
	state.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(state)
	var plus := Label.new()
	plus.text = "－" if _locos == 2 else "＋"
	plus.add_theme_font_size_override("font_size", 22)
	plus.add_theme_color_override("font_color", GOLD if _locos == 2 else ACCENT)
	plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(plus)
	return btn


func _catalog_card(id: String) -> Button:
	var item := ConsistCatalog.info(id)
	if item.is_empty():
		return Button.new()
	var allowed := _can_add(id)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(302, 92)
	btn.disabled = not bool(allowed ["ok"])
	btn.tooltip_text = "%s\n%s\n%s" %[String(item ["name"]), String(item ["desc"]), String(allowed ["reason"])]
	_style_card(btn, false, not btn.disabled)
	btn.pressed.connect(_add_car.bind(id))
	btn.add_child(_catalog_card_body(id, item, bool(allowed ["ok"])))
	return btn


func _catalog_card_body(id: String, item: Dictionary, allowed: bool) -> Control:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	var thumb = ThumbScript.new()
	thumb.custom_minimum_size = Vector2(92, 46)
	thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	thumb.setup(id, _loaded)
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(thumb)
	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.add_theme_constant_override("separation", 1)
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(labels)
	var name := Label.new()
	name.text = String(item ["name"])
	name.add_theme_font_size_override("font_size", 14)
	name.add_theme_color_override("font_color", TEXT_MAIN if allowed else TEXT_MUTED)
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(name)
	var mass_now := float(item ["loaded"] if _loaded else item ["empty"])
	var meta := Label.new()
	meta.text = "%.1f m · %.0f t · %s" %[float(item ["length"]), mass_now, ConsistCatalog.category_name(String(item ["category"]))]
	meta.add_theme_font_size_override("font_size", 11)
	meta.add_theme_color_override("font_color", TEXT_DIM)
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(meta)
	var desc := Label.new()
	desc.text = String(item ["desc"])
	desc.add_theme_font_size_override("font_size", 10)
	desc.add_theme_color_override("font_color", TEXT_MUTED)
	desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(desc)
	var plus := Label.new()
	plus.text = "＋" if allowed else "—"
	plus.add_theme_font_size_override("font_size", 20)
	plus.add_theme_color_override("font_color", ACCENT if allowed else TEXT_MUTED)
	plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(plus)
	return margin


func _refresh_strip() -> void:
	if _strip == null:
		return
	var scroll := _strip_scroll.scroll_horizontal if _strip_scroll != null else 0
	for c in _strip.get_children():
		_strip.remove_child(c)
		c.queue_free()
	_selection_buttons.clear()
	for i in range(_locos):
		_strip.add_child(_loco_card(i))
	if _locos == 1:
		_strip.add_child(_add_loco_card())
	for i in range(_cars.size()):
		var btn := _car_card(i)
		_strip.add_child(btn)
		_selection_buttons.append(btn)
	if _cars.is_empty():
		var placeholder := _panel_card(Vector2(230, 170))
		var hint := Label.new()
		hint.text = "当前只有机车\n从左侧车厢库添加车厢"
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hint.add_theme_font_size_override("font_size", 13)
		hint.add_theme_color_override("font_color", TEXT_MUTED)
		placeholder.add_child(hint)
		_strip.add_child(placeholder)
	if _strip_scroll != null:
		_strip_scroll.scroll_horizontal = scroll
		_style_scrollbar(_strip_scroll)
	_update_selection_styles()


func _loco_card(i: int) -> Control:
	var card := _panel_card(Vector2(108, 170))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var thumb = ThumbScript.new()
	thumb.custom_minimum_size = Vector2(90, 46)
	thumb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	thumb.setup("loco", true, true)
	box.add_child(thumb)
	var name := Label.new()
	name.text = "机车 %d" %(i + 1)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", 12)
	name.add_theme_color_override("font_color", TEXT_MAIN)
	box.add_child(name)
	var role := Label.new()
	role.text = "主控" if i == 0 else "重联"
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role.add_theme_font_size_override("font_size", 10)
	role.add_theme_color_override("font_color", GOLD if i == 0 else ACCENT)
	box.add_child(role)
	var meta := Label.new()
	meta.text = "HXD1 · 20.0 m"
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta.add_theme_font_size_override("font_size", 9)
	meta.add_theme_color_override("font_color", TEXT_MUTED)
	box.add_child(meta)
	return card


func _add_loco_card() -> Button:
	var btn := Button.new()
	btn.name = "AddLocoCard"
	btn.custom_minimum_size = Vector2(126, 170)
	btn.tooltip_text = "再挂一台同步 HXD1，组成双机重联。"
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func() -> void: _set_loco_count(2))
	var normal := _surface(Color(0.075, 0.11, 0.17, 0.72),
			Color(0.34, 0.55, 0.86, 0.62), 12, 8)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	var hover := normal.duplicate()
	hover.bg_color = Color(0.13, 0.21, 0.34, 0.88)
	hover.border_color = Color(0.52, 0.75, 1.0, 0.95)
	var pressed := hover.duplicate()
	pressed.bg_color = Color(0.10, 0.17, 0.28, 0.95)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 3)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(box)
	var plus := Label.new()
	plus.text = "＋"
	plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus.add_theme_font_size_override("font_size", 30)
	plus.add_theme_color_override("font_color", Color(0.58, 0.79, 1.0))
	plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(plus)
	var name := Label.new()
	name.text = "加挂副机车"
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", 12)
	name.add_theme_color_override("font_color", TEXT_MAIN)
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name)
	var note := Label.new()
	note.text = "双机重联"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 9)
	note.add_theme_color_override("font_color", TEXT_MUTED)
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(note)
	return btn


func _car_card(i: int) -> Button:
	var id := _cars [i]
	var item := ConsistCatalog.info(id)
	var btn := Button.new()
	btn.toggle_mode = true
	btn.custom_minimum_size = Vector2(_car_width(id), 170)
	btn.tooltip_text = "%s\n点击选中，可删除或移动" %String(item ["name"])
	_style_card(btn, i == _selected, true)
	btn.pressed.connect(_select_car.bind(i))
	btn.add_child(_car_card_body(i, id, item))
	return btn


func _car_card_body(i: int, id: String, item: Dictionary) -> Control:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)
	var thumb = ThumbScript.new()
	thumb.custom_minimum_size = Vector2(80, 42)
	thumb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	thumb.setup(id, _loaded)
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(thumb)
	var index := Label.new()
	index.text = "%02d · %s" %[i + 1, String(item ["short"])]
	index.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	index.add_theme_font_size_override("font_size", 11)
	index.add_theme_color_override("font_color", GOLD)
	index.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(index)
	var name := Label.new()
	name.text = String(item ["name"])
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", 11)
	name.add_theme_color_override("font_color", TEXT_MAIN)
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name)
	var meta := Label.new()
	var mass := float(item ["loaded"] if _loaded else item ["empty"])
	meta.text = "%.1f m · %.0f t" %[float(item ["length"]), mass]
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta.add_theme_font_size_override("font_size", 9)
	meta.add_theme_color_override("font_color", TEXT_MUTED)
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(meta)
	return margin


func _car_width(id: String) -> float:
	var item := ConsistCatalog.info(id)
	var length := float(item.get("length", 13.8))
	return clampf(70.0 + length * 1.92, 92.0, 136.0)


func _refresh_info() -> void:
	if _info == null:
		return
	for c in _info.get_children():
		_info.remove_child(c)
		c.queue_free()
	var s := _summary()
	var category := String(s ["category"])
	var badge_box := PanelContainer.new()
	badge_box.add_theme_stylebox_override("panel", _surface(
			GOLD if category == "passenger" else (ACCENT if category == "freight" else Color(0.45, 0.5, 0.56)),
			Color(0, 0, 0, 0), 7, 5))
	_info.add_child(badge_box)
	var badge := Label.new()
	badge.text = "%s编组" %ConsistCatalog.category_name(category)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 15)
	badge.add_theme_color_override("font_color", Color(0.08, 0.09, 0.11))
	badge_box.add_child(badge)

	_stat("编组", "%d 台机车 + %d 节车厢" %[int(s ["loco_count"]), int(s ["car_count"])])
	_stat("总长", "%.1f / %.0f m" %[float(s ["length"]), float(s ["limit"])])
	_stat("总重", "%.0f t" %float(s ["mass_now"]))
	_stat("空车总重", "%.0f t" %float(s ["mass_empty"]))
	if category == "passenger":
		_stat("定员", "%d 人" %int(s ["passengers_full"]))
		_stat("行李/载重", "%.0f t" %float(s ["payload"]))
	elif category == "freight":
		_stat("载重", "%.0f / %.0f t" %[float(s ["payload"]), float(s ["payload_full"])])
	else:
		_stat("载重", "未挂车厢")
	_stat("最高速度", "%.0f km/h" %float(s ["max_speed"]))
	_stat("牵引", "%.0f kN" %float(s ["traction_kn"]))
	if int(s ["loco_count"]) > 1:
		_note("双车头重联：第二台 HXD1 的动力与第一台同步，仍由前车统一操纵。")
	_note("限长：货运 %.0f m / 客运 %.0f m（按干线列车）" %[
		ConsistCatalog.MAX_FREIGHT_LENGTH, ConsistCatalog.MAX_PASSENGER_LENGTH])
	if category == "none":
		_note("当前未挂车厢，可直接应用为单机运行。")
	if _selected >= 0 and _selected < _cars.size():
		var sel_id := _cars [_selected]
		var sel := ConsistCatalog.info(sel_id)
		_info.add_child(_divider())
		var sel_head := Label.new()
		sel_head.text = "选中车厢 · %s" %String(sel ["name"])
		sel_head.add_theme_font_size_override("font_size", 13)
		sel_head.add_theme_color_override("font_color", GOLD)
		_info.add_child(sel_head)
		_stat("长度", "%.1f m" %float(sel ["length"]))
		_stat("空车 / 满载", "%.0f / %.0f t" %[float(sel ["empty"]), float(sel ["loaded"])])
		_stat("载重能力", "%.0f t" %float(sel ["payload"]))
		if int(sel.get("passengers", 0)) > 0:
			_stat("定员", "%d 人" %int(sel ["passengers"]))
		_stat("构造速度", "%.0f km/h" %float(sel ["max_speed"]))
		_note(String(sel ["desc"]))


func _stat(label: String, value: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_info.add_child(row)
	var l := Label.new()
	l.text = label
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", TEXT_DIM)
	row.add_child(l)
	var v := Label.new()
	v.text = value
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_theme_font_size_override("font_size", 12)
	v.add_theme_color_override("font_color", TEXT_MAIN)
	row.add_child(v)


func _note(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", TEXT_MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.add_child(l)


func _refresh_toolbar() -> void:
	if _loco_toggle != null:
		_loco_toggle.set_pressed_no_signal(_locos == 2)
	if _loco_button != null:
		_loco_button.text = "移除副机车" if _locos == 2 else "＋ 加挂副机车"
		_loco_button.tooltip_text = "摘除第二台 HXD1，恢复单机牵引。" if _locos == 2 \
				else "在编组最前方再加挂一台同步 HXD1；两台机车共同牵引，仍由主控机车统一操纵。"
	if _loaded_toggle != null:
		_loaded_toggle.set_pressed_no_signal(_loaded)
	var delete: Button = _toolbar.get("delete")
	if delete != null:
		delete.disabled = _selected < 0
	var left: Button = _toolbar.get("left")
	if left != null:
		left.disabled = _selected <= 0
	var right: Button = _toolbar.get("right")
	if right != null:
		right.disabled = _selected < 0 or _selected >= _cars.size() - 1
	var clear: Button = _toolbar.get("clear")
	if clear != null:
		clear.disabled = _cars.is_empty()


func _refresh_status() -> void:
	if _status == null:
		return
	_status.text = _message
	var s := _summary()
	if _cars.is_empty():
		_length_note.text = "%.1f / %.0f m · 单机" %[float(s ["length"]), float(s ["limit"])]
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color(0.3, 0.42, 0.55)
		fill.set_corner_radius_all(4)
		_length_bar.add_theme_stylebox_override("fill", fill)
		_length_bar.value = clampf(float(s ["length"]) / maxf(1.0, float(s ["limit"])) * 100.0, 0.0, 100.0)
		return
	var ratio := float(s ["length"]) / maxf(1.0, float(s ["limit"]))
	_length_note.text = "%.1f / %.0f m · 剩余 %.1f m" %[
		float(s ["length"]), float(s ["limit"]), maxf(0.0, float(s ["limit"]) - float(s ["length"]))]
	_length_bar.value = clampf(ratio * 100.0, 0.0, 100.0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.96, 0.68, 0.3) if ratio > 0.86 else Color(0.35, 0.78, 0.52)
	fill.set_corner_radius_all(4)
	_length_bar.add_theme_stylebox_override("fill", fill)


func _summary() -> Dictionary:
	if game == null:
		return ConsistCatalog.compute([], _locos, _loaded, "standard", "balanced")
	return ConsistCatalog.compute(_cars, _locos, _loaded, game.engine_id, game.transmission_id)


func _can_add(id: String) -> Dictionary:
	if _cars.size() >= ConsistCatalog.MAX_CARS:
		return {"ok": false, "reason": "车辆数量已达上限"}
	var item := ConsistCatalog.info(id)
	if item.is_empty():
		return {"ok": false, "reason": "未知车厢"}
	var cat := String(item ["category"])
	var current := ConsistCatalog.category_for(_cars)
	if current != "none" and cat != current:
		return {"ok": false, "reason": "不能与当前%s编组混编" %ConsistCatalog.category_name(current)}
	var temp := _cars.duplicate()
	temp.append(id)
	var s := ConsistCatalog.compute(temp, _locos, _loaded, game.engine_id if game != null else "standard",
			game.transmission_id if game != null else "balanced")
	if bool(s ["over"]):
		return {"ok": false, "reason": "超出最大编组长度 %.0f m" %float(s ["limit"])}
	return {"ok": true, "reason": ""}


func _add_car(id: String) -> void:
	var allowed := _can_add(id)
	if not bool(allowed ["ok"]):
		_message = String(allowed ["reason"])
		_refresh_status()
		return
	_cars.append(id)
	_selected = _cars.size() - 1
	_message = "已添加：%s" %String(ConsistCatalog.info(id) ["name"])
	_refresh_all()
	_scroll_to_end()


func _on_loco_toggled(on: bool) -> void:
	_set_loco_count(2 if on else 1)


func _set_loco_count(target: int) -> void:
	target = clampi(target, 1, 2)
	if target == _locos:
		return
	var test := ConsistCatalog.compute(_cars, target, _loaded, game.engine_id if game != null else "standard",
			game.transmission_id if game != null else "balanced")
	if bool(test ["over"]):
		_message = "双车头会超出最大编组长度 %.0f m，请先减少车厢" %float(test ["limit"])
		_loco_toggle.set_pressed_no_signal(_locos == 2)
		_refresh_status()
		return
	_locos = target
	_message = "已加挂副机车：双机重联，牵引力翻倍" if target == 2 else "已摘除副机车，恢复单机牵引"
	_refresh_all()


func _on_loaded_toggled(on: bool) -> void:
	_loaded = on
	_message = "按满载计算" if on else "按空车计算"
	_refresh_all()


func _select_car(i: int) -> void:
	if i < 0 or i >= _cars.size():
		return
	_selected = i
	_update_selection_styles()
	_refresh_info()
	_refresh_toolbar()


func _update_selection_styles() -> void:
	for i in range(_selection_buttons.size()):
		var b := _selection_buttons [i]
		b.set_pressed_no_signal(i == _selected)
		_style_card(b, i == _selected, true)


func _remove_selected() -> void:
	if _selected < 0 or _selected >= _cars.size():
		return
	var removed := _cars [_selected]
	_cars.remove_at(_selected)
	_selected = mini(_selected, _cars.size() - 1)
	_message = "已移除：%s" %String(ConsistCatalog.info(removed) ["name"])
	_refresh_all()


func _move_selected(delta: int) -> void:
	if _selected < 0 or _selected >= _cars.size():
		return
	var target := _selected + delta
	if target < 0 or target >= _cars.size():
		return
	var tmp := _cars [_selected]
	_cars [_selected] = _cars [target]
	_cars [target] = tmp
	_selected = target
	_message = "已移动车厢"
	_refresh_strip()
	_refresh_toolbar()


func _clear_cars() -> void:
	if _cars.is_empty():
		return
	_cars.clear()
	_selected = -1
	_message = "已清空车厢，当前为单机编组"
	_refresh_all()


func _scroll_to_end() -> void:
	await get_tree().process_frame
	if _strip_scroll != null:
		_strip_scroll.scroll_horizontal = int(_strip_scroll.get_h_scroll_bar().max_value)


func _apply(close_after: bool) -> void:
	if game == null:
		return
	var result: Dictionary = game.apply_custom_consist(_cars, _locos, _loaded)
	if not bool(result.get("ok", false)):
		_message = String(result.get("message", "编组应用失败"))
		_refresh_status()
		return
	_message = String(result.get("message", "编组已应用"))
	_refresh_all()
	if close_after:
		await get_tree().create_timer(0.22).timeout
		if visible:
			_close(true)


func _close(resume: bool) -> void:
	if not visible:
		return
	visible = false
	closed.emit(resume)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close(false)


func _panel_card(min_size: Vector2) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = min_size
	card.add_theme_stylebox_override("panel", _surface(CARD_BG, Color(0.16, 0.2, 0.26, 0.9), 12, 10))
	return card


func _section(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", GOLD)
	return l


func _toolbar_button(parent: HBoxContainer, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 34)
	b.add_theme_font_size_override("font_size", 12)
	b.pressed.connect(cb)
	_style_button(b, false)
	parent.add_child(b)
	return b


func _template_button(parent: HBoxContainer, text: String, ids: Array) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 30)
	b.add_theme_font_size_override("font_size", 11)
	b.pressed.connect(func() -> void: _apply_template(ids))
	_style_button(b, false)
	parent.add_child(b)


func _repeat(id: String, count: int) -> Array:
	var out: Array = []
	for i in range(count):
		out.append(id)
	return out


func _passenger_template() -> Array:
	return ["baggage", "passenger", "passenger", "passenger", "passenger",
			"baggage", "passenger", "passenger"]


func _mixed_freight_template() -> Array:
	var out: Array = []
	var order := ["water_tank", "flat", "gondola", "reefer", "container", "hopper"]
	for i in range(20):
		out.append(order [i % order.size()])
	return out


func _apply_template(ids: Array) -> void:
	_cars.clear()
	_selected = -1
	for raw in ids:
		var id := String(raw)
		if not ConsistCatalog.has_car(id):
			continue
		var candidate := _cars.duplicate()
		candidate.append(id)
		var s := ConsistCatalog.compute(candidate, _locos, _loaded,
				game.engine_id if game != null else "standard",
				game.transmission_id if game != null else "balanced")
		if bool(s ["over"]):
			break
		_cars.append(id)
	_message = "已载入模板：%d 节车厢" %_cars.size()
	_refresh_all()
	_scroll_to_end()


func _divider() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 1)
	return sep


func _style_scrollbar(scroll: ScrollContainer) -> void:
	for bar: ScrollBar in [scroll.get_v_scroll_bar(), scroll.get_h_scroll_bar()]:
		if bar == null:
			continue
		bar.custom_minimum_size = Vector2(6, 6)
		var track := StyleBoxFlat.new()
		track.bg_color = Color(0.05, 0.06, 0.075, 0.9)
		track.set_corner_radius_all(3)
		var grab := StyleBoxFlat.new()
		grab.bg_color = Color(0.27, 0.32, 0.4, 0.9)
		grab.set_corner_radius_all(3)
		var grab_hot := StyleBoxFlat.new()
		grab_hot.bg_color = Color(0.38, 0.45, 0.55, 0.95)
		grab_hot.set_corner_radius_all(3)
		bar.add_theme_stylebox_override("scroll", track)
		bar.add_theme_stylebox_override("grabber", grab)
		bar.add_theme_stylebox_override("grabber_highlight", grab_hot)
		bar.add_theme_stylebox_override("grabber_pressed", grab_hot)


func _surface(bg: Color, border: Color, radius: int, margin: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1 if border.a > 0.01 else 0)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


func _style_button(b: Button, primary: bool) -> void:
	var normal := _surface(
			Color(0.18, 0.42, 0.78, 0.95) if primary else Color(0.09, 0.11, 0.145, 0.96),
			Color(0.35, 0.62, 0.95, 0.95) if primary else Color(0.23, 0.29, 0.37, 0.95), 8, 0)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate()
	hover.bg_color = Color(0.26, 0.54, 0.9, 0.98) if primary else CARD_HOVER
	hover.border_color = Color(0.55, 0.76, 1.0, 0.95)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.12, 0.3, 0.6, 0.98) if primary else Color(0.05, 0.07, 0.1, 0.98)
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.055, 0.065, 0.08, 0.8)
	disabled.border_color = Color(0.14, 0.17, 0.21, 0.7)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	b.add_theme_color_override("font_disabled_color", Color(0.38, 0.42, 0.48))
	b.focus_mode = Control.FOCUS_ALL


func _style_soft_primary(b: Button) -> void:
	var normal := _surface(Color(0.16, 0.36, 0.68, 0.75), Color(0.34, 0.62, 1.0, 0.7), 9, 0)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate()
	hover.bg_color = Color(0.22, 0.46, 0.84, 0.92)
	hover.border_color = Color(0.52, 0.76, 1.0, 0.95)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.11, 0.27, 0.52, 0.95)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_color_override("font_color", Color(0.84, 0.92, 1.0))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.focus_mode = Control.FOCUS_ALL


func _style_card(b: Button, selected: bool, enabled: bool) -> void:
	var normal := _surface(
			Color(0.12, 0.16, 0.21, 0.98) if selected else CARD_BG,
			Color(0.96, 0.7, 0.36, 0.95) if selected else Color(0.16, 0.2, 0.26, 0.9), 10, 0)
	var hover := normal.duplicate()
	hover.bg_color = CARD_HOVER
	hover.border_color = Color(0.36, 0.54, 0.78, 0.95)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.13, 0.19, 0.26, 0.98)
	pressed.border_color = Color(0.96, 0.7, 0.36, 0.95)
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.05, 0.06, 0.075, 0.75)
	disabled.border_color = Color(0.12, 0.15, 0.18, 0.65)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_color_override("font_color", TEXT_MAIN)
	b.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	b.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
