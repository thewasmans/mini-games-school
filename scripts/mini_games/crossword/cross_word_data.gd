@tool
class_name CrosswordData
extends MiniGameData

@export var clues: Array[WordData] = []

func build_placements() -> Array[CrosswordWordPlacement]:
	var placements: Array[CrosswordWordPlacement] = []
	for clue in clues:
		placements.append(CrosswordWordPlacement.new(clue, clue.grid_position, clue.is_horizontal))
	return placements
