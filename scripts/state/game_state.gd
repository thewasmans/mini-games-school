extends Object
class_name GameState

signal level_unlocked(level_index: int)
signal current_level_changed(level_index: int)
signal all_levels_unlocked
signal progress_changed

const SAVE_COMPLETED_KEY := "completed"
const SAVE_CURRENT_KEY := "current"

var current_study_level: int
var current_school_year: int
var current_subject: int
var _current_levels: Dictionary = {}
var are_all_levels_unlocked := false
var _completed_levels: Dictionary = {}
var _level_counts: Dictionary = {}
var _subject_save_keys: Dictionary = {}

var current_level: int:
	get:
		return _current_levels.get(_progress_key(), 0)

func _init(game_data: GameData) -> void:
	current_study_level = 0
	current_school_year = 0
	current_subject = 0
	for study_level_index in game_data.study_levels.size():
		var study_level := game_data.study_levels[study_level_index]
		var school_years := study_level.school_years
		for school_year_index in school_years.size():
			var school_year := school_years[school_year_index]
			var subjects := school_year.subjects
			for subject_index in subjects.size():
				var key := Vector3i(study_level_index, school_year_index, subject_index)
				_current_levels[key] = 0
				_completed_levels[key] = {}
				_level_counts[key] = subjects[subject_index].levels.size()
				_subject_save_keys[key] = "%s/%s/%s" % [study_level.name, school_year.name, subjects[subject_index].name]

func save_data() -> Dictionary:
	var subjects := {}
	for key: Vector3i in _subject_save_keys:
		var completed_levels: Array = _completed_levels[key].keys()
		if completed_levels.is_empty() and _current_levels[key] == 0:
			continue
		subjects[_subject_save_keys[key]] = {SAVE_COMPLETED_KEY: completed_levels, SAVE_CURRENT_KEY: _current_levels[key]}
	return subjects

func load_save_data(subjects: Dictionary) -> void:
	for key: Vector3i in _subject_save_keys:
		var saved_subject: Variant = subjects.get(_subject_save_keys[key])
		if not saved_subject is Dictionary:
			continue
		var level_count_of_subject: int = _level_counts[key]
		var saved_completed: Variant = saved_subject.get(SAVE_COMPLETED_KEY, [])
		if saved_completed is Array:
			for saved_level_index: Variant in saved_completed:
				var level_index := int(saved_level_index)
				if level_index >= 0 and level_index < level_count_of_subject:
					_completed_levels[key][level_index] = true
		_current_levels[key] = clampi(int(saved_subject.get(SAVE_CURRENT_KEY, 0)), 0, maxi(0, level_count_of_subject - 1))

func select_study_level(study_level_index: int) -> void:
	current_study_level = study_level_index

func select_school_year(school_year_index: int) -> void:
	current_school_year = school_year_index

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
	for key: Vector3i in _completed_levels:
		if key.x == study_level_index:
			total += _completed_levels[key].size()
	return total

func level_count(study_level_index: int) -> int:
	var total := 0
	for key: Vector3i in _level_counts:
		if key.x == study_level_index:
			total += _level_counts[key]
	return total

func select_level(level_index: int) -> void:
	_current_levels[_progress_key()] = level_index
	current_level_changed.emit(level_index)
	progress_changed.emit()

func complete_level(level_index: int) -> void:
	var key := _progress_key()
	var completed_levels: Dictionary = _completed_levels[key]
	if completed_levels.has(level_index):
		return
	completed_levels[level_index] = true
	var next_level_index := level_index + 1
	if next_level_index >= _level_counts[key]:
		progress_changed.emit()
		return
	level_unlocked.emit(next_level_index)
	select_level(next_level_index)

func _progress_key() -> Vector3i:
	return Vector3i(current_study_level, current_school_year, current_subject)
