extends Node3D
class_name Settlement


var night_windows: Array [GeometryInstance3D] = []
var night_lights: Array [OmniLight3D] = []
var _window_mat: StandardMaterial3D
var _lamp_mat: StandardMaterial3D
var _trim_mat: StandardMaterial3D
var _curb_mat: StandardMaterial3D


static func build(parent: Node3D, route: Route, site: Dictionary, yield_frames := false) -> Settlement:
	var s := Settlement.new()
	s.name = "Settlement_%s" %String(site["name"])
	parent.add_child(s)
	s._build(route, site, yield_frames)
	return s

static func build_async(parent: Node3D, route: Route, site: Dictionary) -> Settlement:
	var s := Settlement.new()
	s.name = "Settlement_%s" %String(site["name"])
	parent.add_child(s)
	await s._build(route, site, true)
	return s


func _build(route: Route, site: Dictionary, yield_frames := false) -> void:
	var city := String(site["kind"]) == "city"
	var center: Vector3 = site["center"]
	var pad_h := float(site["height"])
	var radius := float(site["radius"])
	var rng := RandomNumberGenerator.new()
	rng.seed = int(center.x * 13.0 + center.z * 7.0 + (17 if city else 3))
	var walls := [
		Gfx.paint(Color(0.52, 0.53, 0.54), 0.7, 0.05, 0.15),
		Gfx.paint(Color(0.38, 0.41, 0.44), 0.68, 0.08, 0.12),
		Gfx.paint(Color(0.62, 0.55, 0.46), 0.72, 0.04, 0.1),
		Gfx.paint(Color(0.34, 0.37, 0.4), 0.62, 0.12, 0.18),
	]
	var roof_mat := Gfx.metal(Color(0.16, 0.17, 0.18), 0.74, 0.25)
	var road_mat := Gfx.noise_surface(Color(0.095, 0.1, 0.11), 0.9, 0.4, 0.35)
	var walk_mat := Gfx.noise_surface(Color(0.245, 0.25, 0.25), 0.92, 0.35, 0.3)
	var grass := Gfx.noise_surface(Color(0.16, 0.27, 0.12), 0.96, 0.5, 0.4)
	_window_mat = Gfx.emissive(Color(1.0, 0.72, 0.4), 0.1, Color(0.018, 0.026, 0.042))
	_window_mat.emission_energy_multiplier = 0.03
	_trim_mat = Gfx.metal(Color(0.25, 0.26, 0.27), 0.58, 0.45)
	var window_dark := Gfx.glass(Color(0.014, 0.02, 0.03), 0.04, 0.64)
	_curb_mat = Gfx.paint(Color(0.42, 0.43, 0.42), 0.82, 0.0, 0.1)
	var shop_mat := Gfx.glass(Color(0.04, 0.06, 0.08), 0.12, 0.72)
	var mark_white := Gfx.paint(Color(0.62, 0.63, 0.58), 0.8, 0.0, 0.1)
	var mark_yellow := Gfx.paint(Color(0.72, 0.55, 0.15), 0.75, 0.0, 0.1)
	_lamp_mat = Gfx.emissive(Color(1.0, 0.82, 0.5), 1.2, Color(0.18, 0.15, 0.1))

	var walls_items: Array = []
	var roof_items: Array = []
	var window_items: Array = []
	var dark_window_items: Array = []
	var road_items: Array = []
	var walk_items: Array = []
	var grass_items: Array = []
	var detail_items: Array = []
	var lamp_items: Array = []
	var trim_items: Array = []
	var mark_items: Array = []
	var shop_items: Array = []

	var low := Config.quality <= Config.Quality.LOW
	var block := (72.0 if low else 54.0) if city else 34.0
	var road_w := 11.0 if city else 6.0
	var sidewalk := 2.2
	var grid := int(radius / block)
	var concrete_items: Array = []
	concrete_items.append([Forge.cylinder(radius * 0.97, 0.02, 64, -0.05, false, true),
			Transform3D(Basis(), Vector3(center.x, pad_h + 0.02, center.z))])

	for gx in range(-grid, grid + 1):
		for gz in range(-grid, grid + 1):
			var bx := center.x + float(gx) * block
			var bz := center.z + float(gz) * block
			var dist := Vector2(bx - center.x, bz - center.z).length()
			if dist > radius - block * 0.35:
				continue
			var is_road_x := absf(fmod(float(gz), 3.0)) < 0.1
			var is_road_z := absf(fmod(float(gx), 3.0)) < 0.1
			if is_road_x or is_road_z:
				var rw := road_w
				if is_road_x:
					road_items.append([Forge.box(Vector3(block * 2.0, 0.035, rw)),
							Transform3D(Basis(), Vector3(bx, pad_h + 0.075, bz))])
					walk_items.append([Forge.box(Vector3(block * 2.0, 0.055, sidewalk)),
							Transform3D(Basis(), Vector3(bx, pad_h + 0.105, bz + rw * 0.5 + sidewalk * 0.5))])
					walk_items.append([Forge.box(Vector3(block * 2.0, 0.055, sidewalk)),
							Transform3D(Basis(), Vector3(bx, pad_h + 0.105, bz - rw * 0.5 - sidewalk * 0.5))])
				if is_road_z:
					road_items.append([Forge.box(Vector3(rw, 0.035, block * 2.0)),
							Transform3D(Basis(), Vector3(bx, pad_h + 0.08, bz))])
					walk_items.append([Forge.box(Vector3(sidewalk, 0.055, block * 2.0)),
							Transform3D(Basis(), Vector3(bx + rw * 0.5 + sidewalk * 0.5, pad_h + 0.105, bz))])
					walk_items.append([Forge.box(Vector3(sidewalk, 0.055, block * 2.0)),
							Transform3D(Basis(), Vector3(bx - rw * 0.5 - sidewalk * 0.5, pad_h + 0.105, bz))])
				if is_road_x:
					for d in range(-3, 4):
						mark_items.append([Forge.box(Vector3(2.5, 0.014, 0.13)),
								Transform3D(Basis(), Vector3(bx + float(d) * block * 0.24, pad_h + 0.099, bz))])
					trim_items.append([Forge.box(Vector3(block * 2.0, 0.08, 0.16)),
							Transform3D(Basis(), Vector3(bx, pad_h + 0.118, bz + rw * 0.5 + 0.08))])
					trim_items.append([Forge.box(Vector3(block * 2.0, 0.08, 0.16)),
							Transform3D(Basis(), Vector3(bx, pad_h + 0.118, bz - rw * 0.5 - 0.08))])
				if is_road_z:
					for d in range(-3, 4):
						mark_items.append([Forge.box(Vector3(0.13, 0.014, 2.5)),
								Transform3D(Basis(), Vector3(bx, pad_h + 0.101, bz + float(d) * block * 0.24))])
					trim_items.append([Forge.box(Vector3(0.16, 0.08, block * 2.0)),
							Transform3D(Basis(), Vector3(bx + rw * 0.5 + 0.08, pad_h + 0.118, bz))])
					trim_items.append([Forge.box(Vector3(0.16, 0.08, block * 2.0)),
							Transform3D(Basis(), Vector3(bx - rw * 0.5 - 0.08, pad_h + 0.118, bz))])
				if is_road_x and is_road_z:
					for k in range(5):
						mark_items.append([Forge.box(Vector3(0.62, 0.014, rw * 0.72)),
								Transform3D(Basis(), Vector3(bx - rw * 0.42 + float(k) * 0.44, pad_h + 0.103, bz))])
				continue
			if rng.randf() < (0.20 if city else 0.36):
				if rng.randf() < 0.60:
					grass_items.append([Forge.box(Vector3(block * 0.66, 0.07, block * 0.66)),
							Transform3D(Basis(), Vector3(bx, pad_h + 0.08, bz))])
					for ti in range(rng.randi_range(2, 5) if city else rng.randi_range(1, 3)):
						var tx := bx + rng.randf_range(-block * 0.22, block * 0.22)
						var tz := bz + rng.randf_range(-block * 0.22, block * 0.22)
						detail_items.append([Forge.cylinder(0.16, 2.2, 6, 0.0, false, true),
								Transform3D(Basis(), Vector3(tx, pad_h + 0.1, tz))])
						detail_items.append([Forge.lathe(PackedVector2Array([
							Vector2(0.0, 0.0), Vector2(1.4, 1.4), Vector2(1.0, 2.8), Vector2(0.0, 3.6)
						]), 7, true), Transform3D(Basis(), Vector3(tx, pad_h + 1.9, tz))])
				continue
			var count := rng.randi_range(1, 3) if city else rng.randi_range(1, 2)
			if Config.quality <= Config.Quality.LOW:
				count = 1
			for b in range(count):
				var ox := rng.randf_range(-block * 0.3, block * 0.3)
				var oz := rng.randf_range(-block * 0.3, block * 0.3)
				var px := bx + ox
				var pz := bz + oz
				var local := route.frame_at(route.nearest_dist(Vector3(px, pad_h, pz))).affine_inverse() * Vector3(px, pad_h, pz)
				if absf(local.x) < 34.0 and absf(local.z) < 520.0:
					continue
				if Vector2(px - center.x, pz - center.z).length() > radius - 18.0:
					continue
				var w := rng.randf_range(17.0, 31.0) if city else rng.randf_range(8.0, 15.0)
				var dep := rng.randf_range(14.0, 25.0) if city else rng.randf_range(7.0, 13.0)
				var h := 7.0
				var podium_h := 0.0
				if city:
					var core := 1.0 - clampf(Vector2(px - center.x, pz - center.z).length() / radius, 0.0, 1.0)
					h = rng.randf_range(14.0, 28.0) + core * rng.randf_range(14.0, 52.0)
					# Keep most blocks mid-rise, with a restrained number of
					# genuine towers near the city core.
					if core > 0.42 and rng.randf() < 0.22:
						h = maxf(h, rng.randf_range(62.0, 94.0))
					podium_h = minf(11.0, h * 0.32)
				else:
					h = rng.randf_range(6.0, 14.0)
				var y := pad_h + 0.14
				var facade_dep := dep * (1.18 if city else 1.0)
				var wi := rng.randi_range(0, walls.size() - 1)
				# Bigger city masses read as buildings rather than flat cards:
				# a wider podium, a full-height tower and a stepped crown give
				# each block a real silhouette against the sky.
				if city:
					walls_items.append([Forge.box(Vector3(w * 1.18, podium_h, dep * 1.18)),
							Transform3D(Basis(), Vector3(px, y + podium_h * 0.5, pz)), wi])
					var upper_h := maxf(4.0, h - podium_h)
					walls_items.append([Forge.box(Vector3(w, upper_h, dep)),
							Transform3D(Basis(), Vector3(px, y + podium_h + upper_h * 0.5, pz)), wi])
					if h > 34.0:
						var crown_h := rng.randf_range(2.5, 6.5)
						walls_items.append([Forge.box(Vector3(w * 0.58, crown_h, dep * 0.58)),
								Transform3D(Basis(), Vector3(px, y + h + crown_h * 0.5, pz)), wi])
						trim_items.append([Forge.box(Vector3(0.22, 2.6, 0.22)),
								Transform3D(Basis(), Vector3(px + w * 0.18, y + h + crown_h + 1.3, pz + dep * 0.18))])
						detail_items.append([Forge.box(Vector3(0.8, 0.8, 0.8)),
								Transform3D(Basis(), Vector3(px - w * 0.18, y + h + crown_h + 0.4, pz - dep * 0.18))])
					# Deep vertical fins on the street elevations break up the
					# flat window grid and catch the low sun.
					if not low:
						for fx: float in [-0.34, 0.0, 0.34]:
							trim_items.append([Forge.box(Vector3(0.32, minf(h, 38.0), 1.0)),
									Transform3D(Basis(), Vector3(px + w * fx, y + minf(h, 38.0) * 0.5, pz + dep * 0.52))])
				else:
					walls_items.append([Forge.box(Vector3(w, h, dep)),
							Transform3D(Basis(), Vector3(px, y + h * 0.5, pz)), wi])
				if city:
					roof_items.append([Forge.box(Vector3(w + 0.45, 0.24, dep + 0.45)),
							Transform3D(Basis(), Vector3(px, y + h + 0.12, pz))])
					trim_items.append([Forge.box(Vector3(w + 0.55, 0.35, 0.18)),
							Transform3D(Basis(), Vector3(px, y + h + 0.42, pz + dep * 0.5))])
					trim_items.append([Forge.box(Vector3(w + 0.55, 0.35, 0.18)),
							Transform3D(Basis(), Vector3(px, y + h + 0.42, pz - dep * 0.5))])
					trim_items.append([Forge.box(Vector3(w * 0.22, 0.8, dep * 0.3)),
							Transform3D(Basis(), Vector3(px + w * 0.25, y + h + 0.62, pz - dep * 0.12))])
					if h > 24.0:
						trim_items.append([Forge.box(Vector3(0.15, 1.5, 0.15)), Transform3D(Basis(), Vector3(px - w * 0.28, y + h + 1.1, pz + dep * 0.28))])
						detail_items.append([Forge.box(Vector3(0.42, 0.42, 0.42)), Transform3D(Basis(), Vector3(px + w * 0.26, y + h + 1.25, pz + dep * 0.22))])
				else:
					var slope := 0.48
					roof_items.append([Forge.box(Vector3(w + 0.85, 0.18, dep * 0.62)),
							Transform3D(Basis(Vector3.RIGHT, slope), Vector3(px, y + h + 0.22, pz - dep * 0.24))])
					roof_items.append([Forge.box(Vector3(w + 0.85, 0.18, dep * 0.62)),
							Transform3D(Basis(Vector3.RIGHT, -slope), Vector3(px, y + h + 0.22, pz + dep * 0.24))])
					detail_items.append([Forge.box(Vector3(0.55, 1.4, 0.55)), Transform3D(Basis(), Vector3(px + w * 0.24, y + h + 0.9, pz + dep * 0.16))])

				detail_items.append([Forge.box(Vector3(w + 0.4, 0.32, dep + 0.4)),
						Transform3D(Basis(), Vector3(px, y + 0.16, pz))])
				var shop_w := w * 0.66
				for side: float in [-1.0, 1.0]:
					shop_items.append([Forge.box(Vector3(shop_w, 2.25, 0.065)),
							Transform3D(Basis(), Vector3(px, y + 1.25, pz + side * (facade_dep * 0.5 + 0.045)))])
					for pane in range(3):
						trim_items.append([Forge.box(Vector3(0.055, 2.25, 0.08)),
								Transform3D(Basis(), Vector3(px - shop_w * 0.5 + float(pane) * shop_w / 2.0, y + 1.25, pz + side * (facade_dep * 0.5 + 0.075)))])
					trim_items.append([Forge.box(Vector3(shop_w + 0.5, 0.12, 0.62)),
							Transform3D(Basis(), Vector3(px, y + 2.55, pz + side * (facade_dep * 0.5 + 0.28)))])
				detail_items.append([Forge.box(Vector3(1.02, 1.95, 0.075)),
						Transform3D(Basis(), Vector3(px - w * 0.18, y + 1.07, pz + facade_dep * 0.5 + 0.08))])
				var floors := maxi(1, int((h - 1.5) / 3.1))
				var cols_f := maxi(2, int(w / 2.8))
				var cols_s := maxi(2, int(dep / 2.8))
				var pane_w := minf(1.28, w / float(cols_f) * 0.52)
				var pane_d := minf(1.28, dep / float(cols_s) * 0.52)
				var floor_step := 2 if low else 1
				var col_step := 2 if low else 1
				for f in range(0, mini(floors, 18), floor_step):
					var wy := y + 2.15 + float(f) * 3.08
					if wy > y + h - 0.9:
						break
					if city and wy < y + podium_h + 0.7:
						continue
					for c in range(0, cols_f, col_step):
						var wx := px - w * 0.5 + (float(c) + 0.5) * w / float(cols_f)
						for side: float in [-1.0, 1.0]:
							var fz := pz + side * (dep * 0.5 + 0.035)
							if not low:
								trim_items.append([Forge.box(Vector3(pane_w + 0.2, 1.24, 0.035)),
										Transform3D(Basis(), Vector3(wx, wy, fz))])
							var wtarget := window_items if rng.randf() < 0.7 else dark_window_items
							wtarget.append([Forge.box(Vector3(pane_w, 1.0, 0.045)),
									Transform3D(Basis(), Vector3(wx, wy, fz + side * 0.028))])
							if not low:
								trim_items.append([Forge.box(Vector3(pane_w + 0.3, 0.08, 0.15)),
										Transform3D(Basis(), Vector3(wx, wy - 0.62, fz + side * 0.05))])
					for c in range(0, cols_s, col_step):
						var wz := pz - dep * 0.5 + (float(c) + 0.5) * dep / float(cols_s)
						for side: float in [-1.0, 1.0]:
							var fx := px + side * (w * 0.5 + 0.035)
							if not low:
								trim_items.append([Forge.box(Vector3(0.035, 1.24, pane_d + 0.2)),
										Transform3D(Basis(), Vector3(fx, wy, wz))])
							var starget := window_items if rng.randf() < 0.7 else dark_window_items
							starget.append([Forge.box(Vector3(0.045, 1.0, pane_d)),
									Transform3D(Basis(), Vector3(fx + side * 0.028, wy, wz))])
				if city and not low and h < 38.0 and rng.randf() < 0.45:
					for bf in range(2, mini(floors, 7)):
						var by := y + 2.15 + float(bf) * 3.08 - 0.72
						if by < y + podium_h + 0.5:
							continue
						trim_items.append([Forge.box(Vector3(w * 0.38, 0.12, 0.92)),
								Transform3D(Basis(), Vector3(px + w * 0.16, by, pz + dep * 0.5 + 0.42))])
						for rb in range(4):
							trim_items.append([Forge.box(Vector3(0.045, 0.78, 0.045)),
									Transform3D(Basis(), Vector3(px + w * 0.16 - w * 0.17 + float(rb) * w * 0.113, by + 0.45, pz + dep * 0.5 + 0.84))])
				if city and h > 24.0:
					lamp_items.append([Forge.box(Vector3(0.15, 0.9, 0.15)), Transform3D(Basis(), Vector3(px + w * 0.3, y + h + 0.7, pz + dep * 0.3))])
					lamp_items.append([Forge.box(Vector3(0.28, 0.28, 0.28)), Transform3D(Basis(), Vector3(px + w * 0.3, y + h + 1.3, pz + dep * 0.3))])
		if yield_frames:
			await get_tree().process_frame

	for gx in range(-grid, grid + 1):
		for gz in range(-grid, grid + 1):
			if absf(fmod(float(gx), 3.0)) > 0.1 or absf(fmod(float(gz), 3.0)) > 0.1:
				continue
			var px := center.x + float(gx) * block
			var pz := center.z + float(gz) * block
			if Vector2(px - center.x, pz - center.z).length() > radius - 20.0:
				continue
			for side: float in [-1.0, 1.0]:
				lamp_items.append([Forge.cylinder(0.07, 4.6, 8, 0.0, true, true),
						Transform3D(Basis(), Vector3(px + side * (road_w * 0.5 + 1.4), pad_h + 0.05, pz))])
				lamp_items.append([Forge.box(Vector3(0.42, 0.08, 0.42)), Transform3D(Basis(), Vector3(px + side * (road_w * 0.5 + 1.4), pad_h + 4.6, pz))])
				if city and (gx + gz) % 6 == 0:
					var light := OmniLight3D.new()
					light.position = Vector3(px + side * (road_w * 0.5 + 1.4), pad_h + 4.7, pz)
					light.omni_range = 24.0
					light.light_energy = 0.0
					light.light_color = Color(1.0, 0.77, 0.48)
					light.shadow_enabled = false
					add_child(light)
					night_lights.append(light)
		if yield_frames:
			await get_tree().process_frame

	if not walls_items.is_empty():
		print("[settlement] %s walls=%d" %[name, walls_items.size()])
		for i in range(walls.size()):
			var sel: Array = []
			for item: Array in walls_items:
				if item.size() > 2 and item [2] == i:
					sel.append(item)
			var mi := _merged(sel, walls [i], "CityWalls%d" %i)
			if mi != null:
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_add_merged(concrete_items, walk_mat, "CityGround")
	_add_merged(road_items, road_mat, "CityRoads")
	_add_merged(walk_items, walk_mat, "CityWalks")
	_add_merged(grass_items, grass, "CityParks")
	_add_merged(roof_items, roof_mat, "CityRoofs")
	_add_merged(detail_items, Gfx.metal(Color(0.22, 0.23, 0.24), 0.6, 0.4), "CityDetails")
	_add_merged(trim_items, _trim_mat, "CityTrim")
	_add_merged(shop_items, shop_mat, "CityStorefronts")
	_add_merged(mark_items, mark_white, "CityMarkings")
	_add_merged(lamp_items, Gfx.metal(Color(0.28, 0.29, 0.3), 0.5, 0.6), "CityLamps")
	var wmi := _add_merged(window_items, _window_mat, "CityWindows")
	if wmi != null:
		wmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		night_windows.append(wmi)
	var dmi := _add_merged(dark_window_items, window_dark, "CityWindowsDark")
	if dmi != null:
		dmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_sign(center, pad_h, city)


func _merged(items: Array, mat: Material, nm: String) -> GeometryInstance3D:
	if items.is_empty():
		return null
	# Most city detail is axis-aligned boxes. A MultiMesh of a unit cube keeps
	# every window, frame and road marking while avoiding thousands of
	# per-box SurfaceTool merges during world generation.
	var all_boxes := items.size() >= 32
	if all_boxes:
		for item: Array in items:
			var mesh := item[0] as Mesh
			if mesh == null or not mesh.has_meta("box_size"):
				all_boxes = false
				break
	if all_boxes:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		var unit := BoxMesh.new()
		unit.size = Vector3.ONE
		mm.mesh = unit
		mm.instance_count = items.size()
		for i in range(items.size()):
			var item: Array = items[i]
			var size: Vector3 = item[0].get_meta("box_size")
			var xf: Transform3D = item[1]
			mm.set_instance_transform(i, Transform3D(xf.basis * Basis.from_scale(size), xf.origin))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = nm
		mmi.multimesh = mm
		mmi.material_override = mat
		add_child(mmi)
		return mmi
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = Forge.merge_all(items)
	mi.material_override = mat
	add_child(mi)
	return mi


func _add_merged(items: Array, mat: Material, nm: String) -> GeometryInstance3D:
	return _merged(items, mat, nm)


func _add_sign(center: Vector3, pad_h: float, city: bool) -> void:
	var post := MeshInstance3D.new()
	post.mesh = Forge.cylinder(0.22, 7.0, 10, 0.0, true, true)
	post.material_override = Gfx.metal(Color(0.36, 0.38, 0.4), 0.45, 0.7)
	post.position = center + Vector3(-22.0, pad_h + 3.5, 18.0)
	add_child(post)
	var label := Label3D.new()
	label.text = name.replace("Settlement_", "")
	label.font_size = 92
	label.pixel_size = 0.008
	label.modulate = Color(1.0, 0.95, 0.82)
	label.outline_size = 12
	label.outline_modulate = Color(0.04, 0.06, 0.1)
	label.position = center + Vector3(-22.0, pad_h + 7.2, 18.0)
	add_child(label)


func set_night(amount: float) -> void:
	var low := Config.quality <= Config.Quality.LOW
	for l in night_lights:
		if is_instance_valid(l):
			l.visible = not low
			l.light_energy = 0.0 if low else 4.2 * amount
	if _window_mat != null:
		_window_mat.emission_energy_multiplier = 0.03 + (0.55 if low else 1.25) * amount
