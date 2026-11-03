extends Node3D
class_name Railway



var route: Route
var track_root: Node3D
var catenary_root: Node3D
var terrain: Terrain


var stats := {}

const RAIL_PROFILE := [
	Vector2(0.075, 0.0),
	Vector2(0.075, 0.02),
	Vector2(0.022, 0.055),
	Vector2(0.022, 0.122),
	Vector2(0.036, 0.142),
	Vector2(0.036, 0.16),
	Vector2(0.0, 0.176),
	Vector2(-0.036, 0.16),
	Vector2(-0.036, 0.142),
	Vector2(-0.022, 0.122),
	Vector2(-0.022, 0.055),
	Vector2(-0.075, 0.02),
	Vector2(-0.075, 0.0),
]
const BALLAST_PROFILE := [
	Vector2(-3.3, -0.82),
	Vector2(3.3, -0.82),
	Vector2(2.58, -0.24),
	Vector2(-2.58, -0.24),
]
const WIRE_PROFILE := [
	Vector2(-0.014, -0.014),
	Vector2(0.014, -0.014),
	Vector2(0.014, 0.014),
	Vector2(-0.014, 0.014),
]

func setup(p_route: Route) -> void:
	route = p_route



func build_track(step := 4.0, yield_frames := false) -> void:
	if route == null:
		return
	if track_root:
		track_root.queue_free()
	track_root = Node3D.new()
	track_root.name = "Track"
	add_child(track_root)

	var frames := frames_of_route(step)
	var hide := Game.hidden_parts

	if not hide.has("ballast"):
		var ballast_mesh := Forge.loft(BALLAST_PROFILE, frames, true, false)
		var ballast := MeshInstance3D.new()
		ballast.name = "Ballast"
		ballast.mesh = ballast_mesh
		ballast.material_override = Gfx.noise_surface(Color(0.44, 0.42, 0.39), 0.98, 0.6, 0.45)
		ballast.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		track_root.add_child(ballast)


	if not hide.has("rails"):
		var rail_mat := Gfx.metal(Color(0.33, 0.3, 0.28), 0.42, 1.0)
		rail_materials.append(rail_mat)
		for side: float in [-1.0, 1.0]:
			var rail_frames: Array [Transform3D] = []
			for f in frames:
				var xf: Transform3D = f
				xf.origin += xf.basis.x *(side * Config.RAIL_HALF)
				rail_frames.append(xf)
			var rail_mesh := Forge.loft(RAIL_PROFILE, rail_frames, true, false)
			var rail := MeshInstance3D.new()
			rail.name = "Rail%d" %int(side)
			rail.mesh = rail_mesh
			rail.material_override = rail_mat
			track_root.add_child(rail)


	if not hide.has("sleepers"):
		await _build_sleepers(yield_frames)
	stats ["track_frames"] = frames.size()
	stats ["route_length"] = route.total

func _build_sleepers(yield_frames := false) -> void:
	var spacing := Config.SLEEPER_SPACING
	var count := int(route.total / spacing)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var box := BoxMesh.new()
	box.size = Vector3(2.5, 0.16, 0.26)
	mm.mesh = box
	mm.instance_count = count
	for i in range(count):
		var d := float(i) * spacing
		var xf := route.frame_at(d)

		xf.origin += xf.basis.y * -0.255
		mm.set_instance_transform(i, xf)
		if yield_frames and i % 500 == 0:
			await get_tree().process_frame
	var inst := MultiMeshInstance3D.new()
	inst.name = "Sleepers"
	inst.multimesh = mm
	inst.material_override = Gfx.noise_surface(Color(0.4, 0.34, 0.27), 0.95, 0.5, 0.3)
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	track_root.add_child(inst)
	stats ["sleepers"] = count



func build_catenary(spacing := 55.0, yield_frames := false) -> void:
	if route == null:
		return
	if Game.hidden_parts.has("catenary"):
		return
	catenary_root = Node3D.new()
	catenary_root.name = "Catenary"
	add_child(catenary_root)

	var count := int(route.total / spacing)
	var mast_mesh := _catenary_mast_mesh()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mast_mesh
	mm.instance_count = count
	for i in range(count):
		var d := float(i) * spacing
		var xf := route.frame_at(d)

		xf.origin += xf.basis.x * -3.5
		mm.set_instance_transform(i, xf)
		if yield_frames and i % 120 == 0:
			await get_tree().process_frame
	var masts := MultiMeshInstance3D.new()
	masts.name = "Masts"
	masts.multimesh = mm
	masts.material_override = Gfx.metal(Color(0.3, 0.32, 0.33), 0.55, 0.75)
	masts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	catenary_root.add_child(masts)


	var wire_mat := Gfx.metal(Color(0.55, 0.42, 0.28), 0.42, 0.95)
	var frames := frames_of_route(6.0)
	for spec: Dictionary in [{"h": Config.CONTACT_WIRE_H, "name": "ContactWire"}, {"h": Config.CONTACT_WIRE_H + 1.25, "name": "MessengerWire"}]:
		var h: float = spec ["h"]
		var wire_frames: Array [Transform3D] = []
		for f in frames:
			var xf: Transform3D = f
			xf.origin += xf.basis.y * h
			wire_frames.append(xf)
		var mesh := Forge.loft(WIRE_PROFILE, wire_frames, true, false)
		var mi := MeshInstance3D.new()
		mi.name = spec ["name"]
		mi.mesh = mesh
		mi.material_override = wire_mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		catenary_root.add_child(mi)


	var dropper_count := int(route.total / 9.0)
	var dmm := MultiMesh.new()
	dmm.transform_format = MultiMesh.TRANSFORM_3D
	var dbox := BoxMesh.new()
	dbox.size = Vector3(0.02, 1.25, 0.02)
	dmm.mesh = dbox
	dmm.instance_count = dropper_count
	for i in range(dropper_count):
		var d := float(i) * 9.0
		var xf := route.frame_at(d)
		xf.origin += xf.basis.y *(Config.CONTACT_WIRE_H + 0.62)

		xf.origin += xf.basis.x * 0.0
		dmm.set_instance_transform(i, xf)
	var dinst := MultiMeshInstance3D.new()
	dinst.name = "Droppers"
	dinst.multimesh = dmm
	dinst.material_override = wire_mat
	dinst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	catenary_root.add_child(dinst)
	stats ["catenary_masts"] = count
	stats ["droppers"] = dropper_count

func _catenary_mast_mesh() -> ArrayMesh:
	var items := []

	items.append([Forge.cylinder(0.15, 8.6, 12, 0.0, true, true), Transform3D(Basis(), Vector3(0, 0, 0))])

	items.append([Forge.box(Vector3(0.55, 0.3, 0.55)), Transform3D(Basis(), Vector3(0, 0.15, 0))])

	var arm_len := 3.4
	var arm := Forge.cylinder(0.055, arm_len, 8, 0.0, true, true)
	var arm_xf := Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(0.05, 5.9, 0.0))
	items.append([arm, arm_xf])

	var diag := Forge.cylinder(0.04, 3.2, 6, 0.0, true, true)
	var diag_xf := Transform3D(Basis(Vector3.FORWARD, PI * 0.5).rotated(Vector3.FORWARD, -0.55), Vector3(0.1, 4.95, 0.0))
	items.append([diag, diag_xf])

	items.append([Forge.cylinder(0.09, 0.34, 10, 0.0, true, true), Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(3.2, 5.9, 0.0))])
	return Forge.merge_all(items)




func build_siding(sid: Dictionary) -> void:
	if route == null or sid.is_empty() or Game.hidden_parts.has("siding"):
		return
	var d_in: float = float(sid ["in"])
	var d_out: float = float(sid ["out"])
	var root := Node3D.new()
	root.name = "Siding"
	add_child(root)

	var frames: Array [Transform3D] = []
	var d := d_in
	while d <= d_out:
		var xf := route.frame_at(d)
		xf.origin += xf.basis.x * Config.siding_lateral(route, d, sid)
		frames.append(xf)
		d += 3.0
	if frames.size() < 2:
		return


	var bp := PackedVector2Array([
		Vector2(-2.45, -0.8), Vector2(2.45, -0.8), Vector2(1.95, -0.26), Vector2(-1.95, -0.26)
	])
	var ballast := MeshInstance3D.new()
	ballast.name = "SidingBallast"
	ballast.mesh = Forge.loft(bp, frames, true, false)
	ballast.material_override = Gfx.noise_surface(Color(0.42, 0.4, 0.37), 0.98, 0.6, 0.45)
	root.add_child(ballast)


	var rail_mat := Gfx.metal(Color(0.33, 0.3, 0.28), 0.42, 1.0)
	rail_materials.append(rail_mat)
	for side: float in [-1.0, 1.0]:
		var rf: Array [Transform3D] = []
		for f in frames:
			var xf: Transform3D = f
			xf.origin += xf.basis.x *(side * Config.RAIL_HALF)
			rf.append(xf)
		var rail := MeshInstance3D.new()
		rail.name = "SidingRail%d" %int(side)
		rail.mesh = Forge.loft(RAIL_PROFILE, rf, true, false)
		rail.material_override = rail_mat
		root.add_child(rail)


	var spacing := Config.SLEEPER_SPACING
	var count := int((d_out - d_in) / spacing)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var box := BoxMesh.new()
	box.size = Vector3(2.5, 0.16, 0.26)
	mm.mesh = box
	mm.instance_count = count
	for i in range(count):
		var dd := d_in + float(i) * spacing
		var xf := route.frame_at(dd)
		xf.origin += xf.basis.x * Config.siding_lateral(route, dd, sid)
		xf.origin += xf.basis.y * -0.255
		mm.set_instance_transform(i, xf)
	var inst := MultiMeshInstance3D.new()
	inst.name = "SidingSleepers"
	inst.multimesh = mm
	inst.material_override = Gfx.noise_surface(Color(0.4, 0.34, 0.27), 0.95, 0.5, 0.3)
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(inst)


	for t: float in [d_in + 12.0, d_out - 12.0]:
		var f := route.frame_at(t)
		var off := Config.siding_lateral(route, t, sid)
		var pos := f.origin + f.basis.x *(off - signf(off) * 3.1)
		var post := MeshInstance3D.new()
		post.mesh = Forge.cylinder(0.06, 1.6, 8, 0.0, true, true)
		post.material_override = Gfx.metal(Color(0.42, 0.44, 0.46), 0.5, 0.6)
		post.transform = Transform3D(Basis(), pos + Vector3.UP * 0.8)
		root.add_child(post)
		var board := MeshInstance3D.new()
		board.mesh = Forge.box(Vector3(0.62, 0.44, 0.06))
		board.material_override = Gfx.paint(Color(0.88, 0.74, 0.14), 0.55, 0.1, 0.3)
		board.transform = Transform3D(f.basis.orthonormalized(), pos + Vector3.UP * 1.78)
		root.add_child(board)
		var lbl := Label3D.new()
		lbl.text = String(sid.get("sign", "3"))
		lbl.font_size = 120
		lbl.pixel_size = 0.0042
		lbl.modulate = Color(0.1, 0.1, 0.12)
		lbl.transform = Transform3D(f.basis.orthonormalized(), pos + Vector3.UP * 1.78 + f.basis.z * 0.05)
		root.add_child(lbl)
	stats ["siding_frames"] = frames.size()



var rail_materials: Array = []
var signal_root: Node3D
var signals: Array = []


func build_signals(station_stops: Array = []) -> void:
	if route == null or Game.hidden_parts.has("signals"):
		return
	if signal_root:
		signal_root.queue_free()
	signal_root = Node3D.new()
	signal_root.name = "Signals"
	add_child(signal_root)
	signals.clear()
	var d := 90.0
	while d < route.total:
		_add_signal(d, -1.0)
		d += 640.0
	for st in station_stops:
		_add_signal(route.wrap_dist(float(st ["stop"]) - 210.0), -1.0)
	stats ["signals"] = signals.size()

func _add_signal(dist: float, side: float) -> void:
	var xf := route.frame_at(dist)
	var b := xf.basis.orthonormalized()
	var node := Node3D.new()
	node.name = "Signal"
	node.transform = Transform3D(b, xf.origin + b.x *(side * 4.9))
	signal_root.add_child(node)
	var post := MeshInstance3D.new()
	post.mesh = Forge.cylinder(0.085, 5.2, 8, 0.0, true, true)
	post.material_override = Gfx.metal(Color(0.3, 0.31, 0.33), 0.55, 0.65)
	post.position = Vector3(0, 2.6, 0)
	node.add_child(post)
	var head := MeshInstance3D.new()
	head.mesh = Forge.box(Vector3(0.46, 1.46, 0.34))
	head.material_override = Gfx.paint(Color(0.1, 0.11, 0.13), 0.6, 0.2, 0.35)
	head.position = Vector3(0, 5.5, 0)
	node.add_child(head)

	var colors := [Color(0.2, 0.95, 0.35), Color(1.0, 0.8, 0.2), Color(1.0, 0.22, 0.18)]
	var lamps := []
	for i in range(3):
		var lamp := MeshInstance3D.new()
		lamp.mesh = Forge.cylinder(0.155, 0.07, 12, 0.0, true, true)
		lamp.material_override = Gfx.emissive(colors [i], 5.0, colors [i].darkened(0.55))
		lamp.transform = Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 5.94 - float(i) * 0.44, 0.2))
		lamp.visible = i == 0
		node.add_child(lamp)
		lamps.append(lamp)
	signals.append({"dist": dist, "lamps": lamps})

func set_signal_state(index: int, state: int) -> void:
	var lamps: Array = signals [index] ["lamps"]
	for i in range(3):
		(lamps [i] as MeshInstance3D).visible = i == state


func set_wetness(w: float) -> void:
	for m in rail_materials:
		var mat := m as StandardMaterial3D
		if mat == null:
			continue
		mat.roughness = lerpf(0.42, 0.12, clampf(w, 0.0, 1.0))
		mat.metallic = 1.0


func update_signals(train_dist: float, stop_dist: float, require_stop: bool, ai_dist := -1.0, ai_visible := false) -> void:
	if signals.is_empty():
		return
	var to_ai := route.wrap_dist(ai_dist - train_dist) if ai_visible else -1.0
	for i in range(signals.size()):
		var to_sig := route.wrap_dist(float(signals [i] ["dist"]) - train_dist)
		var state := 0
		if ai_visible and to_ai > 0.0 and to_ai < 1800.0 and to_sig < to_ai:
			state = 2 if to_ai < 950.0 else 1
		if require_stop and to_sig <= stop_dist + 60.0 and to_sig < 1500.0:
			if stop_dist < 130.0:
				state = 2
			elif stop_dist < 620.0 and state < 2:
				state = 1
		set_signal_state(i, state)




func frames_of_route(step: float, from := 0.0, to := -1.0) -> Array [Transform3D]:
	var frames: Array [Transform3D] = []
	if route == null:
		return frames
	var end := route.total if to < 0.0 else minf(to, route.total)
	var d := from
	while d <= end:
		frames.append(route.frame_at(d))
		d += step
	if to < 0.0 and frames.size() > 0:
		frames.append(route.frame_at(0.0))
	return frames

func build_tunnels() -> void:
	if route == null or Game.hidden_parts.has("tunnels"):
		return
	var mat := Gfx.noise_surface(Color(0.19, 0.19, 0.2), 0.9, 0.3, 0.3)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var ring_mat := Gfx.noise_surface(Color(0.36, 0.36, 0.35), 0.88, 0.4, 0.3)
	var dark := Gfx.metal(Color(0.12, 0.13, 0.14), 0.6, 0.35)
	var profile := PackedVector2Array([
		Vector2(-3.8, -0.9), Vector2(3.8, -0.9), Vector2(3.8, 1.7),
		Vector2(3.1, 3.5), Vector2(1.9, 4.55), Vector2(0.0, 5.0),
		Vector2(-1.9, 4.55), Vector2(-3.1, 3.5), Vector2(-3.8, 1.7),
	])
	for t: Dictionary in Config.TUNNELS:
		var span := Config.tunnel_span(route, t)
		var a := span.x
		var b := span.y
		var length := route.wrap_dist(b - a)
		if length < 20.0:
			continue
		var frames: Array [Transform3D] = []
		var d := a
		var guard := 0
		while route.wrap_dist(d - a) <= length and guard < 20000:
			frames.append(route.frame_at(d))
			d += 3.0
			guard += 1
		if frames.size() < 2:
			continue
		var tube := MeshInstance3D.new()
		tube.name = "TunnelTube"
		tube.mesh = Forge.loft(profile, frames, true, false)
		tube.material_override = mat
		tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(tube)

		var strip_items := []
		var lum_mat := Gfx.emissive(Color(1.0, 0.78, 0.48), 1.3, Color(0.35, 0.25, 0.12))
		var dd := a + 20.0
		while route.wrap_dist(dd - a) < length - 20.0:
			var xf := route.frame_at(dd)
			for side: float in [-1.0, 1.0]:
				strip_items.append([Forge.box(Vector3(0.08, 0.22, 2.4)), xf * Transform3D(Basis(), Vector3(side * 3.6, 2.8, 0))])
			if int(route.wrap_dist(dd - a) / 90.0) != int(route.wrap_dist(dd - a - 3.0) / 90.0):
				var light := OmniLight3D.new()
				light.position = xf.origin + xf.basis.y * 4.0
				light.omni_range = 22.0
				light.light_energy = 1.8
				light.light_color = Color(1.0, 0.76, 0.48)
				light.shadow_enabled = false
				add_child(light)
			dd += 6.0
		if not strip_items.is_empty():
			var strips := MeshInstance3D.new()
			strips.mesh = Forge.merge_all(strip_items)
			strips.material_override = lum_mat
			strips.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(strips)

		_build_portal(a, profile, ring_mat, dark, String(t.get("name", "隧道")))
		_build_portal(b, profile, ring_mat, dark, String(t.get("name", "隧道")))
		stats ["tunnel_%s" %String(t.get("name", "t"))] = length
func _build_portal(d: float, profile: PackedVector2Array, ring_mat: Material, dark: Material, name_text: String) -> void:
	var xf := route.frame_at(d)
	var items := []
	for i in range(1, profile.size() - 1):
		var p0: Vector2 = profile [i]
		var p1: Vector2 = profile [i + 1]
		var a := xf * Vector3(p0.x, p0.y, 0)
		var b := xf * Vector3(p1.x, p1.y, 0)
		items.append_array(Forge.tube_between(a, b, 0.42, 8, true))
	for side: float in [-1.0, 1.0]:
		items.append([Forge.box(Vector3(1.5, 5.5, 1.4)),
				xf * Transform3D(Basis(), Vector3(side * 4.6, 2.4, 0.55))])
	items.append([Forge.box(Vector3(11.0, 1.6, 1.2)),
			xf * Transform3D(Basis(), Vector3(0.0, 5.75, 0.55))])
	for side: float in [-1.0, 1.0]:
		items.append([Forge.box(Vector3(4.2, 0.6, 5.0)),
				xf * Transform3D(Basis(), Vector3(side * 5.2, 0.6, 2.1))])
	var mi := MeshInstance3D.new()
	mi.name = "TunnelPortal"
	mi.mesh = Forge.merge_all(items)
	mi.material_override = ring_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mi)
	var sign := Label3D.new()
	sign.text = name_text
	sign.font_size = 86
	sign.pixel_size = 0.01
	sign.modulate = Color(1.0, 0.94, 0.8)
	sign.outline_size = 10
	sign.outline_modulate = Color(0.04, 0.05, 0.07)
	sign.transform = xf * Transform3D(Basis(), Vector3(0.0, 5.75, 1.25))
	add_child(sign)


func build_bridges() -> void:
	if route == null or Game.hidden_parts.has("bridges"):
		return
	var deck_mat := Gfx.noise_surface(Color(0.32, 0.32, 0.31), 0.82, 0.35, 0.25)
	var steel := Gfx.metal(Color(0.38, 0.41, 0.43), 0.34, 0.88)
	var concrete := Gfx.noise_surface(Color(0.42, 0.41, 0.39), 0.9, 0.35, 0.25)
	for b: Dictionary in Config.BRIDGES:
		var span := Config.bridge_span(route, b)
		var a := span.x
		var out := span.y
		var length := route.wrap_dist(out - a)
		if length < 20.0:
			continue
		var deck_items := []
		var truss_items := []
		var pier_items := []
		var d := a
		var guard := 0
		while route.wrap_dist(d - a) <= length and guard < 20000:
			var xf := route.frame_at(d)
			deck_items.append([Forge.box(Vector3(4.5, 0.55, 4.3)),
					xf * Transform3D(Basis(), Vector3(0, -0.44, 0))])
			for side: float in [-1.0, 1.0]:
				deck_items.append([Forge.box(Vector3(0.22, 0.42, 4.2)),
						xf * Transform3D(Basis(), Vector3(side * 2.15, 0.1, 0))])
				var p := xf * Vector3(side * 2.35, 1.6, 0)
				var q := xf * Vector3(side * 2.35, 0.1, 0)
				truss_items.append_array(Forge.tube_between(q, p, 0.075, 6))
				if int(guard) % 2 == 0:
					var prev := xf * Vector3(side * 2.35, 1.6, -4.0)
					truss_items.append_array(Forge.tube_between(prev, p, 0.055, 6))
			d += 4.0
			guard += 1
		var deck := MeshInstance3D.new()
		deck.name = "BridgeDeck"
		deck.mesh = Forge.merge_all(deck_items)
		deck.material_override = deck_mat
		deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(deck)
		var truss := MeshInstance3D.new()
		truss.name = "BridgeTruss"
		truss.mesh = Forge.merge_all(truss_items)
		truss.material_override = steel
		add_child(truss)
		var pier_step := 74.0
		var pd := a + 38.0
		while route.wrap_dist(pd - a) < length - 20.0:
			var xf := route.frame_at(pd)
			var g := 0.0
			if terrain != null:
				g = terrain.height_at(xf.origin.x, xf.origin.z)
			var top := xf.origin.y - 0.7
			var h := maxf(2.0, top - g)
			if h > 2.0:
				pier_items.append([Forge.box(Vector3(2.5, h, 3.2)),
						Transform3D(Basis(), Vector3(xf.origin.x, g + h * 0.5, xf.origin.z))])
				pier_items.append([Forge.box(Vector3(3.6, 0.5, 4.2)),
						Transform3D(Basis(), Vector3(xf.origin.x, g + 0.25, xf.origin.z))])
			pd += pier_step
		if not pier_items.is_empty():
			var piers := MeshInstance3D.new()
			piers.name = "BridgePiers"
			piers.mesh = Forge.merge_all(pier_items)
			piers.material_override = concrete
			piers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			add_child(piers)
		stats ["bridge_%s" %String(b.get("name", "b"))] = length


func build_viaducts() -> void:
	if route == null or Game.hidden_parts.has("viaducts"):
		return
	var deck_mat := Gfx.noise_surface(Color(0.46, 0.455, 0.44), 0.88, 0.35, 0.22)
	var barrier_mat := Gfx.noise_surface(Color(0.62, 0.6, 0.56), 0.82, 0.3, 0.2)
	var pier_mat := Gfx.noise_surface(Color(0.4, 0.39, 0.37), 0.9, 0.35, 0.25)
	var steel := Gfx.metal(Color(0.36, 0.39, 0.42), 0.32, 0.86)
	for vi in range(Config.VIADUCTS.size()):
		var vd: Dictionary = Config.VIADUCTS [vi]
		var span := Config.viaduct_span(route, vd)
		var a := span.x
		var out := span.y
		var length := route.wrap_dist(out - a)
		if length < 20.0:
			continue
		var deck_items := []
		var barrier_items := []
		var pier_items := []
		var detail_items := []
		var d := a
		var guard := 0
		while route.wrap_dist(d - a) <= length and guard < 20000:
			var xf := route.frame_at(d)
			deck_items.append([Forge.box(Vector3(5.4, 0.55, 4.25)),
					xf * Transform3D(Basis(), Vector3(0, -0.46, 0))])
			for side: float in [-1.0, 1.0]:
				deck_items.append([Forge.box(Vector3(0.42, 0.72, 4.25)),
						xf * Transform3D(Basis(), Vector3(side * 1.9, -0.92, 0))])
				barrier_items.append([Forge.box(Vector3(0.18, 0.9, 4.2)),
						xf * Transform3D(Basis(), Vector3(side * 2.56, 0.3, 0))])
				detail_items.append([Forge.box(Vector3(0.07, 0.07, 4.2)),
						xf * Transform3D(Basis(), Vector3(side * 2.56, 0.79, 0))])
				if guard % 2 == 0:
					detail_items.append([Forge.box(Vector3(0.1, 0.18, 0.1)),
							xf * Transform3D(Basis(), Vector3(side * 2.56, 0.64, 0))])
			d += 4.0
			guard += 1

		var pier_step := 64.0
		var pd := a + 32.0
		while route.wrap_dist(pd - a) < length - 24.0:
			var xf := route.frame_at(pd)
			var g := xf.origin.y - float(vd.get("height", 22.0))
			if terrain != null:
				g = terrain.height_at(xf.origin.x, xf.origin.z)
			var top := xf.origin.y - 0.92
			var h := maxf(4.0, top - g)
			var lateral := xf.basis.x
			for side: float in [-1.0, 1.0]:
				var p := Vector3(xf.origin.x, g, xf.origin.z) + lateral * (side * 1.62)
				pier_items.append([Forge.box(Vector3(1.15, h, 1.5)),
						Transform3D(Basis(), Vector3(p.x, g + h * 0.5, p.z))])
				pier_items.append([Forge.box(Vector3(1.8, 0.7, 2.0)),
						Transform3D(Basis(), Vector3(p.x, g + 0.35, p.z))])
			pier_items.append([Forge.box(Vector3(5.1, 0.55, 2.1)),
					Transform3D(Basis(), Vector3(xf.origin.x, top, xf.origin.z))])
			if h > 16.0:
				pier_items.append([Forge.box(Vector3(4.0, 0.45, 1.25)),
						Transform3D(Basis(), Vector3(xf.origin.x, g + h * 0.64, xf.origin.z))])
			pd += pier_step

		var deck := MeshInstance3D.new()
		deck.name = "ViaductDeck%d" % vi
		deck.mesh = Forge.merge_all(deck_items)
		deck.material_override = deck_mat
		deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(deck)
		if not barrier_items.is_empty():
			var barriers := MeshInstance3D.new()
			barriers.name = "ViaductBarriers%d" % vi
			barriers.mesh = Forge.merge_all(barrier_items)
			barriers.material_override = barrier_mat
			barriers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(barriers)
		if not detail_items.is_empty():
			var details := MeshInstance3D.new()
			details.name = "ViaductSteel%d" % vi
			details.mesh = Forge.merge_all(detail_items)
			details.material_override = steel
			details.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(details)
		if not pier_items.is_empty():
			var piers := MeshInstance3D.new()
			piers.name = "ViaductPiers%d" % vi
			piers.mesh = Forge.merge_all(pier_items)
			piers.material_override = pier_mat
			piers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			add_child(piers)
		stats ["viaduct_%s" %String(vd.get("name", "v"))] = length
