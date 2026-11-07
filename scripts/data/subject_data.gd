class_name SubjectData
extends Resource

@export var name: String = ""
@export var levels: Array[LevelData] = []

func has_levels() -> bool:
	return not levels.is_empty()
