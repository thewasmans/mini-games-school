class_name LevelManager
extends Manager

@export var level_root: Node
@export var level_prefab: PackedScene

func start_level(level_index: int) -> void:
	var level := level_prefab.instantiate() as Level
	level.initialize(level_index, game_data.levels[level_index])
	level_root.add_child(level)
