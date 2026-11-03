extends RefCounted
class_name Forge




static var invert_winding := false



static func _tri(st: SurfaceTool, a: Vector3, na: Vector3, ua: Vector2,
		b: Vector3, nb: Vector3, ub: Vector2,
		c: Vector3, nc: Vector3, uc: Vector2) -> void:
	if invert_winding:
		st.set_normal(nc); st.set_uv(uc); st.add_vertex(c)
		st.set_normal(nb); st.set_uv(ub); st.add_vertex(b)
		st.set_normal(na); st.set_uv(ua); st.add_vertex(a)
	else:
		st.set_normal(na); st.set_uv(ua); st.add_vertex(a)
		st.set_normal(nb); st.set_uv(ub); st.add_vertex(b)
		st.set_normal(nc); st.set_uv(uc); st.add_vertex(c)

static func _quad(st: SurfaceTool,
		a: Vector3, na: Vector3, ua: Vector2,
		b: Vector3, nb: Vector3, ub: Vector2,
		c: Vector3, nc: Vector3, uc: Vector2,
		d: Vector3, nd: Vector3, ud: Vector2) -> void:
	_tri(st, a, na, ua, b, nb, ub, c, nc, uc)
	_tri(st, a, na, ua, c, nc, uc, d, nd, ud)

static func _radial(n: Vector2, angle: float) -> Vector3:
	return Vector3(cos(angle) * n.x, n.y, sin(angle) * n.x)




static func lathe(profile: PackedVector2Array, segments: int = 32, smooth: bool = true) -> ArrayMesh:
	if profile.size() < 2:
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var arcs := maxi(6, segments)
	for i in range(profile.size() - 1):
		var p0: Vector2 = profile [i]
		var p1: Vector2 = profile [i + 1]
		var nrm := Vector2.ZERO
		if smooth:
			var d :=(p1 - p0).normalized()
			nrm = Vector2(d.y, - d.x)
		for j in range(arcs):
			var a0 := TAU * float(j) / float(arcs)
			var a1 := TAU * float(j + 1) / float(arcs)
			var v00 := Vector3(cos(a0) * p0.x, p0.y, sin(a0) * p0.x)
			var v01 := Vector3(cos(a0) * p1.x, p1.y, sin(a0) * p1.x)
			var v10 := Vector3(cos(a1) * p0.x, p0.y, sin(a1) * p0.x)
			var v11 := Vector3(cos(a1) * p1.x, p1.y, sin(a1) * p1.x)
			var n00 := _radial(nrm, a0)
			var n01 := _radial(nrm, a0)
			var n10 := _radial(nrm, a1)
			var n11 := _radial(nrm, a1)
			var u0 := float(j) / float(arcs)
			var u1 := float(j + 1) / float(arcs)
			_quad(st, v00, n00, Vector2(u0, 0), v10, n10, Vector2(u1, 0),
					v11, n11, Vector2(u1, 1), v01, n01, Vector2(u0, 1))
	return st.commit()


static func cylinder(radius: float, height: float, segments: int = 24,
		y0: float = 0.0, cap_bottom: bool = true, cap_top: bool = true) -> ArrayMesh:
	var profile := PackedVector2Array([Vector2(radius, y0), Vector2(radius, y0 + height)])
	var mesh := lathe(profile, segments, true)
	if mesh == null:
		return null

	if cap_bottom or cap_top:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var center_b := Vector3(0, y0, 0)
		var center_t := Vector3(0, y0 + height, 0)
		for j in range(segments):
			var a0 := TAU * float(j) / float(segments)
			var a1 := TAU * float(j + 1) / float(segments)
			var p0 := Vector3(cos(a0) * radius, y0, sin(a0) * radius)
			var p1 := Vector3(cos(a1) * radius, y0, sin(a1) * radius)
			if cap_bottom:
				_tri(st, center_b, Vector3.DOWN, Vector2(0.5, 0.5), p1, Vector3.DOWN, Vector2(0, 0), p0, Vector3.DOWN, Vector2(1, 0))
			if cap_top:
				var q0 := Vector3(cos(a0) * radius, y0 + height, sin(a0) * radius)
				var q1 := Vector3(cos(a1) * radius, y0 + height, sin(a1) * radius)
				_tri(st, center_t, Vector3.UP, Vector2(0.5, 0.5), q0, Vector3.UP, Vector2(0, 0), q1, Vector3.UP, Vector2(1, 0))
		var caps := st.commit()
		mesh = merge(mesh, caps)
	return mesh


static func rounded_box_x(length: float, width: float, height: float, corner: float,
		segments: int = 4) -> ArrayMesh:
	var prof := PackedVector2Array()
	var hw := width * 0.5
	var c := minf(corner, minf(hw, height) * 0.9)

	for i in range(segments + 1):
		var a := PI * 0.5 * float(i) / float(segments)
		prof.append(Vector2(hw - c + cos(a) * c, height - c + sin(a) * c))
	for i in range(segments + 1):
		var a := PI * 0.5 + PI * 0.5 * float(i) / float(segments)
		prof.append(Vector2(- hw + c + cos(a) * c, height - c + sin(a) * c))
	prof.append(Vector2(- hw, 0.0))
	prof.append(Vector2(hw, 0.0))
	return extrude(prof, length)




static func extrude(poly: PackedVector2Array, depth: float, cap_front: bool = true, cap_back: bool = true) -> ArrayMesh:
	if poly.size() < 3:
		return null
	var pts := poly

	if _signed_area(pts) < 0.0:
		pts = _reversed(pts)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := pts.size()

	for i in range(n):
		var p0 := pts [i]
		var p1 := pts [(i + 1) %n]
		var edge :=(p1 - p0).normalized()
		var nrm := Vector3(edge.y, - edge.x, 0.0)
		var v0 := Vector3(p0.x, p0.y, 0.0)
		var v1 := Vector3(p0.x, p0.y, depth)
		var v2 := Vector3(p1.x, p1.y, depth)
		var v3 := Vector3(p1.x, p1.y, 0.0)
		_quad(st, v0, nrm, Vector2(0, 0), v1, nrm, Vector2(0, 1), v2, nrm, Vector2(1, 1), v3, nrm, Vector2(1, 0))

	var tris := Geometry2D.triangulate_polygon(pts)
	if cap_back:
		for i in range(0, tris.size(), 3):
			var a := pts [tris [i]]
			var b := pts [tris [i + 1]]
			var c := pts [tris [i + 2]]
			_tri(st, Vector3(a.x, a.y, 0), Vector3.BACK, Vector2(a.x, a.y),
					Vector3(b.x, b.y, 0), Vector3.BACK, Vector2(b.x, b.y),
					Vector3(c.x, c.y, 0), Vector3.BACK, Vector2(c.x, c.y))
	if cap_front:
		for i in range(0, tris.size(), 3):
			var a := pts [tris [i]]
			var b := pts [tris [i + 1]]
			var c := pts [tris [i + 2]]
			_tri(st, Vector3(a.x, a.y, depth), Vector3.FORWARD, Vector2(a.x, a.y),
					Vector3(c.x, c.y, depth), Vector3.FORWARD, Vector2(c.x, c.y),
					Vector3(b.x, b.y, depth), Vector3.FORWARD, Vector2(b.x, b.y))
	return st.commit()




static func loft(profile: PackedVector2Array, frames: Array [Transform3D],
		close_profile: bool = true, cap_ends: bool = false) -> ArrayMesh:
	if profile.size() < 2 or frames.size() < 2:
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := profile.size()
	var count := n if close_profile else n - 1
	var ring_count := frames.size()
	var prev: Array [Vector3] = []
	var prev_n: Array [Vector3] = []
	for fi in range(ring_count):
		var xf := frames [fi]
		var ring: Array [Vector3] = []
		var ring_n: Array [Vector3] = []
		var tangent := - xf.basis.z
		for i in range(n):
			var p := profile [i]
			var pos := xf * Vector3(p.x, p.y, 0.0)
			ring.append(pos)

			var a := profile [i]
			var b := profile [(i + 1) %n]
			var e :=(b - a).normalized()
			var nrm2 := Vector2(e.y, - e.x)
			ring_n.append((xf.basis * Vector3(nrm2.x, nrm2.y, 0.0)).normalized())
		if fi > 0:
			for i in range(count):
				var j :=(i + 1) %n
				var u0 := float(i) / float(n)
				var u1 := float(i + 1) / float(n)
				var v0 := float(fi - 1) / float(ring_count - 1)
				var v1 := float(fi) / float(ring_count - 1)
				_quad(st, prev [i], prev_n [i], Vector2(u0, v0),
						prev [j], prev_n [j], Vector2(u1, v0),
						ring [j], ring_n [j], Vector2(u1, v1),
						ring [i], ring_n [i], Vector2(u0, v1))
		prev = ring
		prev_n = ring_n
	if cap_ends and close_profile:
		var first := frames [0]
		var last := frames [frames.size() - 1]
		var tris := Geometry2D.triangulate_polygon(profile)
		for i in range(0, tris.size(), 3):
			var a := profile [tris [i]]
			var b := profile [tris [i + 1]]
			var c := profile [tris [i + 2]]
			var nf := - first.basis.z
			var nb := - last.basis.z
			_tri(st, first * Vector3(a.x, a.y, 0), nf, a,
					first * Vector3(b.x, b.y, 0), nf, b,
					first * Vector3(c.x, c.y, 0), nf, c)
			_tri(st, last * Vector3(a.x, a.y, 0), nb, a,
					last * Vector3(c.x, c.y, 0), nb, c,
					last * Vector3(b.x, b.y, 0), nb, b)
	return st.commit()


static func frames_from_curve(curve: Curve3D, step: float, from: float = 0.0, to: float = -1.0) -> Array [Transform3D]:
	var frames: Array [Transform3D] = []
	if curve == null:
		return frames
	var total := curve.get_baked_length()
	var end := total if to < 0.0 else minf(to, total)
	var d := from
	while d <= end:
		var pos := curve.sample_baked(d, true)
		var ahead := curve.sample_baked(minf(d + 1.0, total), true)
		var dir :=(ahead - pos).normalized()
		var up := Vector3.UP
		var right := dir.cross(up)
		if right.length_squared() < 0.0001:
			right = Vector3.RIGHT
		right = right.normalized()
		var true_up := right.cross(dir).normalized()
		var basis := Basis(right, true_up, - dir)
		frames.append(Transform3D(basis, pos))
		d += step
	return frames




static func basis_from_y(dir: Vector3) -> Basis:
	var yv := dir.normalized()
	if yv.length_squared() < 1e-8:
		return Basis()
	var ref := Vector3.RIGHT
	if absf(yv.dot(Vector3.RIGHT)) > 0.95:
		ref = Vector3.FORWARD
	var x := ref.cross(yv).normalized()
	var z := x.cross(yv).normalized()
	return Basis(x, yv, z)


static func tube_between(a: Vector3, b: Vector3, radius: float, segments: int = 8, capped: bool = false) -> Array:
	var d := b - a
	var len := d.length()
	if len < 0.0001:
		return []
	var mesh := cylinder(radius, len, segments, 0.0, capped, capped)
	return [mesh, Transform3D(basis_from_y(d), a)]


static func beam_between(a: Vector3, b: Vector3, w: float, h: float) -> Array:
	var d := b - a
	var len := d.length()
	if len < 0.0001:
		return []
	var mesh := box(Vector3(w, len, h))
	return [mesh, Transform3D(basis_from_y(d), a)]



static func _signed_area(pts: PackedVector2Array) -> float:
	var s := 0.0
	var n := pts.size()
	for i in range(n):
		var a := pts [i]
		var b := pts [(i + 1) %n]
		s += a.x * b.y - b.x * a.y
	return s * 0.5

static func _reversed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(pts.size() - 1, -1, -1):
		out.append(pts [i])
	return out


static func merge(a: ArrayMesh, b: ArrayMesh) -> ArrayMesh:
	if a == null:
		return b
	if b == null:
		return a
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(a, 0, Transform3D())
	st.append_from(b, 0, Transform3D())
	return st.commit()


static func merge_all(items: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var added := 0
	for it in items:
		var m: Mesh = null
		var xf := Transform3D()
		if it is Mesh:
			m = it
		elif it is Array and it.size() >= 1:
			m = it [0]
			if it.size() > 1:
				xf = it [1]
		if m == null:
			continue
		if m.get_surface_count() == 0:
			continue
		if m.has_meta("box_size"):
			_emit_box(st, m.get_meta("box_size"), xf)
		else:
			st.append_from(m, 0, xf)
		added += 1
	if added == 0:
		return null
	return st.commit()


static func box(size: Vector3) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_emit_box(st, size, Transform3D())
	var mesh := st.commit()
	mesh.set_meta("box_size", size)
	return mesh


static func _emit_box(st: SurfaceTool, size: Vector3, xf: Transform3D) -> void:
	var h := size * 0.5
	var n_zp := xf.basis * Vector3(0, 0, 1)
	var n_zn := xf.basis * Vector3(0, 0, -1)
	var n_xp := xf.basis * Vector3(1, 0, 0)
	var n_xn := xf.basis * Vector3(-1, 0, 0)
	var n_yp := xf.basis * Vector3(0, 1, 0)
	var n_yn := xf.basis * Vector3(0, -1, 0)
	var p := func(v: Vector3) -> Vector3: return xf * v

	_quad(st, p.call(Vector3(- h.x, - h.y, h.z)), n_zp, Vector2(0, 0), p.call(Vector3(- h.x, h.y, h.z)), n_zp, Vector2(0, 1),
			p.call(Vector3(h.x, h.y, h.z)), n_zp, Vector2(1, 1), p.call(Vector3(h.x, - h.y, h.z)), n_zp, Vector2(1, 0))

	_quad(st, p.call(Vector3(h.x, - h.y, - h.z)), n_zn, Vector2(0, 0), p.call(Vector3(h.x, h.y, - h.z)), n_zn, Vector2(0, 1),
			p.call(Vector3(- h.x, h.y, - h.z)), n_zn, Vector2(1, 1), p.call(Vector3(- h.x, - h.y, - h.z)), n_zn, Vector2(1, 0))

	_quad(st, p.call(Vector3(h.x, - h.y, h.z)), n_xp, Vector2(0, 0), p.call(Vector3(h.x, h.y, h.z)), n_xp, Vector2(0, 1),
			p.call(Vector3(h.x, h.y, - h.z)), n_xp, Vector2(1, 1), p.call(Vector3(h.x, - h.y, - h.z)), n_xp, Vector2(1, 0))

	_quad(st, p.call(Vector3(- h.x, - h.y, - h.z)), n_xn, Vector2(0, 0), p.call(Vector3(- h.x, h.y, - h.z)), n_xn, Vector2(0, 1),
			p.call(Vector3(- h.x, h.y, h.z)), n_xn, Vector2(1, 1), p.call(Vector3(- h.x, - h.y, h.z)), n_xn, Vector2(1, 0))

	_quad(st, p.call(Vector3(- h.x, h.y, h.z)), n_yp, Vector2(0, 0), p.call(Vector3(- h.x, h.y, - h.z)), n_yp, Vector2(0, 1),
			p.call(Vector3(h.x, h.y, - h.z)), n_yp, Vector2(1, 1), p.call(Vector3(h.x, h.y, h.z)), n_yp, Vector2(1, 0))

	_quad(st, p.call(Vector3(- h.x, - h.y, - h.z)), n_yn, Vector2(0, 0), p.call(Vector3(- h.x, - h.y, h.z)), n_yn, Vector2(0, 1),
			p.call(Vector3(h.x, - h.y, h.z)), n_yn, Vector2(1, 1), p.call(Vector3(h.x, - h.y, - h.z)), n_yn, Vector2(1, 0))