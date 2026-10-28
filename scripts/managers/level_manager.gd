class_name LevelManager
extends Manager

@export var level_root: Node
@export var level_prefab: PackedScene

func start_level(level_index: int) -> void:
	var level := level_prefab.instantiate() as Level
	var levels := game_data.levels_of(game_state.current_study_level, game_state.current_school_year, game_state.current_subject)
	level.initialize(level_index, levels[level_index], _game_manager)
	level_root.add_child(level)
