extends RefCounted

# ─────────────────────────────────────────
#  CONFIG
# ─────────────────────────────────────────
const SAVE_PATH := "user://pocketoffice_save.json"

# ─────────────────────────────────────────
#  SAVE
# ─────────────────────────────────────────
static func save(data: Dictionary) -> bool:
	data["save_timestamp"] = Time.get_datetime_string_from_system()

	var json_str := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveSystem] Cannot open file for writing: %s" % SAVE_PATH)
		return false

	file.store_string(json_str)
	file.close()
	print("[SaveSystem] Game saved to %s" % SAVE_PATH)
	return true

# ─────────────────────────────────────────
#  LOAD
# ─────────────────────────────────────────
static func load_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveSystem] No save file found.")
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("[SaveSystem] Cannot open save file for reading.")
		return {}

	var json_str := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(json_str)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[SaveSystem] Save file is corrupt or invalid JSON.")
		return {}

	print("[SaveSystem] Game loaded. Saved at: %s" % parsed.get("save_timestamp", "unknown"))
	return parsed

# ─────────────────────────────────────────
#  UTILITIES
# ─────────────────────────────────────────
static func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

static func delete_save() -> void:
	if save_exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		print("[SaveSystem] Save file deleted.")
