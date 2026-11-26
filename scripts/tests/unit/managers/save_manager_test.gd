extends GdUnitTestSuite


func before_test() -> void:
	TestData.use_empty_save()


func after_test() -> void:
	SaveManager.delete_save()


func _start() -> GameManager:
	var game_manager := auto_free(GameManager.new()) as GameManager
	game_manager.game_data = TestData.game_data([3])
	var save_manager := auto_free(SaveManager.new()) as SaveManager
	game_manager.managers.append(save_manager)
	game_manager.initialize()
	game_manager.game_state.select_study_level(TestData.SECONDARY)
	game_manager.game_state.select_school_year(TestData.FOURTH_YEAR)
	game_manager.game_state.select_subject(0)
	return game_manager


func _write_save(text: String) -> void:
	var file := FileAccess.open(SaveManager.save_path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_without_a_save_the_game_starts_from_scratch() -> void:
	var game_manager := _start()
	assert_bool(game_manager.game_state.is_level_completed(0)).is_false()
	assert_int(game_manager.housing_state.action_points).is_equal(0)


func test_progress_and_housing_are_saved_and_reloaded() -> void:
	var first := _start()
	first.game_state.complete_level(0, 2.0)
	first.housing_state.record_level_result(first.game_state.current_subject_key, 0, true, 2, 2.0, 0)
	assert_bool(FileAccess.file_exists(SaveManager.save_path)).is_true()
	var second := _start()
	assert_bool(second.game_state.is_level_completed(0)).is_true()
	assert_float(second.game_state.level_stars(0)).is_equal(2.0)
	assert_int(second.housing_state.action_points).is_equal(4)


func test_a_version_1_save_is_still_read() -> void:
	var key := [TestData.SECONDARY, TestData.FOURTH_YEAR, 0]
	_write_save(JSON.stringify({"bonus_count": 2, "subjects": [{"key": key, "current_level": 1, "stars": {"0": 3.0}, "claimed_islands": {}}]}))
	var game_manager := _start()
	assert_int(game_manager.game_state.bonus_count).is_equal(2)
	assert_bool(game_manager.game_state.is_level_completed(0)).is_true()
	assert_int(game_manager.game_state.current_level).is_equal(1)
	assert_int(game_manager.housing_state.action_points).is_equal(0)


func test_an_unreadable_save_is_ignored() -> void:
	_write_save("pas du json")
	var game_manager := _start()
	assert_bool(game_manager.game_state.is_level_completed(0)).is_false()


func test_the_save_file_has_a_version() -> void:
	var game_manager := _start()
	game_manager.game_state.add_bonus(1)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveManager.save_path))
	assert_int(int(data["version"])).is_equal(SaveManager.SAVE_VERSION)
	assert_bool(data.has("progress")).is_true()
	assert_bool(data.has("housing")).is_true()
