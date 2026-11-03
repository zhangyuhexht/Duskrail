extends Control
class_name SplashFX


var _t := 0.0
var _pulse := 0.0
var _dust: Array[Vector4] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fit()
	get_viewport().size_changed.connect(_fit)
	var rng := RandomNumberGenerator.new()
	rng.seed = 96041
	for i in range(64):
		_dust.append(Vector4(rng.randf(), rng.randf(), rng.randf_range(0.5, 1.0), rng.randf() * TAU))
	set_process(true)


func _fit() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size


func burst() -> void:
	_pulse = 1.0


func _process(delta: float) -> void:
	_t += delta
	_pulse = maxf(0.0, _pulse - delta * 0.65)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 8.0 or h < 8.0:
		return
	var cx := w * 0.5
	var cy := h * 0.46
	var glow := 0.55 + 0.45 * sin(_t * 1.15) + _pulse * 1.4

	# Blue and amber stage beams from the upper corners.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 0), Vector2(w * 0.34, 0), Vector2(w * 0.58, h), Vector2(w * 0.34, h)
	]), Color(0.16, 0.42, 0.96, 0.028 * glow))
	draw_colored_polygon(PackedVector2Array([
		Vector2(w, 0), Vector2(w * 0.72, 0), Vector2(w * 0.50, h), Vector2(w * 0.72, h)
	]), Color(1.0, 0.48, 0.16, 0.022 * glow))

	# Soft halo behind the wordmark.
	for i in range(12):
		var rr := h * (0.10 + float(i) * 0.045)
		var a := (0.018 - float(i) * 0.0012) * glow
		draw_circle(Vector2(cx, cy), rr, Color(1.0, 0.50, 0.20, maxf(a, 0.0)))
	for i in range(7):
		var rr2 := h * (0.12 + float(i) * 0.038)
		draw_circle(Vector2(cx, cy), rr2, Color(0.20, 0.46, 1.0, maxf(0.012 - float(i) * 0.0014, 0.0) * glow))

	# Expanding station-clock rings.
	for i in range(3):
		var phase := fmod(_t * 0.24 + float(i) / 3.0, 1.0)
		var rr := h * (0.11 + phase * 0.56)
		var alpha := (1.0 - phase) * 0.10 * (0.7 + _pulse)
		draw_arc(Vector2(cx, cy), rr, -PI * 0.86, PI * 0.86, 88,
				Color(1.0, 0.62, 0.26, alpha), 1.3, true)
		draw_arc(Vector2(cx, cy), rr * 1.02, PI * 0.14, PI * 1.86, 88,
				Color(0.32, 0.58, 1.0, alpha * 0.7), 1.0, true)

	# A thin anamorphic lens streak across the logo.
	var width := h * (0.55 + 0.35 * _pulse) * (0.92 + 0.08 * sin(_t * 2.1))
	for i in range(9):
		var yy := cy + float(i) * 1.4 - 5.6
		draw_rect(Rect2(cx - width, yy, width * 2.0, 1.0),
				Color(1.0, 0.72, 0.38, (0.020 + _pulse * 0.055) * (1.0 - float(i) * 0.08)))
	draw_rect(Rect2(cx - h * 0.30, cy - 1.0, h * 0.60, 2.0),
			Color(1.0, 0.84, 0.62, 0.030 + _pulse * 0.08))

	# Speed streaks in the lower third.
	for i in range(26):
		var seed := float(i) * 17.13
		var lane := fmod(seed * 0.37, 1.0)
		var yy := h * (0.64 + lane * 0.30)
		var speed := 0.20 + fmod(seed * 0.11, 0.65)
		var xx := fmod(_t * speed * w + seed * 73.0, w * 1.3) - w * 0.15
		var ln := w * (0.03 + fmod(seed * 0.07, 0.16))
		var aa := (0.036 + fmod(seed * 0.03, 0.07)) * (0.6 + 0.4 * sin(_t * 0.8 + seed))
		draw_line(Vector2(xx, yy), Vector2(xx + ln, yy - 1.5),
				Color(0.85, 0.72, 0.58, aa * 0.55), 1.0)

	# Warm dust motes rising through the light.
	for p in _dust:
		var yy := h * (1.0 - fmod(float(p.y) + _t * (0.018 + float(p.z) * 0.022), 1.0))
		var xx := float(p.x) * w + sin(_t * 0.35 + float(p.w)) * w * 0.010
		var a := (0.06 + float(p.z) * 0.10) * (0.6 + 0.4 * sin(_t * 1.2 + float(p.w)))
		draw_circle(Vector2(xx, yy), 0.8 + float(p.z) * 1.1, Color(1.0, 0.72, 0.42, a))

	# Cinema letterbox and edge falloff.
	draw_rect(Rect2(0, 0, w, h * 0.035), Color(0.0, 0.0, 0.0, 0.42))
	draw_rect(Rect2(0, h * 0.965, w, h * 0.035), Color(0.0, 0.0, 0.0, 0.46))
	for i in range(18):
		var edge := h * 0.035 + float(i) * h * 0.015
		var aa2 := 0.014 - float(i) * 0.0007
		draw_rect(Rect2(0, edge, w, h * 0.015), Color(0.0, 0.0, 0.0, maxf(aa2, 0.0)))
		draw_rect(Rect2(0, h - edge - h * 0.015, w, h * 0.015), Color(0.0, 0.0, 0.0, maxf(aa2, 0.0)))
