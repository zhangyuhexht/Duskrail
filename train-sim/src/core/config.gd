extends RefCounted
class_name Config


const GAUGE := 1.435
const RAIL_HALF := GAUGE * 0.5
const SLEEPER_SPACING := 0.62
const RAIL_HEIGHT := 0.176
const BALLAST_DEPTH := 0.55
const CONTACT_WIRE_H := 5.3


const GRAVITY := 9.80665
const AIR_DENSITY := 1.225


const LOCO_MASS := 138.0
const COACH_MASS := 52.0
const WAGON_MASS := 22.0
const WAGON_LOADED_MASS := 80.0


enum Quality {LOW, MEDIUM, HIGH, ULTRA}
static var quality: int = Quality.HIGH


static func route_loop() -> Array:
	var pts: Array = []
	var n := 64
	# Keep the scenic shape, but trim the loop slightly. 1.72 brings the
	# total length to roughly 89 km so station intervals are a little
	# shorter without crowding the existing landmarks.
	var plan_scale := 1.72
	for i in range(n):
		var a := TAU * float(i) / float(n)
		var r := 7800.0 + 900.0 * sin(a * 3.0 + 0.35) + 520.0 * sin(a * 5.0 + 2.1)
		r += 260.0 * cos(a * 7.0 + 0.9) + 120.0 * sin(a * 11.0 + 1.7)
		var x := cos(a) * r * 1.03 * plan_scale
		var z := sin(a) * r * 0.94 * plan_scale
		var y := 48.0 + 24.0 * sin(a * 2.0 + 0.4) + 14.0 * sin(a * 5.0 + 2.2) + 6.0 * cos(a * 9.0 + 0.7)
		pts.append(Vector3(x, y, z))
	return pts


static func test_track() -> Array:
	var pts: Array = []
	var x0 := 900.0
	var r := 95.0
	var n := 241
	# Long snake S: six full waves over 1800 m, amplitude 25 m. The
	# envelope keeps the entry/exit tangent straight for the hairpins.
	for i in range(n):
		var t := float(i) / float(n - 1)
		var x := - x0 + 2.0 * x0 * t
		var z := r + 20.0 * pow(sin(PI * t), 2.0) * sin(TAU * 6.0 * t)
		pts.append(Vector3(x, 0.0, z))
	# Right-hand 85 m radius 180-degree hairpin, bottom to top.
	for i in range(1, 97):
		var a := PI * 0.5 - PI * float(i) / 96.0
		pts.append(Vector3(x0 + cos(a) * r, 0.0, sin(a) * r))
	# Top return S: four full waves, amplitude 18 m, opposite sweep.
	for i in range(1, n):
		var t := float(i) / float(n - 1)
		var x := x0 - 2.0 * x0 * t
		var z := -r + 12.0 * pow(sin(PI * t), 2.0) * sin(TAU * 4.0 * t)
		pts.append(Vector3(x, 0.0, z))
	# Left-hand 85 m radius 180-degree hairpin, top back to bottom.
	for i in range(1, 96):
		var a := 1.5 * PI - PI * float(i) / 96.0
		pts.append(Vector3(- x0 + cos(a) * r, 0.0, sin(a) * r))
	# Rolling profile as a continuous function of plan position, so the
	# loop closes without a vertical seam. Max grade is around 9%.
	for i in range(pts.size()):
		var p: Vector3 = pts[i]
		p.y = 20.0 + 18.0 * sin(p.x / 360.0 + 0.6) \
				+ 12.0 * sin(p.z / 280.0 + 1.4) \
				+ 8.0 * sin(p.x / 200.0 + p.z / 260.0 + 0.2)
		pts[i] = p
	return pts


const STATIONS := [
	{
		"id": "shanchuan", "name": "山川站", "name_en": "Shanchuan",
		"frac": 0.0000, "platform_len": 320.0, "freight": false,
		"settlement": "city", "settlement_side": -1.0, "population": 168000,
	},
	{
		"id": "linjiang", "name": "临江站", "name_en": "Linjiang",
		"frac": 0.0556, "platform_len": 280.0, "freight": true,
		"settlement": "town", "settlement_side": 1.0, "population": 23000,
	},
	{
		"id": "hegu", "name": "河谷站", "name_en": "Hegu",
		"frac": 0.1111, "platform_len": 240.0, "freight": true,
		"settlement": "town", "settlement_side": -1.0, "population": 18000,
	},
	{
		"id": "yunling", "name": "云岭站", "name_en": "Yunling",
		"frac": 0.1667, "platform_len": 220.0, "freight": false,
		"settlement": "town", "settlement_side": 1.0, "population": 12000,
	},
	{
		"id": "qingchuan", "name": "青川站", "name_en": "Qingchuan",
		"frac": 0.2222, "platform_len": 320.0, "freight": true,
		"settlement": "city", "settlement_side": -1.0, "population": 142000,
	},
	{
		"id": "zhuhai", "name": "竹海站", "name_en": "Zhuhai",
		"frac": 0.2778, "platform_len": 220.0, "freight": false,
		"settlement": "halt", "settlement_side": 1.0, "population": 5600,
	},
	{
		"id": "songlin", "name": "松林站", "name_en": "Songlin",
		"frac": 0.3333, "platform_len": 220.0, "freight": true,
		"settlement": "town", "settlement_side": -1.0, "population": 9000,
	},
	{
		"id": "hupan", "name": "湖畔站", "name_en": "Hupan",
		"frac": 0.3889, "platform_len": 220.0, "freight": false,
		"settlement": "town", "settlement_side": 1.0, "population": 14000,
	},
	{
		"id": "jiangwan", "name": "江湾站", "name_en": "Jiangwan",
		"frac": 0.4444, "platform_len": 240.0, "freight": true,
		"settlement": "town", "settlement_side": -1.0, "population": 16000,
	},
	{
		"id": "bailu", "name": "白鹿站", "name_en": "Bailu",
		"frac": 0.5000, "platform_len": 220.0, "freight": false,
		"settlement": "halt", "settlement_side": 1.0, "population": 4200,
	},
	{
		"id": "yangui", "name": "雁归站", "name_en": "Yangui",
		"frac": 0.5556, "platform_len": 240.0, "freight": false,
		"settlement": "town", "settlement_side": -1.0, "population": 11000,
	},
	{
		"id": "shimen", "name": "石门站", "name_en": "Shimen",
		"frac": 0.6111, "platform_len": 260.0, "freight": true,
		"settlement": "halt", "settlement_side": 1.0, "population": 6200,
	},
	{
		"id": "xinghu", "name": "星湖站", "name_en": "Xinghu",
		"frac": 0.6667, "platform_len": 220.0, "freight": false,
		"settlement": "halt", "settlement_side": -1.0, "population": 5100,
	},
	{
		"id": "nanling", "name": "南岭站", "name_en": "Nanling",
		"frac": 0.7222, "platform_len": 220.0, "freight": true,
		"settlement": "halt", "settlement_side": 1.0, "population": 3800,
	},
	{
		"id": "fengqiao", "name": "枫桥站", "name_en": "Fengqiao",
		"frac": 0.7778, "platform_len": 220.0, "freight": false,
		"settlement": "halt", "settlement_side": -1.0, "population": 4800,
	},
	{
		"id": "yunxi", "name": "云溪站", "name_en": "Yunxi",
		"frac": 0.8333, "platform_len": 220.0, "freight": false,
		"settlement": "halt", "settlement_side": 1.0, "population": 4600,
	},
	{
		"id": "wangjiang", "name": "望江站", "name_en": "Wangjiang",
		"frac": 0.8889, "platform_len": 240.0, "freight": true,
		"settlement": "halt", "settlement_side": -1.0, "population": 5400,
	},
	{
		"id": "qingshi", "name": "青石站", "name_en": "Qingshi",
		"frac": 0.9444, "platform_len": 240.0, "freight": true,
		"settlement": "halt", "settlement_side": 1.0, "population": 5900,
	},
]


const SIDING := {
	"station": 1,
	"offset": -4.6,
	"stop": 0.0,
	"begin": -330.0,
	"end": 250.0,
	"blend": 46.0,
}


# Additional passing loops and the Qingchuan yard. The three yard tracks
# sit on the side opposite the passenger platform so they can be entered
# without crossing the platform edge.
const SIDINGS := [
	{"id": "linjiang", "station": 1, "offset": -4.6,
		"begin": -330.0, "end": 250.0, "blend": 46.0, "name": "临江侧线", "sign": "L"},
	{"id": "qingchuan_1", "station": 4, "offset": 4.8,
		"begin": -300.0, "end": 340.0, "blend": 52.0, "name": "青川车场 1 道", "sign": "1"},
	{"id": "qingchuan_2", "station": 4, "offset": 8.9,
		"begin": -300.0, "end": 340.0, "blend": 52.0, "name": "青川车场 2 道", "sign": "2"},
	{"id": "qingchuan_3", "station": 4, "offset": 13.0,
		"begin": -300.0, "end": 340.0, "blend": 52.0, "name": "青川车场 3 道", "sign": "3"},
	{"id": "yangui", "station": 10, "offset": 4.6,
		"begin": -280.0, "end": 260.0, "blend": 46.0, "name": "雁归侧线", "sign": "Y"},
]


const TUNNELS := [
	{"frac": 0.132, "length": 760.0, "height": 34.0, "name": "云岭隧道"},
	{"frac": 0.421, "length": 1180.0, "height": 46.0, "name": "湖畔隧道"},
	{"frac": 0.742, "length": 880.0, "height": 38.0, "name": "南岭隧道"},
]


const BRIDGES := [
	{"frac": 0.250, "length": 430.0, "name": "青川大桥"},
	{"frac": 0.5275, "length": 620.0, "name": "白鹿特大桥"},
	{"frac": 0.860, "length": 390.0, "name": "云溪大桥"},
]


const VIADUCTS := [
	{"frac": 0.152, "length": 920.0, "height": 22.0, "name": "河谷高架桥"},
	{"frac": 0.361, "length": 1080.0, "height": 26.0, "name": "松林高架桥"},
	{"frac": 0.638, "length": 1000.0, "height": 30.0, "name": "石门高架桥"},
	{"frac": 0.916, "length": 600.0, "height": 18.0, "name": "望江高架桥"},
]


static func station_dist(route: Route, index: int) -> float:
	if route == null or index < 0 or index >= STATIONS.size():
		return 0.0
	return route.wrap_dist(route.total * float(STATIONS[index]["frac"]))


static func tunnel_span(route: Route, t: Dictionary) -> Vector2:
	var center := route.total * float(t["frac"])
	return Vector2(route.wrap_dist(center - float(t["length"]) * 0.5), route.wrap_dist(center + float(t["length"]) * 0.5))


static func bridge_span(route: Route, b: Dictionary) -> Vector2:
	var center := route.total * float(b["frac"])
	return Vector2(route.wrap_dist(center - float(b["length"]) * 0.5), route.wrap_dist(center + float(b["length"]) * 0.5))


static func viaduct_span(route: Route, v: Dictionary) -> Vector2:
	var center := route.total * float(v["frac"])
	return Vector2(route.wrap_dist(center - float(v["length"]) * 0.5), route.wrap_dist(center + float(v["length"]) * 0.5))


static func siding_lateral(route: Route, d: float, sid: Dictionary) -> float:
	if route == null or sid.is_empty():
		return 0.0
	var d_in: float = float(sid.get("in", 0.0))
	var d_out: float = float(sid.get("out", 0.0))
	var blend: float = maxf(2.0, float(sid.get("blend", 46.0)))
	var off: float = float(sid.get("offset", -4.6))
	var rel := route.wrap_dist(d - d_in)
	var span := route.wrap_dist(d_out - d_in)
	if span <= 1.0 or rel > span:
		return 0.0
	var t := minf(clampf(rel / blend, 0.0, 1.0), clampf((span - rel) / blend, 0.0, 1.0))
	return off * (t * t * (3.0 - 2.0 * t))
