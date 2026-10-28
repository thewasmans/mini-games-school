@tool
class_name TitleBanner
extends PanelContainer
## Prefab de la bannière de titre : pilule brillante (variation Banner<Couleur> du thème).

const SCENE := "res://scenes/ui/panels/title_banner.tscn"

@export var text := "Titre":
	set(value):
		text = value
		if has_node("Text"):
			$Text.text = value
## Choisit la variation Banner<Couleur> la plus proche.
@export var color := UIStyle.BLUE:
	set(value):
		color = value
		theme_type_variation = "Banner" + UISkin.color_name(value)

var label: Label:
	get:
		return $Text


static func create(text_: String, color_ := UIStyle.BLUE, size := 40, text_color := Color.WHITE) -> TitleBanner:
	var b: TitleBanner = load(SCENE).instantiate()
	b.text = text_
	b.color = color_
	b.label.add_theme_font_size_override("font_size", size)
	b.label.add_theme_constant_override("outline_size", maxi(6, size / 4))
	b.label.add_theme_color_override("font_color", text_color)
	return b
