class_name DevPanel
extends CanvasLayer




var game: Game

var _rows: Array [Dictionary] = []
var _root: PanelContainer

func setup(p_game: Game) -> void:
	game = p_game
	layer = 5
	_build()
	visible = false

func toggle() -> void:
	visible = not visible
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif game != null and game.rig != null and game.rig.mode == CameraRig.Mode.FREE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build() -> void:
	var margin := MarginContainer.new()
	margin.anchor_left = 0.0
	margin.anchor_top = 0.0
	margin.anchor_right = 0.0
	margin.anchor_bottom = 0.0
	margin.offset_left = 16.0
	margin.offset_top = 60.0
	margin.offset_right = 420.0
	margin.offset_bottom = 690.0
	add_child(margin)

	_root = PanelContainer.new()
	margin.add_child(_root)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.08, 0.9)
	style.border_color = Color(0.35, 0.55, 0.65, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	_root.add_theme_stylebox_override("panel", style)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(380, 620)
	_root.add_child(scroll)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	scroll.add_child(box)

	_title(box, "开发调试面板  F3 关闭")
	_hint(box, "参数标 sim_* 的均为模拟值，可在此调整")

	_section(box, "列车")
	_row(box, "车型", func(): return game.train_def.summary() if game.train_def != null else "-")
	_row(box, "起动状态", func(): return "%d/9 %s%s" %[
		game.startup.state_index(), game.startup.state_name(),
		"（测试模式）" if game.startup.is_test_mode() else ""])
	_row(box, "下一步", func(): return game.startup.hint())
	_row(box, "受电弓 / 主断", func(): return "%s / %s" %[
		"已升起" if game.startup.panto_up else("上升中" if game.startup.panto_cmd else "降下"),
		"闭合" if game.startup.vcb_on else "分断"])
	_row(box, "ATP / 制动试验", func(): return "%s / %s" %[
		"通过" if game.startup.atp_ok else "未做", "通过" if game.startup.brake_test_ok else "未做"])
	_row(box, "停放制动 / 车门", func(): return "%s / %s" %[
		"施加" if game.startup.park_brake else "缓解",
		"开" if game.train.doors_open else "关"])
	_row(box, "速度 / 牵引力上限", func(): return "%.1f km/h  /  %.0f kN" %[
		game.train.speed * 3.6, game.train.max_tractive_force / 1000.0])
	_row(box, "手柄 牵引/制动/方向", func(): return "%d / %d / %s" %[
		game.train.notch, game.train.brake_notch,
		{1: "前进", 0: "中立", -1: "后进"}.get(game.train.reverser, "?")])
	_row(box, "坡度 / 阻力 / 牵引力", func(): return "%+.2f%%  /  %.0f kN  /  %.0f kN" %[
		game.train.gradient, game.train.resistance_n / 1000.0, game.train.tractive_force_n / 1000.0])

	_section(box, "物理（模拟值）")
	_slider(box, "列车限速 km/h", 20.0, 200.0, 1.0,
			func(): return game.train.max_speed * 3.6,
			func(v): game.train.max_speed = v / 3.6)
	_slider(box, "升弓耗时 s", 0.5, 8.0, 0.1,
			func(): return game.startup.def.sim_panto_seconds,
			func(v): game.startup.def.sim_panto_seconds = v)
	_slider(box, "制动试验耗时 s", 0.5, 8.0, 0.1,
			func(): return game.startup.def.sim_brake_test_seconds,
			func(v): game.startup.def.sim_brake_test_seconds = v)

	_section(box, "线路")
	_row(box, "里程 / 总长", func(): return "%.3f km / %.2f km" %[
		game.route.wrap_dist(game.train.distance) / 1000.0, game.route.total / 1000.0])
	_row(box, "进路", func(): return "侧线" if game.train.lane == 1 else "正线")
	_row(box, "待避侧线", func(): return "已配置" if not game.train.siding.is_empty() else "无")
	_row(box, "AI 列车", func(): return "无" if game.ai_train == null else "%.1f km/h" %(
		game.ai_train.speed * 3.6))

	_section(box, "图形")
	_slider(box, "时间 时", 0.0, 24.0, 0.05,
			func(): return game.time_of_day,
			func(v): game.time_of_day = v; game._apply_time())
	_slider(box, "雾浓度", 0.0, 0.02, 0.0005,
			func(): return game.world_env.environment.fog_density,
			func(v): game.world_env.environment.fog_density = v)
	_slider(box, "阳光强度", 0.0, 2.0, 0.05,
			func(): return game.sun.light_energy,
			func(v): game.sun.light_energy = v)

	_section(box, "游戏")
	_row(box, "任务", func(): return game.mission.hud_text() if game.mission != null else "-")
	_row(box, "得分 / 完成次数", func(): return "%d / %d" %[
		game.mission.score_total if game.mission != null else 0,
		game.mission.completed if game.mission != null else 0])
	_hbox(box, [
		_button("重置列车", func():
			game.startup.reset()
			game.train.speed = 0.0
			game.hud.toast("调试：列车已复位到冷车状态", 2.4)),
		_button("跳过启动(测试)", func():
			game.startup.dev_skip()
			game.hud.toast("调试：已跳过冷车起动（标记为测试模式）", 2.6)),
		_button("重置任务", func():
			game._setup_mission()
			game.hud.toast("调试：任务已重置", 2.2)),
		_button("关闭", func(): toggle()),
	])

func _section(box: VBoxContainer, text: String) -> void:
	var l := Label.new()
	l.text = "── %s ──" %text
	l.add_theme_color_override("font_color", Color(0.62, 0.86, 1.0))
	box.add_child(l)

func _hint(box: VBoxContainer, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(0.75, 0.78, 0.82))
	box.add_child(l)

func _title(box: VBoxContainer, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 17)
	box.add_child(l)

func _row(box: VBoxContainer, key: String, getter: Callable) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var k := Label.new()
	k.text = key
	k.custom_minimum_size = Vector2(190, 0)
	k.add_theme_color_override("font_color", Color(0.72, 0.75, 0.8))
	h.add_child(k)
	var v := Label.new()
	v.text = "-"
	h.add_child(v)
	box.add_child(h)
	_rows.append({"label": v, "getter": getter})

func _slider(box: VBoxContainer, key: String, lo: float, hi: float, step: float,
		getter: Callable, setter: Callable) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var k := Label.new()
	k.text = key
	k.custom_minimum_size = Vector2(190, 0)
	k.add_theme_color_override("font_color", Color(0.72, 0.75, 0.8))
	h.add_child(k)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.custom_minimum_size = Vector2(120, 0)
	s.value = float(getter.call())
	h.add_child(s)
	var v := Label.new()
	v.custom_minimum_size = Vector2(60, 0)
	h.add_child(v)
	box.add_child(h)
	s.value_changed.connect(func(x):
		setter.call(x)
		v.text = "%.2f" %x)
	_rows.append({"label": v, "getter": func(): return "%.2f" %float(getter.call())})

func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(action)
	return b

func _hbox(box: VBoxContainer, items: Array) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	for it in items:
		h.add_child(it)
	box.add_child(h)

func _process(_delta: float) -> void:
	if not visible or game == null or game.train == null or game.startup == null:
		return
	for r in _rows:
		var l: Label = r ["label"]
		if is_instance_valid(l):
			l.text = str((r ["getter"] as Callable).call())