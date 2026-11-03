extends RefCounted
class_name Vehicles

static var _bogie_templates := {}


const C_BODY_LIGHT := Color(0.845, 0.86, 0.88)
const C_ROOF := Color(0.375, 0.395, 0.415)
const C_DARK := Color(0.135, 0.145, 0.16)
const C_SKIRT := Color(0.18, 0.195, 0.215)
const C_RED := Color(0.69, 0.09, 0.075)
const C_BLUE := Color(0.085, 0.185, 0.5)
const C_YELLOW := Color(0.91, 0.72, 0.11)
const C_RUST := Color(0.33, 0.23, 0.165)
const C_COAL := Color(0.075, 0.07, 0.07)

const LOCO_ENGINES := {
	"standard": {
		"name": "HXD1 标准电传动",
		"desc": "均衡可靠，适合日常重载货运。",
		"traction": 420000.0,
		"speed": 120.0,
		"mass": 138.0,
		"brake": 1.6,
	},
	"heavy": {
		"name": "HXD1H 重载增扭",
		"desc": "起步牵引更强，适合长大货列与坡道。",
		"traction": 520000.0,
		"speed": 100.0,
		"mass": 150.0,
		"brake": 1.75,
	},
	"express": {
		"name": "HXD1G 高速传动",
		"desc": "单机速度更高，适合轻快货运。",
		"traction": 380000.0,
		"speed": 200.0,
		"mass": 132.0,
		"brake": 1.55,
	},
}

const LOCO_SKINS := {
	"classic": {
		"name": "经典蓝白",
		"desc": "HXD1 原厂蓝白涂装",
		"body": Color(0.78, 0.80, 0.84),
		"stripe": Color(0.04, 0.20, 0.62),
		"accent": Color(0.86, 0.62, 0.12),
	},
	"dusk": {
		"name": "暮色橙黑",
		"desc": "Duskrail 主题橙黑涂装",
		"body": Color(0.11, 0.12, 0.14),
		"stripe": Color(0.95, 0.38, 0.10),
		"accent": Color(0.98, 0.72, 0.24),
	},
	"jade": {
		"name": "青碧银线",
		"desc": "青绿车体配银色腰线",
		"body": Color(0.16, 0.33, 0.31),
		"stripe": Color(0.80, 0.88, 0.85),
		"accent": Color(0.91, 0.69, 0.26),
	},
	"heritage": {
		"name": "铁博墨绿",
		"desc": "复古墨绿与暖金饰线",
		"body": Color(0.10, 0.25, 0.17),
		"stripe": Color(0.84, 0.72, 0.22),
		"accent": Color(0.92, 0.88, 0.74),
	},
	"ember": {
		"name": "赤铜晚照",
		"desc": "深赤铜车体配灼金腰线",
		"body": Color(0.30, 0.105, 0.075),
		"stripe": Color(0.92, 0.48, 0.14),
		"accent": Color(0.96, 0.80, 0.50),
	},
	"arctic": {
		"name": "霜蓝银线",
		"desc": "霜蓝车体配深海蓝与银白饰线",
		"body": Color(0.68, 0.77, 0.83),
		"stripe": Color(0.055, 0.20, 0.43),
		"accent": Color(0.78, 0.92, 0.96),
	},
}

const LOCO_TRANSMISSIONS := {
	"balanced": {
		"name": "标准齿轮比",
		"desc": "兼顾起步牵引与线路速度。",
		"traction": 1.0,
		"speed": 1.0,
	},
	"short": {
		"name": "短比重载",
		"desc": "起步更猛，适合坡道和重车。",
		"traction": 1.14,
		"speed": 0.92,
	},
	"long": {
		"name": "长比高速",
		"desc": "极速更高，起步略柔。",
		"traction": 0.92,
		"speed": 1.12,
	},
}

const LOCO_PARTS := {
	"roof_spots": {
		"name": "车顶作业射灯",
		"desc": "车顶双联射灯，照亮前方作业区。",
	},
	"side_lamps": {
		"name": "侧向照地灯",
		"desc": "司机室两侧照地灯，便于夜间检查。",
	},
	"roof_beacon": {
		"name": "车顶警示灯",
		"desc": "橙色旋转警示灯，夜间调车更醒目。",
	},
	"cab_mirrors": {
		"name": "司机室后视镜",
		"desc": "双侧外置后视镜，改善侧向视野。",
	},
	"front_plow": {
		"name": "前部排障板",
		"desc": "强化车头防护与重载视觉效果。",
	},
	"side_skirts": {
		"name": "车体侧裙板",
		"desc": "车头两侧下部装饰裙板，转向架位置留梯形缺口。",
	},
	"roof_horns": {
		"name": "车顶气笛组",
		"desc": "双联黄铜气笛，提升机车细节。",
	},
}

static func clear_bogie_templates() -> void:
	for template in _bogie_templates.values():
		if is_instance_valid(template):
			template.free()
	_bogie_templates.clear()


static func engine_info(id: String) -> Dictionary:
	var d: Dictionary = LOCO_ENGINES.get(id, LOCO_ENGINES["standard"])
	return d

static func skin_info(id: String) -> Dictionary:
	var d: Dictionary = LOCO_SKINS.get(id, LOCO_SKINS["classic"])
	return d

static func transmission_info(id: String) -> Dictionary:
	var d: Dictionary = LOCO_TRANSMISSIONS.get(id, LOCO_TRANSMISSIONS["balanced"])
	return d

static func part_info(id: String) -> Dictionary:
	var d: Dictionary = LOCO_PARTS.get(id, {})
	return d

static func engine_summary(id: String) -> String:
	var e := engine_info(id)
	return "牵引 %.0f kN   ·   最高 %.0f km/h   ·   整备 %.0f t" %[
		float(e["traction"]) / 1000.0, float(e["speed"]), float(e["mass"])
	]

static func transmission_summary(id: String) -> String:
	var t := transmission_info(id)
	return "牵引 %+.0f%%   ·   极速 %+.0f%%" %[
		(float(t["traction"]) - 1.0) * 100.0,
		(float(t["speed"]) - 1.0) * 100.0,
	]

static func _paint(c: Color) -> StandardMaterial3D:
	return Gfx.paint(c, 0.26, 0.5, 0.65)


static func _rounded_rect(w: float, h: float, r: float, segs := 4) -> PackedVector2Array:
	var hw := w * 0.5
	var hh := h * 0.5
	var rr := clampf(r, 0.001, minf(hw, hh) * 0.9)
	var pts := PackedVector2Array()
	var corners := [
		Vector3(hw - rr, hh - rr, 0.0),
		Vector3(- hw + rr, hh - rr, PI * 0.5),
		Vector3(- hw + rr, - hh + rr, PI),
		Vector3(hw - rr, - hh + rr, PI * 1.5),
	]
	for c in corners:
		for i in range(segs + 1):
			var a: float = float(c.z) + PI * 0.5 * float(i) / float(segs)
			pts.append(Vector2(float(c.x) + cos(a) * rr, float(c.y) + sin(a) * rr))
	return pts

static func _panel_mesh(w: float, h: float, r: float, depth: float) -> ArrayMesh:
	return Forge.extrude(_rounded_rect(w, h, r), depth, true, true)

static func _side_xf(side: float, x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, side * PI * 0.5), Vector3(side * x, y, z))

static func _band_profile(hw: float, y0: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(- hw, y0), Vector2(hw, y0), Vector2(hw, y1), Vector2(- hw, y1)
	])



static func electric_loco() -> Vehicle:
	var v := Vehicle.new()
	v.name = "ElectricLoco"
	v.length = 20.0
	v.width = 3.1
	v.height = 3.86
	v.bogie_spacing = 12.4
	v.wheel_radius = 0.5
	v.mass_empty = 138.0
	v.mass_loaded = 138.0
	v.kind = "loco"
	v.designation = "和谐型电力机车"
	v.max_speed = 120.0
	v.brake_force = 1.6

	var body_mat := _paint(C_BODY_LIGHT)
	var stripe_mat := _paint(C_BLUE)
	var accent_mat := _paint(C_YELLOW)
	var mask_mat := _paint(Color(0.215, 0.245, 0.3))
	var roof_mat := Gfx.metal(C_ROOF, 0.52, 0.72)
	var dark_mat := Gfx.metal(C_DARK, 0.62, 0.55)
	var skirt_mat := Gfx.metal(C_SKIRT, 0.6, 0.6)
	var glass_mat := Gfx.glass(Color(0.075, 0.105, 0.14), 0.04, 0.2)
	glass_mat.cull_mode = BaseMaterial3D.CULL_BACK
	var yellow_mat := _paint(C_YELLOW)
	var grille_mat := Gfx.metal(Color(0.2, 0.21, 0.23), 0.7, 0.6)
	var frame_mat := Gfx.metal(Color(0.55, 0.57, 0.6), 0.35, 0.8)
	var win_frame_mat := Gfx.rubber(Color(0.06, 0.06, 0.07), 0.85)

	var half_len := v.length * 0.5 - 0.4
	var floor_y := 1.12
	var roof_y := 3.72


	var prof := PackedVector2Array([
		Vector2(-1.55, floor_y),
		Vector2(1.55, floor_y),
		Vector2(1.55, roof_y - 0.32),
		Vector2(1.4, roof_y - 0.06),
		Vector2(1.1, roof_y + 0.08),
		Vector2(-1.1, roof_y + 0.08),
		Vector2(-1.4, roof_y - 0.06),
		Vector2(-1.55, roof_y - 0.32),
	])
	var shell_cuts := [Vector4(2.56, 3.36, -1000.0, 1000.0)]
	var body_shell_mat := Gfx.cutout_paint(C_BODY_LIGHT, shell_cuts, 0.0, 0.62, 0.2)
	# The front cap is intentionally open so the cab lining sits right behind
	# the windscreen instead of a metre back inside the nose.
	var body_mesh := Forge.extrude(prof, half_len * 2.0, true, false)
	v.part(body_mesh, body_shell_mat, Transform3D(Basis(), Vector3(0, 0, - half_len)), "Carbody")
	var band_mat := Gfx.cutout_paint(C_BODY_LIGHT, [], 0.0, 0.62, 0.2)
	var band_spans := [
		[-half_len, -7.96], [-6.84, -6.46], [-5.34, 5.34], [6.46, 6.84], [7.96, half_len],
	]
	var band_items := []
	for side: float in [-1.0, 1.0]:
		for span: Array in band_spans:
			var za := float(span[0])
			var zb := float(span[1])
			if zb - za < 0.02:
				continue
			band_items.append([Forge.box(Vector3(0.012, 0.80, zb - za)),
					Transform3D(Basis(), Vector3(side * 1.551, 2.96, (za + zb) * 0.5))])
	v.merged(band_items, band_mat, "SideBandPatch")
	v.part(Forge.box(Vector3(3.0, 1.5, 0.08)), Gfx.interior_panel(Color(0.17, 0.19, 0.21), 0.62),
			Transform3D(Basis(), Vector3(0, floor_y + 0.77, - half_len + 0.04)), "CabFrontBulkhead")

	v.part(Forge.box(Vector3(3.115, 0.4, half_len * 2.0 + 0.02)), stripe_mat,
			Transform3D(Basis(), Vector3(0, 2.1, 0)), "Stripe")
	v.part(Forge.box(Vector3(3.118, 0.09, half_len * 2.0 + 0.02)), accent_mat,
			Transform3D(Basis(), Vector3(0, 1.86, 0)), "AccentLine")

	v.part(Forge.box(Vector3(3.1, 0.34, half_len * 2.0)), skirt_mat,
			Transform3D(Basis(), Vector3(0, floor_y + 0.1, 0)), "Skirt")


	var roof_items := []
	roof_items.append([Forge.box(Vector3(2.9, 0.1, half_len * 1.7)), Transform3D(Basis(), Vector3(0, roof_y + 0.12, 0))])
	for z: float in [-6.6, -2.2, 3.0, 6.6]:
		roof_items.append([Forge.box(Vector3(2.28, 0.32, 1.9)), Transform3D(Basis(), Vector3(0, roof_y + 0.33, z))])

	roof_items.append([Forge.box(Vector3(1.05, 0.05, half_len * 1.86)), Transform3D(Basis(), Vector3(0, roof_y + 0.16, 0))])
	for sx: float in [-0.58, 0.58]:
		roof_items.append([Forge.box(Vector3(0.05, 0.26, half_len * 1.86)), Transform3D(Basis(), Vector3(sx, roof_y + 0.31, 0))])
	v.merged(roof_items, roof_mat, "RoofEquipment")


	var cap_items := []
	for z: float in [-8.2, -5.2, -1.0, 1.6, 4.4, 7.9]:
		for sx: float in [-1.05, 1.05]:
			cap_items.append([Forge.cylinder(0.085, 0.3, 8, 0.0, true, true),
					Transform3D(Basis(), Vector3(sx, roof_y + 0.22, z))])
	v.merged(cap_items, Gfx.paint(Color(0.62, 0.6, 0.56), 0.35, 0.15, 0.5), "Insulators")
	var fan_items := []
	for z: float in [-4.2, 1.2]:
		fan_items.append([Forge.cylinder(0.42, 0.16, 14, 0.0, true, true),
				Transform3D(Basis(), Vector3(0, roof_y + 0.24, z))])
	v.merged(fan_items, Gfx.metal(Color(0.3, 0.32, 0.34), 0.5, 0.75), "RoofFans")


	for end: float in [-1.0, 1.0]:
		var z := end *(half_len + 0.02)
		var rot := Basis(Vector3.UP, 0.0 if end < 0 else PI)

		v.part(Forge.box(Vector3(2.98, 1.86, 0.07)), mask_mat, Transform3D(rot, Vector3(0, 2.86, z - end * 0.03)), "CabMask")

		v.part(Forge.box(Vector3(2.98, 0.4, 0.09)), stripe_mat, Transform3D(rot, Vector3(0, 2.1, z - end * 0.01)), "FrontStripe")
		v.part(Forge.box(Vector3(2.98, 0.09, 0.1)), accent_mat, Transform3D(rot, Vector3(0, 1.86, z)), "FrontAccent")

		v.part(Forge.box(Vector3(2.52, 1.04, 0.05)), Gfx.paint(C_BODY_LIGHT.darkened(0.1), 0.4, 0.4, 0.3),
				Transform3D(rot, Vector3(0, 3.1, z - end * 0.02)), "WindshieldFrame")
		v.part(Forge.box(Vector3(2.3, 0.92, 0.1)), glass_mat, Transform3D(rot, Vector3(0, 3.1, z)), "Windshield")
		v.part(Forge.box(Vector3(0.12, 0.98, 0.08)), mask_mat, Transform3D(rot, Vector3(0, 3.1, z + end * 0.04)), "WindshieldPillar")
		v.part(Forge.box(Vector3(2.7, 0.2, 0.06)), yellow_mat, Transform3D(rot, Vector3(0, 2.44, z + end * 0.03)), "FrontWarningBand")
		var wiper_items := []
		for wx: float in [-0.85, 0.85]:
			wiper_items.append([Forge.box(Vector3(0.035, 0.62, 0.022)),
					Transform3D(rot * Basis(Vector3.BACK, 0.38 if wx < 0 else - 0.38), Vector3(wx, 2.86, z + end * 0.085))])
		v.merged(wiper_items, Gfx.rubber(Color(0.03, 0.03, 0.035), 0.85), "Wipers")

		v.part(Forge.box(Vector3(3.02, 0.62, 0.16)), skirt_mat, Transform3D(rot, Vector3(0, 1.45, z + end * 0.05)), "NoseSkirt")
		var plow := Forge.extrude(PackedVector2Array([
			Vector2(-1.5, 0.0), Vector2(1.5, 0.0), Vector2(1.2, 0.55), Vector2(-1.2, 0.55)
		]), 0.22)
		v.part(plow, dark_mat, Transform3D(rot, Vector3(0, 0.3, z + end * 0.08)), "Pilot")

		for lx: float in [-1.12, 1.12]:
			v.part(Forge.box(Vector3(0.42, 0.36, 0.1)), dark_mat,
					Transform3D(rot, Vector3(lx, 2.42, z + end * 0.02)), "LampHousing")
			v.part(Forge.cylinder(0.17, 0.14, 16, 0.0, true, true), Gfx.emissive(Color(1.0, 0.95, 0.82), 10.0, Color(0.95, 0.94, 0.9)),
					Transform3D(Basis(Vector3.BACK, PI * 0.5) * rot, Vector3(lx, 2.42, z + end * 0.09)), "HeadLamp")
		v.part(Forge.cylinder(0.1, 0.1, 12, 0.0, true, true), Gfx.emissive(Color(1.0, 0.35, 0.25), 1.8),
				Transform3D(Basis(Vector3.BACK, PI * 0.5) * rot, Vector3(0, 3.62, z + end * 0.05)), "MarkerLamp")
		v.part(Forge.box(Vector3(2.5, 0.24, 0.1)), dark_mat,
				Transform3D(rot, Vector3(0, 0.98, z + end * 0.1)), "BufferBeam")
		for bx: float in [-0.95, 0.95]:
			v.part(Forge.cylinder(0.17, 0.22, 12, 0.0, true, true), Gfx.metal(Color(0.34, 0.34, 0.36), 0.45, 0.7),
					Transform3D(rot * Basis(Vector3.RIGHT, PI * 0.5 * end), Vector3(bx, 0.98, z + end * 0.08)), "Buffer")


	for side: float in [-1.0, 1.0]:
		var x := side * 1.565
		var rot_side := Basis(Vector3.UP, PI * 0.5 if side > 0 else - PI * 0.5)
		for z: float in [-7.4, -5.9, 5.9, 7.4]:
			var fx := side * 1.565
			for dy: float in [-0.425, 0.425]:
				v.part(Forge.box(Vector3(0.024, 0.07, 1.24)), win_frame_mat,
						Transform3D(Basis(), Vector3(fx, 2.95 + dy, z)), "SideWindowFrame")
			for dz: float in [-0.585, 0.585]:
				v.part(Forge.box(Vector3(0.024, 0.92, 0.07)), win_frame_mat,
						Transform3D(Basis(), Vector3(fx, 2.95, z + dz)), "SideWindowFrame")
			v.part(Forge.box(Vector3(0.018, 0.78, 1.1)), glass_mat,
					Transform3D(Basis(), Vector3(side * 1.578, 2.95, z)), "SideWindow")
			v.part(Forge.box(Vector3(0.03, 0.05, 1.32)), frame_mat,
					Transform3D(Basis(), Vector3(side * 1.585, 2.5, z)), "WindowSill")

		var louvre_panels := []
		var louvre_slats := []
		var louvre_frames := []
		for z: float in [-2.6, 0.0, 2.6]:
			louvre_panels.append([Forge.box(Vector3(2.16, 1.42, 0.045)), Transform3D(rot_side, Vector3(x, 2.95, z))])
			for k in range(7):
				var ly := 2.36 + float(k) * 0.19
				louvre_slats.append([Forge.box(Vector3(2.02, 0.1, 0.07)),
						Transform3D(rot_side, Vector3(x + side * 0.02, ly, z))])
			for fy: float in [-0.76, 0.76]:
				louvre_frames.append([Forge.box(Vector3(2.3, 0.07, 0.07)),
						Transform3D(rot_side, Vector3(x + side * 0.035, 2.95 + fy, z))])
			for fz: float in [-1.12, 1.12]:
				louvre_frames.append([Forge.box(Vector3(0.07, 1.58, 0.07)),
						Transform3D(rot_side, Vector3(x + side * 0.035, 2.95, z + fz))])
		v.merged(louvre_panels, Gfx.paint(C_BODY_LIGHT.darkened(0.14), 0.45, 0.45, 0.35), "LouvrePanels")
		v.merged(louvre_slats, grille_mat, "LouvreSlats")
		v.merged(louvre_frames, frame_mat, "LouvreFrames")

		for end: float in [-1.0, 1.0]:
			var dz := end *(half_len - 0.9)
			v.part(Forge.box(Vector3(0.06, 1.86, 0.86)), dark_mat, Transform3D(rot_side, Vector3(x + side * 0.01, 2.72, dz)), "CabDoor")
			v.part(Forge.box(Vector3(0.07, 0.62, 0.62)), glass_mat, Transform3D(rot_side, Vector3(x + side * 0.02, 3.2, dz)), "CabDoorWindow")
			v.part(Forge.box(Vector3(0.1, 0.05, 0.78)), yellow_mat, Transform3D(rot_side, Vector3(x + side * 0.02, 1.78, dz)), "DoorStepLine")

		var steps := []
		for end: float in [-1.0, 1.0]:
			var sz := end *(half_len - 0.9)
			steps.append([Forge.box(Vector3(0.62, 0.06, 0.55)), Transform3D(Basis(), Vector3(x - side * 0.3, 0.72, sz))])
			steps.append([Forge.box(Vector3(0.62, 0.06, 0.55)), Transform3D(Basis(), Vector3(x - side * 0.3, 1.28, sz))])
		v.merged(steps, dark_mat, "Steps")

		v.part(Forge.box(Vector3(0.03, 0.05, half_len * 2.0)), skirt_mat,
				Transform3D(Basis(), Vector3(side * 1.575, 1.72, 0)), "LineLower")


	var rail_items := []
	for end: float in [-1.0, 1.0]:
		var z := end *(half_len - 0.15)
		for lx: float in [-1.35, 1.35]:
			rail_items.append(Forge.tube_between(Vector3(lx, 1.35, z), Vector3(lx, 3.25, z), 0.024, 10, true))
			rail_items.append(Forge.tube_between(Vector3(lx, 3.25, z), Vector3(lx, 3.25, z - end * 0.5), 0.022, 10, true))

	for side: float in [-1.0, 1.0]:
		var x := side * 1.6
		rail_items.append(Forge.tube_between(Vector3(x, 2.35, - half_len + 0.2), Vector3(x, 2.35, half_len - 0.2), 0.022, 10, true))
	v.merged(rail_items, yellow_mat, "Handrails")


	_coupler(v, - half_len - 0.72, dark_mat)
	_coupler(v, half_len + 0.72, dark_mat)


	_bogie_co(v, - v.bogie_spacing * 0.5, 0.5)
	_bogie_co(v, v.bogie_spacing * 0.5, 0.5)


	var panto := _pantograph(v, Transform3D(Basis(), Vector3(0, roof_y + 0.3, 4.6)))
	v.pantographs.append(panto)
	var panto2 := _pantograph(v, Transform3D(Basis(), Vector3(0, roof_y + 0.3, -4.6)))
	v.pantographs.append(panto2)


	var light_l := SpotLight3D.new()
	light_l.position = Vector3(-1.12, 2.62, - half_len - 0.2)
	light_l.light_color = Color(1.0, 0.96, 0.85)
	light_l.light_energy = 30.0
	light_l.spot_range = 360.0
	light_l.spot_angle = 29.0
	light_l.spot_attenuation = 0.6
	light_l.rotation_degrees = Vector3(-0.6, 0, 0)
	v.attach(light_l)
	v.head_lights.append(light_l)

	var light_r := SpotLight3D.new()
	light_r.position = Vector3(1.12, 2.62, - half_len - 0.2)
	light_r.light_color = Color(1.0, 0.96, 0.85)
	light_r.light_energy = 30.0
	light_r.spot_range = 360.0
	light_r.spot_angle = 29.0
	light_r.spot_attenuation = 0.6
	light_r.rotation_degrees = Vector3(-0.6, 0, 0)
	v.attach(light_r)
	v.head_lights.append(light_r)
	_fill_light(v, Vector3(0.0, 1.9, - half_len - 0.06), Color(1.0, 0.95, 0.84))


	cab_interior(v, 1.16, - half_len + 0.05, - half_len + 4.75, 1.5, -0.72, {}, "electric")
	_mirror_cab_geometry(v)

	return v


static func passenger_coach() -> Vehicle:
	var v := Vehicle.new()
	v.name = "PassengerCoach"
	v.length = 25.5
	v.width = 3.1
	v.height = 4.05
	v.bogie_spacing = 17.5
	v.wheel_radius = 0.4575
	v.mass_empty = 48.0
	v.mass_loaded = 56.0
	v.kind = "coach"
	v.designation = "25T 型客车"
	v.max_speed = 200.0
	v.brake_force = 0.9

	var body_mat := _paint(Color(0.925, 0.935, 0.94))
	var band_mat := _paint(Color(0.045, 0.105, 0.265))
	var red_mat := _paint(Color(0.64, 0.065, 0.05))
	var roof_mat := Gfx.metal(Color(0.47, 0.49, 0.51), 0.5, 0.65)
	var frame_mat := Gfx.metal(Color(0.61, 0.63, 0.65), 0.28, 0.84)
	var dark_mat := Gfx.metal(C_DARK, 0.6, 0.5)
	var glass_mat := Gfx.glass(Color(0.20, 0.28, 0.34), 0.035, 0.28)
	var door_glass := Gfx.glass(Color(0.14, 0.20, 0.26), 0.035, 0.38)
	var skirt_mat := Gfx.metal(C_SKIRT, 0.6, 0.55)

	var half_len := v.length * 0.5 - 0.6
	var floor_y := 1.14
	var roof_y := 3.9

	var prof := PackedVector2Array([
		Vector2(-1.55, floor_y),
		Vector2(1.55, floor_y),
		Vector2(1.55, roof_y - 0.3),
		Vector2(1.38, roof_y - 0.04),
		Vector2(1.05, roof_y + 0.1),
		Vector2(-1.05, roof_y + 0.1),
		Vector2(-1.38, roof_y - 0.04),
		Vector2(-1.55, roof_y - 0.3),
	])
	# Real window and side-door openings. The end caps are replaced by
	# gangway walls so the player can walk through the car.
	var shell_cuts := [
		Vector4(2.60, 3.50, -1000.0, 1000.0),
		Vector4(1.16, 3.48, 1.16, 2.24),
		Vector4(1.16, 3.48, 22.06, 23.14),
	]
	var body_shell_mat := Gfx.cutout_paint(Color(0.925, 0.935, 0.94), shell_cuts,
			0.0, 0.62, 0.2)
	v.part(Forge.extrude(prof, half_len * 2.0, false, false), body_shell_mat,
			Transform3D(Basis(), Vector3(0, 0, - half_len)), "Carbody")

	# 25T 蓝色窗带：上下横带加窗间立柱，恢复原车的连续蓝色带。
	# 所有外饰条必须是薄侧板，不能横穿客舱。
	var side_segments := [Vector2(-half_len, -11.02), Vector2(-9.88, 9.88),
			Vector2(11.02, half_len)]
	var band_posts := []
	for side: float in [-1.0, 1.0]:
		band_posts.append([Forge.box(Vector3(0.025, 0.28, half_len * 2.0 + 0.01)),
				Transform3D(Basis(), Vector3(side * 1.556, 3.64, 0))])
		for seg: Vector2 in side_segments:
			band_posts.append([Forge.box(Vector3(0.025, 0.42, seg.y - seg.x)),
					Transform3D(Basis(), Vector3(side * 1.556, 2.39, (seg.x + seg.y) * 0.5))])
		for pz: float in [-9.765, -7.7, -5.5, -3.3, -1.1, 1.1, 3.3, 5.5, 7.7, 9.765]:
			var pw := 0.29 if absf(pz) > 9.0 else 0.56
			band_posts.append([Forge.box(Vector3(0.022, 1.60, pw)),
					Transform3D(Basis(), Vector3(side * 1.556, 2.98, pz))])
	v.merged(band_posts, band_mat, "WindowBand")
	for side: float in [-1.0, 1.0]:
		for seg: Vector2 in side_segments:
			v.part(Forge.box(Vector3(0.025, 0.06, seg.y - seg.x)), red_mat,
					Transform3D(Basis(), Vector3(side * 1.556, 1.46, (seg.x + seg.y) * 0.5)), "RedWaistline")
		v.part(Forge.box(Vector3(0.03, 0.16, half_len * 2.0)), skirt_mat,
				Transform3D(Basis(), Vector3(side * 1.55, floor_y - 0.06, 0)), "Skirt")

	var coach_hw := v.width * 0.5
	var coach_glass_mesh := _panel_mesh(1.48, 0.78, 0.075, 0.012)
	for side: float in [-1.0, 1.0]:
		var frame_items := []
		var glass_items := []
		var gasket_items := []
		for i in range(9):
			var z := -8.8 + float(i) * 2.2
			# Build a real frame ring instead of a solid filler panel, so
			# the glass really shows the lit interior from outside.
			for fy: float in [-0.47, 0.47]:
				frame_items.append([Forge.box(Vector3(1.64, 0.08, 0.07)),
						_side_xf(side, coach_hw + 0.012, 3.06 + fy, z)])
			for fz: float in [-0.82, 0.82]:
				frame_items.append([Forge.box(Vector3(0.08, 0.94, 0.07)),
						_side_xf(side, coach_hw + 0.012, 3.06, z + fz)])
			glass_items.append([coach_glass_mesh, _side_xf(side, coach_hw + 0.021, 3.06, z)])
			gasket_items.append([Forge.box(Vector3(0.025, 0.03, 1.7)),
					_side_xf(side, coach_hw + 0.022, 2.55, z)])
		v.merged(frame_items, frame_mat, "WindowFrames")
		v.merged(glass_items, glass_mat, "WindowGlass")
		v.merged(gasket_items, frame_mat, "WindowSills")

	# 蓝色塞拉门、镀铬门框、门玻璃、把手和踏梯。门板是独立节点，
	# 停站开门时沿车体侧面向车端滑动。
	var jamb_mat := Gfx.interior_panel(Color(0.74, 0.76, 0.78), 0.55)
	var door_seal_mat := Gfx.rubber(Color(0.035, 0.040, 0.045), 0.85)
	for side: float in [-1.0, 1.0]:
		var rot_side := Basis(Vector3.UP, PI * 0.5 if side > 0 else - PI * 0.5)
		for z: float in [- half_len + 1.7, half_len - 1.7]:
			v.part(Forge.box(Vector3(0.06, 2.3, 0.1)), frame_mat,
					Transform3D(rot_side, Vector3(side * 1.575, 2.33, z - 0.52)), "DoorFrame")
			v.part(Forge.box(Vector3(0.06, 2.3, 0.1)), frame_mat,
					Transform3D(rot_side, Vector3(side * 1.575, 2.33, z + 0.52)), "DoorFrame")
			v.part(Forge.box(Vector3(0.06, 0.05, 1.04)), frame_mat,
					Transform3D(rot_side, Vector3(side * 1.575, 1.2, z)), "DoorSill")
			for sy: float in [0.28, 0.56]:
				v.part(Forge.box(Vector3(0.5, 0.07, 0.22)), dark_mat,
						Transform3D(rot_side, Vector3(side * 1.58, sy, z)), "DoorStep")
			var leaf := Node3D.new()
			leaf.name = "CoachSideDoor"
			leaf.position = Vector3(side * 1.566, 2.33, z)
			leaf.set_meta("door_side", int(side))
			leaf.set_meta("closed_pos", leaf.position)
			leaf.set_meta("open_delta", Vector3.ZERO)
			leaf.set_meta("plug_slide", true)
			leaf.set_meta("slide_out", Vector3(side * 0.055, 0.0, 0.0))
			leaf.set_meta("slide_side", Vector3(0.0, 0.0, 0.98 if z > 0.0 else -0.98))
			v.attach(leaf)
			var panel := MeshInstance3D.new()
			panel.name = "CoachDoorPanel"
			# Build the leaf as a frame around a real opening instead of a
			# solid panel with a dark rectangle pasted on it. The upper door
			# window is therefore see-through from both the saloon and the
			# platform, and the glass shows the opposite side of the coach.
			var door_w := 1.16
			var door_h := 2.36
			var door_t := 0.08
			var win_w := 0.66
			var win_h := 0.58
			var win_cy := 0.52
			var win_y0 := win_cy - win_h * 0.5
			var win_y1 := win_cy + win_h * 0.5
			var stile_w := (door_w - win_w) * 0.5
			var bottom_h := win_y0 + door_h * 0.5
			var top_h := door_h * 0.5 - win_y1
			var panel_items := []
			for sz: float in [-1.0, 1.0]:
				panel_items.append([Forge.box(Vector3(door_t, door_h, stile_w)),
						Transform3D(Basis(), Vector3(0, 0, sz * (win_w * 0.5 + stile_w * 0.5)))])
			panel_items.append([Forge.box(Vector3(door_t, bottom_h, door_w)),
					Transform3D(Basis(), Vector3(0, - door_h * 0.5 + bottom_h * 0.5, 0))])
			panel_items.append([Forge.box(Vector3(door_t, top_h, door_w)),
					Transform3D(Basis(), Vector3(0, door_h * 0.5 - top_h * 0.5, 0))])
			panel.mesh = Forge.merge_all(panel_items)
			panel.material_override = band_mat
			leaf.add_child(panel)
			var door_window := MeshInstance3D.new()
			door_window.name = "CoachDoorGlass"
			door_window.mesh = Forge.box(Vector3(0.018, win_h, win_w))
			door_window.material_override = door_glass
			door_window.position = Vector3(side * 0.006, win_cy, 0.0)
			leaf.add_child(door_window)
			var win_trim := MeshInstance3D.new()
			win_trim.name = "CoachDoorWindowFrame"
			var trim_items := []
			for wy: float in [win_y0 - 0.018, win_y1 + 0.018]:
				trim_items.append([Forge.box(Vector3(0.026, 0.036, win_w + 0.10)), Transform3D(Basis(), Vector3(0, wy, 0))])
			for wz: float in [- win_w * 0.5 - 0.025, win_w * 0.5 + 0.025]:
				trim_items.append([Forge.box(Vector3(0.026, win_h + 0.06, 0.05)), Transform3D(Basis(), Vector3(0, win_cy, wz))])
			win_trim.mesh = Forge.merge_all(trim_items)
			win_trim.material_override = frame_mat
			win_trim.position = Vector3(side * 0.045, 0, 0)
			leaf.add_child(win_trim)
			var door_handle := MeshInstance3D.new()
			door_handle.name = "CoachDoorHandle"
			door_handle.mesh = Forge.box(Vector3(0.03, 0.045, 0.10))
			door_handle.material_override = Gfx.metal(Color(0.7, 0.72, 0.74), 0.3, 0.9)
			door_handle.position = Vector3(side * 0.05, -0.23, 0.32)
			leaf.add_child(door_handle)
			var door_stripe := MeshInstance3D.new()
			door_stripe.name = "CoachDoorStripe"
			door_stripe.mesh = Forge.box(Vector3(0.025, 0.06, 1.02))
			door_stripe.material_override = red_mat
			door_stripe.position = Vector3(side * 0.05, -0.87, 0.0)
			leaf.add_child(door_stripe)
			v.door_leaves.append(leaf)
			# Interior jambs close the 2-3 cm gap between the wall opening
			# and the sliding leaf; without them the outside is visible
			# around a closed door.
			for jz: float in [z - 0.57, z + 0.57]:
				v.part(Forge.box(Vector3(0.12, 2.40, 0.10)), jamb_mat,
						Transform3D(Basis(), Vector3(side * 1.49, 2.33, jz)), "CoachDoorJamb")
				v.part(Forge.box(Vector3(0.06, 2.40, 0.08)), door_seal_mat,
						Transform3D(Basis(), Vector3(side * 1.575, 2.33, jz)), "CoachDoorSeal")
			v.part(Forge.box(Vector3(0.12, 0.10, 1.24)), jamb_mat,
					Transform3D(Basis(), Vector3(side * 1.49, 3.52, z)), "CoachDoorHeader")
			v.part(Forge.box(Vector3(0.12, 0.08, 1.24)), jamb_mat,
					Transform3D(Basis(), Vector3(side * 1.49, 1.19, z)), "CoachDoorSill")
			v.part(Forge.box(Vector3(0.06, 0.08, 1.26)), door_seal_mat,
					Transform3D(Basis(), Vector3(side * 1.575, 3.50, z)), "CoachDoorSealTop")
			v.part(Forge.box(Vector3(0.06, 0.08, 1.26)), door_seal_mat,
					Transform3D(Basis(), Vector3(side * 1.575, 1.18, z)), "CoachDoorSealBottom")
		v.part(Forge.box(Vector3(0.02, 0.12, 0.5)), Gfx.paint(Color(0.12, 0.14, 0.17), 0.5, 0.2, 0.3),
				Transform3D(rot_side, Vector3(side * 1.585, 1.72, - half_len + 1.7)), "NumberPlate")

	var roof_items := []
	roof_items.append([Forge.box(Vector3(2.9, 0.08, half_len * 1.86)),
			Transform3D(Basis(), Vector3(0, roof_y + 0.14, 0))])
	for z: float in [-7.8, -4.2, 4.2, 7.8]:
		roof_items.append([Forge.box(Vector3(1.55, 0.3, 2.0)),
				Transform3D(Basis(), Vector3(0, roof_y + 0.3, z))])
	for z: float in [-9.6, 0.0, 9.6]:
		roof_items.append([Forge.box(Vector3(1.0, 0.1, 1.1)),
				Transform3D(Basis(), Vector3(0, roof_y + 0.22, z))])
	for side: float in [-1.0, 1.0]:
		roof_items.append([Forge.box(Vector3(0.06, 0.05, half_len * 1.9)),
				Transform3D(Basis(), Vector3(side * 1.32, roof_y + 0.16, 0))])
	for rx: float in [-0.72, 0.72]:
		roof_items.append([Forge.box(Vector3(0.035, 0.025, half_len * 1.72)),
				Transform3D(Basis(), Vector3(rx, roof_y + 0.185, 0))])
	v.merged(roof_items, roof_mat, "RoofEquipment")
	for side: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(0.035, 0.05, half_len * 1.9)), frame_mat,
				Transform3D(Basis(), Vector3(side * 1.558, 3.60, 0)), "UpperSideTrim")

	_passenger_interior(v, half_len, floor_y, roof_y, body_mat, frame_mat)
	var lamp_zs := [-8.8, -3.0, 2.6, 8.4]
	if Config.quality <= Config.Quality.LOW:
		lamp_zs = [-3.0, 5.2]
	elif Config.quality == Config.Quality.MEDIUM:
		lamp_zs = [-8.8, -2.2, 5.0]
	for lz: float in lamp_zs:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0, 3.18, lz)
		lamp.omni_range = 7.6
		lamp.light_energy = 0.82
		lamp.light_color = Color(1.0, 0.96, 0.90)
		lamp.shadow_enabled = false
		v.attach(lamp)

	var under_items := []
	# Keep the centre sill above the bolster and all suspended equipment
	# strictly between the two bogie envelopes.
	under_items.append([Forge.box(Vector3(2.2, 0.16, half_len * 1.9)),
			Transform3D(Basis(), Vector3(0, 1.04, 0))])
	for z: float in [-5.9, -1.9, 1.9, 5.9]:
		under_items.append([Forge.box(Vector3(1.95, 0.46, 1.30)),
				Transform3D(Basis(), Vector3(0, 0.82, z))])
		under_items.append([Forge.box(Vector3(0.16, 0.20, 1.34)),
				Transform3D(Basis(), Vector3(0, 1.0, z))])
	under_items.append([Forge.cylinder(0.27, 1.40, 16, - 0.70, true, true),
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.72, 0.72, - 5.6))])
	under_items.append([Forge.cylinder(0.20, 0.70, 14, - 0.35, true, true),
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(- 0.62, 0.68, 5.0))])
	v.merged(under_items, Gfx.metal(Color(0.23, 0.24, 0.26), 0.7, 0.5), "Underframe")

	for end: float in [-1.0, 1.0]:
		_passenger_end(v, end, half_len, floor_y, roof_y, body_mat, frame_mat, band_mat)
	for side: float in [-1.0, 1.0]:
		_car_marking(v, "25T", Vector3(side * 1.585, 1.88, - half_len + 3.6), side,
				Color(0.04, 0.08, 0.18), Color(0.9, 0.9, 0.9))

	_coupler(v, - half_len - 1.05, dark_mat, 0.55)
	_coupler(v, half_len + 1.05, dark_mat, 0.55)
	_bogie_passenger(v, - v.bogie_spacing * 0.5, v.wheel_radius)
	_bogie_passenger(v, v.bogie_spacing * 0.5, v.wheel_radius)
	return v



static func _passenger_interior(v: Vehicle, half_len: float, floor_y: float, roof_y: float,
		body_mat: Material, frame_mat: Material) -> void:
	var floor_mat := Gfx.carpet(Color(0.085, 0.09, 0.10))
	var aisle_mat := Gfx.carpet(Color(0.10, 0.16, 0.27))
	floor_mat.metallic_specular = 0.0
	floor_mat.roughness = 1.0
	aisle_mat.metallic_specular = 0.0
	aisle_mat.roughness = 1.0
	var wall_mat := Gfx.interior_panel(Color(0.74, 0.76, 0.78), 0.55)
	var seat_mat := Gfx.leather(Color(0.16, 0.20, 0.31), 0.48)
	var metal := Gfx.metal(Color(0.45, 0.47, 0.50), 0.40, 0.70)
	var light_mat := Gfx.emissive(Color(1.0, 0.96, 0.88), 0.48, Color(0.62, 0.58, 0.50))
	var span := half_len * 2.0 - 0.5
	v.part(Forge.box(Vector3(2.9, 0.06, span)), floor_mat,
			Transform3D(Basis(), Vector3(0, floor_y + 0.03, 0)), "InteriorFloor")
	v.part(Forge.box(Vector3(1.02, 0.02, span - 0.2)), aisle_mat,
			Transform3D(Basis(), Vector3(0, floor_y + 0.075, 0)), "InteriorAisle")
	v.part(Forge.box(Vector3(2.9, 0.05, span)), Gfx.interior_panel(Color(0.68, 0.70, 0.72), 0.6),
			Transform3D(Basis(), Vector3(0, roof_y - 0.16, 0)), "InteriorCeiling")
	var wall_segments := [Vector2(-half_len - 0.02, -11.02),
			Vector2(-9.88, 9.88), Vector2(11.02, half_len + 0.02)]
	for side: float in [-1.0, 1.0]:
		for wall_seg: Vector2 in wall_segments:
			var wa := wall_seg.x
			var wb := wall_seg.y
			if wb - wa > 0.02:
				# Continuous interior wall from floor to the window sill.
				# The outer shell is single-sided and disappears when viewed
				# from inside, so this panel is what keeps the cabin sealed.
				v.part(Forge.box(Vector3(0.05, 1.42, wb - wa)), wall_mat,
						Transform3D(Basis(), Vector3(side * 1.44, floor_y + 0.75, (wa + wb) * 0.5)), "InteriorWallLower")
		# Window valance above the glazing.
		v.part(Forge.box(Vector3(0.05, 0.24, span - 0.2)), wall_mat,
				Transform3D(Basis(), Vector3(side * 1.44, 3.62, 0)), "InteriorWallTop")
		# Interior pillars between the nine window openings.
		for pz: float in [-9.765, -7.7, -5.5, -3.3, -1.1, 1.1, 3.3, 5.5, 7.7, 9.765]:
			var pw := 0.29 if absf(pz) > 9.0 else 0.56
			v.part(Forge.box(Vector3(0.05, 0.90, pw)), wall_mat,
					Transform3D(Basis(), Vector3(side * 1.44, 3.05, pz)), "InteriorWindowPillar")
		for wz: float in [-8.8, -6.6, -4.4, -2.2, 0.0, 2.2, 4.4, 6.6, 8.8]:
			v.part(Forge.box(Vector3(0.18, 0.05, 1.64)), frame_mat,
					Transform3D(Basis(), Vector3(side * 1.36, 2.60, wz)), "InteriorWindowSill")
		v.part(Forge.box(Vector3(0.30, 0.035, span - 0.4)), metal,
				Transform3D(Basis(), Vector3(side * 1.20, 3.56, 0)), "LuggageRack")

	var seat_items := []
	for i in range(9):
		var z := -8.8 + float(i) * 2.2
		for sx: float in [-1.18, -0.72, 0.72, 1.18]:
			seat_items.append([Forge.box(Vector3(0.44, 0.12, 0.52)),
					Transform3D(Basis(), Vector3(sx, floor_y + 0.43, z))])
			seat_items.append([Forge.box(Vector3(0.42, 0.54, 0.12)),
					Transform3D(Basis(Vector3.RIGHT, deg_to_rad(8.0)), Vector3(sx, floor_y + 0.75, z + 0.27))])
			seat_items.append([Forge.box(Vector3(0.30, 0.17, 0.10)),
					Transform3D(Basis(), Vector3(sx, floor_y + 1.08, z + 0.30))])
			for ax: float in [-0.20, 0.20]:
				seat_items.append([Forge.box(Vector3(0.05, 0.045, 0.42)),
						Transform3D(Basis(), Vector3(sx + ax, floor_y + 0.64, z))])
			for lx: float in [-0.15, 0.15]:
				seat_items.append([Forge.box(Vector3(0.04, 0.30, 0.34)),
						Transform3D(Basis(), Vector3(sx + lx, floor_y + 0.19, z))])
	v.merged(seat_items, seat_mat, "InteriorSeats")

	var light_items := []
	for i in range(9):
		var z := -8.8 + float(i) * 2.2
		for lx: float in [-0.52, 0.52]:
			light_items.append([Forge.box(Vector3(0.20, 0.018, 1.05)),
					Transform3D(Basis(), Vector3(lx, roof_y - 0.198, z))])
	v.merged(light_items, light_mat, "InteriorLights")
	v.set_meta("train_walk", true)
	v.set_meta("train_walk_floor", floor_y + 0.06)
	v.set_meta("train_walk_front", -half_len + 0.10)
	v.set_meta("train_walk_back", half_len - 0.10)
	v.set_meta("train_walk_half", 0.46)


static func _passenger_end(v: Vehicle, end: float, half_len: float, floor_y: float,
		roof_y: float, body_mat: Material, frame_mat: Material, band_mat: Material) -> void:
	var z := end * half_len
	var wall_items := []
	wall_items.append([Forge.box(Vector3(1.00, 2.70, 0.08)),
			Transform3D(Basis(), Vector3(-1.05, 2.54, z))])
	wall_items.append([Forge.box(Vector3(1.00, 2.70, 0.08)),
			Transform3D(Basis(), Vector3(1.05, 2.54, z))])
	wall_items.append([Forge.box(Vector3(1.10, 0.64, 0.08)),
			Transform3D(Basis(), Vector3(0, 3.68, z))])
	wall_items.append([Forge.box(Vector3(1.10, 0.04, 0.08)),
			Transform3D(Basis(), Vector3(0, 1.16, z))])
	v.merged(wall_items, body_mat, "EndWall")
	var rubber := Gfx.rubber(Color(0.045, 0.050, 0.055), 0.82)

	var frame_items := []
	for fx: float in [-0.56, 0.56]:
		frame_items.append([Forge.box(Vector3(0.06, 2.24, 0.10)),
				Transform3D(Basis(), Vector3(fx, 2.28, z + end * 0.04))])
	frame_items.append([Forge.box(Vector3(1.18, 0.06, 0.10)),
			Transform3D(Basis(), Vector3(0, 3.38, z + end * 0.04))])
	v.merged(frame_items, frame_mat, "EndDoorFrame")

	# A real sealed end door. The leaf overlaps the opening on all four
	# sides so the tail of the train no longer shows daylight around it,
	# while the upper window is a genuine opening with transparent glass.
	var door_w := 1.14
	var door_h := 2.28
	var door_t := 0.06
	var win_w := 0.58
	var win_h := 0.56
	var win_cy := 0.48
	var win_y0 := win_cy - win_h * 0.5
	var win_y1 := win_cy + win_h * 0.5
	var stile_w := (door_w - win_w) * 0.5
	var bottom_h := win_y0 + door_h * 0.5
	var top_h := door_h * 0.5 - win_y1
	var door_items := []
	for sx: float in [-1.0, 1.0]:
		door_items.append([Forge.box(Vector3(stile_w, door_h, door_t)),
				Transform3D(Basis(), Vector3(sx * (win_w * 0.5 + stile_w * 0.5), 0, 0))])
	door_items.append([Forge.box(Vector3(door_w, bottom_h, door_t)),
			Transform3D(Basis(), Vector3(0, - door_h * 0.5 + bottom_h * 0.5, 0))])
	door_items.append([Forge.box(Vector3(door_w, top_h, door_t)),
			Transform3D(Basis(), Vector3(0, door_h * 0.5 - top_h * 0.5, 0))])
	var door := MeshInstance3D.new()
	door.name = "EndDoorFront" if end < 0 else "EndDoorRear"
	door.mesh = Forge.merge_all(door_items)
	door.material_override = band_mat
	door.transform = Transform3D(Basis(), Vector3(0, 2.28, z + end * 0.07))
	v.attach(door)
	var win := MeshInstance3D.new()
	win.name = "EndDoorWindow"
	win.mesh = Forge.box(Vector3(win_w, win_h, 0.018))
	win.material_override = Gfx.glass(Color(0.10, 0.16, 0.22), 0.04, 0.28)
	win.position = Vector3(0, win_cy, 0)
	door.add_child(win)
	var win_frame := MeshInstance3D.new()
	win_frame.name = "EndDoorWindowFrame"
	var win_frame_items := []
	for fy: float in [win_y0 - 0.022, win_y1 + 0.022]:
		win_frame_items.append([Forge.box(Vector3(win_w + 0.12, 0.044, door_t + 0.02)),
				Transform3D(Basis(), Vector3(0, fy, 0))])
	for fx: float in [- win_w * 0.5 - 0.03, win_w * 0.5 + 0.03]:
		win_frame_items.append([Forge.box(Vector3(0.06, win_h + 0.08, door_t + 0.02)),
				Transform3D(Basis(), Vector3(fx, win_cy, 0))])
	win_frame.mesh = Forge.merge_all(win_frame_items)
	win_frame.material_override = frame_mat
	door.add_child(win_frame)
	# Rubber seal around the doorway, mounted on the end wall rather than
	# on the moving leaf. It closes the last few millimetres at the tail.
	for sy: float in [1.16, 3.40]:
		v.part(Forge.box(Vector3(1.20, 0.055, 0.055)), rubber,
				Transform3D(Basis(), Vector3(0, sy, z + end * 0.025)), "EndDoorSeal")
	for sx: float in [-0.59, 0.59]:
		v.part(Forge.box(Vector3(0.055, 2.28, 0.055)), rubber,
				Transform3D(Basis(), Vector3(sx, 2.28, z + end * 0.025)), "EndDoorSeal")

	var bellows := []
	# A 0.82 m reach per car closes the coupling gap without poking into
	# the next body. The side and roof sleeves keep the passage dark and
	# solid; the ribs read as the classic concertina gangway.
	for side: float in [-1.0, 1.0]:
		bellows.append([Forge.box(Vector3(0.03, 2.12, 0.80)),
				Transform3D(Basis(), Vector3(side * 0.615, 2.28, z + end * 0.41))])
	bellows.append([Forge.box(Vector3(1.26, 0.03, 0.80)),
			Transform3D(Basis(), Vector3(0, 3.36, z + end * 0.41))])
	bellows.append([Forge.box(Vector3(1.26, 0.03, 0.80)),
			Transform3D(Basis(), Vector3(0, 1.20, z + end * 0.41))])
	for k in range(9):
		var bz := z + end * (0.04 + float(k) * 0.09)
		for side: float in [-1.0, 1.0]:
			bellows.append([Forge.box(Vector3(0.07, 2.18, 0.055)),
					Transform3D(Basis(), Vector3(side * 0.62, 2.28, bz))])
		bellows.append([Forge.box(Vector3(1.34, 0.06, 0.055)),
				Transform3D(Basis(), Vector3(0, 3.38, bz))])
		bellows.append([Forge.box(Vector3(1.34, 0.06, 0.055)),
				Transform3D(Basis(), Vector3(0, 1.18, bz))])
	var gangway := Node3D.new()
	gangway.name = "GangwayFront" if end < 0 else "GangwayRear"
	v.attach(gangway)
	var bellows_mesh := MeshInstance3D.new()
	bellows_mesh.name = "GangwayBellows"
	bellows_mesh.mesh = Forge.merge_all(bellows)
	bellows_mesh.material_override = rubber
	gangway.add_child(bellows_mesh)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "GangwayFloor"
	floor_mesh.mesh = Forge.box(Vector3(1.04, 0.04, 0.86))
	floor_mesh.material_override = Gfx.metal(Color(0.20, 0.21, 0.23), 0.55, 0.45)
	floor_mesh.position = Vector3(0, floor_y + 0.04, z + end * 0.42)
	gangway.add_child(floor_mesh)
	var threshold := MeshInstance3D.new()
	threshold.name = "GangwayThreshold"
	threshold.mesh = Forge.box(Vector3(1.08, 0.05, 0.12))
	threshold.material_override = Gfx.metal(Color(0.42, 0.44, 0.47), 0.35, 0.8)
	threshold.position = Vector3(0, floor_y + 0.055, z + end * 0.05)
	gangway.add_child(threshold)


static func baggage_car(loaded := true) -> Vehicle:
	var v := Vehicle.new()
	v.name = "BaggageCar"
	v.length = 25.5
	v.width = 3.1
	v.height = 4.05
	v.bogie_spacing = 17.5
	v.wheel_radius = 0.4575
	v.mass_empty = 44.0
	v.mass_loaded = 54.0
	v.kind = "baggage"
	v.designation = "XL25T 行李车厢"
	v.max_speed = 160.0
	v.brake_force = 0.9
	v.set_loaded(loaded)

	var body_mat := Gfx.paint(Color(0.095, 0.22, 0.135), 0.46, 0.12, 0.35)
	var door_mat := Gfx.paint(Color(0.075, 0.18, 0.11), 0.48, 0.1, 0.3)
	var yellow := _paint(Color(0.9, 0.72, 0.12))
	var roof_mat := Gfx.metal(Color(0.32, 0.345, 0.35), 0.5, 0.62)
	var frame_mat := Gfx.metal(Color(0.6, 0.62, 0.64), 0.3, 0.8)
	var dark_mat := Gfx.metal(C_DARK, 0.62, 0.48)
	var glass_mat := Gfx.glass(Color(0.04, 0.065, 0.08), 0.05, 0.7)
	var floor_y := 1.14
	var roof_y := 3.9
	var half_len := v.length * 0.5 - 0.6

	var prof := PackedVector2Array([
		Vector2(-1.55, floor_y),
		Vector2(1.55, floor_y),
		Vector2(1.55, roof_y - 0.3),
		Vector2(1.38, roof_y - 0.04),
		Vector2(1.05, roof_y + 0.1),
		Vector2(-1.05, roof_y + 0.1),
		Vector2(-1.38, roof_y - 0.04),
		Vector2(-1.55, roof_y - 0.3),
	])
	v.part(Forge.extrude(prof, half_len * 2.0, false, false), body_mat,
			Transform3D(Basis(), Vector3(0, 0, - half_len)), "Carbody")
	for side: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(0.025, 0.14, half_len * 2.0 + 0.01)), yellow,
				Transform3D(Basis(), Vector3(side * 1.556, 2.52, 0)), "YellowBand")
		v.part(Forge.box(Vector3(0.03, 0.16, half_len * 2.0)), Gfx.metal(C_SKIRT, 0.62, 0.52),
				Transform3D(Basis(), Vector3(side * 1.55, floor_y - 0.06, 0)), "Skirt")

	for side: float in [-1.0, 1.0]:
		var rot_side := Basis(Vector3.UP, PI * 0.5 if side > 0 else - PI * 0.5)
		for z: float in [-6.9, 5.8]:
			v.part(Forge.box(Vector3(2.25, 2.35, 0.075)), door_mat,
					Transform3D(rot_side, Vector3(side * 1.565, 2.33, z)), "BaggageDoor")
			v.part(Forge.box(Vector3(0.07, 2.4, 0.1)), frame_mat,
					Transform3D(rot_side, Vector3(side * 1.575, 2.33, z - 1.14)), "DoorFrame")
			v.part(Forge.box(Vector3(0.07, 2.4, 0.1)), frame_mat,
					Transform3D(rot_side, Vector3(side * 1.575, 2.33, z + 1.14)), "DoorFrame")
			v.part(Forge.box(Vector3(0.06, 0.08, 2.3)), frame_mat,
					Transform3D(rot_side, Vector3(side * 1.575, 3.52, z)), "DoorTrack")
			v.part(Forge.box(Vector3(0.06, 0.08, 2.3)), frame_mat,
					Transform3D(rot_side, Vector3(side * 1.575, 1.16, z)), "DoorTrack")
			v.part(Forge.box(Vector3(2.25, 0.1, 0.08)), yellow,
					Transform3D(rot_side, Vector3(side * 1.57, 2.52, z)), "DoorStripe")
			for dz: float in [-0.55, 0.0, 0.55]:
				v.part(Forge.box(Vector3(0.04, 2.15, 0.06)), frame_mat,
						Transform3D(rot_side, Vector3(side * 1.577, 2.3, z + dz)), "DoorRib")
			v.part(Forge.box(Vector3(0.1, 0.045, 0.03)), Gfx.metal(Color(0.7, 0.72, 0.74), 0.3, 0.9),
					Transform3D(rot_side, Vector3(side * 1.585, 2.2, z + 0.72)), "DoorHandle")
			for sy: float in [0.3, 0.58]:
				v.part(Forge.box(Vector3(0.55, 0.07, 0.22)), dark_mat,
						Transform3D(rot_side, Vector3(side * 1.58, sy, z)), "DoorStep")

		for z: float in [-4.8, -2.6, 0.0, 2.6, 4.8]:
			v.part(Forge.box(Vector3(0.9, 0.34, 0.04)), glass_mat,
					_side_xf(side, 1.57, 3.32, z), "HighWindow")
			v.part(Forge.box(Vector3(1.02, 0.44, 0.06)), frame_mat,
					_side_xf(side, 1.558, 3.32, z), "HighWindowFrame")
		for z: float in [-3.6, 3.6]:
			v.part(Forge.box(Vector3(0.92, 0.72, 0.04)), glass_mat,
					_side_xf(side, 1.57, 3.0, z), "SideWindow")
			v.part(Forge.box(Vector3(1.05, 0.84, 0.06)), frame_mat,
					_side_xf(side, 1.558, 3.0, z), "SideWindowFrame")

	var roof_items := []
	roof_items.append([Forge.box(Vector3(2.9, 0.08, half_len * 1.86)),
			Transform3D(Basis(), Vector3(0, roof_y + 0.14, 0))])
	for z: float in [-7.2, -2.6, 2.6, 7.2]:
		roof_items.append([Forge.box(Vector3(1.7, 0.18, 0.9)),
				Transform3D(Basis(), Vector3(0, roof_y + 0.25, z))])
	v.merged(roof_items, roof_mat, "RoofEquipment")

	var under_items := []
	under_items.append([Forge.box(Vector3(2.2, 0.16, half_len * 1.9)),
			Transform3D(Basis(), Vector3(0, 1.04, 0))])
	for z: float in [-5.9, -1.9, 1.9, 5.9]:
		under_items.append([Forge.box(Vector3(1.95, 0.46, 1.30)),
				Transform3D(Basis(), Vector3(0, 0.82, z))])
		under_items.append([Forge.box(Vector3(0.16, 0.20, 1.34)),
				Transform3D(Basis(), Vector3(0, 1.0, z))])
	under_items.append([Forge.cylinder(0.27, 1.40, 16, - 0.70, true, true),
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.72, 0.72, - 5.6))])
	v.merged(under_items, Gfx.metal(Color(0.23, 0.24, 0.26), 0.7, 0.5), "Underframe")

	_baggage_interior(v, half_len, floor_y, roof_y, frame_mat)
	for end: float in [-1.0, 1.0]:
		_passenger_end(v, end, half_len, floor_y, roof_y, body_mat, frame_mat, door_mat)
	for side: float in [-1.0, 1.0]:
		_car_marking(v, "XL25T", Vector3(side * 1.59, 1.88, -2.0), side,
				Color(0.92, 0.78, 0.22), Color(0.03, 0.06, 0.04))

	_coupler(v, - half_len - 1.05, dark_mat, 0.55)
	_coupler(v, half_len + 1.05, dark_mat, 0.55)
	_bogie_passenger(v, - v.bogie_spacing * 0.5, v.wheel_radius)
	_bogie_passenger(v, v.bogie_spacing * 0.5, v.wheel_radius)
	return v



static func _baggage_interior(v: Vehicle, half_len: float, floor_y: float,
		roof_y: float, frame_mat: Material) -> void:
	var floor_mat := Gfx.carpet(Color(0.08, 0.085, 0.09))
	var aisle_mat := Gfx.carpet(Color(0.15, 0.18, 0.20))
	floor_mat.metallic_specular = 0.0
	aisle_mat.metallic_specular = 0.0
	floor_mat.roughness = 1.0
	aisle_mat.roughness = 1.0
	var wall_mat := Gfx.interior_panel(Color(0.42, 0.47, 0.43), 0.66)
	var cargo_mat := Gfx.paint(Color(0.16, 0.22, 0.18), 0.62, 0.18, 0.25)
	var crate_mat := Gfx.paint(Color(0.23, 0.28, 0.30), 0.64, 0.16, 0.25)
	var light_mat := Gfx.emissive(Color(1.0, 0.96, 0.88), 0.45, Color(0.62, 0.58, 0.50))
	var span := half_len * 2.0 - 0.1
	v.part(Forge.box(Vector3(2.9, 0.06, span)), floor_mat,
			Transform3D(Basis(), Vector3(0, floor_y + 0.03, 0)), "BaggageFloor")
	v.part(Forge.box(Vector3(1.10, 0.02, span - 0.2)), aisle_mat,
			Transform3D(Basis(), Vector3(0, floor_y + 0.075, 0)), "BaggageAisle")
	v.part(Forge.box(Vector3(2.9, 0.05, span)), Gfx.interior_panel(Color(0.56, 0.60, 0.56), 0.7),
			Transform3D(Basis(), Vector3(0, roof_y - 0.16, 0)), "BaggageCeiling")
	for side: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(0.05, 2.55, span)), wall_mat,
				Transform3D(Basis(), Vector3(side * 1.44, floor_y + 1.295, 0)), "BaggageWall")
		# Cargo cages / crates line both sides, leaving a clear centre aisle.
		for cz: float in [-8.4, -5.9, -3.4, -0.9, 1.6, 4.1, 6.6, 9.1]:
			var ch := 1.45 if absf(cz) < 8.0 else 1.25
			v.part(Forge.box(Vector3(0.82, ch, 2.05)), cargo_mat,
					Transform3D(Basis(), Vector3(side * 1.01, floor_y + ch * 0.5 + 0.06, cz)), "BaggageCargo")
			v.part(Forge.box(Vector3(0.74, 0.035, 1.95)), crate_mat,
					Transform3D(Basis(), Vector3(side * 1.01, floor_y + ch + 0.08, cz)), "BaggageCargoLid")
			if absf(cz) < 7.0:
				v.part(Forge.box(Vector3(0.58, 0.42, 1.05)), crate_mat,
						Transform3D(Basis(), Vector3(side * 1.01, floor_y + ch + 0.28, cz - 0.2)), "BaggageCargoTop")
		for lz: float in [-8.8, -6.6, -4.4, -2.2, 0.0, 2.2, 4.4, 6.6, 8.8]:
			v.part(Forge.box(Vector3(0.22, 0.018, 1.05)), light_mat,
					Transform3D(Basis(), Vector3(side * 0.42, roof_y - 0.198, lz)), "BaggageLight")

	for lz: float in [-7.0, 0.0, 7.0]:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0, 3.18, lz)
		lamp.omni_range = 7.0
		lamp.light_energy = 0.70
		lamp.light_color = Color(1.0, 0.96, 0.90)
		lamp.shadow_enabled = false
		v.attach(lamp)
	v.set_meta("train_walk", true)
	v.set_meta("train_walk_floor", floor_y + 0.06)
	v.set_meta("train_walk_front", -half_len + 0.10)
	v.set_meta("train_walk_back", half_len - 0.10)
	v.set_meta("train_walk_half", 0.50)


static func water_tank_wagon(loaded := true) -> Vehicle:
	var v := Vehicle.new()
	v.name = "WaterTankWagon"
	v.length = 12.8
	v.width = 3.0
	v.height = 4.0
	v.bogie_spacing = 8.2
	v.wheel_radius = 0.42
	v.mass_empty = 24.0
	v.mass_loaded = 64.0
	v.kind = "wagon"
	v.designation = "G17 水罐车厢"
	v.max_speed = 100.0
	v.brake_force = 0.85
	v.set_loaded(loaded)

	var frame_mat := Gfx.metal(Color(0.105, 0.11, 0.12), 0.62, 0.45)
	var tank_mat := Gfx.metal(Color(0.66, 0.69, 0.71), 0.32, 0.72)
	var band_dark := Gfx.metal(Color(0.09, 0.095, 0.105), 0.5, 0.5)
	var band_blue := Gfx.metal(Color(0.12, 0.27, 0.48), 0.4, 0.6)
	var steel := Gfx.metal(Color(0.46, 0.48, 0.50), 0.3, 0.82)
	var dark := Gfx.metal(Color(0.10, 0.105, 0.115), 0.62, 0.45)
	var half_len := v.length * 0.5 - 0.55

	# 底架、端平台和鞍座
	v.part(Forge.box(Vector3(2.72, 0.3, half_len * 2.0)), frame_mat,
			Transform3D(Basis(), Vector3(0, 1.0, 0)), "Underframe")
	v.part(Forge.box(Vector3(2.72, 0.12, 1.85)), frame_mat,
			Transform3D(Basis(), Vector3(0, 1.22, - half_len + 0.9)), "EndPlatform")
	v.part(Forge.box(Vector3(2.72, 0.12, 1.85)), frame_mat,
			Transform3D(Basis(), Vector3(0, 1.22, half_len - 0.9)), "EndPlatform")
	for z: float in [-3.45, 3.45]:
		v.part(Forge.box(Vector3(2.5, 0.42, 0.42)), frame_mat,
				Transform3D(Basis(), Vector3(0, 1.18, z)), "TankSaddle")
		for side: float in [-1.0, 1.0]:
			v.part(Forge.box(Vector3(0.16, 0.72, 0.7)), frame_mat,
					Transform3D(Basis(Vector3.UP, side * 0.16), Vector3(side * 1.16, 1.38, z)), "SaddleGusset")

	var tank_prof := PackedVector2Array([
		Vector2(0.0, -5.05),
		Vector2(0.34, -5.0),
		Vector2(0.78, -4.82),
		Vector2(1.12, -4.5),
		Vector2(1.28, -4.05),
		Vector2(1.28, 4.05),
		Vector2(1.12, 4.5),
		Vector2(0.78, 4.82),
		Vector2(0.34, 5.0),
		Vector2(0.0, 5.05),
	])
	v.part(Forge.lathe(tank_prof, 32, true), tank_mat,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 2.3, 0)), "Tank")
	v.part(Forge.cylinder(1.295, 0.16, 32, 0.0, true, true), band_dark,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 2.3, -2.2)), "TankBand")
	v.part(Forge.cylinder(1.295, 0.1, 32, 0.0, true, true), band_blue,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 2.3, 2.1)), "TankBandBlue")

	# 顶部人孔、走台和扶手
	v.part(Forge.cylinder(0.44, 0.28, 18, 0.0, true, true), tank_mat,
			Transform3D(Basis(), Vector3(0, 3.52, 0.55)), "Dome")
	v.part(Forge.cylinder(0.54, 0.08, 18, 0.0, true, true), steel,
			Transform3D(Basis(), Vector3(0, 3.82, 0.55)), "DomeHatch")
	v.part(Forge.box(Vector3(0.62, 0.05, 7.5)), steel,
			Transform3D(Basis(), Vector3(0, 3.78, -0.55)), "Walkway")
	for side: float in [-1.0, 1.0]:
		var x := side * 0.56
		v.part(Forge.box(Vector3(0.04, 0.04, 7.4)), steel,
				Transform3D(Basis(), Vector3(x, 4.22, -0.55)), "TopRail")
		for z: float in [-3.0, -1.5, 0.0, 1.5, 3.0]:
			v.part(Forge.box(Vector3(0.04, 0.44, 0.04)), steel,
					Transform3D(Basis(), Vector3(x, 4.0, z - 0.55)), "TopRailPost")
	for z: float in [-3.9, 3.0]:
		v.part(Forge.cylinder(0.08, 0.4, 10, 0.0, true, true), steel,
				Transform3D(Basis(), Vector3(0.28, 3.68, z)), "TopFitting")
		v.part(Forge.cylinder(0.06, 0.34, 10, 0.0, true, true), steel,
				Transform3D(Basis(), Vector3(-0.3, 3.7, z + 0.25)), "TopPipe")

	# 中央侧梯、端梯和制动轮
	for side: float in [-1.0, 1.0]:
		var x := side * 1.34
		v.part(Forge.box(Vector3(0.06, 2.95, 0.06)), dark,
				Transform3D(Basis(), Vector3(x, 2.45, 0.3)), "LadderRail")
		v.part(Forge.box(Vector3(0.06, 2.95, 0.06)), dark,
				Transform3D(Basis(), Vector3(x, 2.45, 0.9)), "LadderRail")
		for ly: float in [1.15, 1.5, 1.85, 2.2, 2.55, 2.9, 3.25]:
			v.part(Forge.box(Vector3(0.06, 0.045, 0.68)), dark,
					Transform3D(Basis(), Vector3(x, ly, 0.6)), "LadderStep")
	for end: float in [-1.0, 1.0]:
		for lx: float in [-0.3, 0.3]:
			v.part(Forge.box(Vector3(0.04, 1.9, 0.04)), dark,
					Transform3D(Basis(), Vector3(lx, 2.0, end * (half_len + 0.04))), "EndLadderRail")
		for ly: float in [1.2, 1.5, 1.8, 2.1, 2.4, 2.7, 3.0]:
			v.part(Forge.box(Vector3(0.66, 0.035, 0.04)), dark,
					Transform3D(Basis(), Vector3(0, ly, end * (half_len + 0.08))), "EndLadderStep")
		v.part(Forge.box(Vector3(0.05, 1.1, 0.05)), steel,
				Transform3D(Basis(), Vector3(0.58, 1.85, end * (half_len + 0.12))), "EndHandrail")
		v.part(Forge.box(Vector3(0.05, 0.05, 0.85)), steel,
				Transform3D(Basis(), Vector3(0.58, 2.4, end * (half_len + 0.12))), "EndHandrail")
	v.part(Forge.cylinder(0.3, 0.06, 18, 0.0, true, true), dark,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.72, 1.55, half_len + 0.2)), "HandbrakeWheel")
	v.part(Forge.cylinder(0.06, 0.32, 8, 0.0, true, true), steel,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.72, 1.55, half_len + 0.05)), "HandbrakeShaft")

	# 侧架、制动缸和储风筒
	for side: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(0.12, 0.28, 9.2)), frame_mat,
				Transform3D(Basis(), Vector3(side * 1.38, 1.02, 0)), "SideSill")
	v.part(Forge.cylinder(0.2, 0.65, 14, 0.0, true, true), dark,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.55, 0.78, -4.1)), "BrakeCylinder")
	v.part(Forge.cylinder(0.27, 2.2, 16, 0.0, true, true), steel,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.7, 0.78, -1.0)), "AirReservoir")
	v.part(Forge.box(Vector3(0.36, 0.34, 0.7)), Gfx.metal(Color(0.22, 0.23, 0.25), 0.6, 0.5),
			Transform3D(Basis(), Vector3(-0.8, 0.72, 3.6)), "BrakeValve")
	v.part(Forge.box(Vector3(0.9, 0.52, 0.06)), Gfx.paint(Color(0.82, 0.82, 0.78), 0.5, 0.3, 0.4),
			Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(1.5, 1.52, -1.7)), "NumberPlate")
	for side: float in [-1.0, 1.0]:
		_car_marking(v, "G17", Vector3(side * 1.315, 2.25, -1.7), side,
				Color(0.08, 0.1, 0.12), Color(0.88, 0.88, 0.84))

	_coupler(v, - half_len - 0.75, dark, 0.8)
	_coupler(v, half_len + 0.75, dark, 0.8)
	_bogie_k7(v, - v.bogie_spacing * 0.5, v.wheel_radius)
	_bogie_k7(v, v.bogie_spacing * 0.5, v.wheel_radius)
	return v



static func flat_wagon(loaded := true) -> Vehicle:
	var v := Vehicle.new()
	v.name = "FlatWagon"
	v.length = 13.8
	v.width = 3.0
	v.height = 2.3
	v.bogie_spacing = 8.7
	v.wheel_radius = 0.42
	v.mass_empty = 20.0
	v.mass_loaded = 60.0
	v.kind = "wagon"
	v.designation = "NX70 平板车厢"
	v.max_speed = 100.0
	v.brake_force = 0.8
	v.set_loaded(loaded)

	var frame_mat := Gfx.metal(Color(0.20, 0.22, 0.24), 0.58, 0.55)
	var steel := Gfx.metal(Color(0.42, 0.45, 0.48), 0.3, 0.82)
	var wood := Gfx.paint(Color(0.33, 0.235, 0.145), 0.78, 0.15, 0.25)
	var wood_dark := Gfx.paint(Color(0.22, 0.155, 0.095), 0.8, 0.1, 0.2)
	var dark := Gfx.metal(C_DARK, 0.62, 0.45)
	var half_len := v.length * 0.5 - 0.8

	# 钢底架、端梁和侧梁
	v.part(Forge.box(Vector3(2.82, 0.24, half_len * 2.0)), frame_mat,
			Transform3D(Basis(), Vector3(0, 1.04, 0)), "Underframe")
	for side: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(0.14, 0.34, half_len * 2.0)), frame_mat,
				Transform3D(Basis(), Vector3(side * 1.43, 1.07, 0)), "SideSill")
	for end: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(2.9, 0.24, 0.17)), frame_mat,
				Transform3D(Basis(), Vector3(0, 1.04, end * half_len)), "EndBeam")

	# 木地板
	for i in range(7):
		var x := -1.29 + float(i) * 0.43
		v.part(Forge.box(Vector3(0.4, 0.1, half_len * 1.92)), wood if i % 2 == 0 else wood_dark,
				Transform3D(Basis(), Vector3(x, 1.24, 0)), "DeckPlank")

	# 侧柱插、端挡和系固点
	for i in range(7):
		var z := - half_len + 0.85 + float(i) * (half_len * 2.0 - 1.7) / 6.0
		for side: float in [-1.0, 1.0]:
			v.part(Forge.box(Vector3(0.18, 0.42, 0.24)), frame_mat,
					Transform3D(Basis(), Vector3(side * 1.41, 1.25, z)), "StakePocket")
			v.part(Forge.box(Vector3(0.08, 1.0, 0.12)), dark,
					Transform3D(Basis(), Vector3(side * 1.41, 1.9, z)), "StakePost")
	for end: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(2.88, 0.52, 0.12)), frame_mat,
				Transform3D(Basis(), Vector3(0, 1.5, end * (half_len - 0.1))), "EndBulkhead")
		for side: float in [-1.0, 1.0]:
			v.part(Forge.box(Vector3(0.06, 0.44, 0.06)), dark,
					Transform3D(Basis(), Vector3(side * 0.7, 1.9, end * (half_len - 0.05))), "EndPost")

	if loaded:
		for z: float in [-3.45, 0.0, 3.45]:
			v.part(Forge.cylinder(0.72, 2.1, 20, -1.05, true, true), steel,
					Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, 1.98, z)), "SteelCoil")
			for side: float in [-1.0, 1.0]:
				v.part(Forge.cylinder(0.2, 0.04, 18, 0.0, true, true), dark,
						Transform3D(Basis(Vector3.BACK, PI * 0.5),
								Vector3(side * 1.075, 1.98, z)), "CoilEye")
				v.part(Forge.box(Vector3(0.24, 0.42, 1.32)), wood_dark,
						Transform3D(Basis(), Vector3(side * 0.92, 1.52, z)), "CoilChock")
			for side: float in [-1.0, 1.0]:
				v.merged(Forge.tube_between(
						Vector3(side * 0.16, 2.7, z - 0.66),
						Vector3(side * 0.92, 1.46, z - 0.66), 0.012, 5), dark, "CoilChain")
				v.merged(Forge.tube_between(
						Vector3(side * 0.16, 2.7, z + 0.66),
						Vector3(side * 0.92, 1.46, z + 0.66), 0.012, 5), dark, "CoilChain")
		for z: float in [-5.35, 5.35]:
			v.part(Forge.box(Vector3(2.45, 0.4, 1.2)), wood,
					Transform3D(Basis(), Vector3(0, 1.5, z)), "TimberBundle")
			for side: float in [-1.0, 1.0]:
				v.part(Forge.box(Vector3(0.025, 0.05, 1.3)), dark,
						Transform3D(Basis(), Vector3(side * 1.25, 1.75, z)), "TimberStrap")

	# 车钩缓冲、制动和手制动
	v.part(Forge.cylinder(0.2, 0.65, 14, 0.0, true, true), dark,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.55, 0.72, -4.2)), "BrakeCylinder")
	v.part(Forge.cylinder(0.24, 2.2, 16, 0.0, true, true), steel,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.72, 0.7, -0.7)), "AirReservoir")
	v.part(Forge.box(Vector3(0.36, 0.34, 0.62)), frame_mat,
			Transform3D(Basis(), Vector3(-0.8, 0.68, 3.6)), "BrakeValve")
	v.part(Forge.cylinder(0.27, 0.055, 16, 0.0, true, true), dark,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.72, 1.45, half_len + 0.1)), "HandbrakeWheel")
	v.part(Forge.box(Vector3(0.8, 0.22, 0.05)), Gfx.paint(Color(0.78, 0.78, 0.72), 0.5, 0.3, 0.4),
			Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(1.47, 1.32, -2.1)), "NumberPlate")
	for side: float in [-1.0, 1.0]:
		_car_marking(v, "NX70", Vector3(side * 1.53, 1.55, -2.0), side,
				Color(0.92, 0.9, 0.82), Color(0.08, 0.08, 0.07))

	_coupler(v, - half_len - 0.6, dark, 0.75)
	_coupler(v, half_len + 0.6, dark, 0.75)
	_bogie_k6(v, - v.bogie_spacing * 0.5, v.wheel_radius)
	_bogie_k6(v, v.bogie_spacing * 0.5, v.wheel_radius)
	return v



static func gondola_wagon(loaded := true) -> Vehicle:
	var v := Vehicle.new()
	v.name = "GondolaWagon"
	v.length = 13.0
	v.width = 3.1
	v.height = 3.45
	v.bogie_spacing = 8.2
	v.wheel_radius = 0.42
	v.mass_empty = 22.0
	v.mass_loaded = 72.0
	v.kind = "wagon"
	v.designation = "C70 敞车"
	v.max_speed = 100.0
	v.brake_force = 0.85
	v.set_loaded(loaded)

	var body_mat := Gfx.metal(Color(0.43, 0.31, 0.22), 0.78, 0.44)
	var panel_mat := Gfx.metal(Color(0.37, 0.265, 0.185), 0.8, 0.4)
	var rib_mat := Gfx.metal(Color(0.27, 0.19, 0.135), 0.82, 0.38)
	var dark := Gfx.metal(C_DARK, 0.62, 0.45)
	var steel := Gfx.metal(Color(0.45, 0.47, 0.49), 0.3, 0.8)
	var half_len := v.length * 0.5 - 0.65

	# 底架与箱体
	v.part(Forge.box(Vector3(3.0, 0.2, half_len * 2.0)), body_mat,
			Transform3D(Basis(), Vector3(0, 1.18, 0)), "Floor")
	for side: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(0.15, 1.76, half_len * 2.0)), body_mat,
				Transform3D(Basis(), Vector3(side * 1.45, 2.06, 0)), "SideWall")
		v.part(Forge.box(Vector3(0.14, 0.14, half_len * 2.0)), rib_mat,
				Transform3D(Basis(), Vector3(side * 1.52, 2.98, 0)), "TopChord")
		v.part(Forge.box(Vector3(0.12, 0.18, half_len * 2.0)), rib_mat,
				Transform3D(Basis(), Vector3(side * 1.52, 1.25, 0)), "BottomChord")
	for end: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(3.0, 1.76, 0.15)), body_mat,
				Transform3D(Basis(), Vector3(0, 2.06, end * half_len)), "EndWall")
		v.part(Forge.box(Vector3(3.06, 0.14, 0.14)), rib_mat,
				Transform3D(Basis(), Vector3(0, 2.98, end * half_len)), "EndTopChord")
		for side: float in [-1.0, 1.0]:
			v.part(Forge.box(Vector3(0.16, 1.8, 0.2)), rib_mat,
					Transform3D(Basis(), Vector3(side * 1.47, 2.06, end * half_len)), "CornerPost")

	# 每侧 6 块压型下侧门，带门框、铰链和锁扣
	for side: float in [-1.0, 1.0]:
		var x := side * 1.535
		var rot_side := Basis(Vector3.UP, PI * 0.5 if side > 0 else - PI * 0.5)
		for i in range(6):
			var z := - half_len + 1.05 + float(i) * (half_len * 2.0 - 2.1) / 5.0
			v.part(Forge.box(Vector3(1.5, 1.28, 0.055)), panel_mat,
					Transform3D(rot_side, Vector3(x, 1.96, z)), "DropDoor")
			for dz: float in [-0.78, 0.78]:
				v.part(Forge.box(Vector3(0.055, 1.34, 0.09)), rib_mat,
						Transform3D(rot_side, Vector3(x + side * 0.006, 1.96, z + dz)), "DoorFrame")
			for dy: float in [-0.66, 0.66]:
				v.part(Forge.box(Vector3(1.56, 0.06, 0.07)), rib_mat,
						Transform3D(rot_side, Vector3(x + side * 0.006, 1.96 + dy, z)), "DoorFrame")
			v.part(Forge.box(Vector3(0.18, 0.26, 0.08)), dark,
					Transform3D(rot_side, Vector3(x + side * 0.012, 1.96, z)), "DoorLatch")
			for dz: float in [-0.58, 0.58]:
				v.part(Forge.box(Vector3(0.08, 0.14, 0.07)), dark,
						Transform3D(rot_side, Vector3(x + side * 0.01, 1.34, z + dz)), "DoorHinge")
		for i in range(7):
			var z := - half_len + 0.05 + float(i) * (half_len * 2.0 - 0.1) / 6.0
			v.part(Forge.box(Vector3(0.13, 1.68, 0.13)), rib_mat,
					Transform3D(Basis(), Vector3(side * 1.53, 2.06, z)), "SidePost")

	if loaded:
		var coal := Forge.extrude(PackedVector2Array([
			Vector2(-1.38, 2.58), Vector2(1.38, 2.58),
			Vector2(0.95, 2.74), Vector2(0.0, 2.84), Vector2(-0.95, 2.74),
		]), half_len * 2.0 - 0.5)
		v.part(coal, Gfx.noise_surface(C_COAL, 0.95, 0.4, 0.6),
				Transform3D(Basis(), Vector3(0, 0, - half_len + 0.25)), "Coal")
		for i in range(6):
			var lz := - half_len + 2.1 + float(i) * (half_len * 2.0 - 4.2) / 5.0
			var lx := -0.55 if i % 2 == 0 else 0.5
			v.part(Forge.box(Vector3(0.62, 0.12, 0.42)), Gfx.noise_surface(C_COAL, 0.95, 0.4, 0.6),
					Transform3D(Basis(Vector3.UP, float(i) * 0.5), Vector3(lx, 2.89, lz)), "CoalLump")

	# 端梯、端扶手和手制动轮
	for end: float in [-1.0, 1.0]:
		for lx: float in [-0.35, 0.35]:
			v.part(Forge.box(Vector3(0.045, 2.0, 0.05)), dark,
					Transform3D(Basis(), Vector3(lx, 2.0, end * (half_len + 0.12))), "LadderRail")
		for ly: float in [1.2, 1.5, 1.8, 2.1, 2.4, 2.7, 3.0]:
			v.part(Forge.box(Vector3(0.72, 0.035, 0.04)), dark,
					Transform3D(Basis(), Vector3(0, ly, end * (half_len + 0.16))), "LadderStep")
		v.part(Forge.box(Vector3(0.05, 1.1, 0.05)), steel,
				Transform3D(Basis(), Vector3(0.75, 2.15, end * (half_len + 0.1))), "EndHandrail")
		v.part(Forge.box(Vector3(0.05, 0.05, 0.95)), steel,
				Transform3D(Basis(), Vector3(0.75, 2.7, end * (half_len + 0.1))), "EndHandrail")
	v.part(Forge.cylinder(0.3, 0.06, 18, 0.0, true, true), dark,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.78, 1.5, half_len + 0.22)), "HandbrakeWheel")

	# 底架制动设备
	v.part(Forge.box(Vector3(2.6, 0.22, 8.4)), Gfx.metal(Color(0.24, 0.25, 0.26), 0.65, 0.45),
			Transform3D(Basis(), Vector3(0, 0.94, 0)), "BrakeBeam")
	v.part(Forge.cylinder(0.2, 0.65, 14, 0.0, true, true), dark,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.6, 0.76, -3.8)), "BrakeCylinder")
	v.part(Forge.cylinder(0.24, 2.2, 16, 0.0, true, true), steel,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.7, 0.74, -0.5)), "AirReservoir")
	v.part(Forge.box(Vector3(0.85, 0.24, 0.05)), Gfx.paint(Color(0.8, 0.8, 0.75), 0.5, 0.3, 0.4),
			Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(1.54, 1.42, -1.8)), "NumberPlate")
	for side: float in [-1.0, 1.0]:
		_car_marking(v, "C70", Vector3(side * 1.6, 2.18, -4.0), side,
				Color(0.9, 0.86, 0.76), Color(0.12, 0.08, 0.05))

	_coupler(v, - half_len - 0.75, dark, 0.8)
	_coupler(v, half_len + 0.75, dark, 0.8)
	_bogie_k7(v, - v.bogie_spacing * 0.5, v.wheel_radius)
	_bogie_k7(v, v.bogie_spacing * 0.5, v.wheel_radius)
	return v



static func reefer_wagon(loaded := true) -> Vehicle:
	var v := Vehicle.new()
	v.name = "ReeferWagon"
	v.length = 15.0
	v.width = 3.05
	v.height = 4.0
	v.bogie_spacing = 9.5
	v.wheel_radius = 0.42
	v.mass_empty = 28.0
	v.mass_loaded = 58.0
	v.kind = "wagon"
	v.designation = "B23 机械冷藏车厢"
	v.max_speed = 120.0
	v.brake_force = 0.85
	v.set_loaded(loaded)

	var body_mat := _paint(Color(0.84, 0.855, 0.85))
	var rib_mat := _paint(Color(0.70, 0.73, 0.74))
	var door_mat := _paint(Color(0.76, 0.79, 0.80))
	var roof_mat := Gfx.metal(Color(0.42, 0.45, 0.47), 0.5, 0.6)
	var frame_mat := Gfx.metal(Color(0.28, 0.30, 0.32), 0.55, 0.6)
	var dark := Gfx.metal(C_DARK, 0.62, 0.48)
	var unit_mat := Gfx.metal(Color(0.22, 0.24, 0.26), 0.5, 0.55)
	var glass := Gfx.glass(Color(0.05, 0.08, 0.10), 0.05, 0.7)
	var half_len := v.length * 0.5 - 0.8
	var roof_y := 3.55
	var floor_y := 1.12

	var prof := PackedVector2Array([
		Vector2(-1.52, floor_y),
		Vector2(1.52, floor_y),
		Vector2(1.52, roof_y - 0.22),
		Vector2(1.4, roof_y),
		Vector2(1.08, roof_y + 0.1),
		Vector2(-1.08, roof_y + 0.1),
		Vector2(-1.4, roof_y),
		Vector2(-1.52, roof_y - 0.22),
	])
	v.part(Forge.extrude(prof, half_len * 2.0, true, true), body_mat,
			Transform3D(Basis(), Vector3(0, 0, - half_len)), "Carbody")
	v.part(Forge.box(Vector3(3.07, 0.18, half_len * 2.0 + 0.02)), rib_mat,
			Transform3D(Basis(), Vector3(0, 1.5, 0)), "LowerBand")
	v.part(Forge.box(Vector3(3.0, 0.25, half_len * 2.0)), Gfx.metal(C_SKIRT, 0.62, 0.52),
			Transform3D(Basis(), Vector3(0, floor_y + 0.07, 0)), "Skirt")

	# 水平压筋（B23 冷藏车最显著的特征）
	for side: float in [-1.0, 1.0]:
		var ribs := []
		for i in range(15):
			var y := 1.35 + float(i) * 0.155
			ribs.append([Forge.box(Vector3(0.035, 0.028, half_len * 1.92)),
					Transform3D(Basis(), Vector3(side * 1.545, y, 0))])
		v.merged(ribs, rib_mat, "SideCorrugation")
		var rot_side := Basis(Vector3.UP, PI * 0.5 if side > 0 else - PI * 0.5)
		for z: float in [-3.8, 3.8]:
			v.part(Forge.box(Vector3(2.35, 2.28, 0.07)), door_mat,
					Transform3D(rot_side, Vector3(side * 1.56, 2.32, z)), "PlugDoor")
			v.part(Forge.box(Vector3(0.07, 2.32, 0.1)), frame_mat,
					Transform3D(rot_side, Vector3(side * 1.57, 2.32, z - 1.18)), "DoorFrame")
			v.part(Forge.box(Vector3(0.07, 2.32, 0.1)), frame_mat,
					Transform3D(rot_side, Vector3(side * 1.57, 2.32, z + 1.18)), "DoorFrame")
			v.part(Forge.box(Vector3(2.28, 0.07, 0.1)), frame_mat,
					Transform3D(rot_side, Vector3(side * 1.57, 3.48, z)), "DoorFrame")
			v.part(Forge.box(Vector3(2.28, 0.07, 0.1)), frame_mat,
					Transform3D(rot_side, Vector3(side * 1.57, 1.16, z)), "DoorFrame")
			for dz: float in [-0.62, 0.0, 0.62]:
				v.part(Forge.box(Vector3(0.035, 2.12, 0.05)), rib_mat,
						Transform3D(rot_side, Vector3(side * 1.575, 2.3, z + dz)), "DoorRib")
			v.part(Forge.box(Vector3(0.12, 0.055, 0.035)), Gfx.metal(Color(0.72, 0.74, 0.76), 0.3, 0.9),
					Transform3D(rot_side, Vector3(side * 1.585, 2.15, z + 0.78)), "DoorHandle")
			for sy: float in [0.3, 0.58]:
				v.part(Forge.box(Vector3(0.55, 0.07, 0.22)), dark,
						Transform3D(rot_side, Vector3(side * 1.58, sy, z)), "DoorStep")
		v.part(Forge.box(Vector3(0.9, 0.24, 0.05)), Gfx.paint(Color(0.12, 0.23, 0.38), 0.5, 0.3, 0.4),
				Transform3D(rot_side, Vector3(side * 1.58, 1.72, - half_len + 1.55)), "NumberPlate")

	# 端部制冷机组、风扇和管路
	var unit := []
	unit.append([Forge.box(Vector3(1.75, 1.5, 0.85)),
			Transform3D(Basis(), Vector3(0, 2.98, - half_len - 0.22))])
	for i in range(7):
		unit.append([Forge.box(Vector3(1.35, 0.055, 0.06)),
				Transform3D(Basis(), Vector3(0, 2.45 + float(i) * 0.16, - half_len - 0.67))])
	unit.append([Forge.box(Vector3(1.9, 0.1, 0.9)),
			Transform3D(Basis(), Vector3(0, 3.75, - half_len - 0.2))])
	v.merged(unit, unit_mat, "ReeferUnit")
	v.part(Forge.cylinder(0.35, 0.08, 20, 0.0, true, true), dark,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 3.0, - half_len - 0.69)), "ReeferFan")
	v.part(Forge.cylinder(0.045, 0.8, 8, 0.0, true, true), frame_mat,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.45, 1.4, - half_len - 0.3)), "FuelLine")

	var roof := []
	roof.append([Forge.box(Vector3(2.8, 0.08, half_len * 1.85)),
			Transform3D(Basis(), Vector3(0, roof_y + 0.14, 0))])
	for z: float in [-4.8, 0.0, 4.8]:
		roof.append([Forge.box(Vector3(1.2, 0.16, 1.0)),
				Transform3D(Basis(), Vector3(0, roof_y + 0.25, z))])
	v.merged(roof, roof_mat, "RoofHatches")

	var under := []
	for z: float in [-5.2, -1.8, 2.0, 5.4]:
		under.append([Forge.box(Vector3(2.05, 0.55, 1.4)),
				Transform3D(Basis(), Vector3(0, 0.76, z))])
	under.append([Forge.cylinder(0.32, 2.4, 16, 0.0, true, true),
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.78, 0.72, 3.2))])
	under.append([Forge.cylinder(0.24, 2.0, 14, 0.0, true, true),
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.78, 0.7, -3.0))])
	v.merged(under, Gfx.metal(Color(0.23, 0.24, 0.26), 0.7, 0.5), "Underframe")

	for end: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(1.6, 2.15, 0.4)), dark,
				Transform3D(Basis(), Vector3(0, 2.2, end *(half_len + 0.2))), "EndFrame")
		for side: float in [-1.0, 1.0]:
			v.part(Forge.box(Vector3(0.05, 1.9, 0.05)), frame_mat,
					Transform3D(Basis(), Vector3(side * 0.72, 2.15, end *(half_len + 0.42))), "EndHandrail")
			v.part(Forge.box(Vector3(0.05, 0.05, 0.7)), frame_mat,
					Transform3D(Basis(), Vector3(side * 0.72, 2.65, end *(half_len + 0.3))), "EndHandrail")
			for ly: float in [1.25, 1.55, 1.85, 2.15]:
				v.part(Forge.box(Vector3(0.08, 0.035, 0.24)), dark,
						Transform3D(Basis(), Vector3(side * 0.56, ly, end *(half_len + 0.42))), "EndStep")
	for side: float in [-1.0, 1.0]:
		_car_marking(v, "B23", Vector3(side * 1.6, 2.0, -1.5), side,
				Color(0.08, 0.16, 0.28), Color(0.92, 0.92, 0.9))

	_coupler(v, - half_len - 1.0, dark, 0.6)
	_coupler(v, half_len + 1.0, dark, 0.6)
	_bogie_k6(v, - v.bogie_spacing * 0.5, v.wheel_radius)
	_bogie_k6(v, v.bogie_spacing * 0.5, v.wheel_radius)
	return v



static func container_wagon(with_load := true) -> Vehicle:
	var v := Vehicle.new()
	v.name = "ContainerWagon"
	v.length = 13.8
	v.width = 3.05
	v.height = 3.5
	v.bogie_spacing = 8.7
	v.wheel_radius = 0.42
	v.mass_empty = 20.0
	v.mass_loaded = 76.0
	v.kind = "wagon"
	v.designation = "X6K 集装箱平车"
	v.max_speed = 120.0
	v.brake_force = 0.8
	v.set_loaded(with_load)

	var frame_mat := Gfx.metal(Color(0.22, 0.23, 0.25), 0.6, 0.55)
	var deck_mat := Gfx.metal(Color(0.28, 0.24, 0.20), 0.75, 0.45)
	var steel := Gfx.metal(Color(0.44, 0.46, 0.48), 0.3, 0.82)
	var dark := Gfx.metal(C_DARK, 0.62, 0.45)
	var half_len := v.length * 0.5 - 0.8

	# 低矮平车底架
	v.part(Forge.box(Vector3(2.8, 0.22, half_len * 2.0)), deck_mat,
			Transform3D(Basis(), Vector3(0, 1.08, 0)), "Deck")
	for side: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(0.14, 0.32, half_len * 2.0)), frame_mat,
				Transform3D(Basis(), Vector3(side * 1.45, 1.02, 0)), "SideSill")
	for end: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(2.9, 0.22, 0.16)), frame_mat,
				Transform3D(Basis(), Vector3(0, 1.02, end * half_len)), "EndBeam")
		v.part(Forge.box(Vector3(2.7, 0.1, 0.85)), frame_mat,
				Transform3D(Basis(), Vector3(0, 1.18, end * (half_len - 0.5))), "EndPlatform")
	for z: float in [-4.0, -1.35, 1.35, 4.0]:
		v.part(Forge.box(Vector3(2.6, 0.1, 0.16)), frame_mat,
				Transform3D(Basis(), Vector3(0, 1.06, z)), "CrossBearer")

	# 集装箱固定锁、导板和端部挡
	for z: float in [-6.0, -0.1, 0.1, 6.0]:
		for side: float in [-1.0, 1.0]:
			v.part(Forge.box(Vector3(0.22, 0.13, 0.24)), dark,
					Transform3D(Basis(), Vector3(side * 1.06, 1.23, z)), "TwistLock")
			v.part(Forge.box(Vector3(0.12, 0.26, 0.16)), frame_mat,
					Transform3D(Basis(), Vector3(side * 1.12, 1.2, z)), "ContainerGuide")
	for end: float in [-1.0, 1.0]:
		for side: float in [-1.0, 1.0]:
			v.part(Forge.box(Vector3(0.07, 0.04, 0.85)), steel,
					Transform3D(Basis(), Vector3(side * 1.0, 2.75, end * (half_len - 0.2))), "EndHandrail")
			v.part(Forge.box(Vector3(0.05, 0.95, 0.05)), steel,
					Transform3D(Basis(), Vector3(side * 1.0, 2.3, end * (half_len - 0.2))), "EndHandrailPost")

	if with_load:
		for i in range(2):
			var z := -3.1 + float(i) * 6.2
			_container(v, Transform3D(Basis(), Vector3(0, 1.2, z)),
					Color(0.1, 0.3, 0.6) if i == 0 else Color(0.62, 0.16, 0.12))
		for z: float in [-3.1, 3.1]:
			for side: float in [-1.0, 1.0]:
				v.part(Forge.box(Vector3(0.04, 0.1, 5.8)), steel,
						Transform3D(Basis(), Vector3(side * 1.53, 1.55, z)), "ContainerSill")

	# 制动设备、手制动和侧面标牌
	v.part(Forge.cylinder(0.2, 0.65, 14, 0.0, true, true), dark,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.55, 0.72, -4.0)), "BrakeCylinder")
	v.part(Forge.cylinder(0.24, 2.2, 16, 0.0, true, true), steel,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.72, 0.7, -0.6)), "AirReservoir")
	v.part(Forge.box(Vector3(0.36, 0.34, 0.62)), frame_mat,
			Transform3D(Basis(), Vector3(-0.8, 0.68, 3.5)), "BrakeValve")
	v.part(Forge.cylinder(0.27, 0.055, 16, 0.0, true, true), dark,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.72, 1.45, half_len + 0.1)), "HandbrakeWheel")
	v.part(Forge.box(Vector3(1.1, 0.28, 0.05)), Gfx.paint(Color(0.78, 0.78, 0.74), 0.5, 0.3, 0.4),
			Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(1.47, 1.0, -1.8)), "NumberPlate")
	for side: float in [-1.0, 1.0]:
		_car_marking(v, "X6K", Vector3(side * 1.54, 1.2, -2.6), side,
				Color(0.92, 0.9, 0.82), Color(0.08, 0.08, 0.07))

	_coupler(v, - half_len - 0.6, dark, 0.75)
	_coupler(v, half_len + 0.6, dark, 0.75)
	_bogie_k6(v, - v.bogie_spacing * 0.5, v.wheel_radius)
	_bogie_k6(v, v.bogie_spacing * 0.5, v.wheel_radius)
	return v



static func _container(v: Vehicle, xf: Transform3D, color: Color) -> void:
	var w := 2.44
	var h := 2.59
	var l := 6.06
	var mat := Gfx.paint(color, 0.45, 0.3, 0.25)
	var rib_mat := Gfx.paint(color.darkened(0.08), 0.5, 0.3, 0.2)
	var trim_mat := Gfx.paint(color.darkened(0.32), 0.5, 0.35, 0.25)
	var door_mat := Gfx.metal(color.darkened(0.22), 0.5, 0.55)

	v.part(Forge.box(Vector3(w, h, l)), mat, xf * Transform3D(Basis(), Vector3(0, h * 0.5, 0)), "Container")

	var parts := []

	var n := 20
	for i in range(n):
		var z := - l * 0.5 + 0.22 + float(i) *(l - 0.44) / float(n - 1)
		for side: float in [-1.0, 1.0]:
			parts.append([Forge.box(Vector3(0.035, h - 0.26, 0.055)),
					xf * Transform3D(Basis(), Vector3(side *(w * 0.5 - 0.005), h * 0.5, z))])

	for y: float in [0.07, h - 0.09]:
		for side: float in [-1.0, 1.0]:
			parts.append([Forge.box(Vector3(0.06, 0.11, l - 0.1)),
					xf * Transform3D(Basis(), Vector3(side *(w * 0.5 - 0.01), y, 0))])
			parts.append([Forge.box(Vector3(w - 0.1, 0.11, 0.06)),
					xf * Transform3D(Basis(), Vector3(0, y, side *(l * 0.5 - 0.01)))])

	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			parts.append([Forge.box(Vector3(0.13, h - 0.05, 0.13)),
					xf * Transform3D(Basis(), Vector3(sx *(w * 0.5 - 0.045), h * 0.5, sz *(l * 0.5 - 0.045)))])
	v.merged(parts, rib_mat, "ContainerRibs")

	var castings := []
	for sx: float in [-1.0, 1.0]:
		for sy: float in [0.08, h - 0.08]:
			for sz: float in [-1.0, 1.0]:
				castings.append([Forge.box(Vector3(0.18, 0.18, 0.18)),
						xf * Transform3D(Basis(), Vector3(sx *(w * 0.5 - 0.02), sy, sz *(l * 0.5 - 0.02)))])
	v.merged(castings, trim_mat, "ContainerCastings")

	var doors := []
	for sz: float in [-1.0, 1.0]:
		for dx: float in [-0.56, 0.56]:
			doors.append([Forge.box(Vector3(1.02, h - 0.34, 0.05)),
					xf * Transform3D(Basis(), Vector3(dx, h * 0.5, sz *(l * 0.5 + 0.02)))])
			for lx: float in [-0.38, 0.38]:
				doors.append([Forge.box(Vector3(0.045, h - 0.44, 0.07)),
						xf * Transform3D(Basis(), Vector3(dx + lx, h * 0.5, sz *(l * 0.5 + 0.05)))])
			doors.append([Forge.box(Vector3(0.95, 0.06, 0.07)),
					xf * Transform3D(Basis(), Vector3(dx, h * 0.5 + 0.35, sz *(l * 0.5 + 0.055)))])
	v.merged(doors, door_mat, "ContainerDoors")



static func hopper_wagon(loaded := true) -> Vehicle:
	var v := Vehicle.new()
	v.name = "HopperWagon"
	v.length = 13.0
	v.width = 3.1
	v.height = 3.6
	v.bogie_spacing = 8.2
	v.wheel_radius = 0.42
	v.mass_empty = 22.0
	v.mass_loaded = 82.0
	v.kind = "wagon"
	v.designation = "C80 漏斗敞车"
	v.max_speed = 100.0
	v.brake_force = 0.85
	v.set_loaded(loaded)

	var body_mat := Gfx.metal(Color(0.54, 0.555, 0.55), 0.56, 0.52)
	var rib_mat := Gfx.metal(Color(0.36, 0.315, 0.27), 0.72, 0.45)
	var dark := Gfx.metal(C_DARK, 0.62, 0.45)
	var steel := Gfx.metal(Color(0.45, 0.47, 0.49), 0.3, 0.82)
	var half_len := v.length * 0.5 - 0.7

	# 上宽下窄的漏斗车体
	var prof := PackedVector2Array([
		Vector2(-1.42, 1.15),
		Vector2(1.42, 1.15),
		Vector2(1.55, 1.42),
		Vector2(1.55, 2.9),
		Vector2(-1.55, 2.9),
		Vector2(-1.55, 1.42),
	])
	v.part(Forge.extrude(prof, half_len * 2.0), body_mat,
			Transform3D(Basis(), Vector3(0, 0, - half_len)), "Body")
	for end: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(3.1, 1.75, 0.15)), body_mat,
				Transform3D(Basis(), Vector3(0, 2.03, end * half_len)), "EndWall")
		v.part(Forge.box(Vector3(3.14, 0.14, 0.16)), rib_mat,
				Transform3D(Basis(), Vector3(0, 2.95, end * half_len)), "EndTopChord")

	# 侧墙立柱、下弦和顶弦
	for side: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(0.12, 0.12, half_len * 2.0)), rib_mat,
				Transform3D(Basis(), Vector3(side * 1.53, 2.98, 0)), "TopChord")
		v.part(Forge.box(Vector3(0.12, 0.16, half_len * 2.0)), rib_mat,
				Transform3D(Basis(), Vector3(side * 1.53, 1.3, 0)), "BottomChord")
		for i in range(8):
			var z := - half_len + 0.55 + float(i) * (half_len * 2.0 - 1.1) / 7.0
			v.part(Forge.box(Vector3(0.1, 1.62, 0.12)), rib_mat,
					Transform3D(Basis(), Vector3(side * 1.53, 2.08, z)), "SideRib")
		for z: float in [-3.6, 0.0, 3.6]:
			v.part(Forge.box(Vector3(0.08, 1.4, 0.08)), rib_mat,
					Transform3D(Basis(), Vector3(side * 1.57, 2.1, z)), "SidePillar")

	# 底部漏斗、排料口和底架
	for z: float in [-2.8, 2.8]:
		v.part(Forge.box(Vector3(2.45, 0.55, 1.9)), body_mat,
				Transform3D(Basis(), Vector3(0, 0.88, z)), "DischargeChute")
		v.part(Forge.box(Vector3(1.4, 0.32, 0.85)), dark,
				Transform3D(Basis(), Vector3(0, 0.62, z)), "DischargeDoor")
		for side: float in [-1.0, 1.0]:
			v.part(Forge.box(Vector3(0.16, 0.6, 1.85)), rib_mat,
					Transform3D(Basis(Vector3.FORWARD, side * 0.16), Vector3(side * 1.1, 0.86, z)), "ChuteGusset")
	v.part(Forge.box(Vector3(2.8, 0.24, 8.0)), Gfx.metal(Color(0.22, 0.23, 0.25), 0.66, 0.45),
			Transform3D(Basis(), Vector3(0, 1.02, 0)), "Underframe")

	if loaded:
		var coal := Forge.extrude(PackedVector2Array([
			Vector2(-1.44, 2.62), Vector2(1.44, 2.62),
			Vector2(0.95, 2.78), Vector2(0.0, 2.86), Vector2(-0.95, 2.78),
		]), half_len * 2.0 - 0.45)
		v.part(coal, Gfx.noise_surface(C_COAL, 0.95, 0.4, 0.6),
				Transform3D(Basis(), Vector3(0, 0, - half_len + 0.22)), "Coal")
		for i in range(6):
			var lz := - half_len + 2.1 + float(i) * (half_len * 2.0 - 4.2) / 5.0
			var lx := -0.55 if i % 2 == 0 else 0.5
			v.part(Forge.box(Vector3(0.62, 0.12, 0.42)), Gfx.noise_surface(C_COAL, 0.95, 0.4, 0.6),
					Transform3D(Basis(Vector3.UP, float(i) * 0.5), Vector3(lx, 2.89, lz)), "CoalLump")

	# 端梯、端扶手、手制动轮
	for end: float in [-1.0, 1.0]:
		for lx: float in [-0.38, 0.38]:
			v.part(Forge.box(Vector3(0.045, 2.1, 0.05)), dark,
					Transform3D(Basis(), Vector3(lx, 2.0, end * (half_len + 0.1))), "LadderRail")
		for ly: float in [1.2, 1.5, 1.8, 2.1, 2.4, 2.7, 3.0]:
			v.part(Forge.box(Vector3(0.78, 0.035, 0.04)), dark,
					Transform3D(Basis(), Vector3(0, ly, end * (half_len + 0.14))), "LadderStep")
		v.part(Forge.box(Vector3(0.05, 1.05, 0.05)), steel,
				Transform3D(Basis(), Vector3(0.8, 2.2, end * (half_len + 0.1))), "EndHandrail")
		v.part(Forge.box(Vector3(0.05, 0.05, 0.95)), steel,
				Transform3D(Basis(), Vector3(0.8, 2.7, end * (half_len + 0.1))), "EndHandrail")
	v.part(Forge.cylinder(0.3, 0.06, 18, 0.0, true, true), dark,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.78, 1.5, half_len + 0.22)), "HandbrakeWheel")

	# 底架制动设备
	v.part(Forge.cylinder(0.2, 0.65, 14, 0.0, true, true), dark,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.6, 0.76, -3.9)), "BrakeCylinder")
	v.part(Forge.cylinder(0.24, 2.1, 16, 0.0, true, true), steel,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.72, 0.74, -0.5)), "AirReservoir")
	v.part(Forge.box(Vector3(0.36, 0.34, 0.62)), Gfx.metal(Color(0.22, 0.23, 0.25), 0.6, 0.5),
			Transform3D(Basis(), Vector3(-0.8, 0.68, 3.5)), "BrakeValve")
	v.part(Forge.box(Vector3(0.85, 0.24, 0.05)), Gfx.paint(Color(0.8, 0.8, 0.75), 0.5, 0.3, 0.4),
			Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(1.56, 1.48, -1.8)), "NumberPlate")
	for side: float in [-1.0, 1.0]:
		_car_marking(v, "C80", Vector3(side * 1.6, 2.22, -1.1), side,
				Color(0.12, 0.12, 0.13), Color(0.9, 0.9, 0.86))

	_coupler(v, - half_len - 0.75, dark, 0.8)
	_coupler(v, half_len + 0.75, dark, 0.8)
	_bogie_k7(v, - v.bogie_spacing * 0.5, v.wheel_radius)
	_bogie_k7(v, v.bogie_spacing * 0.5, v.wheel_radius)
	return v



static func _bogie_bo(v: Vehicle, z_center: float, wheel_r: float) -> Node3D:
	return _build_bogie(v, z_center, wheel_r, 2, 2.4)

static func _bogie_co(v: Vehicle, z_center: float, wheel_r: float) -> Node3D:
	return _build_bogie(v, z_center, wheel_r, 3, 1.9)


static func _side_frame_profile(axles: Array, wheel_r: float, plate_w: float) -> ArrayMesh:
	var half_len := 0.0
	for raw in axles:
		half_len = maxf(half_len, absf(float(raw)))
	half_len += 0.58
	var top := wheel_r + 0.52
	var end_bot := wheel_r - 0.42
	var arch_top := wheel_r + 0.34
	var sorted := axles.duplicate()
	sorted.sort()
	sorted.reverse()
	var prof := PackedVector2Array()
	# One solid cast-steel plate: flat top chord, pedestal jaws at the ends and
	# an inverted-U arch over the wheels between the axleboxes.
	prof.append(Vector2(-half_len, top))
	prof.append(Vector2(half_len, top))
	prof.append(Vector2(half_len, end_bot + 0.08))
	prof.append(Vector2(half_len - 0.10, end_bot))
	for i in range(sorted.size()):
		var az := float(sorted[i])
		prof.append(Vector2(az + 0.27, end_bot))
		prof.append(Vector2(az - 0.27, end_bot))
		if i < sorted.size() - 1:
			var next := float(sorted[i + 1])
			var a := az - 0.27
			var b := next + 0.27
			for k in range(1, 8):
				var t := float(k) / 8.0
				var z := lerpf(a, b, t)
				var yy := end_bot + (arch_top - end_bot) * smoothstep(0.0, 1.0, sin(PI * t))
				prof.append(Vector2(z, yy))
	prof.append(Vector2(-half_len + 0.10, end_bot))
	prof.append(Vector2(-half_len, end_bot + 0.08))
	return Forge.extrude(prof, plate_w)


static func _build_bogie_new(v: Vehicle, z_center: float, wheel_r: float,
		axles: Array, style := "loco") -> Node3D:
	var bogie := Node3D.new()
	bogie.name = "Bogie"
	bogie.position = Vector3(0, 0, z_center)
	v.attach(bogie)

	var heavy := style == "k7"
	var passenger := style == "passenger"
	var loco := style.begins_with("loco")
	var cast := Gfx.metal(Color(0.42, 0.435, 0.455), 0.68, 0.45)
	var steel := Gfx.metal(Color(0.66, 0.68, 0.70), 0.26, 0.9)
	var dark := Gfx.metal(Color(0.10, 0.105, 0.115), 0.65, 0.4)
	var spring_mat := Gfx.metal(Color(0.60, 0.62, 0.64), 0.28, 0.86)
	var motor_mat := Gfx.metal(Color(0.075, 0.082, 0.09), 0.52, 0.62)
	var plate_w := 0.16
	var x_frame := 1.02
	var top := wheel_r + 0.52
	var frame_half := 0.58
	for raw in axles:
		frame_half = maxf(frame_half, absf(float(raw)) + 0.58)
	var spring_r := 0.17 if heavy else (0.15 if passenger else 0.145)
	var spring_h := 0.30 if not heavy else 0.34
	var spring := _coil_spring(spring_r, spring_h, 5.4, 0.019, 26)
	var inner := _coil_spring(spring_r * 0.55, spring_h * 0.9, 4.8, 0.013, 20)
	var side_mesh := _side_frame_profile(axles, wheel_r, plate_w)

	var frame_items := []
	var spring_items := []
	var detail_items := []
	var brake_items := []
	var motor_items := []

	for side: float in [-1.0, 1.0]:
		var basis := Basis(Vector3.UP, -side * PI * 0.5)
		frame_items.append([side_mesh,
				Transform3D(basis, Vector3(side * (x_frame + plate_w * 0.5), 0, 0))])
		frame_items.append([Forge.box(Vector3(0.26, 0.08, frame_half * 2.0 - 0.10)),
				Transform3D(Basis(), Vector3(side * x_frame, top + 0.02, 0))])
		frame_items.append([Forge.box(Vector3(0.36, 0.07, 0.98)),
				Transform3D(Basis(), Vector3(side * x_frame, top + 0.08, 0))])
		for raw in axles:
			var az := float(raw)
			var ax := side * (x_frame + plate_w * 0.5 + 0.012)
			# Axlebox is captured by the pedestal jaw; only its cover plate and
			# four bolts protrude through the side frame.
			frame_items.append([Forge.box(Vector3(0.06, 0.46, 0.34)),
					Transform3D(Basis(), Vector3(ax, wheel_r - 0.01, az))])
			detail_items.append([Forge.cylinder(0.105, 0.035, 16, 0.0, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5),
							Vector3(ax + side * 0.018, wheel_r - 0.01, az))])
			for by: float in [-0.17, 0.17]:
				for bz: float in [-0.11, 0.11]:
					detail_items.append([Forge.cylinder(0.017, 0.026, 8, 0.0, true, true),
							Transform3D(Basis(Vector3.BACK, PI * 0.5),
									Vector3(ax + side * 0.034, wheel_r - 0.01 + by, az + bz))])
			frame_items.append([Forge.box(Vector3(0.24, 0.11, 0.46)),
					Transform3D(Basis(), Vector3(side * x_frame, wheel_r + 0.34, az))])
			if loco or passenger:
				detail_items.append_array(Forge.tube_between(
						Vector3(side * (x_frame + 0.10), top - 0.06, az + 0.35),
						Vector3(side * (x_frame + 0.16), wheel_r - 0.08, az + 0.26), 0.028, 6))
		for sz: float in [-0.30, 0.30]:
			spring_items.append([spring, Transform3D(Basis(),
					Vector3(side * x_frame, top + 0.12, sz))])
			spring_items.append([inner, Transform3D(Basis(),
					Vector3(side * x_frame, top + 0.16, sz))])
			detail_items.append([Forge.cylinder(spring_r + 0.035, 0.028, 18, 0.0, true, true),
					Transform3D(Basis(), Vector3(side * x_frame, top + 0.10, sz))])
			detail_items.append([Forge.cylinder(spring_r + 0.035, 0.028, 18, 0.0, true, true),
					Transform3D(Basis(), Vector3(side * x_frame, top + 0.12 + spring_h, sz))])
		# Longitudinal equalizer / brake hanger beam along the side frame.
		detail_items.append([Forge.box(Vector3(0.06, 0.10, frame_half * 2.0 - 0.30)),
				Transform3D(Basis(), Vector3(side * (x_frame + 0.09), wheel_r + 0.10, 0))])

	for raw in axles:
		var az := float(raw)
		brake_items.append([Forge.box(Vector3(1.92, 0.12, 0.16)),
				Transform3D(Basis(), Vector3(0, wheel_r - 0.02, az))])
		for side: float in [-1.0, 1.0]:
			brake_items.append([Forge.box(Vector3(0.10, 0.30, 0.15)),
					Transform3D(Basis(), Vector3(side * 0.56, wheel_r - 0.04, az))])
			brake_items.append([Forge.box(Vector3(0.22, 0.11, 0.10)),
					Transform3D(Basis(), Vector3(side * 0.56, wheel_r - 0.19, az))])
			if passenger:
				detail_items.append([Forge.box(Vector3(0.16, 0.28, 0.12)),
						Transform3D(Basis(), Vector3(side * 0.74, wheel_r - 0.02, az + 0.32))])
		detail_items.append_array(Forge.tube_between(Vector3(-0.9, wheel_r + 0.10, az),
				Vector3(0.9, wheel_r + 0.10, az), 0.024, 6))
	brake_items.append([Forge.cylinder(0.15, 0.74, 16, 0.0, true, true),
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.55, wheel_r + 0.16, 0.82))])
	brake_items.append([Forge.box(Vector3(0.3, 0.28, 0.26)),
			Transform3D(Basis(), Vector3(0.55, wheel_r + 0.16, 1.20))])

	if loco:
		for raw in axles:
			var az := float(raw)
			motor_items.append([Forge.cylinder(0.29, 1.08, 18, 0.0, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, wheel_r - 0.04, az))])
			for dx: float in [-0.36, 0.0, 0.36]:
				motor_items.append([Forge.cylinder(0.305, 0.032, 18, 0.0, true, true),
						Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(dx, wheel_r - 0.04, az))])
			motor_items.append([Forge.box(Vector3(0.46, 0.42, 0.56)),
					Transform3D(Basis(), Vector3(0.68, wheel_r - 0.05, az + 0.10))])
			motor_items.append([Forge.cylinder(0.17, 0.86, 14, 0.0, true, true),
					Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, wheel_r - 0.10, az + 0.58))])

	# Bolster and centre pivot.
	frame_items.append([Forge.box(Vector3(2.32, 0.22, 0.62)),
			Transform3D(Basis(), Vector3(0, top + 0.44, 0))])
	frame_items.append([Forge.box(Vector3(1.58, 0.13, 0.82)),
			Transform3D(Basis(), Vector3(0, top + 0.58, 0))])
	detail_items.append([Forge.cylinder(0.26, 0.12, 20, 0.0, true, true),
			Transform3D(Basis(), Vector3(0, top + 0.61, 0))])
	for side: float in [-1.0, 1.0]:
		frame_items.append([Forge.box(Vector3(0.20, 0.12, 0.42)),
				Transform3D(Basis(), Vector3(side * 0.76, top + 0.60, 0))])
		detail_items.append([Forge.cylinder(0.10, 0.12, 14, 0.0, true, true),
				Transform3D(Basis(), Vector3(side * 0.76, top + 0.66, 0))])

	var frame_root := Node3D.new()
	frame_root.name = "BogieFrameRoot"
	bogie.add_child(frame_root)
	for item: Array in [
		[frame_items, cast, "BogieFrame"],
		[spring_items, spring_mat, "Springs"],
		[detail_items, steel, "BogieDetails"],
		[brake_items, dark, "BrakeRigging"],
		[motor_items, motor_mat, "TractionMotors"],
	]:
		var items: Array = item[0]
		if items.is_empty():
			continue
		var mi := MeshInstance3D.new()
		mi.name = String(item[2])
		mi.mesh = Forge.merge_all(items)
		mi.material_override = item[1]
		frame_root.add_child(mi)
	for raw in axles:
		_add_bogie_wheelset(v, bogie, wheel_r, float(raw), passenger or loco)
	v.bogie_frames.append(frame_root)
	return bogie


static func _build_bogie(v: Vehicle, z_center: float, wheel_r: float, axles: int, spacing: float) -> Node3D:
	var list: Array = []
	if axles >= 3:
		for i in range(axles):
			list.append((float(i) - float(axles - 1) * 0.5) * spacing)
		return _build_bogie_new(v, z_center, wheel_r, list, "loco3")
	var half := clampf(spacing, 1.6, 2.35) * 0.5
	list = [-half, half]
	return _build_bogie_new(v, z_center, wheel_r, list, "loco")

static func _coil_spring(radius: float, height: float, turns: float, wire: float, segs := 24) -> ArrayMesh:
	var pts: Array [Vector3] = []
	for i in range(segs + 1):
		var t := float(i) / float(segs)
		var a := TAU * turns * t
		pts.append(Vector3(cos(a) * radius, height * t, sin(a) * radius))
	var items := []
	for i in range(segs):
		items.append_array(Forge.tube_between(pts [i], pts [i + 1], wire, 5))
	return Forge.merge_all(items)


static func _legacy_build_bogie(v: Vehicle, z_center: float, wheel_r: float, axles: int, spacing: float) -> Node3D:
	var bogie := Node3D.new()
	bogie.name = "Bogie"
	bogie.position = Vector3(0, 0, z_center)
	v.attach(bogie)

	var cast := Gfx.metal(Color(0.32, 0.33, 0.35), 0.42, 0.68)
	var steel := Gfx.metal(Color(0.62, 0.63, 0.65), 0.26, 0.92)
	var wheel_steel := Gfx.metal(Color(0.28, 0.29, 0.31), 0.34, 0.86)
	var spring_steel := Gfx.metal(Color(0.78, 0.79, 0.8), 0.26, 0.9)
	var spring_mesh := _coil_spring(0.125, 0.26, 5.0, 0.02, 28)

	var half :=(float(axles - 1) * spacing) * 0.5
	var axle_positions := []
	for i in range(axles):
		axle_positions.append(- half + float(i) * spacing)

	var frame_items := []
	var spring_items := []
	var detail_items := []
	var frame_len := float(axles - 1) * spacing + 1.5
	for side: float in [-1.0, 1.0]:
		frame_items.append([Forge.rounded_box_x(frame_len, 0.18, 0.13, 0.05),
				Transform3D(Basis(), Vector3(side * 1.0, wheel_r + 0.42, 0))])
		frame_items.append([Forge.rounded_box_x(frame_len, 0.18, 0.11, 0.04),
				Transform3D(Basis(), Vector3(side * 1.0, wheel_r + 0.17, 0))])
		detail_items.append([Forge.box(Vector3(0.36, 0.055, frame_len * 0.94)),
				Transform3D(Basis(), Vector3(side * 1.0, wheel_r + 0.54, 0))])
		for ez: float in [-1.0, 1.0]:
			frame_items.append([Forge.box(Vector3(0.19, 0.36, 0.14)),
					Transform3D(Basis(), Vector3(side * 1.0, wheel_r + 0.3, ez * frame_len * 0.47))])
			frame_items.append([Forge.box(Vector3(0.22, 0.1, 0.3)),
					Transform3D(Basis(), Vector3(side * 1.0, wheel_r + 0.47, ez * frame_len * 0.44))])
			frame_items.append_array(Forge.tube_between(
					Vector3(side * 1.02, wheel_r + 0.42, ez * frame_len * 0.38),
					Vector3(side * 1.02, wheel_r + 0.18, ez * frame_len * 0.15), 0.03, 6))
		for az in axle_positions:
			for pz: float in [- 0.3, 0.3]:
				frame_items.append([Forge.box(Vector3(0.19, 0.27, 0.08)),
						Transform3D(Basis(), Vector3(side * 1.0, wheel_r + 0.3, az + pz))])
			frame_items.append([Forge.rounded_box_x(0.4, 0.28, 0.3, 0.05),
					Transform3D(Basis(), Vector3(side * 1.0, wheel_r - 0.02, az))])
			detail_items.append([Forge.box(Vector3(0.3, 0.36, 0.2)),
					Transform3D(Basis(), Vector3(side * 1.06, wheel_r + 0.18, az))])
			spring_items.append([spring_mesh,
					Transform3D(Basis(), Vector3(side * 1.16, wheel_r + 0.27, az))])
			detail_items.append([Forge.cylinder(0.155, 0.028, 16, 0.0, true, true),
					Transform3D(Basis(), Vector3(side * 1.16, wheel_r + 0.25, az))])
			detail_items.append([Forge.cylinder(0.155, 0.028, 16, 0.0, true, true),
					Transform3D(Basis(), Vector3(side * 1.16, wheel_r + 0.53, az))])
			detail_items.append([Forge.cylinder(0.15, 0.07, 16, - 0.035, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(side * 1.16, wheel_r, az))])
			detail_items.append_array(Forge.tube_between(
					Vector3(side * 1.19, wheel_r + 0.47, az + 0.18),
					Vector3(side * 1.21, wheel_r + 0.05, az + 0.34), 0.03, 8))
			detail_items.append_array(Forge.tube_between(
					Vector3(side * 0.9, wheel_r + 0.15, az - frame_len * 0.38),
					Vector3(side * 0.9, wheel_r + 0.15, az + frame_len * 0.38), 0.022, 6))
			detail_items.append([Forge.rounded_box_x(0.55, 0.34, 0.42, 0.07),
					Transform3D(Basis(), Vector3(side * 0.42, wheel_r + 0.05, az))])
			frame_items.append([Forge.box(Vector3(0.1, 0.28, 0.18)),
					Transform3D(Basis(), Vector3(side * 0.46, wheel_r + 0.04, az + 0.18))])
			frame_items.append_array(Forge.tube_between(
					Vector3(side * 0.82, wheel_r + 0.34, az - 0.28),
					Vector3(side * 0.74, wheel_r + 0.03, az - 0.34), 0.018, 6))
		for az: float in [- frame_len * 0.27, frame_len * 0.27]:
			frame_items.append([Forge.cylinder(0.18, 0.2, 16, 0.0, true, true),
					Transform3D(Basis(), Vector3(side * 1.0, wheel_r + 0.56, az))])
			frame_items.append([Forge.cylinder(0.12, 0.05, 12, 0.0, true, true),
					Transform3D(Basis(), Vector3(side * 1.0, wheel_r + 0.77, az))])
			frame_items.append_array(Forge.tube_between(
					Vector3(side * 1.1, wheel_r + 0.56, az + 0.22),
					Vector3(side * 1.1, wheel_r + 0.18, az - 0.05), 0.035, 8))
		detail_items.append([Forge.cylinder(0.13, 0.62, 12, 0.0, true, true),
				Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(side * 1.19, wheel_r + 0.24, - frame_len * 0.34))])
		detail_items.append([Forge.cylinder(0.05, 0.7, 8, 0.0, true, true),
				Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(side * 1.19, wheel_r + 0.24, - frame_len * 0.34 + 0.62))])
		frame_items.append([Forge.box(Vector3(0.34, 0.36, 0.46)),
				Transform3D(Basis(), Vector3(side * 0.82, wheel_r + 0.46, - frame_len * 0.4))])
		detail_items.append([Forge.box(Vector3(0.02, 0.12, 0.24)),
				Transform3D(Basis(), Vector3(side * 1.12, wheel_r + 0.42, frame_len * 0.34))])
		for bz: float in [- frame_len * 0.4, - frame_len * 0.2, 0.0, frame_len * 0.2, frame_len * 0.4]:
			detail_items.append([Forge.cylinder(0.025, 0.04, 8, - 0.02, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(side * 1.1, wheel_r + 0.2, bz))])

	frame_items.append([Forge.box(Vector3(2.26, 0.2, 0.2)), Transform3D(Basis(), Vector3(0, wheel_r + 0.24, 0))])
	for az in axle_positions:
		frame_items.append([Forge.box(Vector3(2.26, 0.16, 0.18)),
				Transform3D(Basis(), Vector3(0, wheel_r + 0.18, az))])
		frame_items.append([Forge.cylinder(0.25, 1.0, 16, 0.0, true, true),
				Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, wheel_r + 0.03, az - 0.5))])
		frame_items.append([Forge.box(Vector3(0.46, 0.42, 0.58)),
				Transform3D(Basis(), Vector3(0.58, wheel_r + 0.06, az + 0.36))])
	frame_items.append_array(Forge.tube_between(Vector3(-1.12, wheel_r + 0.58, frame_len * 0.3),
			Vector3(1.12, wheel_r + 0.58, frame_len * 0.3), 0.04, 8))
	for side: float in [-1.0, 1.0]:
		frame_items.append_array(Forge.tube_between(Vector3(side * 1.12, wheel_r + 0.58, frame_len * 0.3),
				Vector3(side * 1.12, wheel_r + 0.32, frame_len * 0.3), 0.032, 8))
		frame_items.append_array(Forge.tube_between(
				Vector3(side * 0.5, wheel_r + 0.66, 0),
				Vector3(side * 0.5, wheel_r + 0.95, 0.55), 0.03, 8))
	frame_items.append([Forge.box(Vector3(2.35, 0.18, 0.72)),
			Transform3D(Basis(), Vector3(0, wheel_r + 0.64, 0))])
	frame_items.append([Forge.cylinder(0.2, 0.14, 16, 0.0, true, true),
			Transform3D(Basis(), Vector3(0, wheel_r + 0.73, 0))])
	for side: float in [-1.0, 1.0]:
		frame_items.append([Forge.box(Vector3(0.24, 0.1, 0.58)),
				Transform3D(Basis(), Vector3(side * 0.86, wheel_r + 0.72, 0))])

	var frame_root := Node3D.new()
	frame_root.name = "BogieFrameRoot"
	bogie.add_child(frame_root)
	var frame := MeshInstance3D.new()
	frame.name = "BogieFrame"
	frame.mesh = Forge.merge_all(frame_items)
	frame.material_override = cast
	frame_root.add_child(frame)

	var springs := MeshInstance3D.new()
	springs.name = "PrimarySprings"
	springs.mesh = Forge.merge_all(spring_items)
	springs.material_override = spring_steel
	frame_root.add_child(springs)

	var details := MeshInstance3D.new()
	details.name = "BogieDetails"
	details.mesh = Forge.merge_all(detail_items)
	details.material_override = steel
	frame_root.add_child(details)

	var wheel_mesh := _wheel_mesh(wheel_r)
	var disc_mesh := Forge.merge_all([
		[Forge.cylinder(0.28, 0.045, 22, - 0.0225, true, true),
				Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(- 0.42, 0, 0))],
		[Forge.cylinder(0.28, 0.045, 22, - 0.0225, true, true),
				Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.42, 0, 0))],
	])
	var axle_span :=(Config.GAUGE - 0.1) * 0.5

	for az in axle_positions:
		var axle_node := Node3D.new()
		axle_node.name = "Wheelset%d" %(v.wheels.size() + 1)
		axle_node.position = Vector3(0, wheel_r, az)
		bogie.add_child(axle_node)

		var axle := MeshInstance3D.new()
		axle.mesh = Forge.cylinder(0.08, 2.26, 12, - 1.13, true, true)
		axle.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO)
		axle.material_override = steel
		axle_node.add_child(axle)

		var discs := MeshInstance3D.new()
		discs.mesh = disc_mesh
		discs.material_override = Gfx.metal(Color(0.3, 0.31, 0.33), 0.4, 0.85)
		axle_node.add_child(discs)

		for side: float in [-1.0, 1.0]:
			var w := MeshInstance3D.new()
			w.mesh = wheel_mesh
			w.material_override = wheel_steel
			w.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(side * axle_span, 0, 0))
			axle_node.add_child(w)
		v.add_wheel(axle_node, wheel_r)
	v.bogie_frames.append(frame_root)
	return bogie

static func _bogie_k6(v: Vehicle, z_center: float, wheel_r: float) -> Node3D:
	return _bogie_freight(v, z_center, wheel_r, false)


static func _bogie_k7(v: Vehicle, z_center: float, wheel_r: float) -> Node3D:
	return _bogie_freight(v, z_center, wheel_r, true)


static func _add_bogie_wheelset(v: Vehicle, bogie: Node3D, wheel_r: float, az: float, with_discs: bool) -> void:
	var axle_node := Node3D.new()
	axle_node.name = "Wheelset%d" %(v.wheels.size() + 1)
	axle_node.position = Vector3(0, wheel_r, az)
	bogie.add_child(axle_node)
	var steel := Gfx.metal(Color(0.58, 0.60, 0.62), 0.30, 0.9)
	var axle := MeshInstance3D.new()
	axle.mesh = Forge.cylinder(0.075, 2.16, 12, -1.08, true, true)
	axle.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO)
	axle.material_override = steel
	axle_node.add_child(axle)
	if with_discs:
		var disc_mesh := Forge.merge_all([
			[Forge.cylinder(0.29, 0.045, 22, -0.0225, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(-0.43, 0, 0))],
			[Forge.cylinder(0.29, 0.045, 22, -0.0225, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.43, 0, 0))],
		])
		var discs := MeshInstance3D.new()
		discs.mesh = disc_mesh
		discs.material_override = Gfx.metal(Color(0.3, 0.31, 0.33), 0.4, 0.85)
		axle_node.add_child(discs)
	var wheel_mesh := _wheel_mesh(wheel_r)
	var wheel_mat := Gfx.metal(Color(0.25, 0.26, 0.28), 0.38, 0.84)
	var axle_span := (Config.GAUGE - 0.1) * 0.5
	for side: float in [-1.0, 1.0]:
		var w := MeshInstance3D.new()
		w.mesh = wheel_mesh
		w.material_override = wheel_mat
		w.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(side * axle_span, 0, 0))
		axle_node.add_child(w)
	v.add_wheel(axle_node, wheel_r)


static func _register_bogie_instance(v: Vehicle, bogie: Node3D, wheel_r: float) -> void:
	var frame_root := bogie.get_node_or_null("BogieFrameRoot")
	if frame_root is Node3D:
		v.bogie_frames.append(frame_root)
	for child in bogie.get_children():
		if child is Node3D and String(child.name).begins_with("Wheelset"):
			v.add_wheel(child, wheel_r)


static func _bogie_freight(v: Vehicle, z_center: float, wheel_r: float, heavy: bool) -> Node3D:
	var key := "%s_%.3f" % ["k7" if heavy else "k6", wheel_r]
	var template: Node3D = _bogie_templates.get(key, null)
	if template == null:
		var dummy := Vehicle.new()
		template = _build_freight_bogie_uncached(dummy, 0.0, wheel_r, heavy)
		var parent := template.get_parent()
		if parent != null:
			parent.remove_child(template)
		dummy.free()
		_bogie_templates [key] = template
	var bogie: Node3D = template.duplicate()
	bogie.position = Vector3(0, 0, z_center)
	v.attach(bogie)
	_register_bogie_instance(v, bogie, wheel_r)
	return bogie


static func _bogie_passenger(v: Vehicle, z_center: float, wheel_r: float) -> Node3D:
	var key := "p_%.3f" % wheel_r
	var template: Node3D = _bogie_templates.get(key, null)
	if template == null:
		var dummy := Vehicle.new()
		template = _build_passenger_bogie_uncached(dummy, 0.0, wheel_r)
		var parent := template.get_parent()
		if parent != null:
			parent.remove_child(template)
		dummy.free()
		_bogie_templates [key] = template
	var bogie: Node3D = template.duplicate()
	bogie.position = Vector3(0, 0, z_center)
	v.attach(bogie)
	_register_bogie_instance(v, bogie, wheel_r)
	return bogie

static func _carriage_side_frame_mesh(axle_z: Array, plate_w: float,
		top: float, end_bottom: float, arch_top: float) -> ArrayMesh:
	var max_axle := 0.0
	for raw in axle_z:
		max_axle = maxf(max_axle, absf(float(raw)))
	var half_len := max_axle + 0.36
	var sorted := axle_z.duplicate()
	sorted.sort()
	sorted.reverse()
	var prof := PackedVector2Array()
	prof.append(Vector2(-half_len, top))
	prof.append(Vector2(half_len, top))
	prof.append(Vector2(half_len, end_bottom + 0.10))
	prof.append(Vector2(half_len - 0.07, end_bottom))
	for i in range(sorted.size()):
		var az := float(sorted[i])
		prof.append(Vector2(az + 0.24, end_bottom))
		prof.append(Vector2(az - 0.24, end_bottom))
		if i < sorted.size() - 1:
			var next := float(sorted[i + 1])
			var a := az - 0.24
			var b := next + 0.24
			for k in range(1, 11):
				var t := float(k) / 11.0
				var z := lerpf(a, b, t)
				var yy := end_bottom + (arch_top - end_bottom) * smoothstep(0.0, 1.0, sin(PI * t))
				prof.append(Vector2(z, yy))
	prof.append(Vector2(-half_len + 0.07, end_bottom))
	prof.append(Vector2(-half_len, end_bottom + 0.10))
	return Forge.extrude(prof, plate_w)


static func _append_vertical_damper(body_items: Array, rod_items: Array,
		a: Vector3, b: Vector3, radius: float) -> void:
	var dir :=(b - a).normalized()
	var mid := a.lerp(b, 0.5)
	body_items.append([Forge.cylinder(radius, 0.24, 14, - 0.12, true, true),
			Transform3D(Forge.basis_from_y(dir), mid)])
	rod_items.append_array(Forge.tube_between(a, b, radius * 0.42, 8))
	for p: Vector3 in [a, b]:
		rod_items.append([Forge.cylinder(radius * 1.55, 0.05, 14, - 0.025, true, true),
				Transform3D(Basis(Vector3.BACK, PI * 0.5), p)])
		rod_items.append([Forge.cylinder(radius * 0.52, 0.075, 10, - 0.0375, true, true),
				Transform3D(Basis(Vector3.BACK, PI * 0.5), p)])


static func _build_carriage_bogie(v: Vehicle, z_center: float, wheel_r: float,
		style := "k6") -> Node3D:
	var passenger := style == "p209"
	var heavy := style == "k7"
	var bogie := Node3D.new()
	bogie.name = "Bogie"
	bogie.position = Vector3(0, 0, z_center)
	v.attach(bogie)

	var cast := Gfx.metal(Color(0.34, 0.32, 0.29), 0.78, 0.22)
	var bolster_mat := Gfx.metal(Color(0.29, 0.27, 0.24), 0.74, 0.28)
	var spring_mat := Gfx.metal(Color(0.63, 0.52, 0.38), 0.58, 0.34)
	var steel := Gfx.metal(Color(0.68, 0.69, 0.70), 0.28, 0.88)
	var dark := Gfx.metal(Color(0.11, 0.11, 0.115), 0.72, 0.34)
	var rubber := Gfx.carpet(Color(0.04, 0.04, 0.042))
	var pocket_mat := Gfx.metal(Color(0.075, 0.072, 0.067), 0.9, 0.16)
	var wheel_mat := Gfx.metal(Color(0.50, 0.52, 0.54), 0.30, 0.88)
	var damper_mat := Gfx.metal(Color(0.20, 0.20, 0.21), 0.42, 0.58)

	var axle_abs := 1.20 if passenger else (0.93 if heavy else 0.915)
	var axle_z := [-axle_abs, axle_abs]
	var x_frame := 0.90 if (passenger or heavy) else 0.88
	var plate_t := 0.15
	var frame_top := wheel_r + 0.40
	var end_bottom := wheel_r - 0.12
	var arch_y := wheel_r + 0.06
	var half_len := axle_abs + 0.33
	var window_half := 0.33
	var spring_h := frame_top - arch_y - 0.12
	var spring_outer := _coil_spring(0.105, spring_h, 4.6, 0.015, 26)
	var spring_inner := _coil_spring(0.060, spring_h * 0.92, 4.2, 0.012, 20)

	var frame_items := []
	var spring_items := []
	var bolster_items := []
	var detail_items := []
	var brake_items := []
	var rubber_items := []
	var pocket_items := []
	var damper_items := []
	var damper_rod_items := []

	for side: float in [-1.0, 1.0]:
		var x := side * x_frame
		# Slender cast side frame: top chord, arched bottom chord, a compact
		# spring window and open pedestal jaws at each axlebox.
		frame_items.append([Forge.box(Vector3(plate_t, 0.13, half_len * 2.0)),
				Transform3D(Basis(), Vector3(x, frame_top, 0))])
		frame_items.append([Forge.box(Vector3(0.23, 0.05, half_len * 2.0 - 0.08)),
				Transform3D(Basis(), Vector3(x, frame_top + 0.075, 0))])
		var segments := 20
		for i in range(segments):
			var t := (float(i) + 0.5) / float(segments)
			var z := - half_len + t * half_len * 2.0
			var y := end_bottom + (arch_y - end_bottom) * smoothstep(0.0, 1.0, sin(PI * t))
			frame_items.append([Forge.box(Vector3(plate_t, 0.10, half_len * 2.0 / float(segments) + 0.035)),
					Transform3D(Basis(), Vector3(x, y, z))])
		for sgn: float in [-1.0, 1.0]:
			frame_items.append([Forge.box(Vector3(0.17, frame_top - end_bottom - 0.04, 0.10)),
					Transform3D(Basis(), Vector3(x, (frame_top + end_bottom) * 0.5, sgn * half_len))])
			# Compact spring-window columns; no full-height end slabs.
			frame_items.append([Forge.box(Vector3(0.17, frame_top - arch_y + 0.04, 0.13)),
					Transform3D(Basis(), Vector3(x, (frame_top + arch_y) * 0.5, sgn * window_half))])
			detail_items.append([Forge.box(Vector3(0.02, 0.26, 0.16)),
					Transform3D(Basis(), Vector3(x + side * 0.083, (frame_top + arch_y) * 0.5, sgn * window_half))])
		# Open pedestal jaws: two cheeks per axle leave the axlebox and wheel
		# face visible instead of boxing them in.
		for az: float in axle_z:
			for jz: float in [-0.19, 0.19]:
				frame_items.append([Forge.box(Vector3(0.17, frame_top - end_bottom - 0.02, 0.085)),
						Transform3D(Basis(), Vector3(x, (frame_top + end_bottom) * 0.5, az + jz))])
				frame_items.append([Forge.box(Vector3(0.18, 0.06, 0.10)),
						Transform3D(Basis(), Vector3(x, end_bottom + 0.03, az + jz))])
			frame_items.append([Forge.box(Vector3(0.18, 0.10, 0.48)),
					Transform3D(Basis(), Vector3(x, frame_top - 0.055, az))])
			frame_items.append([Forge.box(Vector3(0.30, 0.28, 0.30)),
					Transform3D(Basis(), Vector3(side *(x_frame - 0.02), wheel_r, az))])
			rubber_items.append([Forge.box(Vector3(0.24, 0.08, 0.32)),
					Transform3D(Basis(), Vector3(x, wheel_r + 0.17, az))])
			# Axlebox cover and four bolt heads.
			var cover_x := side *(x_frame + plate_t * 0.5 + 0.02)
			detail_items.append([Forge.cylinder(0.155, 0.030, 24, - 0.015, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(cover_x, wheel_r, az))])
			detail_items.append([Forge.cylinder(0.115, 0.045, 24, - 0.0225, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5),
							Vector3(cover_x + side * 0.025, wheel_r, az))])
			for k in range(4):
				var ba := PI * 0.25 + PI * 0.5 * float(k)
				detail_items.append([Forge.cylinder(0.014, 0.024, 8, - 0.012, true, true),
						Transform3D(Basis(Vector3.BACK, PI * 0.5),
								Vector3(cover_x + side * 0.040, wheel_r + sin(ba) * 0.096, az + cos(ba) * 0.096))])
			# Hydraulic vertical damper, fully outboard so it is easy to see.
			var d0 := Vector3(side *(x_frame + 0.115), wheel_r + 0.02, az + 0.25)
			var d1 := Vector3(side *(x_frame + 0.115), frame_top + 0.01, az + 0.13)
			_append_vertical_damper(damper_items, damper_rod_items, d0, d1, 0.045)
			frame_items.append([Forge.box(Vector3(0.20, 0.07, 0.16)),
					Transform3D(Basis(), Vector3(side *(x_frame + 0.05), frame_top, az + 0.13))])
			frame_items.append([Forge.box(Vector3(0.20, 0.07, 0.16)),
					Transform3D(Basis(), Vector3(side *(x_frame + 0.05), wheel_r + 0.02, az + 0.25))])
		# Two narrow spring nests per side; double coils sit in the window.
		for nest: float in [-0.18, 0.18]:
			frame_items.append([Forge.box(Vector3(0.42, 0.04, 0.34)),
					Transform3D(Basis(), Vector3(x, arch_y + 0.025, nest))])
			spring_items.append([spring_outer, Transform3D(Basis(),
					Vector3(x, arch_y + 0.05, nest))])
			spring_items.append([spring_inner, Transform3D(Basis(),
					Vector3(x, arch_y + 0.055, nest))])
			detail_items.append([Forge.cylinder(0.135, 0.020, 18, 0.0, true, true),
					Transform3D(Basis(), Vector3(x, arch_y + 0.065, nest))])
			detail_items.append([Forge.cylinder(0.135, 0.020, 18, 0.0, true, true),
					Transform3D(Basis(), Vector3(x, arch_y + spring_h + 0.075, nest))])
			pocket_items.append([Forge.cylinder(0.105, 0.012, 18, 0.0, true, true),
					Transform3D(Basis(), Vector3(x + side * 0.078, arch_y + 0.035, nest))])
		# Friction wedges and wear plates at both spring-window columns.
		for cz: float in [-window_half + 0.03, window_half - 0.03]:
			var wx := side *(x_frame - 0.105)
			detail_items.append([Forge.box(Vector3(0.12, 0.24, 0.20)),
					Transform3D(Basis(Vector3.RIGHT, side * 0.20),
							Vector3(wx, frame_top - 0.15, cz))])
			detail_items.append([Forge.box(Vector3(0.025, 0.28, 0.22)),
					Transform3D(Basis(), Vector3(wx + side * 0.06, frame_top - 0.15, cz))])
			detail_items.append([Forge.box(Vector3(0.08, 0.10, 0.14)),
					Transform3D(Basis(), Vector3(wx - side * 0.06, frame_top - 0.28, cz))])
		# Cast lightening pockets on the exposed side-frame web.
		for pz: float in [-0.72, 0.72]:
			pocket_items.append([Forge.cylinder(0.095, 0.012, 18, 0.0, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5),
							Vector3(x + side * 0.078, frame_top - 0.15, pz))])
		# Elastic lower cross bracing, kept thin and inboard.
		if not passenger:
			detail_items.append_array(Forge.tube_between(
					Vector3(-x_frame, wheel_r + 0.10, -0.52),
					Vector3(x_frame, wheel_r + 0.10, 0.52), 0.026, 7))
			detail_items.append_array(Forge.tube_between(
					Vector3(x_frame, wheel_r + 0.10, -0.52),
					Vector3(-x_frame, wheel_r + 0.10, 0.52), 0.026, 7))

	# Bolster: compact fish-belly beam with centre bowl and side bearings.
	var bolster_y := frame_top + 0.02
	bolster_items.append([Forge.box(Vector3(1.60, 0.16, 0.42)),
			Transform3D(Basis(), Vector3(0, bolster_y, 0))])
	bolster_items.append([Forge.box(Vector3(1.28, 0.08, 0.54)),
			Transform3D(Basis(), Vector3(0, bolster_y + 0.11, 0))])
	bolster_items.append([Forge.box(Vector3(0.70, 0.07, 0.86)),
			Transform3D(Basis(), Vector3(0, bolster_y + 0.18, 0))])
	bolster_items.append([Forge.cylinder(0.25, 0.06, 22, 0.0, true, true),
			Transform3D(Basis(), Vector3(0, bolster_y + 0.20, 0))])
	for side: float in [-1.0, 1.0]:
		bolster_items.append([Forge.box(Vector3(0.22, 0.20, 0.38)),
				Transform3D(Basis(), Vector3(side * 0.82, bolster_y, 0))])
		bolster_items.append([Forge.box(Vector3(0.18, 0.10, 0.32)),
				Transform3D(Basis(), Vector3(side * 0.70, bolster_y + 0.15, 0))])
		detail_items.append([Forge.cylinder(0.09, 0.075, 16, 0.0, true, true),
				Transform3D(Basis(), Vector3(side * 0.70, bolster_y + 0.20, 0))])
		detail_items.append([Forge.cylinder(0.20, 0.05, 18, 0.0, true, true),
				Transform3D(Basis(), Vector3(side * 0.42, bolster_y + 0.20, 0))])
	detail_items.append([Forge.cylinder(0.075, 0.10, 14, 0.0, true, true),
			Transform3D(Basis(), Vector3(0, bolster_y + 0.29, 0))])

	# Foundation brake gear, sized to sit between wheel treads and side frames.
	for raw: float in axle_z:
		var az := float(raw)
		var beam_z := az - signf(az) * 0.28
		brake_items.append([Forge.box(Vector3(1.64, 0.10, 0.14)),
				Transform3D(Basis(), Vector3(0, wheel_r - 0.16, beam_z))])
		for side: float in [-1.0, 1.0]:
			brake_items.append([Forge.box(Vector3(0.10, 0.28, 0.12)),
					Transform3D(Basis(), Vector3(side * 0.62, wheel_r - 0.02, az))])
			brake_items.append([Forge.box(Vector3(0.10, 0.16, 0.12)),
					Transform3D(Basis(), Vector3(side * 0.60, wheel_r, az))])
			detail_items.append_array(Forge.tube_between(
					Vector3(side *(x_frame - 0.02), wheel_r + 0.18, az),
					Vector3(side * 0.62, wheel_r + 0.08, beam_z), 0.022, 6))
			if passenger:
				brake_items.append([Forge.box(Vector3(0.11, 0.24, 0.14)),
						Transform3D(Basis(), Vector3(side * 0.45, wheel_r + 0.16, az + 0.06))])
				brake_items.append([Forge.box(Vector3(0.11, 0.24, 0.14)),
						Transform3D(Basis(), Vector3(side * 0.45, wheel_r - 0.16, az - 0.06))])
	brake_items.append([Forge.cylinder(0.14, 0.66, 16, - 0.33, true, true),
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.55, wheel_r + 0.16, 0.78))])
	brake_items.append([Forge.cylinder(0.10, 0.52, 14, - 0.26, true, true),
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(- 0.55, wheel_r + 0.19, 0.78))])
	brake_items.append([Forge.box(Vector3(0.22, 0.16, 0.22)),
			Transform3D(Basis(), Vector3(0.55, wheel_r - 0.08, - 0.62))])

	var frame_root := Node3D.new()
	frame_root.name = "BogieFrameRoot"
	bogie.add_child(frame_root)
	for item: Array in [
		[frame_items, cast, "SideFrames"],
		[spring_items, spring_mat, "BolsterSprings"],
		[bolster_items, bolster_mat, "Bolster"],
		[detail_items, steel, "BogieDetails"],
		[brake_items, dark, "BrakeRigging"],
		[rubber_items, rubber, "AxleboxRubberPads"],
		[pocket_items, pocket_mat, "CastLighteningPockets"],
		[damper_items, damper_mat, "Dampers"],
		[damper_rod_items, steel, "DamperRods"],
	]:
		var items: Array = item[0]
		if items.is_empty():
			continue
		var mi := MeshInstance3D.new()
		mi.name = String(item[2])
		mi.mesh = Forge.merge_all(items)
		mi.material_override = item[1]
		frame_root.add_child(mi)
	for side: float in [-1.0, 1.0]:
		var tag := Label3D.new()
		tag.name = "BogieMarking"
		tag.text = "K6" if not passenger else "209P"
		tag.font_size = 18
		tag.pixel_size = 0.0018
		tag.modulate = Color(0.86, 0.83, 0.74)
		tag.outline_size = 2
		tag.outline_modulate = Color(0.08, 0.07, 0.06)
		tag.position = Vector3(side * 1.00, frame_top - 0.02, - 0.78)
		tag.rotation_degrees = Vector3(0, side * 90.0, 0)
		bogie.add_child(tag)
	for raw: float in axle_z:
		_add_bogie_wheelset(v, bogie, wheel_r, float(raw), passenger)
	v.bogie_frames.append(frame_root)
	return bogie


static func _legacy_build_carriage_bogie(v: Vehicle, z_center: float, wheel_r: float,
		style := "k6") -> Node3D:
	var passenger := style == "p209"
	var heavy := style == "k7"
	var bogie := Node3D.new()
	bogie.name = "Bogie"
	bogie.position = Vector3(0, 0, z_center)
	v.attach(bogie)

	var cast := Gfx.metal(Color(0.39, 0.35, 0.29), 0.82, 0.18)
	var bolster_mat := Gfx.metal(Color(0.31, 0.275, 0.235), 0.78, 0.22)
	var spring_mat := Gfx.metal(Color(0.60, 0.49, 0.37), 0.62, 0.28)
	var steel := Gfx.metal(Color(0.64, 0.61, 0.56), 0.36, 0.82)
	var dark := Gfx.metal(Color(0.18, 0.17, 0.155), 0.76, 0.32)
	var rubber := Gfx.carpet(Color(0.065, 0.06, 0.055))
	var wheel_mat := Gfx.metal(Color(0.27, 0.26, 0.245), 0.5, 0.7)

	var axle_abs := 1.20 if passenger else (0.93 if heavy else 0.915)
	var axle_z := [-axle_abs, axle_abs]
	var x_frame := 1.02
	var plate_w := 0.16
	var top := 0.80 if not passenger else 0.84
	var end_bottom := 0.17
	var arch_top := 0.34
	var half_len := axle_abs + 0.36
	var window_half := 0.72

	var frame_items := []
	var spring_items := []
	var bolster_items := []
	var detail_items := []
	var brake_items := []
	var rubber_items := []
	var pocket_items := []
	var pocket_mat := Gfx.metal(Color(0.075, 0.072, 0.065), 0.9, 0.18)

	var spring_outer := _coil_spring(0.13, 0.28, 3.2, 0.016, 28)
	var spring_inner := _coil_spring(0.078, 0.275, 3.0, 0.014, 24)

	for side: float in [-1.0, 1.0]:
		var x := side * x_frame
		var spring_x := side * (x_frame + 0.08)
		# Top compression chord.
		frame_items.append([Forge.box(Vector3(0.22, 0.10, half_len * 2.0)),
				Transform3D(Basis(), Vector3(x, top, 0))])
		# Arched bottom chord: flat pedestal pads at the ends, rising to the
		# central spring plank between the axleboxes.
		var segments := 14
		for i in range(segments):
			var t := (float(i) + 0.5) / float(segments)
			var z := -half_len + t * half_len * 2.0
			var y := end_bottom + (arch_top - end_bottom) * smoothstep(0.0, 1.0, sin(PI * t))
			frame_items.append([Forge.box(Vector3(0.20, 0.10, half_len * 2.0 / float(segments) + 0.03)),
					Transform3D(Basis(), Vector3(x, y, z))])
		# Solid end panels around the axleboxes; the centre stays open so the
		# bolster springs are visible from the side.
		var end_profile := PackedVector2Array([
			Vector2(window_half, arch_top - 0.03),
			Vector2(half_len, end_bottom),
			Vector2(half_len, top),
			Vector2(window_half, top),
		])
		for sgn: float in [-1.0, 1.0]:
			var plate_basis := Basis(Vector3.UP, -sgn * PI * 0.5)
			var plate_x := side * (x_frame + (0.10 if sgn > 0.0 else 0.05))
			frame_items.append([Forge.extrude(end_profile, 0.05),
					Transform3D(plate_basis, Vector3(plate_x, 0, 0))])
			frame_items.append([Forge.box(Vector3(0.20, top - end_bottom, 0.10)),
					Transform3D(Basis(), Vector3(x, (top + end_bottom) * 0.5, sgn * half_len))])
		# Spring-window columns.
		for cz: float in [-window_half, window_half]:
			frame_items.append([Forge.box(Vector3(0.22, top - arch_top + 0.06, 0.13)),
					Transform3D(Basis(), Vector3(x, (top + arch_top) * 0.5, cz))])
			detail_items.append([Forge.box(Vector3(0.05, 0.30, 0.16)),
					Transform3D(Basis(), Vector3(x - side * 0.13, (top + arch_top) * 0.5, cz))])
		# Two coil nests sit directly on the arched bottom chord, so the lower
		# edge of the side frame stays visible through the spring window.
		for nest: float in [-0.48, 0.48]:
			frame_items.append([Forge.box(Vector3(0.40, 0.04, 0.44)),
					Transform3D(Basis(), Vector3(x, arch_top + 0.02, nest))])
			for dz: float in [-0.10, 0.10]:
				spring_items.append([spring_outer, Transform3D(Basis(),
						Vector3(spring_x, arch_top + 0.04, nest + dz))])
			spring_items.append([spring_inner, Transform3D(Basis(),
					Vector3(spring_x + side * 0.01, arch_top + 0.05, nest))])
			pocket_items.append([Forge.cylinder(0.18, 0.015, 18, 0.0, true, true),
					Transform3D(Basis(), Vector3(x, arch_top + 0.025, nest))])
		for cz: float in [-window_half, window_half]:
			spring_items.append([spring_inner, Transform3D(Basis(),
					Vector3(x - side * 0.10, arch_top + 0.05, cz))])
			frame_items.append([Forge.box(Vector3(0.16, 0.23, 0.15)),
					Transform3D(Basis(Vector3.BACK, side * 0.18),
							Vector3(x - side * 0.13, 0.67, cz))])
			detail_items.append([Forge.box(Vector3(0.05, 0.24, 0.17)),
					Transform3D(Basis(), Vector3(x - side * 0.21, 0.65, cz))])
			# Visible friction wedge and wear plate at the spring-window column.
			frame_items.append([Forge.box(Vector3(0.13, 0.22, 0.16)),
					Transform3D(Basis(Vector3.BACK, side * 0.42),
							Vector3(x + side * 0.12, 0.70, cz))])
			detail_items.append([Forge.box(Vector3(0.035, 0.26, 0.20)),
					Transform3D(Basis(), Vector3(x + side * 0.075, 0.68, cz))])
		# Axlebox covers sit on the end panels.
		for az: float in axle_z:
			var fx := side * (x_frame + 0.16)
			frame_items.append([Forge.box(Vector3(0.06, 0.56, 0.42)),
					Transform3D(Basis(), Vector3(fx, 0.42, az))])
			detail_items.append([Forge.cylinder(0.205, 0.025, 24, 0.0, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(fx + side * 0.04, 0.42, az))])
			detail_items.append([Forge.cylinder(0.165, 0.045, 24, 0.0, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(fx + side * 0.065, 0.42, az))])
			detail_items.append([Forge.cylinder(0.065, 0.055, 16, 0.0, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(fx + side * 0.095, 0.42, az))])
			for bz in range(6):
				var ba := TAU * float(bz) / 6.0
				detail_items.append([Forge.cylinder(0.016, 0.022, 8, 0.0, true, true),
						Transform3D(Basis(Vector3.BACK, PI * 0.5),
								Vector3(fx + side * 0.052, 0.42 + sin(ba) * 0.132, az + cos(ba) * 0.132))])
			rubber_items.append([Forge.box(Vector3(0.22, 0.10, 0.30)),
					Transform3D(Basis(), Vector3(x, 0.60, az))])
			pocket_items.append([Forge.cylinder(0.115, 0.016, 20, 0.0, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5),
							Vector3(fx + side * 0.02, 0.66, az))])
			detail_items.append([Forge.cylinder(0.135, 0.006, 20, 0.0, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5),
							Vector3(fx + side * 0.012, 0.66, az))])
		# Cross-brace support bosses.
		for cz: float in [-window_half, window_half]:
			frame_items.append([Forge.cylinder(0.08, 0.06, 14, 0.0, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5),
							Vector3(side * (x_frame + 0.06), 0.49, cz))])

	# Bolster: fish-belly centre beam with a deep centre bowl and side bearings.
	bolster_items.append([Forge.box(Vector3(2.14, 0.18, 0.58)),
			Transform3D(Basis(), Vector3(0, 0.69, 0))])
	bolster_items.append([Forge.box(Vector3(1.58, 0.11, 0.76)),
			Transform3D(Basis(), Vector3(0, 0.80, 0))])
	bolster_items.append([Forge.box(Vector3(0.72, 0.07, 0.90)),
			Transform3D(Basis(), Vector3(0, 0.86, 0))])
	bolster_items.append([Forge.cylinder(0.28, 0.07, 22, 0.0, true, true),
			Transform3D(Basis(), Vector3(0, 0.89, 0))])
	for side: float in [-1.0, 1.0]:
		bolster_items.append([Forge.box(Vector3(0.20, 0.10, 0.34)),
				Transform3D(Basis(), Vector3(side * 0.82, 0.84, 0))])
		detail_items.append([Forge.cylinder(0.10, 0.09, 14, 0.0, true, true),
				Transform3D(Basis(), Vector3(side * 0.82, 0.89, 0))])
		# Wedge pockets at the bolster ends.
		for wz: float in [-0.62, 0.62]:
			bolster_items.append([Forge.box(Vector3(0.18, 0.18, 0.18)),
					Transform3D(Basis(Vector3.BACK, side * 0.30),
							Vector3(side * 0.96, 0.66, wz))])
	# Two dark oval lightening recesses on the bolster top.
	for bx: float in [-0.38, 0.38]:
		detail_items.append([Forge.cylinder(0.16, 0.018, 20, 0.0, true, true),
				Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.55)),
						Vector3(bx, 0.895, 0))])
		pocket_items.append([Forge.cylinder(0.135, 0.008, 20, 0.0, true, true),
				Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.55)),
						Vector3(bx, 0.902, 0))])
	# Elastic lower cross bracing between the side frames.
	detail_items.append_array(Forge.tube_between(
			Vector3(-x_frame, 0.54, -0.62), Vector3(x_frame, 0.54, 0.62), 0.030, 7))
	detail_items.append_array(Forge.tube_between(
			Vector3(x_frame, 0.54, -0.62), Vector3(-x_frame, 0.54, 0.62), 0.030, 7))
	detail_items.append([Forge.box(Vector3(2.0, 0.09, 0.14)),
			Transform3D(Basis(), Vector3(0, 0.56, 0))])

	# Foundation brake gear: composite beams, shoes, middle rod, levers and cylinder.
	for raw: float in axle_z:
		var az := float(raw)
		var beam_z := az - signf(az) * 0.34
		brake_items.append([Forge.box(Vector3(1.90, 0.13, 0.16)),
				Transform3D(Basis(), Vector3(0, 0.30, beam_z))])
		for side: float in [-1.0, 1.0]:
			brake_items.append([Forge.box(Vector3(0.12, 0.32, 0.13)),
					Transform3D(Basis(), Vector3(side * 0.55, 0.40, az))])
			brake_items.append([Forge.box(Vector3(0.14, 0.10, 0.16)),
					Transform3D(Basis(), Vector3(side * 0.55, 0.24, beam_z))])
			detail_items.append_array(Forge.tube_between(
					Vector3(side * 0.90, 0.62, az), Vector3(side * 0.55, 0.35, beam_z), 0.022, 6))
			if passenger:
				brake_items.append([Forge.box(Vector3(0.12, 0.28, 0.12)),
						Transform3D(Basis(), Vector3(side * 0.72, 0.42, az + 0.30))])
	brake_items.append([Forge.box(Vector3(0.08, 0.10, 2.0)),
			Transform3D(Basis(), Vector3(0, 0.27, 0))])
	brake_items.append([Forge.box(Vector3(0.10, 0.52, 0.12)),
			Transform3D(Basis(), Vector3(0, 0.38, -0.76))])
	brake_items.append([Forge.box(Vector3(0.10, 0.52, 0.12)),
			Transform3D(Basis(), Vector3(0, 0.38, 0.76))])
	brake_items.append([Forge.cylinder(0.14, 0.62, 16, 0.0, true, true),
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.55, 0.52, 0.72))])
	brake_items.append([Forge.cylinder(0.10, 0.48, 14, 0.0, true, true),
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.55, 0.56, 0.72))])
	brake_items.append([Forge.box(Vector3(0.22, 0.16, 0.22)),
			Transform3D(Basis(), Vector3(0.55, 0.30, -0.62))])

	var frame_root := Node3D.new()
	frame_root.name = "BogieFrameRoot"
	bogie.add_child(frame_root)
	for item: Array in [
		[frame_items, cast, "SideFrames"],
		[spring_items, spring_mat, "BolsterSprings"],
		[bolster_items, bolster_mat, "Bolster"],
		[detail_items, steel, "BogieDetails"],
		[brake_items, dark, "BrakeRigging"],
		[rubber_items, rubber, "AxleboxRubberPads"],
		[pocket_items, pocket_mat, "CastLighteningPockets"],
	]:
		var items: Array = item[0]
		if items.is_empty():
			continue
		var mi := MeshInstance3D.new()
		mi.name = String(item[2])
		mi.mesh = Forge.merge_all(items)
		mi.material_override = item[1]
		frame_root.add_child(mi)
	for side: float in [-1.0, 1.0]:
		var tag := Label3D.new()
		tag.name = "BogieMarking"
		tag.text = "K6" if not passenger else "209P"
		tag.font_size = 18
		tag.pixel_size = 0.0018
		tag.modulate = Color(0.86, 0.83, 0.74)
		tag.outline_size = 2
		tag.outline_modulate = Color(0.08, 0.07, 0.06)
		tag.position = Vector3(side * 1.145, 0.66, -0.96)
		tag.rotation_degrees = Vector3(0, side * 90.0, 0)
		bogie.add_child(tag)
	for raw: float in axle_z:
		_add_bogie_wheelset(v, bogie, wheel_r, float(raw), passenger)
	v.bogie_frames.append(frame_root)
	return bogie


static func _build_freight_bogie_uncached(v: Vehicle, z_center: float, wheel_r: float, heavy: bool) -> Node3D:
	return _build_carriage_bogie(v, z_center, wheel_r, "k7" if heavy else "k6")


static func _legacy_build_freight_bogie_uncached(v: Vehicle, z_center: float, wheel_r: float, heavy: bool) -> Node3D:
	var bogie := Node3D.new()
	bogie.name = "Bogie"
	bogie.position = Vector3(0, 0, z_center)
	v.attach(bogie)

	var frame_mat := Gfx.metal(Color(0.27, 0.285, 0.305), 0.55, 0.56)
	var spring_mat := Gfx.metal(Color(0.55, 0.57, 0.59), 0.30, 0.82)
	var steel := Gfx.metal(Color(0.46, 0.48, 0.50), 0.30, 0.86)
	var dark := Gfx.metal(Color(0.10, 0.105, 0.115), 0.65, 0.4)
	var axle_z := [-1.25, 1.25]
	var x_frame := 1.04
	var spring_r := 0.16 if heavy else 0.14
	var spring_h := 0.38 if heavy else 0.33
	var spring := _coil_spring(spring_r, spring_h, 5.5, 0.019, 26)
	var inner_spring := _coil_spring(spring_r * 0.55, spring_h * 0.92, 5.0, 0.014, 22)
	var frame_items := []
	var spring_items := []
	var detail_items := []
	var brake_items := []

	for side: float in [-1.0, 1.0]:
		var x := side * x_frame
		for ez2: float in [-1.0, 1.0]:
			frame_items.append([Forge.rounded_box_x(1.15, 0.24, 0.16, 0.05),
					Transform3D(Basis(), Vector3(x, wheel_r + 0.56, ez2 * 0.95))])
		frame_items.append([Forge.rounded_box_x(0.8, 0.2, 0.12, 0.04),
				Transform3D(Basis(), Vector3(x, wheel_r + 0.66, 0))])
		frame_items.append([Forge.rounded_box_x(2.92, 0.2, 0.12, 0.04),
				Transform3D(Basis(), Vector3(x, wheel_r + 0.13, 0))])
		for az: float in axle_z:
			frame_items.append([Forge.box(Vector3(0.3, 0.5, 0.27)),
					Transform3D(Basis(), Vector3(x, wheel_r + 0.32, az))])
			frame_items.append([Forge.rounded_box_x(0.43, 0.34, 0.29, 0.05),
					Transform3D(Basis(), Vector3(x, wheel_r - 0.005, az))])
			detail_items.append([Forge.cylinder(0.105, 0.05, 14, 0.0, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5),
							Vector3(side * (x_frame + 0.19), wheel_r + 0.02, az))])
			for pz: float in [-0.17, 0.17]:
				spring_items.append([spring, Transform3D(Basis(),
						Vector3(side * (x_frame + 0.19), wheel_r + 0.17, az + pz))])
				spring_items.append([inner_spring, Transform3D(Basis(),
						Vector3(side * (x_frame + 0.19), wheel_r + 0.2, az + pz))])
			frame_items.append([Forge.box(Vector3(0.36, 0.075, 0.55)),
					Transform3D(Basis(), Vector3(side * (x_frame + 0.19), wheel_r + 0.57, az))])
			detail_items.append([Forge.cylinder(0.11, 0.03, 12, 0.0, true, true),
					Transform3D(Basis(), Vector3(side * (x_frame + 0.19), wheel_r + 0.62, az))])
		for z: float in [-0.53, 0.53]:
			frame_items.append([Forge.box(Vector3(0.24, 0.48, 0.2)),
					Transform3D(Basis(), Vector3(x, wheel_r + 0.36, z))])
		for z: float in [-0.48, 0.48]:
			frame_items.append([Forge.box(Vector3(0.2, 0.4, 0.24)),
					Transform3D(Basis(Vector3.RIGHT, side * 0.15),
							Vector3(side * (x_frame - 0.18), wheel_r + 0.48, z))])
		frame_items.append([Forge.box(Vector3(0.18, 0.1, 1.35)),
				Transform3D(Basis(), Vector3(side * (x_frame - 0.18), wheel_r + 0.7, 0))])

	for az: float in axle_z:
		brake_items.append([Forge.box(Vector3(1.95, 0.14, 0.16)),
				Transform3D(Basis(), Vector3(0, wheel_r + 0.06, az))])
		for side: float in [-1.0, 1.0]:
			brake_items.append([Forge.box(Vector3(0.11, 0.34, 0.18)),
					Transform3D(Basis(), Vector3(side * 0.56, wheel_r + 0.09, az))])
			brake_items.append([Forge.box(Vector3(0.22, 0.12, 0.1)),
					Transform3D(Basis(), Vector3(side * 0.56, wheel_r - 0.08, az))])
		detail_items.append_array(Forge.tube_between(
				Vector3(-0.9, wheel_r + 0.16, az),
				Vector3(0.9, wheel_r + 0.16, az), 0.025, 6))

	brake_items.append([Forge.cylinder(0.16, 0.6, 16, 0.0, true, true),
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.48, wheel_r + 0.2, 0.7))])
	brake_items.append([Forge.box(Vector3(0.3, 0.3, 0.24)),
			Transform3D(Basis(), Vector3(0.48, wheel_r + 0.2, 0.7))])
	detail_items.append_array(Forge.tube_between(
			Vector3(0.48, wheel_r + 0.2, 0.95),
			Vector3(0.48, wheel_r + 0.2, 1.3), 0.025, 6))
	detail_items.append_array(Forge.tube_between(
			Vector3(-1.3, wheel_r + 0.22, -0.6),
			Vector3(1.3, wheel_r + 0.22, -0.6), 0.022, 6))

	frame_items.append([Forge.box(Vector3(2.3, 0.28, 0.58)),
			Transform3D(Basis(), Vector3(0, wheel_r + 0.66, 0))])
	frame_items.append([Forge.box(Vector3(1.62, 0.17, 0.78)),
			Transform3D(Basis(), Vector3(0, wheel_r + 0.84, 0))])
	frame_items.append([Forge.cylinder(0.25, 0.12, 18, 0.0, true, true),
			Transform3D(Basis(), Vector3(0, wheel_r + 0.93, 0))])
	frame_items.append([Forge.cylinder(0.32, 0.1, 18, 0.0, true, true),
			Transform3D(Basis(), Vector3(0, wheel_r + 0.58, 0))])
	for side: float in [-1.0, 1.0]:
		frame_items.append([Forge.box(Vector3(0.18, 0.1, 0.4)),
				Transform3D(Basis(), Vector3(side * 0.74, wheel_r + 0.86, 0))])
		detail_items.append([Forge.cylinder(0.085, 0.18, 12, 0.0, true, true),
				Transform3D(Basis(), Vector3(side * 0.74, wheel_r + 0.77, 0))])
		frame_items.append_array(Forge.tube_between(
				Vector3(side * 1.08, wheel_r + 0.54, -1.52),
				Vector3(side * 1.08, wheel_r + 0.54, 1.52), 0.022, 6))
		for z: float in [-1.0, 0.0, 1.0]:
			detail_items.append([Forge.cylinder(0.025, 0.06, 8, -0.03, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5),
							Vector3(side * 1.12, wheel_r + 0.54, z))])

	var frame_root := Node3D.new()
	frame_root.name = "BogieFrameRoot"
	bogie.add_child(frame_root)
	var groups := [
		[frame_items, frame_mat, "BogieFrame"],
		[spring_items, spring_mat, "PrimarySprings"],
		[detail_items, steel, "BogieDetails"],
		[brake_items, dark, "BrakeRigging"],
	]
	for item: Array in groups:
		var items: Array = item [0]
		if items.is_empty():
			continue
		var mi := MeshInstance3D.new()
		mi.name = String(item [2])
		mi.mesh = Forge.merge_all(items)
		mi.material_override = item [1]
		frame_root.add_child(mi)
	for az: float in axle_z:
		_add_bogie_wheelset(v, bogie, wheel_r, az, false)
	v.bogie_frames.append(frame_root)
	return bogie


static func _build_passenger_bogie_uncached(v: Vehicle, z_center: float, wheel_r: float) -> Node3D:
	return _build_carriage_bogie(v, z_center, wheel_r, "p209")


static func _legacy_build_passenger_bogie_uncached(v: Vehicle, z_center: float, wheel_r: float) -> Node3D:
	var bogie := Node3D.new()
	bogie.name = "Bogie"
	bogie.position = Vector3(0, 0, z_center)
	v.attach(bogie)

	var frame_mat := Gfx.metal(Color(0.25, 0.27, 0.29), 0.48, 0.62)
	var spring_mat := Gfx.metal(Color(0.55, 0.57, 0.59), 0.28, 0.86)
	var steel := Gfx.metal(Color(0.52, 0.54, 0.56), 0.26, 0.9)
	var dark := Gfx.metal(Color(0.1, 0.105, 0.115), 0.6, 0.45)
	var axle_z := [-1.22, 1.22]
	var x_frame := 1.0
	var spring := _coil_spring(0.14, 0.34, 5.5, 0.018, 26)
	var secondary := _coil_spring(0.18, 0.3, 4.8, 0.02, 26)
	var frame_items := []
	var spring_items := []
	var detail_items := []
	var brake_items := []

	for side: float in [-1.0, 1.0]:
		var x := side * x_frame
		frame_items.append([Forge.rounded_box_x(2.95, 0.2, 0.15, 0.05),
				Transform3D(Basis(), Vector3(x, wheel_r + 0.54, 0))])
		frame_items.append([Forge.rounded_box_x(2.85, 0.18, 0.11, 0.04),
				Transform3D(Basis(), Vector3(x, wheel_r + 0.12, 0))])
		for az: float in axle_z:
			frame_items.append([Forge.box(Vector3(0.26, 0.44, 0.25)),
					Transform3D(Basis(), Vector3(x, wheel_r + 0.3, az))])
			frame_items.append([Forge.rounded_box_x(0.4, 0.3, 0.27, 0.05),
					Transform3D(Basis(), Vector3(x, wheel_r, az))])
			detail_items.append([Forge.cylinder(0.1, 0.06, 14, 0.0, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5),
							Vector3(side * (x_frame + 0.16), wheel_r + 0.02, az))])
			for pz: float in [-0.15, 0.15]:
				spring_items.append([spring, Transform3D(Basis(),
						Vector3(side * (x_frame + 0.17), wheel_r + 0.2, az + pz))])
			frame_items.append([Forge.box(Vector3(0.32, 0.07, 0.5)),
					Transform3D(Basis(), Vector3(side * (x_frame + 0.17), wheel_r + 0.56, az))])
			brake_items.append([Forge.box(Vector3(0.1, 0.3, 0.14)),
					Transform3D(Basis(), Vector3(side * 0.82, wheel_r + 0.12, az - 0.35))])
			brake_items.append([Forge.cylinder(0.1, 0.08, 12, 0.0, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5),
							Vector3(side * 0.7, wheel_r + 0.12, az - 0.35))])
		for pz: float in [-0.55, 0.55]:
			spring_items.append([secondary, Transform3D(Basis(),
					Vector3(side * 0.72, wheel_r + 0.58, pz))])
		frame_items.append([Forge.box(Vector3(0.18, 0.08, 1.2)),
				Transform3D(Basis(), Vector3(side * 0.72, wheel_r + 0.93, 0))])

	frame_items.append([Forge.box(Vector3(2.2, 0.24, 0.54)),
			Transform3D(Basis(), Vector3(0, wheel_r + 0.72, 0))])
	frame_items.append([Forge.box(Vector3(1.5, 0.16, 0.7)),
			Transform3D(Basis(), Vector3(0, wheel_r + 0.9, 0))])
	frame_items.append([Forge.cylinder(0.24, 0.12, 18, 0.0, true, true),
			Transform3D(Basis(), Vector3(0, wheel_r + 0.98, 0))])
	for side: float in [-1.0, 1.0]:
		frame_items.append([Forge.box(Vector3(0.16, 0.1, 0.36)),
				Transform3D(Basis(), Vector3(side * 0.7, wheel_r + 0.95, 0))])
		detail_items.append([Forge.cylinder(0.08, 0.16, 12, 0.0, true, true),
				Transform3D(Basis(), Vector3(side * 0.7, wheel_r + 0.87, 0))])
		frame_items.append_array(Forge.tube_between(
				Vector3(side * 1.02, wheel_r + 0.55, -1.0),
				Vector3(side * 1.02, wheel_r + 0.55, 1.0), 0.03, 8))
		brake_items.append_array(Forge.tube_between(
				Vector3(side * 0.95, wheel_r + 0.7, 0.75),
				Vector3(-side * 0.95, wheel_r + 0.7, -0.75), 0.02, 6))

	frame_items.append([Forge.box(Vector3(1.8, 0.1, 0.16)),
			Transform3D(Basis(), Vector3(0, wheel_r + 0.1, -0.95))])
	frame_items.append([Forge.box(Vector3(1.8, 0.1, 0.16)),
			Transform3D(Basis(), Vector3(0, wheel_r + 0.1, 0.95))])

	var frame_root := Node3D.new()
	frame_root.name = "BogieFrameRoot"
	bogie.add_child(frame_root)
	for item: Array in [
		[frame_items, frame_mat, "BogieFrame"],
		[spring_items, spring_mat, "Springs"],
		[detail_items, steel, "BogieDetails"],
		[brake_items, dark, "DiscBrakes"],
	]:
		var items: Array = item [0]
		if items.is_empty():
			continue
		var mi := MeshInstance3D.new()
		mi.name = String(item [2])
		mi.mesh = Forge.merge_all(items)
		mi.material_override = item [1]
		frame_root.add_child(mi)
	for az: float in axle_z:
		_add_bogie_wheelset(v, bogie, wheel_r, az, true)
	v.bogie_frames.append(frame_root)
	return bogie


static func _wheel_mesh(r: float) -> ArrayMesh:
	var items := []

	items.append([Forge.cylinder(r, 0.135, 26, - 0.0675, true, true), Transform3D()])

	items.append([Forge.cylinder(r * 0.42, 0.16, 14, - 0.08, true, true), Transform3D()])

	items.append([Forge.cylinder(r * 0.8, 0.055, 20, - 0.0275, true, true), Transform3D()])

	var mesh := Forge.merge_all(items)

	var flange := Forge.cylinder(r + 0.022, 0.03, 26, - 0.015, false, false)
	return Forge.merge(mesh, flange)


static func _pantograph(v: Vehicle, xf: Transform3D) -> Node3D:
	var base := Node3D.new()
	base.name = "Pantograph"
	base.transform = xf
	v.attach(base)

	var dark := Gfx.metal(Color(0.2, 0.21, 0.22), 0.55, 0.7)
	var steel := Gfx.metal(Color(0.55, 0.56, 0.58), 0.35, 0.95)


	var base_items := []
	base_items.append([Forge.box(Vector3(1.65, 0.08, 1.15)), Transform3D(Basis(), Vector3(0, 0.04, 0))])
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			base_items.append([Forge.cylinder(0.085, 0.34, 10, 0.0, true, true),
					Transform3D(Basis(), Vector3(sx * 0.62, 0.08, sz * 0.44))])
	var base_mi := MeshInstance3D.new()
	base_mi.mesh = Forge.merge_all(base_items)
	base_mi.material_override = dark
	base.add_child(base_mi)


	var arm := Node3D.new()
	arm.name = "PantographArm"
	arm.position = Vector3(0, 0.42, 0)
	base.add_child(arm)

	var items := []
	var lower_joint := Vector3(0, 0.0, 0.62)
	var knee := Vector3(0, 0.72, -0.45)
	var head := Vector3(0, 0.98, 0.1)
	for side: float in [-1.0, 1.0]:
		items.append_array(Forge.tube_between(Vector3(side * 0.42, 0, 0.62), Vector3(side * 0.3, 0.7, -0.4), 0.035, 8))
		items.append_array(Forge.tube_between(Vector3(side * 0.3, 0.7, -0.4), Vector3(side * 0.22, 0.98, 0.1), 0.028, 8))

	items.append([Forge.box(Vector3(0.1, 0.05, 1.55)), Transform3D(Basis(Vector3.UP, 0.0), Vector3(-1.0, 1.02, 0.1))])
	items.append([Forge.box(Vector3(0.06, 0.06, 1.75)), Transform3D(Basis(), Vector3(0, 1.04, 0.1))])
	var arm_mi := MeshInstance3D.new()
	arm_mi.mesh = Forge.merge_all(items)
	arm_mi.material_override = steel
	arm.add_child(arm_mi)
	return base


const C_FX_BODY := Color(0.898, 0.91, 0.926)
const C_FX_RED := Color(0.78, 0.115, 0.098)
const C_FX_ORANGE := Color(0.905, 0.52, 0.14)
const C_FX_ROOF := Color(0.455, 0.475, 0.5)
const C_FX_SKIRT := Color(0.2, 0.212, 0.228)
const C_FX_GLASS := Color(0.05, 0.078, 0.1)


static func _emu_section(hw: float, y0: float, y1: float, corner: float, segs := 5) -> PackedVector2Array:
	var prof := PackedVector2Array()
	var c := minf(corner, minf(hw, y1 - y0) * 0.8)
	for i in range(segs + 1):
		var a := PI * 0.5 * float(i) / float(segs)
		prof.append(Vector2(hw - c + cos(a) * c, y1 - c + sin(a) * c))
	for i in range(segs + 1):
		var a := PI * 0.5 + PI * 0.5 * float(i) / float(segs)
		prof.append(Vector2(- hw + c + cos(a) * c, y1 - c + sin(a) * c))
	prof.append(Vector2(- hw, y0))
	prof.append(Vector2(hw, y0))
	return prof

const FX_Y0 := 1.06
const FX_Y1 := 3.96
const FX_YWIN0 := 2.72
const FX_YWIN1 := 3.46
const FX_YBAND0 := 2.12
const FX_YBAND1 := 2.62


static func fuxing_car(cab := false, panto := false, livery := "cr400af") -> Vehicle:
	var v := Vehicle.new()
	v.name = "FuxingCar"
	v.length = 25.5
	v.width = 3.36
	v.height = 4.06
	v.bogie_spacing = 17.5
	v.wheel_radius = 0.43
	v.mass_empty = 47.0
	v.mass_loaded = 57.0
	v.kind = "emu"
	v.designation = "复兴号CR400AF"
	v.max_speed = 200.0
	v.brake_force = 2.2
	v.set_loaded(true)

	var body_col := C_FX_BODY
	var band_col := C_FX_RED
	var accent_col := C_FX_ORANGE
	var roof_col := C_FX_ROOF
	var skirt_col := C_FX_SKIRT
	if livery == "intercity":
		body_col = Color(0.84, 0.88, 0.93)
		band_col = Color(0.055, 0.22, 0.52)
		accent_col = Color(0.93, 0.6, 0.16)
		roof_col = Color(0.36, 0.39, 0.43)
		skirt_col = Color(0.16, 0.18, 0.21)
		v.designation = "城际动车组"
		v.name = "IntercityCar"
	var body_mat := _paint(body_col)
	var red_mat := _paint(band_col)
	var org_mat := _paint(accent_col)
	var roof_mat := Gfx.metal(roof_col, 0.5, 0.68)
	var skirt_mat := Gfx.metal(skirt_col, 0.62, 0.55)
	var dark_mat := Gfx.metal(Color(0.115, 0.125, 0.14), 0.6, 0.5)
	var glass_dark := Gfx.glass(C_FX_GLASS, 0.05, 0.7)
	var glass_clear := Gfx.glass(C_FX_GLASS, 0.03, 0.2)


	var glass_ws := StandardMaterial3D.new()
	glass_ws.albedo_color = Color(0.06, 0.08, 0.12, 0.3)
	glass_ws.roughness = 0.05
	glass_ws.metallic = 0.3
	glass_ws.metallic_specular = 0.9
	glass_ws.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_ws.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass_ws.rim_enabled = true
	glass_ws.rim = 0.5

	var glass_front := StandardMaterial3D.new()
	glass_front.albedo_color = Color(0.62, 0.7, 0.78, 0.16)
	glass_front.roughness = 0.04
	glass_front.metallic = 0.22
	glass_front.metallic_specular = 0.95
	glass_front.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_front.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass_front.rim_enabled = true
	glass_front.rim = 0.55
	var grey_mat := Gfx.paint(Color(0.64, 0.65, 0.67), 0.45, 0.28, 0.4)
	var dark_band_mat := Gfx.paint(Color(0.045, 0.05, 0.062), 0.32, 0.15, 0.35)
	var frame_mat := Gfx.metal(Color(0.28, 0.29, 0.31), 0.35, 0.7)
	var trim_mat := Gfx.metal(Color(0.36, 0.38, 0.41), 0.35, 0.75)

	var hw := v.width * 0.5
	var half := 12.25
	var nose_len := 3.9 if livery == "intercity" else 4.6
	var straight_z := - half + nose_len


	var sect := _emu_section(hw, FX_Y0, FX_Y1, 0.44)
	var ws_lo := 2.34
	var ws_hi := 3.18
	if cab:
		v.part(Forge.extrude(sect, half - straight_z, true, false), body_mat,
				Transform3D(Basis(), Vector3(0, 0, straight_z)), "Carbody")
		var body_sheet := Gfx.sheet(body_col, 0.3, 0.32)

		var lining_mat := Gfx.sheet(Color(0.7, 0.71, 0.735), 0.62, 0.06)


		var nsegs := [
			[0.0, 0.42, ws_lo, ws_hi, false, false],
			[0.42, 0.78, 1.95, 3.38, false, false],
			[0.78, 1.0, 1.55, 3.62, true, true],
		]
		for s: Array in nsegs:
			var t0: float = s [0]
			var t1: float = s [1]
			var ylo: float = s [2]
			var yhi: float = s [3]
			var closed: bool = s [4]
			var darklow: bool = s [5]
			var st := maxi(2, int(round(18.0 *(t1 - t0))))
			var nf := _nose_frames(straight_z, nose_len, st, 1.0, t0, t1)


			v.part(Forge.loft(_emu_lower_band(hw, FX_Y0, ylo), nf, closed, false),
					dark_mat if darklow else body_sheet, Transform3D(), "NoseLower")
			v.part(Forge.loft(_emu_upper_band(hw, FX_Y1, 0.44, yhi), nf, closed, false),
					body_sheet, Transform3D(), "NoseUpper")

			var gsect := _emu_section(hw * 0.994, ylo + 0.01, yhi - 0.01, 0.3)
			v.part(Forge.loft(gsect, nf, true, false), glass_ws, Transform3D(), "Windshield")

			var nfr := _nose_frames(straight_z, nose_len, st, 0.955, t0, t1)
			var low_r := _emu_lower_band(hw, FX_Y0, ylo)
			var up_r := _emu_upper_band(hw, FX_Y1, 0.44, yhi)
			low_r.reverse()
			up_r.reverse()
			v.part(Forge.loft(low_r, nfr, false, false), lining_mat, Transform3D(), "CabLowerTrim")
			v.part(Forge.loft(up_r, nfr, false, false), lining_mat, Transform3D(), "CabCeilTrim")

		var ti := _nose_frames(straight_z, nose_len, 1, 1.0, 0.995, 1.0)
		var ti_g := _nose_frames(straight_z, nose_len, 1, 0.994, 0.995, 1.0)
		v.part(Forge.loft(_emu_lower_band(hw, FX_Y0, 1.55), ti, false, true), dark_mat,
				Transform3D(), "NoseTipLow")
		v.part(Forge.loft(_emu_upper_band(hw, FX_Y1, 0.44, 3.62), ti, false, true), body_sheet,
				Transform3D(), "NoseTipTop")
		v.part(Forge.loft(_emu_section(hw * 0.994, 1.56, 3.61, 0.3), ti_g, true, true), glass_front,
				Transform3D(), "WindshieldPane")

		var stripe_frames := _nose_frames(straight_z, nose_len, 16, 1.006)
		v.part(Forge.loft(_band_profile(hw, FX_YBAND0, FX_YBAND1), stripe_frames, true, false), red_mat,
				Transform3D(), "NoseRedBand")
		var orange_frames := _nose_frames(straight_z, nose_len, 16, 1.008)
		v.part(Forge.loft(_band_profile(hw, FX_YBAND0 - 0.11, FX_YBAND0 - 0.055), orange_frames, true, false),
				org_mat, Transform3D(), "NoseOrangeLine")
		var canopy_frames := _nose_frames(straight_z, nose_len, 10, 1.004, 0.0, 0.72)
		v.part(Forge.loft(_band_profile(hw, 3.24, 3.56), canopy_frames, true, false), dark_band_mat,
				Transform3D(), "NoseCanopy")
		var chin_frames := _nose_frames(straight_z, nose_len, 12, 1.004)
		v.part(Forge.loft(_band_profile(hw, FX_Y0 - 0.02, FX_Y0 + 0.16), chin_frames, true, false), dark_mat,
				Transform3D(), "NoseChin")
		var wiper_items := []
		for sx: float in [-0.55, 0.55]:
			var wf := _nose_frame(straight_z, nose_len, 0.2)
			wiper_items.append([Forge.box(Vector3(0.035, 0.58, 0.02)),
					wf * Transform3D(Basis(Vector3.RIGHT, deg_to_rad(22.0)), Vector3(sx, 2.86, 0.06))])
		v.merged(wiper_items, Gfx.rubber(Color(0.03, 0.03, 0.035), 0.85), "Wipers")
		var mirror_items := []
		for side: float in [-1.0, 1.0]:
			mirror_items.append([Forge.box(Vector3(0.08, 0.18, 0.18)),
					Transform3D(Basis(), Vector3(side *(hw - 0.01), 3.04, straight_z + 0.55))])
			mirror_items.append_array(Forge.tube_between(
					Vector3(side *(hw - 0.18), 3.02, straight_z + 0.55),
					Vector3(side *(hw + 0.38), 3.08, straight_z + 0.55), 0.028, 8))
			mirror_items.append([Forge.box(Vector3(0.1, 0.26, 0.16)),
					Transform3D(Basis(), Vector3(side *(hw + 0.44), 3.0, straight_z + 0.55))])
		v.merged(mirror_items, dark_mat, "Mirrors")
		var df := _nose_frame(straight_z, nose_len, 0.3)
		v.part(Forge.box(Vector3(1.1, 0.16, 0.03)),
				Gfx.emissive(Color(1.0, 0.55, 0.15), 1.4, Color(0.02, 0.02, 0.03)),
				df * Transform3D(Basis(), Vector3(0, 3.43, 0.06)), "Destination")

		v.part(Forge.box(Vector3(0.98, 0.34, 0.34)), dark_mat,
				Transform3D(Basis(), Vector3(0, FX_Y0 + 0.22, - half - 0.44)), "CouplerFairing")
	else:
		v.part(Forge.extrude(sect, half * 2.0, true, true), body_mat,
				Transform3D(Basis(), Vector3(0, 0, - half)), "Carbody")


	var win_frame_mesh := _panel_mesh(1.52, 0.84, 0.12, 0.014)
	var win_glass_mesh := _panel_mesh(1.44, 0.76, 0.10, 0.012)
	var win_sill_mesh := Forge.box(Vector3(0.035, 0.035, 1.56))
	var cab_win_frame := _panel_mesh(1.2, 0.82, 0.11, 0.014)
	var cab_win_glass := _panel_mesh(1.12, 0.74, 0.1, 0.012)
	var door_zs: Array = [7.4] if cab else [-7.4, 7.4]
	var band0 :=(straight_z + 0.15) if cab else(- half + 0.15)
	var band1 := half - 0.15
	for side: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(0.012, 0.84, band1 - band0)), dark_band_mat,
				Transform3D(Basis(), Vector3(side *(hw - 0.004), 3.09,(band0 + band1) * 0.5)), "WindowBand")
		var frame_items := []
		var glass_items := []
		var sill_items := []
		var z := (straight_z + 1.75) if cab else(- half + 1.75)
		while z <= half - 1.55:
			var near_door := false
			for dz in door_zs:
				if absf(z - float(dz)) < 1.25:
					near_door = true
			if not near_door:
				frame_items.append([win_frame_mesh, _side_xf(side, hw - 0.008, 2.98, z)])
				glass_items.append([win_glass_mesh, _side_xf(side, hw + 0.002, 2.98, z)])
				sill_items.append([win_sill_mesh, _side_xf(side, hw + 0.002, 2.49, z)])
			z += 2.18
		if cab:
			frame_items.append([cab_win_frame, _side_xf(side, hw - 0.008, 3.02, straight_z + 0.85)])
			glass_items.append([cab_win_glass, _side_xf(side, hw + 0.002, 3.02, straight_z + 0.85)])
		v.merged(frame_items, frame_mat, "WindowFrames")
		v.merged(glass_items, glass_dark, "WindowGlass")
		v.merged(sill_items, trim_mat, "WindowSills")

		var rb0 :=(straight_z + 0.12) if cab else(- half + 0.08)
		var rb1 := half - 0.06
		v.part(Forge.box(Vector3(0.018, FX_YBAND1 - FX_YBAND0, rb1 - rb0)), red_mat,
				Transform3D(Basis(), Vector3(side *(hw + 0.004),(FX_YBAND0 + FX_YBAND1) * 0.5,(rb0 + rb1) * 0.5)), "RedBand")
		v.part(Forge.box(Vector3(0.012, 0.055, rb1 - rb0)), org_mat,
				Transform3D(Basis(), Vector3(side *(hw + 0.004), FX_YBAND0 - 0.055,(rb0 + rb1) * 0.5)), "OrangeLine")

		for dz in door_zs:
			_emu_door(v, side, float(dz), body_mat, glass_clear, red_mat, dark_mat)


	var skirt_items := []
	var bs := v.bogie_spacing * 0.5
	var skirt_segments := [
		[- half + 0.15, - bs - 2.35],
		[- bs + 2.35, bs - 2.35],
		[bs + 2.35, half - 0.15],
	]
	for side: float in [-1.0, 1.0]:
		for seg in skirt_segments:
			var z0: float = seg [0]
			var z1: float = seg [1]
			if z1 - z0 < 0.3:
				continue
			skirt_items.append([Forge.box(Vector3(0.05, 0.27, z1 - z0)),
					Transform3D(Basis(), Vector3(side *(hw - 0.025), 1.04,(z0 + z1) * 0.5))])
	v.merged(skirt_items, skirt_mat, "SideSkirts")
	var under := []
	for z: float in [-6.2, -1.4, 3.2]:
		under.append([Forge.box(Vector3(2.2, 0.4, 2.0)), Transform3D(Basis(), Vector3(0, FX_Y0 - 0.32, z))])
	for z: float in [-9.2, 5.9]:
		under.append([Forge.cylinder(0.26, 1.7, 14, 0.0, true, true),
				Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, FX_Y0 - 0.25, z - 0.85))])
	v.merged(under, Gfx.metal(Color(0.23, 0.24, 0.25), 0.6, 0.5), "UnderEquipment")


	v.part(Forge.box(Vector3(3.1, 0.06,(half - 0.35) * 2.0)), roof_mat,
			Transform3D(Basis(), Vector3(0, FX_Y1 + 0.02, 0)), "Roof")
	var roof_items := []
	for z: float in [-5.4, 3.0]:
		roof_items.append([Forge.rounded_box_x(3.4, 2.42, 0.34, 0.12),
				Transform3D(Basis(), Vector3(0, FX_Y1 + 0.04, z))])
		for dz: float in [-1.0, 1.0]:
			roof_items.append([Forge.cylinder(0.16, 0.05, 12, 0.0, true, true),
					Transform3D(Basis(), Vector3(0, FX_Y1 + 0.38, z + dz))])
	roof_items.append([Forge.box(Vector3(0.9, 0.08,(half - 1.2) * 2.0)),
			Transform3D(Basis(), Vector3(0.78, FX_Y1 + 0.08, 0))])
	roof_items.append([Forge.box(Vector3(0.9, 0.08,(half - 1.2) * 2.0)),
			Transform3D(Basis(), Vector3(-0.78, FX_Y1 + 0.08, 0))])
	v.merged(roof_items, Gfx.metal(Color(0.5, 0.52, 0.55), 0.55, 0.55), "RoofEquipment")
	v.part(Forge.cylinder(0.02, 0.45, 6, 0.0, true, true), Gfx.metal(Color(0.7, 0.72, 0.75), 0.3, 0.9),
			Transform3D(Basis(), Vector3(0.9, FX_Y1 + 0.08, straight_z + 1.5)), "Antenna")

	v.part(Forge.box(Vector3(0.16, 0.07,(half - 1.6) * 2.0)), Gfx.rubber(Color(0.1, 0.1, 0.11), 0.8),
			Transform3D(Basis(Vector3.UP, 0.0), Vector3(hw - 0.55, FX_Y1 + 0.12, 0)), "RoofCableL")
	v.part(Forge.box(Vector3(0.16, 0.07,(half - 1.6) * 2.0)), Gfx.rubber(Color(0.1, 0.1, 0.11), 0.8),
			Transform3D(Basis(Vector3.UP, 0.0), Vector3(- hw + 0.55, FX_Y1 + 0.12, 0)), "RoofCableR")


	var gangway_ends: Array [float] = []
	gangway_ends.append(1.0)
	if not cab:
		gangway_ends.append(-1.0)
	for end: float in gangway_ends:
		v.part(Forge.box(Vector3(1.6, 2.35, 0.42)), dark_mat,
				Transform3D(Basis(), Vector3(0, 2.1, end *(half + 0.18))), "Gangway")


	if cab:

		for side: float in [-1.0, 1.0]:
			var lf := _nose_frame(straight_z, nose_len, 0.6)
			var p := lf * Vector3(side *(hw + 0.03), 1.62, -0.06)
			v.part(Forge.box(Vector3(0.56, 0.17, 0.12)), Gfx.emissive(Color(1.0, 0.96, 0.86), 9.0, Color(0.92, 0.92, 0.9)),
					Transform3D(lf.basis, p), "HeadLamp")
			var p2 := lf * Vector3(side *(hw + 0.03), 1.9, -0.06)
			v.part(Forge.box(Vector3(0.26, 0.12, 0.1)), Gfx.emissive(Color(1.0, 0.28, 0.2), 1.6),
					Transform3D(lf.basis, p2), "MarkerLamp")

		for side: float in [-1.0, 1.0]:
			var lamp := SpotLight3D.new()
			lamp.position = Vector3(side * 1.15, 1.66, - half + 1.55)
			lamp.light_color = Color(1.0, 0.97, 0.88)
			lamp.light_energy = 30.0
			lamp.spot_range = 360.0
			lamp.spot_angle = 30.0
			lamp.spot_attenuation = 0.6
			lamp.rotation_degrees = Vector3(-0.6, 0, 0)
			v.attach(lamp)
			v.head_lights.append(lamp)
		_fill_light(v, Vector3(0.0, 1.55, - half + 1.4), Color(1.0, 0.97, 0.88))


	_build_bogie(v, - v.bogie_spacing * 0.5, 0.43, 2, 2.5)
	_build_bogie(v, v.bogie_spacing * 0.5, 0.43, 2, 2.5)
	if panto:
		v.pantographs.append(_pantograph(v, Transform3D(Basis(), Vector3(0, FX_Y1 + 0.24, -2.6))))
		v.pantographs.append(_pantograph(v, Transform3D(Basis(), Vector3(0, FX_Y1 + 0.24, 2.6))))
		v.pantographs [1].visible = false
	if cab:
		_coupler(v, half + 0.62, dark_mat, 0.85)
	else:
		_coupler(v, - half - 0.62, dark_mat, 0.85)
		_coupler(v, half + 0.62, dark_mat, 0.85)


	if cab:
		cab_interior(v, 1.14, straight_z - 2.95, straight_z + 1.35, hw - 0.16, -0.72,
			{"hw": hw, "nose_len": nose_len, "straight_z": straight_z}, "intercity" if livery == "intercity" else "emu")
		for child in v.body_root().get_children():
			if child is GeometryInstance3D:
				var nm := String(child.name)
				child.layers = 2
				if nm.begins_with("Cab") and not nm in ["CabMask", "CabRoof", "CabUnderframe", "CabFrontLower", "CabFrontUpper", "CabSideLower", "CabSideUpper"]:
					child.layers = 1
				elif nm.begins_with("Dev"):
					child.layers = 1

	return v


static func intercity_car(cab := false, panto := false) -> Vehicle:
	return fuxing_car(cab, panto, "intercity")


static func _nose_scale(t: float) -> Vector3:
	var sx := 1.0 - 0.70 * pow(t, 2.15)
	var sy := 1.0 - 0.31 * pow(t, 2.35)
	var dy := 0.34 * pow(t, 2.7)
	return Vector3(maxf(sx, 0.1), maxf(sy, 0.3), dy)


static func _emu_lower_band(hw: float, y0: float, y_lo: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(- hw, y_lo), Vector2(- hw, y0), Vector2(hw, y0), Vector2(hw, y_lo)])


static func _emu_upper_band(hw: float, y1: float, corner: float, y_hi: float, segs := 5) -> PackedVector2Array:
	var c := minf(corner, minf(hw, y1 - y_hi) * 0.8)
	var pts := PackedVector2Array()
	pts.append(Vector2(hw, y_hi))
	pts.append(Vector2(hw, y1 - c))
	for i in range(segs + 1):
		var a := PI * 0.5 * float(i) / float(segs)
		pts.append(Vector2(hw - c + cos(a) * c, y1 - c + sin(a) * c))
	for i in range(segs + 1):
		var a := PI * 0.5 + PI * 0.5 * float(i) / float(segs)
		pts.append(Vector2(- hw + c + cos(a) * c, y1 - c + sin(a) * c))
	pts.append(Vector2(- hw, y1 - c))
	pts.append(Vector2(- hw, y_hi))
	return pts


static func _nose_frames(straight_z: float, nose_len: float, steps: int, scale := 1.0,
		t0 := 0.0, t1 := 1.0) -> Array [Transform3D]:
	var out: Array [Transform3D] = []
	for i in range(steps + 1):
		var t := lerpf(t0, t1, float(i) / float(steps))
		var s := _nose_scale(t)
		var sy := s.y * scale
		out.append(Transform3D(Basis().scaled(Vector3(s.x * scale, sy, 1.0)),
				Vector3(0.0, FX_Y0 *(1.0 - sy) + s.z, straight_z - nose_len * t)))
	return out


static func _nose_mesh(sect: PackedVector2Array, straight_z: float, nose_len: float) -> ArrayMesh:
	var frames: Array [Transform3D] = []
	var steps := 12
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var s := _nose_scale(t)
		frames.append(Transform3D(Basis().scaled(Vector3(s.x, s.y, 1.0)),
				Vector3(0.0, FX_Y0 *(1.0 - s.y) + s.z, straight_z - nose_len * t)))
	return Forge.loft(sect, frames, true, true)


static func _nose_frame(straight_z: float, nose_len: float, t: float) -> Transform3D:
	var s := _nose_scale(t)
	return Transform3D(Basis().scaled(Vector3(s.x, s.y, 1.0)),
			Vector3(0.0, FX_Y0 *(1.0 - s.y) + s.z, straight_z - nose_len * t))


static func _emu_door(v: Vehicle, side: float, z: float, body_mat: Material,
		glass: Material, red_mat: Material, dark_mat: Material) -> void:
	var hw := v.width * 0.5
	var frame_mat := Gfx.metal(Color(0.55, 0.57, 0.6), 0.28, 0.7)

	v.part(_panel_mesh(1.56, 2.5, 0.08, 0.02), dark_mat,
			_side_xf(side, hw - 0.055, 2.2, z), "DoorRecess")
	var trim := []
	trim.append([Forge.box(Vector3(0.035, 0.06, 1.64)), _side_xf(side, hw + 0.002, 3.46, z)])
	trim.append([Forge.box(Vector3(0.035, 0.06, 1.64)), _side_xf(side, hw + 0.002, 0.96, z)])
	for dz: float in [-0.81, 0.81]:
		trim.append([Forge.box(Vector3(0.035, 2.56, 0.06)), _side_xf(side, hw + 0.002, 2.21, z + dz)])
	trim.append([Forge.box(Vector3(0.18, 0.03, 1.68)), _side_xf(side, hw - 0.02, 0.93, z)])
	v.merged(trim, frame_mat, "DoorTrim")

	for k in range(2):
		var off := -0.355 if k == 0 else 0.355
		var leaf := Node3D.new()
		leaf.name = "DoorLeaf%d" %k
		leaf.position = Vector3(side *(hw - 0.02), 2.2, z + off)
		leaf.rotation.y = side * PI * 0.5
		v.attach(leaf)
		leaf.set_meta("closed_pos", leaf.position)
		leaf.set_meta("open_delta", Vector3(0, 0, off * 2.0))
		var leaf_mi := MeshInstance3D.new()
		leaf_mi.mesh = _panel_mesh(0.70, 2.42, 0.08, 0.045)
		leaf_mi.material_override = body_mat
		leaf.add_child(leaf_mi)
		var gl := MeshInstance3D.new()
		gl.mesh = _panel_mesh(0.56, 1.12, 0.07, 0.012)
		gl.material_override = glass
		gl.position = Vector3(0, 0.52, 0.045)
		leaf.add_child(gl)
		var band := MeshInstance3D.new()
		band.mesh = _panel_mesh(0.70, 0.5, 0.02, 0.014)
		band.material_override = red_mat
		band.position = Vector3(0, 0.17, 0.042)
		leaf.add_child(band)
		var handle := MeshInstance3D.new()
		handle.mesh = Forge.box(Vector3(0.03, 0.2, 0.03))
		handle.material_override = frame_mat
		handle.position = Vector3(0, -0.08, 0.06)
		leaf.add_child(handle)
		v.door_leaves.append(leaf)




static func cab_interior(v: Vehicle, y_floor: float, z_front: float, z_back: float, hw_in: float,
		seat_x: float, nose: Dictionary = {}, style := "emu") -> void:
	var wall_col := Color(0.62, 0.65, 0.69)
	var desk_col := Color(0.17, 0.19, 0.22)
	var seat_col := Color(0.09, 0.13, 0.24)
	var accent_col := Color(0.9, 0.48, 0.18)
	var trim_col := Color(0.42, 0.45, 0.49)
	if style == "electric":
		wall_col = Color(0.52, 0.55, 0.58)
		desk_col = Color(0.14, 0.16, 0.17)
		seat_col = Color(0.15, 0.18, 0.16)
		accent_col = Color(0.85, 0.58, 0.16)
	elif style == "diesel":
		wall_col = Color(0.6, 0.57, 0.5)
		seat_col = Color(0.16, 0.12, 0.08)
		accent_col = Color(0.55, 0.62, 0.25)
	elif style == "intercity":
		wall_col = Color(0.72, 0.75, 0.79)
		seat_col = Color(0.12, 0.18, 0.3)
		accent_col = Color(0.12, 0.42, 0.72)
	var m_wall := Gfx.interior_panel(wall_col, 0.62)
	var m_dark := Gfx.metal(desk_col, 0.5, 0.4)
	var m_desk := Gfx.interior_panel(desk_col.lightened(0.05), 0.42)
	var m_seat := Gfx.leather(seat_col, 0.48)
	var m_floor := Gfx.carpet(Color(0.075, 0.08, 0.09))
	var m_trim := Gfx.metal(trim_col, 0.32, 0.75)
	var m_accent := Gfx.paint(accent_col, 0.35, 0.35, 0.6)
	var m_glass := Gfx.glass(Color(0.045, 0.07, 0.1), 0.03, 0.22)

	var lining_front := z_front
	if not nose.is_empty():
		lining_front = z_front + 0.15

	var mid_z :=(lining_front + z_back) * 0.5
	var span := z_back - lining_front
	var cab_len := z_back - z_front
	v.part(Forge.box(Vector3(hw_in * 2.0, 0.08, cab_len)), m_floor,
			Transform3D(Basis(), Vector3(0, y_floor - 0.04,(z_front + z_back) * 0.5)), "CabFloor")
	v.part(Forge.box(Vector3(1.05, 0.025, 1.35)), m_dark,
			Transform3D(Basis(), Vector3(seat_x, y_floor + 0.015, z_front + cab_len - 1.05)), "CabFloorMat")

	for side: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(0.07, 0.96, span)), m_wall,
				Transform3D(Basis(), Vector3(side * hw_in, y_floor + 0.48, mid_z)), "CabWallLower")
		v.part(Forge.box(Vector3(0.07, 0.34, span)), m_wall,
				Transform3D(Basis(), Vector3(side * hw_in, y_floor + 2.14, mid_z)), "CabWallUpper")
		v.part(Forge.box(Vector3(0.05, 0.05, span)), m_trim,
				Transform3D(Basis(), Vector3(side *(hw_in - 0.012), y_floor + 0.985, mid_z)), "CabWindowSill")
		v.part(Forge.box(Vector3(0.05, 0.05, span)), m_trim,
				Transform3D(Basis(), Vector3(side *(hw_in - 0.012), y_floor + 1.955, mid_z)), "CabWindowHeader")
		for pz: float in [z_front + 0.14, z_back - 0.14]:
			v.part(Forge.box(Vector3(0.1, 1.02, 0.12)), m_trim,
					Transform3D(Basis(), Vector3(side *(hw_in - 0.02), y_floor + 1.47, pz)), "CabWindowPillar")
		v.part(Forge.box(Vector3(0.04, 0.9, 1.1)), m_glass,
				Transform3D(Basis(), Vector3(side *(hw_in - 0.055), y_floor + 1.46, z_front + 1.0)), "CabSideGlass")
		v.part(Forge.box(Vector3(0.09, 0.4, 0.52)), m_dark,
				Transform3D(Basis(), Vector3(side *(hw_in - 0.09), y_floor + 1.32, z_front + 0.52)), "CabSideConsole")
		v.part(Forge.box(Vector3(0.03, 0.09, 0.22)), m_accent,
				Transform3D(Basis(), Vector3(side *(hw_in - 0.135), y_floor + 1.52, z_front + 0.52)), "CabAccent")

	v.part(Forge.box(Vector3(hw_in * 2.0, 0.08, span)), m_wall,
			Transform3D(Basis(), Vector3(0, y_floor + 2.32, mid_z)), "CabCeiling")
	v.part(Forge.box(Vector3(0.62, 0.025, 1.1)), Gfx.emissive(Color(1.0, 0.94, 0.83), 1.0, Color(0.8, 0.78, 0.72)),
			Transform3D(Basis(), Vector3(seat_x - 0.1, y_floor + 2.315, z_front + 1.35)), "CabCeilLight")
	for vz: float in [z_front + 0.9, z_front + 2.2]:
		v.part(Forge.box(Vector3(0.9, 0.03, 0.12)), m_dark,
				Transform3D(Basis(), Vector3(-0.35, y_floor + 2.31, vz)), "CabVent")
	v.part(Forge.box(Vector3(hw_in * 2.0, 2.4, 0.09)), m_wall,
			Transform3D(Basis(), Vector3(0, y_floor + 1.2, z_back)), "CabBulkhead")
	v.part(Forge.box(Vector3(0.8, 1.98, 0.06)), m_desk,
			Transform3D(Basis(), Vector3(0.62, y_floor + 0.99, z_back + 0.07)), "CabDoor")
	v.part(Forge.box(Vector3(0.54, 0.74, 0.05)), m_glass,
			Transform3D(Basis(), Vector3(0.62, y_floor + 1.72, z_back + 0.08)), "CabDoorWindow")
	v.part(Forge.box(Vector3(0.04, 0.22, 0.05)), m_trim,
			Transform3D(Basis(), Vector3(0.98, y_floor + 1.02, z_back + 0.11)), "CabDoorHandle")

	v.part(Forge.box(Vector3(1.9, 0.08, 0.2)), m_dark,
			Transform3D(Basis(), Vector3(-0.15, y_floor + 2.34, z_front + 0.28)), "CabHeader")
	v.part(Forge.cylinder(0.055, 0.24, 10, 0.0, true, true), m_dark,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.55, y_floor + 2.04, z_front + 0.34)), "CabWiperMotor")
	var wiper_pivot := Node3D.new()
	wiper_pivot.name = "CabWiperPivot"
	wiper_pivot.position = Vector3(0.85, y_floor + 1.27, z_front + 0.1)
	v.attach(wiper_pivot)
	var wiper_mesh := MeshInstance3D.new()
	wiper_mesh.name = "CabWiperArm"
	wiper_mesh.mesh = Forge.box(Vector3(1.55, 0.032, 0.032))
	wiper_mesh.material_override = m_dark
	wiper_mesh.position = Vector3(-0.77, 0.0, 0.0)
	wiper_pivot.add_child(wiper_mesh)
	v.cab_parts ["wiper"] = wiper_pivot

	var desk_z := z_front + 1.32
	v.part(Forge.box(Vector3(2.2, 0.7, 0.78)), m_desk,
			Transform3D(Basis(), Vector3(-0.2, y_floor + 0.35, desk_z)), "CabDesk")
	v.part(Forge.box(Vector3(2.3, 0.06, 0.86)), m_dark,
			Transform3D(Basis(), Vector3(-0.2, y_floor + 0.73, desk_z)), "CabDeskTop")
	v.part(Forge.box(Vector3(2.2, 0.26, 0.08)), m_dark,
			Transform3D(Basis(), Vector3(-0.2, y_floor + 0.58, desk_z + 0.39)), "CabKickPanel")

	var tilt := Basis(Vector3.RIGHT, deg_to_rad(-26.0))
	var pan_xf := Transform3D(tilt, Vector3(-0.2, y_floor + 0.8, desk_z - 0.26))
	v.part(Forge.box(Vector3(1.8, 0.44, 0.1)), m_dark, pan_xf, "CabPanel")
	_cab_instruments(v, pan_xf, m_dark)

	var thrust := _cab_lever(v, Vector3(-1.18, y_floor + 0.58, desk_z + 0.18), Color(0.92, 0.48, 0.1))
	var brake := _cab_lever(v, Vector3(-0.32, y_floor + 0.58, desk_z + 0.18), Color(0.84, 0.16, 0.13))
	v.cab_parts ["thrust"] = thrust
	v.cab_parts ["brake"] = brake
	thrust.name = "Dev_thrust"
	brake.name = "Dev_brake"
	_cab_devices(v, pan_xf, y_floor, desk_z, hw_in, m_dark)

	v.part(Forge.box(Vector3(0.36, 0.24, 0.3)), m_dark,
			Transform3D(Basis(), Vector3(0.62, y_floor + 1.14, desk_z - 0.02)), "CabRadio")
	v.part(Forge.cylinder(0.055, 0.06, 10, 0.0, true, true), Gfx.emissive(Color(0.2, 0.9, 0.55), 0.7),
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.62, y_floor + 1.2, desk_z + 0.14)), "CabRadioLed")
	v.part(Forge.box(Vector3(0.2, 0.14, 0.2)), m_dark,
			Transform3D(Basis(), Vector3(-1.12, y_floor + 0.95, desk_z + 0.3)), "CabCupHolder")

	var seat_z := desk_z + 1.32
	for sx: float in [seat_x, seat_x + 1.4]:
		v.part(Forge.rounded_box_x(0.56, 0.58, 0.14, 0.05), m_seat,
				Transform3D(Basis(), Vector3(sx, y_floor + 0.36, seat_z)), "CabSeatCushion")
		v.part(Forge.rounded_box_x(0.2, 0.58, 0.78, 0.06), m_seat,
				Transform3D(Basis(Vector3.RIGHT, deg_to_rad(8.0)), Vector3(sx, y_floor + 0.93, seat_z + 0.28)), "CabSeatBack")
		v.part(Forge.rounded_box_x(0.16, 0.38, 0.2, 0.05), m_seat,
				Transform3D(Basis(), Vector3(sx, y_floor + 1.38, seat_z + 0.29)), "CabHeadrest")
		for ax: float in [-0.31, 0.31]:
			v.part(Forge.box(Vector3(0.1, 0.08, 0.5)), m_dark,
					Transform3D(Basis(), Vector3(sx + ax, y_floor + 0.63, seat_z + 0.04)), "CabArmrest")
		v.part(Forge.cylinder(0.06, 0.3, 10, 0.0, true, true), m_dark,
				Transform3D(Basis(), Vector3(sx, y_floor + 0.16, seat_z)), "CabSeatPost")
		v.part(Forge.box(Vector3(0.5, 0.04, 0.5)), m_trim,
				Transform3D(Basis(), Vector3(sx, y_floor + 0.03, seat_z)), "CabSeatRail")

	v.part(Forge.cylinder(0.075, 0.52, 10, 0.0, true, true), m_accent,
			Transform3D(Basis(), Vector3(-hw_in + 0.16, y_floor + 0.32, z_back - 0.35)), "CabFireExt")
	v.part(Forge.box(Vector3(0.03, 0.03, 0.26)), Gfx.metal(Color(0.6, 0.62, 0.64), 0.3, 0.9),
			Transform3D(Basis(), Vector3(-hw_in + 0.22, y_floor + 0.6, z_back - 0.35)), "CabFireHandle")
	v.cab_anchor = Vector3(seat_x, y_floor + 1.7, seat_z + 0.02)
	v.set_meta("walk_floor", y_floor)
	v.set_meta("walk_front", z_front + 0.22)
	v.set_meta("walk_back", z_back - 0.20)
	v.set_meta("walk_half", hw_in - 0.10)
	v.set_meta("walk_door_z", z_front + 0.85)
	v.set_meta("walk_door_half", 0.45)
	v.set_meta("walk_seat_x", seat_x)
	v.set_meta("walk_seat_z", seat_z)
	v.set_meta("walk_seat_x2", seat_x + 1.4)
	v.set_meta("walk_desk_z", desk_z)
	for child in v.get_children():
		if child is GeometryInstance3D and String(child.name).begins_with("Cab"):
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF



static func freight_cab_interior(v: Vehicle, y_floor: float, z_front: float, z_back: float,
		hw_in: float, seat_x: float) -> void:
	var wall := Gfx.paint(Color(0.46, 0.5, 0.54), 0.58, 0.12, 0.35)
	var wall_upper := Gfx.paint(Color(0.36, 0.4, 0.44), 0.62, 0.1, 0.32)
	var cab_mask := Gfx.paint(Color(0.08, 0.095, 0.11), 0.4, 0.18, 0.42)
	var desk := Gfx.paint(Color(0.145, 0.16, 0.18), 0.4, 0.12, 0.4)
	var desk_top := Gfx.paint(Color(0.08, 0.09, 0.105), 0.3, 0.15, 0.42)
	var rubber := Gfx.carpet(Color(0.045, 0.05, 0.055))
	var trim := Gfx.metal(Color(0.6, 0.63, 0.66), 0.3, 0.82)
	var dark := Gfx.metal(Color(0.1, 0.11, 0.12), 0.5, 0.55)
	var seat := Gfx.leather(Color(0.12, 0.16, 0.14), 0.44)
	var accent := Gfx.paint(Color(0.86, 0.56, 0.18), 0.38, 0.28, 0.5)
	var glass := Gfx.glass(Color(0.055, 0.08, 0.1), 0.04, 0.17)
	var screen_dark := Gfx.emissive(Color(0.035, 0.13, 0.15), 0.7, Color(0.01, 0.04, 0.045))
	var screen_amber := Gfx.emissive(Color(0.8, 0.48, 0.15), 1.1, Color(0.1, 0.055, 0.012))
	var bulkhead_mat := Gfx.interior_panel(Color(0.16, 0.18, 0.20), 0.56)
	var green := Gfx.paint(Color(0.2, 0.58, 0.32), 0.32, 0.2, 0.45)
	var blue := Gfx.paint(Color(0.22, 0.42, 0.72), 0.32, 0.2, 0.45)
	var red := Gfx.paint(Color(0.68, 0.18, 0.16), 0.35, 0.22, 0.45)
	var grey := Gfx.paint(Color(0.43, 0.46, 0.49), 0.32, 0.22, 0.45)

	var front := z_front
	var back := z_back
	var span := back - front
	var mid_z := (front + back) * 0.5
	var seat_z := front + 1.65
	var desk_z := front + 0.78
	var top_y := y_floor + 2.3
	var door_z := -5.55
	var door_half := 0.50
	var wall_segments := [
		[front, door_z - door_half],
		[door_z + door_half, back],
	]

	v.part(Forge.box(Vector3(hw_in * 2.0, 0.07, span)), rubber,
			Transform3D(Basis(), Vector3(0, y_floor - 0.035, mid_z)), "CabFloor")
	v.part(Forge.box(Vector3(1.18, 0.03, 1.3)), Gfx.carpet(Color(0.075, 0.085, 0.09)),
			Transform3D(Basis(), Vector3(seat_x, y_floor + 0.012, seat_z)), "CabFloorMat")

	for side: float in [-1.0, 1.0]:
		for seg: Array in wall_segments:
			var za := float(seg[0])
			var zb := float(seg[1])
			if zb - za < 0.02:
				continue
			v.part(Forge.box(Vector3(0.075, 1.18, zb - za)), wall,
					Transform3D(Basis(), Vector3(side * hw_in, y_floor + 0.59, (za + zb) * 0.5)), "CabWallLower")
			v.part(Forge.box(Vector3(0.11, 0.08, zb - za)), trim,
					Transform3D(Basis(), Vector3(side * (hw_in - 0.025), y_floor + 1.17, (za + zb) * 0.5)), "CabWindowSill")
			v.part(Forge.box(Vector3(0.11, 0.07, zb - za)), trim,
					Transform3D(Basis(), Vector3(side * (hw_in - 0.025), y_floor + 2.34, (za + zb) * 0.5)), "CabWindowHeader")
		var win_z := front + 2.25
		var win_half := 1.15
		var upper_y := y_floor + 2.30
		var upper_h := 0.34
		v.part(Forge.box(Vector3(0.075, upper_h, win_z - win_half - front)), wall_upper,
				Transform3D(Basis(), Vector3(side * hw_in, upper_y, (front + win_z - win_half) * 0.5)), "CabWallUpperFront")
		for seg2: Array in [[win_z + win_half, door_z - door_half], [door_z + door_half, back]]:
			var za2 := float(seg2[0])
			var zb2 := float(seg2[1])
			if zb2 - za2 < 0.02:
				continue
			v.part(Forge.box(Vector3(0.075, upper_h, zb2 - za2)), wall_upper,
					Transform3D(Basis(), Vector3(side * hw_in, upper_y, (za2 + zb2) * 0.5)), "CabWallUpperRear")
		for jz: float in [door_z - door_half, door_z + door_half]:
			v.part(Forge.box(Vector3(0.11, 2.34, 0.08)), trim,
					Transform3D(Basis(), Vector3(side * (hw_in - 0.03), y_floor + 1.17, jz)), "CabDoorJamb")
		v.part(Forge.box(Vector3(0.11, 0.10, door_half * 2.0 + 0.12)), trim,
				Transform3D(Basis(), Vector3(side * (hw_in - 0.03), y_floor + 2.36, door_z)), "CabDoorHeader")
		for pz: float in [win_z - win_half, win_z, win_z + win_half]:
			v.part(Forge.box(Vector3(0.1, 1.04, 0.09)), trim,
					Transform3D(Basis(), Vector3(side * (hw_in - 0.03), y_floor + 1.83, pz)), "CabWindowPillar")
		v.part(Forge.box(Vector3(0.085, 0.32, 0.55)), desk,
				Transform3D(Basis(), Vector3(side * (hw_in - 0.1), y_floor + 1.19, front + 1.22)), "CabSideConsole")
		v.part(Forge.box(Vector3(0.02, 0.06, 0.2)), accent,
				Transform3D(Basis(), Vector3(side * (hw_in - 0.135), y_floor + 1.3, front + 1.22)), "CabAccent")
		for sz: float in [front + 0.2, back - 0.2]:
			v.part(Forge.box(Vector3(0.018, 2.0, 0.025)), trim,
					Transform3D(Basis(), Vector3(side * (hw_in - 0.045), y_floor + 1.98, sz)), "CabWallSeam")
		var blind := []
		blind.append([Forge.cylinder(0.038, 1.6, 12, 0.0, true, true),
				Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(side * (hw_in - 0.08), y_floor + 2.3, win_z))])
		v.merged(blind, dark, "CabBlindRoller")

	v.part(Forge.box(Vector3(hw_in * 2.0, 0.08, span)), wall_upper,
			Transform3D(Basis(), Vector3(0, top_y + 0.04, mid_z)), "CabCeiling")
	v.part(Forge.box(Vector3(2.55, 0.035, 1.0)), Gfx.interior_panel(Color(0.78, 0.81, 0.82), 0.28),
			Transform3D(Basis(), Vector3(0, top_y - 0.025, mid_z)), "CabCeilingTrim")
	for vz: float in [front + 2.0, front + 3.0]:
		v.part(Forge.box(Vector3(0.56, 0.025, 0.18)), dark,
				Transform3D(Basis(), Vector3(-0.6, top_y - 0.075, vz)), "CabVent")
	v.part(Forge.box(Vector3(0.7, 0.045, 1.05)), Gfx.emissive(Color(1.0, 0.93, 0.8), 1.15, Color(0.75, 0.7, 0.56)),
			Transform3D(Basis(), Vector3(0.05, top_y - 0.055, mid_z + 0.25)), "CabCeilLight")
	v.part(Forge.box(Vector3(0.34, 0.035, 0.52)), Gfx.emissive(Color(1.0, 0.94, 0.82), 1.0, Color(0.76, 0.71, 0.57)),
			Transform3D(Basis(), Vector3(0.0, top_y - 0.055, front + 1.15)), "CabCeilLightFront")
	for rz: float in [front + 0.25, back - 0.45]:
		v.part(Forge.cylinder(0.055, 0.26, 10, 0.0, true, true), trim,
				Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.95, top_y - 0.11, rz)), "CabSpeaker")

	# Rear bulkhead with an open doorway on the right, leading into the
	# engine-room side passage and the small rear cab.
	var door_x := 0.72
	var door_hw := 0.39
	var left_w := door_x - door_hw + hw_in
	var right_w := hw_in - door_x - door_hw
	v.part(Forge.box(Vector3(left_w, 2.28, 0.1)), bulkhead_mat,
			Transform3D(Basis(), Vector3(-hw_in + left_w * 0.5, y_floor + 1.14, back)), "CabBulkhead")
	v.part(Forge.box(Vector3(right_w, 2.28, 0.1)), bulkhead_mat,
			Transform3D(Basis(), Vector3(door_x + door_hw + right_w * 0.5, y_floor + 1.14, back)), "CabBulkhead")
	v.part(Forge.box(Vector3(door_hw * 2.0, 0.28, 0.1)), bulkhead_mat,
			Transform3D(Basis(), Vector3(door_x, y_floor + 2.14, back)), "CabBulkhead")
	v.part(Forge.box(Vector3(door_hw * 2.0, 0.04, 0.1)), bulkhead_mat,
			Transform3D(Basis(), Vector3(door_x, y_floor + 0.02, back)), "CabBulkhead")
	for fx: float in [door_x - door_hw, door_x + door_hw]:
		v.part(Forge.box(Vector3(0.06, 2.02, 0.12)), trim,
				Transform3D(Basis(), Vector3(fx, y_floor + 1.02, back)), "CabRearDoorFrame")
	v.part(Forge.box(Vector3(0.84, 0.06, 0.12)), trim,
			Transform3D(Basis(), Vector3(door_x, y_floor + 2.02, back)), "CabRearDoorFrame")
	var inner_door := v.part(Forge.box(Vector3(0.78, 1.98, 0.055)), desk,
			Transform3D(Basis(), Vector3(door_x, y_floor + 0.99, back + 0.07)), "CabInnerDoor")
	inner_door.visible = false
	var inner_window := v.part(Forge.box(Vector3(0.56, 0.72, 0.04)), glass,
			Transform3D(Basis(), Vector3(door_x, y_floor + 1.7, back + 0.1)), "CabDoorWindow")
	inner_window.visible = false
	var inner_handle := v.part(Forge.box(Vector3(0.04, 0.2, 0.045)), trim,
			Transform3D(Basis(), Vector3(1.08, y_floor + 1.03, back + 0.13)), "CabDoorHandle")
	inner_handle.visible = false
	v.part(Forge.box(Vector3(1.05, 1.38, 0.18)), desk_top,
			Transform3D(Basis(), Vector3(-0.65, y_floor + 1.08, back - 0.08)), "CabEquipmentCabinet")
	v.part(Forge.box(Vector3(0.92, 0.95, 0.04)), dark,
			Transform3D(Basis(), Vector3(-0.65, y_floor + 1.36, back - 0.18)), "CabCabinetDoor")
	v.part(Forge.box(Vector3(0.04, 0.22, 0.04)), trim,
			Transform3D(Basis(), Vector3(-0.23, y_floor + 1.25, back - 0.21)), "CabinetHandle")

	v.part(Forge.box(Vector3(2.7, 0.14, 0.08)), wall_upper,
			Transform3D(Basis(), Vector3(0, y_floor + 2.44, front + 0.04)), "CabFrontHeader")
	v.part(Forge.box(Vector3(2.6, 0.62, 0.16)), desk,
			Transform3D(Basis(), Vector3(0, y_floor + 0.44, front + 0.1)), "CabFrontLower")
	# Interior faces of the outer front frame/nose. Without these, hiding the
	# exterior shell in first-person leaves the front reading as a transparent
	# hole around the windscreen.
	v.part(Forge.box(Vector3(2.7, 0.58, 0.10)), wall_upper,
			Transform3D(Basis(), Vector3(0, y_floor + 1.03, front - 0.02)), "CabFrontLowerBody")
	for side: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(0.18, 1.36, 0.12)), cab_mask,
				Transform3D(Basis(), Vector3(side * 1.45, y_floor + 1.88, front - 0.02)), "CabFrontMaskSide")
		v.part(Forge.box(Vector3(0.1, 1.25, 0.12)), trim,
				Transform3D(Basis(), Vector3(side * 1.37, y_floor + 1.72, front + 0.11)), "CabWindshieldPillar")
	v.part(Forge.box(Vector3(2.9, 0.22, 0.12)), cab_mask,
			Transform3D(Basis(), Vector3(0, y_floor + 2.45, front - 0.02)), "CabFrontMaskTop")
	v.part(Forge.box(Vector3(2.9, 0.26, 0.12)), cab_mask,
			Transform3D(Basis(), Vector3(0, y_floor + 1.27, front - 0.02)), "CabFrontMaskBottom")
	v.part(Forge.box(Vector3(2.7, 0.09, 0.14)), trim,
			Transform3D(Basis(), Vector3(0, y_floor + 2.35, front + 0.11)), "CabWindshieldHeader")
	v.part(Forge.box(Vector3(0.075, 1.2, 0.06)), trim,
			Transform3D(Basis(), Vector3(0, y_floor + 1.78, front + 0.12)), "CabWindshieldMullion")
	for wx: float in [-0.67, 0.67]:
		v.part(Forge.box(Vector3(1.30, 0.96, 0.025)), glass,
				Transform3D(Basis(), Vector3(wx, y_floor + 1.80, front + 0.16)), "CabWindshieldGlass")
	var visor := Basis(Vector3.RIGHT, deg_to_rad(-12.0))
	v.part(Forge.box(Vector3(2.62, 0.23, 0.06)), desk_top,
			Transform3D(visor, Vector3(0, y_floor + 2.42, front + 0.22)), "CabSunVisor")
	for vx: float in [-0.92, -0.3, 0.32, 0.94]:
		v.part(Forge.box(Vector3(0.2, 0.045, 0.06)), dark,
				Transform3D(Basis(), Vector3(vx, y_floor + 2.0, front + 0.16)), "CabDefroster")
	var wiper_pivot := Node3D.new()
	wiper_pivot.name = "CabWiperPivot"
	wiper_pivot.position = Vector3(-1.16, y_floor + 1.33, front + 0.2)
	v.attach(wiper_pivot)
	var wiper_items := []
	for wx: float in [0.0, 0.62]:
		wiper_items.append(Forge.tube_between(Vector3(wx, 0.0, 0.0), Vector3(wx + 0.56, 0.0, 0.0), 0.014, 6))
		wiper_items.append(Forge.tube_between(Vector3(wx + 0.56, 0.0, 0.0), Vector3(wx + 0.56, 0.0, 0.42), 0.011, 6))
	var wiper_mesh := MeshInstance3D.new()
	wiper_mesh.name = "CabWiperArm"
	wiper_mesh.mesh = Forge.merge_all(wiper_items)
	wiper_mesh.material_override = dark
	wiper_pivot.add_child(wiper_mesh)
	v.cab_parts ["wiper"] = wiper_pivot

	var desk_base := Vector3(0, y_floor + 0.42, desk_z)
	v.part(Forge.box(Vector3(2.62, 0.68, 0.78)), desk, Transform3D(Basis(), desk_base), "CabDesk")
	v.part(Forge.box(Vector3(2.72, 0.055, 0.9)), desk_top, Transform3D(Basis(), desk_base + Vector3(0, 0.37, 0.02)), "CabDeskTop")
	v.part(Forge.box(Vector3(2.5, 0.22, 0.035)), dark, Transform3D(Basis(), desk_base + Vector3(0, 0.1, 0.41)), "CabKickPanel")
	for sx: float in [-1.08, 1.08]:
		v.part(Forge.box(Vector3(0.34, 0.12, 0.5)), desk_top,
				Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-18.0)), Vector3(sx, y_floor + 0.79, desk_z + 0.08)), "CabConsole")

	var panel_tilt := Basis(Vector3.RIGHT, deg_to_rad(-30.0))
	var panel := Transform3D(panel_tilt, Vector3(-0.26, y_floor + 1.05, desk_z - 0.19))
	var console_black := StandardMaterial3D.new()
	console_black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	console_black.albedo_color = Color(0.010, 0.012, 0.015)
	var console_edge := StandardMaterial3D.new()
	console_edge.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	console_edge.albedo_color = Color(0.028, 0.031, 0.036)
	var lcd_face := StandardMaterial3D.new()
	lcd_face.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lcd_face.albedo_color = Color(0.045, 0.145, 0.175)
	v.part(Forge.box(Vector3(1.66, 0.46, 0.06)), console_black, panel, "CabPanel")
	v.part(Forge.box(Vector3(1.72, 0.50, 0.016)), console_edge,
			panel * Transform3D(Basis(), Vector3(0, 0, -0.032)), "CabPanelBezel")
	# LCD in the middle, two primary controls on the left, secondary buttons on the right.
	v.part(Forge.box(Vector3(0.62, 0.40, 0.018)), console_edge,
			panel * Transform3D(Basis(), Vector3(-0.32, 0.0, 0.032)), "CabDisplayBezel")
	v.part(Forge.box(Vector3(0.54, 0.32, 0.010)), lcd_face,
			panel * Transform3D(Basis(), Vector3(-0.32, 0.0, 0.045)), "CabDisplayScreen")
	# Autopilot and high-beam are grouped on a small panel immediately to the
	# left of the main instrument display, where the driver can reach them
	# without taking their eyes off the desk.
	var aux_panel := Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-24.0)),
			Vector3(-1.05, y_floor + 1.18, desk_z - 0.04))
	v.part(Forge.box(Vector3(0.31, 0.46, 0.05)), console_black, aux_panel, "CabAuxPanel")
	v.part(Forge.box(Vector3(0.34, 0.49, 0.014)), console_edge,
			aux_panel * Transform3D(Basis(), Vector3(0, 0, -0.028)), "CabAuxPanelBezel")
	for ab in [
		["autopilot", 0.10, Color(0.20, 0.52, 0.94)],
		["high_beam", -0.10, Color(0.94, 0.78, 0.24)],
	]:
		var abp := Vector3(-0.055, float(ab [1]), 0.040)
		v.part(Forge.cylinder(0.045, 0.020, 16, 0.0, true, true), trim,
				aux_panel * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), abp), "CabButtonBase")
		v.part(Forge.cylinder(0.033, 0.017, 16, 0.0, true, true),
				Gfx.paint(ab [2], 0.35, 0.25, 0.55),
				aux_panel * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), abp + Vector3(0, 0, 0.013)),
				"Dev_" + String(ab [0]))
		var albl := Label3D.new()
		albl.name = "CabAuxLabel"
		albl.text = "自驾" if String(ab [0]) == "autopilot" else "远光"
		albl.font_size = 17
		albl.pixel_size = 0.0010
		albl.modulate = Color(0.82, 0.90, 0.94)
		albl.outline_size = 0
		albl.transform = aux_panel * Transform3D(Basis(), Vector3(0.075, float(ab [1]), 0.038))
		v.attach(albl)
	var primary_buttons := [
		["battery", -0.72, 0.11, green],
		["park_brake", -0.72, -0.11, red],
	]
	var secondary_buttons := [
		["cab_key", 0.16, 0.11, blue],
		["panto", 0.25, 0.11, green],
		["vcb", 0.34, 0.11, green],
		["atp", 0.43, 0.11, blue],
		["brake_test", 0.52, 0.11, blue],
		["reset", 0.16, -0.11, grey],
		["horn", 0.25, -0.11, red],
		["doors", 0.34, -0.11, grey],
		["headlight", 0.43, -0.11, grey],
		["wiper", 0.52, -0.11, grey],
	]
	for b in primary_buttons:
		var bp := Vector3(float(b [1]), float(b [2]), 0.040)
		v.part(Forge.cylinder(0.052, 0.022, 16, 0.0, true, true), trim,
				panel * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), bp), "CabButtonBase")
		v.part(Forge.cylinder(0.038, 0.020, 16, 0.0, true, true), b [3],
				panel * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), bp + Vector3(0, 0, 0.015)),
				"Dev_" + String(b [0]))
	for b in secondary_buttons:
		var bp := Vector3(float(b [1]), float(b [2]), 0.040)
		v.part(Forge.cylinder(0.040, 0.020, 16, 0.0, true, true), trim,
				panel * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), bp), "CabButtonBase")
		v.part(Forge.cylinder(0.028, 0.018, 16, 0.0, true, true), b [3],
				panel * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), bp + Vector3(0, 0, 0.014)),
				"Dev_" + String(b [0]))

	var wall_x := - hw_in + 0.075
	var breakers := []
	for by in range(4):
		for bz2 in range(3):
			breakers.append([Forge.box(Vector3(0.018, 0.042, 0.052)),
					Transform3D(Basis(), Vector3(wall_x + 0.045, y_floor + 1.22 + float(by) * 0.105, desk_z + 0.28 + float(bz2) * 0.08))])
	v.merged(breakers, trim, "CabBreakerBank")
	v.part(Forge.cylinder(0.085, 0.06, 18, 0.0, true, true), red,
			Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(wall_x + 0.06, y_floor + 2.26, desk_z + 0.28)), "CabEmergencyStop")
	for side2: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(0.05, 0.035, 0.13)), trim,
				Transform3D(Basis(), Vector3(side2 * (hw_in - 0.07), y_floor + 2.13, front + 2.15)), "CabWindowLatch")
		v.part(Forge.box(Vector3(0.04, 0.24, 0.04)), trim,
				Transform3D(Basis(), Vector3(side2 * (hw_in - 0.08), y_floor + 1.78, door_z + 0.55)), "CabDoorLatch")
	v.part(Forge.box(Vector3(0.12, 0.58, 0.42)), desk,
			Transform3D(Basis(), Vector3(hw_in - 0.11, y_floor + 1.56, desk_z + 0.55)), "CabRightCabinet")
	v.part(Forge.box(Vector3(0.015, 0.34, 0.3)), trim,
			Transform3D(Basis(), Vector3(hw_in - 0.18, y_floor + 1.56, desk_z + 0.55)), "CabRightCabinetDoor")
	v.part(Forge.box(Vector3(0.02, 0.18, 0.03)), dark,
			Transform3D(Basis(), Vector3(hw_in - 0.19, y_floor + 1.45, desk_z + 0.37)), "CabRightCabinetHandle")
	v.part(Forge.box(Vector3(0.38, 0.24, 0.22)), dark,
			Transform3D(Basis(), Vector3(0.72, y_floor + 1.1, desk_z + 0.1)), "CabRadio")
	v.part(Forge.cylinder(0.035, 0.04, 10, 0.0, true, true), Gfx.emissive(Color(0.2, 0.9, 0.55), 0.8),
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.72, y_floor + 1.18, desk_z + 0.22)), "CabRadioLed")
	v.part(Forge.box(Vector3(0.17, 0.12, 0.17)), dark,
			Transform3D(Basis(), Vector3(-1.08, y_floor + 0.88, desk_z + 0.24)), "CabCupHolder")

	var thrust := _cab_lever(v, Vector3(-1.08, y_floor + 0.74, desk_z + 0.17), Color(0.94, 0.46, 0.1))
	thrust.name = "Dev_thrust"
	var brake := _cab_lever(v, Vector3(-0.42, y_floor + 0.74, desk_z + 0.17), Color(0.78, 0.14, 0.12))
	brake.name = "Dev_brake"
	var rev := _cab_lever(v, Vector3(0.08, y_floor + 0.72, desk_z + 0.12), Color(0.3, 0.33, 0.35))
	rev.name = "Dev_reverser"
	v.cab_parts ["thrust"] = thrust
	v.cab_parts ["brake"] = brake
	for qx: float in [-1.08, -0.42, 0.08]:
		v.part(Forge.box(Vector3(0.3, 0.035, 0.36)), Gfx.metal(Color(0.18, 0.2, 0.22), 0.4, 0.62),
				Transform3D(Basis(), Vector3(qx, y_floor + 0.68, desk_z + 0.2)), "CabLeverQuadrant")
		for qn in range(5):
			v.part(Forge.box(Vector3(0.2, 0.018, 0.018)), trim,
					Transform3D(Basis(), Vector3(qx, y_floor + 0.7, desk_z + 0.08 + float(qn) * 0.06)), "CabLeverNotch")

	v.part(Forge.box(Vector3(0.3, 0.04, 0.18)), dark,
			Transform3D(Basis(), Vector3(-0.92, y_floor + 0.035, desk_z + 0.62)), "CabPedal")
	v.part(Forge.box(Vector3(0.3, 0.04, 0.18)), dark,
			Transform3D(Basis(), Vector3(-0.52, y_floor + 0.035, desk_z + 0.62)), "CabPedal")

	for sx: float in [seat_x, seat_x + 1.42]:
		v.part(Forge.rounded_box_x(0.6, 0.58, 0.16, 0.06), seat,
				Transform3D(Basis(), Vector3(sx, y_floor + 0.39, seat_z)), "CabSeatCushion")
		v.part(Forge.rounded_box_x(0.2, 0.62, 0.88, 0.07), seat,
				Transform3D(Basis(Vector3.RIGHT, deg_to_rad(8.0)), Vector3(sx, y_floor + 0.98, seat_z + 0.29)), "CabSeatBack")
		v.part(Forge.rounded_box_x(0.13, 0.4, 0.24, 0.06), seat,
				Transform3D(Basis(Vector3.RIGHT, deg_to_rad(8.0)), Vector3(sx, y_floor + 1.45, seat_z + 0.3)), "CabHeadrest")
		for bx: float in [-0.28, 0.28]:
			v.part(Forge.rounded_box_x(0.12, 0.09, 0.56, 0.03), seat,
					Transform3D(Basis(), Vector3(sx + bx, y_floor + 1.0, seat_z + 0.3)), "CabSeatBolster")
		v.part(Forge.box(Vector3(0.08, 0.055, 0.17)), dark,
				Transform3D(Basis(), Vector3(sx + 0.36, y_floor + 0.56, seat_z + 0.05)), "CabSeatRecline")
		for ax: float in [-0.34, 0.34]:
			v.part(Forge.box(Vector3(0.1, 0.08, 0.48)), dark,
					Transform3D(Basis(), Vector3(sx + ax, y_floor + 0.65, seat_z + 0.03)), "CabArmrest")
		v.part(Forge.cylinder(0.06, 0.3, 10, 0.0, true, true), dark,
				Transform3D(Basis(), Vector3(sx, y_floor + 0.16, seat_z)), "CabSeatPost")
		v.part(Forge.box(Vector3(0.34, 0.035, 0.52)), trim,
				Transform3D(Basis(), Vector3(sx, y_floor + 0.02, seat_z)), "CabSeatRail")

	v.part(Forge.cylinder(0.075, 0.54, 12, 0.0, true, true), accent,
			Transform3D(Basis(), Vector3(-hw_in + 0.17, y_floor + 0.34, back - 0.42)), "CabFireExt")
	v.part(Forge.box(Vector3(0.04, 0.035, 0.28)), trim,
			Transform3D(Basis(), Vector3(-hw_in + 0.22, y_floor + 0.65, back - 0.42)), "CabFireHandle")
	v.merged(Forge.tube_between(Vector3(0.86, y_floor + 1.3, back - 0.2),
			Vector3(0.86, y_floor + 2.8, back - 0.2), 0.022, 7), trim, "CabDoorRail")

	v.part(Forge.box(Vector3(0.14, 0.035, 0.08)), grey,
			Transform3D(Basis(), Vector3(-0.65, top_y - 0.055, mid_z - 0.6)), "Dev_cab_light")
	var lamp := OmniLight3D.new()
	lamp.name = "CabLight"
	lamp.position = Vector3(0.05, top_y - 0.18, seat_z + 0.65)
	lamp.omni_range = 5.2
	lamp.light_energy = 2.1
	lamp.light_color = Color(1.0, 0.91, 0.76)
	lamp.shadow_enabled = false
	v.attach(lamp)
	var front_lamp := OmniLight3D.new()
	front_lamp.name = "CabFrontLight"
	front_lamp.position = Vector3(0.0, top_y - 0.16, front + 0.75)
	front_lamp.omni_range = 3.8
	front_lamp.light_energy = 1.25
	front_lamp.light_color = Color(1.0, 0.94, 0.82)
	front_lamp.shadow_enabled = false
	v.attach(front_lamp)
	var door_lamp := OmniLight3D.new()
	door_lamp.name = "CabDoorLight"
	door_lamp.position = Vector3(0.0, top_y - 0.30, door_z + 0.15)
	door_lamp.omni_range = 3.6
	door_lamp.light_energy = 0.9
	door_lamp.light_color = Color(1.0, 0.91, 0.78)
	door_lamp.shadow_enabled = false
	v.attach(door_lamp)

	var speed_display := Label3D.new()
	speed_display.name = "CabSpeedDisplay"
	speed_display.text = "0"
	speed_display.font_size = 64
	speed_display.pixel_size = 0.0014
	speed_display.modulate = Color(0.55, 1.0, 0.80)
	speed_display.outline_size = 8
	speed_display.outline_modulate = Color(0.01, 0.04, 0.05)
	speed_display.transform = panel * Transform3D(Basis(), Vector3(-0.32, 0.025, 0.055))
	v.attach(speed_display)
	v.cab_parts ["speed_label"] = speed_display
	var unit := Label3D.new()
	unit.name = "CabSpeedUnit"
	unit.text = "km/h"
	unit.font_size = 20
	unit.pixel_size = 0.0011
	unit.modulate = Color(0.55, 0.9, 0.76)
	unit.outline_size = 0
	unit.transform = panel * Transform3D(Basis(), Vector3(-0.32, -0.13, 0.055))
	v.attach(unit)
	for dside: float in [-1.0, 1.0]:
		var swx := dside * (hw_in - 0.08)
		var swz := door_z - 0.62
		v.part(Forge.box(Vector3(0.16, 0.22, 0.05)), dark,
				Transform3D(Basis(), Vector3(swx, y_floor + 1.28, swz)), "CabDoorSwitchPanel")
		v.part(Forge.cylinder(0.045, 0.035, 14, 0.0, true, true), green,
				Transform3D(Basis(Vector3.BACK, PI * 0.5),
						Vector3(swx - dside * 0.03, y_floor + 1.28, swz)), "Dev_" +
				("cab_door_left" if dside < 0 else "cab_door_right"))
		var dlbl := Label3D.new()
		dlbl.name = "CabDoorSwitchLabel"
		dlbl.text = "门"
		dlbl.font_size = 20
		dlbl.pixel_size = 0.0011
		dlbl.modulate = Color(0.72, 0.82, 0.86)
		dlbl.transform = Transform3D(Basis(), Vector3(swx - dside * 0.03, y_floor + 1.13, swz))
		v.attach(dlbl)
	for hx: float in [-1.34, 1.34]:
		v.merged(Forge.tube_between(Vector3(hx, y_floor + 1.06, front + 0.38), Vector3(hx, y_floor + 2.04, front + 0.38), 0.022, 7), trim, "CabGrabHandle")
	v.merged(Forge.tube_between(Vector3(-0.9, top_y - 0.12, mid_z - 0.2), Vector3(0.9, top_y - 0.12, mid_z - 0.2), 0.022, 7), trim, "CabCeilingRail")
	for sx2: float in [seat_x, seat_x + 1.42]:
		v.merged(Forge.tube_between(Vector3(sx2 - 0.2, y_floor + 1.36, seat_z + 0.34), Vector3(sx2 + 0.18, y_floor + 0.5, seat_z - 0.1), 0.018, 6), dark, "CabSeatBelt")

	# Disable backface culling on all interior Cab* meshes so inner faces are visible
	for child in v.body_root().get_children():
		if child is MeshInstance3D and String(child.name).begins_with("Cab"):
			if child.material_override:
				child.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED


	v.cab_anchor = Vector3(seat_x, y_floor + 1.68, seat_z + 0.05)
	v.set_meta("walk_floor", y_floor)
	v.set_meta("walk_front", front + 0.24)
	v.set_meta("walk_back", back - 0.22)
	v.set_meta("walk_half", hw_in - 0.10)
	v.set_meta("walk_door_z", door_z)
	v.set_meta("walk_door_half", door_half)
	v.set_meta("walk_seat_x", seat_x)
	v.set_meta("walk_seat_z", seat_z)
	v.set_meta("walk_seat_x2", seat_x + 1.42)
	v.set_meta("walk_desk_z", desk_z)
	for child in v.get_children():
		if child is GeometryInstance3D and String(child.name).begins_with("Cab"):
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _mirror_cab_geometry(v: Vehicle) -> void:
	# Both ends of a Chinese mainline loco are driving cabs. Mirror the player
	# cab geometry about the vehicle centre so the rear side windows and nose
	# also reveal a furnished interior instead of an empty shell.
	var root := v.body_root()
	var copies: Array = []
	for child in root.get_children():
		if child is MeshInstance3D:
			var nm := String(child.name)
			if not nm.begins_with("Cab") or nm == "Carbody" or nm == "CabMask":
				continue
			if nm.begins_with("CabDoor"):
				continue
			copies.append(child)
	var rot := Basis(Vector3.UP, PI)
	for src: MeshInstance3D in copies:
		var dup := src.duplicate() as MeshInstance3D
		if dup == null:
			continue
		dup.name = "Rear" + String(src.name)
		dup.transform = Transform3D(rot * src.transform.basis, rot * src.transform.origin)
		dup.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(dup)
	var lamp := OmniLight3D.new()
	lamp.name = "RearCabLight"
	lamp.position = Vector3(0.05, 3.24, v.length * 0.5 - 2.45)
	lamp.omni_range = 5.2
	lamp.light_energy = 1.9
	lamp.light_color = Color(1.0, 0.9, 0.74)
	lamp.shadow_enabled = false
	v.attach(lamp)


static func _cab_button_base() -> ArrayMesh:
	return Forge.cylinder(0.055, 0.025, 16, 0.0, true, true)

static func _cab_devices(v: Vehicle, pan_xf: Transform3D, y_floor: float, desk_z: float,
		hw_in: float, m_dark: Material) -> void:
	var col_green := Gfx.paint(Color(0.22, 0.58, 0.34), 0.35, 0.25, 0.5)
	var col_blue := Gfx.paint(Color(0.26, 0.42, 0.72), 0.35, 0.25, 0.5)
	var col_grey := Gfx.paint(Color(0.44, 0.46, 0.49), 0.4, 0.3, 0.5)
	var col_red := Gfx.paint(Color(0.66, 0.22, 0.2), 0.4, 0.25, 0.5)


	var buttons := [
		["panto", 0.05, -0.105, col_green],
		["vcb", 0.18, -0.105, col_green],
		["atp", 0.31, -0.105, col_blue],
		["brake_test", 0.44, -0.105, col_blue],
		["reset", 0.6, -0.105, col_grey],
		["horn", 0.72, -0.105, col_red],
		["doors", 0.84, -0.105, col_grey],
	]
	for b in buttons:
		var xf := pan_xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5),
				Vector3(float(b [1]), float(b [2]), 0.052))
		v.part(Forge.cylinder(0.03, 0.022, 12, 0.0, true, true), b [3], xf, "Dev_" + String(b [0]))


	var toggles := [
		["headlight", 0.06, 0.16, col_grey],
		["wiper", 0.25, 0.16, col_grey],
		["park_brake", 0.44, 0.16, col_red],
	]
	for t in toggles:
		var items := []
		items.append([Forge.box(Vector3(0.075, 0.055, 0.02)), Transform3D()])
		items.append([Forge.box(Vector3(0.018, 0.055, 0.018)),
				Transform3D(Basis(Vector3.RIGHT, deg_to_rad(28.0)), Vector3(0.0, 0.03, 0.022))])
		v.part(Forge.merge_all(items), t [3],
				pan_xf * Transform3D(Basis(), Vector3(float(t [1]), float(t [2]), 0.05)),
				"Dev_" + String(t [0]))


	var rev := _cab_lever(v, Vector3(0.34, y_floor + 0.58, desk_z + 0.18), Color(0.34, 0.36, 0.38))
	rev.name = "Dev_reverser"


	var seat_z := desk_z + 1.32
	v.part(Forge.box(Vector3(0.14, 0.035, 0.09)), col_grey,
			Transform3D(Basis(), Vector3(-0.52, y_floor + 2.285, seat_z)), "Dev_cab_light")
	var lamp := OmniLight3D.new()
	lamp.name = "CabLight"
	lamp.position = Vector3(-0.3, y_floor + 2.1, seat_z + 0.1)
	lamp.omni_range = 5.5
	lamp.light_energy = 2.2
	lamp.light_color = Color(1.0, 0.94, 0.82)
	lamp.shadow_enabled = false
	v.attach(lamp)


static func _cab_instruments(v: Vehicle, pan_xf: Transform3D, m_dark: Material) -> void:
	var r := 0.155
	var cx := -0.44
	var cy := 0.06
	var items := []

	items.append([Forge.cylinder(r, 0.05, 20, 0.0, true, true),
			pan_xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(cx, cy, 0.035))])

	for i in range(11):
		var a := deg_to_rad(150.0 - float(i) * 30.0)
		var p := Vector3(cx + cos(a) *(r - 0.03), cy + sin(a) *(r - 0.03), 0.062)
		items.append([Forge.box(Vector3(0.022, 0.048, 0.008)),
				pan_xf * Transform3D(Basis(Vector3.BACK, a - PI * 0.5), p)])

	items.append([Forge.box(Vector3(0.52, 0.32, 0.03)),
			pan_xf * Transform3D(Basis(), Vector3(0.36, 0.02, 0.028))])

	for i in range(4):
		items.append([Forge.cylinder(0.026, 0.03, 8, 0.0, true, true),
				pan_xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.06 + float(i) * 0.11, -0.185, 0.04))])
	var mi := MeshInstance3D.new()
	mi.mesh = Forge.merge_all(items)
	mi.material_override = m_dark
	mi.name = "CabPanelFace"
	v.attach(mi)


	var lit := [Color(0.25, 1.0, 0.4), Color(1.0, 0.8, 0.25), Color(1.0, 0.3, 0.25)]
	for i in range(3):
		var lamp := MeshInstance3D.new()
		lamp.mesh = Forge.cylinder(0.024, 0.03, 8, 0.0, true, true)
		lamp.material_override = Gfx.emissive(lit [i], 2.2 + float(i %2) * 1.6, lit [i].darkened(0.4))
		lamp.transform = pan_xf * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(cx + r + 0.1 + float(i) * 0.09, cy + 0.11, 0.04))
		v.attach(lamp)


	var needle := Node3D.new()
	needle.name = "GaugeNeedle"
	needle.transform = pan_xf * Transform3D(Basis(), Vector3(cx, cy, 0.068))
	v.attach(needle)
	var nd := MeshInstance3D.new()
	nd.mesh = Forge.merge_all([
		[Forge.box(Vector3(r - 0.02, 0.016, 0.008)), Transform3D(Basis(), Vector3((r - 0.02) * 0.5, 0, 0))],
		[Forge.cylinder(0.03, 0.02, 10, 0.0, true, true), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.004))],
	])
	nd.material_override = Gfx.emissive(Color(1.0, 0.92, 0.8), 1.6, Color(0.92, 0.9, 0.88))
	needle.add_child(nd)
	v.cab_parts ["needle"] = needle


	var scr := MeshInstance3D.new()
	scr.mesh = Forge.box(Vector3(0.48, 0.28, 0.02))
	scr.material_override = Gfx.emissive(Color(0.2, 0.85, 0.65), 1.4, Color(0.03, 0.09, 0.07))
	scr.transform = pan_xf * Transform3D(Basis(), Vector3(0.36, 0.02, 0.048))
	v.attach(scr)
	var lbl := Label3D.new()
	lbl.text = "0"
	lbl.font_size = 96
	lbl.pixel_size = 0.0021
	lbl.modulate = Color(0.55, 1.0, 0.82)
	lbl.outline_size = 0
	lbl.transform = pan_xf * Transform3D(Basis(), Vector3(0.36, 0.02, 0.062))
	v.attach(lbl)
	v.cab_parts ["speed_label"] = lbl


static func _cab_lever(v: Vehicle, pos: Vector3, knob_color: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = "Lever"
	pivot.position = pos
	v.attach(pivot)
	var items := []
	items.append(Forge.tube_between(Vector3(0, 0, 0), Vector3(0, 0.28, 0.1), 0.022, 8))
	items.append(Forge.tube_between(Vector3(0, 0, 0), Vector3(0, -0.05, -0.05), 0.026, 8))
	var mi := MeshInstance3D.new()
	mi.mesh = Forge.merge_all(items)
	mi.material_override = Gfx.metal(Color(0.62, 0.64, 0.66), 0.35, 0.9)
	pivot.add_child(mi)
	var knob := MeshInstance3D.new()
	knob.mesh = Gfx_knob()
	knob.material_override = Gfx.paint(knob_color, 0.4, 0.2, 0.45)
	knob.position = Vector3(0, 0.26, 0.08)
	pivot.add_child(knob)
	pivot.rotation.x = deg_to_rad(-26.0)
	return pivot

static func Gfx_knob() -> ArrayMesh:
	return Forge.merge_all([
		[Forge.cylinder(0.042, 0.086, 14, 0.0, true, true), Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, 0.043, 0))],
	])



static func _car_marking(v: Vehicle, text: String, pos: Vector3, side: float,
		color: Color, outline: Color) -> void:
	var label := Label3D.new()
	label.name = "CarMarking"
	label.text = text
	label.font_size = 72
	label.pixel_size = 0.0056
	label.modulate = color
	label.outline_size = 7
	label.outline_modulate = outline
	label.position = pos
	label.rotation_degrees = Vector3(0, 90.0 if side > 0.0 else -90.0, 0)
	label.no_depth_test = false
	v.attach(label)


static func _coupler(v: Vehicle, z: float, mat: Material, length := 1.1) -> void:
	var items := []
	var dir := signf(z)
	var inner := z - dir * length
	# The drawbar must run from the car end to the coupler head. Centering it
	# at z * 0.5 left the head visibly floating in mid-air.
	items.append([Forge.box(Vector3(0.44, 0.3, length)),
			Transform3D(Basis(), Vector3(0, 0.92, (z + inner) * 0.5))])
	items.append([Forge.box(Vector3(0.48, 0.38, 0.34)),
			Transform3D(Basis(), Vector3(0, 0.92, z))])
	# Collar/fairing where the drawbar meets the underframe.
	items.append([Forge.box(Vector3(0.62, 0.46, 0.16)),
			Transform3D(Basis(), Vector3(0, 0.94, z - dir * length * 0.55))])
	items.append_array(Forge.tube_between(
			Vector3(0.28, 1.15, z), Vector3(0.28, 1.5, z - dir * length * 0.8), 0.03, 6))
	var mi := MeshInstance3D.new()
	mi.mesh = Forge.merge_all(items)
	mi.material_override = mat
	mi.name = "Coupler"
	v.body_root().add_child(mi)



static func _fill_light(v: Vehicle, pos: Vector3, col: Color) -> void:
	var sp := SpotLight3D.new()
	sp.name = "HeadlightFill"
	sp.position = pos
	sp.light_color = col
	sp.light_energy = 9.0
	sp.spot_range = 110.0
	sp.spot_angle = 58.0
	sp.spot_attenuation = 0.75
	sp.rotation_degrees = Vector3(-9, 0, 0)
	sp.shadow_enabled = false
	v.attach(sp)
	v.head_lights.append(sp)


static func _lamp(v: Vehicle, pos: Vector3, col: Color, size := 0.2, forward := true) -> void:
	var h := Gfx.metal(Color(0.22, 0.23, 0.24), 0.4, 0.6)
	v.part(Forge.box(Vector3(size * 1.5, size * 1.35, 0.1)), h,
			Transform3D(Basis(), pos), "LampHousing")
	var lens_mat := Gfx.emissive(col, 5.0, col.darkened(0.3))
	lens_mat.cull_mode = BaseMaterial3D.CULL_FRONT
	v.part(Forge.cylinder(size * 0.5, 0.055, 18, 0.0, true, true), lens_mat,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), pos + Vector3(0, 0, -0.06)), "LampLens")
	if forward:
		var sp := SpotLight3D.new()
		sp.name = "HeadLight"
		sp.position = pos + Vector3(0, -0.02, -0.12)
		sp.spot_range = 240.0
		sp.spot_angle = 28.0
		sp.light_energy = 9.0
		sp.light_color = col
		sp.shadow_enabled = false
		v.attach(sp)
		v.head_lights.append(sp)


static func _buffers(v: Vehicle, z: float, mat: Material) -> void:
	for side: float in [-1.0, 1.0]:
		v.part(Forge.cylinder(0.17, 0.32, 18, 0.0, true, true), mat,
				Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(side * 0.72, 0.86, z + signf(z) * 0.14)), "Buffer")
		v.part(Forge.cylinder(0.28, 0.035, 18, 0.0, true, true), mat,
				Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(side * 0.72, 0.86, z + signf(z) * 0.3)), "BufferPlate")
	v.part(Forge.box(Vector3(2.45, 0.22, 0.12)), mat,
			Transform3D(Basis(), Vector3(0, 0.75, z + signf(z) * 0.06)), "BufferBeam")


static func _handrail(v: Vehicle, x0: float, z0: float, z1: float, y := 1.85, posts := 5) -> void:
	var mat := Gfx.metal(Color(0.62, 0.64, 0.66), 0.32, 0.9)
	var items := []
	items.append_array(Forge.tube_between(Vector3(x0, y, z0), Vector3(x0, y, z1), 0.025, 8))
	for i in range(posts):
		var z := lerpf(z0, z1, float(i) / float(maxi(1, posts - 1)))
		items.append_array(Forge.tube_between(Vector3(x0, 0.9, z), Vector3(x0, y, z), 0.022, 7))
	var mi := MeshInstance3D.new()
	mi.mesh = Forge.merge_all(items)
	mi.material_override = mat
	v.attach(mi)


static func diesel_loco() -> Vehicle:
	var v := Vehicle.new()
	v.name = "DieselLoco"
	v.length = 20.6
	v.width = 3.1
	v.height = 4.02
	v.bogie_spacing = 10.8
	v.wheel_radius = 0.5
	v.mass_empty = 122.0
	v.mass_loaded = 122.0
	v.kind = "loco"
	v.designation = "东风4型内燃机车"
	v.max_speed = 100.0
	v.brake_force = 2.1
	v.set_loaded(true)
	var half := v.length * 0.5
	var floor_y := 1.18
	var green := Gfx.train_paint(Color(0.055, 0.23, 0.15), 0.58, 0.22)
	var cream := Gfx.train_paint(Color(0.78, 0.76, 0.66), 0.35, 0.32)
	var dark := Gfx.metal(Color(0.15, 0.16, 0.18), 0.5, 0.55)
	var roof := Gfx.metal(Color(0.3, 0.31, 0.33), 0.45, 0.65)
	var steel := Gfx.metal(Color(0.52, 0.54, 0.57), 0.3, 0.92)
	var glass := Gfx.glass(Color(0.04, 0.07, 0.1), 0.025, 0.24)
	var red := Gfx.emissive(Color(1.0, 0.16, 0.1), 2.2, Color(0.4, 0.03, 0.02))

	v.part(Forge.box(Vector3(2.75, 0.5, half * 2.0 - 0.8)), dark,
			Transform3D(Basis(), Vector3(0, 1.0, 0)), "Underframe")
	v.part(Forge.box(Vector3(2.55, 0.28, 2.9)), dark,
			Transform3D(Basis(), Vector3(0, 0.72, 0.7)), "FuelTank")
	v.part(Forge.cylinder(0.12, 1.8, 12, 0.0, true, true), steel,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.95, 0.6, 2.9)), "AirTank")

	var hood_z0 := - half + 4.85
	var hood_z1 := half - 2.0
	var hood_len := hood_z1 - hood_z0
	var hood_zc := (hood_z0 + hood_z1) * 0.5
	v.part(Forge.rounded_box_x(hood_len, 2.55, 2.25, 0.2),
			green, Transform3D(Basis(), Vector3(0, floor_y + 1.08, hood_zc)), "LongHood")
	v.part(Forge.rounded_box_x(hood_len - 0.35, 2.62, 0.22, 0.1),
			cream, Transform3D(Basis(), Vector3(0, floor_y + 2.23, hood_zc)), "HoodRoof")
	v.part(Forge.box(Vector3(2.3, 0.16, hood_len - 0.4)),
			roof, Transform3D(Basis(), Vector3(0, floor_y + 2.36, hood_zc)), "RoofWalkway")
	for side: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(0.06, 0.72, hood_len - 0.8)),
				Gfx.metal(Color(0.18, 0.19, 0.2), 0.55, 0.55),
				Transform3D(Basis(), Vector3(side * 1.29, floor_y + 1.0, hood_zc)), "LouverPanel")
		for i in range(8):
			v.part(Forge.box(Vector3(0.04, 0.045, hood_len - 0.9)),
					steel, Transform3D(Basis(), Vector3(side * 1.33, floor_y + 0.72 + float(i) * 0.075, hood_zc)), "LouverSlat")
		v.part(Forge.box(Vector3(0.3, 0.08, 4.8)), dark,
				Transform3D(Basis(), Vector3(side * 1.42, floor_y + 0.32, hood_zc - 2.4)), "Walkway")
		_handrail(v, side * 1.48, hood_z0 + 0.35, hood_z1 - 0.35, floor_y + 1.85, 7)
	v.part(Forge.cylinder(0.2, 1.15, 14, 0.0, true, true), dark,
			Transform3D(Basis(), Vector3(0.52, floor_y + 2.28, hood_z1 - 2.2)), "Exhaust")
	v.part(Forge.cylinder(0.34, 0.12, 18, 0.0, true, true), steel,
			Transform3D(Basis(), Vector3(-0.55, floor_y + 2.43, hood_z1 - 2.5)), "RadiatorFan")
	for i in range(3):
		v.part(Forge.box(Vector3(0.06, 0.42, 0.58)), dark,
				Transform3D(Basis(), Vector3(1.3, floor_y + 1.6, hood_z0 + 1.2 + float(i) * 0.9)), "HoodDoor")

	var cab_z0 := - half + 1.05
	var cab_z1 := - half + 4.82
	var cab_zc := (cab_z0 + cab_z1) * 0.5
	var cab_len := cab_z1 - cab_z0
	v.part(Forge.box(Vector3(2.75, 0.42, cab_len)), dark,
			Transform3D(Basis(), Vector3(0, floor_y + 0.1, cab_zc)), "CabUnderframe")
	v.part(Forge.box(Vector3(3.0, 0.1, cab_len + 0.15)), roof,
			Transform3D(Basis(), Vector3(0, floor_y + 2.48, cab_zc)), "CabRoof")
	for side: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(0.09, 1.05, cab_len)), green,
				Transform3D(Basis(), Vector3(side * 1.46, floor_y + 0.53, cab_zc)), "CabSideLower")
		v.part(Forge.box(Vector3(0.09, 0.4, cab_len)), green,
				Transform3D(Basis(), Vector3(side * 1.46, floor_y + 2.28, cab_zc)), "CabSideUpper")
		for wz: float in [cab_z0 + 1.1, cab_z0 + 2.7]:
			v.part(Forge.box(Vector3(0.04, 0.95, 1.05)), glass,
					Transform3D(Basis(), Vector3(side * 1.405, floor_y + 1.6, wz)), "CabSideWindow")
			v.part(Forge.box(Vector3(0.06, 0.05, 1.16)), steel,
					Transform3D(Basis(), Vector3(side * 1.39, floor_y + 2.1, wz)), "CabWindowSill")
		v.part(Forge.box(Vector3(2.9, 0.95, 0.09)), green,
				Transform3D(Basis(), Vector3(0, floor_y + 0.55, cab_z0)), "CabFrontLower")
		v.part(Forge.box(Vector3(2.9, 0.38, 0.09)), green,
				Transform3D(Basis(), Vector3(0, floor_y + 2.29, cab_z0)), "CabFrontUpper")
		v.part(Forge.box(Vector3(2.65, 0.9, 0.05)), glass,
				Transform3D(Basis(), Vector3(0, floor_y + 1.6, cab_z0 - 0.015)), "CabWindshield")
	v.part(Forge.box(Vector3(3.0, 2.45, 0.1)), green,
			Transform3D(Basis(), Vector3(0, floor_y + 1.2, cab_z1)), "CabRearWall")
	v.part(Forge.box(Vector3(0.72, 1.85, 0.06)), dark,
			Transform3D(Basis(), Vector3(0.82, floor_y + 1.0, cab_z1 + 0.06)), "CabDoor")

	var nose_z := - half + 0.55
	v.part(Forge.box(Vector3(2.7, 1.3, 1.0)), green,
			Transform3D(Basis(), Vector3(0, 1.72, nose_z)), "Nose")
	v.part(Forge.box(Vector3(2.85, 0.3, 0.5)), dark,
			Transform3D(Basis(), Vector3(0, 0.95, - half + 0.22)), "Pilot")
	_buffers(v, - half, dark)
	_coupler(v, - half - 0.42, dark, 0.8)
	_buffers(v, half, dark)
	_coupler(v, half + 0.42, dark, 0.8)
	_lamp(v, Vector3(-0.92, 2.28, - half + 0.12), Color(1.0, 0.94, 0.78), 0.24)
	_lamp(v, Vector3(0.92, 2.28, - half + 0.12), Color(1.0, 0.94, 0.78), 0.24)
	v.part(Forge.box(Vector3(0.12, 0.22, 0.06)), red,
			Transform3D(Basis(), Vector3(-1.2, 1.4, half - 0.01)), "TailLightL")
	v.part(Forge.box(Vector3(0.12, 0.22, 0.06)), red,
			Transform3D(Basis(), Vector3(1.2, 1.4, half - 0.01)), "TailLightR")
	v.part(Forge.cylinder(0.075, 0.55, 10, 0.0, true, true), steel,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.35, 2.95, - half + 0.45)), "Horn")

	var rear_z0 := half - 2.0
	var rear_z1 := half - 0.25
	v.part(Forge.box(Vector3(2.9, 2.45, rear_z1 - rear_z0)), green,
			Transform3D(Basis(), Vector3(0, floor_y + 1.2, (rear_z0 + rear_z1) * 0.5)), "RearCab")
	v.part(Forge.box(Vector3(0.95, 0.72, 0.05)), glass,
			Transform3D(Basis(), Vector3(-0.55, floor_y + 1.75, rear_z1 + 0.01)), "RearCabWindow")
	v.part(Forge.box(Vector3(0.95, 0.72, 0.05)), glass,
			Transform3D(Basis(), Vector3(0.55, floor_y + 1.75, rear_z1 + 0.01)), "RearCabWindowR")

	_build_bogie(v, -4.75, 0.5, 3, 1.9)
	_build_bogie(v, 4.75, 0.5, 3, 1.9)
	cab_interior(v, floor_y, cab_z0 + 0.12, cab_z1 - 0.1, 1.4, -0.68, {}, "diesel")
	return v


static func _steam_axle(v: Vehicle, z: float, r: float) -> void:
	var node := Node3D.new()
	node.name = "DriverAxle"
	node.position = Vector3(0, r, z)
	v.attach(node)
	var steel := Gfx.metal(Color(0.5, 0.51, 0.54), 0.28, 0.95)
	var axle := MeshInstance3D.new()
	axle.mesh = Forge.cylinder(0.1, 2.0, 12, -1.0, true, true)
	axle.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO)
	axle.material_override = steel
	node.add_child(axle)
	for side: float in [-1.0, 1.0]:
		var w := MeshInstance3D.new()
		w.mesh = _wheel_mesh(r)
		w.material_override = Gfx.metal(Color(0.2, 0.21, 0.23), 0.42, 0.85)
		w.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(side * 0.72, 0, 0))
		node.add_child(w)
	v.add_wheel(node, r)


static func steam_loco() -> Vehicle:
	var v := Vehicle.new()
	v.name = "SteamLoco"
	v.length = 21.2
	v.width = 3.1
	v.height = 4.35
	v.bogie_spacing = 12.2
	v.wheel_radius = 0.8
	v.mass_empty = 168.0
	v.mass_loaded = 168.0
	v.kind = "loco"
	v.designation = "前进型蒸汽机车"
	v.max_speed = 80.0
	v.brake_force = 2.0
	v.set_loaded(true)
	var half := v.length * 0.5
	var floor_y := 1.15
	var black := Gfx.train_paint(Color(0.035, 0.038, 0.042), 0.38, 0.28)
	var graphite := Gfx.metal(Color(0.16, 0.17, 0.18), 0.4, 0.55)
	var red := Gfx.train_paint(Color(0.62, 0.075, 0.06), 0.32, 0.3)
	var brass := Gfx.metal(Color(0.6, 0.46, 0.18), 0.3, 0.9)
	var steel := Gfx.metal(Color(0.5, 0.52, 0.55), 0.28, 0.92)

	v.part(Forge.box(Vector3(2.75, 0.42, half * 2.0 - 0.8)), graphite,
			Transform3D(Basis(), Vector3(0, floor_y, 0)), "Frame")
	var boiler_zc := -1.4
	v.part(Forge.cylinder(1.12, 10.6, 24, 0.0, true, true), black,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 2.42, - half + 2.3)), "Boiler")
	v.part(Forge.box(Vector3(2.2, 1.75, 3.3)), graphite,
			Transform3D(Basis(), Vector3(0, 2.2, 3.95)), "Firebox")
	v.part(Forge.cylinder(1.23, 1.15, 24, 0.0, true, true), graphite,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 2.42, - half + 1.1)), "Smokebox")
	v.part(Forge.cylinder(1.17, 0.08, 24, 0.0, true, true), black,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 2.42, - half + 0.55)), "SmokeboxDoor")
	v.part(Forge.cylinder(0.7, 0.08, 20, 0.0, true, true), brass,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 2.68, - half + 0.51)), "SmokeboxRing")
	v.part(Forge.cylinder(0.33, 1.55, 18, 0.0, true, true), graphite,
			Transform3D(Basis(), Vector3(0, 3.35, - half + 1.8)), "Chimney")
	v.part(Forge.cylinder(0.44, 0.18, 18, 0.0, true, true), black,
			Transform3D(Basis(), Vector3(0, 4.82, - half + 1.8)), "ChimneyLip")
	for spec: Array in [[-3.8, 0.72, 0.62], [1.45, 0.58, 0.48]]:
		var dz: float = spec [0]
		var rad: float = spec [1]
		var hh: float = spec [2]
		v.part(Forge.cylinder(rad, hh, 18, 0.0, true, true), brass,
				Transform3D(Basis(), Vector3(0, 3.38, dz)), "SteamDome")
		v.part(Forge.cylinder(rad * 0.55, 0.1, 14, 0.0, true, true), graphite,
				Transform3D(Basis(), Vector3(0, 3.38 + hh, dz)), "DomeCap")
	v.part(Forge.box(Vector3(2.4, 0.16, 10.0)), graphite,
			Transform3D(Basis(), Vector3(0, 1.48, -2.6)), "RunningBoard")
	for side: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(0.08, 1.1, 10.0)), black,
				Transform3D(Basis(), Vector3(side * 1.42, 1.9, -2.6)), "SideSkirt")
		_handrail(v, side * 1.5, - half + 2.0, 4.7, 2.5, 9)
		for i in range(4):
			v.part(Forge.cylinder(0.055, 0.55, 8, 0.0, true, true), brass,
					Transform3D(Basis(), Vector3(side * 1.18, 3.43, -7.0 + float(i) * 2.4)), "Injector")
	v.part(Forge.box(Vector3(3.15, 0.25, 0.55)), red,
			Transform3D(Basis(), Vector3(0, 1.55, - half + 0.35)), "PilotBeam")
	v.part(Forge.box(Vector3(2.7, 0.36, 0.3)), graphite,
			Transform3D(Basis(), Vector3(0, 0.86, - half + 0.05)), "Pilot")
	_buffers(v, - half, steel)
	_coupler(v, - half - 0.42, graphite, 0.8)
	_lamp(v, Vector3(0, 3.0, - half + 0.18), Color(1.0, 0.9, 0.68), 0.26)

	var cab_z0 := half - 5.0
	var cab_z1 := half - 0.45
	var cab_zc := (cab_z0 + cab_z1) * 0.5
	var cab_len := cab_z1 - cab_z0
	v.part(Forge.box(Vector3(3.0, 0.1, cab_len + 0.2)), black,
			Transform3D(Basis(), Vector3(0, floor_y + 2.48, cab_zc)), "CabRoof")
	for side: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(0.09, 1.0, cab_len)), red,
				Transform3D(Basis(), Vector3(side * 1.48, floor_y + 0.5, cab_zc)), "CabSideLower")
		v.part(Forge.box(Vector3(0.09, 0.42, cab_len)), black,
				Transform3D(Basis(), Vector3(side * 1.48, floor_y + 2.27, cab_zc)), "CabSideUpper")
		v.part(Forge.box(Vector3(0.04, 0.85, 1.25)), Gfx.glass(Color(0.04, 0.07, 0.1), 0.03, 0.23),
				Transform3D(Basis(), Vector3(side * 1.43, floor_y + 1.55, cab_zc - 0.2)), "CabSideWindow")
	v.part(Forge.box(Vector3(3.0, 2.45, 0.1)), black,
			Transform3D(Basis(), Vector3(0, floor_y + 1.2, cab_z1)), "CabRearWall")
	v.part(Forge.box(Vector3(0.82, 1.9, 0.06)), red,
			Transform3D(Basis(), Vector3(0.82, floor_y + 1.0, cab_z1 + 0.06)), "CabRearDoor")

	for z: float in [-7.2, -4.5, -1.8]:
		_steam_axle(v, z, 0.8)
	v.part(Forge.box(Vector3(0.1, 0.11, 5.5)), steel,
			Transform3D(Basis(), Vector3(-1.0, 0.8, -4.5)), "SideRod")
	v.part(Forge.box(Vector3(0.1, 0.11, 5.5)), steel,
			Transform3D(Basis(), Vector3(1.0, 0.8, -4.5)), "SideRodR")
	v.part(Forge.cylinder(0.22, 1.1, 14, 0.0, true, true), graphite,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-1.35, 1.1, -7.2)), "CylinderL")
	v.part(Forge.cylinder(0.22, 1.1, 14, 0.0, true, true), graphite,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(1.35, 1.1, -7.2)), "CylinderR")
	v.part(Forge.cylinder(0.14, 1.2, 12, 0.0, true, true), graphite,
			Transform3D(Basis(), Vector3(0.88, 4.18, - half + 1.8)), "ChimneyPipe")
	_lamp(v, Vector3(0.9, 2.1, half), Color(1.0, 0.2, 0.12), 0.18, false)
	v.part(Forge.cylinder(0.08, 0.6, 10, 0.0, true, true), steel,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.45, 3.1, - half + 0.6)), "Bell")
	steam_cab_interior(v, floor_y, cab_z0, cab_z1, 1.4, -0.62)
	return v


static func steam_tender() -> Vehicle:
	var v := Vehicle.new()
	v.name = "SteamTender"
	v.length = 9.6
	v.width = 3.0
	v.height = 3.45
	v.bogie_spacing = 6.4
	v.wheel_radius = 0.45
	v.mass_empty = 32.0
	v.mass_loaded = 60.0
	v.kind = "tender"
	v.designation = "煤水车"
	v.max_speed = 80.0
	v.brake_force = 1.2
	v.set_loaded(true)
	var half := v.length * 0.5
	var black := Gfx.train_paint(Color(0.035, 0.038, 0.042), 0.4, 0.25)
	var coal := Gfx.noise_surface(Color(0.035, 0.035, 0.038), 1.0, 0.6, 0.7)
	var graphite := Gfx.metal(Color(0.16, 0.17, 0.18), 0.42, 0.5)
	v.part(Forge.box(Vector3(2.75, 0.45, half * 2.0)), graphite,
			Transform3D(Basis(), Vector3(0, 1.0, 0)), "TenderFrame")
	v.part(Forge.rounded_box_x(half * 2.0 - 0.3, 2.65, 1.85, 0.15), black,
			Transform3D(Basis(), Vector3(0, 1.42, 0)), "TenderTank")
	v.part(Forge.box(Vector3(2.35, 0.55, 2.8)), coal,
			Transform3D(Basis(), Vector3(0, 2.5, -0.8)), "Coal")
	v.part(Forge.box(Vector3(2.45, 0.58, 2.9)), graphite,
			Transform3D(Basis(), Vector3(0, 2.5, 2.0)), "WaterHatch")
	v.part(Forge.box(Vector3(1.5, 0.12, 0.5)), graphite,
			Transform3D(Basis(), Vector3(0, 2.82, 1.9)), "HatchLid")
	_build_bogie(v, -2.7, 0.45, 2, 2.2)
	_build_bogie(v, 2.7, 0.45, 2, 2.2)
	for side: float in [-1.0, 1.0]:
		_handrail(v, side * 1.38, - half + 0.4, half - 0.4, 2.15, 4)
		v.part(Forge.box(Vector3(0.06, 0.28, 1.3)), Gfx.metal(Color(0.15, 0.16, 0.17), 0.5, 0.5),
				Transform3D(Basis(), Vector3(side * 1.36, 1.9, 0.2)), "TenderStep")
	_buffers(v, half, graphite)
	_coupler(v, half + 0.42, graphite, 0.8)
	return v


static func steam_cab_interior(v: Vehicle, y_floor: float, z_front: float, z_back: float,
		hw_in: float, seat_x: float) -> void:
	var black := Gfx.interior_panel(Color(0.075, 0.075, 0.078), 0.62)
	var red := Gfx.interior_panel(Color(0.22, 0.065, 0.055), 0.62)
	var brass := Gfx.metal(Color(0.52, 0.4, 0.16), 0.3, 0.85)
	var dark := Gfx.metal(Color(0.12, 0.125, 0.13), 0.5, 0.45)
	var steel := Gfx.metal(Color(0.52, 0.54, 0.57), 0.28, 0.92)
	var glass := Gfx.glass(Color(0.04, 0.07, 0.1), 0.03, 0.22)
	var fire := Gfx.emissive(Color(1.0, 0.32, 0.06), 6.0, Color(0.5, 0.08, 0.01))
	var mid := (z_front + z_back) * 0.5
	var span := z_back - z_front
	v.part(Forge.box(Vector3(hw_in * 2.0, 0.08, span)), Gfx.carpet(Color(0.06, 0.055, 0.05)),
			Transform3D(Basis(), Vector3(0, y_floor - 0.04, mid)), "SteamFloor")
	v.part(Forge.box(Vector3(hw_in * 2.0, 0.08, span)), black,
			Transform3D(Basis(), Vector3(0, y_floor + 2.32, mid)), "SteamCeiling")
	for side: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(0.08, 0.95, span)), red,
				Transform3D(Basis(), Vector3(side * hw_in, y_floor + 0.48, mid)), "SteamSideLower")
		v.part(Forge.box(Vector3(0.08, 0.4, span)), black,
				Transform3D(Basis(), Vector3(side * hw_in, y_floor + 2.12, mid)), "SteamSideUpper")
		v.part(Forge.box(Vector3(0.04, 0.85, 1.25)), glass,
				Transform3D(Basis(), Vector3(side * (hw_in - 0.05), y_floor + 1.55, mid - 0.2)), "SteamSideWindow")
	v.part(Forge.box(Vector3(hw_in * 2.0, 2.4, 0.1)), black,
			Transform3D(Basis(), Vector3(0, y_floor + 1.2, z_back)), "SteamBulkhead")
	v.part(Forge.box(Vector3(0.8, 1.9, 0.06)), red,
			Transform3D(Basis(), Vector3(0.78, y_floor + 1.0, z_back + 0.06)), "SteamDoor")

	var back_z := z_front + 0.45
	v.part(Forge.cylinder(1.02, 0.45, 22, 0.0, true, true), dark,
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, y_floor + 1.05, back_z)), "Backhead")
	v.part(Forge.box(Vector3(0.7, 0.62, 0.12)), dark,
			Transform3D(Basis(), Vector3(-0.28, y_floor + 0.72, back_z + 0.3)), "Firebox")
	v.part(Forge.box(Vector3(0.46, 0.4, 0.04)), fire,
			Transform3D(Basis(), Vector3(-0.28, y_floor + 0.72, back_z + 0.38)), "FireboxGlow")
	v.part(Forge.box(Vector3(0.06, 0.06, 0.42)), brass,
			Transform3D(Basis(), Vector3(0.02, y_floor + 0.9, back_z + 0.48)), "FireboxHandle")
	for i in range(6):
		var gx := -0.6 + float(i %3) * 0.32
		var gy := y_floor + 1.5 + float(i / 3) * 0.3
		v.part(Forge.cylinder(0.095, 0.04, 16, 0.0, true, true), brass,
				Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(gx, gy, back_z + 0.28)), "SteamGauge")
		v.part(Forge.cylinder(0.075, 0.045, 16, 0.0, true, true), Gfx.emissive(Color(0.86, 0.8, 0.66), 0.8, Color(0.2, 0.18, 0.12)),
				Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(gx, gy, back_z + 0.3)), "SteamGaugeFace")
	v.part(Forge.box(Vector3(0.9, 0.1, 0.12)), brass,
			Transform3D(Basis(), Vector3(0.1, y_floor + 2.12, back_z + 0.3)), "SteamGaugeHeader")
	for i in range(4):
		v.part(Forge.cylinder(0.035, 0.34, 8, 0.0, true, true), brass,
				Transform3D(Basis(), Vector3(0.5 + float(i) * 0.16, y_floor + 1.8, back_z + 0.2)), "SteamValve")
	v.part(Forge.cylinder(0.06, 0.5, 10, 0.0, true, true), steel,
			Transform3D(Basis(), Vector3(0.45, y_floor + 0.55, back_z + 0.45)), "SteamThrottlePost")
	var thrust := _cab_lever(v, Vector3(-0.85, y_floor + 0.55, back_z + 0.5), Color(0.82, 0.52, 0.12))
	var brake := _cab_lever(v, Vector3(-0.3, y_floor + 0.55, back_z + 0.5), Color(0.72, 0.18, 0.12))
	thrust.name = "Dev_thrust"
	brake.name = "Dev_brake"
	v.cab_parts ["thrust"] = thrust
	v.cab_parts ["brake"] = brake
	var rev := _cab_lever(v, Vector3(0.28, y_floor + 0.55, back_z + 0.45), Color(0.3, 0.32, 0.34))
	rev.name = "Dev_reverser"

	for sx: float in [seat_x, seat_x + 1.35]:
		var seat_z := z_back - 1.25
		v.part(Forge.rounded_box_x(0.56, 0.58, 0.14, 0.05), Gfx.leather(Color(0.13, 0.08, 0.055), 0.6),
				Transform3D(Basis(), Vector3(sx, y_floor + 0.38, seat_z)), "SteamSeat")
		v.part(Forge.rounded_box_x(0.2, 0.58, 0.78, 0.06), Gfx.leather(Color(0.13, 0.08, 0.055), 0.6),
				Transform3D(Basis(Vector3.RIGHT, deg_to_rad(8.0)), Vector3(sx, y_floor + 0.92, seat_z + 0.28)), "SteamSeatBack")
		v.part(Forge.cylinder(0.06, 0.32, 8, 0.0, true, true), dark,
				Transform3D(Basis(), Vector3(sx, y_floor + 0.16, seat_z)), "SteamSeatPost")
	v.cab_anchor = Vector3(seat_x, y_floor + 1.7, z_back - 1.35)

	var lamp := OmniLight3D.new()
	lamp.name = "CabLight"
	lamp.position = Vector3(-0.3, y_floor + 2.05, z_back - 1.1)
	lamp.omni_range = 5.2
	lamp.light_energy = 1.8
	lamp.light_color = Color(1.0, 0.78, 0.56)
	lamp.shadow_enabled = false
	v.attach(lamp)
	var info := Label3D.new()
	info.name = "SteamSpeed"
	info.text = "0"
	info.font_size = 96
	info.pixel_size = 0.002
	info.modulate = Color(1.0, 0.88, 0.66)
	info.outline_size = 0
	info.transform = Transform3D(Basis(), Vector3(0.1, y_floor + 1.9, back_z + 0.34))
	v.attach(info)
	v.cab_parts ["speed_label"] = info
	for dev: String in ["horn", "headlight", "park_brake", "doors", "battery", "cab_key"]:
		var node := Node3D.new()
		node.name = "Dev_" + dev
		node.position = Vector3(0.62 + float(dev.length() %4) * 0.09, y_floor + 1.35, back_z + 0.38)
		v.attach(node)
		v.part(Forge.cylinder(0.035, 0.05, 12, 0.0, true, true), brass,
				Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.62 + float(dev.length() %4) * 0.09, y_floor + 1.35, back_z + 0.41)), "SteamButton")



static func freight_loco(engine_id := "standard", skin_id := "classic", transmission_id := "balanced", parts: Array = []) -> Vehicle:
	var v := Vehicle.new()
	v.name = "FreightLoco"
	v.length = 20.0
	v.width = 3.1
	v.height = 3.95
	v.bogie_spacing = 12.4
	v.wheel_radius = 0.5
	var engine := engine_info(engine_id)
	var skin := skin_info(skin_id)
	var trans := transmission_info(transmission_id)
	v.mass_empty = float(engine["mass"])
	v.mass_loaded = float(engine["mass"])
	v.kind = "loco"
	v.designation = "HXD1"
	v.max_speed = minf(float(engine["speed"]) * float(trans["speed"]), 200.0)
	v.brake_force = float(engine["brake"])
	v.tractive_force = float(engine["traction"]) * float(trans["traction"])
	v.set_meta("engine_id", engine_id)
	v.set_meta("skin_id", skin_id)
	v.set_meta("transmission_id", transmission_id)
	v.set_meta("part_ids", parts.duplicate())

	var body_col: Color = skin["body"]
	var stripe_col: Color = skin["stripe"]
	var accent_col: Color = skin["accent"]
	var body_mat := _paint(body_col)
	var stripe_mat := _paint(stripe_col)
	var accent_mat := _paint(accent_col)
	var mask_mat := Gfx.paint(Color(0.09, 0.105, 0.12), 0.34, 0.22, 0.45)
	var roof_mat := Gfx.metal(Color(0.31, 0.33, 0.35), 0.55, 0.62)
	var dark_mat := Gfx.metal(Color(0.10, 0.11, 0.12), 0.6, 0.45)
	var under_mat := Gfx.metal(Color(0.16, 0.17, 0.19), 0.62, 0.55)
	var glass_mat := Gfx.glass(Color(0.055, 0.08, 0.105), 0.04, 0.22)
	var cab_glass_mat := Gfx.glass(Color(0.095, 0.13, 0.165), 0.03, 0.11)
	var side_glass_mat := Gfx.glass(Color(0.13, 0.17, 0.21), 0.08, 0.04)
	glass_mat.cull_mode = BaseMaterial3D.CULL_BACK
	cab_glass_mat.cull_mode = BaseMaterial3D.CULL_BACK
	# Keep the glazing readable from outside: enough tint to read as glass, but
	# not so mirror-like that the cab interior disappears in daylight.
	cab_glass_mat.metallic = 0.0
	cab_glass_mat.metallic_specular = 0.18
	cab_glass_mat.roughness = 0.06
	cab_glass_mat.rim = 0.10
	glass_mat.metallic = 0.0
	glass_mat.metallic_specular = 0.28
	glass_mat.rim = 0.16
	var frame_mat := Gfx.metal(Color(0.30, 0.31, 0.33), 0.42, 0.62)
	var gasket_mat := Gfx.metal(Color(0.62, 0.64, 0.66), 0.32, 0.68)
	var grille_mat := Gfx.metal(Color(0.19, 0.20, 0.22), 0.7, 0.48)
	var yellow_mat := _paint(Color(0.9, 0.72, 0.12))

	var half_len := 9.6
	var floor_y := 1.14
	var roof_y := 3.78
	var side_x := 1.55
	var front := half_len

	var prof := PackedVector2Array([
		Vector2(-side_x, floor_y),
		Vector2(side_x, floor_y),
		Vector2(side_x, roof_y - 0.36),
		Vector2(1.44, roof_y - 0.12),
		Vector2(1.12, roof_y),
		Vector2(-1.12, roof_y),
		Vector2(-1.44, roof_y - 0.12),
		Vector2(-side_x, roof_y - 0.36),
	])
	# Cut one horizontal band through both outer side shells, then patch every
	# part of that band except the four cab windows. The result is a real
	# opening through the body rather than a dark decal over a solid wall.
	var shell_cuts := [
		Vector4(2.32, 3.38, -1000.0, 1000.0),
		# The Carbody extrusion is local Z 0..2*half_len (world -half_len..+half_len).
		Vector4(1.26, 3.66, half_len - 6.05, half_len - 4.55),
		# Front cab side glazing right behind the windscreen. The interior
		# panel already exists; the outer shell has to be opened as well or
		# the glass is only visible from inside.
		Vector4(2.12, 3.14, half_len - 9.10, half_len - 7.98),
	]
	var body_shell_mat := Gfx.cutout_paint(body_col, shell_cuts, 0.0, 0.62, 0.2)
	v.part(Forge.extrude(prof, half_len * 2.0, true, false), body_shell_mat,
			Transform3D(Basis(), Vector3(0, 0, -half_len)), "Carbody")
	var band_mat := Gfx.cutout_paint(body_col, [], 0.0, 0.62, 0.2)
	# Only the front cab has glazing now; the rear body side is solid and
	# covered by the engine-room louvres.
	var band_spans := [
		[-half_len, -9.10], [-7.98, -7.92], [-6.78, -6.42], [-5.28, -4.85], [-3.85, half_len],
	]
	var band_items := []
	for side: float in [-1.0, 1.0]:
		for span: Array in band_spans:
			var za := float(span[0])
			var zb := float(span[1])
			if zb - za < 0.02:
				continue
			band_items.append([Forge.box(Vector3(0.012, 1.06, zb - za)),
					Transform3D(Basis(), Vector3(side * 1.551, 2.85, (za + zb) * 0.5))])
	v.merged(band_items, band_mat, "SideBandPatch")
	v.part(Forge.box(Vector3(2.78, 0.12, half_len * 2.0 - 0.5)), under_mat,
			Transform3D(Basis(), Vector3(0, floor_y - 0.08, 0)), "Underframe")
	v.part(Forge.box(Vector3(2.72, 0.22, 3.4)), dark_mat,
			Transform3D(Basis(), Vector3(0, floor_y + 0.05, 0)), "CenterEquipment")
	for bz: float in [-3.3, 0.0, 3.3]:
		v.part(Forge.box(Vector3(1.5, 0.38, 1.15)), under_mat,
				Transform3D(Basis(), Vector3(0, floor_y - 0.26, bz)), "UnderEquipment")
	for tx: float in [-1.08, 1.08]:
		v.part(Forge.cylinder(0.2, 3.0, 12, 0.0, true, true), Gfx.metal(Color(0.36, 0.37, 0.39), 0.34, 0.72),
				Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(tx, floor_y - 0.34, 2.1)), "AirTank")
	v.part(Forge.box(Vector3(1.9, 0.3, 0.9)), Gfx.metal(Color(0.26, 0.27, 0.29), 0.32, 0.7),
			Transform3D(Basis(), Vector3(0, floor_y - 0.3, -2.9)), "FuelTank")

	for side: float in [-1.0, 1.0]:
		for zr: Array in [[-9.475, -4.83], [-3.87, 9.475]]:
			var za := float(zr [0])
			var zb := float(zr [1])
			v.part(Forge.box(Vector3(0.012, 0.24, zb - za)), stripe_mat,
					Transform3D(Basis(), Vector3(side * (side_x + 0.009), 2.08, (za + zb) * 0.5)), "SideStripe")
			v.part(Forge.box(Vector3(0.012, 0.045, zb - za)), accent_mat,
					Transform3D(Basis(), Vector3(side * (side_x + 0.01), 1.84, (za + zb) * 0.5)), "SideAccent")
		v.part(Forge.box(Vector3(0.018, 0.08, half_len * 2.0 - 0.45)), under_mat,
				Transform3D(Basis(), Vector3(side * (side_x + 0.01), 1.36, 0)), "SideSkirtLine")

	for end: float in [-1.0, 1.0]:
		var rot := Basis(Vector3.UP, 0.0 if end < 0 else PI)
		var z0 := end * front
		if end < 0:
			v.part(Forge.box(Vector3(2.3, 1.54, 0.06)), body_mat,
					Transform3D(rot, Vector3(0, 1.91, z0)), "FrontEndLower")
			v.part(Forge.box(Vector3(2.3, 0.3, 0.06)), body_mat,
					Transform3D(rot, Vector3(0, 3.63, z0)), "FrontEndTop")
			v.part(Forge.box(Vector3(0.18, 2.64, 0.06)), body_mat,
					Transform3D(rot, Vector3(-1.46, 2.46, z0)), "FrontEndLeft")
			v.part(Forge.box(Vector3(0.18, 2.64, 0.06)), body_mat,
					Transform3D(rot, Vector3(1.46, 2.46, z0)), "FrontEndRight")
			v.part(Forge.box(Vector3(0.15, 1.36, 0.022)), mask_mat,
					Transform3D(rot, Vector3(-1.465, 3.04, z0 + end * 0.03)), "FrontMaskLeft")
			v.part(Forge.box(Vector3(0.15, 1.36, 0.022)), mask_mat,
					Transform3D(rot, Vector3(1.465, 3.04, z0 + end * 0.03)), "FrontMaskRight")
			v.part(Forge.box(Vector3(2.34, 0.22, 0.022)), mask_mat,
					Transform3D(rot, Vector3(0, 3.61, z0 + end * 0.03)), "FrontMaskTop")
			v.part(Forge.box(Vector3(2.34, 0.26, 0.022)), mask_mat,
					Transform3D(rot, Vector3(0, 2.45, z0 + end * 0.03)), "FrontMaskBottom")
		else:
			# Single-cab HXD1: the rear end has a small shunting cab and a
			# central gangway doorway that lines up with the coach corridor.
			var rd_x := 0.0
			var rd_hw := 0.50
			var rd_left_w := rd_x - rd_hw + 1.52
			var rd_right_w := 1.52 - rd_x - rd_hw
			v.part(Forge.box(Vector3(rd_left_w, 2.58, 0.045)), body_mat,
					Transform3D(rot, Vector3(-1.52 + rd_left_w * 0.5, 2.62, z0 + end * 0.01)), "RearCabWall")
			v.part(Forge.box(Vector3(rd_right_w, 2.58, 0.045)), body_mat,
					Transform3D(rot, Vector3(rd_x + rd_hw + rd_right_w * 0.5, 2.62, z0 + end * 0.01)), "RearCabWall")
			v.part(Forge.box(Vector3(rd_hw * 2.0, 0.60, 0.045)), body_mat,
					Transform3D(rot, Vector3(rd_x, 3.60, z0 + end * 0.01)), "RearCabWall")
			v.part(Forge.box(Vector3(rd_hw * 2.0, 0.04, 0.045)), under_mat,
					Transform3D(rot, Vector3(rd_x, 1.16, z0 + end * 0.01)), "RearCabWall")
			for side: float in [-1.0, 1.0]:
				v.part(Forge.box(Vector3(0.12, 2.58, 0.20)), body_mat,
						Transform3D(rot, Vector3(side * 1.50, 2.62, z0 + end * 0.08)), "RearCornerPost")
			v.part(Forge.box(Vector3(3.04, 0.14, 0.28)), body_mat,
					Transform3D(rot, Vector3(0, 3.84, z0 + end * 0.08)), "RearTopCap")
			v.part(Forge.box(Vector3(3.04, 0.14, 0.24)), under_mat,
					Transform3D(rot, Vector3(0, 1.26, z0 + end * 0.08)), "RearBottomCap")
			v.part(Forge.box(Vector3(0.80, 0.72, 0.03)), cab_glass_mat,
					Transform3D(rot, Vector3(-0.98, 3.02, z0 + end * 0.045)), "RearCabWindow")
			for fx: float in [rd_x - rd_hw, rd_x + rd_hw]:
				v.part(Forge.box(Vector3(0.06, 2.08, 0.06)), frame_mat,
						Transform3D(rot, Vector3(fx, 2.28, z0 + end * 0.05)), "RearCabDoorFrame")
			v.part(Forge.box(Vector3(rd_hw * 2.0 + 0.06, 0.06, 0.06)), frame_mat,
					Transform3D(rot, Vector3(rd_x, 3.30, z0 + end * 0.05)), "RearCabDoorFrame")
			var rear_door := MeshInstance3D.new()
			rear_door.name = "EndDoorRear"
			rear_door.mesh = Forge.box(Vector3(rd_hw * 2.0 - 0.04, 1.98, 0.06))
			rear_door.material_override = band_mat
			rear_door.transform = Transform3D(rot, Vector3(rd_x, 2.27, z0 + end * 0.06))
			v.attach(rear_door)
			var rear_win := MeshInstance3D.new()
			rear_win.name = "RearCabDoorWindow"
			rear_win.mesh = Forge.box(Vector3(0.55, 0.55, 0.018))
			rear_win.material_override = cab_glass_mat
			rear_win.position = Vector3(0, 0.42, 0.04)
			rear_door.add_child(rear_win)
			var rear_gangway := Node3D.new()
			rear_gangway.name = "RearGangway"
			v.attach(rear_gangway)
			var rear_rubber := Gfx.rubber(Color(0.045, 0.050, 0.055), 0.82)
			var rear_bellows := []
			for side2: float in [-1.0, 1.0]:
				rear_bellows.append([Forge.box(Vector3(0.03, 2.12, 0.80)),
						Transform3D(Basis(), Vector3(side2 * 0.615, 2.28, z0 + 0.42))])
			rear_bellows.append([Forge.box(Vector3(1.26, 0.03, 0.80)),
					Transform3D(Basis(), Vector3(0, 3.36, z0 + 0.42))])
			rear_bellows.append([Forge.box(Vector3(1.26, 0.03, 0.80)),
					Transform3D(Basis(), Vector3(0, 1.20, z0 + 0.42))])
			for k in range(9):
				var bz2 := z0 + 0.05 + float(k) * 0.09
				for side2: float in [-1.0, 1.0]:
					rear_bellows.append([Forge.box(Vector3(0.07, 2.18, 0.055)),
							Transform3D(Basis(), Vector3(side2 * 0.62, 2.28, bz2))])
				rear_bellows.append([Forge.box(Vector3(1.34, 0.06, 0.055)),
						Transform3D(Basis(), Vector3(0, 3.38, bz2))])
				rear_bellows.append([Forge.box(Vector3(1.34, 0.06, 0.055)),
						Transform3D(Basis(), Vector3(0, 1.18, bz2))])
			var rear_bellows_mesh := MeshInstance3D.new()
			rear_bellows_mesh.name = "RearGangwayBellows"
			rear_bellows_mesh.mesh = Forge.merge_all(rear_bellows)
			rear_bellows_mesh.material_override = rear_rubber
			rear_gangway.add_child(rear_bellows_mesh)
			var rear_floor := MeshInstance3D.new()
			rear_floor.name = "RearGangwayFloor"
			rear_floor.mesh = Forge.box(Vector3(1.04, 0.04, 0.86))
			rear_floor.material_override = Gfx.metal(Color(0.20, 0.21, 0.23), 0.55, 0.45)
			rear_floor.position = Vector3(0, 1.20, z0 + 0.43)
			rear_gangway.add_child(rear_floor)
		if end < 0:
			for wx: float in [-0.67, 0.67]:
				v.part(Forge.box(Vector3(1.28, 0.94, 0.02)), cab_glass_mat,
						Transform3D(rot, Vector3(wx, 3.06, z0 + end * 0.05)), "Windshield")
			for fx: float in [-1.35, 1.35]:
				v.part(Forge.box(Vector3(0.07, 1.12, 0.026)), gasket_mat,
						Transform3D(rot, Vector3(fx, 3.06, z0 + end * 0.061)), "WindscreenPillar")
			v.part(Forge.box(Vector3(0.09, 1.12, 0.026)), gasket_mat,
					Transform3D(rot, Vector3(0, 3.06, z0 + end * 0.061)), "WindscreenMullion")
			v.part(Forge.box(Vector3(2.72, 0.07, 0.026)), gasket_mat,
					Transform3D(rot, Vector3(0, 2.56, z0 + end * 0.061)), "WindscreenSill")
			v.part(Forge.box(Vector3(2.72, 0.08, 0.026)), gasket_mat,
					Transform3D(rot, Vector3(0, 3.55, z0 + end * 0.061)), "WindscreenHeader")
			v.part(Forge.box(Vector3(2.55, 0.3, 0.22)), mask_mat,
					Transform3D(rot, Vector3(0, 3.7, z0 + end * 0.1)), "SunVisor")
			v.part(Forge.box(Vector3(1.45, 0.16, 0.02)), Gfx.emissive(Color(1.0, 0.55, 0.16), 0.9, Color(0.015, 0.018, 0.022)),
					Transform3D(rot, Vector3(0, 3.66, z0 + end * 0.06)), "Destination")
		if end < 0:
			v.part(Forge.box(Vector3(2.9, 0.32, 0.018)), stripe_mat,
					Transform3D(rot, Vector3(0, 2.16, z0 + end * 0.026)), "FrontStripe")
			v.part(Forge.box(Vector3(2.9, 0.045, 0.018)), accent_mat,
					Transform3D(rot, Vector3(0, 1.98, z0 + end * 0.026)), "FrontAccent")
			v.part(Forge.box(Vector3(2.68, 0.15, 0.024)), mask_mat,
					Transform3D(rot, Vector3(0, 2.52, z0 + end * 0.026)), "FrontNumberPanel")
			v.part(Forge.box(Vector3(3.0, 0.36, 0.08)), under_mat,
					Transform3D(rot, Vector3(0, 1.26, z0 + end * 0.03)), "FrontSkirt")
		else:
			# Keep the rear doorway clear: put the blue bands on the two
			# solid side panels instead of running them across the opening.
			for sx: float in [-1.01, 1.01]:
				v.part(Forge.box(Vector3(1.02, 0.32, 0.018)), stripe_mat,
						Transform3D(rot, Vector3(sx, 2.16, z0 + end * 0.026)), "RearStripe")
				v.part(Forge.box(Vector3(1.02, 0.045, 0.018)), accent_mat,
						Transform3D(rot, Vector3(sx, 1.98, z0 + end * 0.026)), "RearAccent")
				v.part(Forge.box(Vector3(0.78, 0.15, 0.024)), mask_mat,
						Transform3D(rot, Vector3(sx, 2.52, z0 + end * 0.026)), "RearNumberPanel")
		v.part(Forge.box(Vector3(2.8, 0.12, 0.06)), under_mat,
				Transform3D(rot, Vector3(0, 0.9, z0 + end * 0.09)), "BufferBeam")
		for lx: float in [-1.08, 1.08]:
			var lamp_basis := rot * Basis(Vector3.RIGHT, -PI * 0.5)
			var lamp_z := z0 + end * 0.07
			v.part(Forge.cylinder(0.20, 0.06, 24, 0.0, true, true),
					Gfx.metal(Color(0.07, 0.08, 0.09), 0.32, 0.72),
					Transform3D(lamp_basis, Vector3(lx, 1.62, lamp_z)), "LampBezel")
			if end < 0:
				v.part(Forge.cylinder(0.145, 0.045, 24, 0.0, true, true),
						Gfx.emissive(Color(1.0, 0.95, 0.82), 10.0, Color(0.9, 0.9, 0.88)),
						Transform3D(lamp_basis, Vector3(lx, 1.62, lamp_z + end * 0.025)), "HeadLamp")
			else:
				v.part(Forge.cylinder(0.145, 0.045, 24, 0.0, true, true),
						Gfx.emissive(Color(1.0, 0.22, 0.14), 3.0, Color(0.3, 0.04, 0.02)),
						Transform3D(lamp_basis, Vector3(lx, 1.62, lamp_z + end * 0.025)), "TailLamp")
			v.part(Forge.box(Vector3(0.16, 0.08, 0.05)), Gfx.emissive(Color(1.0, 0.3, 0.2), 2.0),
					Transform3D(rot, Vector3(lx, 3.58, z0 + end * 0.035)), "MarkerLamp")
		if end < 0:
			v.part(Forge.box(Vector3(1.72, 0.26, 0.035)), grille_mat,
					Transform3D(rot, Vector3(0, 1.82, z0 + end * 0.045)), "FrontGrille")
			for gx: float in [-0.62, -0.31, 0.0, 0.31, 0.62]:
				v.part(Forge.box(Vector3(0.035, 0.18, 0.045)), frame_mat,
						Transform3D(rot, Vector3(gx, 1.82, z0 + end * 0.07)), "FrontGrilleBar")
		v.part(Forge.box(Vector3(1.8, 0.38, 0.04)), yellow_mat,
				Transform3D(rot, Vector3(0, 0.92, z0 + end * 0.035)), "PilotBand")
		if end < 0:
			var wiper_items := []
			for wx: float in [-0.62, 0.62]:
				wiper_items.append([Forge.box(Vector3(0.028, 0.58, 0.022)),
						Transform3D(rot * Basis(Vector3.BACK, 0.28), Vector3(wx, 3.04, z0 + end * 0.078))])
			v.merged(wiper_items, Gfx.rubber(Color(0.035, 0.035, 0.04), 0.9), "Wipers")
		for bx: float in [-0.94, 0.94]:
			v.part(Forge.cylinder(0.16, 0.2, 14, 0.0, true, true), Gfx.metal(Color(0.27, 0.28, 0.3), 0.48, 0.7),
					Transform3D(rot * Basis(Vector3.RIGHT, PI * 0.5 * end), Vector3(bx, 0.98, z0 + end * 0.13)), "Buffer")

	for side: float in [-1.0, 1.0]:
		var sx := side * (side_x + 0.025)
		var srot := Basis(Vector3.UP, PI * 0.5 if side > 0 else - PI * 0.5)
		# Front-most side glazing, matching the interior panel next to the
		# windscreen. This used to be interior-only.
		var fwz := -8.54
		for dy: float in [-0.50, 0.50]:
			v.part(Forge.box(Vector3(0.028, 0.09, 1.24)), frame_mat,
					Transform3D(Basis(), Vector3(side * 1.565, 2.62 + dy, fwz)), "FrontSideWindowFrame")
		for dz: float in [-0.62, 0.62]:
			v.part(Forge.box(Vector3(0.028, 1.08, 0.09)), frame_mat,
					Transform3D(Basis(), Vector3(side * 1.565, 2.62, fwz + dz)), "FrontSideWindowFrame")
		v.part(Forge.box(Vector3(0.018, 0.96, 1.08)), side_glass_mat,
				Transform3D(Basis(), Vector3(side * 1.578, 2.62, fwz)), "FrontSideWindow")
		for wz: float in [-7.35]:
			var fx := side * 1.565
			for dy: float in [-0.535, 0.535]:
				v.part(Forge.box(Vector3(0.028, 0.09, 1.28)), frame_mat,
						Transform3D(Basis(), Vector3(fx, 2.85 + dy, wz)), "SideWindowFrame")
			for dz: float in [-0.595, 0.595]:
				v.part(Forge.box(Vector3(0.028, 1.16, 0.09)), frame_mat,
						Transform3D(Basis(), Vector3(fx, 2.85, wz + dz)), "SideWindowFrame")
			v.part(Forge.box(Vector3(0.018, 1.0, 1.1)), side_glass_mat,
					Transform3D(Basis(), Vector3(side * 1.578, 2.85, wz)), "SideWindow")
			v.part(Forge.box(Vector3(0.035, 0.055, 1.36)), frame_mat,
					Transform3D(Basis(), Vector3(side * 1.585, 2.33, wz)), "WindowSill")
		for lz: float in [-2.2, 0.35, 2.9, 5.45, 8.0]:
			v.part(Forge.box(Vector3(2.34, 1.44, 0.025)), grille_mat,
					Transform3D(srot, Vector3(side * 1.57, 2.93, lz)), "LouvrePanel")
			for k in range(6):
				v.part(Forge.box(Vector3(2.2, 0.075, 0.022)), frame_mat,
						Transform3D(srot, Vector3(side * 1.585, 2.4 + float(k) * 0.2, lz)), "LouvreSlat")
			for fy: float in [-0.76, 0.76]:
				v.part(Forge.box(Vector3(2.42, 0.06, 0.03)), frame_mat,
						Transform3D(srot, Vector3(side * 1.59, 2.93 + fy, lz)), "LouvreFrame")
		for dz: float in [-5.55]:
			for fz: float in [-0.45, 0.45]:
				v.part(Forge.box(Vector3(0.06, 2.34, 0.06)), frame_mat,
						Transform3D(Basis(), Vector3(side * 1.565, 2.47, dz + fz)), "CabDoorFrame")
			for fy: float in [0.95]:
				v.part(Forge.box(Vector3(0.06, 0.06, 0.96)), frame_mat,
						Transform3D(Basis(), Vector3(side * 1.565, 2.65 + fy, dz)), "CabDoorFrame")
			v.part(Forge.box(Vector3(0.06, 0.035, 0.96)), dark_mat,
					Transform3D(Basis(), Vector3(side * 1.565, 1.30, dz)), "CabDoorSill")
			v.part(Forge.box(Vector3(0.08, 0.06, 2.05)), frame_mat,
					Transform3D(Basis(), Vector3(side * 1.61, 3.62, dz)), "CabDoorTrack")
			v.part(Forge.box(Vector3(0.12, 0.10, 1.02)), dark_mat,
					Transform3D(Basis(), Vector3(side * 1.555, 1.28, dz)), "CabDoorThreshold")
			var leaf := Node3D.new()
			leaf.name = "CabDoorLeaf"
			leaf.position = Vector3(side * 1.575, 2.52, dz + 0.43)
			v.attach(leaf)
			# Hollow door leaf: the upper window is a real opening, so it is
			# transparent from both inside the cab and the platform.
			var door_w := 1.04
			var door_h := 2.28
			var door_t := 0.04
			var win_w := 0.50
			var win_h := 0.50
			var win_cy := 0.55
			var win_y0 := win_cy - win_h * 0.5
			var win_y1 := win_cy + win_h * 0.5
			var stile_w := (door_w - win_w) * 0.5
			var bottom_h := win_y0 + door_h * 0.5
			var top_h := door_h * 0.5 - win_y1
			var panel_items := []
			for sz: float in [-1.0, 1.0]:
				panel_items.append([Forge.box(Vector3(door_t, door_h, stile_w)),
						Transform3D(Basis(), Vector3(0, 0, sz * (win_w * 0.5 + stile_w * 0.5)))])
			panel_items.append([Forge.box(Vector3(door_t, bottom_h, door_w)),
					Transform3D(Basis(), Vector3(0, - door_h * 0.5 + bottom_h * 0.5, 0))])
			panel_items.append([Forge.box(Vector3(door_t, top_h, door_w)),
					Transform3D(Basis(), Vector3(0, door_h * 0.5 - top_h * 0.5, 0))])
			var panel := MeshInstance3D.new()
			panel.name = "CabDoorPanel"
			panel.mesh = Forge.merge_all(panel_items)
			panel.material_override = body_mat
			panel.position = Vector3(0.0, 0.0, -0.43)
			leaf.add_child(panel)
			var panel_edge := MeshInstance3D.new()
			panel_edge.name = "CabDoorEdge"
			panel_edge.mesh = Forge.box(Vector3(0.045, 2.34, 0.06))
			panel_edge.material_override = frame_mat
			panel_edge.position = Vector3(0.0, 0.0, -0.95)
			leaf.add_child(panel_edge)
			# Trim the inner face of the lower door panel so the opposite
			# (closed) cab door no longer reads as a white board when the
			# platform-side door is open.
			var inner_panel := MeshInstance3D.new()
			inner_panel.name = "CabDoorInnerPanel"
			inner_panel.mesh = Forge.box(Vector3(0.012, 1.22, 0.80))
			inner_panel.material_override = Gfx.interior_panel(Color(0.26, 0.29, 0.32), 0.55)
			inner_panel.position = Vector3(-side * 0.034, -0.51, -0.43)
			leaf.add_child(inner_panel)
			var door_window := MeshInstance3D.new()
			door_window.name = "CabDoorWindow"
			door_window.mesh = Forge.box(Vector3(0.016, win_h, win_w))
			door_window.material_override = side_glass_mat
			door_window.position = Vector3(0.0, win_cy, -0.43)
			leaf.add_child(door_window)
			var door_win_frame := MeshInstance3D.new()
			door_win_frame.name = "CabDoorWindowFrame"
			var frame_items := []
			for fy: float in [win_y0 - 0.02, win_y1 + 0.02]:
				frame_items.append([Forge.box(Vector3(0.026, 0.04, win_w + 0.08)),
						Transform3D(Basis(), Vector3(0, fy, -0.43))])
			for fz: float in [- win_w * 0.5 - 0.02, win_w * 0.5 + 0.02]:
				frame_items.append([Forge.box(Vector3(0.026, win_h + 0.06, 0.04)),
						Transform3D(Basis(), Vector3(0, win_cy, -0.43 + fz))])
			door_win_frame.mesh = Forge.merge_all(frame_items)
			door_win_frame.material_override = frame_mat
			leaf.add_child(door_win_frame)
			var door_stripe := MeshInstance3D.new()
			door_stripe.name = "CabDoorStripe"
			door_stripe.mesh = Forge.box(Vector3(0.012, 0.24, 0.86))
			door_stripe.material_override = stripe_mat
			door_stripe.position = Vector3(side * 0.031, -0.57, -0.43)
			leaf.add_child(door_stripe)
			var door_accent := MeshInstance3D.new()
			door_accent.name = "CabDoorAccent"
			door_accent.mesh = Forge.box(Vector3(0.012, 0.045, 0.86))
			door_accent.material_override = accent_mat
			door_accent.position = Vector3(side * 0.032, -0.81, -0.43)
			leaf.add_child(door_accent)
			var handle := MeshInstance3D.new()
			handle.name = "CabDoorHandle"
			handle.mesh = Forge.box(Vector3(0.05, 0.07, 0.2))
			handle.material_override = Gfx.metal(Color(0.62, 0.64, 0.66), 0.3, 0.8)
			handle.position = Vector3(side * 0.04, -0.34, -0.72)
			leaf.add_child(handle)
			leaf.set_meta("closed_pos", leaf.position)
			leaf.set_meta("door_side", int(side))
			leaf.set_meta("plug_slide", true)
			leaf.set_meta("slide_out", Vector3(side * 0.06, 0.0, 0.0))
			leaf.set_meta("slide_side", Vector3(0.0, 0.0, 1.02))
			v.door_leaves.append(leaf)
		var step_items := []
		var step_edges := []
		for sz: float in [-5.55]:
			step_items.append([Forge.box(Vector3(0.52, 0.055, 0.58)), Transform3D(Basis(), Vector3(side * 1.62, 0.62, sz))])
			step_items.append([Forge.box(Vector3(0.52, 0.055, 0.58)), Transform3D(Basis(), Vector3(side * 1.62, 0.92, sz))])
			step_edges.append([Forge.box(Vector3(0.05, 0.06, 0.58)), Transform3D(Basis(), Vector3(side * 1.82, 0.65, sz))])
			step_edges.append([Forge.box(Vector3(0.05, 0.06, 0.58)), Transform3D(Basis(), Vector3(side * 1.82, 0.95, sz))])
		v.merged(step_items, dark_mat, "Steps")
		v.merged(step_edges, yellow_mat, "StepEdges")

	var roof_items := []
	roof_items.append([Forge.box(Vector3(2.58, 0.06, 12.4)), Transform3D(Basis(), Vector3(0, roof_y + 0.045, 0))])
	for rz: float in [-4.6, -1.5, 2.0, 5.0]:
		roof_items.append([Forge.box(Vector3(2.1, 0.2, 1.35)), Transform3D(Basis(), Vector3(0, roof_y + 0.16, rz))])
	v.merged(roof_items, roof_mat, "RoofEquipment")
	var cap_items := []
	for rz: float in [-7.0, -4.0, 1.0, 4.0, 7.0]:
		for cx: float in [-0.92, 0.92]:
			cap_items.append([Forge.cylinder(0.075, 0.24, 10, 0.0, true, true),
					Transform3D(Basis(), Vector3(cx, roof_y + 0.18, rz))])
	v.merged(cap_items, Gfx.paint(Color(0.58, 0.56, 0.52), 0.38, 0.18, 0.45), "Insulators")
	var rail_items := []
	for side: float in [-1.0, 1.0]:
		# Split the side handrail around the cab door opening so it does not
		# bridge the cut-out when the door is open.
		for rail_seg: Array in [[- front + 0.25, -6.05], [-5.05, front - 0.25]]:
			rail_items.append(Forge.tube_between(
					Vector3(side * 1.6, 2.32, float(rail_seg[0])),
					Vector3(side * 1.6, 2.32, float(rail_seg[1])), 0.022, 6))
	for end: float in [-1.0, 1.0]:
		for lx: float in [-1.35, 1.35]:
			rail_items.append(Forge.tube_between(Vector3(lx, 1.28, end *(front - 0.2)),
					Vector3(lx, 3.2, end *(front - 0.2)), 0.022, 6))
	v.merged(rail_items, yellow_mat, "Handrails")

	_coupler(v, - front - 0.68, dark_mat)
	_coupler(v, front + 0.68, dark_mat)
	_build_freight_bogie(v, -6.2, 0.5)
	_build_freight_bogie(v, 6.2, 0.5)

	var panto := _pantograph(v, Transform3D(Basis(), Vector3(0, roof_y + 0.1, 3.7)))
	v.pantographs.append(panto)
	var panto2 := _pantograph(v, Transform3D(Basis(), Vector3(0, roof_y + 0.1, -3.7)))
	v.pantographs.append(panto2)

	var light_l := SpotLight3D.new()
	light_l.position = Vector3(-1.08, 1.85, - front - 0.12)
	light_l.light_color = Color(1.0, 0.96, 0.86)
	light_l.light_energy = 30.0
	light_l.spot_range = 360.0
	light_l.spot_angle = 29.0
	light_l.spot_attenuation = 0.6
	light_l.rotation_degrees = Vector3(-0.6, 0, 0)
	v.attach(light_l)
	v.head_lights.append(light_l)
	var light_r := SpotLight3D.new()
	light_r.position = Vector3(1.08, 1.85, - front - 0.12)
	light_r.light_color = Color(1.0, 0.96, 0.86)
	light_r.light_energy = 30.0
	light_r.spot_range = 360.0
	light_r.spot_angle = 29.0
	light_r.spot_attenuation = 0.6
	light_r.rotation_degrees = Vector3(-0.6, 0, 0)
	v.attach(light_r)
	v.head_lights.append(light_r)
	# Dedicated long-range high-beam projectors. They are toggled separately
	# from the marker/head lamps and only burn when the main headlights are on.
	for hx: float in [-1.08, 1.08]:
		var high := SpotLight3D.new()
		high.name = "HighBeam"
		high.position = Vector3(hx, 2.05, - front - 0.14)
		high.light_color = Color(0.92, 0.96, 1.0)
		high.light_energy = 62.0
		high.spot_range = 620.0
		high.spot_angle = 12.5
		high.spot_attenuation = 0.38
		high.rotation_degrees = Vector3(-1.2, 0.0, 0.0)
		high.shadow_enabled = false
		high.set_meta("high_beam", true)
		v.attach(high)
		v.head_lights.append(high)
	_fill_light(v, Vector3(0.0, 1.45, - front - 0.05), Color(1.0, 0.95, 0.84))

	freight_cab_interior(v, 1.16, - front + 0.05, - front + 6.05, 1.5, -0.72)
	_loco_rear_interior(v, 1.16, roof_y, body_mat, dark_mat, frame_mat)
	if not parts.is_empty():
		_add_loco_parts(v, parts, front, roof_y, side_x, body_mat)
	_merge_static_parts(v)
	var wheel_top := v.wheel_radius * 2.0
	print("[loco-check] length=%.2f bogie=%.2f wheel_r=%.2f wheel_top=%.2f floor=%.2f bogie_z=%.2f/%.2f panto_head=%.2f"
			% [v.length, v.bogie_spacing, v.wheel_radius, wheel_top, floor_y, -v.bogie_spacing * 0.5, v.bogie_spacing * 0.5, roof_y + 0.1 + 0.42 + 0.98])
	return v


static func _merge_static_parts(v: Vehicle) -> void:
	var groups := {}
	for child in v.body_root().get_children():
		var mi := child as MeshInstance3D
		if mi == null:
			continue
		var nm := String(mi.name)
		if nm.begins_with("Cab") or nm.begins_with("Dev") or nm.begins_with("Wheel") \
				or nm.begins_with("EndDoor"):
			continue
		var mat := mi.material_override
		if mat == null:
			continue
		var key := mat.get_instance_id()
		if not groups.has(key):
			groups [key] = {"mat": mat, "items": []}
		groups [key] ["items"].append([mi.mesh, mi.transform])
		v.body_root().remove_child(mi)
		mi.queue_free()
	var index := 0
	for g: Dictionary in groups.values():
		var items: Array = g ["items"]
		if items.is_empty():
			continue
		var merged := MeshInstance3D.new()
		merged.name = "MergedBody%d" %index
		merged.mesh = Forge.merge_all(items)
		merged.material_override = g ["mat"]
		v.attach(merged)
		index += 1

static func _build_freight_bogie(v: Vehicle, z_center: float, wheel_r: float) -> Node3D:
	return _build_hxd1_bogie(v, z_center, wheel_r)


static func _add_hxd1_wheelset(v: Vehicle, bogie: Node3D, wheel_r: float, az: float) -> void:
	var axle_node := Node3D.new()
	axle_node.name = "Wheelset%d" %(v.wheels.size() + 1)
	axle_node.position = Vector3(0, wheel_r, az)
	bogie.add_child(axle_node)
	var axle := MeshInstance3D.new()
	axle.mesh = Forge.cylinder(0.085, 2.12, 14, -1.06, true, true)
	axle.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO)
	axle.material_override = Gfx.metal(Color(0.52, 0.54, 0.56), 0.3, 0.9)
	axle_node.add_child(axle)
	var wheel := _wheel_mesh(wheel_r)
	var wheel_mat := Gfx.metal(Color(0.72, 0.735, 0.75), 0.18, 0.96)
	var hub_mat := Gfx.metal(Color(0.56, 0.58, 0.60), 0.28, 0.88)
	var bolt_mat := Gfx.metal(Color(0.78, 0.80, 0.82), 0.22, 0.94)
	var span := (Config.GAUGE - 0.10) * 0.5
	for side: float in [-1.0, 1.0]:
		var w := MeshInstance3D.new()
		w.mesh = wheel
		w.material_override = wheel_mat
		w.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(side * span, 0, 0))
		axle_node.add_child(w)
		# Four bolt heads sit on the axlebox cover face but are parented to the
		# wheelset, so they visibly turn with the wheel.
		var hub := MeshInstance3D.new()
		hub.mesh = Forge.cylinder(0.087, 0.035, 18, - 0.0175, true, true)
		hub.material_override = hub_mat
		hub.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5),
				Vector3(side *(span + 0.068), 0, 0))
		axle_node.add_child(hub)
		for k in range(4):
			var ba := PI * 0.25 + PI * 0.5 * float(k)
			var bolt := MeshInstance3D.new()
			bolt.mesh = Forge.cylinder(0.018, 0.026, 8, - 0.013, true, true)
			bolt.material_override = bolt_mat
			bolt.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5),
					Vector3(side * 1.305, cos(ba) * 0.118, sin(ba) * 0.118))
			axle_node.add_child(bolt)
		# Large inboard brake disc.
		var disc := MeshInstance3D.new()
		disc.mesh = Forge.cylinder(0.335, 0.045, 28, -0.0225, true, true)
		disc.material_override = Gfx.metal(Color(0.84, 0.86, 0.88), 0.20, 0.94)
		disc.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(side * 0.44, 0, 0))
		axle_node.add_child(disc)
	v.add_wheel(axle_node, wheel_r)


static func _build_hxd1_bogie(v: Vehicle, z_center: float, wheel_r: float) -> Node3D:
	var bogie := Node3D.new()
	bogie.name = "Bogie"
	bogie.position = Vector3(0, 0, z_center)
	v.attach(bogie)

	var frame_mat := Gfx.metal(Color(0.45, 0.47, 0.49), 0.48, 0.55)
	var frame_dark := Gfx.metal(Color(0.33, 0.35, 0.37), 0.55, 0.5)
	var steel := Gfx.metal(Color(0.66, 0.68, 0.70), 0.26, 0.9)
	var rubber := Gfx.metal(Color(0.035, 0.035, 0.04), 0.92, 0.04)
	var motor_mat := Gfx.metal(Color(0.32, 0.335, 0.35), 0.52, 0.55)
	var motor_cap := Gfx.metal(Color(0.46, 0.48, 0.50), 0.42, 0.68)
	var spring_mat := Gfx.metal(Color(0.45, 0.47, 0.49), 0.4, 0.68)
	var damper_mat := Gfx.metal(Color(0.30, 0.30, 0.31), 0.38, 0.62)
	var brake_mat := Gfx.metal(Color(0.32, 0.33, 0.34), 0.38, 0.78)
	var hose_mat := Gfx.metal(Color(0.045, 0.048, 0.052), 0.82, 0.18)

	var axle_z := [-1.35, 1.35]
	var x_frame := 1.05
	var frame_half := 1.62
	var spring_primary := _coil_spring(0.09, 0.28, 5.0, 0.017, 24)
	var spring_secondary := _coil_spring(0.065, 0.16, 4.0, 0.012, 20)
	var frame_items := []
	var air_items := []
	var air_rubber := []
	var spring_items := []
	var damper_items := []
	var damper_rod_items := []
	var motor_items := []
	var brake_items := []
	var detail_items := []
	var hose_items := []

	# Box-section side beams, central air-spring seats and end pedestal jaws.
	for side: float in [-1.0, 1.0]:
		var x := side * x_frame
		# Open box-section side frame: top/bottom chords and posts leave large
		# windows through which the motors, discs and calipers remain visible.
		frame_items.append([Forge.box(Vector3(0.30, 0.14, frame_half * 2.0)),
				Transform3D(Basis(), Vector3(x, 0.90, 0))])
		frame_items.append([Forge.box(Vector3(0.30, 0.12, frame_half * 2.0)),
				Transform3D(Basis(), Vector3(x, 0.52, 0))])
		for pz: float in [-0.68, 0.68]:
			frame_items.append([Forge.box(Vector3(0.32, 0.38, 0.16)),
					Transform3D(Basis(), Vector3(x, 0.71, pz))])
		for ez: float in [-1.0, 1.0]:
			var ezp := ez * frame_half
			frame_items.append([Forge.box(Vector3(0.34, 0.30, 0.22)),
					Transform3D(Basis(), Vector3(x, 0.77, ezp))])
			frame_items.append([Forge.box(Vector3(0.34, 0.17, 0.30)),
					Transform3D(Basis(), Vector3(x, 0.66, ezp - ez * 0.16))])
			frame_items.append([Forge.box(Vector3(0.055, 0.36, 0.58)),
					Transform3D(Basis(), Vector3(x + side * 0.15, 0.71, ez * 1.08))])
		# Axlebox pedestal jaws and covers.
		for az: float in axle_z:
			frame_items.append([Forge.box(Vector3(0.30, 0.28, 0.44)),
					Transform3D(Basis(), Vector3(x, 0.64, az))])
			frame_items.append([Forge.box(Vector3(0.30, 0.20, 0.44)),
					Transform3D(Basis(), Vector3(x, 0.36, az))])
			for jz: float in [-0.25, 0.25]:
				frame_items.append([Forge.box(Vector3(0.33, 0.52, 0.10)),
						Transform3D(Basis(), Vector3(x, 0.50, az + jz))])
			var fx := side * (x_frame + 0.17)
			detail_items.append([Forge.cylinder(0.190, 0.025, 24, 0.0, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(fx + side * 0.012, 0.50, az))])
			detail_items.append([Forge.cylinder(0.150, 0.040, 24, 0.0, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(fx + side * 0.040, 0.50, az))])
			detail_items.append([Forge.cylinder(0.060, 0.050, 16, 0.0, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(fx + side * 0.068, 0.50, az))])
			# Outboard primary spring bracket tied back to the side beam.
			frame_items.append([Forge.box(Vector3(0.30, 0.09, 0.62)),
					Transform3D(Basis(), Vector3(side * (x_frame + 0.24), 0.755, az))])
			frame_items.append([Forge.box(Vector3(0.42, 0.08, 0.22)),
					Transform3D(Basis(), Vector3(side * (x_frame + 0.13), 0.78, az))])
			for sz: float in [az - 0.15, az + 0.15]:
				spring_items.append([spring_primary, Transform3D(Basis(),
						Vector3(side * (x_frame + 0.24), 0.54, sz))])
				detail_items.append([Forge.cylinder(0.13, 0.025, 16, 0.0, true, true),
						Transform3D(Basis(), Vector3(side * (x_frame + 0.24), 0.52, sz))])
				detail_items.append([Forge.cylinder(0.12, 0.025, 16, 0.0, true, true),
						Transform3D(Basis(), Vector3(side * (x_frame + 0.24), 0.83, sz))])
			# Outboard vertical damper with a visible cylinder, piston rod,
			# top/bottom eyes and mounting brackets.
			var d0 := Vector3(side * (x_frame + 0.22), 0.50, az + 0.24)
			var d1 := Vector3(side * (x_frame + 0.18), 0.96, az + 0.10)
			_append_vertical_damper(damper_items, damper_rod_items, d0, d1, 0.055)
			frame_items.append([Forge.box(Vector3(0.26, 0.08, 0.18)),
					Transform3D(Basis(), Vector3(side * (x_frame + 0.10), 0.96, az + 0.10))])
			frame_items.append([Forge.box(Vector3(0.26, 0.08, 0.18)),
					Transform3D(Basis(), Vector3(side * (x_frame + 0.10), 0.50, az + 0.24))])
		# Air spring seat and air spring.
		frame_items.append([Forge.cylinder(0.335, 0.075, 24, 0.0, true, true),
				Transform3D(Basis(), Vector3(x, 0.955, 0))])
		air_items.append([Forge.cylinder(0.305, 0.035, 24, 0.0, true, true),
				Transform3D(Basis(), Vector3(x, 0.985, 0))])
		air_rubber.append([Forge.cylinder(0.275, 0.145, 24, 0.0, true, true),
				Transform3D(Basis(), Vector3(x, 1.055, 0))])
		for ry: float in [1.005, 1.055, 1.105]:
			air_rubber.append([Forge.cylinder(0.288, 0.018, 24, 0.0, true, true),
					Transform3D(Basis(), Vector3(x, ry, 0))])
		air_items.append([Forge.cylinder(0.30, 0.040, 24, 0.0, true, true),
				Transform3D(Basis(), Vector3(x, 1.145, 0))])
		detail_items.append([Forge.cylinder(0.035, 0.055, 12, 0.0, true, true),
				Transform3D(Basis(), Vector3(x, 1.165, 0))])
		hose_items.append_array(Forge.tube_between(
				Vector3(x, 1.02, -0.24), Vector3(x, 0.87, -0.44), 0.022, 6))
	# One narrow central cross-tie keeps the frame open so the motors, discs
	# and calipers remain visible from the side.
	frame_items.append([Forge.box(Vector3(1.95, 0.15, 0.24)),
			Transform3D(Basis(), Vector3(0, 0.80, 0))])
	detail_items.append([Forge.cylinder(0.19, 0.09, 18, 0.0, true, true),
			Transform3D(Basis(), Vector3(0, 0.87, 0))])
	# Anti-roll bar and links.
	detail_items.append_array(Forge.tube_between(
			Vector3(-x_frame, 0.70, 0.63), Vector3(x_frame, 0.70, 0.63), 0.032, 8))
	for side2: float in [-1.0, 1.0]:
		detail_items.append_array(Forge.tube_between(
				Vector3(side2 * x_frame, 0.70, 0.63),
				Vector3(side2 * x_frame, 0.86, 0.53), 0.026, 8))
	# Traction rods along the frame.
	for tx: float in [-0.46, 0.46]:
		detail_items.append_array(Forge.tube_between(
				Vector3(tx, 0.86, -1.22), Vector3(tx, 0.86, 1.22), 0.022, 6))
		for tz: float in [-1.22, 1.22]:
			detail_items.append([Forge.box(Vector3(0.10, 0.08, 0.16)),
					Transform3D(Basis(), Vector3(tx, 0.86, tz))])

	# Traction motors, gearboxes, cooling ducts and brake gear.
	for az: float in axle_z:
		# The motor barrel is centred on the axle; earlier it grew from the
		# origin and therefore sat entirely on one side of the wheelset.
		motor_items.append([Forge.cylinder(0.285, 1.16, 20, - 0.58, true, true),
				Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, 0.40, az))])
		for mx: float in [-0.40, -0.20, 0.20, 0.40]:
			motor_items.append([Forge.cylinder(0.298, 0.026, 20, - 0.013, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(mx, 0.40, az))])
		for side: float in [-1.0, 1.0]:
			motor_items.append([Forge.cylinder(0.295, 0.055, 20, - 0.0275, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5),
							Vector3(side * 0.585, 0.40, az))])
			motor_items.append([Forge.box(Vector3(0.40, 0.48, 0.58)),
					Transform3D(Basis(), Vector3(side * 0.72, 0.36, az + 0.18))])
			motor_items.append([Forge.cylinder(0.13, 0.12, 14, - 0.06, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5),
							Vector3(side * 0.92, 0.36, az + 0.18))])
			detail_items.append_array(Forge.tube_between(
					Vector3(side * 0.60, 0.52, az), Vector3(side * x_frame, 0.78, az), 0.034, 7))
		# Symmetric motor nose suspension under the axle centreline.
		motor_items.append([Forge.box(Vector3(0.34, 0.22, 0.34)),
				Transform3D(Basis(), Vector3(0, 0.22, az))])
		detail_items.append_array(Forge.tube_between(
				Vector3(- 0.36, 0.24, az), Vector3(- x_frame, 0.52, az), 0.030, 7))
		detail_items.append_array(Forge.tube_between(
				Vector3(0.36, 0.24, az), Vector3(x_frame, 0.52, az), 0.030, 7))
		# Corrugated cooling ducts.
		for side: float in [-1.0, 1.0]:
			var a := Vector3(side * 0.18, 0.68, az + 0.08)
			var b := Vector3(side * (x_frame + 0.02), 0.82, az + 0.24)
			hose_items.append_array(Forge.tube_between(a, a.lerp(b, 0.52) + Vector3(0, 0.06, 0), 0.055, 8))
			hose_items.append_array(Forge.tube_between(a.lerp(b, 0.52) + Vector3(0, 0.06, 0), b, 0.055, 8))
			for hx: float in [0.30, 0.62, 0.78]:
				detail_items.append([Forge.cylinder(0.063, 0.018, 12, 0.0, true, true),
						Transform3D(Forge.basis_from_y(b - a), a.lerp(b, hx))])
		# Outboard brake discs and calipers.
		for side: float in [-1.0, 1.0]:
			var bx := side * 0.66
			brake_items.append([Forge.box(Vector3(0.14, 0.30, 0.18)),
					Transform3D(Basis(Vector3.BACK, side * 0.10), Vector3(bx, 0.40, az))])
			brake_items.append([Forge.box(Vector3(0.10, 0.10, 0.32)),
					Transform3D(Basis(), Vector3(side * 0.52, 0.30, az + 0.34))])
			detail_items.append_array(Forge.tube_between(
					Vector3(side * 0.66, 0.62, az), Vector3(side * 0.66, 0.40, az), 0.020, 6))
		# Brake cylinder / reservoir.
		brake_items.append([Forge.cylinder(0.135, 0.55, 16, 0.0, true, true),
				Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.55, 0.62, 0.66))])
		brake_items.append([Forge.cylinder(0.10, 0.44, 14, 0.0, true, true),
				Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.55, 0.66, 0.66))])

	# Loom and coiled cable at one end.
	for side: float in [-1.0, 1.0]:
		var cx := side * 0.80
		var cy := 0.70
		var cz := 1.18
		for k in range(8):
			var a0 := TAU * float(k) / 8.0
			var a1 := TAU * float(k + 1) / 8.0
			var p0 := Vector3(cx + 0.08 * cos(a0), cy + 0.12 * sin(a0), cz)
			var p1 := Vector3(cx + 0.08 * cos(a1), cy + 0.12 * sin(a1), cz)
			hose_items.append_array(Forge.tube_between(p0, p1, 0.018, 6))
		hose_items.append_array(Forge.tube_between(
				Vector3(side * 0.80, 0.70, 0.95), Vector3(side * 0.80, 0.84, -0.35), 0.018, 6))
	# Small equipment boxes on the side beams.
	for side: float in [-1.0, 1.0]:
		frame_items.append([Forge.box(Vector3(0.20, 0.26, 0.44)),
				Transform3D(Basis(), Vector3(side * (x_frame + 0.18), 0.70, -1.00))])
		detail_items.append([Forge.cylinder(0.055, 0.04, 12, 0.0, true, true),
				Transform3D(Basis(Vector3.BACK, PI * 0.5),
						Vector3(side * (x_frame + 0.29), 0.74, -1.00))])
		var nm := Label3D.new()
		nm.name = "BogieMarking"
		nm.text = "HXD1"
		nm.font_size = 18
		nm.pixel_size = 0.0018
		nm.modulate = Color(0.82, 0.85, 0.88)
		nm.outline_size = 1
		nm.outline_modulate = Color(0.06, 0.07, 0.08)
		nm.position = Vector3(side * (x_frame + 0.20), 0.84, -0.70)
		nm.rotation_degrees = Vector3(0, side * 90.0, 0)
		bogie.add_child(nm)

	var frame_root := Node3D.new()
	frame_root.name = "BogieFrameRoot"
	bogie.add_child(frame_root)
	for item: Array in [
		[frame_items, frame_mat, "BogieFrame"],
		[air_items, steel, "AirSpringPlates"],
		[air_rubber, rubber, "AirSprings"],
		[spring_items, spring_mat, "PrimarySprings"],
		[damper_items, damper_mat, "Dampers"],
		[damper_rod_items, steel, "DamperRods"],
		[motor_items, motor_mat, "TractionMotors"],
		[brake_items, brake_mat, "BrakeGear"],
		[detail_items, steel, "BogieDetails"],
		[hose_items, hose_mat, "CablesAndHoses"],
	]:
		var items: Array = item[0]
		if items.is_empty():
			continue
		var mi := MeshInstance3D.new()
		mi.name = String(item[2])
		mi.mesh = Forge.merge_all(items)
		mi.material_override = item[1]
		frame_root.add_child(mi)
	# Motor housings use a slightly lighter cap material on the ends.
	for az: float in axle_z:
		_add_hxd1_wheelset(v, bogie, wheel_r, az)
	v.bogie_frames.append(frame_root)
	return bogie


static func _legacy_build_freight_bogie(v: Vehicle, z_center: float, wheel_r: float) -> Node3D:
	var bogie := Node3D.new()
	bogie.name = "FreightBogie"
	bogie.position = Vector3(0, 0, z_center)
	v.attach(bogie)

	var frame_mat := Gfx.metal(Color(0.15, 0.16, 0.17), 0.62, 0.5)
	var equip_mat := Gfx.metal(Color(0.24, 0.25, 0.26), 0.55, 0.55)
	var silver := Gfx.metal(Color(0.56, 0.58, 0.6), 0.3, 0.8)
	var wheel_mat := Gfx.metal(Color(0.22, 0.23, 0.24), 0.4, 0.8)
	var spring_mat := Gfx.metal(Color(0.52, 0.53, 0.54), 0.32, 0.78)
	var damper_mat := Gfx.metal(Color(0.72, 0.62, 0.22), 0.3, 0.65)
	var motor_mat := Gfx.metal(Color(0.08, 0.09, 0.1), 0.55, 0.65)
	var brake_mat := Gfx.metal(Color(0.1, 0.1, 0.11), 0.72, 0.35)
	var spring_mesh := _coil_spring(0.13, 0.28, 5.5, 0.018, 26)
	var spring_big := _coil_spring(0.2, 0.3, 4.5, 0.022, 28)
	var axle_z := [-1.42, 1.42]
	var frame_len := 4.55
	var x_frame := 1.06

	var frame_items := []
	var equip_items := []
	var spring_items := []
	var secondary_items := []
	var damper_items := []
	var motor_items := []
	var brake_items := []
	var detail_items := []

	for side: float in [-1.0, 1.0]:
		var x := side * x_frame
		frame_items.append([Forge.rounded_box_x(frame_len, 0.28, 0.2, 0.06),
				Transform3D(Basis(), Vector3(x, wheel_r + 0.3, 0))])
		frame_items.append([Forge.rounded_box_x(frame_len, 0.32, 0.14, 0.05),
				Transform3D(Basis(), Vector3(x, wheel_r + 0.06, 0))])
		for ez: float in [-1.9, 1.9]:
			frame_items.append([Forge.box(Vector3(0.34, 0.3, 0.28)),
					Transform3D(Basis(), Vector3(x, wheel_r + 0.3, ez))])
			frame_items.append([Forge.box(Vector3(0.38, 0.18, 0.2)),
					Transform3D(Basis(), Vector3(x, wheel_r + 0.07, ez))])
		for az in axle_z:
			frame_items.append([Forge.box(Vector3(0.26, 0.32, 0.42)),
					Transform3D(Basis(), Vector3(x, wheel_r + 0.02, az))])
			frame_items.append([Forge.box(Vector3(0.36, 0.14, 0.54)),
					Transform3D(Basis(), Vector3(side * (x_frame + 0.12), wheel_r + 0.16, az))])
			for sz: float in [-0.17, 0.17]:
				spring_items.append([spring_mesh, Transform3D(Basis(),
						Vector3(side * (x_frame + 0.3), wheel_r + 0.42, az + sz))])
			var ax := side * (x_frame + 0.32)
			detail_items.append([Forge.cylinder(0.13, 0.04, 16, 0.0, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(ax, wheel_r + 0.12, az))])
			for by: float in [-0.08, 0.08]:
				for bz: float in [-0.08, 0.08]:
					detail_items.append([Forge.cylinder(0.016, 0.03, 8, 0.0, true, true),
							Transform3D(Basis(Vector3.BACK, PI * 0.5),
									Vector3(ax + side * 0.025, wheel_r + 0.12 + by, az + bz))])
			for bz: float in [-0.22, 0.22]:
				brake_items.append([Forge.box(Vector3(0.08, 0.2, 0.13)),
						Transform3D(Basis(), Vector3(side * 0.52, wheel_r + 0.04, az + bz))])
				detail_items.append_array(Forge.tube_between(
						Vector3(side * 0.52, wheel_r + 0.12, az + bz),
						Vector3(side * (x_frame - 0.12), wheel_r + 0.34, az + bz), 0.018, 6))
		for ez: float in [-0.72, 0.72]:
			equip_items.append([Forge.rounded_box_x(1.28, 0.44, 0.4, 0.07),
					Transform3D(Basis(), Vector3(side * 1.25, wheel_r + 0.38, ez))])
			equip_items.append([Forge.box(Vector3(0.02, 0.22, 0.92)),
					Transform3D(Basis(), Vector3(side * 1.48, wheel_r + 0.38, ez))])
			for lz: float in [-0.38, 0.0, 0.38]:
				detail_items.append([Forge.box(Vector3(0.02, 0.07, 0.2)),
						Transform3D(Basis(), Vector3(side * 1.485, wheel_r + 0.5, ez + lz))])
		for ez: float in [-1.86, 1.86]:
			equip_items.append([Forge.rounded_box_x(0.62, 0.4, 0.5, 0.06),
					Transform3D(Basis(), Vector3(side * 1.27, wheel_r + 0.2, ez))])
			detail_items.append([Forge.cylinder(0.09, 0.05, 12, 0.0, true, true),
					Transform3D(Basis(), Vector3(side * 1.27, wheel_r + 0.47, ez))])
		for ez: float in [-1.62, 1.62]:
			damper_items.append_array(Forge.tube_between(
					Vector3(side * 1.42, wheel_r + 0.55, ez),
					Vector3(side * 1.12, wheel_r + 0.06, ez - 0.42), 0.035, 8))
			detail_items.append([Forge.cylinder(0.075, 0.18, 12, 0.0, true, true),
					Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(side * 1.42, wheel_r + 0.55, ez))])
		frame_items.append([Forge.rounded_box_x(4.6, 0.12, 0.1, 0.03),
				Transform3D(Basis(), Vector3(side * 1.4, wheel_r + 0.28, 0))])
		for dz: float in [-0.78, 0.78]:
			spring_items.append([spring_mesh, Transform3D(Basis(),
					Vector3(side * 1.42, wheel_r + 0.34, dz))])
		equip_items.append([Forge.rounded_box_x(0.48, 0.3, 0.34, 0.05),
				Transform3D(Basis(), Vector3(side * 1.38, wheel_r + 0.22, 1.9))])
		detail_items.append([Forge.box(Vector3(0.03, 0.18, 0.34)),
				Transform3D(Basis(), Vector3(side * 1.45, wheel_r + 0.2, 1.4))])
		for dz: float in [-0.55, 0.55]:
			secondary_items.append([spring_big, Transform3D(Basis(),
					Vector3(side * 1.02, wheel_r + 0.55, dz))])
			detail_items.append([Forge.cylinder(0.23, 0.04, 18, 0.0, true, true),
					Transform3D(Basis(), Vector3(side * 1.02, wheel_r + 0.71, dz))])
		detail_items.append_array(Forge.tube_between(
				Vector3(side * 1.18, wheel_r + 0.3, -1.6),
				Vector3(side * 1.18, wheel_r + 0.3, 1.6), 0.018, 6))

	for az in axle_z:
		frame_items.append([Forge.box(Vector3(2.2, 0.14, 0.18)),
				Transform3D(Basis(), Vector3(0, wheel_r + 0.12, az))])
	frame_items.append([Forge.box(Vector3(2.35, 0.26, 0.66)),
			Transform3D(Basis(), Vector3(0, wheel_r + 0.32, 0))])
	frame_items.append([Forge.box(Vector3(1.55, 0.36, 0.82)),
			Transform3D(Basis(), Vector3(0, wheel_r + 0.46, 0))])
	equip_items.append([Forge.cylinder(0.22, 0.1, 18, 0.0, true, true),
			Transform3D(Basis(), Vector3(0, wheel_r + 0.64, 0))])
	for az in axle_z:
		motor_items.append([Forge.cylinder(0.3, 1.15, 18, 0.0, true, true),
				Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, wheel_r + 0.02, az))])
		for dx: float in [-0.38, 0.0, 0.38]:
			motor_items.append([Forge.cylinder(0.318, 0.035, 18, 0.0, true, true),
					Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(dx, wheel_r + 0.02, az))])
		equip_items.append([Forge.box(Vector3(0.5, 0.46, 0.62)),
				Transform3D(Basis(), Vector3(0.7, wheel_r + 0.02, az + 0.1))])
		motor_items.append([Forge.cylinder(0.18, 0.9, 14, 0.0, true, true),
				Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, wheel_r - 0.04, az - 0.55))])
	brake_items.append([Forge.cylinder(0.14, 0.6, 16, 0.0, true, true),
			Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, wheel_r + 0.28, -0.55))])
	brake_items.append([Forge.box(Vector3(0.34, 0.26, 0.3)),
			Transform3D(Basis(), Vector3(0, wheel_r + 0.28, -0.55))])
	detail_items.append_array(Forge.tube_between(
			Vector3(-0.9, wheel_r + 0.35, -1.9), Vector3(0.9, wheel_r + 0.35, -1.9), 0.035, 8))
	detail_items.append([Forge.box(Vector3(0.34, 0.08, 0.1)),
			Transform3D(Basis(), Vector3(-1.22, wheel_r + 0.4, 1.35))])

	var frame_root := Node3D.new()
	frame_root.name = "BogieFrameRoot"
	bogie.add_child(frame_root)
	var parts := [
		[frame_items, frame_mat, "BogieFrame"],
		[equip_items, equip_mat, "BogieEquipment"],
		[spring_items, spring_mat, "PrimarySprings"],
		[secondary_items, spring_mat, "SecondarySprings"],
		[damper_items, damper_mat, "BogieDampers"],
		[motor_items, motor_mat, "TractionMotors"],
		[brake_items, brake_mat, "BrakeRigging"],
		[detail_items, silver, "BogieDetails"],
	]
	for item: Array in parts:
		var items: Array = item [0]
		if items.is_empty():
			continue
		var mi := MeshInstance3D.new()
		mi.name = String(item [2])
		mi.mesh = Forge.merge_all(items)
		mi.material_override = item [1]
		frame_root.add_child(mi)

	var wheel_mesh := _wheel_mesh(wheel_r)
	var axle_span :=(Config.GAUGE - 0.12) * 0.5
	for az in axle_z:
		var axle_node := Node3D.new()
		axle_node.name = "Wheelset%d" %(v.wheels.size() + 1)
		axle_node.position = Vector3(0, wheel_r, az)
		bogie.add_child(axle_node)
		var axle := MeshInstance3D.new()
		axle.mesh = Forge.cylinder(0.075, 2.1, 12, -1.05, true, true)
		axle.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO)
		axle.material_override = silver
		axle_node.add_child(axle)
		for side: float in [-1.0, 1.0]:
			var w := MeshInstance3D.new()
			w.mesh = wheel_mesh
			w.material_override = wheel_mat
			w.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(side * axle_span, 0, 0))
			axle_node.add_child(w)
		v.add_wheel(axle_node, wheel_r)
	v.bogie_frames.append(frame_root)
	return bogie

static func _cab_mirror(v: Vehicle, side: float, side_x: float, front: float, steel: Material) -> void:
	var mz := -front + 0.35
	var mx := side * (side_x + 0.55)
	var root := Node3D.new()
	root.name = "CabMirrorLeft" if side < 0.0 else "CabMirrorRight"
	root.position = Vector3(mx, 3.02, mz)
	v.attach(root)

	var arm_items := []
	var upper_mount := Vector3(side * (side_x - 0.12), 3.12, mz + 0.15) - root.position
	var upper_end := Vector3(side * -0.02, 0.1, 0.0)
	var lower_mount := Vector3(side * (side_x - 0.1), 2.6, mz + 0.15) - root.position
	var lower_end := Vector3(side * -0.02, -0.15, 0.0)
	arm_items.append_array(Forge.tube_between(upper_mount, upper_end, 0.055, 8))
	arm_items.append_array(Forge.tube_between(lower_mount, lower_end, 0.04, 8))
	arm_items.append([Forge.box(Vector3(0.1, 0.24, 0.22)),
			Transform3D(Basis(), Vector3(side * -0.55, 0.17, 0.15))])
	arm_items.append([Forge.cylinder(0.06, 0.1, 10, 0.0, true, true),
			Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(side * -0.04, 0.1, 0.0))])
	var arms := MeshInstance3D.new()
	arms.name = "CabMirrorArm"
	arms.mesh = Forge.merge_all(arm_items)
	arms.material_override = steel
	root.add_child(arms)

	var housing := MeshInstance3D.new()
	housing.name = "CabMirrorHousing"
	housing.mesh = Forge.box(Vector3(0.17, 0.5, 0.36))
	housing.material_override = Gfx.metal(Color(0.09, 0.1, 0.11), 0.45, 0.6)
	housing.rotation.y = -side * 0.32
	root.add_child(housing)
	var vp := SubViewport.new()
	vp.name = "MirrorViewport"
	vp.size = Vector2i(160, 100)
	vp.own_world_3d = false
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.scaling_3d_scale = 0.7
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	root.add_child(vp)
	var cam := Camera3D.new()
	cam.name = "MirrorCamera"
	cam.fov = 70.0
	cam.near = 0.05
	cam.far = 3000.0
	cam.position = Vector3(side * 0.12, 0.02, 0.06)
	cam.rotation = Vector3(-0.04, PI + side * 0.2, 0.0)
	cam.current = true
	vp.add_child(cam)

	var timer := Timer.new()
	timer.wait_time = 0.1
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(func() -> void:
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE)
	root.add_child(timer)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = vp.get_texture()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.disable_receive_shadows = true
	var glass := MeshInstance3D.new()
	glass.name = "CabMirrorGlass"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.3, 0.28)
	glass.mesh = quad
	glass.material_override = mat
	glass.position = Vector3(-side * 0.105, 0.0, 0.0)
	glass.rotation.y = -side * 0.55
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(glass)


static func _loco_rear_interior(v: Vehicle, floor_y: float, roof_y: float,
		body_mat: Material, dark_mat: Material, frame_mat: Material) -> void:
	var z0 := -3.70
	var z1 := 9.35
	var floor_mat := Gfx.carpet(Color(0.16, 0.17, 0.18))
	floor_mat.metallic_specular = 0.0
	floor_mat.roughness = 1.0
	var wall_mat := Gfx.interior_panel(Color(0.34, 0.36, 0.38), 0.58)
	v.part(Forge.box(Vector3(3.0, 0.06, z1 - z0)), floor_mat,
			Transform3D(Basis(), Vector3(0, floor_y + 0.03, (z0 + z1) * 0.5)), "EngineRoomFloor")
	var runner_mat := Gfx.carpet(Color(0.22, 0.23, 0.24))
	runner_mat.metallic_specular = 0.0
	runner_mat.roughness = 1.0
	v.part(Forge.box(Vector3(1.08, 0.02, z1 - z0 - 0.25)), runner_mat,
			Transform3D(Basis(), Vector3(0.75, floor_y + 0.075, (z0 + z1) * 0.5)), "EngineRoomAisle")
	v.part(Forge.box(Vector3(3.0, 0.05, z1 - z0)), Gfx.interior_panel(Color(0.28, 0.30, 0.32), 0.62),
			Transform3D(Basis(), Vector3(0, floor_y + 2.28, (z0 + z1) * 0.5)), "EngineRoomCeiling")
	for lz: float in [-2.2, 1.2, 4.6, 7.6]:
		v.part(Forge.box(Vector3(0.52, 0.025, 1.20)), Gfx.emissive(Color(1.0, 0.95, 0.86), 1.0, Color(0.62, 0.58, 0.50)),
				Transform3D(Basis(), Vector3(0.38, floor_y + 2.245, lz)), "EngineRoomLight")
	# Left side: engine and traction motor block. Right side stays clear as
	# the walk-through passage from the cab to the rear shunting cab.
	v.part(Forge.box(Vector3(1.58, 1.95, 10.6)), Gfx.metal(Color(0.09, 0.10, 0.11), 0.60, 0.38),
			Transform3D(Basis(), Vector3(-0.62, 2.12, 1.55)), "EngineBlock")
	for z: float in [-2.5, 0.0, 2.5, 5.0]:
		v.part(Forge.cylinder(0.11, 0.72, 10, 0.0, true, true), Gfx.metal(Color(0.16, 0.17, 0.18), 0.5, 0.5),
				Transform3D(Basis(), Vector3(-0.62, 3.18, z)), "EnginePipe")
	# The body shell is single-sided and disappears from inside, so the
	# engine-room and rear-cab walls must be solid interior panels from the
	# floor all the way to the ceiling.
	for side: float in [-1.0, 1.0]:
		v.part(Forge.box(Vector3(0.05, 2.30, z1 - z0)), wall_mat,
				Transform3D(Basis(), Vector3(side * 1.45, floor_y + 1.15, (z0 + z1) * 0.5)), "EngineRoomWall")
	# Rear shunting cab partition, with a doorway on the right.
	v.part(Forge.box(Vector3(1.65, 2.30, 0.08)), wall_mat,
			Transform3D(Basis(), Vector3(-0.575, floor_y + 1.15, 6.85)), "RearCabPartition")
	v.part(Forge.box(Vector3(1.45, 0.41, 0.08)), wall_mat,
			Transform3D(Basis(), Vector3(0.725, floor_y + 2.095, 6.85)), "RearCabPartition")
	for fx: float in [0.30, 1.20]:
		v.part(Forge.box(Vector3(0.06, 2.0, 0.10)), frame_mat,
				Transform3D(Basis(), Vector3(fx, 2.18, 6.85)), "RearCabDoorFrame")
	v.part(Forge.box(Vector3(0.90, 0.06, 0.10)), frame_mat,
			Transform3D(Basis(), Vector3(0.75, 3.18, 6.85)), "RearCabDoorFrame")
	# Flush threshold across the rear-cab doorway. Keep it carpet-coloured
	# so it reads as a continuous floor rather than a dark hole.
	v.part(Forge.box(Vector3(1.10, 0.02, 0.55)), Gfx.carpet(Color(0.24, 0.25, 0.26)),
			Transform3D(Basis(), Vector3(0.75, floor_y + 0.105, 6.85)), "RearCabThreshold")
	# The rear shunting cab is a standing cab: keep the centre of the
	# compartment and the doorway into the train clear. Controls are folded
	# into a narrow desk against the left wall instead of a loose seat in the
	# middle of the tail.
	var desk_mat := Gfx.interior_panel(Color(0.22, 0.24, 0.26), 0.55)
	v.part(Forge.box(Vector3(0.52, 0.10, 0.62)), desk_mat,
			Transform3D(Basis(), Vector3(-1.08, floor_y + 1.03, 8.55)), "RearCabDesk")
	v.part(Forge.box(Vector3(0.46, 0.50, 0.06)), desk_mat,
			Transform3D(Basis(), Vector3(-1.08, floor_y + 0.78, 8.85)), "RearCabDeskFront")
	v.part(Forge.box(Vector3(0.16, 0.26, 0.12)), Gfx.metal(Color(0.18, 0.19, 0.21), 0.5, 0.55),
			Transform3D(Basis(), Vector3(-1.03, floor_y + 1.17, 8.42)), "RearCabBrakeValve")
	v.part(Forge.cylinder(0.035, 0.20, 8, 0.0, true, true), dark_mat,
			Transform3D(Basis(Vector3.RIGHT, deg_to_rad(22.0)), Vector3(-1.03, floor_y + 1.30, 8.42)), "RearCabBrakeHandle")
	v.part(Forge.box(Vector3(0.56, 0.03, 1.10)), Gfx.emissive(Color(1.0, 0.95, 0.86), 0.85, Color(0.62, 0.58, 0.50)),
			Transform3D(Basis(), Vector3(0.20, roof_y - 0.20, 8.0)), "RearCabLight")
	for hz: float in [7.45, 9.10]:
		v.part(Forge.cylinder(0.018, 1.9, 8, 0.0, true, true), frame_mat,
				Transform3D(Basis(), Vector3(0.42, floor_y + 0.98, hz)), "RearCabGrabRail")
	v.part(Forge.box(Vector3(1.04, 0.04, 0.42)), Gfx.metal(Color(0.18, 0.19, 0.21), 0.55, 0.5),
			Transform3D(Basis(), Vector3(0, floor_y + 0.05, 9.45)), "RearCabDoorSill")
	var rear_lamp_zs := [-1.5, 2.5, 6.2, 7.0, 8.0]
	if Config.quality <= Config.Quality.LOW:
		rear_lamp_zs = [2.5, 7.0]
	elif Config.quality == Config.Quality.MEDIUM:
		rear_lamp_zs = [2.5, 6.2, 8.0]
	for lamp_z: float in rear_lamp_zs:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0.35, 3.10, lamp_z)
		lamp.omni_range = 5.4 if lamp_z < 7.0 else 4.2
		lamp.light_energy = 0.9 if lamp_z < 7.0 else 0.85
		lamp.light_color = Color(1.0, 0.93, 0.82)
		lamp.shadow_enabled = false
		v.attach(lamp)
	# Low fill lights: engine-room floor and rear-cab doorway threshold.
	var fill_zs := [5.0, 6.9] if Config.quality > Config.Quality.LOW else [6.9]
	for fill_z: float in fill_zs:
		var fill := OmniLight3D.new()
		fill.position = Vector3(0.75, 1.95, fill_z)
		fill.omni_range = 2.4
		fill.light_energy = 1.1
		fill.light_color = Color(1.0, 0.95, 0.88)
		fill.shadow_enabled = false
		v.attach(fill)
	v.set_meta("train_walk", true)
	v.set_meta("train_walk_floor", floor_y + 0.06)
	v.set_meta("train_walk_front", -9.45)
	v.set_meta("train_walk_back", 9.35)
	v.set_meta("train_walk_half", 1.35)
	v.set_meta("train_walk_corridor_x", 0.36)
	v.set_meta("train_walk_corridor_z0", -3.65)
	v.set_meta("train_walk_corridor_z1", 6.85)


static func _add_loco_parts(v: Vehicle, parts: Array, front: float, roof_y: float, side_x: float,
		body_mat: Material = null) -> void:
	var steel := Gfx.metal(Color(0.22, 0.23, 0.25), 0.4, 0.75)
	var lens := Gfx.emissive(Color(1.0, 0.94, 0.78), 2.4, Color(0.72, 0.68, 0.58))
	var brass := Gfx.metal(Color(0.74, 0.56, 0.22), 0.28, 0.86)
	var beacon_lens := Gfx.emissive(Color(1.0, 0.36, 0.08), 3.0, Color(0.35, 0.07, 0.02))
	var plow_paint := Gfx.paint(Color(0.82, 0.62, 0.12), 0.34, 0.32, 0.45)
	if "roof_spots" in parts:
		v.part(Forge.box(Vector3(2.0, 0.08, 0.22)), steel,
				Transform3D(Basis(), Vector3(0, roof_y + 0.06, -front + 0.74)), "RoofSpotMount")
		for x: float in [-0.82, 0.82]:
			v.part(Forge.box(Vector3(0.55, 0.30, 0.62)), steel,
					Transform3D(Basis(), Vector3(x, roof_y + 0.21, -front + 0.54)), "RoofSpotHousing")
			v.part(Forge.cylinder(0.16, 0.09, 16, 0.0, true, true), lens,
					Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(x, roof_y + 0.23, -front + 0.20)), "RoofSpotLens")
			var sp := SpotLight3D.new()
			sp.position = Vector3(x, roof_y + 0.24, -front + 0.28)
			sp.rotation_degrees = Vector3(-8, 0, 0)
			sp.light_color = Color(1.0, 0.95, 0.82)
			sp.light_energy = 9.0
			sp.spot_range = 220.0
			sp.spot_angle = 30.0
			v.attach(sp)
			v.head_lights.append(sp)
	if "side_lamps" in parts:
		for side: float in [-1.0, 1.0]:
			v.part(Forge.box(Vector3(0.34, 0.22, 0.40)), steel,
					Transform3D(Basis(), Vector3(side * (side_x + 0.04), 2.28, -front + 2.05)), "SideLampHousing")
			v.part(Forge.box(Vector3(0.08, 0.16, 0.24)), lens,
					Transform3D(Basis(), Vector3(side * (side_x + 0.22), 2.28, -front + 2.05)), "SideLampLens")
			var sp := SpotLight3D.new()
			sp.position = Vector3(side * (side_x + 0.26), 2.26, -front + 2.02)
			sp.rotation_degrees = Vector3(-28, side * 35, 0)
			sp.light_color = Color(1.0, 0.94, 0.80)
			sp.light_energy = 5.0
			sp.spot_range = 150.0
			sp.spot_angle = 36.0
			v.attach(sp)
			v.head_lights.append(sp)
	if "roof_beacon" in parts:
		for x: float in [-0.7, 0.7]:
			v.part(Forge.cylinder(0.16, 0.10, 16, 0.0, true, true), steel,
					Transform3D(Basis(), Vector3(x, roof_y + 0.04, -front + 1.15)), "BeaconBase")
			v.part(Forge.cylinder(0.11, 0.28, 16, 0.0, true, true), beacon_lens,
					Transform3D(Basis(), Vector3(x, roof_y + 0.14, -front + 1.15)), "BeaconLens")
			v.part(Forge.cylinder(0.13, 0.05, 16, 0.0, true, true), steel,
					Transform3D(Basis(), Vector3(x, roof_y + 0.43, -front + 1.15)), "BeaconCap")
		var beacon_light := OmniLight3D.new()
		beacon_light.position = Vector3(0, roof_y + 0.34, -front + 1.15)
		beacon_light.light_color = Color(1.0, 0.35, 0.08)
		beacon_light.light_energy = 0.7
		beacon_light.omni_range = 10.0
		beacon_light.shadow_enabled = false
		v.attach(beacon_light)
	if "cab_mirrors" in parts:
		for side: float in [-1.0, 1.0]:
			_cab_mirror(v, side, side_x, front, steel)
	if "side_skirts" in parts:
		var skirt_skin := skin_info(String(v.get_meta("skin_id", "classic")))
		# Share the carbody material when possible so the skirt follows the
		# selected skin exactly, including under different lighting.
		var skirt_mat: Material = body_mat if body_mat != null else Gfx.paint(skirt_skin["body"], 0.26, 0.5, 0.65)
		var skirt_edge := Gfx.metal(Color(0.86, 0.64, 0.16), 0.35, 0.7)
		var y_top := 1.28
		var y_lip := 1.14
		var y_bot := 0.38
		var edge_y := y_bot + 0.035
		var cut_bot_in := 3.55
		var cut_top_in := 4.35
		var cut_top_out := 8.05
		var cut_bot_out := 8.90
		var z_end := 9.58
		# Side elevation of the skirt: a continuous lower valance with
		# earlier/longer trapezoidal bogie cut-outs and a clean recess under
		# the cab door so the step and doorway read properly.
		var door_z0 := -6.10
		var door_z1 := -5.00
		var door_notch_y := 0.62
		var skirt_profile := PackedVector2Array([
			Vector2(-z_end, y_top), Vector2(door_z0, y_top),
			Vector2(door_z0, door_notch_y), Vector2(door_z1, door_notch_y),
			Vector2(door_z1, y_top), Vector2(z_end, y_top), Vector2(z_end, y_bot),
			Vector2(cut_bot_out, y_bot), Vector2(cut_top_out, y_lip),
			Vector2(cut_top_in, y_lip), Vector2(cut_bot_in, y_bot),
			Vector2(-cut_bot_in, y_bot), Vector2(-cut_top_in, y_lip),
			Vector2(-cut_top_out, y_lip), Vector2(-cut_bot_out, y_bot),
			Vector2(-z_end, y_bot),
		])
		for side: float in [-1.0, 1.0]:
			# Extrusion grows from its transform origin outward by 0.045 m.
			# Put the outer face only 2 mm proud of the body side so the
			# skirt reads as part of the body instead of an external box.
			var xf := Transform3D(Basis(Vector3.UP, side * PI * 0.5),
					Vector3(side * (side_x - 0.043), 0, 0))
			v.part(Forge.extrude(skirt_profile, 0.045), skirt_mat, xf, "SideSkirtPanel")
			var edge_x := side * (side_x + 0.002)
			for seg: Array in [
				[-z_end, -cut_bot_out], [-cut_bot_in, cut_bot_in], [cut_bot_out, z_end]
			]:
				var za := float(seg[0])
				var zb := float(seg[1])
				v.part(Forge.box(Vector3(0.008, 0.035, zb - za)), skirt_edge,
						Transform3D(Basis(), Vector3(edge_x, edge_y, (za + zb) * 0.5)), "SideSkirtEdge")
			# Follow the sloped sides of each trapezoidal bogie cut-out.
			for slope: Array in [
				[-cut_bot_out, y_bot, -cut_top_out, y_lip],
				[-cut_top_in, y_lip, -cut_bot_in, y_bot],
				[cut_bot_in, y_bot, cut_top_in, y_lip],
				[cut_top_out, y_lip, cut_bot_out, y_bot],
			]:
				var z0 := float(slope[0])
				var y0 := float(slope[1])
				var z1 := float(slope[2])
				var y1 := float(slope[3])
				var a := Vector3(edge_x, y0, z0)
				var b := Vector3(edge_x, y1, z1)
				var mid := a.lerp(b, 0.5)
				var length := a.distance_to(b)
				var tilt := Basis(Vector3.RIGHT, atan2(z1 - z0, y1 - y0))
				v.part(Forge.box(Vector3(0.008, length + 0.02, 0.04)), skirt_edge,
						Transform3D(tilt, mid), "SideSkirtEdgeSlope")
			for top_seg: Array in [[-z_end, door_z0], [door_z1, z_end]]:
				var ta := float(top_seg[0])
				var tb := float(top_seg[1])
				v.part(Forge.box(Vector3(0.012, 0.04, tb - ta)), steel,
						Transform3D(Basis(), Vector3(side * (side_x + 0.002), y_top, (ta + tb) * 0.5)),
						"SideSkirtTop")
			# Edge returns around the cab-door recess.
			for nz: float in [door_z0, door_z1]:
				v.part(Forge.box(Vector3(0.012, y_top - door_notch_y, 0.05)), skirt_edge,
						Transform3D(Basis(), Vector3(side * (side_x + 0.002),
								(y_top + door_notch_y) * 0.5, nz)), "SideSkirtDoorRecess")
			v.part(Forge.box(Vector3(0.012, 0.05, door_z1 - door_z0 + 0.04)), skirt_edge,
					Transform3D(Basis(), Vector3(side * (side_x + 0.002), door_notch_y,
							(door_z0 + door_z1) * 0.5)), "SideSkirtDoorRecess")
			for ez: float in [-z_end, z_end]:
				v.part(Forge.box(Vector3(0.006, y_top - y_bot, 0.06)), skirt_mat,
						Transform3D(Basis(), Vector3(side * (side_x + 0.002), (y_top + y_bot) * 0.5, ez)), "SideSkirtEndCap")
				# Return faces cover the front and rear end of the valance so
				# the open edge of the extrusion is not visible from the cab
				# end or from behind the locomotive.
				var inward := 1.0 if ez < 0.0 else -1.0
				v.part(Forge.box(Vector3(0.30, y_top - y_bot, 0.012)), skirt_mat,
						Transform3D(Basis(), Vector3(side * 1.40, (y_top + y_bot) * 0.5,
								ez + inward * 0.008)), "SideSkirtEndFace")
				v.part(Forge.box(Vector3(0.30, 0.035, 0.012)), skirt_edge,
						Transform3D(Basis(), Vector3(side * 1.40, edge_y,
								ez + inward * 0.008)), "SideSkirtEndFaceEdge")
			# Close the lower front corner between the side skirt and the nose.
			v.part(Forge.box(Vector3(0.22, y_top - y_bot, 0.10)), skirt_mat,
					Transform3D(Basis(), Vector3(side * 1.45, (y_top + y_bot) * 0.5, -9.60)), "SideSkirtFrontCorner")
			v.part(Forge.box(Vector3(0.30, y_top - y_bot, 0.10)), skirt_mat,
					Transform3D(Basis(), Vector3(side * 1.30, (y_top + y_bot) * 0.5, -9.64)), "SideSkirtFrontInner")
			v.part(Forge.box(Vector3(0.30, 0.035, 0.10)), skirt_edge,
					Transform3D(Basis(), Vector3(side * 1.30, edge_y, -9.64)), "SideSkirtFrontEdge")
			v.part(Forge.box(Vector3(0.22, 0.035, 0.10)), skirt_edge,
					Transform3D(Basis(), Vector3(side * 1.45, edge_y, -9.60)), "SideSkirtFrontEdge")
			# Wrap the side plane forward to the nose/plough face.
			v.part(Forge.box(Vector3(0.008, y_top - y_bot, 0.14)), skirt_mat,
					Transform3D(Basis(), Vector3(side * (side_x + 0.002),
							(y_top + y_bot) * 0.5, -9.64)), "SideSkirtFrontWrap")
			v.part(Forge.box(Vector3(0.008, 0.035, 0.14)), skirt_edge,
					Transform3D(Basis(), Vector3(side * (side_x + 0.002), edge_y, -9.64)), "SideSkirtFrontWrapEdge")
	if "front_plow" in parts:
		var plow_tilt := Basis(Vector3.RIGHT, deg_to_rad(-10.0))
		v.part(Forge.box(Vector3(1.75, 0.55, 0.10)), plow_paint,
				Transform3D(plow_tilt, Vector3(0, 1.2, -front - 0.36)), "PlowBlade")
		for side: float in [-1.0, 1.0]:
			v.part(Forge.box(Vector3(0.55, 0.48, 0.08)), plow_paint,
					Transform3D(Basis(Vector3.UP, side * deg_to_rad(30.0)) * plow_tilt,
							Vector3(side * 1.06, 1.19, -front - 0.12)), "PlowWing")
			v.merged(Forge.tube_between(
					Vector3(side * 0.95, 1.2, -front - 0.05),
					Vector3(side * 0.78, 1.2, -front - 0.30), 0.045, 8),
					steel, "PlowBrace")
		v.part(Forge.box(Vector3(0.12, 0.5, 0.12)), steel,
				Transform3D(Basis(), Vector3(0, 1.2, -front - 0.42)), "PlowCenter")
	if "roof_horns" in parts:
		v.part(Forge.box(Vector3(0.92, 0.06, 0.22)), steel,
				Transform3D(Basis(), Vector3(0, roof_y + 0.05, -front + 2.55)), "HornMount")
		for x: float in [-0.32, 0.32]:
			v.part(Forge.cylinder(0.04, 0.55, 10, 0.0, true, true), brass,
					Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(x, roof_y + 0.23, -front + 2.42)), "HornPipe")
			v.part(Forge.cylinder(0.10, 0.12, 12, 0.0, true, true), brass,
					Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(x, roof_y + 0.23, -front + 2.12)), "HornBell")
