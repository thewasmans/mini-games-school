class_name LevelMap
extends Control

signal level_pressed(level_index: int)
signal island_pressed(island_index: int)

const PATH_STONES := 4
const ISLAND_PATH_STONES := 2

@export var camera: Camera3D
@export var world: Node3D
@export var markers_root: Control
@export var level_marker_prefab: PackedScene
@export var island_marker_prefab: PackedScene

@export_group("Réglages")
## Distance entre deux levels le long du chemin, en mètres.
@export var level_spacing := 4.5
## Écart latéral du chemin de part et d'autre du centre, en mètres.
@export var path_width := 2.2
## Hauteur de la caméra au-dessus des îles, en mètres.
@export var camera_height := 12.0
## Recul de la caméra derrière le level visé, en mètres.
@export var camera_distance := 7.0
## Distance devant le level visé où regarde la caméra, en mètres.
@export var focus_ahead := 2.0
## Distance latérale entre une île bonus et le chemin, en mètres.
@export var bonus_island_offset := 3.4
## Hauteur des marqueurs au-dessus des îles, en mètres.
@export var marker_height := 1.7
## Défilement par cran de molette, en mètres.
@export var wheel_step := 1.5
## Défilement par pixel glissé, en mètres.
@export var drag_speed := 0.03
## Déplacement en pixels au-delà duquel un appui devient un glissement.
@export var drag_threshold := 14.0
## Couleur des plateformes, dans l'ordre : verrouillé, ouvert, en cours, terminé.
@export var platform_colors: Array[Color] = [Color("8f88b8"), Color("4fb6ff"), Color("7ff0ff"), Color("ffc53d")]
## Couleur des pierres d'un chemin pas encore ouvert.
@export var stone_color := Color("6e6a8e")
## Couleur des pierres d'un chemin ouvert.
@export var lit_stone_color := Color("ffe27a")
## Nombre de nuages sous les îles, pour 10 mètres de chemin.
@export var clouds_per_ten_meters := 2.0

var level_markers: Array[LevelMarker] = []
var island_markers: Array[BonusIslandMarker] = []

var _content: Node3D
var _level_islands: Array[Node3D] = []
var _platforms: Array[MeshInstance3D] = []
var _bonus_islands: Array[Node3D] = []
var _bonus_sparkles: Array[Node3D] = []
var _level_paths: Array[Array] = []
var _island_paths: Array[Array] = []
var _anchors: Array[Dictionary] = []
var _floaters: Array[Dictionary] = []
var _platform_meshes: Array[ArrayMesh] = []
var _stone_mesh: ArrayMesh
var _lit_stone_mesh: ArrayMesh
var _camera_z := 0.0
var _target_z := 0.0
var _min_z := 0.0
var _max_z := 0.0
var _press_position := Vector2.ZERO
var _pressing := false
var _dragging := false
var _t := 0.0


func _ready() -> void:
	for color in platform_colors:
		_platform_meshes.append(LowPoly.flat(LowPoly.cylinder(0.78, 0.86, 0.2, 10), color, Vector3.ONE * 0.02, 3.0))
	_stone_mesh = LowPoly.flat(LowPoly.sphere(0.2, 5, 3), stone_color, Vector3.ONE * 0.03, 5.0)
	_lit_stone_mesh = LowPoly.flat(LowPoly.sphere(0.2, 5, 3), lit_stone_color, Vector3.ONE * 0.03, 5.0, Color(0, 0, 0, 0), 0.0)
	visibility_changed.connect(func() -> void: set_process(is_visible_in_tree()))


func build(levels: Array[LevelData], game_state: GameState) -> void:
	_clear()
	_content = Node3D.new()
	world.add_child(_content)
	var start := _add_floater(LowPoly.island(1.8, 90.0, 2), Vector3(_level_x(-1), 0, level_spacing))
	var house := LowPoly.house()
	house.scale = Vector3.ONE * 0.75
	house.position = Vector3(0.2, 0.25, -0.1)
	start.add_child(house)

	for level_index in levels.size():
		var island := _add_floater(LowPoly.island(1.25, 20.0 + level_index * 1.7, 0), _level_position(level_index))
		var tree_angle := level_index * 2.3
		island.add_child(LowPoly.tree(0.6, level_index, Vector3(cos(tree_angle) * 1.0, 0.15, sin(tree_angle) * 1.0)))
		var platform := LowPoly.part(_platform_meshes[0], Vector3(0, 0.25, 0))
		island.add_child(platform)
		_level_islands.append(island)
		_platforms.append(platform)
		var previous := _level_position(level_index - 1) if level_index > 0 else start.position
		_level_paths.append(_add_path(previous, island.position, PATH_STONES))
		var mini_game := levels[level_index].mini_game
		var marker := _add_marker(level_marker_prefab, island) as LevelMarker
		marker.setup(level_index, mini_game.theme_title if mini_game.theme_title != "" else mini_game.get_kind_name(), mini_game.get_kind_id(), game_state.level_stars(level_index))
		level_markers.append(marker)

	var end_z := _level_position(levels.size() - 1).z - level_spacing * 1.3 if not levels.is_empty() else -level_spacing
	var end := _add_floater(LowPoly.island(2.2, 91.0, 3), Vector3(0, 0, end_z))
	var castle := LowPoly.castle()
	castle.scale = Vector3.ONE * 0.5
	castle.position = Vector3(0, 0.25, 0)
	end.add_child(castle)
	if not levels.is_empty():
		_level_paths.append(_add_path(_level_position(levels.size() - 1), end.position, PATH_STONES))

	for island_index in game_state.island_count:
		_add_bonus_island(island_index, game_state)
	_add_clouds(level_spacing * 3.0, end_z - level_spacing * 4.0)

	_max_z = level_spacing * 0.5
	_min_z = end_z + level_spacing
	refresh(game_state)


func refresh(game_state: GameState) -> void:
	var all_done := not level_markers.is_empty()
	for level_index in level_markers.size():
		var state := _state_of(level_index, game_state)
		level_markers[level_index].state = state
		_set_platform(level_index, state)
		_light_path(_level_paths[level_index], state != LevelMarker.State.LOCKED)
		all_done = all_done and game_state.is_level_completed(level_index)
	if _level_paths.size() > level_markers.size():
		_light_path(_level_paths[-1], all_done)
	for island_index in island_markers.size():
		var reached := game_state.is_island_reached(island_index)
		var pending := game_state.island_reward(island_index) - game_state.island_claimed(island_index)
		var state := BonusIslandMarker.State.LOCKED if not reached else (BonusIslandMarker.State.READY if pending > 0 else BonusIslandMarker.State.CLAIMED)
		island_markers[island_index].setup(state, pending, game_state.island_claimed(island_index))
		_light_path(_island_paths[island_index], reached)
		_bonus_sparkles[island_index].visible = state == BonusIslandMarker.State.READY


func focus_level(level_index: int, instant := false) -> void:
	_target_z = clampf(_level_position(level_index).z, _min_z, _max_z)
	if instant:
		_camera_z = _target_z
		_update_camera()


func prepare_unlock(level_index: int) -> void:
	level_markers[level_index].state = LevelMarker.State.LOCKED
	_set_platform(level_index, LevelMarker.State.LOCKED)
	_light_path(_level_paths[level_index], false)


func play_unlock(level_index: int) -> void:
	if level_index < 0 or level_index >= level_markers.size():
		return
	var stones: Array = _level_paths[level_index]
	var tw := create_tween()
	for stone: MeshInstance3D in stones:
		tw.tween_callback(_light_stone.bind(stone))
		tw.tween_interval(0.09)
	level_markers[level_index].play_unlock()
	tw.tween_interval(0.7)
	tw.tween_callback(func() -> void:
		_set_platform(level_index, LevelMarker.State.CURRENT)
		_bounce(_level_islands[level_index]))


func celebrate_island(island_index: int, gained: int) -> void:
	island_markers[island_index].celebrate(gained)
	_bounce(_bonus_islands[island_index])


func _clear() -> void:
	if _content != null:
		_content.queue_free()
		_content = null
	for marker in markers_root.get_children():
		marker.queue_free()
	level_markers.clear()
	island_markers.clear()
	_level_islands.clear()
	_platforms.clear()
	_bonus_islands.clear()
	_bonus_sparkles.clear()
	_level_paths.clear()
	_island_paths.clear()
	_anchors.clear()
	_floaters.clear()


func _level_x(level_index: int) -> float:
	return sin(level_index * 1.1) * path_width


func _level_position(level_index: int) -> Vector3:
	return Vector3(_level_x(level_index), 0, -level_index * level_spacing)


func _add_floater(node: Node3D, at: Vector3) -> Node3D:
	node.position = at
	_content.add_child(node)
	_floaters.append({"node": node, "base": at.y, "phase": at.z * 0.7})
	return node


func _add_bonus_island(island_index: int, game_state: GameState) -> void:
	var last_level: int = game_state.island_levels(island_index)[-1]
	var from := _level_position(last_level)
	var middle := (from + _level_position(last_level + 1)) / 2.0
	var side := 1.0 if middle.x <= 0.0 else -1.0
	var island := _add_floater(LowPoly.island(1.4, 60.0 + island_index, 1), Vector3(middle.x + side * bonus_island_offset, 0.3, middle.z))
	var castle := LowPoly.castle()
	castle.scale = Vector3.ONE * 0.32
	castle.position = Vector3(0, 0.18, 0)
	castle.rotation_degrees.y = -20.0 * side
	island.add_child(castle)
	var sparkles := Node3D.new()
	for k in 6:
		var sparkle := LowPoly.sparkle()
		var angle := TAU * k / 6.0
		sparkle.position = Vector3(cos(angle) * 1.6, 1.0 + (k % 2) * 0.8, sin(angle) * 1.6)
		sparkles.add_child(sparkle)
	island.add_child(sparkles)
	_bonus_islands.append(island)
	_bonus_sparkles.append(sparkles)
	_island_paths.append(_add_path(from, island.position, ISLAND_PATH_STONES))
	island_markers.append(_add_marker(island_marker_prefab, island) as BonusIslandMarker)


func _add_marker(prefab: PackedScene, island: Node3D) -> Control:
	var holder := Control.new()
	holder.mouse_filter = MOUSE_FILTER_IGNORE
	markers_root.add_child(holder)
	var marker := prefab.instantiate() as Control
	holder.add_child(marker)
	holder.size = marker.size
	holder.pivot_offset = marker.pivot_offset
	_anchors.append({"holder": holder, "marker": marker, "node": island})
	return marker


func _add_clouds(from_z: float, to_z: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for cloud_index in roundi((from_z - to_z) / 10.0 * clouds_per_ten_meters):
		var cloud := LowPoly.cloud(200.0 + cloud_index)
		var side := -1.0 if cloud_index % 2 == 0 else 1.0
		cloud.position = Vector3(side * rng.randf_range(7.0, 13.0), rng.randf_range(-7.0, -4.0), rng.randf_range(to_z, from_z))
		cloud.scale = Vector3.ONE * rng.randf_range(1.0, 1.8)
		_content.add_child(cloud)


func _add_path(from: Vector3, to: Vector3, stone_count: int) -> Array[MeshInstance3D]:
	var stones: Array[MeshInstance3D] = []
	var bend := (to - from).cross(Vector3.UP).normalized() * 0.5
	for stone_index in stone_count:
		var t := (stone_index + 1.0) / (stone_count + 1.0)
		var stone := LowPoly.part(_stone_mesh, from.lerp(to, t) + bend * sin(t * PI) + Vector3(0, 0.15, 0), false)
		_content.add_child(stone)
		stones.append(stone)
	return stones


func _light_path(stones: Array, lit: bool) -> void:
	for stone: MeshInstance3D in stones:
		stone.mesh = _lit_stone_mesh if lit else _stone_mesh
		stone.material_override = LowPoly.glow_material() if lit else LowPoly.material()


func _light_stone(stone: MeshInstance3D) -> void:
	_light_path([stone], true)
	stone.scale = Vector3.ONE * 1.8
	create_tween().tween_property(stone, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _set_platform(level_index: int, state: LevelMarker.State) -> void:
	_platforms[level_index].mesh = _platform_meshes[state]


func _bounce(node: Node3D) -> void:
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector3.ONE * 1.25, 0.12)
	tw.tween_property(node, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _state_of(level_index: int, game_state: GameState) -> LevelMarker.State:
	if not game_state.is_level_unlocked(level_index):
		return LevelMarker.State.LOCKED
	if game_state.is_level_completed(level_index):
		return LevelMarker.State.DONE
	if level_index == game_state.current_level:
		return LevelMarker.State.CURRENT
	return LevelMarker.State.OPEN


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		match button.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_scroll_by(-wheel_step)
			MOUSE_BUTTON_WHEEL_DOWN:
				_scroll_by(wheel_step)
			MOUSE_BUTTON_LEFT:
				if button.pressed:
					_pressing = true
					_dragging = false
					_press_position = button.position
				elif _pressing:
					_pressing = false
					if not _dragging:
						_click(button.position)
		accept_event()
	elif event is InputEventMouseMotion and _pressing:
		var motion := event as InputEventMouseMotion
		if not _dragging and motion.position.distance_to(_press_position) > drag_threshold:
			_dragging = true
		if _dragging:
			_scroll_by(-motion.relative.y * drag_speed)
		accept_event()


func _scroll_by(meters: float) -> void:
	_target_z = clampf(_target_z + meters, _min_z, _max_z)


func _click(at: Vector2) -> void:
	var best := {}
	for anchor in _anchors:
		var holder: Control = anchor.holder
		var visual_rect := Rect2(holder.position + holder.pivot_offset * (Vector2.ONE - holder.scale), holder.size * holder.scale)
		if holder.visible and visual_rect.has_point(at) and (best.is_empty() or holder.scale.x > best.holder.scale.x):
			best = anchor
	if best.is_empty():
		return
	if best.marker is BonusIslandMarker:
		island_pressed.emit(island_markers.find(best.marker))
	else:
		(best.marker as LevelMarker).punch()
		level_pressed.emit(level_markers.find(best.marker))


func _process(delta: float) -> void:
	_t += delta
	_camera_z = lerpf(_camera_z, _target_z, 1.0 - exp(-delta * 8.0))
	_update_camera()
	for floater in _floaters:
		var node: Node3D = floater.node
		node.position.y = floater.base + sin(_t * 1.4 + floater.phase) * 0.12
	for sparkles in _bonus_sparkles:
		sparkles.rotation.y += delta * 0.8
	_place_markers()


func _update_camera() -> void:
	camera.position = Vector3(0, camera_height, _camera_z + camera_distance)
	camera.look_at(Vector3(0, 0, _camera_z - focus_ahead))


func _place_markers() -> void:
	var reference_depth := Vector2(camera_height, camera_distance + focus_ahead).length()
	for anchor in _anchors:
		var holder: Control = anchor.holder
		var node: Node3D = anchor.node
		var point := node.position + Vector3(0, marker_height, 0)
		if camera.is_position_behind(point):
			holder.hide()
			continue
		holder.show()
		holder.scale = Vector2.ONE * clampf(reference_depth / camera.position.distance_to(point), 0.5, 1.15)
		holder.position = camera.unproject_position(point) - holder.pivot_offset
