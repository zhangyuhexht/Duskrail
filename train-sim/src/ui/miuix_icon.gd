extends Control
class_name MiuixIcon


var kind := "play"
var icon_color := Color.WHITE
var stroke := 1.8

func _init(p_kind := "play", p_color := Color.WHITE, p_size := 22.0) -> void:
	kind = p_kind
	icon_color = p_color
	custom_minimum_size = Vector2(p_size, p_size)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var s := minf(size.x, size.y)
	if s <= 1.0:
		return
	var o := (size - Vector2(s, s)) * 0.5
	var u := s / 24.0
	var w := maxf(1.35, stroke * u)
	var c := icon_color
	match kind:
		"play":
			draw_colored_polygon(PackedVector2Array([
				o + Vector2(9.0, 6.5) * u,
				o + Vector2(18.5, 12.0) * u,
				o + Vector2(9.0, 17.5) * u,
			]), c)
		"single":
			draw_arc(o + Vector2(12.0, 8.0) * u, 3.2 * u, 0.0, TAU, 24, c, w, true)
			draw_arc(o + Vector2(12.0, 18.7) * u, 6.0 * u, PI * 1.14, PI * 1.86, 28, c, w, true)
		"multi":
			draw_arc(o + Vector2(9.0, 8.4) * u, 2.8 * u, 0.0, TAU, 24, c, w, true)
			draw_arc(o + Vector2(9.0, 18.2) * u, 5.0 * u, PI * 1.18, PI * 1.82, 24, c, w, true)
			draw_arc(o + Vector2(16.4, 9.6) * u, 2.3 * u, 0.0, TAU, 24, c, w, true)
			draw_arc(o + Vector2(17.0, 18.0) * u, 4.3 * u, PI * 1.30, PI * 1.94, 20, c, w, true)
		"settings":
			draw_arc(o + Vector2(12.0, 12.0) * u, 5.0 * u, 0.0, TAU, 32, c, w, true)
			draw_circle(o + Vector2(12.0, 12.0) * u, 1.5 * u, c)
			for i in range(8):
				var a := TAU * float(i) / 8.0
				var d := Vector2(cos(a), sin(a))
				draw_line(o + (Vector2(12.0, 12.0) + d * 6.7) * u,
						o + (Vector2(12.0, 12.0) + d * 8.7) * u, c, w, true)
		"exit":
			draw_arc(o + Vector2(12.0, 12.4) * u, 6.5 * u, - PI * 0.36, PI * 1.36, 36, c, w, true)
			draw_line(o + Vector2(12.0, 4.4) * u, o + Vector2(12.0, 11.5) * u, c, w, true)
		"arrow":
			draw_polyline(PackedVector2Array([
				o + Vector2(9.5, 6.0) * u,
				o + Vector2(16.0, 12.0) * u,
				o + Vector2(9.5, 18.0) * u,
			]), c, w, true)
		"back":
			draw_polyline(PackedVector2Array([
				o + Vector2(14.5, 6.0) * u,
				o + Vector2(8.0, 12.0) * u,
				o + Vector2(14.5, 18.0) * u,
			]), c, w, true)
		"plus":
			draw_line(o + Vector2(12.0, 5.0) * u, o + Vector2(12.0, 19.0) * u, c, w, true)
			draw_line(o + Vector2(5.0, 12.0) * u, o + Vector2(19.0, 12.0) * u, c, w, true)
		"folder":
			draw_polyline(PackedVector2Array([
				o + Vector2(3.5, 7.0) * u,
				o + Vector2(3.5, 19.0) * u,
				o + Vector2(20.5, 19.0) * u,
				o + Vector2(20.5, 8.5) * u,
				o + Vector2(12.0, 8.5) * u,
				o + Vector2(10.0, 6.0) * u,
				o + Vector2(3.5, 6.0) * u,
				o + Vector2(3.5, 7.0) * u,
			]), c, w, true)
		"warn":
			draw_polyline(PackedVector2Array([
				o + Vector2(12.0, 3.5) * u,
				o + Vector2(21.0, 20.0) * u,
				o + Vector2(3.0, 20.0) * u,
				o + Vector2(12.0, 3.5) * u,
			]), c, w, true)
			draw_line(o + Vector2(12.0, 9.0) * u, o + Vector2(12.0, 14.0) * u, c, w, true)
			draw_circle(o + Vector2(12.0, 17.0) * u, maxf(0.9, w * 0.52), c)
		"rail":
			draw_line(o + Vector2(7.0, 3.0) * u, o + Vector2(9.0, 21.0) * u, c, w, true)
			draw_line(o + Vector2(17.0, 3.0) * u, o + Vector2(15.0, 21.0) * u, c, w, true)
			for i in range(5):
				var y := 5.0 + float(i) * 3.5
				draw_line(o + Vector2(8.0, y) * u, o + Vector2(16.0, y) * u, c, w * 0.8, true)
		"light":
			draw_circle(o + Vector2(12.0, 11.0) * u, 3.2 * u, c)
			for i in range(8):
				var a := TAU * float(i) / 8.0
				var d := Vector2(cos(a), sin(a))
				draw_line(o + (Vector2(12.0, 11.0) + d * 5.6) * u,
						o + (Vector2(12.0, 11.0) + d * 8.4) * u, c, w, true)
			draw_line(o + Vector2(8.5, 19.5) * u, o + Vector2(15.5, 19.5) * u, c, w, true)
		"mirror":
			var mirror_rect := Rect2(o + Vector2(7.0, 4.5) * u, Vector2(10.0, 13.0) * u)
			draw_rect(mirror_rect, c, false, w, true)
			draw_line(o + Vector2(9.0, 6.5) * u, o + Vector2(14.0, 14.0) * u, c, w * 0.8, true)
			draw_line(o + Vector2(17.0, 17.5) * u, o + Vector2(20.0, 20.0) * u, c, w, true)
		"plow":
			draw_polyline(PackedVector2Array([
				o + Vector2(4.0, 8.0) * u,
				o + Vector2(12.0, 15.0) * u,
				o + Vector2(20.0, 8.0) * u,
			]), c, w, true)
			draw_line(o + Vector2(12.0, 15.0) * u, o + Vector2(12.0, 20.0) * u, c, w, true)
		"horn":
			draw_arc(o + Vector2(11.0, 11.0) * u, 5.0 * u, PI * 0.15, PI * 1.35, 20, c, w, true)
			draw_line(o + Vector2(15.0, 8.0) * u, o + Vector2(20.0, 5.0) * u, c, w, true)
			draw_line(o + Vector2(15.0, 14.0) * u, o + Vector2(20.0, 17.0) * u, c, w, true)
		_:
			draw_arc(o + Vector2(12.0, 12.0) * u, 8.0 * u, 0.0, TAU, 32, c, w, true)
