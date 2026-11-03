class_name TrainStartup
extends RefCounted

















enum State {
	COLD_AND_DARK, AUX_POWER, CAB_ACTIVE, SYSTEM_INIT, SAFETY_CHECK,
	BRAKE_CHECK, READY, DEPARTURE_READY, RUNNING, FAULT
}

const STATE_NAMES := [
	"全车断电", "辅助供电", "司机室激活", "系统初始化", "安全自检",
	"制动试验", "整备完成", "出发准备完毕", "运行中", "故障"
]

var train: Train
var def: TrainDef

var state := State.COLD_AND_DARK
var log: Array [String] = []
var fault_text := ""
var resume_state := State.READY


var battery_on := false
var cab_active := false
var panto_cmd := false
var panto_up := false
var vcb_on := false
var atp_ok := false
var brake_test_ok := false
var park_brake := true
var headlight_on := true
var wiper_on := false
var cab_light_on := true
var horn_used := false

var _timer := 0.0
var _timer_total := 0.0
var _busy := ""
var _base_traction := 0.0
var _dev_skip := false

func _init(p_train: Train, p_def: TrainDef) -> void:
	train = p_train
	def = p_def
	_base_traction = train.max_tractive_force if train != null else 420000.0

	reset()

func reset() -> void:
	state = State.COLD_AND_DARK
	fault_text = ""
	resume_state = State.READY
	battery_on = false
	cab_active = false
	panto_cmd = false
	panto_up = false
	vcb_on = false
	atp_ok = false
	brake_test_ok = false
	park_brake = true
	wiper_on = false
	horn_used = false
	_dev_skip = false
	_timer = 0.0
	_timer_total = 0.0
	_busy = ""
	log.clear()
	_log("复位：全车断电（冷车）")
	if train != null:
		train.set_gear(Train.GEAR_P3)
		train.handbrake = true
		train.doors_open = false
		train.door_open_side = 0
		train.cab_door_only = false
		train.speed = 0.0
		train.emergency = false
	apply_physics()

func prepare_for_service() -> void:
	reset()
	battery_on = true
	cab_active = true
	panto_cmd = true
	panto_up = true
	vcb_on = true
	atp_ok = true
	brake_test_ok = true
	park_brake = false
	state = State.DEPARTURE_READY
	if train != null:
		train.handbrake = false
		train.speed = 0.0
		train.emergency = false
		train.set_gear(Train.GEAR_P3)
	apply_physics()
	_log("整备完成：冷车起动已由地勤完成，选择档位即可发车")

func serialize() -> Dictionary:
	return {
		"state": int(state),
		"battery_on": battery_on,
		"cab_active": cab_active,
		"panto_cmd": panto_cmd,
		"panto_up": panto_up,
		"vcb_on": vcb_on,
		"atp_ok": atp_ok,
		"brake_test_ok": brake_test_ok,
		"park_brake": park_brake,
		"headlight_on": headlight_on,
		"wiper_on": wiper_on,
		"cab_light_on": cab_light_on,
	}

func restore(d: Dictionary) -> void:
	reset()
	state = int(d.get("state", State.COLD_AND_DARK))
	battery_on = bool(d.get("battery_on", false))
	cab_active = bool(d.get("cab_active", false))
	panto_cmd = bool(d.get("panto_cmd", false))
	panto_up = bool(d.get("panto_up", false))
	vcb_on = bool(d.get("vcb_on", false))
	atp_ok = bool(d.get("atp_ok", false))
	brake_test_ok = bool(d.get("brake_test_ok", false))
	park_brake = bool(d.get("park_brake", true))
	headlight_on = bool(d.get("headlight_on", true))
	wiper_on = bool(d.get("wiper_on", false))
	cab_light_on = bool(d.get("cab_light_on", true))
	if panto_up:
		panto_cmd = true
	if train != null:
		train.handbrake = park_brake
		train.set_light_state(headlight_on)
	apply_physics()
	_log("读取存档：%s" %state_name())


func dev_skip() -> void:
	reset()
	battery_on = true
	cab_active = true
	panto_cmd = true
	panto_up = true
	vcb_on = true
	atp_ok = true
	brake_test_ok = true
	park_brake = false
	state = State.DEPARTURE_READY
	_dev_skip = true
	if train != null:
		train.handbrake = false
		train.speed = 0.0
		train.set_gear(Train.GEAR_N)
	_log("【测试模式】跳过冷车起动流程，直接进入出发准备完毕")
	apply_physics()

func is_test_mode() -> bool:
	return _dev_skip

func state_index() -> int:
	return int(state)

func state_name() -> String:
	return STATE_NAMES [int(state)]

func step_progress() -> float:
	if _busy == "" or _timer_total <= 0.0:
		return 1.0
	return clampf(1.0 - _timer / _timer_total, 0.0, 1.0)


func instruments_live() -> bool:
	return state != State.COLD_AND_DARK and state != State.FAULT


func can_traction() -> bool:
	if state == State.FAULT or state == State.COLD_AND_DARK:
		return false
	if not vcb_on or not panto_up:
		return false
	if park_brake:
		return false
	if train != null and train.doors_open:
		return false
	return int(state) >= int(State.DEPARTURE_READY)


func apply_physics() -> void:
	if train == null:
		return
	train.max_tractive_force = _base_traction if can_traction() else 0.0
	train.pantograph_up = panto_up
	if panto_cmd and not panto_up:

		train.max_tractive_force = 0.0


func recapture_base() -> void:
	if train == null:
		return
	_base_traction = train.max_tractive_force
	if _base_traction <= 0.0:
		_base_traction = 420000.0
	apply_physics()

func step(delta: float) -> void:
	if _busy != "":
		_timer -= delta
		if _timer <= 0.0:
			_finish_step()
	if state == State.RUNNING and not can_traction():

		state = State.DEPARTURE_READY
		_log("牵引条件不满足（车门/停放制动/主断），退回出发准备")
	apply_physics()

func _log(text: String) -> void:
	log.append(text)
	if log.size() > 60:
		log.pop_front()



func press(id: String, value := -1.0) -> String:
	match id:
		"battery":
			if state == State.COLD_AND_DARK:
				battery_on = true
				cab_active = true
				panto_cmd = true
				panto_up = true
				vcb_on = true
				atp_ok = true
				brake_test_ok = true
				park_brake = false
				state = State.DEPARTURE_READY
				if train != null:
					train.handbrake = false
					train.emergency = false
				_log("① 主电源闭合：受电弓、主断路器与自检自动完成")
				_log("整备完成：停放制动已缓解，可直接升档起步")
				apply_physics()
				return "① 主电源已接通，可以起步"
			battery_on = false
			cab_active = false
			panto_cmd = false
			panto_up = false
			vcb_on = false
			atp_ok = false
			brake_test_ok = false
			park_brake = true
			state = State.COLD_AND_DARK
			_busy = ""
			_timer = 0.0
			_timer_total = 0.0
			if train != null:
				train.handbrake = true
				train.emergency_brake()
			_log("主电源断开：全车断电，停放制动施加")
			apply_physics()
			return "主电源已断开"
		"cab_key":
			if state == State.AUX_POWER:
				cab_active = true
				state = State.CAB_ACTIVE
				_log("② 司机室激活：操纵台得电")
				return "② 司机室已激活，可以升弓"
			if state == State.COLD_AND_DARK:
				return "✗ 无辅助电源，先闭合蓄电池"
			return "司机室激活 %s" %("开" if cab_active else "关")
		"panto":
			if state == State.COLD_AND_DARK:
				return "✗ 无辅助电源，无法升弓"
			if state == State.AUX_POWER:
				return "✗ 请先激活司机室"
			if not panto_up and not panto_cmd and int(state) <= int(State.CAB_ACTIVE):
				panto_cmd = true
				state = State.SYSTEM_INIT
				_start_step("panto", maxf(0.5, def.sim_panto_seconds), "③ 受电弓上升中…")
				return "③ 升弓指令已发出"
			if panto_up:
				if vcb_on:
					return "✗ 先断开主断路器再降弓"
				panto_cmd = false
				panto_up = false
				state = State.CAB_ACTIVE
				_log("受电弓已降下")
				return "受电弓下降"
			return "受电弓动作中…"
		"vcb":
			if not panto_up:
				_fault("受电弓未升起就闭合主断路器（联锁保护动作）")
				return "✗ 故障：受电弓未升起"
			if state != State.SYSTEM_INIT:
				if vcb_on:
					vcb_on = false
					_log("主断路器分断")
					return "主断路器分断"
				return "当前状态不允许闭合主断"
			vcb_on = true
			state = State.SAFETY_CHECK
			_log("④ 主断路器闭合：主电路得电")
			return "④ 主断闭合，进行安全自检"
		"atp":
			if state != State.SAFETY_CHECK:
				return "当前状态无需 ATP 自检"
			if not vcb_on:
				return "✗ 主断路器未闭合"
			_start_step("atp", maxf(0.4, def.sim_atp_seconds), "⑤ ATP 自检中…")
			return "⑤ ATP 自检开始"
		"brake_test":
			if state != State.BRAKE_CHECK:
				return "当前状态无需制动试验"
			_start_step("brake_test", maxf(0.4, def.sim_brake_test_seconds), "⑥ 制动试验中…")
			return "⑥ 制动试验开始"
		"park_brake":
			if state == State.COLD_AND_DARK:
				return "✗ 无电，停放制动为机械施加"
			park_brake = not park_brake
			train.handbrake = park_brake
			_log("停放制动 %s" %("施加" if park_brake else "缓解"))
			_check_ready()
			return "停放制动%s" %("已施加" if park_brake else "已缓解")
		"reverser":
			if state == State.COLD_AND_DARK:
				return "✗ 无电，方向手柄无作用"
			var next := [1, 0, -1]
			var i := next.find(train.reverser)
			train.reverser = next [(i + 1) %3]
			_check_ready()
			var names := {1: "前进", 0: "中立", -1: "后进"}
			return "方向手柄：%s" %names [train.reverser]
		"thrust":
			if value >= 0.0:
				return set_thrust(value)
			return "档位：%s" %train.gear_name()
		"brake":
			if value >= 0.0:
				var lvl := int(round(value * 7.0))
				train.set_brake(lvl)
				match lvl:
					7:
						train.gear = Train.GEAR_P3
					5, 6:
						train.gear = Train.GEAR_P2
					1, 2, 3, 4:
						train.gear = Train.GEAR_P1
					0:
						train.gear = Train.GEAR_N
				return "制动手柄：%d 级（%s）" %[train.brake_notch, train.gear_name()]
			return "制动手柄：%d 级（%s）" %[train.brake_notch, train.gear_name()]
		"horn":
			horn_used = true
			return "鸣笛"
		"headlight":
			headlight_on = not headlight_on
			if train != null:
				train.set_light_state(headlight_on)
			return "前照灯%s" %("开" if headlight_on else "关")
		"wiper":
			wiper_on = not wiper_on
			return "雨刷%s" %("开" if wiper_on else "关")
		"cab_light":
			cab_light_on = not cab_light_on
			return "驾驶室灯%s" %("开" if cab_light_on else "关")
		"doors":
			if absf(train.speed) > 0.4:
				return "✗ 行驶中不能开关车门，请先停车"
			train.doors_open = not train.doors_open
			_log("车门%s" %("开启" if train.doors_open else "关闭"))
			return "车门%s" %("开启" if train.doors_open else "关闭")
		"reset":
			if state == State.FAULT:
				state = resume_state
				fault_text = ""
				if train != null:
					train.emergency = false
				_log("故障已复位")
				return "故障已复位"
			return "无故障"
	return ""


func set_thrust(value: float) -> String:
	var level := clampi(int(round(value * 5.0)), 0, 5)
	if level > 0 and not can_traction():
		return "✗ 动力未接通：%s" %readiness_text()
	train.set_gear(Train.GEAR_N if level == 0 else Train.GEAR_D1 + level - 1)
	if level > 0 and state == State.DEPARTURE_READY:
		state = State.RUNNING
		_log("⑧ 开始牵引，进入运行")
	return "档位：%s" %train.gear_name()

func readiness_text() -> String:
	if train == null:
		return ""
	if state == State.FAULT:
		return "故障：%s（在司机室按【复位】）" %fault_text
	if state == State.COLD_AND_DARK or int(state) < int(State.DEPARTURE_READY):
		return "起动流程未完成（%s）：%s" %[state_name(), hint()]
	if park_brake:
		return "停放制动未缓解（按 B 缓解）"
	if train.doors_open:
		return "车门未关闭（按 A 关闭车门）"
	if not panto_up or not vcb_on:
		return "主电路未接通（受电弓 / 主断路器）"
	return "就绪"

func readiness_short() -> String:
	if state == State.FAULT:
		return "故障未复位"
	if state == State.COLD_AND_DARK or int(state) < int(State.DEPARTURE_READY):
		return "起动流程未完成"
	if park_brake:
		return "停放制动未缓解"
	if train != null and train.doors_open:
		return "车门未关闭"
	if not panto_up or not vcb_on:
		return "主电路未接通"
	return "就绪"

func on_drive_gear(driving: bool) -> void:
	if train == null:
		return
	if driving:
		if can_traction() and state == State.DEPARTURE_READY:
			state = State.RUNNING
			_log("⑧ 开始牵引，进入运行")
	elif state == State.RUNNING:
		state = State.DEPARTURE_READY
		_log("牵引回零，退回出发准备")
	apply_physics()

func _check_ready() -> void:
	if state == State.READY and train.reverser > 0 and not park_brake:
		state = State.DEPARTURE_READY
		_log("⑦ 方向前进、停放制动缓解：出发准备完毕")

func _start_step(id: String, seconds: float, message: String) -> void:
	_busy = id
	_timer = seconds
	_timer_total = seconds
	_log(message)

func _finish_step() -> void:
	var id := _busy
	_busy = ""
	_timer = 0.0
	_timer_total = 0.0
	match id:
		"panto":
			panto_up = true
			_log("受电弓已升起（等待闭合主断路器）")
		"atp":
			atp_ok = true
			state = State.BRAKE_CHECK
			_log("⑤ ATP 自检通过 → 请做制动试验")
		"brake_test":
			brake_test_ok = true
			state = State.READY
			_log("⑥ 制动试验通过 → 方向手柄置前进并缓解停放制动")
	apply_physics()

func _fault(text: String) -> void:
	resume_state = state if state != State.FAULT else resume_state
	state = State.FAULT
	fault_text = text
	_log("⚠ 故障：%s" %text)
	if train != null:
		train.emergency_brake()
	apply_physics()


func hint() -> String:
	var busy := state == State.SYSTEM_INIT and _busy == "panto"
	match state:
		State.COLD_AND_DARK:
			return "冷车：打开【主电源】开关（操纵台），整车自动整备"
		State.AUX_POWER:
			return "② 打开【司机室激活】（钥匙）"
		State.CAB_ACTIVE:
			return "③ 操作【受电弓】开关：升弓"
		State.SYSTEM_INIT:
			if busy:
				return "受电弓上升中… %.0f%%" %(step_progress() * 100.0)
			return "④ 闭合【主断路器】"
		State.SAFETY_CHECK:
			if _busy == "atp":
				return "ATP 自检中… %.0f%%" %(step_progress() * 100.0)
			return "⑤ 按下【ATP 自检】"
		State.BRAKE_CHECK:
			if _busy == "brake_test":
				return "制动试验中… %.0f%%" %(step_progress() * 100.0)
			return "⑥ 按下【制动试验】"
		State.READY:
			var parts: Array [String] = []
			if train.reverser <= 0:
				parts.append("挂入前进档（按 W 升档）")
			if park_brake:
				parts.append("缓解停放制动")
			if train.doors_open:
				parts.append("等待乘降完成（车门开启）")
			if parts.is_empty():
				return "⑦ 准备完毕"
			return "⑦ %s" %"，".join(parts)
		State.DEPARTURE_READY:
			if train.doors_open:
				return "车门开启中：等待乘降结束后牵引"
			return "主电源已接通：按 W 升档至 D1 起步"
		State.RUNNING:
			return "运行中：W/S 换档 · A 车门 · D 车灯"
		State.FAULT:
			return "⚠ %s —— 按【复位】清除" %fault_text
	return ""