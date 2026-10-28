@tool
class_name Pill
extends PanelContainer
## Prefab de la petite pastille arrondie (compteur, tag) : variation Pill ou PillBlue.

const SCENE := "res://scenes/ui/panels/pill.tscn"

@export var text := "":
	set(value):
		text = value
		if has_node("Text"):
			$Text.text = value

var label: Label:
	get:
		return $Text


static func create(text_ := "", size := 22, variation := &"Pill") -> Pill:
	var p: Pill = load(SCENE).instantiate()
	p.text = text_
	p.theme_type_variation = variation
	p.label.add_theme_font_size_override("font_size", size)
	return p
