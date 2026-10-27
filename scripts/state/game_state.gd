extends Object
class_name GameState

signal level_unlocked(level_index: int)
signal current_level_changed(level_index: int)

var current_study_level: int
var current_subject: int
var _current_levels: Dictionary = {}
var _unlocked_level_counts: Dictionary = {}
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
			_unlocked_level_counts[key] = 1
			_level_counts[key] = subjects[subject_index].levels.size()

func select_study_level(study_level_index: int) -> void:
	current_study_level = study_level_index

func select_subject(subject_index: int) -> void:
	current_subject = subject_index

func is_level_unlocked(level_index: int) -> bool:
	return level_index < _unlocked_level_counts[_progress_key()]

func select_level(level_index: int) -> void:
	_current_levels[_progress_key()] = level_index
	current_level_changed.emit(level_index)

func complete_level(level_index: int) -> void:
	var key := _progress_key()
	if level_index != _unlocked_level_counts[key] - 1:
		return
	if _unlocked_level_counts[key] >= _level_counts[key]:
		return
	_unlocked_level_counts[key] += 1
	var unlocked_index: int = _unlocked_level_counts[key] - 1
	level_unlocked.emit(unlocked_index)
	select_level(unlocked_index)

func _progress_key() -> Vector2i:
	return Vector2i(current_study_level, current_subject)
