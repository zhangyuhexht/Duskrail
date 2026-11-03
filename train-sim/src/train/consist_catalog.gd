extends RefCounted
class_name ConsistCatalog

const GAP := 0.5
const LOCO_LENGTH := 20.0
const MAX_FREIGHT_LENGTH := 700.0
const MAX_PASSENGER_LENGTH := 500.0
const MAX_CARS := 200

const CARS := {
	"passenger": {
		"name": "25T 载客车厢", "short": "载客", "category": "passenger",
		"length": 25.5, "empty": 48.0, "loaded": 56.0, "payload": 8.0,
		"passengers": 118, "max_speed": 200.0,
		"desc": "定员 118 人，适合长大编组旅客列车。",
	},
	"baggage": {
		"name": "25T 行李车厢", "short": "行李", "category": "passenger",
		"length": 25.5, "empty": 44.0, "loaded": 54.0, "payload": 10.0,
		"passengers": 0, "max_speed": 200.0,
		"desc": "大开门行李车，用于旅客列车行包运输。",
	},
	"water_tank": {
		"name": "水罐车厢", "short": "水罐", "category": "freight",
		"length": 12.8, "empty": 24.0, "loaded": 64.0, "payload": 40.0,
		"passengers": 0, "max_speed": 100.0,
		"desc": "40 t 级水罐车，罐体、人孔与端梯齐全。",
	},
	"flat": {
		"name": "平板车厢", "short": "平板", "category": "freight",
		"length": 13.8, "empty": 20.0, "loaded": 60.0, "payload": 40.0,
		"passengers": 0, "max_speed": 100.0,
		"desc": "钢卷与木材两用平车，可混装长大货物。",
	},
	"gondola": {
		"name": "敞车", "short": "敞车", "category": "freight",
		"length": 13.0, "empty": 22.0, "loaded": 72.0, "payload": 50.0,
		"passengers": 0, "max_speed": 100.0,
		"desc": "通用敞车，装运煤炭、矿石与散粒货物。",
	},
	"reefer": {
		"name": "冷藏车厢", "short": "冷藏", "category": "freight",
		"length": 15.0, "empty": 28.0, "loaded": 58.0, "payload": 30.0,
		"passengers": 0, "max_speed": 120.0,
		"desc": "机械冷藏车，端部制冷机组与侧门保温结构。",
	},
	"container": {
		"name": "集装箱平车", "short": "集装箱", "category": "freight",
		"length": 13.8, "empty": 20.0, "loaded": 76.0, "payload": 56.0,
		"passengers": 0, "max_speed": 120.0,
		"desc": "双箱集装箱平车，适合集装箱干线运输。",
	},
	"hopper": {
		"name": "漏斗敞车", "short": "漏斗车", "category": "freight",
		"length": 13.0, "empty": 22.0, "loaded": 82.0, "payload": 60.0,
		"passengers": 0, "max_speed": 100.0,
		"desc": "煤炭漏斗车，底部卸料，适合大宗散货。",
	},
}

const CATEGORY_NAMES := {
	"freight": "货运",
	"passenger": "客运",
	"none": "单机",
}


static func has_car(id: String) -> bool:
	return CARS.has(id)


static func car_ids() -> Array:
	return CARS.keys()


static func info(id: String) -> Dictionary:
	return CARS.get(id, {})


static func category_name(category: String) -> String:
	return String(CATEGORY_NAMES.get(category, "未编组"))


static func max_length_for(category: String) -> float:
	return MAX_PASSENGER_LENGTH if category == "passenger" else MAX_FREIGHT_LENGTH


static func loco_vehicle(engine_id: String, skin_id: String, transmission_id: String, parts: Array) -> Vehicle:
	return Vehicles.freight_loco(engine_id, skin_id, transmission_id, parts)


static func loco_mass(engine_id: String) -> float:
	return float(Vehicles.engine_info(engine_id).get("mass", 138.0))


static func loco_traction_kn(engine_id: String, transmission_id: String) -> float:
	var engine := Vehicles.engine_info(engine_id)
	var trans := Vehicles.transmission_info(transmission_id)
	return float(engine.get("traction", 420000.0)) * float(trans.get("traction", 1.0)) / 1000.0


static func loco_max_speed(engine_id: String, transmission_id: String) -> float:
	var engine := Vehicles.engine_info(engine_id)
	var trans := Vehicles.transmission_info(transmission_id)
	return float(engine.get("speed", 120.0)) * float(trans.get("speed", 1.0))


static func vehicle_for(id: String, loaded: bool) -> Vehicle:
	match id:
		"passenger":
			var coach := Vehicles.passenger_coach()
			coach.set_loaded(loaded)
			return coach
		"baggage":
			return Vehicles.baggage_car(loaded)
		"water_tank":
			return Vehicles.water_tank_wagon(loaded)
		"flat":
			return Vehicles.flat_wagon(loaded)
		"gondola":
			return Vehicles.gondola_wagon(loaded)
		"reefer":
			return Vehicles.reefer_wagon(loaded)
		"hopper":
			return Vehicles.hopper_wagon(loaded)
		_:
			return Vehicles.container_wagon(loaded)


static func build_consist(cars: Array, locos: int, loaded: bool, engine_id: String, skin_id: String,
		transmission_id: String, parts: Array) -> Array:
	var out: Array = []
	var count := clampi(locos, 1, 2)
	for i in range(count):
		var loco := loco_vehicle(engine_id, skin_id, transmission_id, parts)
		loco.name = "FreightLoco%d" %(i + 1)
		loco.set_meta("trailing_loco", i > 0)
		out.append(loco)
	var car_index := 1
	for raw in cars:
		var id := String(raw)
		if CARS.has(id):
			var car := vehicle_for(id, loaded)
			car.name = "%s%02d" %[car.name, car_index]
			car_index += 1
			out.append(car)
	return out


static func category_for(cars: Array) -> String:
	for raw in cars:
		var id := String(raw)
		if CARS.has(id):
			return String(CARS[id]["category"])
	return "none"


static func compute(cars: Array, locos: int, loaded: bool, engine_id: String, transmission_id: String) -> Dictionary:
	var count := clampi(locos, 1, 2)
	var category := category_for(cars)
	var car_length := 0.0
	var car_mass_now := 0.0
	var car_mass_full := 0.0
	var car_mass_empty := 0.0
	var payload := 0.0
	var passengers := 0
	var speed_limit := loco_max_speed(engine_id, transmission_id)
	var car_count := 0
	for raw in cars:
		var id := String(raw)
		if not CARS.has(id):
			continue
		var item: Dictionary = CARS[id]
		car_length += float(item["length"])
		car_mass_now += float(item["loaded"] if loaded else item["empty"])
		car_mass_full += float(item["loaded"])
		car_mass_empty += float(item["empty"])
		payload += float(item["payload"])
		passengers += int(item.get("passengers", 0))
		speed_limit = minf(speed_limit, float(item["max_speed"]))
		car_count += 1
	var loco_mass_total := loco_mass(engine_id) * float(count)
	var vehicles_count := count + car_count
	var total_length := float(count) * LOCO_LENGTH + car_length + maxf(0.0, float(vehicles_count - 1)) * GAP
	var limit := max_length_for(category)
	return {
		"category": category,
		"loco_count": count,
		"car_count": car_count,
		"length": total_length,
		"limit": limit,
		"mass_now": loco_mass_total + car_mass_now,
		"mass_full": loco_mass_total + car_mass_full,
		"mass_empty": loco_mass_total + car_mass_empty,
		"payload": payload if loaded else 0.0,
		"payload_full": payload,
		"passengers": passengers if loaded else 0,
		"passengers_full": passengers,
		"max_speed": speed_limit,
		"traction_kn": loco_traction_kn(engine_id, transmission_id) * float(count),
		"loco_mass": loco_mass(engine_id),
		"over": total_length > limit + 0.01,
	}


static func validate(cars: Array, locos: int, loaded: bool, engine_id: String, transmission_id: String) -> Dictionary:
	if locos < 1 or locos > 2:
		return {"ok": false, "message": "机车数量只能是 1 或 2 台"}
	if cars.size() > MAX_CARS:
		return {"ok": false, "message": "编组车辆过多"}
	var category := ""
	for raw in cars:
		var id := String(raw)
		if not CARS.has(id):
			return {"ok": false, "message": "存在未知车厢：%s" %id}
		var c := String(CARS[id]["category"])
		if category == "":
			category = c
		elif c != category:
			return {"ok": false, "message": "货运车厢和客运车厢不能混编"}
	var summary := compute(cars, locos, loaded, engine_id, transmission_id)
	if bool(summary["over"]):
		return {"ok": false, "message": "超出最大编组长度 %.0f m" %float(summary["limit"]), "summary": summary}
	return {"ok": true, "message": "编组可用", "summary": summary}


static func sanitize(cars: Array, locos: int) -> Dictionary:
	var count := clampi(locos, 1, 2)
	var out: Array[String] = []
	var category := ""
	var limit := MAX_FREIGHT_LENGTH
	for raw in cars:
		var id := String(raw)
		if not CARS.has(id):
			continue
		var c := String(CARS[id]["category"])
		if category == "":
			category = c
			limit = max_length_for(category)
		elif c != category:
			continue
		var candidate := out.duplicate()
		candidate.append(id)
		var summary := compute(candidate, count, true, "standard", "balanced")
		if float(summary["length"]) > limit + 0.01:
			continue
		out.append(id)
		if out.size() >= MAX_CARS:
			break
	return {"cars": out, "locos": count}
