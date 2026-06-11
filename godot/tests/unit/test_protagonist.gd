extends GutTest

# PR-5: Character Customization — protagonist creation, starter rules,
# validation logic, save/load round-trip.

const EXPECTED_STATS: Dictionary = {
	"management": 30, "focus": 25, "charm": 20, "communication": 20,
	"technical": 15, "procurement": 15, "logistics": 15, "precision": 15,
}

var gm: Node = null

func before_each() -> void:
	SaveSystem.delete_save()
	var gm_script: GDScript = preload("res://GameManager.gd")
	gm = gm_script.new()
	# _ready finds no save file and runs new_game (zero employees).
	add_child_autofree(gm)

func after_each() -> void:
	SaveSystem.delete_save()

# ─────────────────────────────────────────
#  STARTER RULES
# ─────────────────────────────────────────
func test_new_game_has_no_protagonist_and_zero_employees() -> void:
	assert_false(gm.has_protagonist(), "fresh game must have no protagonist")
	assert_eq(gm.employees.hired_count(), 0, "v1.5.2 starter rules: zero employees before customization")

func test_create_protagonist_stores_dict_and_hires_exactly_one() -> void:
	gm.create_protagonist(3, "Anan", "Mekong Hope")
	assert_true(gm.has_protagonist())
	var protagonist: Dictionary = gm.company_data.get("protagonist", {})
	assert_eq(int(protagonist.get("portrait_id", -1)), 3)
	assert_eq(protagonist.get("name", ""), "Anan")
	assert_eq(protagonist.get("ngo_name", ""), "Mekong Hope")

	assert_eq(gm.employees.hired_count(), 1, "exactly one employee after customization")
	var emp: Employee = gm.employees.get_hired_employees()[0]
	assert_eq(emp.first_name, "Anan")
	assert_eq(int(emp.role), int(Employee.Role.MANAGEMENT), "protagonist must be a Project Manager")
	assert_eq(emp.tier, "D")
	assert_eq(emp.sp_current, 5)
	assert_eq(emp.sp_max, 5)
	for stat_name in EXPECTED_STATS:
		assert_eq(int(emp.get(str(stat_name))), int(EXPECTED_STATS.get(stat_name, -1)),
			"protagonist stat %s" % str(stat_name))

func test_create_protagonist_is_idempotent() -> void:
	gm.create_protagonist(0, "Anan", "Mekong Hope")
	gm.create_protagonist(1, "Imposter", "Other NGO")
	assert_eq(gm.employees.hired_count(), 1, "second call must not add an employee")
	var protagonist: Dictionary = gm.company_data.get("protagonist", {})
	assert_eq(protagonist.get("name", ""), "Anan", "second call must not overwrite")

# ─────────────────────────────────────────
#  VALIDATION LOGIC (static, tested directly)
# ─────────────────────────────────────────
func test_name_trimming_and_max_length() -> void:
	var cc: GDScript = preload("res://scripts/ui/CharacterCustomization.gd")
	assert_eq(cc.sanitize_name("  Anan  ", 20), "Anan", "whitespace must be trimmed")
	assert_eq(cc.sanitize_name("\tMekong Hope \n", 30), "Mekong Hope")
	var long_name: String = "X".repeat(25)
	assert_eq(cc.sanitize_name(long_name, 20).length(), 20, "name capped at 20 chars")
	assert_eq(cc.sanitize_name(long_name, 30).length(), 25, "shorter input not padded")

func test_start_validation_requires_both_names() -> void:
	var cc: GDScript = preload("res://scripts/ui/CharacterCustomization.gd")
	assert_false(cc.is_valid_input("", ""), "both empty")
	assert_false(cc.is_valid_input("Anan", ""), "missing NGO name")
	assert_false(cc.is_valid_input("", "Mekong Hope"), "missing founder name")
	assert_false(cc.is_valid_input("   ", "Mekong Hope"), "whitespace-only founder name")
	assert_false(cc.is_valid_input("Anan", " \t "), "whitespace-only NGO name")
	assert_true(cc.is_valid_input("Anan", "Mekong Hope"))
	assert_true(cc.is_valid_input("  Anan  ", "  Mekong Hope  "), "trimmed input is valid")

# ─────────────────────────────────────────
#  SAVE / LOAD ROUND-TRIP
# ─────────────────────────────────────────
func test_protagonist_survives_save_load_round_trip() -> void:
	gm.create_protagonist(2, "Nok", "Lotus Aid")
	gm.save_game()

	var gm2_script: GDScript = preload("res://GameManager.gd")
	var gm2: Node = gm2_script.new()
	# _ready finds the save file written above and loads it.
	add_child_autofree(gm2)

	assert_true(gm2.has_protagonist(), "protagonist must survive save/load")
	var protagonist: Dictionary = gm2.company_data.get("protagonist", {})
	assert_eq(int(protagonist.get("portrait_id", -1)), 2)
	assert_eq(protagonist.get("name", ""), "Nok")
	assert_eq(protagonist.get("ngo_name", ""), "Lotus Aid")
	assert_eq(gm2.employees.hired_count(), 1, "protagonist employee must be restored")
	var emp: Employee = gm2.employees.get_hired_employees()[0]
	assert_eq(int(emp.role), int(Employee.Role.MANAGEMENT))
	assert_eq(emp.sp_current, 5)
	assert_eq(emp.sp_max, 5)
