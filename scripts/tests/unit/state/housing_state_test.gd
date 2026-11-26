extends GdUnitTestSuite

const DAY := 24 * 3600

var _key := TestData.housing_subject_key()


func _unlocked_state(items: Array[HousingItemData], action_points := 10, grid_size := Vector2i(4, 4)) -> HousingState:
	var words: Array[String] = []
	for item in items:
		words.append(item.word)
	var state := TestData.housing_state([words], items, grid_size)
	var word_points: Dictionary[String, int] = {}
	for word in words:
		word_points[word] = 10
	state.record_encounters(_key, 0, word_points)
	state.action_points = action_points
	return state


func _points(word: String, points: int) -> Dictionary[String, int]:
	var word_points: Dictionary[String, int] = {}
	word_points[word] = points
	return word_points


func test_gauge_size_grows_with_the_levels_that_contain_the_word() -> void:
	var rare := TestData.housing_item("CNTP")
	var common := TestData.housing_item("MOLE")
	var absent := TestData.housing_item("ISOTOPE")
	var state := TestData.housing_state([["MOLE", "CNTP"], ["MOLE"], ["MOLE"], ["MOLE"]], [rare, common, absent])
	assert_int(state.catalog.gauge_size(rare)).is_equal(10)
	assert_int(state.catalog.gauge_size(common)).is_equal(30)
	assert_int(state.catalog.gauge_size(absent)).is_equal(0)
	assert_array(state.catalog.levels_with(common)).contains_exactly([0, 1, 2, 3])


func test_replaying_the_same_level_keeps_only_the_best_encounter() -> void:
	var mole := TestData.housing_item("MOLE")
	var state := TestData.housing_state([["MOLE"], ["MOLE"], ["MOLE"]], [mole])
	state.record_encounters(_key, 0, _points("MOLE", 5))
	state.record_encounters(_key, 0, _points("MOLE", 10))
	state.record_encounters(_key, 0, _points("MOLE", 10))
	state.record_encounters(_key, 0, _points("MOLE", 2))
	assert_that(state.gauge(_key, mole)).is_equal(Vector2i(10, 30))
	assert_bool(state.is_unlocked(_key, mole)).is_false()


func test_encounters_in_different_levels_unlock_the_item() -> void:
	var mole := TestData.housing_item("MOLE")
	var state := TestData.housing_state([["MOLE"], ["MOLE"], ["MOLE"]], [mole])
	monitor_signals(state, false)
	state.record_encounters(_key, 0, _points("MOLE", 10))
	state.record_encounters(_key, 1, _points("MOLE", 10))
	var progress := state.record_encounters(_key, 2, _points("MOLE", 10))
	assert_bool(state.is_unlocked(_key, mole)).is_true()
	assert_int(state.unlocked_count(_key)).is_equal(1)
	assert_int(progress[0]["before"]).is_equal(20)
	assert_int(progress[0]["after"]).is_equal(30)
	@warning_ignore("redundant_await")
	await assert_signal(state).is_emitted("item_unlocked", _key, mole)


func test_a_variant_of_the_word_counts_as_an_encounter() -> void:
	var mole := TestData.housing_item("Mole")
	mole.variants = PackedStringArray(["moles"])
	var state := TestData.housing_state([["MOLES"]], [mole])
	assert_int(state.catalog.gauge_size(mole)).is_equal(10)
	state.record_encounters(_key, 0, _points("MOLES", 10))
	assert_bool(state.is_unlocked(_key, mole)).is_true()


func test_first_completion_and_new_stars_give_action_points() -> void:
	var state := TestData.housing_state([["MOLE"]], [])
	assert_int(state.record_level_result(_key, 0, true, 3, 3.0, 0)).is_equal(5)
	assert_int(state.action_points).is_equal(5)


func test_replaying_always_rewards_revision_when_at_least_one_star_is_earned() -> void:
	var state := TestData.housing_state([["MOLE"]], [])
	state.record_level_result(_key, 0, true, 1, 1.0, 0)
	assert_int(state.record_level_result(_key, 0, false, 0, 1.0, DAY)).is_equal(1)
	assert_int(state.record_level_result(_key, 0, false, 1, 2.0, 2 * DAY)).is_equal(2)
	assert_int(state.record_level_result(_key, 0, false, 0, 2.0, 10 * DAY)).is_equal(2)
	assert_int(state.record_level_result(_key, 0, false, 0, 0.0, 30 * DAY)).is_equal(0)


func test_placing_needs_an_unlocked_item_and_action_points() -> void:
	var mole := TestData.housing_item("MOLE")
	var locked := TestData.housing_state([["MOLE"]], [mole])
	locked.action_points = 5
	assert_bool(locked.place_item(_key, mole, Vector2i.ZERO)).is_false()
	var broke := _unlocked_state([mole], 0)
	assert_bool(broke.place_item(_key, mole, Vector2i.ZERO)).is_false()
	var state := _unlocked_state([mole], 1)
	assert_bool(state.place_item(_key, mole, Vector2i.ZERO)).is_true()
	assert_int(state.action_points).is_equal(0)
	assert_that(state.placed_cell(_key, mole)).is_equal(Vector2i.ZERO)


func test_items_cannot_overlap_or_leave_the_grid() -> void:
	var table := TestData.housing_item("MOLE", Vector2i(2, 2))
	var lamp := TestData.housing_item("DENSITE")
	var chandelier := TestData.housing_item("TERNAIRE", Vector2i.ONE, HousingItemData.Slot.CEILING)
	var state := _unlocked_state([table, lamp, chandelier])
	assert_bool(state.place_item(_key, table, Vector2i(3, 3))).is_false()
	assert_bool(state.place_item(_key, table, Vector2i(0, 0))).is_true()
	assert_bool(state.place_item(_key, lamp, Vector2i(1, 1))).is_false()
	assert_bool(state.place_item(_key, lamp, Vector2i(2, 1))).is_true()
	assert_bool(state.place_item(_key, chandelier, Vector2i(1, 1))).is_true()


func test_removing_frees_the_place_and_costs_a_point() -> void:
	var table := TestData.housing_item("MOLE", Vector2i(2, 2))
	var lamp := TestData.housing_item("DENSITE")
	var state := _unlocked_state([table, lamp], 2)
	state.place_item(_key, table, Vector2i.ZERO)
	assert_bool(state.remove_item(_key, table)).is_true()
	assert_int(state.action_points).is_equal(0)
	assert_bool(state.is_placed(_key, table)).is_false()
	assert_bool(state.can_place(_key, lamp, Vector2i(1, 1))).is_true()


func test_an_item_can_move_onto_its_own_cells() -> void:
	var table := TestData.housing_item("MOLE", Vector2i(2, 2))
	var state := _unlocked_state([table], 2)
	state.place_item(_key, table, Vector2i.ZERO)
	assert_bool(state.move_item(_key, table, Vector2i(1, 0))).is_true()
	assert_that(state.placed_cell(_key, table)).is_equal(Vector2i(1, 0))


func test_damaged_cells_are_blocked_until_renovated() -> void:
	var lamp := TestData.housing_item("DENSITE")
	var state := _unlocked_state([lamp], 4)
	var renovation := HousingRenovationData.new()
	renovation.cost = 3
	renovation.cells = [Vector2i(0, 0)] as Array[Vector2i]
	state.catalog.room(_key).renovations.append(renovation)
	assert_bool(state.can_place(_key, lamp, Vector2i.ZERO)).is_false()
	assert_bool(state.renovate(_key, 0)).is_true()
	assert_int(state.action_points).is_equal(1)
	assert_bool(state.renovate(_key, 0)).is_false()
	assert_bool(state.can_place(_key, lamp, Vector2i.ZERO)).is_true()


func test_housing_survives_a_save_and_reload() -> void:
	var table := TestData.housing_item("MOLE", Vector2i(2, 2))
	var state := _unlocked_state([table], 3)
	state.place_item(_key, table, Vector2i(1, 2))
	state.record_level_result(_key, 0, true, 0, 0.0, 1000)
	var json := JSON.stringify(state.to_save_data())
	var loaded := TestData.housing_state([["MOLE"]], [table])
	loaded.load_save_data(JSON.parse_string(json))
	assert_int(loaded.action_points).is_equal(state.action_points)
	assert_bool(loaded.is_unlocked(_key, table)).is_true()
	assert_that(loaded.placed_cell(_key, table)).is_equal(Vector2i(1, 2))
	assert_int(loaded.record_level_result(_key, 0, false, 0, 1.0, 1000 + DAY)).is_equal(1)


func test_unlock_all_fills_every_gauge_and_adds_points() -> void:
	var mole := TestData.housing_item("MOLE")
	var cntp := TestData.housing_item("CNTP")
	var state := TestData.housing_state([["MOLE"], ["MOLE", "CNTP"]], [mole, cntp])
	state.unlock_all(50)
	assert_bool(state.is_unlocked(_key, mole)).is_true()
	assert_bool(state.is_unlocked(_key, cntp)).is_true()
	assert_int(state.action_points).is_equal(50)


func test_level_to_play_points_to_a_level_that_can_still_fill_the_gauge() -> void:
	var mole := TestData.housing_item("MOLE")
	var absent := TestData.housing_item("CNTP")
	var state := TestData.housing_state([["MOLE"], ["MOLE"], ["MOLE"]], [mole, absent])
	assert_int(state.level_to_play(_key, mole)).is_equal(0)
	state.record_encounters(_key, 0, _points("MOLE", 10))
	state.record_encounters(_key, 1, _points("MOLE", 5))
	assert_int(state.level_to_play(_key, mole)).is_equal(1)
	state.record_encounters(_key, 1, _points("MOLE", 10))
	state.record_encounters(_key, 2, _points("MOLE", 10))
	assert_int(state.level_to_play(_key, mole)).is_equal(0)
	assert_int(state.level_to_play(_key, absent)).is_equal(-1)


func test_an_item_is_announced_only_once() -> void:
	var mole := TestData.housing_item("MOLE")
	var state := TestData.housing_state([["MOLE"], ["MOLE"]], [mole])
	var unlocks := [0]
	state.item_unlocked.connect(func(_subject_key: Vector3i, _item: HousingItemData) -> void: unlocks[0] += 1)
	state.record_encounters(_key, 0, _points("MOLE", 10))
	state.record_encounters(_key, 1, _points("MOLE", 10))
	state.record_encounters(_key, 1, _points("MOLE", 10))
	state.record_encounters(_key, 0, _points("MOLE", 10))
	assert_int(unlocks[0]).is_equal(1)


func test_words_without_item_give_no_progress() -> void:
	var mole := TestData.housing_item("MOLE")
	var state := TestData.housing_state([["MOLE", "SEL"]], [mole])
	assert_array(state.record_encounters(_key, 0, _points("SEL", 10))).is_empty()
	assert_that(state.gauge(_key, mole)).is_equal(Vector2i(0, 10))


func test_wall_floor_and_ceiling_have_separate_cells() -> void:
	var lamp := TestData.housing_item("DENSITE")
	var portrait := TestData.housing_item("AVOGADRO", Vector2i.ONE, HousingItemData.Slot.WALL)
	var chandelier := TestData.housing_item("TERNAIRE", Vector2i.ONE, HousingItemData.Slot.CEILING)
	var state := _unlocked_state([lamp, portrait, chandelier])
	assert_bool(state.place_item(_key, lamp, Vector2i.ZERO)).is_true()
	assert_bool(state.place_item(_key, portrait, Vector2i.ZERO)).is_true()
	assert_bool(state.place_item(_key, chandelier, Vector2i.ZERO)).is_true()


func test_a_renovation_only_blocks_its_own_slot() -> void:
	var portrait := TestData.housing_item("AVOGADRO", Vector2i.ONE, HousingItemData.Slot.WALL)
	var lamp := TestData.housing_item("DENSITE")
	var state := _unlocked_state([portrait, lamp])
	var stain := HousingRenovationData.new()
	stain.slot = HousingItemData.Slot.WALL
	stain.cells = [Vector2i.ZERO] as Array[Vector2i]
	state.catalog.room(_key).renovations.append(stain)
	assert_bool(state.can_place(_key, portrait, Vector2i.ZERO)).is_false()
	assert_bool(state.can_place(_key, lamp, Vector2i.ZERO)).is_true()


func test_an_item_cannot_be_placed_twice() -> void:
	var lamp := TestData.housing_item("DENSITE")
	var state := _unlocked_state([lamp])
	assert_bool(state.place_item(_key, lamp, Vector2i.ZERO)).is_true()
	assert_bool(state.place_item(_key, lamp, Vector2i(2, 2))).is_false()
	assert_that(state.placed_cell(_key, lamp)).is_equal(Vector2i.ZERO)


func test_actions_without_enough_points_change_nothing() -> void:
	var lamp := TestData.housing_item("DENSITE")
	var state := _unlocked_state([lamp], 1)
	state.place_item(_key, lamp, Vector2i.ZERO)
	assert_bool(state.move_item(_key, lamp, Vector2i(2, 2))).is_false()
	assert_bool(state.remove_item(_key, lamp)).is_false()
	assert_that(state.placed_cell(_key, lamp)).is_equal(Vector2i.ZERO)
	assert_bool(state.remove_item(_key, TestData.housing_item("MOLE"))).is_false()


func test_spending_points_is_signaled() -> void:
	var lamp := TestData.housing_item("DENSITE")
	var state := _unlocked_state([lamp], 3)
	monitor_signals(state, false)
	state.place_item(_key, lamp, Vector2i.ZERO)
	@warning_ignore("redundant_await")
	await assert_signal(state).is_emitted("action_points_changed", 2)


func test_loading_an_empty_save_resets_the_house() -> void:
	var lamp := TestData.housing_item("DENSITE")
	var state := _unlocked_state([lamp], 3)
	state.place_item(_key, lamp, Vector2i.ZERO)
	state.load_save_data({})
	assert_int(state.action_points).is_equal(0)
	assert_bool(state.is_unlocked(_key, lamp)).is_false()
	assert_bool(state.is_placed(_key, lamp)).is_false()
