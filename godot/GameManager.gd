## GameManager.gd
## Register this as an Autoload singleton in Project Settings:
##   Project > Project Settings > Autoload > Add > GameManager.gd > Name: GameManager
##
## This is the single source of truth for all game state.
## All sub-managers are child nodes added in _ready().

extends Node

# ─────────────────────────────────────────
#  ENUMS
# ─────────────────────────────────────────
enum CompanyTier { STARTUP, SME, ENTERPRISE, GLOBAL_CORP }

# ─────────────────────────────────────────
#  SIGNALS  (replaces C# static events)
# ─────────────────────────────────────────
signal tick_passed(tick: int)
signal month_passed(month: int)
signal year_passed(year: int)
signal tier_upgraded(new_tier: CompanyTier)
signal game_message(message: String)
signal corp_points_changed(new_value: int)
signal evaluation_ready(year: int, results: Array)
signal game_over(final_rank: int)
signal fever_mode_started
signal fever_mode_ended

# ─────────────────────────────────────────
#  SUB-MANAGERS  (child nodes)
# ─────────────────────────────────────────
var employees: Node
var economy:   Node
var projects:  Node
var events:    Node
var office:    Node

# ─────────────────────────────────────────
#  COMPANY STATE
# ─────────────────────────────────────────
var company_data := {
	"company_name":                "My Startup Inc.",
	"reputation":                  10,
	"tier":                        CompanyTier.STARTUP,
	"current_year":                2024,
	"current_month":               1,
	"current_tick":                0,
	"unlocked_departments":        ["General"],
	"discovered_training_combos":  [],
	"discovered_facility_combos":  [],
}

# ─────────────────────────────────────────
#  TIME
# ─────────────────────────────────────────
@export var tick_duration_seconds: float = 10.0
var _tick_timer: float = 0.0
var is_paused: bool  = false
var corp_points: int = 0

var game_year:               int   = 1
var last_evaluation_year:    int   = 0
var last_evaluation_results: Array = []

var is_fever_mode: bool        = false
var _fever_timer: float        = 0.0
var _fever_duration: float     = 60.0
var _fever_cooldown_month: int = -1

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	_init_sub_managers()
	if SaveSystem.save_exists():
		load_game()
	else:
		new_game("My Startup Inc.")
	var _clock: Node = get_node_or_null("/root/ClockManager")
	if _clock != null:
		_clock.month_changed.connect(_on_clock_month_changed)

func _process(delta: float) -> void:
	if is_paused:
		return
	_tick_timer += delta
	if _tick_timer >= tick_duration_seconds:
		_tick_timer = 0.0
		_advance_tick()
	if is_fever_mode:
		_fever_timer -= delta
		if _fever_timer <= 0.0:
			_end_fever_mode()

# ─────────────────────────────────────────
#  SUB-MANAGER SETUP
# ─────────────────────────────────────────
func _init_sub_managers() -> void:
	employees = load("res://EmployeeManager.gd").new()
	economy   = load("res://EconomyManager.gd").new()
	projects  = load("res://ProjectManager.gd").new()
	events    = load("res://EventManager.gd").new()
	office    = load("res://OfficeManager.gd").new()

	for manager in [employees, economy, projects, events, office]:
		add_child(manager)

	# Connect event popup to UI (UI listens to this signal)
	events.event_triggered.connect(_on_event_triggered)
	economy.went_bankrupt.connect(_on_bankrupt)
	employees.employee_burnout.connect(_on_employee_burnout)

# ─────────────────────────────────────────
#  NEW GAME
# ─────────────────────────────────────────
func new_game(company_name: String) -> void:
	company_data = {
		"company_name":                company_name,
		"reputation":                  10,
		"tier":                        CompanyTier.STARTUP,
		"current_year":                2024,
		"current_month":               1,
		"current_tick":                0,
		"unlocked_departments":        ["General"],
		"discovered_training_combos":  [],
		"discovered_facility_combos":  [],
	}
	economy.initialize(10000)
	projects.initialize()
	events.initialize()
	office.initialize()
	employees.hire_starting_team()

	broadcast("Welcome to %s! Let's build something great. 🚀" % company_name)

# ─────────────────────────────────────────
#  TIME PROGRESSION
# ─────────────────────────────────────────
func _advance_tick() -> void:
	company_data["current_tick"] += 1
	tick_passed.emit(company_data["current_tick"])

	employees.tick_motivation()
	events.try_trigger_random_event()

	if company_data["current_tick"] > 8:
		company_data["current_tick"] = 0
		_advance_month()
	_check_fever_trigger()

func _advance_month() -> void:
	company_data["current_month"] += 1
	month_passed.emit(company_data["current_month"])

	projects.generate_new_projects(2)

	if company_data["current_month"] > 12:
		company_data["current_month"] = 1
		_advance_year()

	_check_tier_upgrade()
	save_game()  # Auto-save every month

func _advance_year() -> void:
	company_data["current_year"] += 1
	year_passed.emit(company_data["current_year"])

	var score := _calculate_annual_score()
	company_data["reputation"] = mini(1000, company_data["reputation"] + roundi(score / 10.0))
	broadcast("📊 Annual Review: Score %d/100 — Year %d" % [score, company_data["current_year"]])

# ─────────────────────────────────────────
#  TIER UPGRADE
# ─────────────────────────────────────────
func _check_tier_upgrade() -> void:
	var current_tier: int = company_data["tier"]
	var new_tier := current_tier
	var emp_count: int = employees.hired_count()
	var earned: int    = economy.total_earned
	var rep: int       = company_data["reputation"]

	if emp_count >= 51 and earned >= 1_000_000 and rep >= 500:
		new_tier = CompanyTier.GLOBAL_CORP
	elif emp_count >= 21 and earned >= 200_000 and rep >= 200:
		new_tier = CompanyTier.ENTERPRISE
	elif emp_count >= 6 and earned >= 30_000 and rep >= 50:
		new_tier = CompanyTier.SME

	if new_tier != current_tier:
		company_data["tier"] = new_tier
		var tier_names := ["Startup","SME","Enterprise","Global Corp"]
		tier_upgraded.emit(new_tier as CompanyTier)
		broadcast("🎉 Congratulations! You've reached %s!" % tier_names[new_tier])

# ─────────────────────────────────────────
#  SCORING
# ─────────────────────────────────────────
func _calculate_annual_score() -> int:
	var rep_score      := minf(company_data["reputation"] / 10.0, 30.0)
	var finance_score  := minf(economy.current_cash / 10000.0, 40.0)
	var employee_score := minf(employees.average_morale() / 100.0 * 30.0, 30.0)
	return roundi(rep_score + finance_score + employee_score)

func _build_evaluation_results() -> Array:
	var dm: Node = get_node_or_null("/root/DonorManager")
	var cm: Node = get_node_or_null("/root/CompetitorManager")

	var won_count: int    = 0
	if dm != null:
		won_count = dm.won_donors.size()
	var reputation: int   = int(company_data.get("reputation", 0))
	var total_earned: int = economy.total_earned

	var p_donors_score:  float = clampf(float(won_count) / 5.0 * 100.0, 0.0, 100.0)
	var p_revenue_score: float = clampf(float(total_earned) / 500000.0 * 100.0, 0.0, 100.0)
	var p_rep_score:     float = clampf(float(reputation) / 200.0 * 100.0, 0.0, 100.0)
	var p_total:         float = (p_donors_score + p_revenue_score + p_rep_score) / 3.0

	var results: Array = []
	results.append({
		"name":          str(company_data.get("company_name", "Your Company")),
		"is_player":     true,
		"donors_score":  p_donors_score,
		"revenue_score": p_revenue_score,
		"rep_score":     p_rep_score,
		"total":         p_total,
	})

	if cm != null:
		for comp in cm.competitors:
			var c_donors:  float = float(comp["donors"])
			var c_revenue: float = float(comp["revenue"])
			var c_rep:     float = float(comp["reputation"])
			var c_donors_score:  float = clampf(floorf(c_donors) / 5.0 * 100.0, 0.0, 100.0)
			var c_revenue_score: float = clampf(c_revenue / 500000.0 * 100.0, 0.0, 100.0)
			var c_rep_score:     float = clampf(c_rep / 200.0 * 100.0, 0.0, 100.0)
			var c_total:         float = (c_donors_score + c_revenue_score + c_rep_score) / 3.0
			results.append({
				"name":          str(comp["name"]),
				"is_player":     false,
				"donors_score":  c_donors_score,
				"revenue_score": c_revenue_score,
				"rep_score":     c_rep_score,
				"total":         c_total,
			})

	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["total"]) > float(b["total"])
	)
	for i in range(results.size()):
		results[i]["rank"] = i + 1

	return results

# ─────────────────────────────────────────
#  FEVER MODE
# ─────────────────────────────────────────
func _check_fever_trigger() -> void:
	if is_fever_mode:
		return
	var current_month: int = company_data.get("current_month", 1)
	if current_month == _fever_cooldown_month:
		return
	var avg_mot: float = employees.average_morale()
	if avg_mot >= 100.0:
		_start_fever_mode()

func _start_fever_mode() -> void:
	is_fever_mode = true
	_fever_timer = _fever_duration
	var current_month: int = company_data.get("current_month", 1)
	_fever_cooldown_month = current_month
	fever_mode_started.emit()
	broadcast("FEVER MODE! All stats doubled for 60 seconds!")

func _end_fever_mode() -> void:
	is_fever_mode = false
	_fever_timer = 0.0
	for emp in employees.get_hired_employees():
		emp.morale = 50
	fever_mode_ended.emit()
	broadcast("Fever Mode ended. Time to recharge.")

# ─────────────────────────────────────────
#  GAME CONTROLS
# ─────────────────────────────────────────
func add_corp_points(amount: int) -> void:
	corp_points += amount
	corp_points_changed.emit(corp_points)

func toggle_pause() -> void:
	is_paused = !is_paused

func set_speed(multiplier: float) -> void:
	tick_duration_seconds = 10.0 / clampf(multiplier, 0.5, 4.0)

func get_current_date_string() -> String:
	return "Month %d, Year %d" % [company_data["current_month"], company_data["current_year"]]

# ─────────────────────────────────────────
#  BROADCAST
# ─────────────────────────────────────────
func broadcast(message: String) -> void:
	game_message.emit(message)
	print("[Game] %s" % message)

# ─────────────────────────────────────────
#  EVENT HANDLERS
# ─────────────────────────────────────────
func _on_event_triggered(event_data: Dictionary) -> void:
	# UI should connect to events.event_triggered and show a popup
	# For now just log it
	print("[GameManager] Event triggered: %s" % event_data["title"])

func _on_bankrupt() -> void:
	broadcast("BANKRUPT! Game Over.")
	is_paused = true

func _on_employee_burnout(emp_name: String) -> void:
	broadcast("[WARNING] %s has burned out! Reduce their workload." % emp_name)

# ─────────────────────────────────────────
#  SAVE / LOAD
# ─────────────────────────────────────────
func save_game() -> void:
	var data := {
		"company_data":        company_data,
		"employees":           employees.to_save_array(),
		"economy":             economy.to_save_dict(),
		"active_projects":     projects.to_save_array(),
		"office":              office.to_save_dict(),
		"is_fever_mode":       is_fever_mode,
		"fever_cooldown_month": _fever_cooldown_month,
	}
	SaveSystem.save(data)

func load_game() -> void:
	var data: Dictionary = SaveSystem.load_save()
	if data.is_empty():
		return

	company_data = data.get("company_data", company_data)
	# Backfill keys missing from old saves so direct access never crashes
	if not company_data.has("current_tick"):
		company_data["current_tick"] = 0
	if not company_data.has("current_month"):
		company_data["current_month"] = 1
	if not company_data.has("current_year"):
		company_data["current_year"] = 2024
	economy.from_save_dict(data.get("economy", {}))
	employees.load_employees(data.get("employees", []))
	projects.load_projects(data.get("active_projects", []))
	office.from_save_dict(data.get("office", {}))
	events.initialize()
	is_fever_mode         = data.get("is_fever_mode", false)
	_fever_cooldown_month = data.get("fever_cooldown_month", -1)
	broadcast("Game loaded! Welcome back to %s." % company_data["company_name"])

# ─────────────────────────────────────────
#  CLOCK HANDLERS
# ─────────────────────────────────────────
# ─────────────────────────────────────────
#  UTILITY
# ─────────────────────────────────────────
func format_cash(amount: int) -> String:
	var negative: bool = amount < 0
	var abs_val: int = abs(amount)
	var prefix: String = "-" if negative else ""
	if abs_val >= 10000000:
		return "$%s%dM" % [prefix, abs_val / 1000000]
	elif abs_val >= 1000000:
		return "$%s%.1fM" % [prefix, abs_val / 1000000.0]
	else:
		var s: String = str(abs_val)
		var result: String = ""
		var count: int = 0
		for i in range(s.length() - 1, -1, -1):
			if count > 0 and count % 3 == 0:
				result = "," + result
			result = s[i] + result
			count += 1
		return "$%s%s" % [prefix, result]

# ─────────────────────────────────────────
#  CLOCK HANDLERS
# ─────────────────────────────────────────
func _on_clock_month_changed(_month: int, _year: int) -> void:
	var total_salary: int = employees.get_total_monthly_salary()
	var monthly_rent: int = office.get_monthly_rent()
	print("[ECON] Monthly: salary=$%d rent=$%d total=$%d" % [total_salary, monthly_rent, total_salary + monthly_rent])
	economy.process_monthly_costs(total_salary, monthly_rent)

	var dm: Node = get_node_or_null("/root/DonorManager")
	if dm != null:
		var donor_income: int = dm.get_monthly_total()
		if donor_income > 0:
			economy.add_revenue(donor_income, "Donor Monthly Funding")
			broadcast("Donor funding received: $%d" % donor_income)

	if _month == 12:
		var tier: int        = int(company_data.get("tier", CompanyTier.STARTUP))
		var hq_funding: int  = 0
		match tier:
			CompanyTier.STARTUP:     hq_funding = 10000
			CompanyTier.SME:         hq_funding = 25000
			CompanyTier.ENTERPRISE:  hq_funding = 50000
			CompanyTier.GLOBAL_CORP: hq_funding = 100000
		if hq_funding > 0:
			economy.add_revenue(hq_funding, "Annual HQ Funding")
			broadcast("Annual HQ funding received: $%d!" % hq_funding)

		var results: Array = _build_evaluation_results()
		last_evaluation_results = results
		last_evaluation_year    = game_year
		evaluation_ready.emit(game_year, results)

		var player_rank: int = 1
		for entry in results:
			if bool(entry.get("is_player", false)):
				player_rank = int(entry.get("rank", 1))
				break
		if game_year >= 5:
			game_over.emit(player_rank)

		game_year += 1
