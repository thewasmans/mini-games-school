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
	@warning_ignore("redundant_await")
	await assert_signal(state).is_emitted("level_unlocked", 1)


func test_completing_the_last_level_unlocks_nothing() -> void:
	var state := TestData.game_state([2])
	state.complete_level(0)
	monitor_signals(state, false)
	state.complete_level(1)
	assert_int(state.current_level).is_equal(1)
	@warning_ignore("redundant_await")
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
	@warning_ignore("redundant_await")
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


func test_a_level_keeps_its_best_stars() -> void:
	var state := TestData.game_state([3])
	state.complete_level(0, 2.4)
	state.complete_level(0, 1.5)
	assert_float(state.level_stars(0)).is_equal(2.4)
	state.complete_level(0, 3.0)
	assert_float(state.level_stars(0)).is_equal(3.0)
	assert_float(state.level_stars(1)).is_equal(0.0)


func test_islands_follow_the_subject_interval() -> void:
	assert_int(TestData.game_state_with_islands(7, 3).island_count).is_equal(2)
	assert_int(TestData.game_state_with_islands(7, 0).island_count).is_equal(0)
	assert_array(TestData.game_state_with_islands(7, 3).island_levels(1)).is_equal([3, 4, 5])


func test_island_is_reached_once_its_levels_are_completed() -> void:
	var state := TestData.game_state_with_islands(6, 3)
	state.complete_level(0)
	state.complete_level(1)
	assert_bool(state.is_island_reached(0)).is_false()
	assert_int(state.island_reward(0)).is_equal(0)
	state.complete_level(2)
	assert_bool(state.is_island_reached(0)).is_true()


func test_island_reward_is_the_floored_star_average() -> void:
	var state := TestData.game_state_with_islands(3, 3)
	state.complete_level(0, 3.0)
	state.complete_level(1, 2.5)
	state.complete_level(2, 2.4)
	assert_int(state.island_reward(0)).is_equal(2)
	state.complete_level(2, 3.0)
	assert_int(state.island_reward(0)).is_equal(2)
	state.complete_level(1, 3.0)
	assert_int(state.island_reward(0)).is_equal(3)


func test_claiming_an_island_gives_only_the_missing_bonuses() -> void:
	var state := TestData.game_state_with_islands(2, 2)
	state.complete_level(0, 1.2)
	state.complete_level(1, 1.0)
	assert_int(state.claim_island(0)).is_equal(1)
	assert_int(state.claim_island(0)).is_equal(0)
	state.complete_level(0, 3.0)
	state.complete_level(1, 3.0)
	assert_int(state.claim_island(0)).is_equal(2)
	assert_int(state.bonus_count).is_equal(3)
	assert_int(state.island_claimed(0)).is_equal(3)


func test_spending_a_bonus_needs_one() -> void:
	var state := TestData.game_state([1])
	monitor_signals(state, false)
	assert_bool(state.spend_bonus()).is_false()
	state.add_bonus(1)
	assert_bool(state.spend_bonus()).is_true()
	assert_int(state.bonus_count).is_equal(0)
	@warning_ignore("redundant_await")
	await assert_signal(state).is_emitted("bonus_count_changed", 0)


func test_completing_a_level_returns_the_newly_earned_stars() -> void:
	var state := TestData.game_state([3])
	assert_int(state.complete_level(0, 2.4)).is_equal(2)
	assert_int(state.complete_level(0, 1.5)).is_equal(0)
	assert_int(state.complete_level(0, 3.0)).is_equal(1)
	assert_int(state.complete_level(1, 0.0)).is_equal(0)


func test_current_subject_key_follows_the_selection() -> void:
	var state := TestData.game_state([3, 3])
	assert_that(state.current_subject_key).is_equal(Vector3i(TestData.SECONDARY, TestData.FOURTH_YEAR, 0))
	state.select_subject(1)
	assert_that(state.current_subject_key).is_equal(Vector3i(TestData.SECONDARY, TestData.FOURTH_YEAR, 1))


func test_bonus_changes_are_signaled_as_progress() -> void:
	var state := TestData.game_state([1])
	monitor_signals(state, false)
	state.add_bonus(2)
	@warning_ignore("redundant_await")
	await assert_signal(state).is_emitted("progress_changed")


func test_selecting_a_level_is_signaled_as_progress() -> void:
	var state := TestData.game_state([3])
	monitor_signals(state, false)
	state.select_level(2)
	@warning_ignore("redundant_await")
	await assert_signal(state).is_emitted("progress_changed")
