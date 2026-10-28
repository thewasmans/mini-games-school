@tool
class_name SubjectData
extends Resource
## Une matière (Biologie, Chimie…) et sa liste ordonnée de levels.

@export var name: String = ""
## Couleur du bouton. Laisse transparent pour une couleur automatique.
@export var color: Color = Color(0, 0, 0, 0)
@export var levels: Array[LevelData] = []


func count_levels() -> int:
	var n := 0
	for level in levels:
		if level != null and level.mini_game != null:
			n += 1
	return n
