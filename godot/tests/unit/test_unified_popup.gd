extends GutTest

# PR-6: UnifiedPopup template — page state, skip rule, acknowledgement,
# close gating per UI_SYSTEMS_BIBLE.

const POPUP_SCENE: PackedScene = preload("res://scenes/ui/UnifiedPopup.tscn")

func _spawn(pages: Array) -> CanvasLayer:
	var popup: CanvasLayer = POPUP_SCENE.instantiate()
	add_child_autofree(popup)
	popup.setup("Test Popup", pages)
	popup.open()
	return popup

func _left_click() -> InputEventMouseButton:
	var ev: InputEventMouseButton = InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	return ev

# ─────────────────────────────────────────
#  SINGLE PAGE
# ─────────────────────────────────────────
func test_single_page_close_visible_and_acknowledged() -> void:
	var popup: CanvasLayer = _spawn(["only page"])
	assert_true(popup._close_btn.visible, "CLOSE visible immediately on 1-pager")
	assert_true(popup.acknowledged, "1-pager is acknowledged at open")
	assert_false(popup._nav_row.visible, "no page indicator on 1-pager")

# ─────────────────────────────────────────
#  MULTI PAGE
# ─────────────────────────────────────────
func test_three_pages_close_hidden_until_last() -> void:
	var popup: CanvasLayer = _spawn(["a", "b", "c"])
	assert_false(popup._close_btn.visible, "CLOSE hidden on page 1")
	assert_false(popup.acknowledged)
	assert_false(popup._prev_arrow.visible, "no prev arrow on first page")
	assert_true(popup._next_arrow.visible)

	popup.next_page()
	assert_false(popup._close_btn.visible, "CLOSE hidden on page 2")
	assert_true(popup._prev_arrow.visible)
	assert_true(popup._next_arrow.visible)

	popup.next_page()
	assert_true(popup._close_btn.visible, "CLOSE visible on last page")
	assert_true(popup.acknowledged, "reaching last page acknowledges")
	assert_false(popup._next_arrow.visible, "no next arrow on last page")
	assert_eq(popup._dots_row.get_child_count(), 3, "one dot per page")

func test_navigation_bounds() -> void:
	var popup: CanvasLayer = _spawn(["a", "b", "c"])
	popup.prev_page()
	assert_eq(popup.current_page, 0, "cannot go below first page")
	popup.next_page()
	popup.next_page()
	popup.next_page()
	assert_eq(popup.current_page, 2, "cannot go past last page")
	popup.prev_page()
	assert_eq(popup.current_page, 1)
	assert_true(popup.acknowledged, "acknowledged persists after leaving last page")

func test_pages_capped_at_three() -> void:
	var popup: CanvasLayer = _spawn(["a", "b", "c", "d", "e"])
	assert_eq(popup.page_count(), 3)

# ─────────────────────────────────────────
#  SKIP RULE
# ─────────────────────────────────────────
func test_body_tap_jumps_to_last_page_and_acknowledges() -> void:
	var popup: CanvasLayer = _spawn(["a", "b", "c"])
	popup._on_body_input(_left_click())
	assert_eq(popup.current_page, 2, "body tap jumps to last page")
	assert_true(popup.acknowledged)
	assert_true(popup._close_btn.visible)

# ─────────────────────────────────────────
#  OUTSIDE TAP
# ─────────────────────────────────────────
func test_outside_tap_ignored_before_acknowledgement() -> void:
	var popup: CanvasLayer = _spawn(["a", "b", "c"])
	watch_signals(popup)
	popup._on_dimmer_input(_left_click())
	assert_signal_emit_count(popup, "popup_closed", 0, "outside tap ignored before acknowledgement")
	assert_false(popup.is_queued_for_deletion())

func test_outside_tap_closes_after_acknowledgement() -> void:
	var popup: CanvasLayer = _spawn(["a", "b", "c"])
	watch_signals(popup)
	popup.skip_to_last()
	popup._on_dimmer_input(_left_click())
	assert_signal_emit_count(popup, "popup_closed", 1, "outside tap closes once acknowledged")
	assert_true(popup.is_queued_for_deletion())

# ─────────────────────────────────────────
#  CLOSE
# ─────────────────────────────────────────
func test_popup_closed_emitted_exactly_once() -> void:
	var popup: CanvasLayer = _spawn(["only page"])
	watch_signals(popup)
	popup._close_btn.pressed.emit()
	popup._close_btn.pressed.emit()
	popup._on_dimmer_input(_left_click())
	assert_signal_emit_count(popup, "popup_closed", 1, "popup_closed fires exactly once")
	assert_true(popup.is_queued_for_deletion())
