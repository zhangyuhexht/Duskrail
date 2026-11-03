class_name CabInteraction
extends Node3D






const DEVICE_INFO := {
	"battery": ["主电源", "toggle"],
	"cab_key": ["司机室激活", "toggle"],
	"panto": ["受电弓", "toggle"],
	"vcb": ["主断路器", "toggle"],
	"atp": ["ATP 自检", "button"],
	"brake_test": ["制动试验", "button"],
	"reverser": ["方向手柄", "lever3"],
	"thrust": ["牵引手柄", "lever"],
	"brake": ["制动手柄", "lever"],
	"park_brake": ["停放制动", "toggle"],
	"horn": ["鸣笛", "button"],
	"headlight": ["前照灯", "toggle"],
	"wiper": ["雨刷", "toggle"],
	"cab_light": ["驾驶室灯", "toggle"],
	"doors": ["车门", "button"],
	"reset": ["复位", "button"],
	"cab_door_left": ["整列左侧车门", "button"],
	"cab_door_right": ["整列右侧车门", "button"],
}

const DEVICE_DESC := {
	"battery": "接通或断开整车控制电源。",
	"cab_key": "激活或关闭司机室控制。",
	"panto": "升弓或降弓，接通接触网电源。",
	"vcb": "合上或断开主断路器。",
	"atp": "执行 ATP 自检。",
	"brake_test": "执行制动试验。",
	"reverser": "选择列车前进或后退方向。",
	"thrust": "控制牵引级位。",
	"brake": "控制列车制动力。",
	"park_brake": "施加或缓解停放制动。",
	"horn": "鸣笛。",
	"headlight": "开启或关闭前照灯。",
	"wiper": "开启或关闭雨刷。",
	"cab_light": "开启或关闭司机室照明。",
	"doors": "在停靠站台并施加停放制动后，同步开启站台侧整列车门。",
	"reset": "复位故障提示。",
	"cab_door_left": "在站台停稳并施加停放制动后，同步开启整列左侧车门（含司机室门）。",
	"cab_door_right": "在站台停稳并施加停放制动后，同步开启整列右侧车门（含司机室门）。",
}

const MAX_PICK_DIST := 5.8
const PICK_COS := 0.984
const DRAG_SCALE := 0.0075

var train: Train
var camera: Camera3D
var handler: Callable
var feedback: Callable
var enabled := true

var devices: Array [Dictionary] = []
var hovered := -1
var dragging := false

var _drag_id := ""
var _drag_from_y := 0.0
var _drag_from_value := 0.0
var _reticle: MeshInstance3D

signal hover_changed(device_id: String, text: String, description: String)

func setup(p_train: Train, p_cam: Camera3D, p_handler: Callable, p_feedback: Callable) -> void:
	train = p_train
	camera = p_cam
	handler = p_handler
	feedback = p_feedback
	_build_reticle()
	rebuild()

func _build_reticle() -> void:
	_reticle = MeshInstance3D.new()
	_reticle.name = "CabReticle"
	_reticle.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var q := QuadMesh.new()
	q.size = Vector2(0.085, 0.085)
	_reticle.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.55, 1.0, 0.85, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.disable_receive_shadows = true
	_reticle.material_override = m
	_reticle.visible = false
	add_child(_reticle)


func rebuild() -> void:
	devices.clear()
	hovered = -1
	if train == null or train.vehicles.is_empty():
		return
	var v: Vehicle = train._cab_vehicle()
	if v == null:
		return
	for node in v.find_children("Dev_*", "Node3D", true, false):
		var id := String(node.name).substr(4)
		if not DEVICE_INFO.has(id):
			continue
		var info: Array = DEVICE_INFO [id]
		devices.append({
			"id": id,
			"label": String(info [0]),
			"kind": String(info [1]),
			"node": node,
			"radius": 0.16 if String(info [1]).begins_with("lever") else 0.06,
		})

func hovered_label() -> String:
	if hovered < 0:
		return ""
	var d: Dictionary = devices [hovered]
	return String(d ["label"])

func hovered_id() -> String:
	if hovered < 0:
		return ""
	return String(devices [hovered] ["id"])


func hovered_description() -> String:
	var id := hovered_id()
	return String(DEVICE_DESC.get(id, ""))

func _cam() -> Camera3D:
	if camera != null and is_instance_valid(camera):
		return camera
	return get_viewport().get_camera_3d()

func _pick() -> void:
	var prev := hovered
	hovered = -1
	var cam := _cam()
	if not enabled or cam == null or devices.is_empty():
		if _reticle != null:
			_reticle.visible = false
		if prev != -1:
			hover_changed.emit("", "", "")
		return
	var origin := cam.global_position
	var mouse_pos := get_viewport().get_mouse_position()
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_pos = get_viewport().get_visible_rect().size * 0.5
	var best_score := INF
	for i in range(devices.size()):
		var d: Dictionary = devices [i]
		var node: Node3D = d ["node"]
		if node == null or not node.is_inside_tree() or not node.is_visible_in_tree():
			continue
		var visual := _visual_pos(node)
		var to := visual - origin
		var dist := to.length()
		if dist < 0.05 or dist > MAX_PICK_DIST:
			continue
		if cam.is_position_behind(visual):
			continue
		var screen_pos := cam.unproject_position(visual)
		var radius_px := clampf(1050.0 * float(d ["radius"]) / maxf(dist, 0.6), 24.0, 88.0)
		var pixel_dist := screen_pos.distance_to(mouse_pos)
		if pixel_dist > radius_px:
			continue
		var score := pixel_dist / radius_px
		if score < best_score:
			best_score = score
			hovered = i
	if _reticle != null:
		if hovered >= 0:
			var d2: Dictionary = devices [hovered]
			_reticle.global_position = _visual_pos(d2 ["node"] as Node3D)
			_reticle.visible = true
		else:
			_reticle.visible = false
	if hovered != prev:
		hover_changed.emit(hovered_id(), hovered_label(), hovered_description())


func _visual_pos(node: Node3D) -> Vector3:
	if node.is_inside_tree():
		return node.get_global_transform_interpolated().origin
	return node.global_position

func _process(_delta: float) -> void:
	_pick()

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	var cam := _cam()
	if cam == null or not cam.is_current():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			if hovered < 0:
				return
			var d: Dictionary = devices [hovered]
			if String(d ["kind"]).begins_with("lever"):
				dragging = true
				_drag_id = String(d ["id"])
				_drag_from_y = mb.position.y
				_drag_from_value = _lever_value(_drag_id)
				_emit("拖拽调节 %s" %String(d ["label"]))
			else:
				_fire(_drag_id if false else String(d ["id"]), -1.0)
		else:
			dragging = false
			_drag_id = ""
	elif event is InputEventMouseMotion and dragging:
		var mm := event as InputEventMouseMotion
		var v := clampf(_drag_from_value +(_drag_from_y - mm.position.y) * DRAG_SCALE, 0.0, 1.0)
		_fire(_drag_id, v)

func _lever_value(id: String) -> float:
	if train == null:
		return 0.0
	match id:
		"thrust":
			return clampf(float(train.notch) / 8.0, 0.0, 1.0)
		"brake":
			return clampf(float(train.brake_notch) / 7.0, 0.0, 1.0)
	return 0.0

func _fire(id: String, value: float) -> void:
	if handler.is_valid():
		var msg: String = handler.call(id, value)
		if msg != "":
			_emit(msg)

func _emit(text: String) -> void:
	if feedback.is_valid():
		feedback.call(text)