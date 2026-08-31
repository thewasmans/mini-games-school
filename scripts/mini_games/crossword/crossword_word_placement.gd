class_name CrosswordWordPlacement
extends RefCounted

var word_data: WordData
var start: Vector2i
var is_horizontal: bool

func _init(_word_data: WordData, _start: Vector2i, _is_horizontal: bool) -> void:
	word_data = _word_data
	start = _start
	is_horizontal = _is_horizontal

func cell_position(letter_index: int) -> Vector2i:
	if is_horizontal:
		return start + Vector2i(letter_index, 0)
	return start + Vector2i(0, letter_index)
