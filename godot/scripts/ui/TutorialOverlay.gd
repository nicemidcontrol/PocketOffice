extends CanvasLayer

const PREFS_PATH: String = "user://pocketoffice_prefs.json"

# ------------------------------------------
#  TUTORIAL STEPS
# ------------------------------------------
const STEPS: Array = [
	{
		"title":   "Welcome to Pocket Office!",
		"body":    "You are the boss of a new company.\nHire staff, win projects, beat competitors\nover 5 years to be #1.\nCHAMP will guide you!",
		"speaker": "CHAMP"
	},
	{
		"title":   "Step 1: Hire Your Team",
		"body":    "MENU -> HR -> Recruit.\nHigher ad tier = better candidates.\nTry Newspaper ($600) to start.",
		"speaker": "HOW TO HIRE"
	},
	{
		"title":   "Step 2: Accept Projects",
		"body":    "MENU -> Corporate -> Assign Tasks.\nAccept a project, assign an employee,\nwatch progress tick up!",
		"speaker": "PROJECTS"
	},
	{
		"title":   "Step 3: Earn Corporate Points",
		"body":    "Completing projects earns CASH and CP.\nCP shows top-right of HUD.\nUse CP for items, training, donors.",
		"speaker": "CORP POINTS"
	},
	{
		"title":   "Step 4: Build Your Office",
		"body":    "MENU -> Build to place facilities.\nFacilities boost employee stats.\nCombine facilities for COMBO BONUSES!",
		"speaker": "OFFICE"
	},
	{
		"title":   "Step 5: Win!",
		"body":    "Every 12 months = Annual Evaluation.\nScored on Donors, Revenue, Reputation\nvs 3 AI competitors.\nFinish #1 after Year 5 to WIN!\nGood luck - CHAMP believes in you.",
		"speaker": "WIN"
	}
]

# ------------------------------------------
#  NODE REFS
# ------------------------------------------
@onready var _root:        Control       = $Root
@onready var _step_lbl:    Label         = $Root/Card/CardMargin/CardVBox/StepLabel
@onready var _title_lbl:   Label         = $Root/Card/CardMargin/CardVBox/TitleLabel
@onready var _body_lbl:    Label         = $Root/Card/CardMargin/CardVBox/BodyLabel
@onready var _speaker_lbl: Label         = $Root/Card/CardMargin/CardVBox/TopRow/SpeakerLabel
@onready var _next_btn:    Button        = $Root/Card/CardMargin/CardVBox/BtnRow/NextBtn
@onready var _skip_btn:    Button        = $Root/Card/CardMargin/CardVBox/BtnRow/SkipBtn
@onready var _dot_row:     HBoxContainer = $Root/Card/CardMargin/CardVBox/DotRow

# ------------------------------------------
#  STATE
# ------------------------------------------
var _step: int = 0

# ------------------------------------------
#  STATIC PREFS
# ------------------------------------------
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

# ------------------------------------------
#  LIFECYCLE
# ------------------------------------------
func _ready() -> void:
	_root.visible = false
	_next_btn.pressed.connect(_on_next_pressed)
	_skip_btn.pressed.connect(_on_skip_pressed)

# ------------------------------------------
#  PUBLIC API
# ------------------------------------------
func show_tutorial() -> void:
	_step = 0
	_root.visible = true
	_show_step()

# ------------------------------------------
#  STEP LOGIC
# ------------------------------------------
func _show_step() -> void:
	var data: Dictionary = STEPS[_step]
	_speaker_lbl.text = data["speaker"]
	_title_lbl.text   = data["title"]
	_body_lbl.text    = data["body"]
	_step_lbl.text    = "%d / %d" % [_step + 1, STEPS.size()]
	if _step == STEPS.size() - 1:
		_next_btn.text = "LET'S GO!"
	else:
		_next_btn.text = "NEXT >"
	_build_dots()

func _build_dots() -> void:
	for child in _dot_row.get_children():
		child.queue_free()
	for i in range(STEPS.size()):
		var dot: Label = Label.new()
		dot.text = "O" if i == _step else "o"
		dot.add_theme_font_size_override("font_size", 12)
		if i == _step:
			dot.add_theme_color_override("font_color", Color(1.0, 0.82, 0.1, 1.0))
		else:
			dot.add_theme_color_override("font_color", Color(0.4, 0.41, 0.52, 1.0))
		_dot_row.add_child(dot)

func _on_next_pressed() -> void:
	_step += 1
	if _step >= STEPS.size():
		_finish()
	else:
		_show_step()

func _on_skip_pressed() -> void:
	_finish()

func _finish() -> void:
	mark_tutorial_seen()
	_root.visible = false
	queue_free()
