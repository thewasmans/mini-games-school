extends GdUnitTestSuite

var _key := TestData.housing_subject_key()


func _catalog_with(items: Array[HousingItemData], level_words: Array) -> HousingCatalog:
	var data := TestData.game_data([level_words.size(), 2])
	var subject := data.secondary_4.subjects[0]
	for level_index in level_words.size():
		if not level_words[level_index] is Array:
			subject.levels[level_index].mini_game = null
			continue
		var words: Array[String] = []
		words.assign(level_words[level_index])
		subject.levels[level_index].mini_game = TestData.memo_about(words)
	var room := HousingRoomData.new()
	room.items = items
	subject.housing_room = room
	return HousingCatalog.new(data)


func test_only_subjects_with_a_room_are_listed() -> void:
	var catalog := _catalog_with([TestData.housing_item("MOLE")], [["MOLE"]])
	assert_array(catalog.subject_keys()).contains_exactly([_key])
	var other := Vector3i(TestData.SECONDARY, TestData.FOURTH_YEAR, 1)
	assert_object(catalog.room(other)).is_null()
	assert_array(catalog.items(other)).is_empty()


func test_levels_without_mini_game_are_ignored() -> void:
	var mole := TestData.housing_item("MOLE")
	var catalog := _catalog_with([mole], [["MOLE"], null, ["MOLE"]])
	assert_array(catalog.levels_with(mole)).contains_exactly([0, 2])
	assert_int(catalog.gauge_size(mole)).is_equal(20)


func test_gauge_size_stops_growing_after_the_counted_levels() -> void:
	var mole := TestData.housing_item("MOLE")
	var catalog := _catalog_with([mole], [["MOLE"], ["MOLE"], ["MOLE"], ["MOLE"], ["MOLE"]])
	assert_int(catalog.gauge_size(mole)).is_equal(HousingCatalog.POINTS_PER_LEVEL * HousingCatalog.MAX_COUNTED_LEVELS)


func test_ids_are_normalized() -> void:
	var item := TestData.housing_item("Densité")
	assert_str(HousingCatalog.item_id(_key, item)).is_equal("%d/%d/0/DENSITE" % [TestData.SECONDARY, TestData.FOURTH_YEAR])
	assert_str(HousingCatalog.subject_id(_key)).is_equal("%d/%d/0" % [TestData.SECONDARY, TestData.FOURTH_YEAR])


func test_item_matches_its_word_and_variants() -> void:
	var item := TestData.housing_item("Mole")
	item.variants = PackedStringArray(["molés"])
	assert_array(Array(item.matching_words())).contains_exactly(["MOLE", "MOLES"])


func test_item_cells_follow_its_footprint() -> void:
	var item := TestData.housing_item("AQUEUSE", Vector2i(2, 1))
	assert_array(item.cells_at(Vector2i(1, 2))).contains_exactly([Vector2i(1, 2), Vector2i(2, 2)])
