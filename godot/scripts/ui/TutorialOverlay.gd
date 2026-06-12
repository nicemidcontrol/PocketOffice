extends CanvasLayer

# v1.5.2 (PR-6): presentation is delegated to UnifiedPopup. This node keeps
# its public interface (show_tutorial + seen-flag statics) so callers are
# unchanged. The 6 v1.4 steps are served as two chained 3-page popups
# (UnifiedPopup is capped at 3 pages per UI_SYSTEMS_BIBLE).

const PREFS_PATH: String = "user://pocketoffice_prefs.json"
const POPUP_SCENE_PATH: String = "res://scenes/ui/UnifiedPopup.tscn"

const TUTORIAL_SEQUENCE: Array = [
	{
		"title": "Welcome to Pocket Office!",
		"pages": [
			"You are the boss of a new company.\nHire staff, win projects, beat competitors\nover 5 years to be #1.\nCHAMP will guide you!",
			"STEP 1 - HIRE YOUR TEAM\n\nMENU -> HR -> Recruit.\nHigher ad tier = better candidates.\nTry Newspaper ($600) to start.",
			"STEP 2 - ACCEPT PROJECTS\n\nMENU -> Corporate -> Assign Tasks.\nAccept a project, assign an employee,\nwatch progress tick up!",
		],
	},
	{
		"title": "CHAMP's Tips to Win",
		"pages": [
			"STEP 3 - EARN CORPORATE POINTS\n\nCompleting projects earns CASH and CP.\nCP shows top-right of HUD.\nUse CP for items, training, donors.",
			"STEP 4 - BUILD YOUR OFFICE\n\nMENU -> Build to place facilities.\nFacilities boost employee stats.\nCombine facilities for COMBO BONUSES!",
			"STEP 5 - WIN!\n\nEvery 12 months = Annual Evaluation.\nScored on Donors, Revenue, Reputation\nvs 3 AI competitors.\nFinish #1 after Year 5 to WIN!\nGood luck - CHAMP believes in you.",
		],
	},
]

var _sequence_index: int = 0

# ─────────────────────────────────────────
#  STATIC PREFS (unchanged public interface)
# ─────────────────────────────────────────
static func is_tutorial_seen() -> bool:
	var f: FileAccess = FileAccess.open(PREFS_PATH, FileAccess.READ)
	if f == null:
		return false
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		return false
	return bool(parsed.get("tutorial_seen", false))

static func mark_tutorial_seen() -> void:
	var f: FileAccess = FileAccess.open(PREFS_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"tutorial_seen": true}))
	f.close()

# ─────────────────────────────────────────
#  PUBLIC API (unchanged)
# ─────────────────────────────────────────
func show_tutorial() -> void:
	_sequence_index = 0
	_show_next_popup()

# ─────────────────────────────────────────
#  POPUP CHAIN
# ─────────────────────────────────────────
func _show_next_popup() -> void:
	if _sequence_index >= TUTORIAL_SEQUENCE.size():
		_finish()
		return
	var entry: Dictionary = TUTORIAL_SEQUENCE[_sequence_index]
	_sequence_index += 1
	var popup_scene: PackedScene = load(POPUP_SCENE_PATH)
	var popup: CanvasLayer = popup_scene.instantiate()
	add_child(popup)
	popup.setup(str(entry.get("title", "")), entry.get("pages", []))
	popup.open()
	popup.popup_closed.connect(_show_next_popup)

func _finish() -> void:
	mark_tutorial_seen()
	queue_free()
