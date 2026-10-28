@tool
class_name StarsPill
extends PanelContainer
## Prefab de la pastille du haut : étoile + levels terminés / levels disponibles.

const SCENE := "res://scenes/ui/panels/stars_pill.tscn"


static func create(progress: Vector2i) -> StarsPill:
	var p: StarsPill = load(SCENE).instantiate()
	p.set_progress(progress)
	return p


func set_progress(progress: Vector2i) -> void:
	$Row/Inner/Count.text = "%d / %d" % [progress.x, progress.y]
