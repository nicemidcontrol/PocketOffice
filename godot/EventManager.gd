class_name EventManager
extends Node

# ─────────────────────────────────────────
#  SIGNALS
# ─────────────────────────────────────────
signal event_triggered(event_data: Dictionary)

# ─────────────────────────────────────────
#  OUTCOME TYPES
# ─────────────────────────────────────────
enum OutcomeType {
	MONEY_GAIN,
	MONEY_LOSS,
	REPUTATION_GAIN,
	REPUTATION_LOSS,
	MOTIVATION_GAIN,
	MOTIVATION_LOSS
}

# ─────────────────────────────────────────
#  EVENT POOL
# ─────────────────────────────────────────
var _event_pool: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

# ─────────────────────────────────────────
#  INIT
# ─────────────────────────────────────────
func initialize() -> void:
	_rng.randomize()
	_build_event_pool()

func _build_event_pool() -> void:
	_event_pool = [
		{
			"title": "🎉 Investor Visit",
			"description": "A potential investor wants to tour your office. Impressions matter!",
			"icon_key": "icon_investor",
			"trigger_chance": 0.15,
			"choices": [
				{ "label": "Clean Up & Impress",  "result": "Investor loved it!",       "outcome_type": OutcomeType.REPUTATION_GAIN, "outcome_value": 20 },
				{ "label": "Business as Usual",   "result": "Investor was unimpressed.", "outcome_type": OutcomeType.REPUTATION_LOSS, "outcome_value": 5  }
			]
		},
		{
			"title": "🔥 Employee Burnout",
			"description": "Half your team is showing signs of burnout. What do you do?",
			"icon_key": "icon_burnout",
			"trigger_chance": 0.20,
			"choices": [
				{ "label": "Paid Team Retreat", "result": "Team morale soared!",  "outcome_type": OutcomeType.MONEY_LOSS,       "outcome_value": 3000 },
				{ "label": "Ignore It",         "result": "Two employees quit.",  "outcome_type": OutcomeType.MOTIVATION_LOSS,  "outcome_value": 30   }
			]
		},
		{
			"title": "📱 Viral Social Media Post",
			"description": "A staff member posted about the company — it's going viral!",
			"icon_key": "icon_viral",
			"trigger_chance": 0.10,
			"choices": [
				{ "label": "Embrace the Moment",  "result": "Brand awareness exploded!", "outcome_type": OutcomeType.REPUTATION_GAIN, "outcome_value": 30   },
				{ "label": "Issue Damage Control", "result": "Contained, but costly.",    "outcome_type": OutcomeType.MONEY_LOSS,       "outcome_value": 1000 }
			]
		},
		{
			"title": "🎂 Office Birthday Party",
			"description": "It's someone's birthday! Celebrate or focus on deadlines?",
			"icon_key": "icon_party",
			"trigger_chance": 0.25,
			"choices": [
				{ "label": "Throw a Party!",    "result": "Everyone's happy!",         "outcome_type": OutcomeType.MOTIVATION_GAIN, "outcome_value": 15 },
				{ "label": "Politely Decline",  "result": "Morale dipped a little.",   "outcome_type": OutcomeType.MOTIVATION_LOSS, "outcome_value": 5  }
			]
		},
		{
			"title": "📰 Press Coverage",
			"description": "A journalist wants to feature your company in a tech magazine.",
			"icon_key": "icon_press",
			"trigger_chance": 0.12,
			"choices": [
				{ "label": "Accept Interview", "result": "Great exposure!",       "outcome_type": OutcomeType.REPUTATION_GAIN, "outcome_value": 25 },
				{ "label": "Decline for Now",  "result": "Missed opportunity.",   "outcome_type": OutcomeType.REPUTATION_LOSS, "outcome_value": 3  }
			]
		},
		{
			"title": "💰 Government Grant",
			"description": "Your company qualifies for a small business development grant!",
			"icon_key": "icon_money",
			"trigger_chance": 0.08,
			"choices": [
				{ "label": "Apply!", "result": "Grant approved! $5,000 received.", "outcome_type": OutcomeType.MONEY_GAIN, "outcome_value": 5000 }
			]
		},
		{
			"title": "🤝 Partnership Offer",
			"description": "A larger firm wants to co-brand with your company for a campaign.",
			"icon_key": "icon_handshake",
			"trigger_chance": 0.10,
			"choices": [
				{ "label": "Accept Partnership", "result": "Revenue boost incoming!", "outcome_type": OutcomeType.MONEY_GAIN,       "outcome_value": 4000 },
				{ "label": "Decline",            "result": "Stayed independent.",     "outcome_type": OutcomeType.REPUTATION_GAIN,  "outcome_value": 3    }
			]
		},
		{
			"title": "⚡ Power Outage",
			"description": "The office lost power for a day. Work grinds to a halt.",
			"icon_key": "icon_outage",
			"trigger_chance": 0.07,
			"choices": [
				{ "label": "Send Everyone Home",     "result": "At least morale is fine.",  "outcome_type": OutcomeType.MOTIVATION_GAIN, "outcome_value": 5  },
				{ "label": "Rent Generator ASAP",    "result": "Expensive, but productive.","outcome_type": OutcomeType.MONEY_LOSS,      "outcome_value": 800 }
			]
		}
	]

# ─────────────────────────────────────────
#  TRIGGER
# ─────────────────────────────────────────
# Called every in-game day by GameManager
func try_trigger_random_event() -> void:
	for ev in _event_pool:
		# Distribute trigger_chance across ~30 days per month
		if _rng.randf() < ev["trigger_chance"] / 30.0:
			event_triggered.emit(ev)
			return  # max one event per day

# ─────────────────────────────────────────
#  RESOLVE  (called by UI after player picks a choice)
# ─────────────────────────────────────────
func resolve_event(event_data: Dictionary, choice: Dictionary, gm: GameManager) -> void:
	var outcome_type:  int = choice["outcome_type"]
	var outcome_value: int = choice["outcome_value"]

	match outcome_type:
		OutcomeType.MONEY_GAIN:
			gm.economy.add_revenue(outcome_value, event_data["title"])
		OutcomeType.MONEY_LOSS:
			gm.economy.spend(outcome_value, event_data["title"])
		OutcomeType.REPUTATION_GAIN:
			gm.company_data.reputation = mini(1000, gm.company_data.reputation + outcome_value)
		OutcomeType.REPUTATION_LOSS:
			gm.company_data.reputation = maxi(0, gm.company_data.reputation - outcome_value)
		OutcomeType.MOTIVATION_GAIN, OutcomeType.MOTIVATION_LOSS:
			var delta := outcome_value if outcome_type == OutcomeType.MOTIVATION_GAIN else -outcome_value
			for emp in gm.employees.get_hired_employees():
				emp.adjust_motivation(delta / 3)

	gm.broadcast("[%s] %s" % [event_data["title"], choice["result"]])
