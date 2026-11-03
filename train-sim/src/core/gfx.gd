extends RefCounted
class_name Gfx


static var _micro_normal: NoiseTexture2D
static var _micro_rough: NoiseTexture2D
static var _brushed_normal: NoiseTexture2D
static var _fabric_normal: NoiseTexture2D
static var _wood_albedo: NoiseTexture2D


static func _noise_tex(freq: float, seed_value: int, normal := false, bump := 0.35) -> NoiseTexture2D:
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.generate_mipmaps = true
	tex.normalize = true
	var n := FastNoiseLite.new()
	n.seed = seed_value
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = freq
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = 4
	n.fractal_lacunarity = 2.1
	n.fractal_gain = 0.48
	tex.noise = n
	if normal:
		tex.as_normal_map = true
		tex.bump_strength = bump
	return tex


static func _ensure_textures() -> void:
	if _micro_normal == null:
		_micro_normal = _noise_tex(0.035, 8101, true, 0.45)
	if _micro_rough == null:
		_micro_rough = _noise_tex(0.026, 8102, false, 0.0)
	if _brushed_normal == null:
		_brushed_normal = _noise_tex(0.075, 8103, true, 0.28)
	if _fabric_normal == null:
		_fabric_normal = _noise_tex(0.18, 8104, true, 0.7)
	if _wood_albedo == null:
		_wood_albedo = _noise_tex(0.012, 8105, false, 0.0)
		var ramp := Gradient.new()
		ramp.set_color(0, Color(0.12, 0.075, 0.045))
		ramp.set_color(1, Color(0.32, 0.2, 0.11))
		_wood_albedo.color_ramp = ramp


static func _add_detail(m: StandardMaterial3D, rough_scale := 1.0, normal_scale := 0.18, uv := 6.0) -> void:
	_ensure_textures()
	m.normal_enabled = true
	m.normal_texture = _micro_normal
	m.normal_scale = normal_scale
	m.roughness_texture = _micro_rough
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE
	m.roughness = clampf(m.roughness * rough_scale, 0.02, 1.0)
	m.uv1_scale = Vector3(uv, uv, uv)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = false


static func _base(albedo: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = roughness
	m.metallic = metallic
	m.metallic_specular = 0.5
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


static func paint(albedo: Color, roughness := 0.28, metallic := 0.55, clearcoat := 0.6, detailed := true) -> StandardMaterial3D:
	var m := _base(albedo, roughness, metallic)
	m.clearcoat_enabled = true
	m.clearcoat = clearcoat
	m.clearcoat_roughness = 0.1
	if detailed:
		_add_detail(m, 1.0, 0.12, 5.0)
	return m


static func train_paint(albedo: Color, metallic := 0.62, roughness := 0.2) -> StandardMaterial3D:
	var m := _base(albedo, roughness, metallic)
	m.clearcoat_enabled = true
	m.clearcoat = 1.0
	m.clearcoat_roughness = 0.045
	m.anisotropy_enabled = true
	m.anisotropy = 0.35
	_add_detail(m, 0.9, 0.09, 4.0)
	return m


static func metal(albedo: Color, roughness := 0.45, metallic := 0.9, detailed := true) -> StandardMaterial3D:
	var m := _base(albedo, roughness, metallic)
	if detailed:
		_ensure_textures()
		m.normal_enabled = true
		m.normal_texture = _brushed_normal
		m.normal_scale = 0.22
		m.roughness_texture = _micro_rough
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE
		m.uv1_scale = Vector3(14.0, 2.0, 14.0)
		m.uv1_triplanar = true
	return m


static func chrome(albedo := Color(0.78, 0.8, 0.83)) -> StandardMaterial3D:
	var m := _base(albedo, 0.035, 1.0)
	m.metallic_specular = 0.9
	return m


static func glass(tint := Color(0.05, 0.08, 0.11), roughness := 0.04, alpha := 0.6) -> StandardMaterial3D:
	var m := _base(Color(tint.r, tint.g, tint.b, alpha), roughness, 0.2)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic_specular = 1.0
	m.rim_enabled = true
	m.rim = 0.35
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.refraction_enabled = false
	return m


static func cutout_paint(albedo: Color, cuts: Array, z_shift: float,
		metallic := 0.62, roughness := 0.2) -> ShaderMaterial:
	# A painted steel shell that discards fragments inside real window openings.
	# The cab interior behind it is therefore visible from outside instead of
	# reading as a black decal. cuts = [Vector4(y0, y1, z0, z1), ...].
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(0.86, 0.89, 0.92, 1.0);
uniform float metallic = 0.62;
uniform float roughness = 0.2;
uniform float z_shift = 0.0;
uniform vec4 cut0 = vec4(9999.0);
uniform vec4 cut1 = vec4(9999.0);
uniform vec4 cut2 = vec4(9999.0);
uniform vec4 cut3 = vec4(9999.0);

varying vec3 body_local;

void vertex() {
	body_local = VERTEX;
}

void fragment() {
	float z = body_local.z + z_shift;
	if (abs(body_local.x) > 1.38) {
		if ((body_local.y > cut0.x && body_local.y < cut0.y && z > cut0.z && z < cut0.w) ||
				(body_local.y > cut1.x && body_local.y < cut1.y && z > cut1.z && z < cut1.w) ||
				(body_local.y > cut2.x && body_local.y < cut2.y && z > cut2.z && z < cut2.w) ||
				(body_local.y > cut3.x && body_local.y < cut3.y && z > cut3.z && z < cut3.w)) {
			discard;
		}
	}
	ALBEDO = albedo.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = 0.5;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("albedo", albedo)
	m.set_shader_parameter("metallic", metallic)
	m.set_shader_parameter("roughness", roughness)
	m.set_shader_parameter("z_shift", z_shift)
	for i in range(4):
		m.set_shader_parameter("cut%d" %i,
				cuts[i] if i < cuts.size() else Vector4(9999.0, 9999.0, 9999.0, 9999.0))
	return m


static func interior_panel(albedo: Color, roughness := 0.52) -> StandardMaterial3D:
	var m := _base(albedo, roughness, 0.06)
	_add_detail(m, 1.0, 0.08, 3.0)
	return m


static func leather(albedo: Color, roughness := 0.46) -> StandardMaterial3D:
	var m := _base(albedo, roughness, 0.03)
	_ensure_textures()
	m.normal_enabled = true
	m.normal_texture = _fabric_normal
	m.normal_scale = 0.35
	m.uv1_scale = Vector3(5, 5, 5)
	return m


static func carpet(albedo: Color) -> StandardMaterial3D:
	var m := _base(albedo, 0.94, 0.0)
	_ensure_textures()
	m.normal_enabled = true
	m.normal_texture = _fabric_normal
	m.normal_scale = 0.55
	m.uv1_scale = Vector3(9, 9, 9)
	return m


static func wood(albedo := Color(0.25, 0.15, 0.08)) -> StandardMaterial3D:
	var m := _base(albedo, 0.36, 0.05)
	_ensure_textures()
	m.albedo_texture = _wood_albedo
	m.uv1_scale = Vector3(2, 2, 2)
	return m


static func emissive(color: Color, energy := 4.0, albedo := Color(0.9, 0.9, 0.9)) -> StandardMaterial3D:
	var m := _base(albedo, 0.3, 0.0)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


static func dbg_color(albedo: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func rubber(albedo := Color(0.06, 0.06, 0.07), roughness := 0.85) -> StandardMaterial3D:
	return _base(albedo, roughness, 0.0)


static func sheet(albedo: Color, roughness := 0.6, metallic := 0.2) -> StandardMaterial3D:
	var m := _base(albedo, roughness, metallic)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func noise_surface(albedo: Color, roughness := 0.95, noise_scale := 0.35, grain := 0.35) -> StandardMaterial3D:
	var m := _base(albedo, roughness, 0.0)
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.02
	noise.fractal_octaves = 4
	tex.noise = noise
	tex.color_ramp = _grain_ramp(grain, noise_scale)
	m.albedo_texture = tex
	m.uv1_scale = Vector3(6, 6, 6)
	m.roughness_texture = tex
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE
	return m


static func _grain_ramp(grain: float, bias: float) -> Gradient:
	var g := Gradient.new()
	var lo := clampf(0.82 - grain * 0.3 + bias * 0.1, 0.0, 1.0)
	var hi := clampf(1.06 - grain * 0.12 + bias * 0.06, 0.0, 1.4)
	g.set_color(0, Color(lo, lo, lo))
	g.set_color(1, Color(hi, hi, hi))
	return g


static func terrain() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 grass_color : source_color = vec3(0.20, 0.29, 0.13);
uniform vec3 rock_color : source_color = vec3(0.30, 0.29, 0.25);
uniform vec3 dirt_color : source_color = vec3(0.28, 0.23, 0.16);
uniform float roughness_v : hint_range(0.0, 1.0) = 0.95;
uniform float noise_scale = 0.02;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453);
}

float gnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = dot(hash2(i), f);
	float b = dot(hash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
	float c = dot(hash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
	float d = dot(hash2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 5; i++) {
		v += amp * gnoise(p);
		p = p * 2.03 + vec2(17.3, 9.1);
		amp *= 0.5;
	}
	return v;
}

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 wp = world_pos.xz;
	float n = fbm(wp * noise_scale);
	float macro = gnoise(wp * noise_scale * 0.13 + vec2(11.0, 7.0));
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float slope = 1.0 - clamp(wn.y, 0.0, 1.0);
	vec3 col = mix(grass_color, dirt_color, smoothstep(0.45, 0.95, n * 0.65 + macro * 0.35) * 0.55);
	col = mix(col, rock_color, smoothstep(0.30, 0.72, slope));
	col *= 0.94 + 0.14 * macro;
	ALBEDO = col;
	ROUGHNESS = clamp(roughness_v - slope * 0.10, 0.65, 1.0);
	METALLIC = 0.0;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m

static func water() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 shallow_color : source_color = vec3(0.055, 0.14, 0.17);
uniform vec3 deep_color : source_color = vec3(0.012, 0.036, 0.068);
uniform float flow_speed = 0.05;
uniform float wave_scale = 0.065;
uniform float wave_strength = 0.10;
uniform float ripple_scale = 0.38;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453);
}

float gnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = dot(hash2(i), f);
	float b = dot(hash2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
	float c = dot(hash2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
	float d = dot(hash2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += amp * gnoise(p);
		p = p * 2.03 + vec2(17.3, 9.1);
		amp *= 0.5;
	}
	return v;
}

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float t = TIME * flow_speed;
	vec2 drift = vec2(t, t * 0.63);
	float cam_dist = length(CAMERA_POSITION_WORLD - world_pos);
	float footprint = max(fwidth(world_pos.x), fwidth(world_pos.z));
	float detail = 1.0 - smoothstep(50.0, 420.0, cam_dist);
	detail *= 1.0 - smoothstep(0.05, 0.35, footprint);

	float e = 0.55;
	float h0 = fbm(p * wave_scale + drift);
	float hx = fbm((p + vec2(e, 0.0)) * wave_scale + drift);
	float hz = fbm((p + vec2(0.0, e)) * wave_scale + drift);
	vec2 swell = vec2(hx - h0, hz - h0) / e;

	vec2 rdrift = vec2(t * 1.6, -t * 1.1);
	float r0 = fbm(p * ripple_scale + rdrift);
	float rx = fbm((p + vec2(e, 0.0)) * ripple_scale + rdrift);
	float rz = fbm((p + vec2(0.0, e)) * ripple_scale + rdrift);
	vec2 ripple = vec2(rx - r0, rz - r0) / e;

	vec2 grad = swell * (0.55 - 0.25 * smoothstep(500.0, 2200.0, cam_dist)) + ripple * 0.45 * detail;
	vec3 n_world = normalize(vec3(-grad.x * wave_strength * 4.0, 1.0, -grad.y * wave_strength * 4.0));
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);

	vec3 view = normalize(CAMERA_POSITION_WORLD - world_pos);
	float fres = pow(1.0 - clamp(dot(view, n_world), 0.0, 1.0), 4.0);
	float depth_t = clamp((-VERTEX.z - 6.0) / 260.0, 0.0, 1.0);
	vec3 col = mix(shallow_color, deep_color, depth_t);
	col = mix(col, vec3(0.26, 0.36, 0.44), fres * 0.14);
	ALBEDO = col;
	ROUGHNESS = clamp(mix(0.20, 0.10, fres) + smoothstep(80.0, 1200.0, cam_dist) * 0.18, 0.08, 0.42);
	METALLIC = 0.0;
	SPECULAR = 0.5;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m

static func tree(conifer: bool) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 trunk_color : source_color = vec3(0.18, 0.12, 0.075);
uniform vec3 foliage_color : source_color = vec3(0.16, 0.30, 0.13);
uniform float trunk_h = 3.1;
uniform float sway = 0.12;
varying float v_height;
varying vec3 v_tint;

void vertex() {
	v_height = VERTEX.y;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float amp = clamp(VERTEX.y / 9.0, 0.0, 1.0);
	VERTEX.x += sin(TIME * 1.25 + wp.x * 0.07 + wp.z * 0.09) * amp * sway;
	VERTEX.z += cos(TIME * 1.05 + wp.z * 0.06 + wp.x * 0.05) * amp * sway * 0.65;
	v_tint = COLOR.rgb;
}

void fragment() {
	float t = smoothstep(trunk_h * 0.72, trunk_h * 1.16, v_height);
	vec3 base = mix(trunk_color, foliage_color, t);
	base *= 0.86 + 0.28 * v_tint;
	float grain = 0.92 + 0.12 * fract(sin(dot(floor(v_height * 9.0 + v_tint.xy * 13.0), vec2(12.9898, 78.233))) * 43758.5453);
	ALBEDO = base * grain;
	ROUGHNESS = mix(0.92, 0.84, t);
	METALLIC = 0.0;
	SPECULAR = 0.18;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("trunk_h", 2.2 if conifer else 2.9)
	m.set_shader_parameter("foliage_color", Color(0.13, 0.27, 0.11) if conifer else Color(0.2, 0.34, 0.12))
	return m
