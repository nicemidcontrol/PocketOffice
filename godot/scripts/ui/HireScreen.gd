extends "res://scripts/ui/BaseModal.gd"

# ─────────────────────────────────────────
#  PHASES
# ─────────────────────────────────────────
const PHASE_ADS:   int = 0
const PHASE_CHAMP: int = 1
const PHASE_CANDS: int = 2

# ─────────────────────────────────────────
#  CONSTANTS  (preserved from original)
# ─────────────────────────────────────────
const AD_DATA: Array = [
	{"name": "Milk Carton",    "cost": 300,  "tier": 0, "count": 2, "desc": "Desperate times..."},
	{"name": "Newspaper",      "cost": 600,  "tier": 1, "count": 3, "desc": "Old school but reliable."},
	{"name": "Radio",          "cost": 1000, "tier": 2, "count": 3, "desc": "Reaches more ears."},
	{"name": "Television",     "cost": 1800, "tier": 3, "count": 4, "desc": "Prime time exposure."},
	{"name": "Online Ad",      "cost": 2200, "tier": 4, "count": 4, "desc": "Targeted and effective."},
	{"name": "CHAMP's Agency", "cost": 3500, "tier": 5, "count": 3, "desc": "The best. Period."},
]

const TIER_NAMES: Array    = ["E", "D", "C", "B", "A", "S"]
const TIER_SKILL_MIN: Array = [10, 25, 40, 55, 70, 85]
const TIER_SKILL_MAX: Array = [25, 40, 55, 70, 85, 100]
const TIER_MOT_MIN: Array   = [10, 25, 40, 55, 70, 85]
const TIER_MOT_MAX: Array   = [30, 45, 60, 75, 90, 100]

const CHAMP_LINES: Array = [
	"Hey hey hey! CHAMP here! Leave the recruiting to the BEST. Stand by...",
	"You want the best? You came to the right place. CHAMP delivers. Always.",
	"CHAMP's Guarantee: If not satisfied... no refunds. But you WILL be satisfied.",
	"Top talent incoming. CHAMP has never failed a client. Today is no exception.",
]
const CHAMP_HERO_LINE: String = "Even I'm surprised by this one. Truly special. You're welcome."

# ─────────────────────────────────────────
#  NODE REFS
# ─────────────────────────────────────────
@onready var _cash_label:   Label         = $Dimmer/Card/VBox/CashLabel
@onready var _arrow_row:    HBoxContainer = $Dimmer/Card/VBox/ArrowRow
@onready var _desc_label:   Label         = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/DescLabel
@onready var _badge_label:  Label         = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/BadgeLabel
@onready var _stats_label:  Label         = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/StatsLabel
@onready var _cost_label:   Label         = $Dimmer/Card/VBox/DetailCard/Margin/DetailVBox/CostLabel
@onready var _status_label: Label         = $Dimmer/Card/VBox/StatusLabel
@onready var _champ_timer:  Timer         = $ChampTimer

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var _gm:            Node     = null
var _em:            GDScript = null
var _phase:         int      = PHASE_ADS
var _current_cands: Array    = []
var _hero_templates:Array    = []
var _selected_tier: int      = 0
var _hired_emps:    Array    = []

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	super._ready()
	set_title("RECRUIT")
	_em = load("res://EmployeeManager.gd") as GDScript
	_gm = get_node_or_null("/root/GameManager")
	if _gm != null:
		_gm.economy.cash_changed.connect(_on_cash_changed)
		_on_cash_changed(_gm.economy.current_cash)
	_champ_timer.timeout.connect(_on_champ_timer_timeout)
	_show_phase(PHASE_ADS)

# ─────────────────────────────────────────
#  PHASE MANAGEMENT
# ─────────────────────────────────────────
func _show_phase(phase: int) -> void:
	_phase = phase
	_status_label.text = ""
	_current_index = 0
	match phase:
		PHASE_ADS:
			set_title("RECRUIT")
			_arrow_row.visible  = true
			_page_label.visible = true
			_action_btn.visible = true
			set_items_count(AD_DATA.size())
		PHASE_CHAMP:
			set_title("CHAMP'S AGENCY")
			_arrow_row.visible  = false
			_page_label.visible = false
			_action_btn.visible = false
			var rng: RandomNumberGenerator = RandomNumberGenerator.new()
			rng.randomize()
			var line: String = CHAMP_HERO_LINE if not _hero_templates.is_empty() else CHAMP_LINES[rng.randi_range(0, CHAMP_LINES.size() - 1)]
			_item_name_label.text = ""
			_desc_label.text      = line
			_badge_label.text     = "CHAMP"
			_stats_label.text     = "..."
			_cost_label.text      = ""
			_champ_timer.start()
		PHASE_CANDS:
			set_title("TIER %s CANDIDATES" % TIER_NAMES[_selected_tier])
			_arrow_row.visible  = true
			_page_label.visible = true
			_action_btn.visible = true
			set_items_count(_current_cands.size())

# ─────────────────────────────────────────
#  DISPLAY (BaseModal override)
# ─────────────────────────────────────────
func _refresh_display() -> void:
	super._refresh_display()
	match _phase:
		PHASE_ADS:   _refresh_ad_display()
		PHASE_CANDS: _refresh_cand_display()

func _refresh_ad_display() -> void:
	var ad: Dictionary   = AD_DATA[_current_index]
	var cash: int        = 0
	if _gm != null:
		cash = _gm.economy.current_cash
	var can_afford: bool = cash >= int(ad.get("cost", 0))
	var tier: int        = int(ad.get("tier", 0))
	var is_champ: bool   = tier == 5
	_item_name_label.text = ad.get("name", "")
	_desc_label.text      = ad.get("desc", "")
	if is_champ:
		_badge_label.text = "TIER %s  GUARANTEED S-TIER" % TIER_NAMES[tier]
	else:
		_badge_label.text = "TIER %s" % TIER_NAMES[tier]
	_stats_label.text = "%d candidates" % int(ad.get("count", 0))
	_cost_label.text  = "$%d" % int(ad.get("cost", 0))
	_action_btn.disabled = not can_afford
	if can_afford:
		_action_btn.text = "SELECT"
		_action_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))
	else:
		_action_btn.text = "TOO POOR"
		_action_btn.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))

func _refresh_cand_display() -> void:
	if _current_cands.is_empty():
		_item_name_label.text = "No candidates"
		_desc_label.text      = ""
		_badge_label.text     = ""
		_stats_label.text     = ""
		_cost_label.text      = ""
		_action_btn.disabled  = true
		return
	var emp: Object    = _current_cands[_current_index]
	var is_hero: bool  = _is_hero_candidate(emp)
	var is_hired: bool = _hired_emps.has(emp)
	_item_name_label.text = emp.full_name()
	_desc_label.text      = _pers_str(int(emp.personality))
	var badges: Array[String] = [_role_str(int(emp.role))]
	if is_hero:
		badges.append("HERO")
	if is_hired:
		badges.append("HIRED")
	_badge_label.text = "  ".join(badges)
	_stats_label.text = "TEC %d   FOC %d   MGT %d" % [int(emp.technical), int(emp.focus), int(emp.management)]
	_cost_label.text  = "$%d / mo" % int(emp.monthly_salary)
	_action_btn.disabled = is_hired
	if is_hired:
		_action_btn.text = "HIRED"
		_action_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
	else:
		_action_btn.text = "HIRE"
		_action_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))

# ─────────────────────────────────────────
#  ACTIONS
# ─────────────────────────────────────────
func _on_action_pressed() -> void:
	match _phase:
		PHASE_ADS:
			_do_select_ad()
		PHASE_CHAMP:
			_show_phase(PHASE_CANDS)
		PHASE_CANDS:
			_do_hire()

func _do_select_ad() -> void:
	if _gm == null:
		return
	var ad: Dictionary = AD_DATA[_current_index]
	var cost: int      = int(ad.get("cost", 0))
	if not _gm.economy.spend(cost, "Recruitment Ad"):
		_status_label.text = "Not enough cash!"
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
		return
	_selected_tier = int(ad.get("tier", 0))
	_hero_templates.clear()
	_hired_emps.clear()
	var count: int = int(ad.get("count", 2))
	_current_cands = _generate_candidates(_selected_tier, count)
	if _selected_tier == 5:
		var heroes: Array = _gm.employees.get_available_heroes()
		for template in heroes:
			_hero_templates.append(template)
			var hero_emp: Object = _gm.employees.create_hero_employee(template)
			_current_cands.append(hero_emp)
		_show_phase(PHASE_CHAMP)
	else:
		_show_phase(PHASE_CANDS)

func _do_hire() -> void:
	if _gm == null or _current_cands.is_empty():
		return
	var emp: Object = _current_cands[_current_index]
	if _hired_emps.has(emp):
		return
	_gm.employees.hire(emp)
	_gm.broadcast("%s joined the team!" % emp.full_name())
	_hired_emps.append(emp)
	_refresh_cand_display()

# ─────────────────────────────────────────
#  SIGNAL HANDLERS
# ─────────────────────────────────────────
func _on_cash_changed(amount: int) -> void:
	_cash_label.text = "$%d" % amount
	if _phase == PHASE_ADS:
		_refresh_ad_display()

func _on_champ_timer_timeout() -> void:
	_stats_label.text   = ""
	_action_btn.visible = true

# ─────────────────────────────────────────
#  CANDIDATE GENERATION
# ─────────────────────────────────────────
func _generate_candidates(tier: int, count: int) -> Array:
	var result: Array = []
	var tier_name: String = TIER_NAMES[tier]
	for i: int in range(count):
		var emp: Employee = _em.generate_random_candidate()
		emp.generate_stats(tier_name, emp.role)
		emp.monthly_salary = (emp.technical + emp.management + emp.precision) / 60 * 30
		result.append(emp)
	return result

func _is_hero_candidate(emp: Object) -> bool:
	for template in _hero_templates:
		if template.get("id", "") == emp.id:
			return true
	return false

# ─────────────────────────────────────────
#  DISPLAY HELPERS
# ─────────────────────────────────────────
func _role_str(role: int) -> String:
	match role:
		0: return "OPS"
		1: return "PRO"
		2: return "SEC"
		3: return "MGT"
		4: return "FIN"
	return "???"

func _pers_str(p: int) -> String:
	match p:
		0: return "Normal"
		1: return "Workaholic"
		2: return "Lazy"
		3: return "Gossip"
		4: return "Perfectionist"
		5: return "Team Player"
		6: return "Lone Star"
	return "Unknown"
