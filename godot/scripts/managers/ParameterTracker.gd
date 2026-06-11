extends Node

# ParameterTracker — pure parameter math and reward-tier constants for the
# v1.5.2 phase system. Stateless: no UI, no writes into ProjectManager data.
# Phase execution arrives with PhaseManager (PR-10).
# Design values locked per GAME_BIBLE_v1.5.2.

# Stat pair summed for each parameter.
const PARAMETER_STATS: Dictionary = {
	"PLANNING":  ["management", "focus"],
	"EXECUTION": ["technical", "precision"],
	"LOGISTICS": ["procurement", "logistics"],
	"COMMUNITY": ["charm", "communication"],
}

# Primary role per parameter. v1.5.2 role names map onto the existing
# Employee.Role enum: Project Manager = MANAGEMENT, Field Officer =
# OPERATIONS, Supply Officer = PROCUREMENT. COMMUNITY has no primary
# role — anyone works it, gated by Charm instead.
const PARAMETER_PRIMARY_ROLE: Dictionary = {
	"PLANNING":  Employee.Role.MANAGEMENT,
	"EXECUTION": Employee.Role.OPERATIONS,
	"LOGISTICS": Employee.Role.PROCUREMENT,
}

# Contribution multiplier for a non-primary role on EXECUTION/LOGISTICS,
# and for a low-Charm employee on COMMUNITY.
const OFF_ROLE_EFFICIENCY: float = 0.7
# Working assumption per GAME_BIBLE_v1.5.2 ("to be playtested") — tunable.
const SPECIALTY_BONUS: float = 1.2
# COMMUNITY contributes at full rate from this Charm value upward — tunable.
const COMMUNITY_CHARM_THRESHOLD: int = 40
# Lower bounds of reward Tiers 2-5 on project_total; below 200 is Tier 1.
const TIER_THRESHOLDS: Array[int] = [200, 500, 1200, 2500]

func is_eligible_for_parameter(emp: Employee, parameter: String) -> bool:
	if emp == null:
		return false
	if not PARAMETER_STATS.has(parameter):
		return false
	if parameter == "PLANNING":
		# Hard gate: PLANNING can only be worked by a Project Manager.
		return int(emp.role) == int(PARAMETER_PRIMARY_ROLE.get("PLANNING", -1))
	return true

func base_contribution(emp: Employee, parameter: String) -> int:
	if not is_eligible_for_parameter(emp, parameter):
		return 0
	var stat_names: Array = PARAMETER_STATS.get(parameter, [])
	var stat_sum: int = 0
	for stat_name in stat_names:
		stat_sum += int(emp.get(str(stat_name)))
	var modifier: float = 1.0
	match parameter:
		"PLANNING":
			# Eligibility already guarantees a PM — always a specialty match.
			modifier = SPECIALTY_BONUS
		"EXECUTION", "LOGISTICS":
			if int(emp.role) == int(PARAMETER_PRIMARY_ROLE.get(parameter, -1)):
				modifier = SPECIALTY_BONUS
			else:
				modifier = OFF_ROLE_EFFICIENCY
		"COMMUNITY":
			if int(emp.charm) >= COMMUNITY_CHARM_THRESHOLD:
				modifier = 1.0
			else:
				modifier = OFF_ROLE_EFFICIENCY
	return int(round(float(stat_sum) * modifier))

func tier_for_total(total: int) -> int:
	var tier: int = 1
	for threshold: int in TIER_THRESHOLDS:
		if total >= threshold:
			tier += 1
	return tier
