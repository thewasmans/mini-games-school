class_name LevelPath
extends Control
## Grille des levels : un chemin en serpent qui monte du bas vers le haut.

signal level_pressed(index: int)

const COLUMNS := 3
const ROW_HEIGHT := 230.0
const MARGIN_TOP := 150.0
const MARGIN_BOTTOM := 110.0

var nodes: Array[LevelNode] = []
## 0..1 : progression du tracé lumineux vers le level fraîchement débloqué.
var unlock_glow := 1.0
var unlock_index := -1

var _t := 0.0
var _needed_height := 0.0


func _init(levels: Array[LevelData], key: String) -> void:
	size_flags_horizontal = SIZE_EXPAND_FILL
	var rows := ceili(levels.size() / float(COLUMNS))
	_needed_height = MARGIN_TOP + MARGIN_BOTTOM + maxi(rows - 1, 0) * ROW_HEIGHT + LevelNode.NODE_SIZE.y
	custom_minimum_size = Vector2(0, _needed_height)
	var selected := GameState.get_selected(key)
	for i in levels.size():
		var mg := levels[i].mini_game
		var kind := "crossword" if mg is CrosswordData else ("memo" if mg is MemoData else "crypto")
		var title := mg.theme_title if mg.theme_title != "" else mg.get_kind_name()
		var node := LevelNode.new(i, title, kind)
		if not GameState.is_unlocked(key, i):
			node.state = LevelNode.State.LOCKED
		elif i == selected:
			node.state = LevelNode.State.CURRENT
		elif GameState.is_completed(key, i):
			node.state = LevelNode.State.DONE
		else:
			node.state = LevelNode.State.OPEN
		node.pressed.connect(func() -> void: level_pressed.emit(i))
		add_child(node)
		nodes.append(node)
	resized.connect(_layout)


## Le chemin part toujours du bas, même quand il y a peu de levels.
func fit_height(visible_height: float) -> void:
	custom_minimum_size.y = maxf(_needed_height, visible_height)


func node_center(i: int) -> Vector2:
	var row := i / COLUMNS
	var col := i % COLUMNS
	if row % 2 == 1:
		col = COLUMNS - 1 - col
	var xs: Array[float] = [0.2, 0.5, 0.8]
	var y := size.y - MARGIN_BOTTOM - LevelNode.NODE_SIZE.y / 2 - row * ROW_HEIGHT
	# Léger décalage vertical pour casser l'alignement
	y -= (col - 1) * 24.0 * (1 if row % 2 == 0 else -1)
	return Vector2(size.x * xs[col], y)


func _layout() -> void:
	for i in nodes.size():
		nodes[i].position = node_center(i) - LevelNode.NODE_SIZE / 2
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for i in nodes.size() - 1:
		var a := node_center(i)
		var b := node_center(i + 1)
		var pts := _curve(a, b, 18.0 if i % 2 == 0 else -18.0)
		var lit := nodes[i + 1].state != LevelNode.State.LOCKED
		draw_polyline(pts, Color(0.02, 0.05, 0.2, 0.6), 26, true)
		if lit and i + 1 != unlock_index:
			_draw_glow(pts, 1.0)
		elif i + 1 == unlock_index:
			_draw_dashes(pts)
			_draw_glow(pts, unlock_glow)
		else:
			_draw_dashes(pts)


func _curve(a: Vector2, b: Vector2, bend: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var perp := (b - a).orthogonal().normalized()
	for k in 25:
		var t := k / 24.0
		pts.append(a.lerp(b, t) + perp * sin(t * PI) * bend)
	return pts


func _draw_glow(pts: PackedVector2Array, amount: float) -> void:
	if amount <= 0.0:
		return
	var n := maxi(2, int(pts.size() * amount))
	var part := pts.slice(0, n)
	var pulse := 0.6 + 0.4 * sin(_t * 3.0)
	draw_polyline(part, Color(0.3, 0.9, 1.0, 0.25 * pulse), 30, true)
	draw_polyline(part, Color("6fe8ff"), 14, true)
	draw_polyline(part, Color(1, 1, 1, 0.8), 5, true)


func _draw_dashes(pts: PackedVector2Array) -> void:
	for k in range(0, pts.size() - 1, 2):
		draw_line(pts[k], pts[k + 1], Color(0.65, 0.7, 0.85, 0.7), 10, true)


## Anime le tracé et le cadenas du level qui vient d'être débloqué.
func play_unlock(i: int) -> void:
	if i < 0 or i >= nodes.size():
		return
	unlock_index = i
	unlock_glow = 0.0
	var tw := create_tween()
	tw.tween_property(self, "unlock_glow", 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_delay(0.3)
	nodes[i].play_unlock()
