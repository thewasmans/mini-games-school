@tool
class_name ThemeBuilder
extends RefCounted
## Génère le thème Godot du jeu à partir des PNG extraits des maquettes (content/ui/*.png) :
##   - content/fonts/fredoka.tres : Fredoka graisse 650 (police par défaut)
##   - content/ui/game_theme.tres : thème du projet (Project Settings > GUI > Theme > Custom)
## ATTENTION : écrase game_theme.tres. Les retouches faites dans l'éditeur de thème seront perdues.
##
## Projet > Outils > Outils du jeu > Régénérer le thème, ou :
##   godot --headless --path . --script res://addons/dev_tools/cli.gd -- theme
##
## Contenu du thème :
## - Button : variations Button<Couleur> (voir UISkin.BUTTON_COLORS), ButtonPlay, ButtonKey,
##   ButtonBack / ButtonGear (boutons ronds, icône comprise).
## - PanelContainer : PanelFrame (défaut), PanelTitled, PanelInner, PanelBig, PanelGlass, Pill, PillBlue,
##   PillStars, PillStarsInner, Tile, Banner<Couleur>. Panel : Board.
## - Icônes : CrosswordCell, CryptoCell, LevelNode, LevelPath, DefaultQuizImage, GameIcons.

const UI := "res://content/ui/"
const THEME_PATH := "res://content/ui/game_theme.tres"
const FONT_PATH := "res://content/fonts/fredoka.tres"

## Marges 9-slice [gauche, haut, droite, bas] en pixels de texture.
const BUTTON_MARGINS := [30, 20, 30, 24]
const MARGINS := {
	"button_orange": [30, 22, 30, 28],
	"button_play": [64, 24, 30, 30],
	"button_navy": [24, 18, 24, 22],
	"key": [10, 10, 10, 12],
	"panel_blue": [34, 30, 34, 40],
	"panel_titled": [20, 58, 20, 22],
	"panel_container": [44, 44, 44, 44],
}
## Marges de contenu des boutons [gauche, haut, droite, bas] (le bas inclut l'épaisseur du bouton).
const BUTTON_CONTENT := [22, 10, 22, 20]
## Décalage du contenu quand le bouton est enfoncé.
const PRESS_SHIFT := 4

const STATES := ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]
const FONT_COLORS := ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]


static func run() -> Error:
	return ThemeBuilder.new()._build()


## Remplit le thème déjà chargé (s'il existe) pour que l'éditeur et le jeu voient le changement sans recharger.
func _build() -> Error:
	var t: Theme = load(THEME_PATH) if ResourceLoader.exists(THEME_PATH) else Theme.new()
	t.clear()
	t.default_font = _font()
	t.default_font_size = 28
	_text_defaults(t)
	_buttons(t)
	_panels(t)
	_icons(t)
	_scrollbars(t)
	t.take_over_path(THEME_PATH)
	var err := ResourceSaver.save(t, THEME_PATH)
	print("Thème écrit : %s (%s)" % [THEME_PATH, error_string(err)])
	return err


func _font() -> Font:
	var fv: FontVariation = load(FONT_PATH) if ResourceLoader.exists(FONT_PATH) else FontVariation.new()
	fv.base_font = load("res://content/fonts/Fredoka.ttf")
	var ts := TextServerManager.get_primary_interface()
	fv.variation_opentype = {ts.name_to_tag("wght"): 650}
	fv.take_over_path(FONT_PATH)
	ResourceSaver.save(fv, FONT_PATH)
	return fv


func _text_defaults(t: Theme) -> void:
	for type in ["Label", "Button", "CheckBox"]:
		t.set_color("font_color", type, Color.WHITE)
		t.set_color("font_outline_color", type, UIStyle.INK)
		t.set_constant("outline_size", type, 10)
	t.set_color("font_shadow_color", "Label", Color(0.02, 0.05, 0.2, 0.45))
	t.set_constant("shadow_offset_x", "Label", 0)
	t.set_constant("shadow_offset_y", "Label", 3)
	t.set_constant("shadow_outline_size", "Label", 10)


# --- Boutons ---------------------------------------------------------------

func _tex(name: String) -> Texture2D:
	var path := UI + name + ".png"
	if not ResourceLoader.exists(path):
		push_warning("PNG manquant : " + path)
		return null
	return load(path)


func _nine(name: String) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = _tex(name)
	var m: Array = MARGINS.get(name, BUTTON_MARGINS if name.begins_with("button") else [0, 0, 0, 0])
	sb.texture_margin_left = m[0]
	sb.texture_margin_top = m[1]
	sb.texture_margin_right = m[2]
	sb.texture_margin_bottom = m[3]
	return sb


## Déclare une variation de Button : un état par StyleBoxTexture (survol éclairci, appui assombri et décalé).
func _button(t: Theme, variation: String, png: String, content: Array, font_color: Color, outline_color: Color, outline: int) -> void:
	t.set_type_variation(variation, "Button")
	var normal := _nine(png)
	normal.content_margin_left = content[0]
	normal.content_margin_top = content[1]
	normal.content_margin_right = content[2]
	normal.content_margin_bottom = content[3]
	var hover: StyleBoxTexture = normal.duplicate()
	hover.modulate_color = Color(1.12, 1.12, 1.12)
	var pressed: StyleBoxTexture = normal.duplicate()
	pressed.modulate_color = Color(0.9, 0.9, 0.9)
	pressed.content_margin_top += PRESS_SHIFT
	pressed.content_margin_bottom -= PRESS_SHIFT
	var styles := {"normal": normal, "hover": hover, "pressed": pressed, "hover_pressed": pressed,
		"disabled": normal, "focus": StyleBoxEmpty.new()}
	for state: String in STATES:
		t.set_stylebox(state, variation, styles[state])
	for c: String in FONT_COLORS:
		t.set_color(c, variation, font_color)
	t.set_color("font_disabled_color", variation, Color(font_color, 0.85))
	t.set_color("font_outline_color", variation, outline_color)
	t.set_constant("outline_size", variation, outline)


func _buttons(t: Theme) -> void:
	for name: String in UISkin.BUTTON_COLORS:
		var c: Color = UISkin.BUTTON_COLORS[name]
		var png := "button_" + name.to_lower()
		match name:
			"Light":
				_button(t, "ButtonLight", png, BUTTON_CONTENT, UIStyle.INK, UIStyle.INK, 0)
			"Navy":
				_button(t, "ButtonNavy", png, BUTTON_CONTENT, Color("b9c8f0"), c.darkened(0.62), 8)
			_:
				_button(t, "Button" + name, png, BUTTON_CONTENT, Color.WHITE, c.darkened(0.62), 10)
	_button(t, "ButtonPlay", "button_play", [40, 14, 30, 26], Color.WHITE, Color("6a1f4a"), 16)
	_button(t, "ButtonKey", "key", [2, 6, 2, 12], UIStyle.INK, UIStyle.INK, 0)
	# Boutons ronds : le sprite est simplement étiré, sans 9-slice ni texte.
	_button(t, "ButtonBack", "button_back", [0, 0, 0, 0], Color.WHITE, UIStyle.INK, 0)
	_button(t, "ButtonGear", "button_gear", [0, 0, 0, 0], Color.WHITE, UIStyle.INK, 0)
	# Button sans variation = bouton bleu.
	for state: String in STATES:
		t.set_stylebox(state, "Button", t.get_stylebox(state, "ButtonBlue"))


# --- Panneaux --------------------------------------------------------------

func _margins(sb: StyleBox, l: float, t: float, r: float, b: float) -> StyleBox:
	sb.content_margin_left = l
	sb.content_margin_top = t
	sb.content_margin_right = r
	sb.content_margin_bottom = b
	return sb


func _panel(t: Theme, variation: String, sb: StyleBox, base := "PanelContainer") -> void:
	t.set_type_variation(variation, base)
	t.set_stylebox("panel", variation, sb)


func _panels(t: Theme) -> void:
	# Cadre bleu à liseré clair (question du quiz) : aussi le style par défaut des PanelContainer.
	var frame := _margins(_nine("panel_blue"), 22, 22, 22, 28)
	_panel(t, "PanelFrame", frame)
	t.set_stylebox("panel", "PanelContainer", frame)
	# Cadre titré (« Clue ») : bandeau de titre en haut, intérieur bleu nuit déjà dans le PNG.
	_panel(t, "PanelTitled", _margins(_nine("panel_titled"), 14, 4, 14, 16))
	var inner := StyleBoxEmpty.new()
	inner.set_content_margin_all(10)
	_panel(t, "PanelInner", inner)
	# Grand conteneur bleu nuit à bord lumineux (menus, phrase du cryptogramme).
	_panel(t, "PanelBig", _margins(_nine("panel_container"), 28, 28, 28, 28))

	var glass := UIStyle.box(Color(0.85, 0.9, 1.0, 0.22), 24, 0, 2, Color(1, 1, 1, 0.5))
	glass.set_content_margin_all(12)
	_panel(t, "PanelGlass", glass)
	_panel(t, "Pill", _pill(UIStyle.PANEL_DARK))
	_panel(t, "PillBlue", _pill(Color("1f3a8f")))
	var stars := UIStyle.box(Color("1f3a8f"), 30, 0, 3, Color("6fa8ff"))
	stars.shadow_color = Color(0.02, 0.05, 0.2, 0.4)
	stars.shadow_size = 6
	stars.shadow_offset = Vector2(0, 4)
	_panel(t, "PillStars", _margins(stars, 10, 6, 12, 6))
	_panel(t, "PillStarsInner", _margins(UIStyle.box(UIStyle.INK, 20), 18, 2, 18, 4))
	var tile := UIStyle.box(Color("f4f6ff"), 20, 6, 3, Color("aab4d9"))
	tile.set_content_margin_all(14)
	_panel(t, "Tile", tile)
	var board := UIStyle.box(Color(0.06, 0.12, 0.4, 0.55), 24, 0, 2, Color(0.6, 0.8, 1.0, 0.35))
	_panel(t, "Board", board, "Panel")

	# Bannières de titre : mêmes PNG que les boutons.
	for name: String in UISkin.BUTTON_COLORS:
		_panel(t, "Banner" + name, _margins(_nine("button_" + name.to_lower()), 26, 10, 26, 18))

	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())


func _pill(color: Color) -> StyleBox:
	return _margins(UIStyle.box(color, 40, 0, 2, color.lightened(0.25)), 16, 4, 16, 6)


# --- Icônes (sprites des contrôles dessinés à la main) ---------------------

func _icons(t: Theme) -> void:
	var icons := {
		"CrosswordCell": {"empty": "cell_empty", "word": "cell_word", "cursor": "cell_cursor", "done": "cell_done", "wrong": "cell_wrong"},
		"CryptoCell": {"word": "cell_word", "cursor": "cell_cursor", "good": "cell_good", "wrong": "cell_wrong"},
		"LevelNode": {"open": "platform_open", "lock": "platform_lock", "done": "platform_done"},
		"LevelPath": {"castle_start": "castle_start", "castle_end": "castle_end"},
		"DefaultQuizImage": {"island": "island_castle"},
		"GameIcons": {},
	}
	for name in ["book", "pencil", "compass", "ruler", "scroll", "microscope", "castle", "crown", "bulb", "coin", "gem"]:
		icons["GameIcons"][name] = "icon_" + name
	for type: String in icons:
		for icon: String in icons[type]:
			var tex := _tex(icons[type][icon])
			if tex != null:
				t.set_icon(icon, type, tex)


func _scrollbars(t: Theme) -> void:
	var grabber := UIStyle.box(Color(1, 1, 1, 0.35), 6)
	for s in ["grabber", "grabber_highlight", "grabber_pressed"]:
		t.set_stylebox(s, "VScrollBar", grabber)
	var track := UIStyle.box(Color(0, 0, 0, 0.15), 6)
	track.content_margin_left = 6
	track.content_margin_right = 6
	t.set_stylebox("scroll", "VScrollBar", track)
