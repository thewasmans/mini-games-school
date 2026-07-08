extends Object
class_name GameState

signal level_unlocked(level_index: int)
signal current_level_changed(level_index: int)

var current_level: int
var current_mini_game: int
var unlocked_level_count: int

func _init(_game_data:GameData) -> void:
	current_level = 0
	current_mini_game = 0
	unlocked_level_count = 1

func is_level_unlocked(level_index: int) -> bool:
	return level_index < unlocked_level_count

func select_level(level_index: int) -> void:
	current_level = level_index
	current_level_changed.emit(current_level)

func complete_level(level_index: int) -> void:
	if level_index != unlocked_level_count - 1:
		return
	unlocked_level_count += 1
	level_unlocked.emit(unlocked_level_count - 1)
	select_level(unlocked_level_count - 1)
