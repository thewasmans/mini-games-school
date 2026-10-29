class_name GameState
extends RefCounted

signal level_unlocked(level_index: int)
signal current_level_changed(level_index: int)
signal all_levels_unlocked

var current_study_level := 0
var current_school_year := 0
var current_subject := 0
var are_all_levels_unlocked := false

var _game_data: GameData
var _current_levels: Dictionary[Vector3i, int] = {}
var _completed_levels: Dictionary[Vector3i, Dictionary] = {}

var current_level: int:
	get:
		return _current_levels.get(_progress_key(), 0)

var current_levels: Array[LevelData]:
	get:
		var subject := _game_data.get_subject(current_study_level, current_school_year, current_subject)
		return subject.levels if subject != null else [] as Array[LevelData]


func _init(game_data: GameData) -> void:
	_game_data = game_data


func select_study_level(study_level_index: int) -> void:
	current_study_level = study_level_index


func select_school_year(school_year_index: int) -> void:
	current_school_year = school_year_index


func select_subject(subject_index: int) -> void:
	current_subject = subject_index


func select_level(level_index: int) -> void:
	_current_levels[_progress_key()] = level_index
	current_level_changed.emit(level_index)


func is_level_unlocked(level_index: int) -> bool:
	if are_all_levels_unlocked or level_index == 0:
		return true
	return is_level_completed(level_index) or is_level_completed(level_index - 1)


func is_level_completed(level_index: int) -> bool:
	return _completed_in(_progress_key()).has(level_index)


func unlock_all_levels() -> void:
	are_all_levels_unlocked = true
	all_levels_unlocked.emit()


func complete_level(level_index: int) -> void:
	var key := _progress_key()
	var completed_levels := _completed_in(key)
	if completed_levels.has(level_index):
		return
	completed_levels[level_index] = true
	var next_level_index := level_index + 1
	if next_level_index >= current_levels.size():
		return
	level_unlocked.emit(next_level_index)
	select_level(next_level_index)


func completed_level_count(study_level_index: int, school_year_index := -1, subject_index := -1) -> int:
	var total := 0
	for key: Vector3i in _completed_levels:
		if _matches(key, study_level_index, school_year_index, subject_index):
			total += _completed_levels[key].size()
	return total


func level_count(study_level_index: int, school_year_index := -1, subject_index := -1) -> int:
	var total := 0
	for year_index in GameData.YEARS_PER_STUDY:
		if school_year_index >= 0 and year_index != school_year_index:
			continue
		var school_year := _game_data.get_year(study_level_index, year_index)
		if school_year == null:
			continue
		for index in school_year.subjects.size():
			if subject_index < 0 or index == subject_index:
				total += school_year.subjects[index].levels.size()
	return total


func total_progress() -> Vector2i:
	var progress := Vector2i.ZERO
	for study_level_index in GameData.STUDY_NAMES.size():
		progress += Vector2i(completed_level_count(study_level_index), level_count(study_level_index))
	return progress


func _matches(key: Vector3i, study_level_index: int, school_year_index: int, subject_index: int) -> bool:
	return key.x == study_level_index and (school_year_index < 0 or key.y == school_year_index) and (subject_index < 0 or key.z == subject_index)


func _completed_in(key: Vector3i) -> Dictionary:
	if not _completed_levels.has(key):
		_completed_levels[key] = {}
	return _completed_levels[key]


func _progress_key() -> Vector3i:
	return Vector3i(current_study_level, current_school_year, current_subject)
