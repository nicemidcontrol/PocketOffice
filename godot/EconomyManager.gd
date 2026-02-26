class_name EconomyManager
extends Node

# ─────────────────────────────────────────
#  SIGNALS
# ─────────────────────────────────────────
signal cash_changed(new_cash: int)
signal went_bankrupt

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
var current_cash: int     = 0
var total_earned: int     = 0
var total_spent: int      = 0
var active_loan_amount: int = 0
var loan_interest_rate: float = 0.05   # 5% monthly

var _ledger: Array[Dictionary] = []

# ─────────────────────────────────────────
#  INIT
# ─────────────────────────────────────────
func initialize(starting_cash: int) -> void:
	current_cash       = starting_cash
	total_earned       = starting_cash
	total_spent        = 0
	active_loan_amount = 0
	_ledger.clear()

# ─────────────────────────────────────────
#  INCOME
# ─────────────────────────────────────────
func add_revenue(amount: int, description: String) -> void:
	current_cash += amount
	total_earned  += amount
	_log_transaction(description, amount)
	cash_changed.emit(current_cash)

# ─────────────────────────────────────────
#  SPENDING
# ─────────────────────────────────────────
func spend(amount: int, description: String) -> bool:
	if current_cash < amount:
		push_warning("[Economy] Not enough cash to spend $%d for '%s'" % [amount, description])
		return false
	current_cash -= amount
	total_spent  += amount
	_log_transaction(description, -amount)
	cash_changed.emit(current_cash)
	return true

# ─────────────────────────────────────────
#  MONTHLY PROCESSING
# ─────────────────────────────────────────
func process_monthly_costs(total_salary: int, monthly_rent: int) -> void:
	var total_cost := total_salary + monthly_rent

	# Loan interest
	if active_loan_amount > 0:
		var interest := int(active_loan_amount * loan_interest_rate)
		total_cost        += interest
		active_loan_amount += interest
		_log_transaction("Loan Interest", -interest)

	current_cash -= total_cost
	total_spent  += total_cost
	_log_transaction("Monthly Costs (Salaries + Rent)", -total_cost)
	cash_changed.emit(current_cash)

	if current_cash < 0:
		went_bankrupt.emit()

# ─────────────────────────────────────────
#  LOANS
# ─────────────────────────────────────────
func take_loan(amount: int) -> bool:
	if active_loan_amount > 0:
		return false   # one loan at a time
	active_loan_amount = amount
	add_revenue(amount, "Business Loan")
	print("[Economy] Loan taken: $%d at %.0f%% monthly interest" % [amount, loan_interest_rate * 100])
	return true

func repay_loan(amount: int) -> bool:
	if active_loan_amount <= 0 or current_cash < amount:
		return false
	var repay := mini(amount, active_loan_amount)
	spend(repay, "Loan Repayment")
	active_loan_amount -= repay
	return true

# ─────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────
func _log_transaction(description: String, amount: int) -> void:
	var gm: GameManager = get_node_or_null("/root/GameManager")
	_ledger.append({
		"description": description,
		"amount":      amount,
		"month":       gm.company_data.current_month if gm else 0,
		"year":        gm.company_data.current_year  if gm else 0,
	})

func get_ledger() -> Array[Dictionary]:
	return _ledger.duplicate()

# ─────────────────────────────────────────
#  SAVE / LOAD
# ─────────────────────────────────────────
func to_save_dict() -> Dictionary:
	return {
		"current_cash":       current_cash,
		"total_earned":       total_earned,
		"total_spent":        total_spent,
		"active_loan_amount": active_loan_amount,
	}

func from_save_dict(d: Dictionary) -> void:
	current_cash       = d.get("current_cash", 10000)
	total_earned       = d.get("total_earned", 10000)
	total_spent        = d.get("total_spent", 0)
	active_loan_amount = d.get("active_loan_amount", 0)
