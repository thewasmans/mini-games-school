extends GdUnitTestSuite


func _round_trip(state: GameState) -> GameState:
	var json := JSON.stringify(state.to_save_data())
	var loaded := TestData.game_state([5, 5])
	loaded.load_save_data(JSON.parse_string(json))
	return loaded


func test_a_new_state_saves_nothing_but_the_bonus_count() -> void:
	var data := TestData.game_state([3]).to_save_data()
	assert_int(data["bonus_count"]).is_equal(0)
	assert_array(data["subjects"]).is_empty()


func test_completed_levels_and_stars_survive_a_reload() -> void:
	var state := TestData.game_state([5, 5])
	state.complete_level(0, 3.0)
	state.complete_level(1, 1.5)
	var loaded := _round_trip(state)
	assert_bool(loaded.is_level_completed(0)).is_true()
	assert_float(loaded.level_stars(1)).is_equal(1.5)
	assert_bool(loaded.is_level_unlocked(2)).is_true()
	assert_bool(loaded.is_level_unlocked(3)).is_false()
	assert_int(loaded.current_level).is_equal(2)


func test_progress_stays_separate_per_subject() -> void:
	var state := TestData.game_state([5, 5])
	state.complete_level(0)
	var loaded := _round_trip(state)
	loaded.select_subject(1)
	assert_bool(loaded.is_level_completed(0)).is_false()


func test_bonus_and_claimed_islands_survive_a_reload() -> void:
	var state := TestData.game_state_with_islands(4, 2)
	state.complete_level(0, 3.0)
	state.complete_level(1, 3.0)
	state.claim_island(0)
	var json := JSON.stringify(state.to_save_data())
	var loaded := TestData.game_state_with_islands(4, 2)
	loaded.load_save_data(JSON.parse_string(json))
	assert_int(loaded.bonus_count).is_equal(3)
	assert_int(loaded.island_claimed(0)).is_equal(3)
	assert_int(loaded.claim_island(0)).is_equal(0)


func test_every_progress_change_is_signaled() -> void:
	var state := TestData.game_state([3])
	monitor_signals(state, false)
	state.complete_level(0)
	@warning_ignore("redundant_await")
	await assert_signal(state).is_emitted("progress_changed")


func test_loading_an_empty_save_resets_the_progress() -> void:
	var state := TestData.game_state([3])
	state.complete_level(0)
	state.add_bonus(4)
	state.load_save_data({})
	assert_bool(state.is_level_completed(0)).is_false()
	assert_int(state.bonus_count).is_equal(0)
	assert_int(state.current_level).is_equal(0)


func test_malformed_subjects_are_skipped() -> void:
	var state := TestData.game_state([3])
	var key := [TestData.SECONDARY, TestData.FOURTH_YEAR, 0]
	state.load_save_data({"subjects": [{"key": [1, 2]}, {"key": key, "stars": {"1": 2.0}}]})
	assert_bool(state.is_level_completed(1)).is_true()
	assert_float(state.level_stars(1)).is_equal(2.0)
