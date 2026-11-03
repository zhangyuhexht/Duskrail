extends Node
class_name TrainAudio


const MIX_RATE := 22050

var train: Train
var motor: AudioStreamPlayer
var rolling: AudioStreamPlayer
var horn: AudioStreamPlayer
var brake: AudioStreamPlayer
var squeal: AudioStreamPlayer
var tunnel: AudioStreamPlayer
var rain: AudioStreamPlayer
var chime: AudioStreamPlayer

var _rain_amount := 0.0
var _wetness := 0.0
var _in_tunnel := false
var _doors_were_open := false


func setup(p_train: Train) -> void:
	train = p_train
	motor = _player("Motor", _make_motor(1.0, 46.0), -60.0, true)
	rolling = _player("Rolling", _make_rolling(1.6), -60.0, true)
	brake = _player("BrakeAir", _make_brake_air(1.2), -60.0, true)
	squeal = _player("FlangeSqueal", _make_squeal(1.4), -60.0, true)
	tunnel = _player("TunnelWash", _make_tunnel(1.8), -60.0, true)
	rain = _player("Rain", _make_rain(1.8), -60.0, true)
	horn = _player("Horn", _make_horn(1.7), -9.0, false)
	chime = _player("DoorChime", _make_chime(), -15.0, false)
	_doors_were_open = train != null and train.doors_open
	if horn != null:
		horn.stop()
	if chime != null:
		chime.stop()
	print("[audio] procedural layers ready: motor/roll/brake/squeal/tunnel/rain/horn/chime")


func _player(pname: String, stream: AudioStreamWAV, db: float, looped: bool) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = pname
	p.stream = stream
	p.volume_db = db
	add_child(p)
	p.play()
	return p


func set_weather(rain_amount: float, wetness: float) -> void:
	_rain_amount = clampf(rain_amount, 0.0, 1.0)
	_wetness = clampf(wetness, 0.0, 1.0)


func set_environment(in_tunnel: bool, severity: float) -> void:
	_in_tunnel = in_tunnel
	if tunnel != null:
		tunnel.set_meta("severity", clampf(severity, 0.0, 1.0))


func blast() -> void:
	if horn != null:
		horn.stop()
		horn.play()


func chime_once() -> void:
	if chime != null:
		chime.stop()
		chime.play()


func _process(delta: float) -> void:
	if train == null or motor == null:
		return
	var kmh := absf(train.speed_kmh())
	var powered: bool = train.notch != 0 or kmh > 0.6
	var motor_db := -60.0
	if powered:
		motor_db = -26.0 + clampf(kmh * 0.28, 0.0, 12.0)
	if _in_tunnel:
		motor_db += 2.0
	motor.volume_db = maxf(-60.0, lerpf(motor.volume_db, motor_db, 0.08))
	motor.pitch_scale = clampf(0.62 + kmh / 58.0, 0.55, 2.4)

	var roll_db := -60.0
	if kmh > 0.8:
		roll_db = -30.0 + clampf(kmh * 0.34, 0.0, 14.0)
	rolling.volume_db = maxf(-60.0, lerpf(rolling.volume_db, roll_db, 0.1))
	rolling.pitch_scale = clampf(0.75 + kmh / 42.0, 0.7, 2.6)

	var brake_db := -60.0
	if train.brake_cylinder > 0.15 or train.brake_notch > 0:
		brake_db = -35.0 + clampf(float(train.brake_notch) * 2.0, 0.0, 8.0)
		if kmh > 1.0:
			brake_db += 2.0
	brake.volume_db = maxf(-60.0, lerpf(brake.volume_db, brake_db, 0.12))
	brake.pitch_scale = lerpf(0.82, 1.12, clampf(train.brake_cylinder / 4.5, 0.0, 1.0))

	var curve := _curve_amount()
	var squeal_db := -60.0
	if kmh > 10.0 and curve > 0.015:
		squeal_db = -50.0 + clampf(curve * 360.0, 0.0, 12.0) + clampf(kmh * 0.08, 0.0, 5.0)
		if _wetness > 0.2:
			squeal_db -= 4.0
	squeal.volume_db = maxf(-60.0, lerpf(squeal.volume_db, squeal_db, 0.07))
	squeal.pitch_scale = clampf(0.86 + curve * 10.0 + kmh / 240.0, 0.75, 1.7)

	var tunnel_db := -60.0
	if _in_tunnel:
		tunnel_db = -29.0 + clampf(kmh * 0.18, 0.0, 5.0)
	tunnel.volume_db = maxf(-60.0, lerpf(tunnel.volume_db, tunnel_db, 0.06))
	tunnel.pitch_scale = clampf(0.82 + kmh / 180.0, 0.8, 1.25)

	var rain_db := -60.0
	if _rain_amount > 0.03:
		rain_db = -34.0 + _rain_amount * 15.0
	rain.volume_db = maxf(-60.0, lerpf(rain.volume_db, rain_db, 0.08))
	rain.pitch_scale = 0.92 + _rain_amount * 0.16

	if train.doors_open != _doors_were_open:
		_doors_were_open = train.doors_open
		chime_once()


func _curve_amount() -> float:
	if train == null or train.route == null:
		return 0.0
	var a := train.route.frame_at(train.distance + 12.0).basis.z
	var b := train.route.frame_at(train.distance - 12.0).basis.z
	return a.angle_to(b)


func _exit_tree() -> void:
	for p in [motor, rolling, brake, squeal, tunnel, rain, horn, chime]:
		if p != null and is_instance_valid(p):
			p.stop()
			p.stream = null


func _make_motor(length: float, f0: float) -> AudioStreamWAV:
	var n := int(MIX_RATE * length)
	var data := PackedByteArray()
	data.resize(n * 2)
	var harm := [1.0, 2.0, 3.0, 4.5, 6.0, 12.0]
	var amp := [0.5, 0.3, 0.16, 0.1, 0.07, 0.02]
	for i in range(n):
		var t := float(i) / float(MIX_RATE)
		var v := 0.0
		for k in range(harm.size()):
			v += amp [k] * sin(TAU * f0 * harm [k] * t)
		var trem := 0.78 + 0.22 * sin(TAU * 6.0 * t)
		data.encode_s16(i * 2, int(clampf(v * trem * 0.55, -1.0, 1.0) * 32000.0))
	return _wav(data, n, true)


func _make_rolling(length: float) -> AudioStreamWAV:
	var n := int(MIX_RATE * length)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261017
	var raw := PackedFloat32Array()
	raw.resize(n)
	var lp := 0.0
	for i in range(n):
		var w := rng.randf_range(-1.0, 1.0)
		lp = lp * 0.86 + w * 0.14
		raw [i] = lp
	var fade := int(MIX_RATE * 0.12)
	for i in range(fade):
		var k := float(i) / float(fade)
		raw [i] = lerpf(raw [i], raw [n - fade + i], k)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		data.encode_s16(i * 2, int(clampf(raw [i] * 6.0, -1.0, 1.0) * 32000.0))
	return _wav(data, n, true)


func _make_brake_air(length: float) -> AudioStreamWAV:
	var n := int(MIX_RATE * length)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7719
	var data := PackedByteArray()
	data.resize(n * 2)
	var lp := 0.0
	for i in range(n):
		var w := rng.randf_range(-1.0, 1.0)
		lp = lp * 0.72 + w * 0.28
		var t := float(i) / float(MIX_RATE)
		var pulse := 0.5 + 0.5 * sin(TAU * 3.4 * t + sin(TAU * 0.7 * t))
		data.encode_s16(i * 2, int(clampf(lp * 0.42 * pulse, -1.0, 1.0) * 32000.0))
	return _wav(data, n, true)


func _make_squeal(length: float) -> AudioStreamWAV:
	var n := int(MIX_RATE * length)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4421
	for i in range(n):
		var t := float(i) / float(MIX_RATE)
		var mod := 0.72 + 0.28 * sin(TAU * 3.1 * t + sin(TAU * 0.43 * t))
		var tone := sin(TAU * 2150.0 * t + sin(TAU * 7.0 * t) * 0.8)
		tone += 0.35 * sin(TAU * 3170.0 * t)
		tone += rng.randf_range(-0.08, 0.08)
		data.encode_s16(i * 2, int(clampf(tone * 0.32 * mod, -1.0, 1.0) * 32000.0))
	return _wav(data, n, true)


func _make_tunnel(length: float) -> AudioStreamWAV:
	var n := int(MIX_RATE * length)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9182
	var data := PackedByteArray()
	data.resize(n * 2)
	var lp := 0.0
	var lp2 := 0.0
	for i in range(n):
		var w := rng.randf_range(-1.0, 1.0)
		lp = lp * 0.96 + w * 0.04
		lp2 = lp2 * 0.72 + w * 0.28
		var t := float(i) / float(MIX_RATE)
		var v := lp * 1.4 + lp2 * 0.18 + 0.08 * sin(TAU * 42.0 * t)
		data.encode_s16(i * 2, int(clampf(v * 0.5, -1.0, 1.0) * 32000.0))
	return _wav(data, n, true)


func _make_rain(length: float) -> AudioStreamWAV:
	var n := int(MIX_RATE * length)
	var rng := RandomNumberGenerator.new()
	rng.seed = 60013
	var data := PackedByteArray()
	data.resize(n * 2)
	var lp := 0.0
	var lp2 := 0.0
	for i in range(n):
		var w := rng.randf_range(-1.0, 1.0)
		lp = lp * 0.8 + w * 0.2
		lp2 = lp2 * 0.93 + w * 0.07
		var t := float(i) / float(MIX_RATE)
		var v := lp * 0.22 + lp2 * 0.5 + 0.04 * sin(TAU * 110.0 * t + sin(TAU * 0.33 * t))
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32000.0))
	return _wav(data, n, true)


func _make_horn(length: float) -> AudioStreamWAV:
	var n := int(MIX_RATE * length)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / float(MIX_RATE)
		var env := minf(t / 0.07, 1.0) * minf((length - t) / 0.25, 1.0)
		env = clampf(env, 0.0, 1.0)
		var v := 0.0
		for f: float in [311.0, 370.0, 466.0]:
			v += 0.34 * sin(TAU * f * t) + 0.1 * sin(TAU * f * 2.0 * t)
		v *= 0.6 + 0.12 * sin(TAU * 5.0 * t)
		data.encode_s16(i * 2, int(clampf(v * env, -1.0, 1.0) * 32000.0))
	return _wav(data, n, false)


func _make_chime() -> AudioStreamWAV:
	var length := 1.35
	var n := int(MIX_RATE * length)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / float(MIX_RATE)
		var v := 0.0
		for f: float in [740.0, 988.0]:
			var start := 0.0 if f < 800.0 else 0.42
			var tt := t - start
			if tt > 0.0:
				var env := minf(tt / 0.025, 1.0) * exp(-tt * 3.2)
				v += 0.45 * env * sin(TAU * f * tt)
				v += 0.12 * env * sin(TAU * f * 2.01 * tt)
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32000.0))
	return _wav(data, n, false)


func _wav(data: PackedByteArray, frames: int, looped: bool) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = MIX_RATE
	s.stereo = false
	s.data = data
	if looped:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = frames
	return s
