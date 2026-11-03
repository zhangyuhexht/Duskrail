extends CanvasLayer
class_name PauseMenu


signal resume
signal restart
signal to_menu
signal quit
signal save_requested
signal settings_changed
signal career_requested
signal tuning_requested
signal consist_requested

var _buttons: VBoxContainer
var _consist_button: Button
var _settings: SettingsPanel
var _panel: PanelContainer
var _status: Label
var _flash_token := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	layer = 20
	visible = false
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.1, 0.97)
	sb.border_color = Color(0.35, 0.45, 0.55, 0.9)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(26)
	_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	_panel.add_child(vb)

	var title := Label.new()
	title.text = "已暂停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	vb.add_child(title)
	vb.add_child(HSeparator.new())

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 10)
	_buttons.custom_minimum_size = Vector2(300, 0)
	vb.add_child(_buttons)
	_add_button("继续游戏", func() -> void: resume.emit())
	_add_button("任务中心 / 车库", func() -> void: career_requested.emit())
	_consist_button = _add_button("列车编组", func() -> void: consist_requested.emit())
	_add_button("改装车间", func() -> void: tuning_requested.emit())
	_add_button("保存游戏", func() -> void: save_requested.emit())
	_add_button("设置", _on_settings)
	_add_button("重新开始", func() -> void: restart.emit())
	_add_button("返回主菜单", func() -> void: to_menu.emit())
	_add_button("退出游戏", func() -> void: quit.emit())

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 14)
	_status.add_theme_color_override("font_color", Color(0.55, 0.9, 0.62))
	_status.custom_minimum_size = Vector2(300, 22)
	vb.add_child(_status)

	_settings = SettingsPanel.new()
	_settings.name = "SettingsPanel"
	add_child(_settings)
	_settings.closed.connect(_show_buttons)
	_settings.changed.connect(func() -> void: settings_changed.emit())

func _add_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 46)
	b.add_theme_font_size_override("font_size", 18)
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(cb)
	_buttons.add_child(b)
	return b

func set_consist_available(on: bool) -> void:
	if _consist_button != null:
		_consist_button.visible = on


func open() -> void:
	visible = true
	_show_buttons()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _buttons.get_child_count() > 0:
		(_buttons.get_child(0) as Button).grab_focus()

func close() -> void:
	visible = false
	if _settings != null:
		_settings.visible = false

func flash(text: String) -> void:
	if _status == null:
		return
	_status.text = text
	_flash_token += 1
	var tok := _flash_token
	await get_tree().create_timer(2.4, true).timeout
	if tok == _flash_token and _status != null:
		_status.text = ""

func _show_buttons() -> void:
	_buttons.visible = true
	if _settings != null:
		_settings.visible = false

func _on_settings() -> void:
	_buttons.visible = false
	_status.text = ""
	_settings.open(0)

func open_settings() -> void:
	_on_settings()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		if _settings.visible:
			_settings.close()
			_show_buttons()
		else:
			resume.emit()
		get_viewport().set_input_as_handled()
