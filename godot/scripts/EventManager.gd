extends Node

# ------------------------------------------
#  SIGNALS
# ------------------------------------------
signal event_fired(event: Dictionary)

# ------------------------------------------
#  CONFIG
# ------------------------------------------
const _FIRE_CHANCE_LOW:  float = 0.30   # months 6-12
const _FIRE_CHANCE_MID:  float = 0.60   # months 13-24
const _FIRE_CHANCE_FULL: float = 1.00   # months 25+
const _MIN_MONTHS:       int   = 6      # no events before this

# ------------------------------------------
#  STATE
# ------------------------------------------
var _active: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# ------------------------------------------
#  EVENT POOL  (12 hardcoded events)
# ------------------------------------------
const _EVENTS: Array = [
	{
		"id": "printer_broken",
		"title": "The Printer is Broken!",
		"description": "30 minutes before a deadline, the office printer breaks down.",
		"choices": [
			{
				"text": "Fix it yourself",
				"preview": "-$200  MOT +5",
				"effects": [
					{"type": "cash", "value": -200},
					{"type": "motivation_all", "value": 5}
				]
			},
			{
				"text": "Send to repair shop",
				"preview": "-$500",
				"effects": [
					{"type": "cash", "value": -500}
				]
			},
			{
				"text": "Print at nearby shop",
				"preview": "-$100  REP -2",
				"effects": [
					{"type": "cash", "value": -100},
					{"type": "reputation", "value": -2}
				]
			}
		]
	},
	{
		"id": "fish_microwave",
		"title": "Someone Left Fish in the Microwave",
		"description": "The entire office smells. Productivity is suffering.",
		"requires": "facility:microwave",
		"choices": [
			{
				"text": "Send a passive-aggressive office email",
				"preview": "MOT -3",
				"effects": [
					{"type": "motivation_all", "value": -3}
				]
			},
			{
				"text": "Buy air fresheners",
				"preview": "-$50  MOT +5",
				"effects": [
					{"type": "cash", "value": -50},
					{"type": "motivation_all", "value": 5}
				]
			},
			{
				"text": "Ignore it",
				"preview": "MOT -8",
				"effects": [
					{"type": "motivation_all", "value": -8}
				]
			}
		]
	},
	{
		"id": "birthday_cake",
		"title": "Birthday Cake in the Kitchen!",
		"description": "It's someone's birthday. Everyone is distracted for 30 minutes.",
		"choices": [
			{
				"text": "Let everyone celebrate",
				"preview": "MOT +10",
				"effects": [
					{"type": "motivation_all", "value": 10}
				]
			},
			{
				"text": "Keep it brief",
				"preview": "MOT +3",
				"effects": [
					{"type": "motivation_all", "value": 3}
				]
			}
		]
	},
	{
		"id": "ac_broken",
		"title": "The Air Conditioning Broke",
		"description": "It is 35 degrees in the office. No one can focus.",
		"choices": [
			{
				"text": "Call repair immediately",
				"preview": "-$800",
				"effects": [
					{"type": "cash", "value": -800}
				]
			},
			{
				"text": "Buy portable fans",
				"preview": "-$200  MOT -5",
				"effects": [
					{"type": "cash", "value": -200},
					{"type": "motivation_all", "value": -5}
				]
			},
			{
				"text": "Send everyone home early",
				"preview": "MOT +8",
				"effects": [
					{"type": "motivation_all", "value": 8}
				]
			}
		]
	},
	{
		"id": "competitor_poach",
		"title": "Competitor is Poaching Your Staff!",
		"description": "A competitor offered one of your best employees a higher salary.",
		"choices": [
			{
				"text": "Counter offer +20% salary",
				"preview": "-$500",
				"effects": [
					{"type": "cash", "value": -500}
				]
			},
			{
				"text": "Let them go",
				"preview": "Lose 1 employee",
				"effects": [
					{"type": "lose_employee", "value": 0}
				]
			},
			{
				"text": "Appeal to loyalty",
				"preview": "MOT -15",
				"effects": [
					{"type": "motivation_employee", "value": -15}
				]
			}
		]
	},
	{
		"id": "investor_visit",
		"title": "Investor Wants to Visit the Office",
		"description": "An important investor is coming tomorrow. The office needs to look presentable.",
		"choices": [
			{
				"text": "Deep clean and prepare",
				"preview": "-$300  REP +10",
				"effects": [
					{"type": "cash", "value": -300},
					{"type": "reputation", "value": 10}
				]
			},
			{
				"text": "Wing it",
				"preview": "REP +3 or -5",
				"effects": [
					{"type": "reputation_random", "value": 0, "value_a": 3, "value_b": -5}
				]
			}
		]
	},
	{
		"id": "new_management",
		"title": "New Management Wants to Revolutionize Everything",
		"description": "Leadership sent a memo: all workflows must be redesigned by end of month.",
		"choices": [
			{
				"text": "Comply enthusiastically",
				"preview": "MOT -5  REP +5",
				"effects": [
					{"type": "motivation_all", "value": -5},
					{"type": "reputation", "value": 5}
				]
			},
			{
				"text": "Push back diplomatically",
				"preview": "MOT +3",
				"effects": [
					{"type": "motivation_all", "value": 3}
				]
			},
			{
				"text": "Ignore the memo",
				"preview": "REP -8",
				"effects": [
					{"type": "reputation", "value": -8}
				]
			}
		]
	},
	{
		"id": "hr_complaint",
		"title": "An HR Complaint Was Filed",
		"description": "Someone filed a complaint about a coworker. HR needs to investigate.",
		"choices": [
			{
				"text": "Investigate properly",
				"preview": "-$200  MOT -3",
				"effects": [
					{"type": "cash", "value": -200},
					{"type": "motivation_all", "value": -3}
				]
			},
			{
				"text": "Mediate directly",
				"preview": "MOT +2",
				"effects": [
					{"type": "motivation_all", "value": 2}
				]
			}
		]
	},
	{
		"id": "wfh_request",
		"title": "Employee Wants to Work From Home Permanently",
		"description": "One of your team members requests full remote work.",
		"choices": [
			{
				"text": "Approve full remote",
				"preview": "MOT +15",
				"effects": [
					{"type": "motivation_employee", "value": 15}
				]
			},
			{
				"text": "Hybrid 3 days office",
				"preview": "MOT +5",
				"effects": [
					{"type": "motivation_employee", "value": 5}
				]
			},
			{
				"text": "Decline",
				"preview": "MOT -20",
				"effects": [
					{"type": "motivation_employee", "value": -20}
				]
			}
		]
	},
	{
		"id": "press_feature",
		"title": "Press Wants to Feature Your Company",
		"description": "A journalist wants to write about your company. But the office is a mess.",
		"choices": [
			{
				"text": "Agree and clean up fast",
				"preview": "-$400  REP +20",
				"effects": [
					{"type": "cash", "value": -400},
					{"type": "reputation", "value": 20}
				]
			},
			{
				"text": "Decline politely",
				"preview": "No effect",
				"effects": []
			},
			{
				"text": "Agree without cleaning",
				"preview": "REP +5 or -10",
				"effects": [
					{"type": "reputation_random", "value": 0, "value_a": 5, "value_b": -10}
				]
			}
		]
	},
	{
		"id": "team_building",
		"title": "Mandatory Fun Team Building Event",
		"description": "HR scheduled a team building day during your busiest week.",
		"choices": [
			{
				"text": "Participate fully",
				"preview": "MOT +12",
				"effects": [
					{"type": "motivation_all", "value": 12}
				]
			},
			{
				"text": "Make it optional",
				"preview": "MOT +5",
				"effects": [
					{"type": "motivation_all", "value": 5}
				]
			},
			{
				"text": "Cancel it",
				"preview": "MOT -8  REP -3",
				"effects": [
					{"type": "motivation_all", "value": -8},
					{"type": "reputation", "value": -3}
				]
			}
		]
	},
	{
		"id": "perfume_complaint",
		"title": "Unbearable Perfume Alert",
		"description": "A colleague is wearing an overwhelming amount of perfume. Complaints are flooding in.",
		"choices": [
			{
				"text": "Address it privately",
				"preview": "MOT +3",
				"effects": [
					{"type": "motivation_all", "value": 3}
				]
			},
			{
				"text": "Send anonymous note",
				"preview": "MOT -2",
				"effects": [
					{"type": "motivation_all", "value": -2}
				]
			},
			{
				"text": "Ignore it",
				"preview": "MOT -5",
				"effects": [
					{"type": "motivation_all", "value": -5}
				]
			}
		]
	}
]

# ------------------------------------------
#  LIFECYCLE
# ------------------------------------------
func _ready() -> void:
	_rng.randomize()
	var cm: Node = get_node_or_null("/root/ClockManager")
	if cm != null:
		cm.work_day_started.connect(_on_work_day_started)

# ------------------------------------------
#  DAILY ROLL
# ------------------------------------------
func _on_work_day_started() -> void:
	if _active:
		return
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		return

	# 1. Month gate — no events before month 6
	var total_months: int = _get_total_months(gm)
	if total_months < _MIN_MONTHS:
		return

	# 2. Gradual ramp-up chance
	var fire_chance: float = _get_fire_chance(total_months)
	if _rng.randf() >= fire_chance:
		return

	# 3. Filter events by requires conditions, then pick one
	var fm: Node = get_node_or_null("/root/FacilityManager")
	var eligible: Array = []
	for ev in _EVENTS:
		if _check_requires(ev, gm, fm, total_months):
			eligible.append(ev)
	if eligible.is_empty():
		return

	_active = true
	event_fired.emit(eligible[_rng.randi_range(0, eligible.size() - 1)])

# ------------------------------------------
#  TIMING HELPERS
# ------------------------------------------
func _get_total_months(gm: Node) -> int:
	var year: int  = gm.game_year
	var month: int = gm.company_data.get("current_month", 1)
	return (year - 1) * 12 + month

func _get_fire_chance(total_months: int) -> float:
	if total_months >= 25:
		return _FIRE_CHANCE_FULL
	elif total_months >= 13:
		return _FIRE_CHANCE_MID
	return _FIRE_CHANCE_LOW

# ------------------------------------------
#  CONDITION CHECK
# ------------------------------------------
# Parses the optional "requires" string on an event dict.
# Formats: "facility:<id>"  |  "month_min:<n>"  |  "employees_min:<n>"
func _check_requires(ev: Dictionary, gm: Node, fm: Node, total_months: int) -> bool:
	var req: String = ev.get("requires", "")
	if req == "":
		return true
	var parts: PackedStringArray = req.split(":")
	if parts.size() < 2:
		return true
	var cond_type: String = parts[0]
	var cond_val: String  = parts[1]
	match cond_type:
		"facility":
			if fm == null:
				return false
			for f in fm.facilities:
				if f.get("id", "") == cond_val and f.get("placed", false):
					return true
			return false
		"month_min":
			return total_months >= int(cond_val)
		"employees_min":
			return gm.employees.get_hired_employees().size() >= int(cond_val)
	return true

# ------------------------------------------
#  RESOLVE  (called by EventPopup after player picks a choice)
# ------------------------------------------
func resolve(choice: Dictionary) -> void:
	_active = false
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		return
	var effects: Array = choice.get("effects", [])
	for effect in effects:
		_apply_effect(effect, gm)

func _apply_effect(effect: Dictionary, gm: Node) -> void:
	var t: String = effect.get("type", "")
	var v: int = effect.get("value", 0)
	match t:
		"cash":
			if v >= 0:
				gm.economy.add_revenue(v, "Event")
			else:
				gm.economy.spend(-v, "Event")
		"motivation_all":
			for emp in gm.employees.get_hired_employees():
				emp.adjust_morale(v)
		"motivation_employee":
			var hired: Array = gm.employees.get_hired_employees()
			if not hired.is_empty():
				hired[_rng.randi_range(0, hired.size() - 1)].adjust_morale(v)
		"reputation":
			var rep: int = gm.company_data.get("reputation", 0)
			gm.company_data["reputation"] = clampi(rep + v, 0, 1000)
		"reputation_random":
			var rnd_val: int = effect.get("value_a", 0) if _rng.randf() > 0.5 else effect.get("value_b", 0)
			var rep: int = gm.company_data.get("reputation", 0)
			gm.company_data["reputation"] = clampi(rep + rnd_val, 0, 1000)
		"lose_employee":
			var hired: Array = gm.employees.get_hired_employees()
			if not hired.is_empty():
				gm.employees.fire(hired[_rng.randi_range(0, hired.size() - 1)])
