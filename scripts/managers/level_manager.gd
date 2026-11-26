class_name LevelManager
extends Manager

signal level_started(level: Level)
signal level_closed

@export var level_root: Node
@export var level_prefab: PackedScene

var _level: Level


func initialize(game_manager: GameManager) -> void:
	super.initialize(game_manager)
	game_state.bonus_count_changed.connect(_on_bonus_count_changed)


func start_level(level_index: int) -> void:
	var level_data := game_state.current_levels[level_index]
	_level = level_prefab.instantiate() as Level
	level_root.add_child(_level)
	_level.initialize(level_index, level_data, _title_of(level_data))
	_level.top_bar.set_progress(game_state.total_progress())
	_level.set_bonus_count(game_state.bonus_count)
	_level.top_bar.set_action_points(housing_state.action_points)
	_level.validated.connect(_on_level_validated)
	_level.exited.connect(_close_level)
	_level.hint_requested.connect(_on_hint_requested)
	level_started.emit(_level)


func _title_of(level_data: LevelData) -> String:
	var title_parts := PackedStringArray([
		GameData.STUDY_NAMES[game_state.current_study_level],
		game_data.get_year_name(game_state.current_study_level, game_state.current_school_year),
		game_data.get_subject(game_state.current_study_level, game_state.current_school_year, game_state.current_subject).name,
	])
	if level_data.mini_game != null and not level_data.mini_game.theme_title.strip_edges().is_empty():
		title_parts.append(level_data.mini_game.theme_title)
	return " - ".join(title_parts)


func _on_level_validated(level_index: int, stars: float) -> void:
	var subject_key := game_state.current_subject_key
	var first_completion := not game_state.is_level_completed(level_index)
	var new_stars := game_state.complete_level(level_index, stars)
	var gained := housing_state.record_level_result(subject_key, level_index, first_completion, new_stars, stars, int(Time.get_unix_time_from_system()))
	var progress := housing_state.record_encounters(subject_key, level_index, _level.word_points())
	var grown := progress.filter(func(entry: Dictionary) -> bool: return entry.after > entry.before)
	if gained <= 0 and grown.is_empty():
		_close_level()
		return
	var shown: Array[Dictionary] = []
	shown.assign(grown)
	_level.rewards_closed.connect(_close_level, CONNECT_ONE_SHOT)
	_level.show_rewards(gained, housing_state.action_points, shown)


func _on_hint_requested() -> void:
	if game_state.bonus_count > 0 and _level.use_hint():
		game_state.spend_bonus()


func _on_bonus_count_changed(bonus_count: int) -> void:
	if _level != null:
		_level.set_bonus_count(bonus_count)


func _close_level() -> void:
	_level.queue_free()
	_level = null
	level_closed.emit()
