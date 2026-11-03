extends Node3D
class_name Terrain



var noise := FastNoiseLite.new()
var ridge := FastNoiseLite.new()
var amplitude := 176.0
var base_height := 0.0
var flat_radius := 34.0
var blend_radius := 210.0
var cell := 50.0

var _corridor := {}
var _river_points := PackedVector2Array()
var _river_levels := PackedFloat32Array()
var _river_depth := 5.0
var _river_half_width := 30.0
var _valley_radius := 260.0
var _river_bounds := Rect2()
var _route_total := 0.0
var _pads: Array = []
var _lakes: Array = []
var _tunnels: Array = []
var _bridges: Array = []
var _viaducts: Array = []

func setup(seed_value: int = 20261017) -> void:
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.00075
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	noise.fractal_lacunarity = 2.15
	noise.fractal_gain = 0.47
	ridge.seed = seed_value + 7919
	ridge.noise_type = FastNoiseLite.TYPE_SIMPLEX
	ridge.frequency = 0.00042
	ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	ridge.fractal_octaves = 5
	ridge.fractal_lacunarity = 2.05
	ridge.fractal_gain = 0.52


func add_pad(center: Vector3, radius: float, blend: float, height: float) -> void:
	_pads.append({"center": center, "radius": radius, "blend": blend, "height": height})


func add_lake(center: Vector2, radius: float, level: float, shore := 90.0) -> void:
	_lakes.append({"center": center, "radius": radius, "level": level, "shore": shore})


func add_tunnel(route: Route, span: Vector2, height: float) -> void:
	if route == null:
		return
	_tunnels.append({"a": span.x, "b": span.y, "height": height})


func add_bridge(route: Route, span: Vector2) -> void:
	if route == null:
		return
	_bridges.append({"a": span.x, "b": span.y})


func add_viaduct(route: Route, span: Vector2, height: float) -> void:
	if route == null:
		return
	_viaducts.append({"a": span.x, "b": span.y, "height": height})


func _in_span(d: float, a: float, b: float) -> bool:
	if a <= b:
		return d >= a and d <= b
	return d >= a or d <= b


func _span_near(d: float, a: float, b: float, margin: float) -> bool:
	return _in_span(d, a - margin, b + margin)


func _span_edge(d: float, a: float, b: float) -> float:
	var total := _route_total
	if total <= 0.0:
		return 99999.0
	var rel := fposmod(d - a, total)
	var span := fposmod(b - a, total)
	return minf(rel, maxf(0.0, span - rel))


func inside_pad(x: float, z: float, scale := 1.0) -> bool:
	for p in _pads:
		var c: Vector3 = p["center"]
		var r := (float(p["radius"]) + float(p["blend"]) * 0.45) * scale
		if Vector2(x - c.x, z - c.z).length_squared() < r * r:
			return true
	return false


func inside_water(x: float, z: float) -> bool:
	for lake: Dictionary in _lakes:
		var c: Vector2 = lake ["center"]
		var r := float(lake ["radius"]) + 8.0
		if Vector2(x - c.x, z - c.y).length_squared() < r * r:
			return true
	if _river_points.size() >= 2:
		var info := _nearest_river(x, z)
		if float(info [0]) < _river_half_width + 6.0:
			return true
	return false



func add_corridor(route: Route, step := 10.0) -> void:
	if route == null:
		return
	_route_total = route.total
	var d := 0.0
	while d <= route.total:
		var p := route.position_at(d)
		var key := _key(p.x, p.z)
		if not _corridor.has(key):
			_corridor [key] = []
		_corridor [key].append([p, d])
		d += step

func _key(x: float, z: float) -> Vector2i:
	return Vector2i(int(floor(x / cell)), int(floor(z / cell)))

func _nearest_corridor(x: float, z: float) -> Variant:
	var cx := int(floor(x / cell))
	var cz := int(floor(z / cell))
	var best: Variant = null
	var best_d := INF
	for dx in range(-3, 4):
		for dz in range(-3, 4):
			var k := Vector2i(cx + dx, cz + dz)
			if not _corridor.has(k):
				continue
			for entry: Array in _corridor [k]:
				var p: Vector3 = entry [0]
				var d :=(x - p.x) *(x - p.x) +(z - p.z) *(z - p.z)
				if d < best_d:
					best_d = d
					best = entry
	return best



func add_river(points: PackedVector2Array, depth := 5.0, half_width := 30.0, valley := 260.0) -> void:
	_river_points = points
	_river_depth = depth
	_river_half_width = half_width
	_valley_radius = valley
	_prepare_river()

func _prepare_river() -> void:
	_river_levels = PackedFloat32Array()
	var n := _river_points.size()
	if n < 2:
		return
	_river_levels.resize(n)
	var minx := INF
	var miny := INF
	var maxx := - INF
	var maxy := - INF
	for i in range(n):
		var p := _river_points [i]
		_river_levels [i] = base_height + noise.get_noise_2d(p.x, p.y) * amplitude
		minx = minf(minx, p.x)
		miny = minf(miny, p.y)
		maxx = maxf(maxx, p.x)
		maxy = maxf(maxy, p.y)
	_river_bounds = Rect2(minx, miny, maxx - minx, maxy - miny)

	var smoothed := _river_levels.duplicate()
	var window := 2
	for i in range(n):
		var sum := 0.0
		var cnt := 0
		for j in range(maxi(0, i - window), mini(n, i + window + 1)):
			sum += _river_levels [j]
			cnt += 1
		smoothed [i] = sum / float(cnt)
	_river_levels = smoothed
	for i in range(_river_levels.size()):
		_river_levels [i] -= _river_depth * 0.5

func _apply_river(h: float, x: float, z: float) -> float:
	if _river_points.size() < 2:
		return h

	if x < _river_bounds.position.x - _valley_radius or x > _river_bounds.end.x + _valley_radius:
		return h
	if z < _river_bounds.position.y - _valley_radius or z > _river_bounds.end.y + _valley_radius:
		return h
	var info := _nearest_river(x, z)
	var d: float = info [0]
	if d > _valley_radius:
		return h
	var level: float = info [1]
	var target := level + 0.34 * d
	if h > target:
		var t := smoothstep(_valley_radius, 0.0, d)
		h = lerpf(h, target, clampf(t * 1.2, 0.0, 1.0))
	if d < _river_half_width:
		var k := 1.0 - d / _river_half_width
		h = minf(h, level - 1.0 - 2.2 * k)
	return h

func _nearest_river(x: float, z: float) -> Array:
	var best := INF
	var level := 0.0
	var p := Vector2(x, z)
	for i in range(_river_points.size() - 1):
		var a := _river_points [i]
		var b := _river_points [i + 1]
		var ab := b - a
		var len2 := ab.length_squared()
		var t := 0.0
		if len2 > 0.000001:
			t = clampf((p - a).dot(ab) / len2, 0.0, 1.0)
		var proj := a + ab * t
		var dd := p.distance_to(proj)
		if dd < best:
			best = dd
			level = lerpf(_river_levels [i], _river_levels [i + 1], t)
	return [best, level]



func height_at(x: float, z: float) -> float:
	var h := base_height + noise.get_noise_2d(x, z) * amplitude
	h += noise.get_noise_2d(x * 3.1 + 512.0, z * 3.1 + 512.0) * amplitude * 0.14
	var ridged := (ridge.get_noise_2d(x, z) * 0.5 + 0.5)
	if ridged > 0.34:
		h += (ridged - 0.34) * 245.0
	# A second, broader massif layer gives the compact map a proper mountain
	# skyline instead of only small hills between the settlements.
	var massif := (ridge.get_noise_2d(x * 0.52 + 1830.0, z * 0.52 - 940.0) * 0.5 + 0.5)
	if massif > 0.46:
		h += (massif - 0.46) * 210.0
	h = _apply_river(h, x, z)
	for lake: Dictionary in _lakes:
		var c: Vector2 = lake ["center"]
		var d := Vector2(x - c.x, z - c.y).length()
		var rad := float(lake ["radius"])
		var shore := float(lake ["shore"])
		if d < rad + shore:
			var t := 1.0 - smoothstep(rad, rad + shore, d)
			h = lerpf(h, float(lake ["level"]) - 0.8, t)
			if d < rad:
				h = minf(h, float(lake ["level"]) - 1.4)
	for pad: Dictionary in _pads:
		var c: Vector3 = pad ["center"]
		var d := Vector2(x - c.x, z - c.z).length()
		var rad := float(pad ["radius"])
		var blend := float(pad ["blend"])
		if d < rad + blend:
			var t := 1.0 - smoothstep(rad, rad + blend, d)
			h = lerpf(h, float(pad ["height"]), t)
	var entry: Variant = _nearest_corridor(x, z)
	if entry != null:
		var pt: Vector3 = entry [0]
		var rd: float = entry [1]
		var dx := x - pt.x
		var dz := z - pt.z
		var d := sqrt(dx * dx + dz * dz)
		if d < blend_radius:
			var t := 1.0
			if d > flat_radius:
				t = 1.0 - smoothstep(flat_radius, blend_radius, d)
			var bridge: Dictionary = {}
			for b: Dictionary in _bridges:
				if _in_span(rd, float(b ["a"]), float(b ["b"])):
					bridge = b
					break
			var tunnel: Dictionary = {}
			for tn: Dictionary in _tunnels:
				var ta := float(tn ["a"]) + 28.0
				var tb := float(tn ["b"]) - 28.0
				if _in_span(rd, ta, tb):
					tunnel = tn
					break
			var viaduct: Dictionary = {}
			for vd: Dictionary in _viaducts:
				if _in_span(rd, float(vd ["a"]), float(vd ["b"])):
					viaduct = vd
					break
			if not tunnel.is_empty():
				var target: float = pt.y + float(tunnel ["height"])
				h = lerpf(h, target, t)
			elif not bridge.is_empty():
				var ba := float(bridge ["a"])
				var bb := float(bridge ["b"])
				var edge := _span_edge(rd, ba, bb)
				var end_blend := smoothstep(0.0, 1.0, clampf(edge / 120.0, 0.0, 1.0))
				var target := lerpf(pt.y - 0.75, pt.y - 19.0, end_blend)
				if h > target:
					h = lerpf(h, target, t)
			elif not viaduct.is_empty():
				var va := float(viaduct ["a"])
				var vb := float(viaduct ["b"])
				var edge := _span_edge(rd, va, vb)
				var end_blend := smoothstep(0.0, 1.0, clampf(edge / 180.0, 0.0, 1.0))
				var target := pt.y - 0.75 - (float(viaduct ["height"]) - 0.75) * end_blend
				if h > target:
					h = lerpf(h, target, t)
			else:
				var target := pt.y - 0.75
				h = lerpf(h, target, t)
	return h




func _sample_rows(x0: float, z0: float, step: float, n: int, start_row: int, row_count: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(row_count * n)
	for r in range(row_count):
		var z := z0 + float(start_row + r) * step
		var base := r * n
		for ix in range(n):
			out[base + ix] = height_at(x0 + float(ix) * step, z)
	return out


func sample_grid_parallel(size: float, divisions: int, origin: Vector2) -> PackedFloat32Array:
	# Terrain height sampling is pure math. Split the grid across CPU workers so
	# the 640x640 near mesh no longer dominates the loading time.
	var n := divisions + 1
	var half := size * 0.5
	var step := size / float(divisions)
	var heights := PackedFloat32Array()
	heights.resize(n * n)
	var chunks := clampi(OS.get_processor_count(), 1, 8)
	var rows_per := int(ceil(float(n) / float(chunks)))
	var x0 := origin.x - half
	var z0 := origin.y - half
	var threads: Array = []
	var specs: Array = []
	for c in range(chunks):
		var start := c * rows_per
		var count := mini(rows_per, n - start)
		if count <= 0:
			continue
		var t := Thread.new()
		var err := t.start(Callable(self, "_sample_rows").bind(x0, z0, step, n, start, count))
		if err == OK:
			threads.append(t)
			specs.append([start, count, threads.size() - 1])
		else:
			var arr := _sample_rows(x0, z0, step, n, start, count)
			for r in range(count):
				for ix in range(n):
					heights[(start + r) * n + ix] = arr[r * n + ix]
	var results: Array = []
	results.resize(threads.size())
	for i in range(threads.size()):
		results[i] = threads[i].wait_to_finish()
	for spec: Array in specs:
		var arr: PackedFloat32Array = results[int(spec[2])]
		var start := int(spec[0])
		var count := int(spec[1])
		for r in range(count):
			var dst := (start + r) * n
			var src := r * n
			for ix in range(n):
				heights[dst + ix] = arr[src + ix]
	return heights


func _build_strip_mesh(heights: PackedFloat32Array, n: int, origin: Vector2, step: float,
		divisions: int, x_start: int, x_count: int, uvinv: float,
		skip_inner: bool, inner_half: float) -> ArrayMesh:
	var half := float(divisions) * step * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in range(divisions):
		var z0 := origin.y - half + float(iz) * step
		var z1 := z0 + step
		for ix in range(x_start, x_start + x_count):
			var x0 := origin.x - half + float(ix) * step
			var x1 := x0 + step
			if skip_inner:
				var cx := (x0 + x1) * 0.5
				var cz := (z0 + z1) * 0.5
				if absf(cx) < inner_half and absf(cz) < inner_half:
					continue
			var h00 := heights[iz * n + ix]
			var h10 := heights[iz * n + ix + 1]
			var h01 := heights[(iz + 1) * n + ix]
			var h11 := heights[(iz + 1) * n + ix + 1]
			var v00 := Vector3(x0, h00, z0)
			var v10 := Vector3(x1, h10, z0)
			var v01 := Vector3(x0, h01, z1)
			var v11 := Vector3(x1, h11, z1)
			var n00 := _grid_normal(heights, ix, iz, n, step)
			var n10 := _grid_normal(heights, ix + 1, iz, n, step)
			var n01 := _grid_normal(heights, ix, iz + 1, n, step)
			var n11 := _grid_normal(heights, ix + 1, iz + 1, n, step)
			Forge._tri(st, v00, n00, Vector2(x0, z0) * uvinv, v10, n10, Vector2(x1, z0) * uvinv,
					v11, n11, Vector2(x1, z1) * uvinv)
			Forge._tri(st, v00, n00, Vector2(x0, z0) * uvinv, v11, n11, Vector2(x1, z1) * uvinv,
					v01, n01, Vector2(x0, z1) * uvinv)
	return st.commit()


func _make_terrain_mesh(size: float, divisions: int, origin: Vector2, mat: Material,
		outer := false, inner_size := 0.0) -> MeshInstance3D:
	var n := divisions + 1
	var half := size * 0.5
	var step := size / float(divisions)
	var heights := sample_grid_parallel(size, divisions, origin)
	var uvinv := 0.0 if outer else 0.006
	var inner_half := inner_size * 0.5 - step * 0.6
	var mesh := _build_strip_mesh(heights, n, origin, step, divisions, 0, divisions,
			uvinv, outer, inner_half)
	var mi := MeshInstance3D.new()
	mi.name = "TerrainOuter" if outer else "TerrainNear"
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if outer \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi


func build_mesh(size: float, divisions: int, mat: Material, origin := Vector2.ZERO) -> MeshInstance3D:
	return _make_terrain_mesh(size, divisions, origin, mat, false, 0.0)


func build_outer_mesh(inner_size: float, outer_size: float, divisions: int, mat: Material) -> MeshInstance3D:
	return _make_terrain_mesh(outer_size, divisions, Vector2.ZERO, mat, true, inner_size)


func build_mesh_async(size: float, divisions: int, mat: Material, origin: Vector2,
		progress := Callable()) -> MeshInstance3D:
	if progress.is_valid():
		progress.call(0.08)
	await get_tree().process_frame
	var mi := build_mesh(size, divisions, mat, origin)
	if progress.is_valid():
		progress.call(1.0)
	await get_tree().process_frame
	return mi


func build_outer_mesh_async(inner_size: float, outer_size: float, divisions: int, mat: Material,
		progress := Callable()) -> MeshInstance3D:
	if progress.is_valid():
		progress.call(0.08)
	await get_tree().process_frame
	var mi := build_outer_mesh(inner_size, outer_size, divisions, mat)
	if progress.is_valid():
		progress.call(1.0)
	await get_tree().process_frame
	return mi


func _legacy_build_mesh(size: float, divisions: int, mat: Material, origin := Vector2.ZERO) -> MeshInstance3D:
	var n := divisions + 1
	var half := size * 0.5
	var step := size / float(divisions)
	var heights := sample_grid_parallel(size, divisions, origin)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var uvinv := 0.006
	for iz in range(divisions):
		for ix in range(divisions):
			var x0 := origin.x - half + float(ix) * step
			var z0 := origin.y - half + float(iz) * step
			var x1 := x0 + step
			var z1 := z0 + step
			var h00 := heights [iz * n + ix]
			var h10 := heights [iz * n + ix + 1]
			var h01 := heights [(iz + 1) * n + ix]
			var h11 := heights [(iz + 1) * n + ix + 1]
			var v00 := Vector3(x0, h00, z0)
			var v10 := Vector3(x1, h10, z0)
			var v01 := Vector3(x0, h01, z1)
			var v11 := Vector3(x1, h11, z1)
			var n00 := _grid_normal(heights, ix, iz, n, step)
			var n10 := _grid_normal(heights, ix + 1, iz, n, step)
			var n01 := _grid_normal(heights, ix, iz + 1, n, step)
			var n11 := _grid_normal(heights, ix + 1, iz + 1, n, step)
			Forge._tri(st, v00, n00, Vector2(x0, z0) * uvinv, v10, n10, Vector2(x1, z0) * uvinv, v11, n11, Vector2(x1, z1) * uvinv)
			Forge._tri(st, v00, n00, Vector2(x0, z0) * uvinv, v11, n11, Vector2(x1, z1) * uvinv, v01, n01, Vector2(x0, z1) * uvinv)
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.name = "TerrainNear"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi

func _grid_normal(heights: PackedFloat32Array, ix: int, iz: int, n: int, step: float) -> Vector3:
	var i0 := clampi(ix - 1, 0, n - 1)
	var i1 := clampi(ix + 1, 0, n - 1)
	var j0 := clampi(iz - 1, 0, n - 1)
	var j1 := clampi(iz + 1, 0, n - 1)
	var hl := heights [iz * n + i0]
	var hr := heights [iz * n + i1]
	var hd := heights [j0 * n + ix]
	var hu := heights [j1 * n + ix]
	var dx := float(i1 - i0) * step
	var dz := float(j1 - j0) * step
	return Vector3(hl - hr, dx if dx > 0.0 else 1.0, hd - hu).normalized() if dx > 0.0 and dz > 0.0 else Vector3.UP


func _legacy_build_outer_mesh(inner_size: float, outer_size: float, divisions: int, mat: Material) -> MeshInstance3D:
	var n := divisions + 1
	var half := outer_size * 0.5
	var step := outer_size / float(divisions)
	var heights := sample_grid_parallel(outer_size, divisions, Vector2.ZERO)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner_half := inner_size * 0.5 - step * 0.6
	for iz in range(divisions):
		for ix in range(divisions):
			var x0 := - half + float(ix) * step
			var z0 := - half + float(iz) * step
			var x1 := x0 + step
			var z1 := z0 + step
			var cx :=(x0 + x1) * 0.5
			var cz :=(z0 + z1) * 0.5
			if absf(cx) < inner_half and absf(cz) < inner_half:
				continue
			var v00 := Vector3(x0, heights [iz * n + ix], z0)
			var v10 := Vector3(x1, heights [iz * n + ix + 1], z0)
			var v01 := Vector3(x0, heights [(iz + 1) * n + ix], z1)
			var v11 := Vector3(x1, heights [(iz + 1) * n + ix + 1], z1)
			var n00 := _grid_normal(heights, ix, iz, n, step)
			var n10 := _grid_normal(heights, ix + 1, iz, n, step)
			var n01 := _grid_normal(heights, ix, iz + 1, n, step)
			var n11 := _grid_normal(heights, ix + 1, iz + 1, n, step)
			Forge._tri(st, v00, n00, Vector2.ZERO, v10, n10, Vector2.ZERO, v11, n11, Vector2.ZERO)
			Forge._tri(st, v00, n00, Vector2.ZERO, v11, n11, Vector2.ZERO, v01, n01, Vector2.ZERO)
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.name = "TerrainOuter"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _legacy_build_outer_mesh_async(inner_size: float, outer_size: float, divisions: int, mat: Material, progress := Callable()) -> MeshInstance3D:
	var n := divisions + 1
	var half := outer_size * 0.5
	var step := outer_size / float(divisions)
	var heights := sample_grid_parallel(outer_size, divisions, Vector2.ZERO)
	if progress.is_valid():
		progress.call(0.45)
	await get_tree().process_frame
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner_half := inner_size * 0.5 - step * 0.6
	for iz in range(divisions):
		for ix in range(divisions):
			var x0 := - half + float(ix) * step
			var z0 := - half + float(iz) * step
			var x1 := x0 + step
			var z1 := z0 + step
			var cx :=(x0 + x1) * 0.5
			var cz :=(z0 + z1) * 0.5
			if absf(cx) < inner_half and absf(cz) < inner_half:
				continue
			var v00 := Vector3(x0, heights [iz * n + ix], z0)
			var v10 := Vector3(x1, heights [iz * n + ix + 1], z0)
			var v01 := Vector3(x0, heights [(iz + 1) * n + ix], z1)
			var v11 := Vector3(x1, heights [(iz + 1) * n + ix + 1], z1)
			var n00 := _grid_normal(heights, ix, iz, n, step)
			var n10 := _grid_normal(heights, ix + 1, iz, n, step)
			var n01 := _grid_normal(heights, ix, iz + 1, n, step)
			var n11 := _grid_normal(heights, ix + 1, iz + 1, n, step)
			Forge._tri(st, v00, n00, Vector2.ZERO, v10, n10, Vector2.ZERO, v11, n11, Vector2.ZERO)
			Forge._tri(st, v00, n00, Vector2.ZERO, v11, n11, Vector2.ZERO, v01, n01, Vector2.ZERO)
		if iz % 2 == 0:
			if progress.is_valid():
				progress.call(0.4 + 0.6 * float(iz) / float(divisions))
			await get_tree().process_frame
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.name = "TerrainOuter"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func build_lake(center: Vector2, radius: float, level: float, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := center
	var segs := 72
	for i in range(segs):
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		var p0 := Vector3(c.x + cos(a0) * radius, level, c.y + sin(a0) * radius)
		var p1 := Vector3(c.x + cos(a1) * radius, level, c.y + sin(a1) * radius)
		Forge._tri(st, Vector3(c.x, level, c.y), Vector3.UP, Vector2(c.x, c.y) * 0.02,
				p0, Vector3.UP, Vector2(p0.x, p0.z) * 0.02, p1, Vector3.UP, Vector2(p1.x, p1.z) * 0.02)
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.name = "LakeWater"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func build_water(half_width := 34.0, mat: Material = null) -> MeshInstance3D:
	var n := _river_points.size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if n >= 2 and mat != null:
		var uvinv := 0.02
		var left := PackedVector3Array()
		var right := PackedVector3Array()
		left.resize(n)
		right.resize(n)
		for i in range(n):
			var a := _river_points[maxi(i - 1, 0)]
			var b := _river_points[mini(i + 1, n - 1)]
			var dir := b - a
			if dir.length_squared() < 0.000001:
				dir = Vector2(1.0, 0.0)
			dir = dir.normalized()
			var perp := Vector2(- dir.y, dir.x)
			var y := _river_levels [i] - 0.15
			var c := _river_points [i]
			var w := half_width
			left [i] = Vector3(c.x + perp.x * w, y, c.y + perp.y * w)
			right [i] = Vector3(c.x - perp.x * w, y, c.y - perp.y * w)
		for i in range(n - 1):
			var v0 := left [i]
			var v1 := right [i]
			var v2 := left [i + 1]
			var v3 := right [i + 1]
			Forge._tri(st, v0, Vector3.UP, Vector2(v0.x, v0.z) * uvinv, v1, Vector3.UP, Vector2(v1.x, v1.z) * uvinv, v3, Vector3.UP, Vector2(v3.x, v3.z) * uvinv)
			Forge._tri(st, v0, Vector3.UP, Vector2(v0.x, v0.z) * uvinv, v3, Vector3.UP, Vector2(v3.x, v3.z) * uvinv, v2, Vector3.UP, Vector2(v2.x, v2.z) * uvinv)
	var mesh := st.commit()
	if mesh != null and mesh.get_surface_count() > 0:
		mesh.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.name = "Water"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
func _legacy_build_mesh_async(size: float, divisions: int, mat: Material, origin: Vector2, progress := Callable()) -> MeshInstance3D:
	var n := divisions + 1
	var half := size * 0.5
	var step := size / float(divisions)
	var heights := sample_grid_parallel(size, divisions, origin)
	if progress.is_valid():
		progress.call(0.45)
	await get_tree().process_frame

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var uvinv := 0.006
	for iz in range(divisions):
		for ix in range(divisions):
			var x0 := origin.x - half + float(ix) * step
			var z0 := origin.y - half + float(iz) * step
			var x1 := x0 + step
			var z1 := z0 + step
			var h00 := heights [iz * n + ix]
			var h10 := heights [iz * n + ix + 1]
			var h01 := heights [(iz + 1) * n + ix]
			var h11 := heights [(iz + 1) * n + ix + 1]
			var v00 := Vector3(x0, h00, z0)
			var v10 := Vector3(x1, h10, z0)
			var v01 := Vector3(x0, h01, z1)
			var v11 := Vector3(x1, h11, z1)
			var n00 := _grid_normal(heights, ix, iz, n, step)
			var n10 := _grid_normal(heights, ix + 1, iz, n, step)
			var n01 := _grid_normal(heights, ix, iz + 1, n, step)
			var n11 := _grid_normal(heights, ix + 1, iz + 1, n, step)
			Forge._tri(st, v00, n00, Vector2(x0, z0) * uvinv, v10, n10, Vector2(x1, z0) * uvinv, v11, n11, Vector2(x1, z1) * uvinv)
			Forge._tri(st, v00, n00, Vector2(x0, z0) * uvinv, v11, n11, Vector2(x1, z1) * uvinv, v01, n01, Vector2(x0, z1) * uvinv)
		if progress.is_valid():
			progress.call(0.42 + 0.58 * float(iz) / float(divisions))
		await get_tree().process_frame
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.name = "TerrainNear"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if progress.is_valid():
		progress.call(1.0)
	return mi