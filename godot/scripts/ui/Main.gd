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
	_notif_timer.timeout.connect(_on_notif_timer_timeout)

	await get_tree().process_frame
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.projects.project_completed.connect(_on_project_completed)
		gm.corp_points_changed.connect(_on_cp_changed)
		_cp_value.text = str(gm.corp_points)
		gm.employees.hero_unlocked.connect(_on_hero_unlocked)
	var em: Node = get_node_or_null("/root/EventManager")
	if em != null:
		em.event_fired.connect(_on_event_fired)

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

func _on_project_completed(proj: Dictionary) -> void:
	var proj_name: String = proj.get("name", "Project")
	var cash: int = proj.get("reward_cash", 0)
	var cp: int   = proj.get("reward_corp_points", 0)
	_notif_label.text = "%s Complete!\n+$%d  +%d CP" % [proj_name, cash, cp]
	_notif_panel.visible = true
	_notif_timer.start()

func _on_notif_timer_timeout() -> void:
	_notif_panel.visible = false

func _on_hero_unlocked(_hero_name: String) -> void:
	_notif_label.text = "A legendary employee is now available!\nCheck HR > Recruit."
	_notif_panel.visible = true
	_notif_timer.start()

func _on_event_fired(event: Dictionary) -> void:
	_event_popup.show_event(event)

func _on_cp_changed(new_val: int) -> void:
	_cp_value.text = str(new_val)
