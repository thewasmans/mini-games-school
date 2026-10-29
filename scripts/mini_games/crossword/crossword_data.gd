@tool
class_name CrosswordData
extends MiniGameData
## Mots croisés. La grille est calculée dans l'éditeur (onglet Crossword ou import CSV).

@export var entries: Array[CrosswordEntry] = []

@export_group("Grille (générée)")
@export var grid_width: int = 0
@export var grid_height: int = 0


func get_kind_name() -> String:
	return "Mots croisés"


func is_generated() -> bool:
	return grid_width > 0 and grid_height > 0


func get_placed_entries() -> Array[CrosswordEntry]:
	var out: Array[CrosswordEntry] = []
	for e in entries:
		if e != null and e.placed:
			out.append(e)
	return out
