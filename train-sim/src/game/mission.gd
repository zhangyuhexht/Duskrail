extends Node
class_name MissionSystem



enum Phase {BRIEFING, LOADING, RUNNING, WAITING, UNLOADING, DONE}

signal task_started(index: int, task: Dictionary)
signal task_finished(index: int, result: Dictionary)
signal message(text: String)
signal all_done

const STOP_TOL := 5.0
const STOP_SPEED := 0.4
const OVERSHOOT := 12.0
const SAVE_PATH := "user://progress.cfg"

var route: Route
var train: Train
var stations: Array = []
var tasks: Array = []
var index := -1
var phase: int = Phase.BRIEFING
var progress := 0.0
var elapsed := 0.0
var overspeed_time := 0.0
var score_total := 0
var money := 0
var completed := 0
var last_result := {}
var task: Dictionary = {}
var time_scale_debug := 1.0
var _advance_timer := 0.0
var _stop_offset := 0.0
var pass_required := false
var pass_done := false
var single_job := false
var _all_done_emitted := false
var _wait_timer := 0.0

func setup(p_route: Route, p_train: Train, p_stations: Array, p_tasks: Array) -> void:
	route = p_route
	train = p_train
	stations = p_stations
	tasks = p_tasks
	start_task(0)



func start_task(i: int) -> void:
	if tasks.is_empty():
		return
	index = i %tasks.size()
	task = tasks [index]
	phase = Phase.BRIEFING
	progress = 0.0
	elapsed = 0.0
	overspeed_time = 0.0
	_advance_timer = 0.0
	_stop_offset = 0.0
	pass_required = bool(task.get("siding", false))
	pass_done = false
	_wait_timer = 0.0
	_all_done_emitted = false
	task_started.emit(index, task)
	message.emit("新任务：%s → %s（%s %s）" %[
		_origin() ["name"], _dest() ["name"], task ["cargo"], _amount()
	])


func _amount() -> String:
	var unit: String = String(task.get("unit", "t"))
	if unit == "人":
		return "%d 人" %int(task ["weight"])
	return "%.0f t" %float(task ["weight"])


func _is_pax() -> bool:
	return String(task.get("unit", "t")) == "人"

func _verb_load() -> String:
	return "旅客乘降" if _is_pax() else "装货"

func _verb_unload() -> String:
	return "旅客乘降" if _is_pax() else "卸货"

func _verb_loading() -> String:
	return "旅客乘降中" if _is_pax() else "装货中"

func _verb_unloading() -> String:
	return "旅客乘降中" if _is_pax() else "卸货中"


func notify_pass_done() -> void:
	if pass_done:
		return
	pass_done = true
	if phase == Phase.WAITING:
		message.emit("对向列车已通过，作业继续")

func _origin() -> Dictionary:
	if task.is_empty() or not task.has("origin") or stations.is_empty():
		return {"name": "—", "stop": 0.0}
	return stations [task ["origin"]]

func _dest() -> Dictionary:
	if task.is_empty() or not task.has("dest") or stations.is_empty():
		return {"name": "—", "stop": 0.0}
	return stations [task ["dest"]]


func stop_mark() -> float:
	if task.is_empty():
		return 0.0
	var st: Dictionary = _origin() if phase == Phase.BRIEFING or phase == Phase.LOADING else _dest()
	return float(st ["stop"])


func _signed_delta(a: float, b: float) -> float:
	var d := route.wrap_dist(a - b)
	var half := route.total * 0.5
	if d > half:
		d -= route.total
	return d


func head_offset() -> float:
	if task.is_empty() or route == null or train == null:
		return 0.0
	return _signed_delta(train.distance, stop_mark())


func distance_to_stop() -> float:
	return absf(head_offset())

func _physics_process(delta: float) -> void:
	if route == null or train == null or task.is_empty():
		return
	_stop_offset = head_offset()
	var stopped := absf(train.speed) < STOP_SPEED
	var on_mark := absf(_stop_offset) <= STOP_TOL
	match phase:
		Phase.BRIEFING:
			if on_mark and stopped:
				phase = Phase.LOADING
				progress = 0.0
				message.emit("开始%s：%s" %[_verb_load(), task ["cargo"]])
		Phase.LOADING:
			elapsed += delta
			if on_mark and stopped:
				progress = minf(1.0, progress + delta * time_scale_debug / maxf(1.0, float(task ["load_time"])))
			if progress >= 1.0:
				progress = 0.0
				phase = Phase.RUNNING
				elapsed = 0.0
				message.emit("%s完毕，前往 %s（限速 %.0f km/h）" %[_verb_load(), _dest() ["name"], task ["limit"]])
		Phase.RUNNING:
			elapsed += delta
			if train.speed_kmh() > float(task ["limit"]) + 3.0:
				overspeed_time += delta

			if _stop_offset > OVERSHOOT and absf(train.speed) < 1.0:
				message.emit("已越过停车标 %.0f 米，请后退对位" %_stop_offset)
			if on_mark and stopped:
				if pass_required and not pass_done:
					phase = Phase.WAITING
					_wait_timer = 0.0
					message.emit("已进入侧线待避，等待对向列车通过")
				else:
					phase = Phase.UNLOADING
					progress = 0.0
					message.emit("到达 %s，开始%s" %[_dest() ["name"], _verb_unload()])
		Phase.WAITING:
			_wait_timer += delta * maxf(1.0, time_scale_debug)
			if pass_done or _wait_timer > 150.0:
				phase = Phase.UNLOADING
				progress = 0.0
				message.emit("开始%s：%s" %[_verb_unload(), task ["cargo"]])
		Phase.UNLOADING:
			if on_mark and stopped:
				progress = minf(1.0, progress + delta * time_scale_debug / maxf(1.0, float(task ["unload_time"])))
			if progress >= 1.0:
				_finish_task()
		Phase.DONE:
			_advance_timer -= delta
			if _advance_timer <= 0.0:
				if single_job:
					if not _all_done_emitted:
						_all_done_emitted = true
						all_done.emit()
				else:
					start_task(index + 1)

func _finish_task() -> void:
	var precision := clampf(1.0 - absf(_stop_offset) / STOP_TOL, 0.0, 1.0)
	var time_bonus: float = maxf(0.0, float(task ["time_limit"]) - elapsed) * 1.5
	var penalty := overspeed_time * 25.0
	var total := int(float(task ["reward"]) *(0.6 + 0.4 * precision) + time_bonus - penalty)
	total = maxi(total, int(float(task ["reward"]) * 0.3))
	score_total += total
	money += total
	completed += 1
	last_result = {
		"task": index, "cargo": task ["cargo"], "precision": precision,
		"offset": _stop_offset, "time": elapsed, "overspeed": overspeed_time,
		"bonus": int(time_bonus), "penalty": int(penalty), "score": total,
	}
	phase = Phase.DONE
	progress = 1.0
	_advance_timer = 5.0 / maxf(1.0, time_scale_debug)
	task_finished.emit(index, last_result)
	message.emit("任务完成！得分 +%d（停车偏差 %.1f m，超速 %.0f s）" %[total, absf(_stop_offset), overspeed_time])


func begin_job(job: Dictionary, p_money: int, p_completed: int) -> void:
	tasks = [job]
	single_job = true
	index = -1
	score_total = 0
	money = p_money
	completed = p_completed
	_all_done_emitted = false
	start_task(0)


func restore_state(d: Dictionary) -> void:
	if tasks.is_empty():
		return
	var idx := clampi(int(d.get("index", 0)), 0, tasks.size() - 1)
	start_task(idx)
	phase = int(d.get("phase", Phase.BRIEFING))
	progress = float(d.get("progress", 0.0))
	elapsed = float(d.get("elapsed", 0.0))
	overspeed_time = float(d.get("overspeed_time", 0.0))
	pass_done = bool(d.get("pass_done", false))
	score_total = int(d.get("score", score_total))
	money = int(d.get("money", money))
	completed = int(d.get("completed", completed))
	_advance_timer = 8.0
	_wait_timer = 0.0
	_stop_offset = head_offset()



func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "score", score_total)
	cfg.set_value("progress", "money", money)
	cfg.set_value("progress", "completed", completed)
	cfg.save(SAVE_PATH)

func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	score_total = cfg.get_value("progress", "score", 0)
	money = cfg.get_value("progress", "money", 0)
	completed = cfg.get_value("progress", "completed", 0)



func phase_name() -> String:
	match phase:
		Phase.BRIEFING:
			return "前往 %s %s点停车" %[_origin() ["name"], _verb_load()]
		Phase.LOADING:
			return "%s（%s）" %[_verb_loading(), task ["cargo"]]
		Phase.RUNNING:
			return "运行至 %s" %_dest() ["name"]
		Phase.WAITING:
			return "侧线待避：等待对向列车通过"
		Phase.UNLOADING:
			return _verb_unloading()
		_:
			return "任务完成"

func hud_text() -> String:
	if task.is_empty():
		return "暂无任务"
	var lines: Array [String] = []
	lines.append("任务 %d/%d   %s %s" %[index + 1, tasks.size(), task ["cargo"], _amount()])
	lines.append("%s" %phase_name())
	var d := distance_to_stop()
	if phase == Phase.RUNNING or phase == Phase.WAITING:
		if d > 1200.0:
			lines.append("距 %s %.1f km   限速 %.0f km/h" %[_dest() ["name"], d / 1000.0, task ["limit"]])
		else:
			var sign_txt := "距停车标 %.0f m" %d
			if absf(_stop_offset) <= STOP_TOL:
				sign_txt = "已对准停车标（±%.0f m）" %STOP_TOL
			elif _stop_offset > STOP_TOL:
				sign_txt = "已越过停车标 %.0f m！" %_stop_offset
			lines.append("%s   建议速度 %.0f km/h" %[sign_txt, _suggest_speed(d)])
		if overspeed_time > 1.0:
			lines.append("超速累计 %.0f s（扣分中）" %overspeed_time)
	else:
		var st_name: String = _origin() ["name"] if(phase == Phase.BRIEFING or phase == Phase.LOADING) else _dest() ["name"]
		lines.append("停车位置 %s（精度 ±%.0f m）" %[st_name, STOP_TOL])
	lines.append("得分 %d   资金 %d 元   完成 %d 次" %[score_total, money, completed])
	return "\n".join(lines)


func _suggest_speed(d: float) -> float:
	if d < 30.0:
		return 3.0
	if d < 80.0:
		return 8.0
	if d < 200.0:
		return 18.0
	if d < 450.0:
		return 30.0
	return minf(float(task ["limit"]), 45.0)

func show_progress() -> bool:
	return phase == Phase.LOADING or phase == Phase.UNLOADING


func on_siding() -> bool:
	return pass_required