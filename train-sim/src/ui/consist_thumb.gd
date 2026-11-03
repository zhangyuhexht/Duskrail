extends Control
class_name ConsistThumb

const BODY := Color(0.82, 0.85, 0.88)
const ROOF := Color(0.45, 0.48, 0.5)
const GLASS := Color(0.12, 0.2, 0.29)
const BLUE := Color(0.07, 0.19, 0.5)
const RED := Color(0.62, 0.1, 0.085)
const CREAM := Color(0.9, 0.8, 0.56)
const RUST := Color(0.34, 0.24, 0.17)
const DARK := Color(0.07, 0.08, 0.09)
const STEEL := Color(0.55, 0.58, 0.6)
const COAL := Color(0.05, 0.05, 0.055)
const YELLOW := Color(0.92, 0.72, 0.16)

var car_id := "passenger"
var loaded := true
var is_loco := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func setup(id: String, p_loaded: bool, loco := false) -> void:
	car_id = id
	loaded = p_loaded
	is_loco = loco
	queue_redraw()

func _draw() -> void:
	if size.x < 4.0 or size.y < 4.0:
		return
	var lw := 240.0
	var lh := 82.0
	var s := minf(size.x / lw, size.y / lh)
	var offset := Vector2((size.x - lw * s) * 0.5, (size.y - lh * s) * 0.5)
	draw_set_transform(offset, 0.0, Vector2(s, s))
	draw_line(Vector2(12, 75), Vector2(228, 75), Color(0.23, 0.25, 0.27), 2.0)
	for x in [42, 90, 150, 198]:
		draw_line(Vector2(x, 75), Vector2(x - 5, 79), Color(0.16, 0.17, 0.19), 1.0)
	if is_loco:
		_draw_loco()
	else:
		match car_id:
			"passenger":
				_draw_passenger()
			"baggage":
				_draw_baggage()
			"water_tank":
				_draw_water_tank()
			"flat":
				_draw_flat()
			"gondola":
				_draw_gondola()
			"reefer":
				_draw_reefer()
			"hopper":
				_draw_hopper()
			_:
				_draw_container()

func _box(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c, true)

func _outline(x: float, y: float, w: float, h: float, c: Color, width := 1.0) -> void:
	draw_rect(Rect2(x, y, w, h), c, false, width)

func _wheel(x: float) -> void:
	draw_circle(Vector2(x, 69), 8.0, Color(0.04, 0.045, 0.05))
	draw_circle(Vector2(x, 69), 5.2, Color(0.38, 0.4, 0.42))
	draw_circle(Vector2(x, 69), 2.0, Color(0.09, 0.1, 0.11))

func _wheels(a := 62.0, b := 178.0) -> void:
	_wheel(a)
	_wheel(b)

func _shadow(y := 59.0) -> void:
	draw_rect(Rect2(22, y, 196, 3), Color(0.04, 0.045, 0.05, 0.8), true)

func _draw_loco() -> void:
	_shadow(59)
	_box(28, 20, 184, 38, BODY)
	_box(28, 38, 184, 7, BLUE)
	_box(28, 20, 46, 38, Color(0.73, 0.76, 0.8))
	_box(33, 25, 34, 13, GLASS)
	_box(33, 48, 34, 6, YELLOW)
	_box(79, 25, 126, 16, Color(0.13, 0.15, 0.18))
	for i in range(8):
		var x := 85.0 + float(i) * 15.0
		draw_line(Vector2(x, 27), Vector2(x, 39), Color(0.32, 0.35, 0.38), 1.2)
	_box(28, 16, 184, 5, ROOF)
	draw_line(Vector2(139, 16), Vector2(154, 6), Color(0.34, 0.37, 0.4), 2.0)
	draw_line(Vector2(154, 6), Vector2(172, 16), Color(0.34, 0.37, 0.4), 2.0)
	draw_line(Vector2(145, 16), Vector2(160, 7), Color(0.58, 0.62, 0.66), 1.5)
	_wheels(58, 182)

func _draw_passenger() -> void:
	_shadow()
	_box(24, 19, 192, 40, BODY)
	_box(24, 19, 192, 4, ROOF)
	_box(24, 39, 192, 7, BLUE)
	for i in range(8):
		var x := 36.0 + float(i) * 21.0
		_box(x, 26, 14, 9, GLASS)
		_outline(x, 26, 14, 9, Color(0.32, 0.34, 0.36), 1.0)
	for x: float in [27.0, 201.0]:
		draw_line(Vector2(x + 5, 22), Vector2(x + 5, 56), Color(0.4, 0.43, 0.46), 1.2)
	_wheels(58, 182)

func _draw_baggage() -> void:
	_shadow()
	_box(24, 19, 192, 40, RED)
	_box(24, 39, 192, 7, CREAM)
	_box(24, 19, 192, 4, ROOF)
	for x: float in [40.0, 160.0]:
		_box(x, 24, 40, 31, Color(0.42, 0.07, 0.06))
		_outline(x, 24, 40, 31, Color(0.22, 0.04, 0.04), 1.2)
		for k in range(3):
			draw_line(Vector2(x + 8 + float(k) * 11, 27), Vector2(x + 8 + float(k) * 11, 52), Color(0.56, 0.12, 0.1), 1.0)
	for x: float in [92.0, 112.0, 132.0]:
		_box(x, 28, 10, 7, GLASS)
	_wheels(58, 182)

func _draw_container() -> void:
	_shadow(57)
	_box(24, 48, 192, 10, Color(0.22, 0.24, 0.26))
	_box(39, 24, 72, 25, Color(0.1, 0.27, 0.55))
	_box(126, 24, 72, 25, Color(0.58, 0.13, 0.1))
	for box_x: float in [39.0, 126.0]:
		_outline(box_x, 24, 72, 25, Color(0.05, 0.06, 0.07), 1.2)
		for i in range(7):
			draw_line(Vector2(box_x + 6 + float(i) * 10, 26), Vector2(box_x + 6 + float(i) * 10, 47), Color(0.08, 0.1, 0.12, 0.45), 1.0)
	_wheels(58, 182)

func _draw_hopper() -> void:
	_shadow()
	draw_colored_polygon(PackedVector2Array([
		Vector2(28, 24), Vector2(212, 24), Vector2(206, 55), Vector2(34, 55),
	]), RUST)
	for i in range(9):
		var x := 40.0 + float(i) * 20.0
		draw_line(Vector2(x, 27), Vector2(x, 53), Color(0.22, 0.15, 0.1), 1.3)
	draw_colored_polygon(PackedVector2Array([
		Vector2(42, 24), Vector2(198, 24), Vector2(184, 16), Vector2(56, 16),
	]), COAL)
	_box(30, 52, 180, 4, Color(0.15, 0.11, 0.08))
	_wheels(58, 182)

func _draw_gondola() -> void:
	_shadow()
	_box(30, 24, 180, 31, RUST)
	_box(34, 18, 172, 8, COAL)
	_box(30, 24, 180, 4, Color(0.23, 0.16, 0.11))
	for i in range(8):
		var x := 42.0 + float(i) * 21.0
		draw_line(Vector2(x, 26), Vector2(x, 54), Color(0.22, 0.15, 0.1), 1.4)
	_wheels(58, 182)

func _draw_water_tank() -> void:
	_shadow(58)
	_box(24, 52, 192, 7, Color(0.18, 0.2, 0.23))
	draw_circle(Vector2(52, 38), 15.0, STEEL)
	draw_circle(Vector2(188, 38), 15.0, STEEL)
	_box(52, 23, 136, 30, STEEL)
	_box(52, 23, 136, 4, Color(0.72, 0.75, 0.77))
	for x: float in [88.0, 120.0, 152.0]:
		_box(x, 24, 5, 28, BLUE)
	_box(114, 16, 16, 8, STEEL)
	draw_line(Vector2(198, 22), Vector2(198, 55), Color(0.28, 0.3, 0.32), 2.0)
	for y: float in [27.0, 34.0, 41.0, 48.0]:
		draw_line(Vector2(195, y), Vector2(203, y), Color(0.28, 0.3, 0.32), 1.2)
	_wheels(58, 182)

func _draw_flat() -> void:
	_shadow(57)
	_box(24, 50, 192, 8, RUST)
	_box(24, 59, 192, 3, Color(0.16, 0.11, 0.08))
	for i in range(7):
		var x := 36.0 + float(i) * 27.0
		draw_line(Vector2(x, 32), Vector2(x, 51), Color(0.18, 0.13, 0.09), 2.0)
	if loaded:
		for x: float in [72.0, 120.0, 168.0]:
			draw_circle(Vector2(x, 42), 12.0, STEEL)
			draw_circle(Vector2(x, 42), 5.0, Color(0.32, 0.34, 0.36))
			draw_circle(Vector2(x, 42), 1.8, Color(0.12, 0.13, 0.14))
		_box(30, 44, 20, 7, Color(0.36, 0.25, 0.14))
		_box(190, 44, 20, 7, Color(0.36, 0.25, 0.14))
	_wheels(58, 182)

func _draw_reefer() -> void:
	_shadow()
	_box(24, 19, 192, 40, Color(0.8, 0.83, 0.82))
	_box(24, 19, 192, 4, ROOF)
	for i in range(10):
		var x := 34.0 + float(i) * 17.5
		draw_line(Vector2(x, 23), Vector2(x, 56), Color(0.61, 0.65, 0.66), 1.2)
	_box(44, 24, 42, 29, Color(0.7, 0.74, 0.75))
	_box(154, 24, 42, 29, Color(0.7, 0.74, 0.75))
	for x: float in [45.0, 155.0]:
		_outline(x, 24, 40, 29, Color(0.42, 0.46, 0.48), 1.2)
		for k in range(3):
			draw_line(Vector2(x + 8 + float(k) * 11, 27), Vector2(x + 8 + float(k) * 11, 52), Color(0.52, 0.56, 0.57), 1.0)
	_box(26, 22, 16, 20, Color(0.36, 0.39, 0.41))
	for y: float in [26.0, 30.0, 34.0, 38.0]:
		draw_line(Vector2(27, y), Vector2(41, y), Color(0.16, 0.18, 0.2), 1.2)
	_wheels(58, 182)
