@tool
class_name SubjectData
extends Resource

@export var name: String = ""
@export var color: Color = Color(0, 0, 0, 0)
@export var levels: Array[LevelData] = []

@export_group("Réglages")
## Nombre de levels entre deux îles bonus (0 : aucune île).
@export_range(0, 20) var bonus_island_interval := 5
