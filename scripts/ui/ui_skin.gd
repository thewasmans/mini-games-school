@tool
class_name UISkin
extends RefCounted

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

const ICON_BUTTONS := {"back": &"ButtonBack", "gear": &"ButtonGear", "sound_off": &"ButtonGear"}

const ICONS_TYPE := &"GameIcons"
const ICON_ALIASES := {"book_blue": "book"}


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


static func icon(name: String) -> Texture2D:
	var t := UIStyle.theme()
	var key: StringName = ICON_ALIASES.get(name, name)
	return t.get_icon(key, ICONS_TYPE) if t.has_icon(key, ICONS_TYPE) else null


static func draw_fit(ci: CanvasItem, t: Texture2D, c: Vector2, side: float, modulate := Color.WHITE) -> void:
	var k := side / maxf(t.get_width(), t.get_height())
	var sz := Vector2(t.get_width(), t.get_height()) * k
	ci.draw_texture_rect(t, Rect2(c - sz / 2, sz), false, modulate)
