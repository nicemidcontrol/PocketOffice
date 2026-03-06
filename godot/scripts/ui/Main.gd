extends Control

@onready var _bottom_bar:   Node  = $BottomBar
@onready var _pause_menu:   Node  = $PauseMenu
@onready var _cp_value:     Label = $CpIndicator/CpPanel/HBox/CpValue
@onready var _notif_panel:  Panel = $NotifLayer/NotifPanel
@onready var _notif_label:  Label = $NotifLayer/NotifPanel/Margin/VBox/NotifLabel
@onready var _notif_timer:  Timer = $NotifLayer/NotifPanel/NotifTimer
@onready var _event_popup:  Node  = $EventPopup

func _ready() -> void:
	_bottom_bar.menu_requested.connect(_on_menu_requested)
	_pause_menu.hire_requested.connect(_on_hire_requested)
	_pause_menu.project_board_requested.connect(_on_project_board_requested)
	_pause_menu.employee_list_requested.connect(_on_employee_list_requested)
	_pause_menu.build_requested.connect(_on_build_requested)
	_pause_menu.research_requested.connect(_on_research_requested)
	_pause_menu.shop_requested.connect(_on_shop_requested)
	_notif_timer.timeout.connect(_on_notif_timer_timeout)

	await get_tree().process_frame
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.projects.project_completed.connect(_on_project_completed)
		gm.corp_points_changed.connect(_on_cp_changed)
		_cp_value.text = str(gm.corp_points)
		gm.employees.hero_unlocked.connect(_on_hero_unlocked)
		gm.employees.employee_burnout.connect(_on_employee_burnout)
		gm.evaluation_ready.connect(_on_evaluation_ready)
	var dm: Node = get_node_or_null("/root/DonorManager")
	if dm != null:
		dm.donor_won.connect(_on_donor_won)
	var em: Node = get_node_or_null("/root/EventManager")
	if em != null:
		em.event_fired.connect(_on_event_fired)
	_maybe_show_tutorial()
	_load_debug_menu()

func _load_debug_menu() -> void:
	if not OS.is_debug_build():
		return
	var debug_scene: PackedScene = load("res://scenes/DebugMenu.tscn")
	if debug_scene == null:
		return
	var debug_menu: Node = debug_scene.instantiate()
	add_child(debug_menu)

func _on_shop_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/ShopScreen.tscn")

func _maybe_show_tutorial() -> void:
	var tut_script: GDScript = load("res://scripts/ui/TutorialOverlay.gd")
	if tut_script == null:
		return
	if tut_script.is_tutorial_seen():
		return
	var overlay: Node = load("res://scenes/TutorialOverlay.tscn").instantiate()
	add_child(overlay)
	overlay.show_tutorial()

func _on_menu_requested() -> void:
	_pause_menu.open()

func _on_hire_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/HireScreen.tscn")

func _on_project_board_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/ProjectBoard.tscn")

func _on_employee_list_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/EmployeeListScreen.tscn")

func _on_build_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/BuildScreen.tscn")

func _on_research_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/ResearchScreen.tscn")

func _on_evaluation_ready(_year: int, _results: Array) -> void:
	get_tree().change_scene_to_file("res://scenes/EvaluationScreen.tscn")

func _on_score_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/EvaluationScreen.tscn")

func _on_project_completed(proj: Dictionary) -> void:
	var proj_name: String = proj.get("name", "Project")
	var cash: int = proj.get("reward_cash", 0)
	var cp: int   = proj.get("reward_corp_points", 0)
	_notif_label.text = "%s Complete!\n+$%d  +%d CP" % [proj_name, cash, cp]
	_notif_panel.visible = true
	_notif_timer.start()

func _on_notif_timer_timeout() -> void:
	_notif_panel.visible = false
	_notif_label.remove_theme_color_override("font_color")
	_notif_panel.remove_theme_stylebox_override("panel")

func _on_employee_burnout(emp_name: String) -> void:
	_notif_label.text = emp_name + " is burned out!\nRemove OT immediately."
	var red_style: StyleBoxFlat = StyleBoxFlat.new()
	red_style.bg_color = Color(0.15, 0.04, 0.04, 0.97)
	red_style.border_width_left   = 2
	red_style.border_width_top    = 2
	red_style.border_width_right  = 2
	red_style.border_width_bottom = 2
	red_style.border_color = Color(0.9, 0.2, 0.2, 1.0)
	red_style.corner_radius_top_left     = 8
	red_style.corner_radius_top_right    = 8
	red_style.corner_radius_bottom_right = 8
	red_style.corner_radius_bottom_left  = 8
	_notif_panel.add_theme_stylebox_override("panel", red_style)
	_notif_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
	_notif_panel.visible = true
	_notif_timer.start()

func _on_hero_unlocked(_hero_name: String) -> void:
	_notif_label.text = "A legendary employee is now available!\nCheck HR > Recruit."
	_notif_panel.visible = true
	_notif_timer.start()

func _on_event_fired(event: Dictionary) -> void:
	_event_popup.show_event(event)

func _on_donor_won(donor_name: String, monthly: int) -> void:
	var green_style: StyleBoxFlat = StyleBoxFlat.new()
	green_style.bg_color = Color(0.05, 0.14, 0.07, 0.97)
	green_style.border_width_left   = 2
	green_style.border_width_top    = 2
	green_style.border_width_right  = 2
	green_style.border_width_bottom = 2
	green_style.border_color = Color(0.2, 0.85, 0.3, 1.0)
	green_style.corner_radius_top_left     = 8
	green_style.corner_radius_top_right    = 8
	green_style.corner_radius_bottom_right = 8
	green_style.corner_radius_bottom_left  = 8
	_notif_panel.add_theme_stylebox_override("panel", green_style)
	_notif_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))
	_notif_label.text = "%s secured!\n+$%d/mo funding" % [donor_name, monthly]
	_notif_panel.visible = true
	_notif_timer.start()

func _on_cp_changed(new_val: int) -> void:
	_cp_value.text = str(new_val)
