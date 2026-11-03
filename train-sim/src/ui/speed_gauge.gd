extends Control
class_name SpeedGauge

const MAX_SPEED := 200.0
const START_ANGLE := 2.3561945 # 135 degrees
const SWEEP := 4.712389  # 270 degrees

var _target_speed := 0.0
var _shown_speed := 0.0
var _gear := "P3"
var _gear_color := Color(1.0, 0.62, 0.4)
var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = get_theme_default_font()
	if _font == null:
		_font = ThemeDB.fallback_font
	resized.connect(queue_redraw)
	set_process(true)


func set_values(kmh: float, gear: String, gear_color: Color) -> void:
	_target_speed = clampf(kmh, 0.0, MAX_SPEED)
	_gear = gear
	_gear_color = gear_color
	queue_redraw()


func _process(delta: float) -> void:
	if absf(_target_speed - _shown_speed) < 0.005:
		if _shown_speed != _target_speed:
			_shown_speed = _target_speed
			queue_redraw()
		return
	_shown_speed = lerpf(_shown_speed, _target_speed, clampf(delta * 11.0, 0.0, 1.0))
	queue_redraw()


func _angle_for(kmh: float) -> float:
	return START_ANGLE + SWEEP * clampf(kmh / MAX_SPEED, 0.0, 1.0)


func _text_center(text: String, center: Vector2, font_size: int, color: Color) -> void:
	if _font == null:
		return
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var pos := center + Vector2(- width * 0.5, _font.get_ascent(font_size) * 0.5)
	draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw() -> void:
	var extent := minf(size.x, size.y)
	if extent < 80.0:
		return
	var center := size * 0.5 + Vector2(0.0, 2.0)
	var radius := extent * 0.455
	var face := Color(0.025, 0.038, 0.055, 0.86)
	var rim := Color(0.65, 0.51, 0.3, 0.86)
	var rim_dark := Color(0.1, 0.13, 0.17, 0.86)
	var text_main := Color(0.9, 0.94, 0.99, 0.96)
	var text_muted := Color(0.52, 0.63, 0.74, 0.9)
	var tick := Color(0.62, 0.7, 0.8, 0.82)
	var tick_major := Color(0.94, 0.97, 1.0, 0.95)
	var redline := Color(1.0, 0.34, 0.22, 0.95)

	# Soft halo and a layered bezel. The inner circles give the dial a
	# subtle radial falloff without needing a texture.
	draw_circle(center, radius + 9.0, Color(1.0, 0.62, 0.28, 0.045))
	draw_circle(center, radius + 5.0, Color(0.0, 0.0, 0.0, 0.45))
	draw_circle(center, radius + 2.0, rim_dark)
	draw_circle(center, radius, rim)
	draw_circle(center, radius - 3.0, Color(0.025, 0.028, 0.034, 0.72))
	draw_circle(center, radius - 7.0, face)
	draw_circle(center, radius * 0.86, Color(0.034, 0.05, 0.068, 0.70))
	draw_circle(center, radius * 0.62, Color(0.043, 0.061, 0.083, 0.74))

	# Thin progress ring from zero to the current speed.
	var speed_angle := _angle_for(_shown_speed)
	draw_arc(center, radius - 6.0, START_ANGLE, speed_angle, 64,
			Color(1.0, 0.55, 0.24, 0.62), 3.0, true)

	# Red zone arc and ticks.
	var red_start := _angle_for(180.0)
	draw_arc(center, radius - 23.0, red_start, _angle_for(MAX_SPEED), 32,
			Color(0.82, 0.17, 0.12, 0.62), 5.0, true)

	for value in range(0, 205, 5):
		var angle := _angle_for(float(value))
		var direction := Vector2(cos(angle), sin(angle))
		var is_major := value % 20 == 0
		var is_medium := value % 10 == 0
		var length := 14.0 if is_major else (9.0 if is_medium else 5.0)
		var color := redline if value >= 180 else (tick_major if is_major else tick)
		var outer := center + direction * (radius - 14.0)
		var inner := center + direction * (radius - 14.0 - length)
		draw_line(inner, outer, color, 2.2 if is_major else 1.2, true)
		if is_major:
			_text_center(str(value), center + direction * (radius - 43.0),
					maxi(10, roundi(radius * 0.105)), color)

	# Gear badge and digital speed.
	_text_center(_gear, center + Vector2(0.0, - radius * 0.52),
			maxi(18, roundi(radius * 0.23)), _gear_color)
	_text_center("%d" % roundi(_shown_speed), center + Vector2(0.0, radius * 0.25),
			maxi(26, roundi(radius * 0.33)), text_main)
	_text_center("km/h", center + Vector2(0.0, radius * 0.47),
			maxi(9, roundi(radius * 0.095)), text_muted)

	# Needle + hub, drawn over the digital readout like a real dashboard.
	var direction := Vector2(cos(speed_angle), sin(speed_angle))
	var tip := center + direction * (radius - 34.0)
	var tail := center - direction * 16.0
	draw_line(tail + Vector2(2.0, 3.0), tip + Vector2(2.0, 3.0),
			Color(0.0, 0.0, 0.0, 0.48), 5.5, true)
	draw_line(tail, tip, Color(0.92, 0.28, 0.12, 0.96), 3.4, true)
	draw_line(center, tip, Color(1.0, 0.62, 0.3, 0.95), 1.2, true)
	draw_circle(center, 10.0, Color(0.02, 0.025, 0.03, 1.0))
	draw_circle(center, 7.5, Color(0.56, 0.6, 0.66, 1.0))
	draw_circle(center, 3.6, Color(1.0, 0.74, 0.38, 1.0))
