@tool
class_name MenuPanel
extends PanelContainer
## Prefab du grand conteneur bleu nuit à bord lumineux (menus, phrase du cryptogramme),
## avec un bandeau d'en-tête à étincelles, masqué si `header_text` est vide.
## Le contenu va dans `content` (sous l'en-tête).

const SCENE := "res://scenes/ui/panels/menu_panel.tscn"

@export_multiline var header_text := "":
	set(value):
		header_text = value
		if has_node("Content/Header"):
			$Content/Header.text = value
			$Content/Header.visible = value != ""

var content: VBoxContainer:
	get:
		return $Content


static func create(header_text_ := "") -> MenuPanel:
	var p: MenuPanel = load(SCENE).instantiate()
	p.header_text = header_text_
	return p
