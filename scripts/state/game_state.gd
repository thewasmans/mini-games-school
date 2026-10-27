extends Object
class_name GameState

signal level_unlocked(level_index: int)
signal current_level_changed(level_index: int)
signal all_levels_unlocked

var current_study_level: int
var current_subject: int
var _current_levels: Dictionary = {}
var are_all_levels_unlocked := false
var _completed_levels: Dictionary = {}
var _level_counts: Dictionary = {}

var current_level: int:
	get:
		return _current_levels[_progress_key()]

func _init(game_data: GameData) -> void:
	current_study_level = 0
	current_subject = 0
	for study_level_index in game_data.study_levels.size():
		var subjects := game_data.study_levels[study_level_index].subjects
		for subject_index in subjects.size():
			var key := Vector2i(study_level_index, subject_index)
			_current_levels[key] = 0
			_completed_levels[key] = {}
			_level_counts[key] = subjects[subject_index].levels.size()

func select_study_level(study_level_index: int) -> void:
	current_study_level = study_level_index

func select_subject(subject_index: int) -> void:
	current_subject = subject_index

func is_level_unlocked(level_index: int) -> bool:
	if are_all_levels_unlocked or level_index == 0:
		return true
	return _completed_levels[_progress_key()].has(level_index - 1)

func unlock_all_levels() -> void:
	are_all_levels_unlocked = true
	all_levels_unlocked.emit()

func completed_level_count(study_level_index: int) -> int:
	var total := 0
	for key: Vector2i in _completed_levels:
		if key.x == study_level_index:
			total += _completed_levels[key].size()
	return total

func level_count(study_level_index: int) -> int:
	var total := 0
	for key: Vector2i in _level_counts:
		if key.x == study_level_index:
			total += _level_counts[key]
	return total

func select_level(level_index: int) -> void:
	_current_levels[_progress_key()] = level_index
	current_level_changed.emit(level_index)

func complete_level(level_index: int) -> void:
	var key := _progress_key()
	var completed_levels: Dictionary = _completed_levels[key]
	if completed_levels.has(level_index):
		return
	completed_levels[level_index] = true
	var next_level_index := level_index + 1
	if next_level_index >= _level_counts[key]:
		return
	level_unlocked.emit(next_level_index)
	select_level(next_level_index)

func _progress_key() -> Vector2i:
	return Vector2i(current_study_level, current_subject)
