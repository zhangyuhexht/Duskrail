class_name TrainDef
extends Resource







@export var id := "cr400af"
@export var name_cn := "复兴号 CR400AF"
@export var kind := "emu"


@export var pub_cars := 8
@export var pub_car_length_m := 25.5
@export var pub_car_width_m := 3.36
@export var pub_car_height_m := 4.06
@export var pub_vmax_kmh := 350.0
@export var pub_service_speed_kmh := 300.0
@export var pub_bogie_spacing_m := 17.5
@export var pub_wheel_radius_m := 0.43
@export var pub_mass_empty_t := 47.0
@export var pub_mass_loaded_t := 57.0
@export var pub_pantograph_cars := 2


@export var sim_traction_kn_per_motor_car := 240.0
@export var sim_brake_rate := 0.95
@export var sim_panto_seconds := 3.0
@export var sim_vcb_seconds := 1.6
@export var sim_atp_seconds := 2.4
@export var sim_brake_test_seconds := 3.2
@export var sim_note := "牵引/制动/阻力/时序为模拟值，可在 F3 调试面板调整"

static func cr400af() -> TrainDef:
	return TrainDef.new()


static func freight() -> TrainDef:
	var d := TrainDef.new()
	d.id = "hxd_freight"
	d.name_cn = "和谐型电力机车货列"
	d.kind = "freight"
	d.pub_cars = 9
	d.pub_car_length_m = 20.0
	d.pub_vmax_kmh = 120.0
	d.pub_service_speed_kmh = 80.0
	d.pub_mass_empty_t = 23.0
	d.pub_mass_loaded_t = 80.0
	d.pub_pantograph_cars = 1
	d.sim_traction_kn_per_motor_car = 420.0
	return d


static func intercity() -> TrainDef:
	var d := TrainDef.new()
	d.id = "crh6_intercity"
	d.name_cn = "城际动车组"
	d.kind = "intercity"
	d.pub_cars = 4
	d.pub_car_length_m = 25.5
	d.pub_vmax_kmh = 200.0
	d.pub_service_speed_kmh = 200.0
	d.pub_mass_empty_t = 45.0
	d.pub_mass_loaded_t = 58.0
	d.pub_pantograph_cars = 2
	d.sim_traction_kn_per_motor_car = 220.0
	d.sim_brake_rate = 1.0
	return d


static func diesel() -> TrainDef:
	var d := TrainDef.new()
	d.id = "df4_diesel"
	d.name_cn = "东风4型内燃机车"
	d.kind = "diesel"
	d.pub_cars = 9
	d.pub_car_length_m = 20.0
	d.pub_vmax_kmh = 100.0
	d.pub_service_speed_kmh = 70.0
	d.pub_mass_empty_t = 122.0
	d.pub_mass_loaded_t = 122.0
	d.pub_pantograph_cars = 0
	d.sim_traction_kn_per_motor_car = 350.0
	d.sim_brake_rate = 0.9
	return d


static func steam() -> TrainDef:
	var d := TrainDef.new()
	d.id = "qj_steam"
	d.name_cn = "前进型蒸汽机车"
	d.kind = "steam"
	d.pub_cars = 8
	d.pub_car_length_m = 20.0
	d.pub_vmax_kmh = 80.0
	d.pub_service_speed_kmh = 55.0
	d.pub_mass_empty_t = 168.0
	d.pub_mass_loaded_t = 168.0
	d.pub_pantograph_cars = 0
	d.sim_traction_kn_per_motor_car = 300.0
	d.sim_brake_rate = 0.85
	return d


static func custom(category := "freight") -> TrainDef:
	var d := TrainDef.new()
	d.id = "custom"
	d.name_cn = "自定义旅客列车" if category == "passenger" else ("自定义单机" if category == "none" else "自定义货物列车")
	d.kind = "custom"
	d.pub_cars = 0
	d.pub_car_length_m = 20.0
	d.pub_vmax_kmh = 120.0
	d.pub_service_speed_kmh = 80.0
	d.pub_mass_empty_t = 0.0
	d.pub_mass_loaded_t = 0.0
	d.pub_pantograph_cars = 1
	d.sim_traction_kn_per_motor_car = 420.0
	d.sim_brake_rate = 0.95
	return d


static func for_kind(kind: String) -> TrainDef:
	match kind:
		"intercity":
			return intercity()
		"diesel":
			return diesel()
		"steam":
			return steam()
		"emu":
			return cr400af()
		"custom":
			return custom()
		_:
			return freight()

func total_length_m() -> float:
	return float(pub_cars) * pub_car_length_m

func summary() -> String:
	return "%s ｜ %d 辆编组 ｜ 最高 %.0f km/h ｜ 牵引 %.0f kN（模拟）" %[
		name_cn, pub_cars, pub_vmax_kmh, sim_traction_kn_per_motor_car
	]