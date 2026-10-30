class_name GameState
extends RefCounted

signal level_unlocked(level_index: int)
signal current_level_changed(level_index: int)
signal all_levels_unlocked
signal bonus_count_changed(bonus_count: int)

var current_study_level := 0
var current_school_year := 0
var current_subject := 0
var are_all_levels_unlocked := false
var bonus_count := 0

var _game_data: GameData
var _current_levels: Dictionary[Vector3i, int] = {}
var _completed_levels: Dictionary[Vector3i, Dictionary] = {}
var _claimed_islands: Dictionary[Vector3i, Dictionary] = {}

var current_level: int:
	get:
		return _current_levels.get(_progress_key(), 0)

var current_levels: Array[LevelData]:
	get:
		var subject := _current_subject_data()
		return subject.levels if subject != null else [] as Array[LevelData]

var island_count: int:
	get:
		var subject := _current_subject_data()
		if subject == null or subject.bonus_island_interval <= 0:
			return 0
		return floori(subject.levels.size() / float(subject.bonus_island_interval))


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


func level_stars(level_index: int) -> float:
	return _completed_in(_progress_key()).get(level_index, 0.0)


func complete_level(level_index: int, stars := 3.0) -> void:
	var completed_levels := _completed_in(_progress_key())
	var first_completion := not completed_levels.has(level_index)
	completed_levels[level_index] = maxf(completed_levels.get(level_index, 0.0), stars)
	if not first_completion:
		return
	var next_level_index := level_index + 1
	if next_level_index >= current_levels.size():
		return
	level_unlocked.emit(next_level_index)
	select_level(next_level_index)


func island_levels(island_index: int) -> Array[int]:
	var interval := _current_subject_data().bonus_island_interval
	var level_indices: Array[int] = []
	for level_index in range(island_index * interval, (island_index + 1) * interval):
		level_indices.append(level_index)
	return level_indices


func is_island_reached(island_index: int) -> bool:
	return island_levels(island_index).all(is_level_completed)


func island_reward(island_index: int) -> int:
	if not is_island_reached(island_index):
		return 0
	var level_indices := island_levels(island_index)
	var total_stars := 0.0
	for level_index in level_indices:
		total_stars += level_stars(level_index)
	return floori(total_stars / level_indices.size() + 0.001)


func island_claimed(island_index: int) -> int:
	return _claimed_in(_progress_key()).get(island_index, 0)


func claim_island(island_index: int) -> int:
	var gained := island_reward(island_index) - island_claimed(island_index)
	if gained <= 0:
		return 0
	_claimed_in(_progress_key())[island_index] = island_reward(island_index)
	add_bonus(gained)
	return gained


func add_bonus(count: int) -> void:
	bonus_count += count
	bonus_count_changed.emit(bonus_count)


func spend_bonus() -> bool:
	if bonus_count <= 0:
		return false
	bonus_count -= 1
	bonus_count_changed.emit(bonus_count)
	return true


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


func _claimed_in(key: Vector3i) -> Dictionary:
	if not _claimed_islands.has(key):
		_claimed_islands[key] = {}
	return _claimed_islands[key]


func _current_subject_data() -> SubjectData:
	return _game_data.get_subject(current_study_level, current_school_year, current_subject)


func _progress_key() -> Vector3i:
	return Vector3i(current_study_level, current_school_year, current_subject)
