class_name DragScrollContainer
extends ScrollContainer

const DRAG_THRESHOLD := 12.0

var _is_tracking := false
var _is_dragging := false
var _press_position := Vector2.ZERO
var _press_scroll := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		_is_tracking = false
		_is_dragging = false
		return
	var mouse_button := event as InputEventMouseButton
	if mouse_button != null and mouse_button.button_index == MOUSE_BUTTON_LEFT:
		if mouse_button.pressed:
			_begin_tracking(mouse_button.position)
		else:
			_is_tracking = false
			_is_dragging = false
		return
	var mouse_motion := event as InputEventMouseMotion
	if mouse_motion != null and _is_tracking:
		_drag_to(mouse_motion.position)

func _gui_input(event: InputEvent) -> void:
	var mouse_button := event as InputEventMouseButton
	if event is InputEventMouseMotion or (mouse_button != null and mouse_button.button_index == MOUSE_BUTTON_LEFT):
		accept_event()

func _begin_tracking(pointer_position: Vector2) -> void:
	if not get_global_rect().has_point(pointer_position) or _is_on_scroll_bar(pointer_position):
		return
	_is_tracking = true
	_is_dragging = false
	_press_position = pointer_position
	_press_scroll = Vector2(scroll_horizontal, scroll_vertical)

func _is_on_scroll_bar(pointer_position: Vector2) -> bool:
	for scroll_bar: ScrollBar in [get_v_scroll_bar(), get_h_scroll_bar()]:
		if scroll_bar.is_visible_in_tree() and scroll_bar.get_global_rect().has_point(pointer_position):
			return true
	return false

func _drag_to(pointer_position: Vector2) -> void:
	var offset := pointer_position - _press_position
	if not _is_dragging:
		if offset.length() < DRAG_THRESHOLD:
			return
		_is_dragging = true
		_cancel_button_presses(self)
	if horizontal_scroll_mode != SCROLL_MODE_DISABLED:
		scroll_horizontal = int(_press_scroll.x - offset.x)
	if vertical_scroll_mode != SCROLL_MODE_DISABLED:
		scroll_vertical = int(_press_scroll.y - offset.y)
	get_viewport().set_input_as_handled()

func _cancel_button_presses(node: Node) -> void:
	for child in node.get_children():
		var button := child as BaseButton
		if button != null and not button.disabled:
			button.disabled = true
			button.disabled = false
		_cancel_button_presses(child)
