extends RefCounted
class_name SaveManager


const DIR := "user://saves"
const INDEX_PATH := "user://saves/index.cfg"
const BACKUP_DIR := "user://saves_backup"
const VERSION := 4
# Alpha policy: old save files stay visible and are copied to a backup before
# they can be overwritten. Set this to false only in a later beta if the save
# schema needs a clean break; the files in saves_backup are never deleted.
const LEGACY_COMPAT := true

static func ensure_dir() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)

static func slot_path(id: String) -> String:
	return "%s/%s.cfg" %[DIR, id]

static func new_slot_id() -> String:
	ensure_dir()
	var base := "save_%d" %int(Time.get_unix_time_from_system())
	var id := base
	var n := 2
	while FileAccess.file_exists(slot_path(id)):
		id = "%s_%d" %[base, n]
		n += 1
	return id

static func list_saves() -> Array:
	ensure_dir()
	var out: Array = []
	var dir := DirAccess.open(DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir() and f.begins_with("save_") and f.ends_with(".cfg"):
			var id := f.trim_suffix(".cfg")
			var data := read_save(id)
			if not data.is_empty():
				out.append(data)
		f = dir.get_next()
	dir.list_dir_end()
	out.sort_custom(func(a, b) -> bool: return int(a ["timestamp"]) > int(b ["timestamp"]))
	return out

static func has_saves() -> bool:
	return not list_saves().is_empty()

static func read_save(id: String) -> Dictionary:
	if id == "":
		return {}
	var cfg := ConfigFile.new()
	if cfg.load(slot_path(id)) != OK:
		return {}
	var save_version := int(cfg.get_value("meta", "version", 1))
	var minimum := 1 if LEGACY_COMPAT else VERSION
	if save_version < minimum:
		return {}
	return {
		"id": id,
		"name": String(cfg.get_value("meta", "name", "未命名存档")),
		"timestamp": int(cfg.get_value("meta", "timestamp", 0)),
		"version": save_version,
		"legacy": save_version < VERSION,
		"summary": cfg.get_value("meta", "summary", {}),
		"state": cfg.get_value("state", "data", {}),
	}


static func backup_legacy_saves() -> int:
	ensure_dir()
	DirAccess.make_dir_recursive_absolute(BACKUP_DIR)
	var d := DirAccess.open(DIR)
	if d == null:
		return 0
	var copied := 0
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		if not d.current_is_dir() and f.begins_with("save_") and f.ends_with(".cfg"):
			var src := DIR.path_join(f)
			var cfg := ConfigFile.new()
			if cfg.load(src) == OK:
				var save_version := int(cfg.get_value("meta", "version", 1))
				if save_version < VERSION:
					var dst := BACKUP_DIR.path_join("%s_v%d.cfg" %[
							f.trim_suffix(".cfg"), save_version])
					if not FileAccess.file_exists(dst):
						DirAccess.copy_absolute(src, dst)
						copied += 1
		f = d.get_next()
	d.list_dir_end()
	return copied

static func write_save(id: String, name: String, state: Dictionary) -> bool:
	if id == "":
		return false
	ensure_dir()
	var cfg := ConfigFile.new()
	var ts := int(Time.get_unix_time_from_system())
	cfg.set_value("meta", "name", name)
	cfg.set_value("meta", "timestamp", ts)
	cfg.set_value("meta", "version", VERSION)
	cfg.set_value("meta", "summary", _summary(state))
	cfg.set_value("state", "data", state)
	if cfg.save(slot_path(id)) != OK:
		return false
	set_last_slot(id)
	return true

static func delete_save(id: String) -> void:
	if id == "":
		return
	var path := slot_path(id)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if last_slot() == id:
		var rest := list_saves()
		set_last_slot(String(rest [0] ["id"]) if not rest.is_empty() else "")

static func last_slot() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(INDEX_PATH) != OK:
		return ""
	return String(cfg.get_value("last", "slot", ""))

static func set_last_slot(id: String) -> void:
	ensure_dir()
	var cfg := ConfigFile.new()
	cfg.load(INDEX_PATH)
	cfg.set_value("last", "slot", id)
	cfg.save(INDEX_PATH)

static func last_or_latest() -> String:
	var id := last_slot()
	if id != "" and FileAccess.file_exists(slot_path(id)):
		return id
	var all := list_saves()
	if all.is_empty():
		return ""
	return String(all [0] ["id"])

static func _summary(state: Dictionary) -> Dictionary:
	var t: Dictionary = state.get("train", {})
	var m: Dictionary = state.get("mission", {})
	var career: Dictionary = state.get("career", {})
	return {
		"distance": float(t.get("distance", 0.0)),
		"gear": String(t.get("gear_name", "P3")),
		"index": int(m.get("index", 0)),
		"score": int(m.get("score", 0)),
		"money": int(career.get("money", m.get("money", 0))),
		"completed": int(career.get("completed", m.get("completed", 0))),
		"mode": String(state.get("mode", "open")),
		"level": int(career.get("level", 1)),
	}

static func format_time(ts: int) -> String:
	if ts <= 0:
		return "-"
	var d := Time.get_datetime_dict_from_unix_time(ts)
	return "%04d-%02d-%02d %02d:%02d" %[
		int(d ["year"]), int(d ["month"]), int(d ["day"]), int(d ["hour"]), int(d ["minute"])
	]
