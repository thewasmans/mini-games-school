extends GdUnitTestSuite


func test_only_first_level_is_unlocked_at_start() -> void:
	var state := TestData.game_state([3])
	assert_bool(state.is_level_unlocked(0)).is_true()
	assert_bool(state.is_level_unlocked(1)).is_false()


func test_completing_a_level_unlocks_and_selects_the_next_one() -> void:
	var state := TestData.game_state([3])
	monitor_signals(state, false)
	state.complete_level(0)
	assert_bool(state.is_level_unlocked(1)).is_true()
	assert_bool(state.is_level_unlocked(2)).is_false()
	assert_int(state.current_level).is_equal(1)
	await assert_signal(state).is_emitted("level_unlocked", 1)


func test_completing_the_last_level_unlocks_nothing() -> void:
	var state := TestData.game_state([2])
	state.complete_level(0)
	monitor_signals(state, false)
	state.complete_level(1)
	assert_int(state.current_level).is_equal(1)
	await assert_signal(state).wait_until(100).is_not_emitted("level_unlocked")


func test_a_completed_level_stays_unlocked() -> void:
	var state := TestData.game_state([3])
	state.complete_level(0)
	state.complete_level(1)
	assert_bool(state.is_level_completed(1)).is_true()
	assert_bool(state.is_level_unlocked(2)).is_true()


func test_completing_a_level_twice_counts_once() -> void:
	var state := TestData.game_state([3])
	state.complete_level(0)
	state.complete_level(0)
	assert_int(state.completed_level_count(TestData.SECONDARY)).is_equal(1)


func test_progress_is_tracked_per_subject() -> void:
	var state := TestData.game_state([3, 3])
	state.complete_level(0)
	state.select_subject(1)
	assert_bool(state.is_level_unlocked(1)).is_false()
	assert_int(state.current_level).is_equal(0)


func test_unlock_all_levels_unlocks_every_level() -> void:
	var state := TestData.game_state([3])
	monitor_signals(state, false)
	state.unlock_all_levels()
	assert_bool(state.is_level_unlocked(2)).is_true()
	await assert_signal(state).is_emitted("all_levels_unlocked")


func test_level_count_can_be_scoped_to_a_year_or_a_subject() -> void:
	var state := TestData.game_state([3, 2])
	assert_int(state.level_count(TestData.SECONDARY)).is_equal(5)
	assert_int(state.level_count(TestData.SECONDARY, TestData.FOURTH_YEAR)).is_equal(5)
	assert_int(state.level_count(TestData.SECONDARY, TestData.FOURTH_YEAR, 1)).is_equal(2)
	assert_int(state.level_count(TestData.SECONDARY, 0)).is_equal(0)
	assert_int(state.level_count(0)).is_equal(0)


func test_completed_level_count_can_be_scoped_to_a_subject() -> void:
	var state := TestData.game_state([3, 2])
	state.complete_level(0)
	state.select_subject(1)
	state.complete_level(0)
	assert_int(state.completed_level_count(TestData.SECONDARY)).is_equal(2)
	assert_int(state.completed_level_count(TestData.SECONDARY, TestData.FOURTH_YEAR, 1)).is_equal(1)
	assert_int(state.completed_level_count(0)).is_equal(0)


func test_total_progress_covers_every_study_level() -> void:
	var state := TestData.game_state([3, 2])
	state.complete_level(0)
	assert_that(state.total_progress()).is_equal(Vector2i(1, 5))
