extends Object
class_name GameState

signal level_unlocked(study_level_index: int, level_index: int)
signal current_level_changed(level_index: int)

var current_study_level: int
var current_levels: Array[int] = []
var unlocked_level_counts: Array[int] = []

var current_level: int:
	get:
		return current_levels[current_study_level]

func _init(game_data: GameData) -> void:
	current_study_level = 0
	current_levels.resize(game_data.study_levels.size())
	current_levels.fill(0)
	unlocked_level_counts.resize(game_data.study_levels.size())
	unlocked_level_counts.fill(1)

func select_study_level(study_level_index: int) -> void:
	current_study_level = study_level_index

func is_level_unlocked(study_level_index: int, level_index: int) -> bool:
	return level_index < unlocked_level_counts[study_level_index]

func select_level(level_index: int) -> void:
	current_levels[current_study_level] = level_index
	current_level_changed.emit(level_index)

func complete_level(level_index: int) -> void:
	if level_index != unlocked_level_counts[current_study_level] - 1:
		return
	unlocked_level_counts[current_study_level] += 1
	var unlocked_index := unlocked_level_counts[current_study_level] - 1
	level_unlocked.emit(current_study_level, unlocked_index)
	select_level(unlocked_index)
