extends Node

var competitors: Array = [
	{
		"id":                     "green_future",
		"name":                   "Green Future Foundation",
		"description":            "Environmental NGO. Steady and reliable.",
		"difficulty":             "easy",
		"donors":                 1.0,
		"revenue":                8000.0,
		"reputation":             15.0,
		"monthly_donor_growth":   0.08,
		"monthly_revenue_growth": 600.0,
		"monthly_rep_growth":     1.2,
	},
	{
		"id":                     "hope_alliance",
		"name":                   "Hope Alliance",
		"description":            "Community development org. Aggressive growth.",
		"difficulty":             "medium",
		"donors":                 1.0,
		"revenue":                12000.0,
		"reputation":             20.0,
		"monthly_donor_growth":   0.12,
		"monthly_revenue_growth": 900.0,
		"monthly_rep_growth":     1.8,
	},
	{
		"id":                     "nexus_global",
		"name":                   "Nexus Global",
		"description":            "International powerhouse. Very hard to beat.",
		"difficulty":             "hard",
		"donors":                 2.0,
		"revenue":                18000.0,
		"reputation":             30.0,
		"monthly_donor_growth":   0.18,
		"monthly_revenue_growth": 1400.0,
		"monthly_rep_growth":     2.5,
	},
]

func _ready() -> void:
	var clock: Node = get_node_or_null("/root/ClockManager")
	if clock != null:
		clock.month_changed.connect(_on_month_changed)

func _on_month_changed(_month: int, _year: int) -> void:
	for i in range(competitors.size()):
		competitors[i]["revenue"]    += float(competitors[i]["monthly_revenue_growth"])
		competitors[i]["reputation"]  = minf(
			200.0,
			float(competitors[i]["reputation"]) + float(competitors[i]["monthly_rep_growth"])
		)
		competitors[i]["donors"]     += float(competitors[i]["monthly_donor_growth"])
