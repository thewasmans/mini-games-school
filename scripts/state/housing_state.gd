class_name HousingState
extends RefCounted

signal changed
signal action_points_changed(action_points: int)
signal item_unlocked(subject_key: Vector3i, item: HousingItemData)

const FIRST_COMPLETION_POINTS := 2
const NEW_STAR_POINTS := 1
const REPLAY_POINTS := 1
const LATE_REPLAY_POINTS := 2
const LATE_REPLAY_DELAY := 7 * 24 * 3600
const PLACE_COST := 1
const REMOVE_COST := 1
const MOVE_COST := 1

var action_points := 0
var catalog: HousingCatalog

var _best_points: Dictionary[String, Dictionary] = {}
var _last_played: Dictionary[String, int] = {}
var _placements: Dictionary[String, Dictionary] = {}
var _renovated: Dictionary[String, bool] = {}


func _init(housing_catalog: HousingCatalog) -> void:
	catalog = housing_catalog


func record_level_result(subject_key: Vector3i, level_index: int, first_completion: bool, new_stars: int, stars: float, now: int) -> int:
	var level_id := "%s/%d" % [HousingCatalog.subject_id(subject_key), level_index]
	var gained := new_stars * NEW_STAR_POINTS
	if first_completion:
		gained += FIRST_COMPLETION_POINTS
	elif stars >= 1.0:
		var late := _last_played.has(level_id) and now - _last_played[level_id] >= LATE_REPLAY_DELAY
		gained += LATE_REPLAY_POINTS if late else REPLAY_POINTS
	_last_played[level_id] = now
	_add_action_points(gained)
	changed.emit()
	return gained


func record_encounters(subject_key: Vector3i, level_index: int, word_points: Dictionary[String, int]) -> Array[Dictionary]:
	var progress: Array[Dictionary] = []
	for item in catalog.items(subject_key):
		var points := -1
		for word in item.matching_words():
			points = maxi(points, word_points.get(word, -1))
		if points < 0:
			continue
		var before := gauge(subject_key, item)
		var best := _best_in(subject_key, item)
		best[level_index] = maxi(best.get(level_index, 0), points)
		var after := gauge(subject_key, item)
		progress.append({"item": item, "before": before.x, "after": after.x, "size": after.y})
		if before.x < before.y and after.x >= after.y:
			item_unlocked.emit(subject_key, item)
	changed.emit()
	return progress


func unlock_all(extra_action_points: int) -> void:
	for subject_key in catalog.subject_keys():
		for item in catalog.items(subject_key):
			var best := _best_in(subject_key, item)
			for level_index in catalog.levels_with(item):
				best[level_index] = HousingCatalog.POINTS_PER_LEVEL
	_add_action_points(extra_action_points)
	changed.emit()


func gauge(subject_key: Vector3i, item: HousingItemData) -> Vector2i:
	var size := catalog.gauge_size(item)
	var total := 0
	var best: Dictionary = _best_points.get(HousingCatalog.item_id(subject_key, item), {})
	for points: int in best.values():
		total += points
	return Vector2i(mini(total, size), size)


func level_to_play(subject_key: Vector3i, item: HousingItemData) -> int:
	var levels := catalog.levels_with(item)
	if levels.is_empty():
		return -1
	var best: Dictionary = _best_points.get(HousingCatalog.item_id(subject_key, item), {})
	for level_index in levels:
		if best.get(level_index, 0) < HousingCatalog.POINTS_PER_LEVEL:
			return level_index
	return levels[0]


func is_unlocked(subject_key: Vector3i, item: HousingItemData) -> bool:
	var value := gauge(subject_key, item)
	return value.y > 0 and value.x >= value.y


func unlocked_count(subject_key: Vector3i) -> int:
	var count := 0
	for item in catalog.items(subject_key):
		if is_unlocked(subject_key, item):
			count += 1
	return count


func is_placed(subject_key: Vector3i, item: HousingItemData) -> bool:
	return _room_placements(subject_key).has(_word(item))


func placed_cell(subject_key: Vector3i, item: HousingItemData) -> Vector2i:
	return _room_placements(subject_key).get(_word(item), Vector2i(-1, -1))


func is_renovated(subject_key: Vector3i, renovation_index: int) -> bool:
	return _renovated.has(_renovation_id(subject_key, renovation_index))


func can_place(subject_key: Vector3i, item: HousingItemData, origin: Vector2i, ignored: HousingItemData = null) -> bool:
	var room := catalog.room(subject_key)
	var taken := _taken_cells(subject_key, item.slot, ignored)
	for cell in item.cells_at(origin):
		if cell.x < 0 or cell.y < 0 or cell.x >= room.grid_size.x or cell.y >= room.grid_size.y:
			return false
		if taken.has(cell):
			return false
	return true


func place_item(subject_key: Vector3i, item: HousingItemData, origin: Vector2i) -> bool:
	if not is_unlocked(subject_key, item) or is_placed(subject_key, item) or action_points < PLACE_COST:
		return false
	if not can_place(subject_key, item, origin):
		return false
	_room_placements(subject_key)[_word(item)] = origin
	_spend(PLACE_COST)
	return true


func remove_item(subject_key: Vector3i, item: HousingItemData) -> bool:
	if not is_placed(subject_key, item) or action_points < REMOVE_COST:
		return false
	_room_placements(subject_key).erase(_word(item))
	_spend(REMOVE_COST)
	return true


func move_item(subject_key: Vector3i, item: HousingItemData, origin: Vector2i) -> bool:
	if not is_placed(subject_key, item) or action_points < MOVE_COST:
		return false
	if not can_place(subject_key, item, origin, item):
		return false
	_room_placements(subject_key)[_word(item)] = origin
	_spend(MOVE_COST)
	return true


func renovate(subject_key: Vector3i, renovation_index: int) -> bool:
	var renovations := catalog.room(subject_key).renovations
	if renovation_index < 0 or renovation_index >= renovations.size() or is_renovated(subject_key, renovation_index):
		return false
	var cost := renovations[renovation_index].cost
	if action_points < cost:
		return false
	_renovated[_renovation_id(subject_key, renovation_index)] = true
	_spend(cost)
	return true


func to_save_data() -> Dictionary:
	var best_points := {}
	for id: String in _best_points:
		var levels := {}
		for level_index: int in _best_points[id]:
			levels[str(level_index)] = _best_points[id][level_index]
		best_points[id] = levels
	var placements := {}
	for subject: String in _placements:
		var cells := {}
		for word: String in _placements[subject]:
			var cell: Vector2i = _placements[subject][word]
			cells[word] = [cell.x, cell.y]
		placements[subject] = cells
	return {
		"action_points": action_points,
		"best_points": best_points,
		"last_played": _last_played.duplicate(),
		"placements": placements,
		"renovated": _renovated.keys(),
	}


func load_save_data(data: Dictionary) -> void:
	action_points = int(data.get("action_points", 0))
	_best_points.clear()
	_last_played.clear()
	_placements.clear()
	_renovated.clear()
	var best_points: Dictionary = data.get("best_points", {})
	for id: String in best_points:
		var levels := {}
		for level_index: String in best_points[id]:
			levels[int(level_index)] = int(best_points[id][level_index])
		_best_points[id] = levels
	var last_played: Dictionary = data.get("last_played", {})
	for id: String in last_played:
		_last_played[id] = int(last_played[id])
	var placements: Dictionary = data.get("placements", {})
	for subject: String in placements:
		var cells := {}
		for word: String in placements[subject]:
			var raw: Array = placements[subject][word]
			cells[word] = Vector2i(int(raw[0]), int(raw[1]))
		_placements[subject] = cells
	for id: String in data.get("renovated", []):
		_renovated[id] = true


func _taken_cells(subject_key: Vector3i, slot: HousingItemData.Slot, ignored: HousingItemData) -> Dictionary[Vector2i, bool]:
	var taken: Dictionary[Vector2i, bool] = {}
	var room := catalog.room(subject_key)
	for renovation_index in room.renovations.size():
		var renovation := room.renovations[renovation_index]
		if renovation.slot == slot and not is_renovated(subject_key, renovation_index):
			for cell in renovation.cells:
				taken[cell] = true
	for item in room.items:
		if item == ignored or item.slot != slot or not is_placed(subject_key, item):
			continue
		for cell in item.cells_at(placed_cell(subject_key, item)):
			taken[cell] = true
	return taken


func _best_in(subject_key: Vector3i, item: HousingItemData) -> Dictionary:
	var id := HousingCatalog.item_id(subject_key, item)
	if not _best_points.has(id):
		_best_points[id] = {}
	return _best_points[id]


func _room_placements(subject_key: Vector3i) -> Dictionary:
	var id := HousingCatalog.subject_id(subject_key)
	if not _placements.has(id):
		_placements[id] = {}
	return _placements[id]


func _word(item: HousingItemData) -> String:
	return TextUtil.to_answer(item.word)


func _renovation_id(subject_key: Vector3i, renovation_index: int) -> String:
	return "%s/%d" % [HousingCatalog.subject_id(subject_key), renovation_index]


func _spend(cost: int) -> void:
	_add_action_points(-cost)
	changed.emit()


func _add_action_points(amount: int) -> void:
	if amount == 0:
		return
	action_points += amount
	action_points_changed.emit(action_points)
