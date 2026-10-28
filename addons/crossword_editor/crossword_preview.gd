@tool
extends Control
## Aperçu de la grille dans l'onglet Crossword.

const COLOR_CELL := Color("d6d0ff")
const COLOR_EMPTY := Color(1, 1, 1, 0.05)
const COLOR_HIGHLIGHT := Color("ffe14d")
const COLOR_ISOLATED := Color("ff9f1c")
const COLOR_CONFLICT := Color("ff4d5a")

var data: CrosswordData
var full_grid := false
var highlighted: CrosswordEntry
var isolated: Array[CrosswordEntry] = []
var conflicts: Array[Vector2i] = []


func _draw() -> void:
	if data == null or not data.is_generated():
		var msg := "Aucun mot croisé ouvert." if data == null else "Grille non générée : clique sur « Régénérer la grille »."
		draw_string(get_theme_default_font(), Vector2(20, 40), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.6))
		return
	var cs := floorf(minf((size.x - 20) / data.grid_width, (size.y - 20) / data.grid_height))
	cs = clampf(cs, 8, 64)
	var origin := (size - Vector2(data.grid_width, data.grid_height) * cs) / 2
	var font := get_theme_default_font()

	if full_grid:
		for x in data.grid_width:
			for y in data.grid_height:
				draw_rect(Rect2(origin + Vector2(x, y) * cs + Vector2.ONE, Vector2(cs - 2, cs - 2)), COLOR_EMPTY)

	var letters := {}
	var colors := {}
	var numbers := {}
	for e in data.get_placed_entries():
		var c := COLOR_CELL
		if e == highlighted:
			c = COLOR_HIGHLIGHT
		elif e in isolated:
			c = COLOR_ISOLATED
		for k in e.answer.length():
			var p := Vector2i(e.x + k, e.y) if e.horizontal else Vector2i(e.x, e.y + k)
			letters[p] = e.answer[k]
			if not colors.has(p) or c != COLOR_CELL:
				colors[p] = c
			if k == 0:
				numbers[p] = e.number
	for p: Vector2i in conflicts:
		colors[p] = COLOR_CONFLICT

	for p: Vector2i in letters:
		var r := Rect2(origin + Vector2(p) * cs + Vector2.ONE, Vector2(cs - 2, cs - 2))
		draw_rect(r, colors[p])
		var fs := int(cs * 0.55)
		var w := font.get_string_size(letters[p], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, r.position + Vector2((r.size.x - w) / 2, r.size.y * 0.72), letters[p], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("101a4a"))
		if numbers.has(p) and cs >= 18:
			draw_string(font, r.position + Vector2(2, cs * 0.28), str(numbers[p]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(cs * 0.24), Color(0.1, 0.1, 0.35, 0.8))
