extends CanvasLayer

signal screen_closed

@onready var _back_btn:    Button        = $Card/Header/HBox/BackBtn
@onready var _title_lbl:   Label         = $Card/Header/HBox/TitleLabel
@onready var _body_vbox:   VBoxContainer = $Card/Body/BodyMargin/BodyVBox
@onready var _footer_btn:  Button        = $Card/FooterBar/FooterBtn
@onready var _win_panel:   Control       = $Card/WinLosePanel
@onready var _win_title:   Label         = $Card/WinLosePanel/WinLoseMargin/WinLoseScroll/WinLoseVBox/WinLoseTitle
@onready var _win_sub:     Label         = $Card/WinLosePanel/WinLoseMargin/WinLoseScroll/WinLoseVBox/WinLoseSubtitle
@onready var _final_ranks: VBoxContainer = $Card/WinLosePanel/WinLoseMargin/WinLoseScroll/WinLoseVBox/FinalRankList
@onready var _play_again:  Button        = $Card/WinLosePanel/WinLoseMargin/WinLoseScroll/WinLoseVBox/PlayAgainBtn

var _results:     Array = []
var _game_year:   int   = 1
var _is_year_5:   bool  = false
var _player_rank: int   = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Dimmer.gui_input.connect(_on_dimmer_input)
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		_results   = gm.last_evaluation_results
		_game_year = gm.last_evaluation_year
		_is_year_5 = _game_year >= 5

	_title_lbl.text   = "YEAR %d EVALUATION" % _game_year
	_back_btn.visible = not _is_year_5

	if _results.is_empty():
		_build_no_results()
		return

	_find_player_rank()
	_build_performance_section()
	_build_ranking_section()
	_build_feedback_section()

	if _is_year_5:
		_footer_btn.text = "FINAL RESULTS"
	else:
		_footer_btn.text = "CONTINUE"

# ─────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────
func _find_player_rank() -> void:
	for entry in _results:
		if bool(entry.get("is_player", false)):
			_player_rank = int(entry.get("rank", 1))
			return

func _build_no_results() -> void:
	var lbl: Label = Label.new()
	lbl.text = "No evaluation data yet.\nComplete a full year to see results."
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1.0))
	lbl.add_theme_font_size_override("font_size", 14)
	_body_vbox.add_child(lbl)
	_footer_btn.text = "BACK"

# ─────────────────────────────────────────
#  PERFORMANCE SECTION
# ─────────────────────────────────────────
func _build_performance_section() -> void:
	var player_entry: Dictionary = {}
	for entry in _results:
		if bool(entry.get("is_player", false)):
			player_entry = entry
			break
	if player_entry.is_empty():
		return

	var donors_score:  float = float(player_entry.get("donors_score", 0))
	var revenue_score: float = float(player_entry.get("revenue_score", 0))
	var rep_score:     float = float(player_entry.get("rep_score", 0))
	var total:         float = float(player_entry.get("total", 0))

	var sec_lbl: Label = Label.new()
	sec_lbl.text = "YOUR PERFORMANCE"
	sec_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2, 1.0))
	sec_lbl.add_theme_font_size_override("font_size", 13)
	_body_vbox.add_child(sec_lbl)

	var cards_row: HBoxContainer = HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 8)
	_body_vbox.add_child(cards_row)
	cards_row.add_child(_make_score_card("DONORS",  "%d/100" % roundi(donors_score),  Color(0.3, 0.9, 1.0, 1.0)))
	cards_row.add_child(_make_score_card("REVENUE", "%d/100" % roundi(revenue_score), Color(0.3, 1.0, 0.4, 1.0)))
	cards_row.add_child(_make_score_card("REP",     "%d/100" % roundi(rep_score),     Color(1.0, 0.82, 0.2, 1.0)))

	var total_row: HBoxContainer = HBoxContainer.new()
	total_row.add_theme_constant_override("separation", 10)
	_body_vbox.add_child(total_row)

	var total_lbl: Label = Label.new()
	total_lbl.text = "TOTAL SCORE:"
	total_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 1.0))
	total_lbl.add_theme_font_size_override("font_size", 14)
	total_row.add_child(total_lbl)

	var total_val: Label = Label.new()
	total_val.text = "%.1f" % total
	total_val.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	total_val.add_theme_font_size_override("font_size", 20)
	total_row.add_child(total_val)

	var grade: String      = _get_grade(total)
	var grade_color: Color = _get_grade_color(grade)

	var grade_row: HBoxContainer = HBoxContainer.new()
	grade_row.add_theme_constant_override("separation", 10)
	_body_vbox.add_child(grade_row)

	var grade_lbl: Label = Label.new()
	grade_lbl.text = "GRADE:"
	grade_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 1.0))
	grade_lbl.add_theme_font_size_override("font_size", 14)
	grade_row.add_child(grade_lbl)

	var grade_badge: Label = Label.new()
	grade_badge.text = " %s " % grade
	grade_badge.add_theme_color_override("font_color", grade_color)
	grade_badge.add_theme_font_size_override("font_size", 22)
	grade_row.add_child(grade_badge)

	_body_vbox.add_child(_make_sep())

func _get_grade(total: float) -> String:
	if total >= 85.0:
		return "S"
	elif total >= 70.0:
		return "A"
	elif total >= 55.0:
		return "B"
	elif total >= 40.0:
		return "C"
	return "D"

func _get_grade_color(grade: String) -> Color:
	match grade:
		"S": return Color(1.0, 0.84, 0.0, 1.0)
		"A": return Color(0.3, 1.0, 0.4, 1.0)
		"B": return Color(0.3, 0.9, 1.0, 1.0)
		"C": return Color(1.0, 0.82, 0.2, 1.0)
		_:   return Color(1.0, 0.3, 0.3, 1.0)

# ─────────────────────────────────────────
#  RANKING SECTION
# ─────────────────────────────────────────
func _build_ranking_section() -> void:
	var sec_lbl: Label = Label.new()
	sec_lbl.text = "RANKINGS"
	sec_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2, 1.0))
	sec_lbl.add_theme_font_size_override("font_size", 13)
	_body_vbox.add_child(sec_lbl)

	var list_vbox: VBoxContainer = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 6)
	_body_vbox.add_child(list_vbox)

	for entry in _results:
		list_vbox.add_child(_make_rank_row(entry))

	_body_vbox.add_child(_make_sep())

func _make_rank_row(entry: Dictionary) -> PanelContainer:
	var rank: int        = int(entry.get("rank", 0))
	var name_str: String = str(entry.get("name", ""))
	var total: float     = float(entry.get("total", 0))
	var is_player: bool  = bool(entry.get("is_player", false))

	var card: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat  = StyleBoxFlat.new()
	if is_player:
		style.bg_color         = Color(0.05, 0.12, 0.28, 0.85)
		style.border_width_left = 3
		style.border_color      = Color(0.3, 0.6, 1.0, 1.0)
	else:
		style.bg_color = Color(0.06, 0.06, 0.14, 0.7)
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left  = 4
	style.content_margin_left   = 10.0
	style.content_margin_right  = 10.0
	style.content_margin_top    = 6.0
	style.content_margin_bottom = 6.0
	card.add_theme_stylebox_override("panel", style)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)

	var rank_lbl: Label = Label.new()
	rank_lbl.text               = "[%d]" % rank
	rank_lbl.custom_minimum_size = Vector2(32, 0)
	rank_lbl.add_theme_font_size_override("font_size", 13)
	if rank == 1:
		rank_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
	else:
		rank_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
	row.add_child(rank_lbl)

	var name_lbl: Label = Label.new()
	name_lbl.text               = name_str
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.autowrap_mode      = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_size_override("font_size", 13)
	if is_player:
		name_lbl.add_theme_color_override("font_color", Color(0.4, 0.75, 1.0, 1.0))
	else:
		name_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	row.add_child(name_lbl)

	var score_lbl: Label = Label.new()
	score_lbl.text = "%.1f" % total
	score_lbl.add_theme_font_size_override("font_size", 14)
	score_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	row.add_child(score_lbl)

	return card

# ─────────────────────────────────────────
#  FEEDBACK SECTION
# ─────────────────────────────────────────
func _build_feedback_section() -> void:
	var player_entry: Dictionary = {}
	for entry in _results:
		if bool(entry.get("is_player", false)):
			player_entry = entry
			break
	if player_entry.is_empty():
		return

	var donors_score:  float = float(player_entry.get("donors_score", 0))
	var revenue_score: float = float(player_entry.get("revenue_score", 0))
	var rep_score:     float = float(player_entry.get("rep_score", 0))

	var weakest: float  = minf(minf(donors_score, revenue_score), rep_score)
	var feedback: String = ""
	if weakest == donors_score:
		feedback = "Your donor pipeline needs work. Focus on Research to secure more donors and unlock new funding streams."
	elif weakest == revenue_score:
		feedback = "Revenue is falling behind. Complete more projects and increase your team output to hit financial targets."
	else:
		feedback = "Reputation lags behind competitors. Invest in quality work and employee morale to build a stronger brand."

	var sec_lbl: Label = Label.new()
	sec_lbl.text = "FEEDBACK"
	sec_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2, 1.0))
	sec_lbl.add_theme_font_size_override("font_size", 13)
	_body_vbox.add_child(sec_lbl)

	var feedback_lbl: Label = Label.new()
	feedback_lbl.text         = feedback
	feedback_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72, 1.0))
	feedback_lbl.add_theme_font_size_override("font_size", 13)
	_body_vbox.add_child(feedback_lbl)

# ─────────────────────────────────────────
#  CARD / SEP BUILDERS
# ─────────────────────────────────────────
func _make_score_card(title: String, value_text: String, val_color: Color) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.18, 0.95)
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left  = 6
	style.content_margin_left   = 8.0
	style.content_margin_right  = 8.0
	style.content_margin_top    = 8.0
	style.content_margin_bottom = 8.0
	card.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var title_lbl: Label = Label.new()
	title_lbl.text               = title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1.0))
	title_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(title_lbl)

	var val_lbl: Label = Label.new()
	val_lbl.text               = value_text
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.add_theme_color_override("font_color", val_color)
	val_lbl.add_theme_font_size_override("font_size", 15)
	vbox.add_child(val_lbl)

	return card

func _make_sep() -> HSeparator:
	var sep: HSeparator = HSeparator.new()
	sep.add_theme_color_override("color", Color(0.2, 0.2, 0.35, 0.8))
	return sep

# ─────────────────────────────────────────
#  WIN / LOSE SCREEN
# ─────────────────────────────────────────
func _show_win_lose_screen() -> void:
	for child in _final_ranks.get_children():
		child.queue_free()

	if _player_rank == 1:
		_win_title.text = "YOU WIN!"
		_win_sub.text   = "Your NGO is #1! You beat all competitors after 5 years."
		_win_title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
	elif _player_rank == 2:
		_win_title.text = "2nd Place"
		_win_sub.text   = "So close! You were just behind the top spot."
		_win_title.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
	else:
		_win_title.text = "Defeated"
		_win_sub.text   = "Better luck next time. Try a different strategy!"
		_win_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))

	for entry in _results:
		_final_ranks.add_child(_make_rank_row(entry))

	_win_panel.visible = true

# ─────────────────────────────────────────
#  BUTTON HANDLERS
# ─────────────────────────────────────────
func _on_back_pressed() -> void:
	screen_closed.emit()
	queue_free()

func _on_footer_btn_pressed() -> void:
	if _is_year_5:
		_show_win_lose_screen()
	else:
		screen_closed.emit()
		queue_free()

func _on_play_again_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			queue_free()
