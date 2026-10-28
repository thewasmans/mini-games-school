@tool
class_name UISkin
extends RefCounted
## Correspondances entre le code et le thème Godot du jeu (content/ui/game_theme.tres, généré par
## addons/dev_tools/theme_builder.gd à partir des PNG extraits des maquettes).
## Boutons : variations « Button<Couleur> », bannières : « Banner<Couleur> ».

## Couleur représentative de chaque skin de bouton (PNG content/ui/button_<nom>.png),
## pour choisir la variation la plus proche d'une couleur quelconque.
const BUTTON_COLORS := {
	"Blue": Color("3d84f2"),
	"Orange": Color("ff9a1f"),
	"Green": Color("4cc24a"),
	"Purple": Color("a855e0"),
	"Yellow": Color("ffd23f"),
	"Red": Color("ff4d5a"),
	"Grey": Color("8a93a6"),
	"Light": Color("eef0ff"),
	"Navy": Color("22357e"),
}

## Boutons-icônes entièrement dessinés par le thème (icône comprise).
const ICON_BUTTONS := {"back": &"ButtonBack", "gear": &"ButtonGear", "sound_off": &"ButtonGear"}

## Type de thème qui porte les icônes-sprites (UIDraw.icon les préfère au dessin vectoriel).
const ICONS_TYPE := &"GameIcons"
const ICON_ALIASES := {"book_blue": "book"}


## Nom de la couleur de skin la plus proche de `c` (clé de BUTTON_COLORS).
static func color_name(c: Color) -> String:
	var best := "Blue"
	var best_d := INF
	for name: String in BUTTON_COLORS:
		var ref: Color = BUTTON_COLORS[name]
		var d := Vector3(c.r - ref.r, c.g - ref.g, c.b - ref.b).length_squared()
		if d < best_d:
			best_d = d
			best = name
	return best


## Icône-sprite du thème (type GameIcons), ou null.
static func icon(name: String) -> Texture2D:
	var t := UIStyle.theme()
	var key: StringName = ICON_ALIASES.get(name, name)
	return t.get_icon(key, ICONS_TYPE) if t.has_icon(key, ICONS_TYPE) else null


## Dessine une texture centrée en c, ajustée dans un carré de côté `side` (proportions gardées).
static func draw_fit(ci: CanvasItem, t: Texture2D, c: Vector2, side: float, modulate := Color.WHITE) -> void:
	var k := side / maxf(t.get_width(), t.get_height())
	var sz := Vector2(t.get_width(), t.get_height()) * k
	ci.draw_texture_rect(t, Rect2(c - sz / 2, sz), false, modulate)
