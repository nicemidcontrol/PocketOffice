extends Control

# =============================================================================
# THROWAWAY PROTOTYPE — v1.5.2 Phase Animation Loop
# Purpose: test if the loop is fun. NOT for integration.
# Run with F6 in Godot. R = restart. Tap = 3x speed. Hold = skip.
# =============================================================================

# ── Palette (closest PICO-8 matches to UI_SYSTEMS_BIBLE tokens) ──────────────
const C_NAVY    := Color(0.102, 0.137, 0.196)   # #1a2332 modal bg
const C_BORDER  := Color(0.239, 0.353, 0.502)   # #3d5a80 border
const C_GOLD    := Color(1.000, 0.784, 0.341)   # #ffc857 accent
const C_TEAL    := Color(0.365, 0.792, 0.647)   # #5dcaa5 SP filled
const C_GREY    := Color(0.267, 0.267, 0.267)   # #444444 SP empty
const C_WHITE   := Color(1.0, 1.0, 1.0)
const C_RED     := Color(0.90, 0.25, 0.25)
const C_GREEN   := Color(0.20, 0.75, 0.30)      # Field Officer
const C_BLUE    := Color(0.20, 0.45, 0.85)      # Project Manager
const C_ORANGE  := Color(0.90, 0.55, 0.15)      # Supply Officer
const C_PANEL   := Color(0.08, 0.11, 0.17)      # darker navy for sub-panels

# ── State machine ─────────────────────────────────────────────────────────────
enum State {
	PICKER,
	TABLEAU,
	SUBROUND,
	SUBROUND_GAP,
	PHASE_COMPLETE,
	PHASE_GAP,
	TASK_COMPLETE
}

# ── Employee data ─────────────────────────────────────────────────────────────
class ProtoEmployee:
	var id: int
	var display_name: String
	var role: String
	var tier: String
	var color: Color
	var sp: int
	var sp_max: int
	var management: int
	var focus: int
	var technical: int
	var precision: int
	var procurement: int
	var logistics: int

func _make_employees() -> Array:
	var george := ProtoEmployee.new()
	george.id = 0
	george.display_name = "George Anan"
	george.role = "PROJECT MANAGER"
	george.tier = "D"
	george.color = C_BLUE
	george.sp = 5
	george.sp_max = 5
	george.management = 38
	george.focus = 32
	george.technical = 20
	george.precision = 18
	george.procurement = 15
	george.logistics = 12

	var sarah := ProtoEmployee.new()
	sarah.id = 1
	sarah.display_name = "Sarah Oduya"
	sarah.role = "FIELD OFFICER"
	sarah.tier = "D"
	sarah.color = C_GREEN
	sarah.sp = 5
	sarah.sp_max = 5
	sarah.management = 14
	sarah.focus = 20
	sarah.technical = 40
	sarah.precision = 35
	sarah.procurement = 18
	sarah.logistics = 16

	var tom := ProtoEmployee.new()
	tom.id = 2
	tom.display_name = "Tom Supasit"
	tom.role = "SUPPLY OFFICER"
	tom.tier = "D"
	tom.color = C_ORANGE
	tom.sp = 4
	tom.sp_max = 5
	tom.management = 16
	tom.focus = 18
	tom.technical = 22
	tom.precision = 20
	tom.procurement = 42
	tom.logistics = 38

	return [george, sarah, tom]

# ── Phase data ────────────────────────────────────────────────────────────────
const PHASES: Array = [
	{
		"name": "PLANNING",
		"stat_a_key": "management",
		"stat_a_label": "Management",
		"stat_b_key": "focus",
		"stat_b_label": "Focus",
		"icon": "P",
		"best_role": "PROJECT MANAGER"
	},
	{
		"name": "EXECUTION",
		"stat_a_key": "technical",
		"stat_a_label": "Technical",
		"stat_b_key": "precision",
		"stat_b_label": "Precision",
		"icon": "X",
		"best_role": "FIELD OFFICER"
	},
	{
		"name": "LOGISTICS",
		"stat_a_key": "procurement",
		"stat_a_label": "Procurement",
		"stat_b_key": "logistics",
		"stat_b_label": "Logistics",
		"icon": "L",
		"best_role": "SUPPLY OFFICER"
	}
]

const SUBROUND_MULTIPLIERS: Array = [0.10, 0.30, 0.60]
const SP_COST_PER_PHASE: int = 3

# ── Timing constants (seconds, real-time before time scale) ──────────────────
const T_TABLEAU_TOTAL: float = 1.5
const T_SUBROUND_ANIM: float = 2.0
const T_SUBROUND_GAP: float = 5.0
const T_PHASE_COMPLETE: float = 2.5
const T_PHASE_GAP: float = 30.0
const T_HOLD_SKIP: float = 0.4

# ── Runtime state ─────────────────────────────────────────────────────────────
var _state: State = State.PICKER
var _elapsed: float = 0.0
var _time_scale: float = 1.0
var _hold_time: float = 0.0

var _employees: Array = []
var _phase_idx: int = 0          # 0..2
var _subround_idx: int = 0       # 0..2
var _selected_emp_id: int = -1
var _used_emp_ids: Array = []    # cannot reuse same emp in same task

var _phase_param: float = 0.0    # accumulated param score this phase
var _subround_param: float = 0.0 # param earned this subround (animated)
var _param_scores: Array = [0.0, 0.0, 0.0]  # final scores per phase

# floating icon animation
var _icon_active: bool = false
var _icon_t: float = 0.0
var _icon_label: Label = null
var _icon_start: Vector2 = Vector2.ZERO
var _icon_end: Vector2 = Vector2.ZERO

# ── UI node references (built in _ready) ─────────────────────────────────────
var _top_bar: ColorRect = null
var _phase_label: Label = null
var _subround_label: Label = null

var _param_bars: Array = []       # Array of ProgressBar
var _param_labels: Array = []     # Array of Label (score numbers)
var _param_names: Label = null    # combined label shown in top bar

var _office_area: Control = null
var _emp_blocks: Array = []       # ColorRect per employee
var _emp_name_labels: Array = []  # Label per employee (name overlay)
var _emp_sp_labels: Array = []    # Label per employee (SP count)
var _emp_glow: ColorRect = null   # highlight overlay on selected emp

var _bottom_area: Control = null
var _picker_container: VBoxContainer = null
var _picker_cards: Array = []
var _status_label: Label = null
var _hint_label: Label = null
var _continue_btn: Button = null

var _score_summary: VBoxContainer = null

# ── Initialisation ────────────────────────────────────────────────────────────

func _ready() -> void:
	_employees = _make_employees()
	_build_ui()
	_enter_picker()

func _build_ui() -> void:
	custom_minimum_size = Vector2(390, 844)

	# root bg
	var bg := ColorRect.new()
	bg.color = C_NAVY
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── Top bar (60px) ────────────────────────────────────────────────────
	_top_bar = ColorRect.new()
	_top_bar.color = C_PANEL
	_top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_bar.size = Vector2(390, 60)
	_top_bar.position = Vector2(0, 0)
	add_child(_top_bar)

	_phase_label = Label.new()
	_phase_label.position = Vector2(12, 8)
	_phase_label.size = Vector2(300, 24)
	_phase_label.add_theme_color_override("font_color", C_GOLD)
	_phase_label.text = "Soil Sampling Survey — PLANNING phase"
	_top_bar.add_child(_phase_label)

	_subround_label = Label.new()
	_subround_label.position = Vector2(12, 34)
	_subround_label.size = Vector2(366, 20)
	_subround_label.add_theme_color_override("font_color", C_WHITE)
	_subround_label.text = "Pick an employee to work this phase"
	_top_bar.add_child(_subround_label)

	# ── Param area (90px, y=60) ───────────────────────────────────────────
	var param_area := ColorRect.new()
	param_area.color = C_PANEL
	param_area.position = Vector2(0, 62)
	param_area.size = Vector2(390, 90)
	add_child(param_area)

	var phase_names := ["PLANNING", "EXECUTION", "LOGISTICS"]
	for i in range(3):
		var row := Control.new()
		row.position = Vector2(12, i * 28 + 6)
		row.size = Vector2(366, 24)
		param_area.add_child(row)

		var lbl := Label.new()
		lbl.position = Vector2(0, 0)
		lbl.size = Vector2(90, 20)
		lbl.text = phase_names[i]
		lbl.add_theme_color_override("font_color", C_WHITE)
		lbl.add_theme_font_size_override("font_size", 11)
		row.add_child(lbl)

		var bar := ProgressBar.new()
		bar.position = Vector2(96, 2)
		bar.size = Vector2(210, 16)
		bar.min_value = 0.0
		bar.max_value = 200.0
		bar.value = 0.0
		bar.show_percentage = false
		row.add_child(bar)
		_param_bars.append(bar)

		var score_lbl := Label.new()
		score_lbl.position = Vector2(312, 0)
		score_lbl.size = Vector2(54, 20)
		score_lbl.text = "0"
		score_lbl.add_theme_color_override("font_color", C_GOLD)
		score_lbl.add_theme_font_size_override("font_size", 12)
		row.add_child(score_lbl)
		_param_labels.append(score_lbl)

	# ── Office area (400px, y=154) ─────────────────────────────────────────
	_office_area = Control.new()
	_office_area.position = Vector2(0, 154)
	_office_area.size = Vector2(390, 400)
	add_child(_office_area)

	var office_bg := ColorRect.new()
	office_bg.color = Color(0.06, 0.09, 0.14)
	office_bg.size = Vector2(390, 400)
	_office_area.add_child(office_bg)

	# office floor grid lines (decorative)
	for gx in range(0, 390, 32):
		var line := ColorRect.new()
		line.color = Color(0.12, 0.16, 0.22)
		line.position = Vector2(gx, 0)
		line.size = Vector2(1, 400)
		_office_area.add_child(line)
	for gy in range(0, 400, 32):
		var line := ColorRect.new()
		line.color = Color(0.12, 0.16, 0.22)
		line.position = Vector2(0, gy)
		line.size = Vector2(390, 1)
		_office_area.add_child(line)

	# employee blocks: 3 side by side, 100x90 px, y=155 inside office_area
	var emp_positions := [
		Vector2(15, 155),
		Vector2(145, 155),
		Vector2(275, 155)
	]
	for i in range(3):
		var emp: ProtoEmployee = _employees[i]

		var block := ColorRect.new()
		block.color = emp.color
		block.position = emp_positions[i]
		block.size = Vector2(100, 90)
		_office_area.add_child(block)
		_emp_blocks.append(block)

		var name_lbl := Label.new()
		name_lbl.position = emp_positions[i] + Vector2(0, 94)
		name_lbl.size = Vector2(100, 18)
		name_lbl.text = emp.display_name.split(" ")[0]
		name_lbl.add_theme_color_override("font_color", C_WHITE)
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_office_area.add_child(name_lbl)
		_emp_name_labels.append(name_lbl)

		var sp_lbl := Label.new()
		sp_lbl.position = emp_positions[i] + Vector2(0, 112)
		sp_lbl.size = Vector2(100, 16)
		sp_lbl.text = "SP: %d/%d" % [emp.sp, emp.sp_max]
		sp_lbl.add_theme_color_override("font_color", C_TEAL)
		sp_lbl.add_theme_font_size_override("font_size", 10)
		sp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_office_area.add_child(sp_lbl)
		_emp_sp_labels.append(sp_lbl)

	# glow ring overlay (hidden until needed)
	_emp_glow = ColorRect.new()
	_emp_glow.color = Color(C_GOLD, 0.25)
	_emp_glow.size = Vector2(108, 98)
	_emp_glow.position = Vector2(-200, -200)
	_office_area.add_child(_emp_glow)

	# floating icon label
	_icon_label = Label.new()
	_icon_label.position = Vector2(-100, -100)
	_icon_label.size = Vector2(30, 30)
	_icon_label.add_theme_color_override("font_color", C_GOLD)
	_icon_label.add_theme_font_size_override("font_size", 18)
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_icon_label)

	# ── Bottom area (240px, y=554) ─────────────────────────────────────────
	_bottom_area = Control.new()
	_bottom_area.position = Vector2(0, 554)
	_bottom_area.size = Vector2(390, 290)
	add_child(_bottom_area)

	var bottom_bg := ColorRect.new()
	bottom_bg.color = C_PANEL
	bottom_bg.size = Vector2(390, 290)
	_bottom_area.add_child(bottom_bg)

	# Picker container (shown in PICKER state)
	_picker_container = VBoxContainer.new()
	_picker_container.position = Vector2(8, 8)
	_picker_container.size = Vector2(374, 274)
	_bottom_area.add_child(_picker_container)

	var picker_title := Label.new()
	picker_title.text = "Choose who works this phase:"
	picker_title.add_theme_color_override("font_color", C_WHITE)
	picker_title.add_theme_font_size_override("font_size", 13)
	_picker_container.add_child(picker_title)

	for i in range(3):
		var card := _build_picker_card(i)
		_picker_container.add_child(card)
		_picker_cards.append(card)

	# Status label (shown during animation states)
	_status_label = Label.new()
	_status_label.position = Vector2(12, 12)
	_status_label.size = Vector2(366, 60)
	_status_label.add_theme_color_override("font_color", C_GOLD)
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.visible = false
	_bottom_area.add_child(_status_label)

	# Hint label
	_hint_label = Label.new()
	_hint_label.position = Vector2(12, 248)
	_hint_label.size = Vector2(366, 18)
	_hint_label.add_theme_color_override("font_color", C_GREY)
	_hint_label.add_theme_font_size_override("font_size", 10)
	_hint_label.text = ""
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bottom_area.add_child(_hint_label)

	# Continue button (shown in PHASE_GAP)
	_continue_btn = Button.new()
	_continue_btn.position = Vector2(95, 200)
	_continue_btn.size = Vector2(200, 40)
	_continue_btn.text = "Continue to next phase ->"
	_continue_btn.visible = false
	_continue_btn.pressed.connect(_on_continue_pressed)
	_bottom_area.add_child(_continue_btn)

	# Score summary (shown at TASK_COMPLETE)
	_score_summary = VBoxContainer.new()
	_score_summary.position = Vector2(12, 8)
	_score_summary.size = Vector2(366, 270)
	_score_summary.visible = false
	_bottom_area.add_child(_score_summary)

func _build_picker_card(emp_idx: int) -> PanelContainer:
	var emp: ProtoEmployee = _employees[emp_idx]

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(374, 72)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)

	# portrait block
	var portrait := ColorRect.new()
	portrait.color = emp.color
	portrait.custom_minimum_size = Vector2(56, 64)
	hbox.add_child(portrait)

	# info vbox
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = emp.display_name
	name_lbl.add_theme_color_override("font_color", C_WHITE)
	name_lbl.add_theme_font_size_override("font_size", 13)
	info.add_child(name_lbl)

	var role_lbl := Label.new()
	role_lbl.text = "%s  TIER %s" % [emp.role, emp.tier]
	role_lbl.add_theme_color_override("font_color", Color(C_WHITE, 0.6))
	role_lbl.add_theme_font_size_override("font_size", 10)
	info.add_child(role_lbl)

	var sp_lbl := Label.new()
	sp_lbl.text = "SP: %d/%d" % [emp.sp, emp.sp_max]
	sp_lbl.add_theme_color_override("font_color", C_TEAL)
	sp_lbl.add_theme_font_size_override("font_size", 11)
	info.add_child(sp_lbl)
	sp_lbl.set_meta("sp_label", true)

	# contribution estimate
	var phase := PHASES[_phase_idx]
	var stat_a: int = emp.get(phase["stat_a_key"])
	var stat_b: int = emp.get(phase["stat_b_key"])
	var contrib := stat_a + stat_b
	var contrib_lbl := Label.new()
	contrib_lbl.text = "Expected contribution: ~%d" % contrib
	contrib_lbl.add_theme_color_override("font_color", C_GOLD)
	contrib_lbl.add_theme_font_size_override("font_size", 10)
	info.add_child(contrib_lbl)
	contrib_lbl.set_meta("contrib_label", true)

	# tap to select
	var btn := Button.new()
	btn.text = "SELECT"
	btn.custom_minimum_size = Vector2(72, 0)
	btn.pressed.connect(_on_picker_select.bind(emp_idx))
	hbox.add_child(btn)

	return panel

# ── State transitions ─────────────────────────────────────────────────────────

func _enter_picker() -> void:
	_state = State.PICKER
	_elapsed = 0.0
	_selected_emp_id = -1

	var phase := PHASES[_phase_idx]
	_phase_label.text = "Soil Sampling Survey — %s phase" % phase["name"]
	_subround_label.text = "Pick an employee to work this phase"

	_picker_container.visible = true
	_status_label.visible = false
	_continue_btn.visible = false
	_score_summary.visible = false
	_hint_label.text = "Select an employee below"

	_emp_glow.position = Vector2(-200, -200)
	_refresh_picker_cards()


func _refresh_picker_cards() -> void:
	var phase := PHASES[_phase_idx]
	for i in range(3):
		var emp: ProtoEmployee = _employees[i]
		var card: PanelContainer = _picker_cards[i]
		var insufficient_sp := emp.sp < SP_COST_PER_PHASE
		var already_used := _used_emp_ids.has(emp.id)
		var ineligible := insufficient_sp or already_used

		card.modulate = Color(1, 1, 1, 0.35) if ineligible else Color(1, 1, 1, 1.0)

		# update contrib estimate for current phase
		var stat_a: int = emp.get(phase["stat_a_key"])
		var stat_b: int = emp.get(phase["stat_b_key"])
		var contrib := stat_a + stat_b
		# find the contrib label inside the card
		var hbox: HBoxContainer = card.get_child(0)
		var info: VBoxContainer = hbox.get_child(1)
		for child in info.get_children():
			if child.has_meta("contrib_label"):
				child.text = "Expected contribution: ~%d" % contrib
			if child.has_meta("sp_label"):
				var color := C_RED if insufficient_sp else C_TEAL
				child.add_theme_color_override("font_color", color)
				child.text = "SP: %d/%d  %s" % [emp.sp, emp.sp_max, "(need 3)" if insufficient_sp else ""]


func _on_picker_select(emp_idx: int) -> void:
	if _state != State.PICKER:
		return
	var emp: ProtoEmployee = _employees[emp_idx]
	if emp.sp < SP_COST_PER_PHASE or _used_emp_ids.has(emp.id):
		return
	_selected_emp_id = emp.id
	_used_emp_ids.append(emp.id)
	emp.sp -= SP_COST_PER_PHASE
	_emp_sp_labels[emp_idx].text = "SP: %d/%d" % [emp.sp, emp.sp_max]
	_enter_tableau()


func _enter_tableau() -> void:
	_state = State.TABLEAU
	_elapsed = 0.0
	_subround_idx = 0
	_phase_param = 0.0

	_picker_container.visible = false
	_status_label.visible = true
	_status_label.text = "Getting ready..."
	_hint_label.text = "Tap = 3x speed   Hold = skip"

	# show glow on selected employee
	var sel_idx := _get_emp_idx(_selected_emp_id)
	if sel_idx >= 0:
		var emp_block: ColorRect = _emp_blocks[sel_idx]
		_emp_glow.position = emp_block.position - Vector2(4, 4)
		_emp_glow.get_parent().move_child(_emp_glow, _emp_glow.get_parent().get_child_count() - 1)


func _enter_subround() -> void:
	_state = State.SUBROUND
	_elapsed = 0.0
	_subround_param = 0.0

	var phase := PHASES[_phase_idx]
	var emp: ProtoEmployee = _employees[_get_emp_idx(_selected_emp_id)]
	var stat_a: int = emp.get(phase["stat_a_key"])
	var stat_b: int = emp.get(phase["stat_b_key"])
	var base: float = float(stat_a + stat_b)
	var variance: float = randf_range(-0.15, 0.15)
	_subround_param = base * SUBROUND_MULTIPLIERS[_subround_idx] * (1.0 + variance)

	_subround_label.text = "Subround %d/3 — %s contributing..." % [_subround_idx + 1, emp.display_name.split(" ")[0]]
	_status_label.text = ""

	# kick off floating icon
	var sel_idx := _get_emp_idx(_selected_emp_id)
	var emp_block: ColorRect = _emp_blocks[sel_idx]
	_icon_start = _office_area.position + emp_block.position + Vector2(50, 0)
	_icon_end = Vector2(195, 120)  # param bar area
	_icon_label.text = phase["icon"]
	_icon_t = 0.0
	_icon_active = true


func _enter_subround_gap() -> void:
	_state = State.SUBROUND_GAP
	_elapsed = 0.0

	_phase_param += _subround_param
	_param_bars[_phase_idx].value = _phase_param
	_param_labels[_phase_idx].text = str(int(_phase_param))

	var sub := _subround_idx + 1
	_status_label.text = "Subround %d complete: +%d\nTotal so far: %d" % [sub, int(_subround_param), int(_phase_param)]
	_hint_label.text = "Tap = 3x speed   Hold = skip"


func _enter_phase_complete() -> void:
	_state = State.PHASE_COMPLETE
	_elapsed = 0.0

	_param_scores[_phase_idx] = _phase_param
	var phase := PHASES[_phase_idx]
	_subround_label.text = "%s COMPLETE!" % phase["name"]
	_status_label.text = "%s score: %d\n\nDrum roll..." % [phase["name"], int(_phase_param)]
	_hint_label.text = "(Phase complete — cannot skip)"


func _enter_phase_gap() -> void:
	_state = State.PHASE_GAP
	_elapsed = 0.0
	_emp_glow.position = Vector2(-200, -200)

	var phase := PHASES[_phase_idx]
	_status_label.text = "%s phase score: %d\n\nEmployees are resting...\n\nNext phase starts soon." % [phase["name"], int(_phase_param)]
	_hint_label.text = "Tap anywhere to advance immediately"
	_continue_btn.visible = true


func _advance_to_next_phase() -> void:
	_continue_btn.visible = false
	_phase_idx += 1
	if _phase_idx >= PHASES.size():
		_enter_task_complete()
	else:
		_enter_picker()


func _enter_task_complete() -> void:
	_state = State.TASK_COMPLETE
	_elapsed = 0.0
	_emp_glow.position = Vector2(-200, -200)

	_picker_container.visible = false
	_status_label.visible = false
	_continue_btn.visible = false
	_score_summary.visible = true
	_hint_label.text = "Press R to restart"
	_phase_label.text = "Soil Sampling Survey — COMPLETE"
	_subround_label.text = "Task finished!"

	# clear and rebuild score summary
	for child in _score_summary.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "Task Complete — Final Scores"
	title.add_theme_color_override("font_color", C_GOLD)
	title.add_theme_font_size_override("font_size", 16)
	_score_summary.add_child(title)

	var sep := HSeparator.new()
	_score_summary.add_child(sep)

	var phase_names_full := ["PLANNING", "EXECUTION", "LOGISTICS"]
	for i in range(3):
		var row := Label.new()
		row.text = "  %s: %d" % [phase_names_full[i], int(_param_scores[i])]
		row.add_theme_color_override("font_color", C_WHITE)
		row.add_theme_font_size_override("font_size", 14)
		_score_summary.add_child(row)

	var total: float = _param_scores[0] + _param_scores[1] + _param_scores[2]
	var sep2 := HSeparator.new()
	_score_summary.add_child(sep2)

	var total_lbl := Label.new()
	total_lbl.text = "  TOTAL: %d" % int(total)
	total_lbl.add_theme_color_override("font_color", C_GOLD)
	total_lbl.add_theme_font_size_override("font_size", 15)
	_score_summary.add_child(total_lbl)

	var grade := _calc_grade(total)
	var grade_lbl := Label.new()
	grade_lbl.text = "  Grade: %s" % grade
	grade_lbl.add_theme_color_override("font_color", C_GOLD)
	grade_lbl.add_theme_font_size_override("font_size", 20)
	_score_summary.add_child(grade_lbl)

	var restart_lbl := Label.new()
	restart_lbl.text = "\nPress R to play again"
	restart_lbl.add_theme_color_override("font_color", Color(C_WHITE, 0.5))
	restart_lbl.add_theme_font_size_override("font_size", 11)
	_score_summary.add_child(restart_lbl)


func _calc_grade(total: float) -> String:
	if total >= 210.0:
		return "S  (Outstanding!)"
	elif total >= 175.0:
		return "A  (Excellent)"
	elif total >= 140.0:
		return "B  (Good)"
	elif total >= 105.0:
		return "C  (Adequate)"
	elif total >= 70.0:
		return "D  (Struggling)"
	else:
		return "F  (Failed)"

# ── Process loop ──────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_elapsed += delta * _time_scale

	# floating icon animation
	if _icon_active:
		_icon_t += delta * _time_scale * 0.7
		var t := clampf(_icon_t, 0.0, 1.0)
		_icon_label.position = _icon_start.lerp(_icon_end, t)
		if t >= 1.0:
			_icon_active = false
			_icon_label.position = Vector2(-100, -100)

	match _state:
		State.TABLEAU:
			if _elapsed >= T_TABLEAU_TOTAL:
				_enter_subround()

		State.SUBROUND:
			if _elapsed >= T_SUBROUND_ANIM:
				_enter_subround_gap()

		State.SUBROUND_GAP:
			if _elapsed >= T_SUBROUND_GAP:
				_subround_idx += 1
				if _subround_idx < 3:
					_enter_subround()
				else:
					_enter_phase_complete()

		State.PHASE_COMPLETE:
			if _elapsed >= T_PHASE_COMPLETE:
				_enter_phase_gap()

		State.PHASE_GAP:
			if _elapsed >= T_PHASE_GAP:
				_advance_to_next_phase()

# ── Input handling ────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	# restart
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_R:
			_restart()
			return

	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed := false
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			pressed = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
			if not mb.pressed:
				_time_scale = 1.0
				_hold_time = 0.0
		elif event is InputEventScreenTouch:
			var st := event as InputEventScreenTouch
			pressed = st.pressed
			if not st.pressed:
				_time_scale = 1.0
				_hold_time = 0.0

		if pressed:
			_on_tap()

	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		# track hold for skip
		pass


func _on_tap() -> void:
	match _state:
		State.TABLEAU, State.SUBROUND, State.SUBROUND_GAP:
			_time_scale = 3.0
		State.PHASE_GAP:
			_advance_to_next_phase()
		State.PHASE_COMPLETE:
			pass  # cannot skip phase complete reveal


func _on_continue_pressed() -> void:
	if _state == State.PHASE_GAP:
		_advance_to_next_phase()


func _restart() -> void:
	_employees = _make_employees()
	_phase_idx = 0
	_subround_idx = 0
	_used_emp_ids = []
	_param_scores = [0.0, 0.0, 0.0]
	_icon_active = false
	_icon_label.position = Vector2(-100, -100)
	_time_scale = 1.0
	_hold_time = 0.0

	for bar in _param_bars:
		bar.value = 0.0
	for lbl in _param_labels:
		lbl.text = "0"
	for i in range(3):
		var emp: ProtoEmployee = _employees[i]
		_emp_sp_labels[i].text = "SP: %d/%d" % [emp.sp, emp.sp_max]

	# rebuild picker cards fresh
	for card in _picker_cards:
		card.queue_free()
	_picker_cards.clear()
	for i in range(3):
		var card := _build_picker_card(i)
		_picker_container.add_child(card)
		_picker_cards.append(card)

	_enter_picker()

# ── Helpers ───────────────────────────────────────────────────────────────────

func _get_emp_idx(emp_id: int) -> int:
	for i in range(_employees.size()):
		var emp: ProtoEmployee = _employees[i]
		if emp.id == emp_id:
			return i
	return -1
