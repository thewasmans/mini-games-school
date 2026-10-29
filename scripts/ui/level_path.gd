class_name LevelPath
extends Control

signal level_pressed(index: int)

const COLUMNS := 3
const ROW_HEIGHT := 250.0
const MARGIN_TOP := 330.0
const MARGIN_BOTTOM := 340.0
const CASTLE_SCALE := 62.0

var nodes: Array[LevelNode] = []
var unlock_glow := 1.0
var unlock_index := -1

var _t := 0.0
var _needed_height := 0.0
var _all_done := false


@export var level_node_prefab: PackedScene


func _ready() -> void:
	resized.connect(_layout)


func build(levels: Array[LevelData], game_state: GameState) -> void:
	for node in nodes:
		remove_child(node)
		node.queue_free()
	nodes.clear()
	unlock_index = -1
	unlock_glow = 1.0
	var rows := ceili(levels.size() / float(COLUMNS))
	_needed_height = MARGIN_TOP + MARGIN_BOTTOM + maxi(rows - 1, 0) * ROW_HEIGHT
	custom_minimum_size.y = _needed_height
	var completed_count := 0
	for level_index in levels.size():
		var mini_game := levels[level_index].mini_game
		var node := level_node_prefab.instantiate() as LevelNode
		node.setup(level_index, mini_game.theme_title if mini_game.theme_title != "" else mini_game.get_kind_name(), mini_game.get_kind_id())
		if not game_state.is_level_unlocked(level_index):
			node.state = LevelNode.State.LOCKED
		elif level_index == game_state.current_level:
			node.state = LevelNode.State.CURRENT
		elif game_state.is_level_completed(level_index):
			node.state = LevelNode.State.DONE
		else:
			node.state = LevelNode.State.OPEN
		if game_state.is_level_completed(level_index):
			completed_count += 1
		node.pressed.connect(level_pressed.emit.bind(level_index))
		add_child(node)
		nodes.append(node)
	_all_done = levels.size() > 0 and completed_count >= levels.size()
	_layout()


func prepare_unlock(level_index: int) -> void:
	nodes[level_index].state = LevelNode.State.LOCKED
	unlock_index = level_index
	unlock_glow = 0.0


func fit_height(visible_height: float) -> void:
	custom_minimum_size.y = maxf(_needed_height, visible_height)


func node_center(i: int) -> Vector2:
	var row := i / COLUMNS
	var col := i % COLUMNS
	if row % 2 == 1:
		col = COLUMNS - 1 - col
	var xs: Array[float] = [0.2, 0.5, 0.8]
	var y := size.y - MARGIN_BOTTOM - row * ROW_HEIGHT
	y -= (col - 1) * 30.0 * (1 if row % 2 == 0 else -1)
	return Vector2(size.x * xs[col], y)


func _anchor(i: int) -> Vector2:
	if i < 0:
		return Vector2(size.x * 0.42, size.y - MARGIN_BOTTOM + 215)
	if i >= nodes.size():
		var last := node_center(nodes.size() - 1)
		return Vector2(lerpf(last.x, size.x * 0.5, 0.6), last.y - 230)
	return node_center(i)


func _layout() -> void:
	for i in nodes.size():
		nodes[i].position = node_center(i) - LevelNode.NODE_SIZE / 2
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if nodes.is_empty():
		return
	for i in range(-1, nodes.size()):
		var a := _anchor(i)
		var b := _anchor(i + 1)
		var pts := _curve(a, b, 40.0 if (i + 2) % 2 == 0 else -40.0)
		var lit: bool
		if i + 1 >= nodes.size():
			lit = _all_done
		else:
			lit = nodes[i + 1].state != LevelNode.State.LOCKED
		draw_polyline(pts, Color(0.02, 0.05, 0.2, 0.45), 22, true)
		draw_polyline(pts, Color(0.55, 0.75, 1.0, 0.35), 8, true)
		if i + 1 == unlock_index:
			_draw_glow(pts, unlock_glow)
		elif lit:
			_draw_glow(pts, 1.0)

	var start := _anchor(-1) + Vector2(0, sin(_t * 1.2) * 5)
	var end := _anchor(nodes.size()) + Vector2(0, sin(_t * 1.2 + 1.5) * 5)
	if _all_done:
		draw_circle(end + Vector2(0, -40), 130, Color(1, 0.9, 0.4, 0.12 + 0.06 * sin(_t * 3.0)))
	if has_theme_icon("castle_start", "LevelPath") and has_theme_icon("castle_end", "LevelPath"):
		UISkin.draw_fit(self, get_theme_icon("castle_start", "LevelPath"), start + Vector2(0, -50), 190)
		UISkin.draw_fit(self, get_theme_icon("castle_end", "LevelPath"), end + Vector2(0, -50), 210, Color.WHITE if _all_done else Color(0.75, 0.75, 0.85))
	else:
		UIDraw.castle_island(self, start, CASTLE_SCALE, Color("3b6fd8"))
		UIDraw.castle_island(self, end, CASTLE_SCALE, Color("6b4fa8"), not _all_done)


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
	draw_polyline(part, Color(0.3, 0.85, 1.0, 0.18 * pulse), 34, true)
	draw_polyline(part, Color(0.4, 0.9, 1.0, 0.35), 20, true)
	draw_polyline(part, Color("7ff0ff"), 10, true)
	draw_polyline(part, Color(1, 1, 1, 0.9), 4, true)
	var k := int(fposmod(_t * 0.6, 1.0) * (part.size() - 1))
	UIDraw.sparkle(self, part[k], 9.0, Color(1, 1, 1, 0.9))


func play_unlock(i: int) -> void:
	if i < 0 or i >= nodes.size():
		return
	unlock_index = i
	unlock_glow = 0.0
	var tw := create_tween()
	tw.tween_property(self, "unlock_glow", 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_delay(0.3)
	nodes[i].play_unlock()
