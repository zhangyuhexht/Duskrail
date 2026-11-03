extends RefCounted
class_name Upscaling

# Stable IDs are saved in settings.cfg. Keep these values when editing.
enum Mode {
	OFF,
	FSR2_QUALITY,
	FSR2_BALANCED,
	FSR2_PERFORMANCE,
	DLSS_QUALITY,
	DLSS_BALANCED,
	DLSS_PERFORMANCE,
	DLAA,
}

const LABELS := [
	"关闭（原生）",
	"FSR 2.2 质量",
	"FSR 2.2 平衡",
	"FSR 2.2 性能",
	"DLSS 质量",
	"DLSS 平衡",
	"DLSS 性能",
	"DLAA",
]

const SCALES := [1.0, 0.667, 0.588, 0.500, 0.667, 0.588, 0.500, 1.0]
# Matching Viewport scaling_3d_mode values in the NVIDIA Godot fork:
# 0 = bilinear, 2 = FSR 2.2, 6 = NVIDIA DLSS.
const VIEWPORT_MODES := [0, 2, 2, 2, 6, 6, 6, 6]


static func dlss_available() -> bool:
	if not Engine.has_singleton("Streamline"):
		return false
	var streamline := Engine.get_singleton("Streamline")
	if streamline == null or not streamline.has_method("get_capability"):
		return false
	# StreamlineCapabilityType.STREAMLINE_CAPABILITY_DLSS == 0
	return bool(streamline.call("get_capability", 0))


static func available_modes() -> Array:
	var modes := [Mode.OFF, Mode.FSR2_QUALITY, Mode.FSR2_BALANCED, Mode.FSR2_PERFORMANCE]
	if dlss_available():
		modes.append_array([Mode.DLSS_QUALITY, Mode.DLSS_BALANCED,
				Mode.DLSS_PERFORMANCE, Mode.DLAA])
	return modes


static func label_for(mode: int) -> String:
	return String(LABELS[clampi(mode, 0, LABELS.size() - 1)])


static func mode_from_name(name: String) -> int:
	match name.to_lower().replace("_", "-"):
		"off", "native":
			return Mode.OFF
		"fsr2-quality", "fsr-quality":
			return Mode.FSR2_QUALITY
		"fsr2-balanced", "fsr-balanced":
			return Mode.FSR2_BALANCED
		"fsr2-performance", "fsr-performance":
			return Mode.FSR2_PERFORMANCE
		"dlss-quality":
			return Mode.DLSS_QUALITY
		"dlss-balanced":
			return Mode.DLSS_BALANCED
		"dlss-performance":
			return Mode.DLSS_PERFORMANCE
		"dlaa":
			return Mode.DLAA
	return -1


static func is_dlss_mode(mode: int) -> bool:
	return mode >= Mode.DLSS_QUALITY and mode <= Mode.DLAA


static func is_temporal(mode: int) -> bool:
	return mode >= Mode.FSR2_QUALITY and mode <= Mode.DLAA


static func apply(viewport: Viewport, mode: int) -> int:
	if viewport == null:
		return Mode.OFF
	var requested := clampi(mode, 0, LABELS.size() - 1)
	var actual := requested
	if is_dlss_mode(requested) and not dlss_available():
		actual = Mode.FSR2_QUALITY
	viewport.scaling_3d_mode = int(VIEWPORT_MODES[actual])
	viewport.scaling_3d_scale = float(SCALES[actual])
	# Temporal upscalers do their own anti-aliasing. Keeping MSAA on top is
	# both redundant and expensive, and can hide the performance gain.
	if is_temporal(actual):
		viewport.msaa_3d = Viewport.MSAA_DISABLED
	return actual


static func apply_to_root(mode: int) -> int:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return Mode.OFF
	return apply(tree.root, mode)
