@tool
class_name TitledPanel
extends PanelContainer
## Prefab du cadre titré (panneaux « Clue », crédits) : bandeau de titre puis intérieur bleu nuit.
## Le contenu va dans `content`, les éléments à côté du titre (pastille…) dans `header`.

const SCENE := "res://scenes/ui/panels/titled_panel.tscn"

@export var title := "Titre":
	set(value):
		title = value
		if has_node("Layout/Header/Title"):
			$Layout/Header/Title.text = value

var header: HBoxContainer:
	get:
		return $Layout/Header
var content: VBoxContainer:
	get:
		return $Layout/Inner/Content


static func create(title_: String) -> TitledPanel:
	var p: TitledPanel = load(SCENE).instantiate()
	p.title = title_
	return p
