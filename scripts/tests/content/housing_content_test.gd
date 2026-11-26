extends GdUnitTestSuite

const GAME_DATA_PATH := "res://data/game_data.tres"

var _catalog: HousingCatalog


func before() -> void:
	_catalog = HousingCatalog.new(load(GAME_DATA_PATH))


func test_every_item_word_appears_in_a_level_of_its_subject() -> void:
	var unreachable: Array[String] = []
	for subject_key in _catalog.subject_keys():
		for item in _catalog.items(subject_key):
			if _catalog.levels_with(item).is_empty():
				unreachable.append(HousingCatalog.item_id(subject_key, item))
	assert_array(unreachable).is_empty()


func test_items_of_a_room_have_different_words() -> void:
	var duplicates: Array[String] = []
	for subject_key in _catalog.subject_keys():
		var seen: Array[String] = []
		for item in _catalog.items(subject_key):
			var id := HousingCatalog.item_id(subject_key, item)
			if seen.has(id):
				duplicates.append(id)
			seen.append(id)
	assert_array(duplicates).is_empty()


func test_every_item_fits_in_its_room() -> void:
	var too_big: Array[String] = []
	for subject_key in _catalog.subject_keys():
		var room := _catalog.room(subject_key)
		for item in room.items:
			if item.footprint.x > room.grid_size.x or item.footprint.y > room.grid_size.y:
				too_big.append(HousingCatalog.item_id(subject_key, item))
	assert_array(too_big).is_empty()


func test_every_item_has_a_model() -> void:
	var missing: Array[String] = []
	for subject_key in _catalog.subject_keys():
		for item in _catalog.items(subject_key):
			if item.model != null:
				continue
			var model := ChemistryModels.build(TextUtil.to_answer(item.word))
			if model == null:
				missing.append(HousingCatalog.item_id(subject_key, item))
			else:
				model.free()
	assert_array(missing).is_empty()
