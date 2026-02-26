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
signal day_passed(day: int)
signal month_passed(month: int)
signal year_passed(year: int)
signal tier_upgraded(new_tier: CompanyTier)
signal game_message(message: String)

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
	"company_name":          "My Startup Inc.",
	"reputation":            10,
	"tier":                  CompanyTier.STARTUP,
	"current_year":          2024,
	"current_month":         1,
	"current_day":           1,
	"unlocked_departments":  ["General"],
}

# ─────────────────────────────────────────
#  TIME
# ─────────────────────────────────────────
@export var day_duration_seconds: float = 10.0
var _day_timer: float = 0.0
var is_paused: bool = false

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────
func _ready() -> void:
	_init_sub_managers()
	if SaveSystem.save_exists():
		load_game()
	else:
		new_game("My Startup Inc.")

func _process(delta: float) -> void:
	if is_paused:
		return
	_day_timer += delta
	if _day_timer >= day_duration_seconds:
		_day_timer = 0.0
		_advance_day()

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

# ─────────────────────────────────────────
#  NEW GAME
# ─────────────────────────────────────────
func new_game(company_name: String) -> void:
	company_data = {
		"company_name":         company_name,
		"reputation":           10,
		"tier":                 CompanyTier.STARTUP,
		"current_year":         2024,
		"current_month":        1,
		"current_day":          1,
		"unlocked_departments": ["General"],
	}
	economy.initialize(10000)
	projects.initialize()
	events.initialize()
	office.initialize()

	broadcast("Welcome to %s! Let's build something great. 🚀" % company_name)

# ─────────────────────────────────────────
#  TIME PROGRESSION
# ─────────────────────────────────────────
func _advance_day() -> void:
	company_data["current_day"] += 1
	day_passed.emit(company_data["current_day"])

	employees.tick_motivation()
	projects.tick_projects(self)
	events.try_trigger_random_event()

	if company_data["current_day"] > 30:
		company_data["current_day"] = 1
		_advance_month()

func _advance_month() -> void:
	company_data["current_month"] += 1
	month_passed.emit(company_data["current_month"])

	economy.process_monthly_costs(
		employees.get_total_monthly_salary(),
		office.get_monthly_rent()
	)
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
	company_data["reputation"] = mini(1000, company_data["reputation"] + score / 10)
	broadcast("📊 Annual Review: Score %d/100 — Year %d" % [score, company_data["current_year"]])

# ─────────────────────────────────────────
#  TIER UPGRADE
# ─────────────────────────────────────────
func _check_tier_upgrade() -> void:
	var current_tier: int = company_data["tier"]
	var new_tier := current_tier
	var emp_count := employees.hired_count()
	var earned    := economy.total_earned
	var rep       := company_data["reputation"]

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
	var employee_score := minf(employees.average_motivation() / 100.0 * 30.0, 30.0)
	return roundi(rep_score + finance_score + employee_score)

# ─────────────────────────────────────────
#  GAME CONTROLS
# ─────────────────────────────────────────
func toggle_pause() -> void:
	is_paused = !is_paused

func set_speed(multiplier: float) -> void:
	day_duration_seconds = 10.0 / clampf(multiplier, 0.5, 4.0)

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
	broadcast("💀 BANKRUPT! Game Over.")
	is_paused = true

# ─────────────────────────────────────────
#  SAVE / LOAD
# ─────────────────────────────────────────
func save_game() -> void:
	var data := {
		"company_data":   company_data,
		"employees":      employees.to_save_array(),
		"economy":        economy.to_save_dict(),
		"active_projects":projects.to_save_array(),
		"office":         office.to_save_dict(),
	}
	SaveSystem.save(data)

func load_game() -> void:
	var data := SaveSystem.load_save()
	if data.is_empty():
		return

	company_data = data.get("company_data", company_data)
	economy.from_save_dict(data.get("economy", {}))
	employees.load_employees(data.get("employees", []))
	projects.load_projects(data.get("active_projects", []))
	office.from_save_dict(data.get("office", {}))
	events.initialize()
	broadcast("Game loaded! Welcome back to %s." % company_data["company_name"])
