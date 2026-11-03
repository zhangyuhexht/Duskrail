extends Control
class_name MenuBackground


var _t := 0.0
var _stars: Array[Dictionary] = []
var _dust: Array[Vector3] = []
var _mouse := Vector2.ZERO
var _mouse_target := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fit()
	get_viewport().size_changed.connect(_fit)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261018
	for i in range(110):
		_stars.append({
			"x": rng.randf(),
			"y": rng.randf() * 0.46,
			"r": rng.randf_range(0.6, 1.8),
			"a": rng.randf_range(0.22, 0.82),
			"ph": rng.randf() * TAU,
		})
	for i in range(54):
		_dust.append(Vector3(rng.randf(), rng.randf_range(0.50, 0.98), rng.randf_range(0.3, 1.0)))


func _fit() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	var vp := get_viewport_rect().size
	if vp.x > 8.0 and vp.y > 8.0:
		var mp := get_viewport().get_mouse_position()
		_mouse_target = Vector2((mp.x / vp.x - 0.5) * 2.0, (mp.y / vp.y - 0.5) * 2.0)
	_mouse = _mouse.lerp(_mouse_target, clampf(delta * 2.0, 0.0, 1.0))
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 8.0 or h < 8.0:
		return
	_draw_sky(w, h)
	_draw_sun(w, h)
	_draw_clouds(w, h)
	_draw_mountains(w, h)
	_draw_city(w, h)
	_draw_rail_yard(w, h)
	_draw_train(w, h)
	_draw_atmosphere(w, h)


func _sky_color(f: float) -> Color:
	# Deep dusk blue overhead, warm haze at the horizon.
	var top := Color(0.012, 0.022, 0.050)
	var mid := Color(0.030, 0.070, 0.130)
	var low := Color(0.120, 0.170, 0.240)
	var warm := Color(0.620, 0.350, 0.220)
	if f < 0.62:
		return top.lerp(mid, smoothstep(0.0, 0.62, f))
	if f < 0.89:
		return mid.lerp(low, smoothstep(0.62, 0.89, f))
	return low.lerp(warm, smoothstep(0.89, 1.0, f) * 0.62)


func _draw_sky(w: float, h: float) -> void:
	var bands := 96
	var prev := Color(0, 0, 0, 0)
	for i in range(bands):
		var f := float(i) / float(bands - 1)
		var c := _sky_color(f)
		if i > 0:
			c = prev.lerp(c, 0.5)
		prev = c
		draw_rect(Rect2(0.0, h * f, w, h / float(bands) + 1.5), c)

	var horizon := h * 0.585
	# Atmospheric glow above the horizon.
	for i in range(10):
		var rr := h * (0.34 - float(i) * 0.026)
		var a := 0.018 - float(i) * 0.0014
		draw_circle(Vector2(w * 0.55, horizon), rr, Color(1.0, 0.56, 0.28, a))

	for s in _stars:
		var tw := 0.62 + 0.38 * sin(_t * 1.25 + float(s["ph"]))
		var col := Color(0.82, 0.90, 1.0, float(s["a"]) * tw * 0.85)
		draw_circle(Vector2(float(s["x"]) * w, float(s["y"]) * h), float(s["r"]), col)


func _draw_sun(w: float, h: float) -> void:
	var horizon := h * 0.585
	var sun := Vector2(w * 0.55 + _mouse.x * 6.0, horizon - h * 0.052 + _mouse.y * 2.0)
	for i in range(9):
		var rr := h * (0.160 - float(i) * 0.015)
		draw_circle(sun, rr, Color(1.0, 0.48, 0.20, 0.030 - float(i) * 0.0026))
	draw_circle(sun, h * 0.036, Color(1.0, 0.70, 0.36, 0.72))
	draw_circle(sun + Vector2(-h * 0.003, -h * 0.003), h * 0.029, Color(1.0, 0.82, 0.55, 0.92))
	# Haze stripes across the sun.
	for i in range(4):
		var y := sun.y + h * (0.004 + float(i) * 0.012)
		draw_rect(Rect2(sun.x - h * 0.09, y, h * 0.18, h * 0.006), Color(0.72, 0.40, 0.25, 0.10))


func _draw_clouds(w: float, h: float) -> void:
	# Long, soft strata drifting slowly across the dusk sky.
	var specs := [
		[0.18, 0.13, 0.20, 0.010, 0.0],
		[0.48, 0.21, 0.30, 0.008, 0.8],
		[0.74, 0.30, 0.24, 0.010, 1.6],
		[0.24, 0.37, 0.34, 0.007, 2.3],
		[0.62, 0.45, 0.40, 0.009, 3.1],
	]
	for spec in specs:
		var cx := float(spec[0]) * w + sin(_t * 0.012 + float(spec[4])) * w * 0.02
		var cy := float(spec[1]) * h
		var cw := float(spec[2]) * w
		var a := float(spec[3])
		for k in range(5):
			var ox := (float(k) - 2.0) * cw * 0.18
			var oy := sin(float(k) * 1.7 + float(spec[4])) * h * 0.010
			var rx := cw * (0.24 - absf(float(k) - 2.0) * 0.025)
			var ry := h * (0.018 + float(k % 2) * 0.008)
			draw_circle(Vector2(cx + ox, cy + oy), rx, Color(0.62, 0.48, 0.48, a))
			draw_circle(Vector2(cx + ox, cy + oy - h * 0.004), rx * 0.92, Color(0.80, 0.60, 0.53, a * 0.55))


func _draw_mountains(w: float, h: float) -> void:
	var horizon := h * 0.585
	# Far range with hazy snow.
	var far := PackedVector2Array([
		Vector2(0, horizon + 3), Vector2(0, horizon - h * 0.105),
		Vector2(w * 0.07, horizon - h * 0.155), Vector2(w * 0.15, horizon - h * 0.085),
		Vector2(w * 0.24, horizon - h * 0.185), Vector2(w * 0.33, horizon - h * 0.095),
		Vector2(w * 0.43, horizon - h * 0.20), Vector2(w * 0.53, horizon - h * 0.09),
		Vector2(w * 0.62, horizon - h * 0.165), Vector2(w * 0.72, horizon - h * 0.08),
		Vector2(w * 0.83, horizon - h * 0.145), Vector2(w * 0.93, horizon - h * 0.075),
		Vector2(w, horizon - h * 0.11), Vector2(w, horizon + 3),
	])
	draw_colored_polygon(far, Color(0.085, 0.115, 0.155, 0.92))
	# Snow caps on the highest far peaks.
	for peak: Array in [[0.24, -0.185, 0.050], [0.43, -0.20, 0.060], [0.62, -0.165, 0.042], [0.83, -0.145, 0.034]]:
		var px := w * float(peak[0])
		var py := horizon + h * float(peak[1])
		var pr := w * float(peak[2])
		draw_colored_polygon(PackedVector2Array([
			Vector2(px, py), Vector2(px - pr * 0.44, py + pr * 0.42),
			Vector2(px - pr * 0.12, py + pr * 0.24), Vector2(px, py + pr * 0.35),
			Vector2(px + pr * 0.14, py + pr * 0.22), Vector2(px + pr * 0.46, py + pr * 0.45),
		]), Color(0.58, 0.64, 0.70, 0.30))

	var near := PackedVector2Array([
		Vector2(0, horizon + 6), Vector2(0, horizon - h * 0.038),
		Vector2(w * 0.10, horizon - h * 0.080), Vector2(w * 0.20, horizon - h * 0.022),
		Vector2(w * 0.30, horizon - h * 0.070), Vector2(w * 0.43, horizon - h * 0.015),
		Vector2(w * 0.55, horizon - h * 0.065), Vector2(w * 0.68, horizon - h * 0.018),
		Vector2(w * 0.79, horizon - h * 0.060), Vector2(w * 0.90, horizon - h * 0.020),
		Vector2(w, horizon - h * 0.052), Vector2(w, horizon + 6),
	])
	draw_colored_polygon(near, Color(0.035, 0.055, 0.080, 1.0))
	# Haze line at the foot of the ranges.
	for i in range(5):
		draw_rect(Rect2(0, horizon - h * 0.012 + float(i) * h * 0.004, w, h * 0.004),
				Color(0.56, 0.48, 0.42, 0.018 - float(i) * 0.0025))


func _draw_city(w: float, h: float) -> void:
	var base := h * 0.593
	var rng := RandomNumberGenerator.new()
	rng.seed = 711
	var city_x := w * 0.015
	var city_w := w * 0.26
	var x := city_x
	while x < city_x + city_w:
		var bw := rng.randf_range(w * 0.010, w * 0.026)
		var bh := rng.randf_range(h * 0.020, h * 0.070)
		draw_rect(Rect2(x, base - bh, bw, bh), Color(0.020, 0.030, 0.048, 0.98))
		draw_rect(Rect2(x + bw * 0.12, base - bh - h * 0.003, bw * 0.76, h * 0.003),
				Color(0.050, 0.062, 0.082, 0.95))
		var cols := maxi(1, int(bw / 7.0))
		var rows := maxi(1, int(bh / 10.0))
		for r in range(rows):
			for c in range(cols):
				if rng.randf() < 0.38:
					var wx := x + 2.0 + float(c) * (bw - 4.0) / float(cols)
					var wy := base - bh + 4.0 + float(r) * 8.0
					var warm := rng.randf() < 0.72
					draw_rect(Rect2(wx, wy, 2.0, 2.4),
							Color(1.0, 0.70, 0.35, 0.50) if warm else Color(0.50, 0.74, 1.0, 0.34))
		x += bw + rng.randf_range(1.0, 6.0)
	# A few closer industrial silhouettes.
	draw_rect(Rect2(w * 0.235, base - h * 0.048, w * 0.020, h * 0.048), Color(0.018, 0.026, 0.040, 1.0))
	draw_line(Vector2(w * 0.245, base - h * 0.048), Vector2(w * 0.245, base - h * 0.075),
			Color(0.10, 0.12, 0.15, 0.9), 1.2)
	draw_circle(Vector2(w * 0.245, base - h * 0.078), 2.2, Color(1.0, 0.25, 0.16, 0.85))


func _draw_rail_yard(w: float, h: float) -> void:
	var horizon := h * 0.593
	var vp := Vector2(w * 0.62, horizon + h * 0.010)
	# Ground plane.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, horizon + h * 0.006), Vector2(w, horizon + h * 0.006),
		Vector2(w, h), Vector2(0, h),
	]), Color(0.018, 0.026, 0.037, 1.0))
	# Wet reflection of the sky along the horizon.
	for i in range(9):
		var yy := horizon + h * (0.012 + float(i) * 0.009)
		draw_rect(Rect2(0, yy, w, h * 0.007), Color(0.16, 0.16, 0.20, 0.018 - float(i) * 0.0014))

	# Track bed and rails converging toward the horizon.
	for track in range(3):
		var center_b := w * (0.43 + float(track) * 0.17)
		var spread := w * (0.095 - float(track) * 0.012)
		var l0 := Vector2(center_b - spread, h * 1.03)
		var r0 := Vector2(center_b + spread, h * 1.03)
		var bed := PackedVector2Array([
			vp + Vector2(-w * 0.008, 0), vp + Vector2(w * 0.008, 0), r0, l0,
		])
		draw_colored_polygon(bed, Color(0.060, 0.055, 0.050, 0.92))
		draw_line(vp, l0, Color(0.27, 0.29, 0.31, 0.86), 1.4)
		draw_line(vp, r0, Color(0.27, 0.29, 0.31, 0.86), 1.4)
		draw_line(vp + Vector2(0, 1.0), l0 + Vector2(0, 4), Color(0.55, 0.50, 0.38, 0.36), 1.0)
		draw_line(vp + Vector2(0, 1.0), r0 + Vector2(0, 4), Color(0.55, 0.50, 0.38, 0.36), 1.0)
		var step := 0.055
		var t := 0.12
		while t < 1.0:
			var fl := vp.lerp(l0, t)
			var fr := vp.lerp(r0, t)
			draw_line(fl, fr, Color(0.10, 0.10, 0.10, 0.65), 1.0 + t * 2.4)
			t += step

	# Station platform edge on the left.
	var plat_top := h * 0.83
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, plat_top), Vector2(w * 0.27, plat_top + h * 0.015),
		Vector2(w * 0.30, h), Vector2(0, h),
	]), Color(0.11, 0.12, 0.13, 0.96))
	draw_line(Vector2(0, plat_top), Vector2(w * 0.27, plat_top + h * 0.015),
			Color(0.74, 0.58, 0.16, 0.62), 2.0)
	for i in range(6):
		var px := w * (0.03 + float(i) * 0.040)
		var py := plat_top + h * (0.008 + float(i) * 0.010)
		draw_line(Vector2(px, py), Vector2(px - w * 0.012, h), Color(0.05, 0.06, 0.07, 0.75), 1.0)

	# Catenary masts and signal.
	for i in range(5):
		var mx := w * (0.34 + float(i) * 0.12)
		var my := horizon + h * (0.035 + float(i) * 0.044)
		var mh := h * (0.16 - float(i) * 0.018)
		draw_line(Vector2(mx, my), Vector2(mx, my - mh), Color(0.10, 0.12, 0.14, 0.95), 1.6)
		draw_line(Vector2(mx, my - mh), Vector2(mx - w * 0.055, my - mh + h * 0.008),
				Color(0.10, 0.12, 0.14, 0.92), 1.2)
		draw_line(Vector2(mx, my - mh + h * 0.012), Vector2(mx + w * 0.065, my - mh + h * 0.018),
				Color(0.36, 0.27, 0.18, 0.55), 1.0)
	draw_line(Vector2(w * 0.32, horizon + h * 0.010), Vector2(w * 0.74, horizon + h * 0.060),
			Color(0.55, 0.42, 0.28, 0.28), 1.0)
	draw_line(Vector2(w * 0.32, horizon + h * 0.030), Vector2(w * 0.74, horizon + h * 0.080),
			Color(0.55, 0.42, 0.28, 0.20), 1.0)
	var sig := Vector2(w * 0.585, horizon + h * 0.035)
	draw_line(sig, sig + Vector2(0, -h * 0.052), Color(0.12, 0.13, 0.15, 0.95), 1.6)
	draw_circle(sig + Vector2(0, -h * 0.055), 2.2, Color(1.0, 0.18, 0.12, 0.92))
	draw_circle(sig + Vector2(0, -h * 0.055), 7.0, Color(1.0, 0.18, 0.12, 0.07))


func _draw_train(w: float, h: float) -> void:
	var horizon := h * 0.593
	var scale := h * 0.065
	var x := w * 0.30 + _mouse.x * 3.0
	var y := horizon + h * 0.060 + _mouse.y * 1.5
	# Headlight beam toward the left.
	var beam := PackedVector2Array([
		Vector2(x - scale * 3.05, y - scale * 0.30),
		Vector2(x - scale * 9.5, y - scale * 0.55),
		Vector2(x - scale * 9.5, y + scale * 0.62),
		Vector2(x - scale * 3.05, y + scale * 0.10),
	])
	draw_colored_polygon(beam, Color(1.0, 0.86, 0.55, 0.055))
	# A two-car HXD1 silhouette on the near track.
	for car in range(2):
		var cx := x + float(car) * scale * 5.2
		if car == 1:
			cx += scale * 0.18
		var body_y := y - scale * 1.02
		if car == 0:
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx, body_y + scale * 0.08),
				Vector2(cx - scale * 0.62, body_y + scale * 0.62),
				Vector2(cx, body_y + scale * 1.04),
			]), Color(0.045, 0.060, 0.080, 0.98))
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - scale * 0.04, body_y + scale * 0.16),
				Vector2(cx - scale * 0.36, body_y + scale * 0.42),
				Vector2(cx - scale * 0.36, body_y + scale * 0.60),
				Vector2(cx - scale * 0.04, body_y + scale * 0.40),
			]), Color(0.10, 0.16, 0.23, 0.95))
		draw_rect(Rect2(cx, body_y, scale * 4.65, scale * 1.02), Color(0.045, 0.060, 0.080, 0.98))
		draw_rect(Rect2(cx + scale * 0.10, body_y - scale * 0.10, scale * 4.35, scale * 0.16),
				Color(0.16, 0.18, 0.20, 0.98))
		draw_rect(Rect2(cx + scale * 0.12, body_y + scale * 0.42, scale * 4.30, scale * 0.17),
				Color(0.10, 0.24, 0.56, 0.92))
		draw_rect(Rect2(cx + scale * 0.12, body_y + scale * 0.60, scale * 4.30, scale * 0.055),
				Color(0.92, 0.56, 0.20, 0.85))
		for k in range(5):
			var lit := 0.55 + 0.25 * sin(_t * 1.4 + float(k) * 1.7 + float(car))
			draw_rect(Rect2(cx + scale * (0.42 + float(k) * 0.80), body_y + scale * 0.20,
					scale * 0.34, scale * 0.18), Color(1.0, 0.79, 0.42, lit))
		# Cab glazing and underframe.
		draw_rect(Rect2(cx + scale * 0.15, body_y + scale * 0.10, scale * 0.46, scale * 0.24),
				Color(0.07, 0.12, 0.18, 0.95))
		draw_rect(Rect2(cx + scale * 0.12, body_y + scale * 0.96, scale * 4.40, scale * 0.12),
				Color(0.035, 0.045, 0.060, 0.98))
		for wheel in range(2):
			draw_circle(Vector2(cx + scale * (0.72 + float(wheel) * 2.95), body_y + scale * 1.01),
					scale * 0.16, Color(0.025, 0.030, 0.038))
	# Lead headlight.
	draw_circle(Vector2(x - scale * 0.44, y - scale * 0.52), scale * 0.11, Color(1.0, 0.95, 0.78, 0.98))
	draw_circle(Vector2(x - scale * 0.44, y - scale * 0.52), scale * 0.48, Color(1.0, 0.85, 0.52, 0.08))
	# A red tail lamp on the far car.
	var tail := x + scale * 9.9
	draw_circle(Vector2(tail, y - scale * 0.54), 1.6, Color(1.0, 0.18, 0.12, 0.78))


func _draw_atmosphere(w: float, h: float) -> void:
	# Warm dust / fireflies drifting over the yard.
	var horizon := h * 0.593
	for p in _dust:
		var yy := fmod(float(p.y) * h - _t * (3.0 + float(p.z) * 7.0), h * 0.46)
		if yy < 0.0:
			yy += h * 0.46
		var px := float(p.x) * w + sin(_t * 0.25 + float(p.z) * 9.0) * w * 0.006
		var a := 0.055 + float(p.z) * 0.09
		draw_circle(Vector2(px, horizon + yy - h * 0.02), 1.0 + float(p.z) * 1.2,
				Color(1.0, 0.72, 0.38, a))
	# Bottom fog/glow.
	for i in range(8):
		draw_rect(Rect2(0, h * (0.78 + float(i) * 0.022), w, h * 0.022),
				Color(0.18, 0.18, 0.20, 0.014 - float(i) * 0.0015))
	# Very subtle horizontal film grain bands.
	for i in range(5):
		draw_rect(Rect2(0, h * (0.10 + float(i) * 0.16), w, 1.0), Color(1, 1, 1, 0.008))
