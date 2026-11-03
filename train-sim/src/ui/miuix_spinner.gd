extends Control
class_name MiuixSpinner


var spinner_color := Color(0.55, 0.75, 1.0)
var line_width := 2.0
var speed := 4.2
var _angle := 0.0


func _init(p_color := Color(0.55, 0.75, 1.0), p_size := 20.0) -> void:
	spinner_color = p_color
	custom_minimum_size = Vector2(p_size, p_size)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_angle = fmod(_angle + delta * speed, TAU)
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y)
	if s <= 2.0:
		return
	var center := size * 0.5
	var radius := s * 0.5 - line_width
	# MIUIX-style track and sweeping 270-degree head.
	draw_arc(center, radius, 0.0, TAU, 40, Color(spinner_color, 0.16), line_width, true)
	var head := _angle + 4.4
	draw_arc(center, radius, _angle, head, 32, spinner_color, line_width, true)
	var tip := center + Vector2(cos(head), sin(head)) * radius
	var tail := center + Vector2(cos(_angle), sin(_angle)) * radius
	draw_circle(tip, line_width * 0.85, spinner_color)
	draw_circle(tail, line_width * 0.55, Color(spinner_color, 0.55))
