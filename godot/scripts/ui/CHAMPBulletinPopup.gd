extends CanvasLayer

# ------------------------------------------
#  NODE REFS
# ------------------------------------------
@onready var _headline_label:   Label         = $Panel/Margin/VBox/HeadlineLabel
@onready var _effect_label:     Label         = $Panel/Margin/VBox/EffectLabel
@onready var _duration_label:   Label         = $Panel/Margin/VBox/DurationLabel
@onready var _mitigation_vbox:  VBoxContainer = $Panel/Margin/VBox/MitigationVBox
@onready var _ack_btn:          Button        = $Panel/Margin/VBox/AcknowledgeBtn

# ------------------------------------------
#  STATE
# ------------------------------------------
var _queue: Array          = []
var _current: Dictionary   = {}

# ------------------------------------------
#  LIFECYCLE
# ------------------------------------------
func _ready() -> void:
	visible = false
	_ack_btn.pressed.connect(_on_acknowledge)
	var bm: Node = get_node_or_null("/root/CHAMPBulletinManager")
	if bm != null:
		bm.bulletin_fired.connect(_on_bulletin_fired)

# ------------------------------------------
#  SIGNALS FROM MANAGER
# ------------------------------------------
func _on_bulletin_fired(bulletin_data: Dictionary) -> void:
	_queue.append(bulletin_data)
	if not visible:
		_show_next()

# ------------------------------------------
#  DISPLAY
# ------------------------------------------
func _show_next() -> void:
	if _queue.is_empty():
		visible = false
		return
	_current = _queue.pop_front()
	_headline_label.text = _current.get("headline", "")
	_effect_label.text   = _build_effect_text(_current)
	var dur: int         = _current.get("duration_months", 1)
	_duration_label.text = "Duration: " + str(dur) + " month" + ("s" if dur != 1 else "")
	_build_mitigation_buttons()
	visible = true

func _build_effect_text(b: Dictionary) -> String:
	var etype: String = b.get("effect_type", "")
	var eval: float   = b.get("effect_value", 1.0)
	match etype:
		"project_slow":
			return "Projects slow to " + str(int(eval * 100)) + "% speed"
		"project_boost":
			return "Projects boosted to " + str(int(eval * 100)) + "% speed"
		"project_pause":
			return "All projects PAUSED"
		"project_regress":
			return "Projects lose " + str(int(abs(eval) * 100)) + "% progress each tick"
		"cash_freeze":
			return "Cash income FROZEN"
		"reputation_gain":
			return "Reputation +" + str(int(eval))
		_:
			return ""

func _build_mitigation_buttons() -> void:
	for child in _mitigation_vbox.get_children():
		child.queue_free()
	if not _current.get("has_mitigation", false):
		return
	var opts: Array = _current.get("mitigation_options", [])
	var idx: int = 0
	for opt in opts:
		var btn: Button = Button.new()
		btn.text = opt.get("label", "Mitigate")
		btn.custom_minimum_size = Vector2(0, 36)
		btn.add_theme_font_size_override("font_size", 11)
		btn.add_theme_color_override("font_color", Color(0.2, 0.85, 0.94, 1))
		var capture_idx: int = idx
		btn.pressed.connect(func() -> void: _on_mitigate(capture_idx))
		_mitigation_vbox.add_child(btn)
		idx += 1

# ------------------------------------------
#  HANDLERS
# ------------------------------------------
func _on_acknowledge() -> void:
	_current = {}
	_show_next()

func _on_mitigate(opt_idx: int) -> void:
	var bm: Node = get_node_or_null("/root/CHAMPBulletinManager")
	if bm != null:
		bm.apply_mitigation(_current.get("id", ""), opt_idx)
	_current = {}
	_show_next()
