extends RefCounted


const NAME_EN := "DUSKRAIL"
const NAME_CN := "暮轨"
const TAGLINE_EN := "3D RAILWAY SIMULATION"
const TAGLINE_CN := "3D 铁路运输模拟"
const STUDIO := "Duskrail Studio"
const VERSION := "alpha1.0"

static var _display_font: Font
static var _wordmark_font: Font

static func cjk_font() -> Font:
	return ThemeDB.fallback_font

static func display_font() -> Font:
	if _display_font == null:
		var f := FontFile.new()
		var path := "C:/Windows/Fonts/bahnschrift.ttf"
		if FileAccess.file_exists(path) and f.load_dynamic_font(path) == OK:
			_display_font = f
		else:
			_display_font = ThemeDB.fallback_font
	return _display_font

static func wordmark_font() -> Font:
	if _wordmark_font == null:
		var fv := FontVariation.new()
		fv.base_font = display_font()
		fv.variation_embolden = 0.55
		_wordmark_font = fv
	return _wordmark_font
