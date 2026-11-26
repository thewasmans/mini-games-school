class_name HouseWorld
extends Node3D

const CELL := 1.0
const WALL_HEIGHT := 3.0
const WALL_THICKNESS := 0.3
const WALL_BASE := 0.6
const WALL_ROW_HEIGHT := 1.0
const CEILING_HEIGHT := 2.7
const DOOR_WIDTH := 1.6
const DOOR_HEIGHT := 2.2
const WALL_REACH := 1.8
const HALL_KEY := Vector3i(-1, -1, -1)
const HALL_SIZE := Vector2i(4, 6)
const CAMERA_BLOCKING_LAYER := 1
const PROPS_LAYER := 2
const SPAWN_DEPTH_RATIO := 0.6

var rooms: Array[Dictionary] = []

var _housing_state: HousingState
var _item_roots: Dictionary[Vector3i, Node3D] = {}
var _ghost: MeshInstance3D
var _ghost_item: HousingItemData
var _depth := 0.0


func build(housing_state: HousingState, open_keys: Array[Vector3i]) -> void:
	_housing_state = housing_state
	for child in get_children():
		child.queue_free()
	rooms.clear()
	_item_roots.clear()
	_ghost = null
	_ghost_item = null
	var keys: Array[Vector3i] = [HALL_KEY]
	keys.append_array(housing_state.catalog.subject_keys())
	_depth = HALL_SIZE.y * CELL
	for key in keys:
		if key != HALL_KEY:
			_depth = maxf(_depth, housing_state.catalog.room(key).grid_size.y * CELL)
	var x := 0.0
	for key in keys:
		var size := HALL_SIZE if key == HALL_KEY else housing_state.catalog.room(key).grid_size
		rooms.append({"key": key, "origin": Vector3(x, 0, 0), "size": size, "open": key == HALL_KEY or open_keys.has(key)})
		x += size.x * CELL + WALL_THICKNESS
	_build_base(x - WALL_THICKNESS)
	for index in rooms.size():
		_build_room(rooms[index], index)
	_build_side_wall(-WALL_THICKNESS, false, 0)
	for index in range(1, rooms.size()):
		var room: Dictionary = rooms[index]
		_build_side_wall(room.origin.x - WALL_THICKNESS, room.open, index)
	_build_side_wall(x - WALL_THICKNESS, false, rooms.size())
	for room in rooms:
		if room.key != HALL_KEY:
			refresh_room(room.key)


func room_of(key: Vector3i) -> Dictionary:
	for room in rooms:
		if room.key == key:
			return room
	return {}


func room_at(world_position: Vector3) -> Dictionary:
	for room in rooms:
		var local := world_position - (room.origin as Vector3)
		var size: Vector2i = room.size
		if local.x >= 0 and local.x < size.x * CELL and local.z >= -WALL_THICKNESS and local.z < _depth + 1.0:
			return room
	return {}


func spawn_position(key: Vector3i) -> Vector3:
	var room := room_of(key)
	if room.is_empty():
		room = rooms[0]
	var size: Vector2i = room.size
	return (room.origin as Vector3) + Vector3(size.x * CELL / 2, 0.1, size.y * CELL * SPAWN_DEPTH_RATIO)


func target_cell(room: Dictionary, item: HousingItemData, target: Vector3) -> Vector2i:
	var local := target - (room.origin as Vector3)
	var footprint := item.footprint if item != null else Vector2i.ONE
	var column := floori(local.x / CELL - (footprint.x - 1) / 2.0)
	if item != null and item.slot == HousingItemData.Slot.WALL:
		return Vector2i(column, 0) if local.z <= WALL_REACH else Vector2i(-100, -100)
	return Vector2i(column, floori(local.z / CELL - (footprint.y - 1) / 2.0))


func item_at(room: Dictionary, target: Vector3) -> HousingItemData:
	if room.is_empty() or room.key == HALL_KEY:
		return null
	var local := target - (room.origin as Vector3)
	var cell := Vector2i(floori(local.x / CELL), floori(local.z / CELL))
	var found: HousingItemData = null
	for item in _housing_state.catalog.items(room.key):
		if not _housing_state.is_placed(room.key, item):
			continue
		var origin := _housing_state.placed_cell(room.key, item)
		match item.slot:
			HousingItemData.Slot.FLOOR:
				if item.cells_at(origin).has(cell):
					return item
			HousingItemData.Slot.CEILING:
				if item.cells_at(origin).has(cell):
					found = item
			HousingItemData.Slot.WALL:
				if found == null and local.z <= WALL_REACH and cell.x >= origin.x and cell.x < origin.x + item.footprint.x:
					found = item
	return found


func renovation_at(room: Dictionary, target: Vector3) -> int:
	if room.is_empty() or room.key == HALL_KEY:
		return -1
	var local := target - (room.origin as Vector3)
	var cell := Vector2i(floori(local.x / CELL), floori(local.z / CELL))
	var renovations := _housing_state.catalog.room(room.key).renovations
	for index in renovations.size():
		if _housing_state.is_renovated(room.key, index):
			continue
		var renovation := renovations[index]
		if renovation.slot == HousingItemData.Slot.WALL:
			if local.z <= WALL_REACH and renovation.cells.any(func(c: Vector2i) -> bool: return c.x == cell.x):
				return index
		elif renovation.cells.has(cell):
			return index
	return -1


func item_position(room: Dictionary, item: HousingItemData, cell: Vector2i) -> Vector3:
	var origin: Vector3 = room.origin
	var center_x := (cell.x + item.footprint.x / 2.0) * CELL
	match item.slot:
		HousingItemData.Slot.WALL:
			return origin + Vector3(center_x, WALL_BASE + cell.y * WALL_ROW_HEIGHT, 0.06)
		HousingItemData.Slot.CEILING:
			return origin + Vector3(center_x, CEILING_HEIGHT, (cell.y + item.footprint.y / 2.0) * CELL)
	return origin + Vector3(center_x, 0, (cell.y + item.footprint.y / 2.0) * CELL)


func show_ghost(room: Dictionary, item: HousingItemData, cell: Vector2i, valid: bool) -> void:
	if _ghost_item != item:
		hide_ghost()
		_ghost = HouseModels.ghost(item)
		_ghost_item = item
		add_child(_ghost)
	var position_offset := Vector3.ZERO
	match item.slot:
		HousingItemData.Slot.FLOOR:
			position_offset = Vector3(0, 0.5, 0)
		HousingItemData.Slot.WALL:
			position_offset = Vector3(0, item.footprint.y * WALL_ROW_HEIGHT / 2, 0)
		HousingItemData.Slot.CEILING:
			position_offset = Vector3(0, -0.5, 0)
	_ghost.position = item_position(room, item, cell) + position_offset
	(_ghost.material_override as StandardMaterial3D).albedo_color = Color(0.45, 1, 0.5, 0.45) if valid else Color(1, 0.35, 0.4, 0.45)


func hide_ghost() -> void:
	if _ghost != null:
		_ghost.queue_free()
	_ghost = null
	_ghost_item = null


func refresh_room(key: Vector3i) -> void:
	var room := room_of(key)
	if room.is_empty() or key == HALL_KEY:
		return
	if _item_roots.has(key):
		_item_roots[key].queue_free()
	var root := Node3D.new()
	root.position = room.origin
	add_child(root)
	_item_roots[key] = root
	var room_data := _housing_state.catalog.room(key)
	for index in room_data.renovations.size():
		if _housing_state.is_renovated(key, index):
			continue
		var renovation := room_data.renovations[index]
		root.add_child(HouseModels.debris(renovation, index * 3.0))
		if renovation.slot == HousingItemData.Slot.FLOOR:
			for cell in renovation.cells:
				_add_collision(root, Vector3((cell.x + 0.5) * CELL, 0.5, (cell.y + 0.5) * CELL), Vector3(CELL, 1.0, CELL), PROPS_LAYER)
	for item in room_data.items:
		if not _housing_state.is_placed(key, item):
			continue
		var cell := _housing_state.placed_cell(key, item)
		var model := HouseModels.item(item)
		model.position = item_position(room, item, cell) - (room.origin as Vector3)
		root.add_child(model)
		if item.slot == HousingItemData.Slot.FLOOR:
			var size := Vector3(item.footprint.x * CELL - 0.1, 1.0, item.footprint.y * CELL - 0.1)
			_add_collision(root, model.position + Vector3(0, 0.5, 0), size, PROPS_LAYER)


func _build_base(width: float) -> void:
	var rock := LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(width + 1.6, 1.4, _depth + 2.0)), LowPoly.ROCK_TOP, Vector3.ONE * 0.08, 60.0, LowPoly.ROCK_BOTTOM, 0.1))
	rock.position = Vector3(width / 2, -0.8, _depth / 2 + 0.3)
	add_child(rock)
	for index in ceili(width / 3.0):
		var cone := LowPoly.part(LowPoly.flat(LowPoly.cylinder(1.3, 0.2, 2.4, 6), LowPoly.ROCK_BOTTOM, Vector3.ONE * 0.1, 61.0 + index))
		cone.position = Vector3(1.5 + index * 3.0, -2.6, _depth / 2 + sin(index * 1.7) * 1.2)
		add_child(cone)
	var grass := LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(width + 1.6, 0.12, 1.4)), LowPoly.GRASS, Vector3.ONE * 0.03, 62.0), Vector3(width / 2, -0.05, _depth + 0.6), false)
	add_child(grass)


func _build_room(room: Dictionary, index: int) -> void:
	var origin: Vector3 = room.origin
	var size: Vector2i = room.size
	var width := size.x * CELL
	var floor_color := HouseModels.FLOOR_WOOD if room.open else HouseModels.FLOOR_WOOD.darkened(0.35)
	add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(width, 0.2, _depth)), floor_color, Vector3(0.01, 0, 0.01), 70.0 + index, Color(0, 0, 0, 0), 0.08), origin + Vector3(width / 2, -0.1, _depth / 2), false))
	_add_collision(self, origin + Vector3(width / 2, -0.1, _depth / 2), Vector3(width, 0.2, _depth))
	var wall_color := HouseModels.WALL_PAPER if room.open else HouseModels.WALL_PAPER.darkened(0.3)
	add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(width + WALL_THICKNESS, WALL_HEIGHT, WALL_THICKNESS)), wall_color, Vector3.ZERO, 71.0 + index), origin + Vector3(width / 2, WALL_HEIGHT / 2, -WALL_THICKNESS / 2)))
	add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(width, 0.25, 0.06)), HouseModels.WALL_TRIM, Vector3.ZERO, 72.0 + index), origin + Vector3(width / 2, 0.12, 0.02), false))
	_add_collision(self, origin + Vector3(width / 2, WALL_HEIGHT / 2, -WALL_THICKNESS / 2), Vector3(width + WALL_THICKNESS, WALL_HEIGHT, WALL_THICKNESS))
	for post in ceili(width / CELL) + 1:
		add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(0.1, 0.6, 0.1)), LowPoly.WOOD, Vector3.ZERO, 73.0 + post), origin + Vector3(post * CELL, 0.3, _depth + 0.05)))
	add_child(LowPoly.part(LowPoly.flat(LowPoly.box(Vector3(width, 0.08, 0.12)), LowPoly.WOOD, Vector3.ZERO, 74.0 + index), origin + Vector3(width / 2, 0.58, _depth + 0.05)))
	_add_collision(self, origin + Vector3(width / 2, 0.75, _depth + 0.05), Vector3(width + WALL_THICKNESS, 1.5, 0.2), PROPS_LAYER)
	if room.key == HALL_KEY:
		var portrait := HouseModels.grandfather_portrait()
		portrait.position = origin + Vector3(width / 2, 1.7, 0.06)
		add_child(portrait)


func _build_side_wall(x: float, with_door: bool, index: int) -> void:
	var center_x := x + WALL_THICKNESS / 2
	var color := HouseModels.WALL_PAPER.darkened(0.08)
	if not with_door:
		_add_wall_block(Vector3(center_x, WALL_HEIGHT / 2, _depth / 2), Vector3(WALL_THICKNESS, WALL_HEIGHT, _depth), color, index)
		if index > 0 and index < rooms.size():
			var lock_node := HouseModels.lock_sign()
			lock_node.position = Vector3(center_x - WALL_THICKNESS, 1.5, _depth / 2)
			lock_node.rotation.y = PI / 2
			add_child(lock_node)
		return
	var side := (_depth - DOOR_WIDTH) / 2
	_add_wall_block(Vector3(center_x, WALL_HEIGHT / 2, side / 2), Vector3(WALL_THICKNESS, WALL_HEIGHT, side), color, index)
	_add_wall_block(Vector3(center_x, WALL_HEIGHT / 2, _depth - side / 2), Vector3(WALL_THICKNESS, WALL_HEIGHT, side), color, index + 0.5)
	var lintel_height := WALL_HEIGHT - DOOR_HEIGHT
	_add_wall_block(Vector3(center_x, DOOR_HEIGHT + lintel_height / 2, _depth / 2), Vector3(WALL_THICKNESS, lintel_height, DOOR_WIDTH), HouseModels.WALL_TRIM, index + 0.25)


func _add_wall_block(center: Vector3, size: Vector3, color: Color, noise_seed: float) -> void:
	add_child(LowPoly.part(LowPoly.flat(LowPoly.box(size), color, Vector3.ZERO, 80.0 + noise_seed), center))
	_add_collision(self, center, size)


func _add_collision(parent: Node3D, center: Vector3, size: Vector3, layer := CAMERA_BLOCKING_LAYER) -> void:
	var body := StaticBody3D.new()
	body.position = center
	body.collision_layer = 0
	body.set_collision_layer_value(layer, true)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)
