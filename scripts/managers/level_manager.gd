class_name LevelManager
extends Manager

@export var level_root: Node
@export var level_prefab: PackedScene

func start_level(level_index: int) -> void:
	var level := level_prefab.instantiate() as Level
	var levels := game_data.study_levels[game_state.current_study_level].levels
	level.initialize(level_index, levels[level_index], _game_manager)
	level_root.add_child(level)
