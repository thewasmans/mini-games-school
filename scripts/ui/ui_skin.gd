class_name UISkin
extends RefCounted
## Thème bitmap extrait des maquettes : assets/ui/*.png (voir tools/extract_ui_assets.py).
## Les boutons et panneaux sont utilisés en 9-slice (StyleBoxTexture), les sprites tels quels.
## Si un PNG manque, les appelants retombent sur le dessin vectoriel de UIDraw.

const DIR := "res://assets/ui/"

## Couleur représentative de chaque skin de bouton, pour choisir le plus proche d'une couleur.
const BUTTON_COLORS := {
	"button_blue": Color("3d84f2"),
	"button_orange": Color("ff9a1f"),
	"button_green": Color("4cc24a"),
	"button_purple": Color("a855e0"),
	"button_yellow": Color("ffd23f"),
	"button_red": Color("ff4d5a"),
	"button_grey": Color("8a93a6"),
	"button_light": Color("eef0ff"),
	"button_navy": Color("22357e"),
}

## Marges 9-slice [gauche, haut, droite, bas] en pixels de texture.
const MARGINS := {
	"button": [30, 20, 30, 24],
	"button_orange": [30, 22, 30, 28],
	"button_play": [64, 24, 30, 30],
	"button_navy": [24, 18, 24, 22],
	"panel_blue": [34, 30, 34, 40],
	"panel_titled": [20, 58, 20, 22],
	"panel_container": [44, 44, 44, 44],
}

## Icônes vectorielles remplacées par un sprite extrait.
const ICON_SPRITES := {
	"book": "icon_book", "book_blue": "icon_book", "pencil": "icon_pencil", "compass": "icon_compass",
	"ruler": "icon_ruler", "scroll": "icon_scroll", "microscope": "icon_microscope", "castle": "icon_castle",
	"crown": "icon_crown", "bulb": "icon_bulb", "coin": "icon_coin", "gem": "icon_gem",
}

## Boutons-icônes dessinés entièrement par un sprite (icône comprise).
const BUTTON_SPRITES := {"back": "button_back", "gear": "button_gear", "sound_off": "button_gear"}

static var _tex := {}


static func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		var path := DIR + name + ".png"
		_tex[name] = load(path) if ResourceLoader.exists(path) else null
	return _tex[name]


## StyleBoxTexture 9-slice, ou null si le PNG est absent.
static func style(name: String) -> StyleBoxTexture:
	var t := tex(name)
	if t == null:
		return null
	var sb := StyleBoxTexture.new()
	sb.texture = t
	var m: Array = MARGINS.get(name, MARGINS["button"] if name.begins_with("button") else [12, 12, 12, 12])
	sb.texture_margin_left = m[0]
	sb.texture_margin_top = m[1]
	sb.texture_margin_right = m[2]
	sb.texture_margin_bottom = m[3]
	return sb


## Skin de bouton dont la couleur est la plus proche de `c`.
static func button_for(c: Color) -> String:
	var best := "button_blue"
	var best_d := INF
	for name: String in BUTTON_COLORS:
		var ref: Color = BUTTON_COLORS[name]
		var d := Vector3(c.r - ref.r, c.g - ref.g, c.b - ref.b).length_squared()
		if d < best_d:
			best_d = d
			best = name
	return best


## Dessine une texture centrée en c, ajustée dans un carré de côté `side` (proportions gardées).
static func draw_fit(ci: CanvasItem, t: Texture2D, c: Vector2, side: float, modulate := Color.WHITE) -> void:
	var k := side / maxf(t.get_width(), t.get_height())
	var sz := Vector2(t.get_width(), t.get_height()) * k
	ci.draw_texture_rect(t, Rect2(c - sz / 2, sz), false, modulate)
