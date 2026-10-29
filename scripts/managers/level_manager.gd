class_name LevelManager
extends Manager

signal level_started(level: Level)
signal level_closed

@export var level_root: Node
@export var level_prefab: PackedScene

var _level: Level


func start_level(level_index: int) -> void:
	var level_data := game_state.current_levels[level_index]
	_level = level_prefab.instantiate() as Level
	level_root.add_child(_level)
	_level.initialize(level_index, level_data, _title_of(level_data))
	_level.top_bar.set_progress(game_state.total_progress())
	_level.validated.connect(_on_level_validated)
	_level.exited.connect(_close_level)
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


func _on_level_validated(level_index: int) -> void:
	game_state.complete_level(level_index)
	_close_level()


func _close_level() -> void:
	_level.queue_free()
	_level = null
	level_closed.emit()
