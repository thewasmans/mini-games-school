class_name ButtonLevelUI
extends Button

var level_index: int

func initialize(level_index_value: int, is_unlocked: bool) -> void:
	level_index = level_index_value
	text = str(level_index + 1)
	disabled = not is_unlocked

func set_unlocked(is_unlocked: bool) -> void:
	disabled = not is_unlocked

func set_current(is_current: bool) -> void:
	modulate = Color.PURPLE if is_current else Color.WHITE
