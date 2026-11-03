extends CanvasLayer
class_name CareerPanel

const Brand = preload("res://src/core/brand.gd")


signal closed

var game: Game
var _center: CenterContainer
var _panel: PanelContainer
var _root: VBoxContainer
var _content: VBoxContainer
var _scroll: ScrollContainer
var _tab := "jobs"
var _message := ""


func _ready() -> void:
	layer = 32
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_shell()


func _build_shell() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.018, 0.03, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_center = CenterContainer.new()
	_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_center)

	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.035, 0.052, 0.075, 0.98)
	sb.border_color = Color(0.36, 0.46, 0.56, 0.95)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(22)
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.custom_minimum_size = Vector2(880, 620)
	_center.add_child(_panel)

	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 10)
	_panel.add_child(_root)

	var title := Label.new()
	title.text = "任务中心  ·  %s" %Brand.NAME_EN
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	_root.add_child(title)
	_root.add_child(HSeparator.new())

	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(820, 500)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_root.add_child(_scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 9)
	_scroll.add_child(_content)


func open(p_game: Game) -> void:
	game = p_game
	visible = true
	_tab = "jobs"
	_message = ""
	refresh()
	if _content.get_child_count() > 0:
		_scroll.scroll_vertical = 0


func refresh() -> void:
	if _content == null:
		return
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()
	_add_header()
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	_content.add_child(tabs)
	if game != null and game.mode == "career":
		_add_tab(tabs, "快速任务", "jobs")
		_add_tab(tabs, "车库", "garage")
	else:
		_add_tab(tabs, "车辆编组", "garage")
	if _message != "":
		var msg := Label.new()
		msg.text = _message
		msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		msg.add_theme_color_override("font_color", Color(1.0, 0.83, 0.48))
		_content.add_child(msg)
	if game == null:
		return
	if game.mode == "career":
		if _tab == "jobs":
			_add_jobs()
		else:
			_add_garage()
	else:
		_add_open_consists()
	_add_close_button()


func _add_header() -> void:
	if game == null:
		return
	var line := Label.new()
	if game.mode == "career":
		var career: Dictionary = game.career
		line.text = "资金  ¥%d     等级  Lv.%d     经验  %d     完成  %d 单     生涯收入  ¥%d" %[
			int(career.get("money", 0)), int(career.get("level", 1)),
			int(career.get("xp", 0)), int(career.get("completed", 0)),
			int(career.get("earnings", 0))
		]
		line.add_theme_color_override("font_color", Color(0.68, 0.82, 0.92))
	elif game.mode == "test":
		line.text = "测试模式 · 专用试验线 · 动力锁定 1800 kN"
		line.add_theme_color_override("font_color", Color(0.95, 0.72, 0.38))
	else:
		line.text = "开放模式 · 全部车辆与线路已解锁 · 资金无限"
		line.add_theme_color_override("font_color", Color(0.6, 0.9, 0.7))
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.add_theme_font_size_override("font_size", 14)
	_content.add_child(line)


func _add_tab(parent: HBoxContainer, text: String, tab: String) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(180, 38)
	b.toggle_mode = true
	b.button_pressed = _tab == tab
	b.pressed.connect(func() -> void:
		_tab = tab
		_message = ""
		refresh()
	)
	_style_button(b, _tab == tab)
	parent.add_child(b)


func _add_jobs() -> void:
	var career: Dictionary = game.career
	if bool(career.get("job_finished", false)):
		var last: Dictionary = career.get("last_result", {})
		var done := Label.new()
		done.text = "上一单已完成：%s +¥%d" %[String(last.get("cargo", "任务")), int(last.get("score", 0))]
		done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		done.add_theme_color_override("font_color", Color(0.55, 0.95, 0.68))
		done.add_theme_font_size_override("font_size", 16)
		_content.add_child(done)
	var cur: Dictionary = career.get("current_job", {})
	if not cur.is_empty() and not bool(career.get("job_finished", false)):
		_content.add_child(_section("当前任务"))
		_content.add_child(_job_card(cur, true))
	_content.add_child(_section("可接快速任务 · 由铁路调度中心发布"))
	var offers: Array = game.get_career_offers()
	for job: Dictionary in offers:
		_content.add_child(_job_card(job, false))


func _job_card(job: Dictionary, current: bool) -> Control:
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.1, 0.14, 0.96)
	sb.border_color = Color(0.26, 0.36, 0.46, 0.9)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(9)
	sb.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	var top := Label.new()
	var kind_text := _kind_name(String(job.get("kind", "electric")))
	var owned := bool(job.get("owned", false))
	top.text = "%s  %s  ·  %s → %s" %[
		String(job.get("number", "JOB")), kind_text,
		String(game.station_data [int(job.get("origin", 0))] ["name"]),
		String(game.station_data [int(job.get("dest", 1))] ["name"])
	]
	top.add_theme_font_size_override("font_size", 17)
	top.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	info.add_child(top)
	var detail := Label.new()
	var cargo := String(job.get("cargo", "货物"))
	var amount := "%d 人" %int(job.get("weight", 0)) if String(job.get("unit", "t")) == "人" else "%.0f t" %float(job.get("weight", 0))
	detail.text = "%s %s   ·   %.1f km   ·   限速 %.0f km/h   ·   时限 %s   ·   %s" %[
		cargo, amount, float(job.get("distance", 0.0)) / 1000.0, float(job.get("limit", 0.0)),
		_time_text(float(job.get("time_limit", 0.0))), "自有车辆 +25%%" if owned else "快速任务配车"
	]
	detail.add_theme_font_size_override("font_size", 13)
	detail.add_theme_color_override("font_color", Color(0.62, 0.72, 0.82))
	info.add_child(detail)
	var pay := Label.new()
	pay.text = "¥%d" %int(job.get("reward", 0))
	pay.add_theme_font_size_override("font_size", 26)
	pay.add_theme_color_override("font_color", Color(1.0, 0.78, 0.4))
	row.add_child(pay)
	var b := Button.new()
	b.text = "当前" if current else "接单"
	b.disabled = current
	b.custom_minimum_size = Vector2(100, 46)
	_style_button(b, false)
	if not current:
		b.pressed.connect(func() -> void:
			_message = "正在派车…"
			game.accept_job(job)
		)
	row.add_child(b)
	return card


func _add_garage() -> void:
	var career: Dictionary = game.career
	_content.add_child(_section("车辆库 · 购买后可获得该型车辆的自有任务加成"))
	var owned: Array = career.get("owned", [])
	for v: Dictionary in Game.CAREER_CATALOG:
		var card := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.07, 0.1, 0.14, 0.96)
		sb.border_color = Color(0.26, 0.36, 0.46, 0.9)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(9)
		sb.set_content_margin_all(10)
		card.add_theme_stylebox_override("panel", sb)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var nm := Label.new()
		var has_it := String(v ["id"]) in owned or (String(v ["id"]) == "electric" and owned.has("electric"))
		nm.text = "%s%s" %[String(v ["name"]), "   ✓ 已拥有" if has_it else ""]
		nm.add_theme_font_size_override("font_size", 18)
		nm.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
		info.add_child(nm)
		var desc := Label.new()
		desc.text = String(v ["desc"])
		desc.add_theme_font_size_override("font_size", 13)
		desc.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
		info.add_child(desc)
		var meta := Label.new()
		meta.text = "需要等级 Lv.%d" %int(v ["level"]) if not has_it else "已加入车库"
		meta.add_theme_font_size_override("font_size", 12)
		meta.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
		info.add_child(meta)
		var b := Button.new()
		if has_it:
			b.text = "已拥有"
			b.disabled = true
		else:
			b.text = "¥%d" %int(v ["price"]) if int(v ["price"]) > 0 else "初始车辆"
		b.custom_minimum_size = Vector2(130, 46)
		_style_button(b, false)
		if not has_it:
			b.pressed.connect(func() -> void:
				_message = game.buy_vehicle(String(v ["id"]))
				refresh()
			)
		row.add_child(b)
		_content.add_child(card)


func _add_open_consists() -> void:
	_content.add_child(_section("自由编组 · 创造模式"))
	var snap: Dictionary = game.consist_snapshot()
	var summary := ConsistCatalog.compute(snap ["cars"], int(snap ["locos"]), bool(snap ["loaded"]),
			game.engine_id, game.transmission_id)
	var custom_card := PanelContainer.new()
	var custom_sb := StyleBoxFlat.new()
	custom_sb.bg_color = Color(0.08, 0.105, 0.15, 0.98)
	custom_sb.border_color = Color(0.38, 0.52, 0.68, 0.95)
	custom_sb.set_border_width_all(1)
	custom_sb.set_corner_radius_all(9)
	custom_sb.set_content_margin_all(11)
	custom_card.add_theme_stylebox_override("panel", custom_sb)
	_content.add_child(custom_card)
	var custom_row := HBoxContainer.new()
	custom_row.add_theme_constant_override("separation", 12)
	custom_card.add_child(custom_row)
	var custom_info := VBoxContainer.new()
	custom_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_info.add_theme_constant_override("separation", 3)
	custom_row.add_child(custom_info)
	var custom_name := Label.new()
	custom_name.text = "自定义列车编组"
	custom_name.add_theme_font_size_override("font_size", 18)
	custom_name.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	custom_info.add_child(custom_name)
	var custom_desc := Label.new()
	custom_desc.text = "%s · %d 台机车 + %d 节车厢 · %.1f m / %.0f m · %.0f t" %[
		ConsistCatalog.category_name(String(summary ["category"])),
		int(summary ["loco_count"]), int(summary ["car_count"]),
		float(summary ["length"]), float(summary ["limit"]), float(summary ["mass_now"])]
	custom_desc.add_theme_font_size_override("font_size", 13)
	custom_desc.add_theme_color_override("font_color", Color(0.62, 0.72, 0.82))
	custom_info.add_child(custom_desc)
	var custom_btn := Button.new()
	custom_btn.text = "编辑编组"
	custom_btn.custom_minimum_size = Vector2(120, 46)
	_style_button(custom_btn, true)
	custom_btn.pressed.connect(func() -> void: game.open_consist_panel("career"))
	custom_row.add_child(custom_btn)

	_content.add_child(_section("可用预设 · 点击后立即在当前线路切换"))
	var items := [
		{"name": "HXD1 集装箱货列", "kind": "container", "desc": "HXD1 电力机车 + 8 辆集装箱平车"},
		{"name": "HXD1 空车货列", "kind": "hopper", "desc": "HXD1 电力机车 + 8 辆空敞车"},
	]
	for item: Dictionary in items:
		var card := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.07, 0.1, 0.14, 0.96)
		sb.border_color = Color(0.26, 0.36, 0.46, 0.9)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(9)
		sb.set_content_margin_all(9)
		card.add_theme_stylebox_override("panel", sb)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var nm := Label.new()
		nm.text = String(item ["name"])
		nm.add_theme_font_size_override("font_size", 18)
		nm.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
		info.add_child(nm)
		var desc := Label.new()
		desc.text = String(item ["desc"])
		desc.add_theme_font_size_override("font_size", 13)
		desc.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
		info.add_child(desc)
		var b := Button.new()
		b.text = "使用"
		b.custom_minimum_size = Vector2(100, 44)
		_style_button(b, false)
		b.pressed.connect(func() -> void:
			game.select_consist(String(item ["kind"]))
			_message = "已切换为 %s" %String(item ["name"])
			refresh()
		)
		row.add_child(b)
		_content.add_child(card)


func _section(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.95, 0.68, 0.38))
	return l


func _add_close_button() -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.add_child(row)
	var close := Button.new()
	close.text = "关闭并继续"
	close.custom_minimum_size = Vector2(230, 42)
	_style_button(close, false)
	close.pressed.connect(func() -> void:
		visible = false
		closed.emit()
	)
	row.add_child(close)


func _style_button(b: Button, selected: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.22, 0.29, 0.98) if selected else Color(0.08, 0.11, 0.15, 0.95)
	sb.border_color = Color(0.95, 0.62, 0.3, 0.95) if selected else Color(0.28, 0.36, 0.46, 0.9)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(7)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("focus", sb)
	b.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.52, 0.6))
	b.focus_mode = Control.FOCUS_ALL


func _kind_name(kind: String) -> String:
	match kind:
		"emu":
			return "复兴号动车组"
		"intercity":
			return "城际动车组"
		"hopper":
			return "敞车货列"
		"container":
			return "集装箱货列"
		"diesel":
			return "内燃货列"
		"steam":
			return "蒸汽货列"
		_:
			return "电力货列"


func _time_text(seconds: float) -> String:
	var s := maxi(0, int(seconds))
	return "%d:%02d" %[s / 60, s % 60]


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		visible = false
		closed.emit()
