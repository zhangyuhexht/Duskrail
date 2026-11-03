extends Control
class_name MapView


enum Mode {MINI, FULL}

signal full_closed

var route: Route
var stations: Array = []
var lakes: Array = []
var train: Train
var ai_train: Train
var siding: Dictionary = {}
var signal_points: Array = []
var mission: MissionSystem

var mode: Mode = Mode.MINI
var mini_zoom := false
var just_closed := false

var _line := PackedVector2Array()
var _sid_line := PackedVector2Array()
var _bounds := Rect2()
var _has_bounds := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)
	_fit()
	get_viewport().size_changed.connect(_fit)

func _fit() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	queue_redraw()

func setup(p_route: Route, p_stations: Array, p_train: Train, p_ai: Train,
		p_siding: Dictionary, p_signals: Array, p_mission: MissionSystem, p_lakes: Array = []) -> void:
	route = p_route
	stations = p_stations
	lakes = p_lakes
	train = p_train
	ai_train = p_ai
	siding = p_siding
	signal_points = p_signals
	mission = p_mission
	_build_lines()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fit()

func is_full() -> bool:
	return mode == Mode.FULL


func cycle_mini_mode() -> String:
	if mode != Mode.MINI:
		return ""
	mini_zoom = not mini_zoom
	queue_redraw()
	return "小地图：放大" if mini_zoom else "小地图：全览"

func open_full() -> void:
	mode = Mode.FULL
	just_closed = false
	visible = true
	queue_redraw()

func close_full() -> void:
	if mode != Mode.FULL:
		return
	mode = Mode.MINI
	just_closed = true
	queue_redraw()
	full_closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if mode != Mode.FULL:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("map_toggle"):
		get_viewport().set_input_as_handled()
		close_full()

func _build_lines() -> void:
	_line = PackedVector2Array()
	_sid_line = PackedVector2Array()
	if route == null:
		return
	var minp := Vector2(INF, INF)
	var maxp := Vector2(- INF, - INF)
	var d := 0.0
	while d < route.total:
		var p := route.position_at(d)
		var v := Vector2(p.x, p.z)
		_line.append(v)
		minp = minp.min(v)
		maxp = maxp.max(v)
		d += 12.0
	if not siding.is_empty():
		var s := float(siding ["in"])
		var e := float(siding ["out"])
		while s <= e:
			var fp := route.frame_at(s)
			var p2 := fp.origin + fp.basis.x * Config.siding_lateral(route, s, siding)
			_sid_line.append(Vector2(p2.x, p2.z))
			minp = minp.min(Vector2(p2.x, p2.z))
			maxp = maxp.max(Vector2(p2.x, p2.z))
			s += 12.0
	_bounds = Rect2(minp, maxp - minp)
	_has_bounds = true

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _map_rect() -> Rect2:
	var w := size.x
	var h := size.y
	if mode == Mode.MINI:
		var mw := 380.0
		var mh := 250.0
		if w < 900.0:
			mw = 320.0
			mh = 210.0
		return Rect2(Vector2(w - mw - 18.0, h - mh - 18.0), Vector2(mw, mh))
	var margin := 80.0
	var top := 92.0
	var bottom := 80.0
	var avail_w := w - margin * 2.0
	var avail_h := h - top - bottom
	var rw := minf(avail_w, avail_h * 1.5)
	var rh := rw / 1.5
	return Rect2(Vector2((w - rw) * 0.5, top + (avail_h - rh) * 0.5), Vector2(rw, rh))

func _xform() -> Transform2D:
	var rect := _map_rect()
	if not _has_bounds or _bounds.size.x <= 0.1:
		return Transform2D()
	var view := _bounds
	if mode == Mode.MINI and mini_zoom and train != null:
		var center := Vector2(train.head_position().x, train.head_position().z)
		var aspect := maxf(rect.size.x / maxf(rect.size.y, 1.0), 0.1)
		var view_w := 14000.0
		var view_h := view_w / aspect
		view = Rect2(center - Vector2(view_w, view_h) * 0.5, Vector2(view_w, view_h))
	var pad := 14.0 if mode == Mode.MINI else 26.0
	var sc := minf((rect.size.x - pad * 2.0) / view.size.x,
			(rect.size.y - pad * 2.0) / view.size.y)
	var center_map := view.position + view.size * 0.5
	var org := rect.position + rect.size * 0.5 - center_map * sc
	return Transform2D(Vector2(sc, 0.0), Vector2(0.0, sc), org)


func _rect_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		rect.position + Vector2(0.0, rect.size.y),
		rect.position + rect.size,
		rect.position + Vector2(rect.size.x, 0.0),
	])


func _draw_clipped_polyline(points: PackedVector2Array, rect: Rect2,
		color: Color, width: float) -> void:
	if points.size() < 2:
		return
	var parts := Geometry2D.intersect_polyline_with_polygon(points, _rect_polygon(rect))
	for part: PackedVector2Array in parts:
		if part.size() >= 2:
			draw_polyline(part, color, width, true)

func _draw() -> void:
	if route == null:
		return
	var mini := mode == Mode.MINI
	var font := get_theme_default_font()
	var rect := _map_rect()
	var pad := 12.0 if mini else 74.0
	var outer := rect.grow(pad)

	if not mini:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.02, 0.04, 0.72), true)

	draw_rect(outer, Color(0.03, 0.05, 0.08, 0.92), true)
	draw_rect(outer, Color(0.36, 0.45, 0.54, 0.85), false, 2.0)
	draw_rect(rect, Color(0.06, 0.09, 0.13, 0.95), true)
	draw_rect(rect, Color(0.24, 0.31, 0.38, 0.9), false, 1.0)

	var title_size := 14 if mini else 24
	var sub_size := 11 if mini else 15
	if font != null:
		if mini:
			var mode_name := "放大" if mini_zoom else "全览"
			draw_string(font, Vector2(outer.position.x + 10.0, outer.position.y + 22.0),
					"线路图 · %s" %mode_name, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color(0.86, 0.92, 1.0))
			draw_string(font, Vector2(outer.position.x + outer.size.x - 152.0, outer.position.y + 22.0),
					"F5 切换   M 大地图", HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size, Color(0.55, 0.65, 0.75))
		else:
			var gear := train.gear_name() if train != null else "-"
			var pos_km := train.distance / 1000.0 if train != null else 0.0
			draw_string(font, Vector2(outer.position.x + 18.0, outer.position.y + 34.0),
					"线路图  ·  山川环线", HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color(0.86, 0.92, 1.0))
			draw_string(font, Vector2(outer.position.x + 18.0, outer.position.y + 60.0),
					"总里程 %.1f km    当前位置 %.2f km    档位 %s    ESC 返回游戏" %[
						route.total / 1000.0, pos_km, gear],
					HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size, Color(0.6, 0.7, 0.8))

	var xf := _xform()
	var map_scale := xf.get_scale().x
	var cull_local := mini and mini_zoom
	var cull_rect := rect.grow(24.0)
	for lake in lakes:
		var lake_center := xf * Vector2(lake ["center"])
		var lake_radius := float(lake ["radius"]) * map_scale
		if lake_radius < 2.0:
			continue
		if cull_local and not cull_rect.grow(lake_radius).has_point(lake_center):
			continue
		draw_circle(lake_center, lake_radius, Color(0.1, 0.28, 0.46, 0.52))
		draw_arc(lake_center, lake_radius, 0.0, TAU, 48, Color(0.36, 0.63, 0.86, 0.58), 1.2, true)
	var grid := 4 if mini else 6
	for i in range(-grid, grid + 1):
		var gx := rect.position.x + rect.size.x * (0.5 + float(i) / float(grid * 2))
		var gy := rect.position.y + rect.size.y * (0.5 + float(i) / float(grid * 2))
		draw_line(Vector2(gx, rect.position.y), Vector2(gx, rect.position.y + rect.size.y), Color(0.16, 0.2, 0.25, 0.5), 1.0)
		draw_line(Vector2(rect.position.x, gy), Vector2(rect.position.x + rect.size.x, gy), Color(0.16, 0.2, 0.25, 0.5), 1.0)

	var pts := PackedVector2Array()
	if mini and mini_zoom and train != null:
		# Local route slice around the train, clipped to the mini-map window.
		var local_pts := PackedVector2Array()
		var d0 := train.distance - 9000.0
		var d1 := train.distance + 9000.0
		var dd := d0
		while dd <= d1:
			var wp := route.position_at(dd)
			local_pts.append(xf * Vector2(wp.x, wp.z))
			dd += 12.0
		_draw_clipped_polyline(local_pts, rect, Color(0.3, 0.36, 0.42), 5.0 if mini else 7.0)
		_draw_clipped_polyline(local_pts, rect, Color(0.86, 0.9, 0.94), 2.0 if mini else 3.0)
	else:
		for p in _line:
			pts.append(xf * p)
		pts.append(pts [0])
		draw_polyline(pts, Color(0.3, 0.36, 0.42), 5.0 if mini else 7.0, true)
		draw_polyline(pts, Color(0.86, 0.9, 0.94), 2.0 if mini else 3.0, true)

	if _sid_line.size() > 1:
		var spts := PackedVector2Array()
		for p in _sid_line:
			spts.append(xf * p)
		if mini and mini_zoom:
			_draw_clipped_polyline(spts, rect, Color(0.95, 0.72, 0.2), 2.0 if mini else 3.0)
		else:
			draw_polyline(spts, Color(0.95, 0.72, 0.2), 2.0 if mini else 3.0, true)

	for sd in signal_points:
		var wp0 := route.position_at(float(sd))
		var sp := xf * Vector2(wp0.x, wp0.z)
		if cull_local and not cull_rect.has_point(sp):
			continue
		draw_circle(sp, 2.0 if mini else 3.0, Color(0.3, 0.95, 0.45))

	for i in range(stations.size()):
		var st: Dictionary = stations [i]
		var wp := route.position_at(float(st ["stop"]))
		var sp2 := xf * Vector2(wp.x, wp.z)
		if cull_local and not cull_rect.has_point(sp2):
			continue
		var is_dest := false
		if mission != null and not mission.task.is_empty():
			is_dest = int(mission.task ["dest"]) == i and mission.phase != MissionSystem.Phase.DONE
		draw_circle(sp2, 5.0 if mini else 9.0, Color(0.1, 0.14, 0.2))
		draw_circle(sp2, 3.5 if mini else 6.5, Color(0.95, 0.62, 0.18) if is_dest else Color(0.3, 0.62, 0.9))
		if font != null:
			var label: String = String(st ["name"])
			if is_dest and not mini:
				label += "  ← 目的地"
			draw_string(font, sp2 + (Vector2(8, 4) if mini else Vector2(13, 5)), label,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11 if mini else 17,
					Color(1.0, 0.86, 0.55) if is_dest else Color(0.8, 0.9, 1.0))

	if not siding.is_empty():
		var swp := route.position_at(float(siding ["stop"]))
		var swf := route.frame_at(float(siding ["stop"]))
		var slp := swp + swf.basis.x * float(siding ["offset"])
		var sp3 := xf * Vector2(slp.x, slp.z)
		if not cull_local or cull_rect.has_point(sp3):
			draw_circle(sp3, 3.0 if mini else 4.5, Color(0.98, 0.4, 0.25))

	if ai_train != null and ai_train.visible and not ai_train.vehicles.is_empty():
		_draw_train(xf, ai_train, Color(0.72, 0.74, 0.78), font, "对向列车", mini)

	if train != null and not train.vehicles.is_empty():
		_draw_train(xf, train, Color(0.35, 0.95, 0.95), font, "本务", mini)
		if not mini:
			var tp := xf * Vector2(train.head_position().x, train.head_position().z)
			draw_arc(tp, 15.0, 0.0, TAU, 40, Color(0.35, 0.95, 0.95, 0.65), 2.0, true)

	if not mini and font != null:
		var ly := outer.position.y + outer.size.y - 42.0
		var lx := outer.position.x + 18.0
		draw_circle(Vector2(lx, ly), 5.0, Color(0.35, 0.95, 0.95))
		draw_string(font, Vector2(lx + 12.0, ly + 5.0), "本务列车", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.75, 0.85, 0.92))
		draw_circle(Vector2(lx + 130.0, ly), 5.0, Color(0.72, 0.74, 0.78))
		draw_string(font, Vector2(lx + 142.0, ly + 5.0), "对向列车", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.75, 0.85, 0.92))
		draw_line(Vector2(lx + 260.0, ly), Vector2(lx + 292.0, ly), Color(0.95, 0.72, 0.2), 3.0)
		draw_string(font, Vector2(lx + 300.0, ly + 5.0), "侧线（待避）", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.75, 0.85, 0.92))
		draw_string(font, Vector2(lx + 450.0, ly + 5.0), "比例尺 500 m", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.55, 0.65, 0.75))
		var sc2 := xf.basis_xform(Vector2(1, 0)).length()
		draw_line(Vector2(lx + 560.0, ly), Vector2(lx + 560.0 + 500.0 * sc2, ly), Color(0.7, 0.8, 0.88), 2.0)
		draw_line(Vector2(lx + 560.0, ly - 4.0), Vector2(lx + 560.0, ly + 4.0), Color(0.7, 0.8, 0.88), 2.0)
		draw_line(Vector2(lx + 560.0 + 500.0 * sc2, ly - 4.0), Vector2(lx + 560.0 + 500.0 * sc2, ly + 4.0), Color(0.7, 0.8, 0.88), 2.0)

func _draw_train(xf: Transform2D, t: Train, col: Color, font: Font, label: String, mini: bool) -> void:
	var d := t.distance
	var a := t.pos_at(d - 8.0)
	var b := t.pos_at(d + 8.0)
	var dir := (Vector2(b.x, b.z) - Vector2(a.x, a.z)).normalized()
	var p := xf * Vector2(a.x, a.z).lerp(Vector2(b.x, b.z), 0.5)
	var fwd := (xf.basis_xform(dir)).normalized()
	var side := Vector2(- fwd.y, fwd.x)
	var sz := 7.0 if mini else 13.0
	var tri := PackedVector2Array([
		p + fwd * sz, p - fwd * (sz * 0.62) + side * (sz * 0.62), p - fwd * (sz * 0.62) - side * (sz * 0.62)
	])
	draw_colored_polygon(tri, col)
	draw_polyline(PackedVector2Array([tri [0], tri [1], tri [2], tri [0]]), col.darkened(0.5), 1.5)
	if font != null and not mini:
		var txt := "%s %.0f km/h" %[label, t.speed_kmh()]
		draw_string(font, p + Vector2(16, -12), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col)
