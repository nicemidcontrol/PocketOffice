extends Node

# StaminaManager — tracks employee SP (stamina points) for phase work.
# Design values locked per GAME_BIBLE_v1.5.2:
#   - working a phase costs 3 SP
#   - +1 SP recovery per in-game week, capped at sp_max
#   - an employee is eligible to work a phase at >= 3 SP

signal sp_changed(employee_id: String, new_sp: int)

const PHASE_SP_COST: int = 3
const WEEKLY_SP_RECOVERY: int = 1
const ELIGIBILITY_MIN_SP: int = 3

func is_eligible(emp: Employee) -> bool:
	if emp == null:
		return false
	return emp.sp_current >= ELIGIBILITY_MIN_SP

func spend_phase(emp: Employee) -> bool:
	if not is_eligible(emp):
		return false
	emp.sp_current = maxi(emp.sp_current - PHASE_SP_COST, 0)
	sp_changed.emit(str(emp.id), emp.sp_current)
	return true

# Call once per in-game week. With no argument it recovers all hired
# employees; an explicit array can be passed for targeted use or tests.
func weekly_recovery(target_employees: Array = []) -> void:
	var emps: Array = target_employees
	if emps.is_empty():
		var gm: Node = get_node_or_null("/root/GameManager")
		if gm == null or gm.employees == null:
			return
		emps = gm.employees.get_hired_employees()
	for emp in emps:
		if emp == null:
			continue
		if emp.sp_current < emp.sp_max:
			emp.sp_current = mini(emp.sp_current + WEEKLY_SP_RECOVERY, emp.sp_max)
			sp_changed.emit(str(emp.id), emp.sp_current)
