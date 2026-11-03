extends RefCounted
class_name Route



const SAMPLE_STEP := 1.0

var points := PackedVector3Array()
var tangents := PackedVector3Array()
var up_vectors := PackedVector3Array()
var total := 0.0
var closed := true

var _fine := PackedVector3Array()
var _fine_dist := PackedFloat32Array()
var _grid := {}
const GRID_CELL := 80.0


func build_cyclic(control: Array, tension := 0.5, fine_step := 0.4) -> void:
	closed = true
	var n := control.size()
	if n < 3:
		push_error("Route 需要至少 3 个控制点")
		return
	_fine = PackedVector3Array()
	_fine_dist = PackedFloat32Array()
	var seg_count := n
	var rough_len := 0.0
	for i in range(n):
		rough_len +=(control [(i + 1) %n] - control [i]).length()
	var steps_per_seg := maxi(4, int(ceil(rough_len / float(n) / fine_step)))
	var acc := 0.0
	var last := Vector3.ZERO
	for i in range(seg_count):
		var p0: Vector3 = control [(i - 1 + n) %n]
		var p1: Vector3 = control [i]
		var p2: Vector3 = control [(i + 1) %n]
		var p3: Vector3 = control [(i + 2) %n]
		for j in range(steps_per_seg):
			var t := float(j) / float(steps_per_seg)
			var p := _catmull_rom(p0, p1, p2, p3, t) * tension + _lerp3(p1, p2, t) *(1.0 - tension)
			if _fine.size() > 0:
				acc +=(p - last).length()
			_fine.append(p)
			_fine_dist.append(acc)
			last = p

	if _fine.size() > 0:
		acc +=(control [0] - last).length()
		_fine.append(control [0])
		_fine_dist.append(acc)
	total = acc
	_resample()

func build_open(control: Array, tension := 0.5, fine_step := 0.4) -> void:
	closed = false
	var n := control.size()
	_fine = PackedVector3Array()
	_fine_dist = PackedFloat32Array()
	var steps_per_seg := 24
	var acc := 0.0
	var last := Vector3.ZERO
	for i in range(n - 1):
		var p0: Vector3 = control [maxi(i - 1, 0)]
		var p1: Vector3 = control [i]
		var p2: Vector3 = control [i + 1]
		var p3: Vector3 = control [mini(i + 2, n - 1)]
		for j in range(steps_per_seg):
			var t := float(j) / float(steps_per_seg)
			var p := _catmull_rom(p0, p1, p2, p3, t) * tension + _lerp3(p1, p2, t) *(1.0 - tension)
			if _fine.size() > 0:
				acc +=(p - last).length()
			_fine.append(p)
			_fine_dist.append(acc)
			last = p
	_fine.append(control [n - 1])
	_fine_dist.append(acc +(control [n - 1] - last).length())
	total = _fine_dist [_fine_dist.size() - 1]
	_resample()


func _resample() -> void:
	points = PackedVector3Array()
	tangents = PackedVector3Array()
	up_vectors = PackedVector3Array()
	if _fine.size() < 2 or total <= 0.0:
		return
	var count := int(floor(total / SAMPLE_STEP)) + 1
	points.resize(count)
	tangents.resize(count)
	up_vectors.resize(count)
	var fi := 0
	for i in range(count):
		var d := float(i) * SAMPLE_STEP
		while fi < _fine_dist.size() - 2 and _fine_dist [fi + 1] < d:
			fi += 1
		var d0 := _fine_dist [fi]
		var d1 := _fine_dist [fi + 1]
		var t := 0.0
		if d1 > d0:
			t = clampf((d - d0) /(d1 - d0), 0.0, 1.0)
		points [i] = _fine [fi].lerp(_fine [fi + 1], t)

	_grid.clear()
	for i in range(count):
		var a := points [(i - 1 + count) %count] if closed else points [maxi(i - 1, 0)]
		var b := points [(i + 1) %count] if closed else points [mini(i + 1, count - 1)]
		var dir :=(b - a)
		if dir.length_squared() < 1e-8:
			dir = Vector3.FORWARD
		dir = dir.normalized()
		tangents [i] = dir
		var up := Vector3.UP - dir * dir.dot(Vector3.UP)
		if up.length_squared() < 0.000001:
			up = Vector3.UP
		up_vectors [i] = up.normalized()
		var key := Vector2i(int(floor(points[i].x / GRID_CELL)), int(floor(points[i].z / GRID_CELL)))
		if not _grid.has(key):
			_grid[key] = []
		_grid[key].append(i)



func wrap_dist(dist: float) -> float:
	if closed:
		return fposmod(dist, total)
	return clampf(dist, 0.0, total)

func position_at(dist: float) -> Vector3:
	if points.is_empty():
		return Vector3.ZERO
	var raw := wrap_dist(dist) / SAMPLE_STEP
	var i := int(floor(raw))
	var t := raw - float(i)
	var i0 := i %points.size()
	var i1 :=(i + 1) %points.size()
	if not closed and i1 >= points.size():
		i1 = points.size() - 1
		i0 = maxi(i1 - 1, 0)
	return points [i0].lerp(points [i1], t)

func tangent_at(dist: float) -> Vector3:
	if points.is_empty():
		return Vector3.FORWARD
	var raw := wrap_dist(dist) / SAMPLE_STEP
	var i := int(floor(raw))
	var t := raw - float(i)
	var i0 := i %points.size()
	var i1 :=(i + 1) %points.size()
	if not closed and i1 >= points.size():
		i1 = points.size() - 1
		i0 = maxi(i1 - 1, 0)
	return tangents [i0].lerp(tangents [i1], t).normalized()

func frame_at(dist: float) -> Transform3D:
	var pos := position_at(dist)
	var dir := tangent_at(dist)
	var up := Vector3.UP - dir * dir.dot(Vector3.UP)
	if up.length_squared() < 0.000001:
		up = Vector3.UP
	up = up.normalized()
	var right := dir.cross(up).normalized()

	var basis := Basis(right, up, - dir)
	return Transform3D(basis, pos)


func gradient_at(dist: float) -> float:
	var a := position_at(dist - 12.0)
	var b := position_at(dist + 12.0)
	var d := b - a
	var horiz := Vector2(d.x, d.z).length()
	if horiz < 0.001:
		return 0.0
	return atan2(d.y, horiz)


func curvature_at(dist: float) -> float:
	var a := position_at(dist - 14.0)
	var b := position_at(dist)
	var c := position_at(dist + 14.0)
	var v1 := Vector2(b.x - a.x, b.z - a.z)
	var v2 := Vector2(c.x - b.x, c.z - b.z)
	if v1.length() < 0.01 or v2.length() < 0.01:
		return 0.0
	var ang := absf(v1.angle_to(v2))
	var ds :=(v1.length() + v2.length()) * 0.5
	if ds < 0.01:
		return 0.0
	return ang / ds


func nearest_dist(pos: Vector3) -> float:
	var best := 0.0
	var best_d := INF
	var cell := Vector2i(int(floor(pos.x / GRID_CELL)), int(floor(pos.z / GRID_CELL)))
	var found := false
	for dx in range(-2, 3):
		for dz in range(-2, 3):
			var arr: Array = _grid.get(Vector2i(cell.x + dx, cell.y + dz), [])
			for idx: int in arr:
				var d := points[idx].distance_squared_to(pos)
				if d < best_d:
					best_d = d
					best = float(idx) * SAMPLE_STEP
					found = true
	if not found:
		var i := 0
		while i < points.size():
			var d := points[i].distance_squared_to(pos)
			if d < best_d:
				best_d = d
				best = float(i) * SAMPLE_STEP
			i += 8

	var lo := best - 8.0
	var hi := best + 8.0
	var s := lo
	while s <= hi:
		var d := position_at(s).distance_squared_to(pos)
		if d < best_d:
			best_d = d
			best = wrap_dist(s)
		s += 1.0
	return best


func height_at(dist: float) -> float:
	return position_at(dist).y



func _catmull_rom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 *(
		(2.0 * p1) +
		(- p0 + p2) * t +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
		(- p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)

func _lerp3(a: Vector3, b: Vector3, t: float) -> Vector3:
	return a.lerp(b, t)