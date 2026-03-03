extends Control

@onready var _bottom_bar:  Node = $BottomBar
@onready var _pause_menu:  Node = $PauseMenu

func _ready() -> void:
	_bottom_bar.menu_requested.connect(_on_menu_requested)
	_pause_menu.hire_requested.connect(_on_hire_requested)

func _on_menu_requested() -> void:
	_pause_menu.open()

func _on_hire_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/HireScreen.tscn")
