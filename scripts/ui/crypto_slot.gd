class_name CryptoSlot
extends Button

const EMPTY_SIZE := Vector2(22, 44)
const FILLED_SIZE := Vector2(0, 44)
const MINIMUM_CLICK_WIDTH := 40.0
const SELECTED_VARIATION := &"CryptoSlotSelected"
const FILLED_VARIATION := &"CryptoSlotFilled"

var selected := false:
	set(value):
		selected = value
		_refresh_style()

func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_refresh_style()

func set_letter(letter: String) -> void:
	text = letter
	_refresh_style()

func _refresh_style() -> void:
	if selected:
		theme_type_variation = SELECTED_VARIATION
	elif text != "":
		theme_type_variation = FILLED_VARIATION
	else:
		theme_type_variation = &""
	custom_minimum_size = FILLED_SIZE if text != "" and not selected else EMPTY_SIZE

func _has_point(point: Vector2) -> bool:
	var extra_width := maxf(0.0, (MINIMUM_CLICK_WIDTH - size.x) / 2.0)
	return Rect2(Vector2(-extra_width, 0.0), Vector2(size.x + extra_width * 2.0, size.y)).has_point(point)
