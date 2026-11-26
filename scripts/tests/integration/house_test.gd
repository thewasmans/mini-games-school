extends GdUnitTestSuite

const MAIN_SCENE := "res://scenes/main.tscn"

var _game_manager: GameManager
var _ui: GameUI


func before_test() -> void:
	TestData.use_empty_save()
	var main := scene_runner(MAIN_SCENE).scene() as Main
	_game_manager = main.game_manager
	_ui = _game_manager.game_ui_manager._game_ui
	await await_millis(100)


func _open_house() -> House:
	_ui.menu_start.top_bar.house_button.pressed.emit()
	await await_millis(100)
	return _game_manager.house_manager.house


func _chemistry_key() -> Vector3i:
	return _game_manager.housing_state.catalog.subject_keys()[0]


func _item(word: String) -> HousingItemData:
	for item in _game_manager.housing_state.catalog.items(_chemistry_key()):
		if item.word == word:
			return item
	return null


func _unlock(item: HousingItemData) -> void:
	var housing_state := _game_manager.housing_state
	for level_index in housing_state.catalog.levels_with(item):
		var word_points: Dictionary[String, int] = {}
		word_points[item.word] = 10
		housing_state.record_encounters(_chemistry_key(), level_index, word_points)


func test_the_house_button_is_on_the_start_menu_only_when_asked() -> void:
	assert_bool(_ui.menu_start.top_bar.house_button.visible).is_true()
	assert_bool(_ui.menu_credits.top_bar.house_button.visible).is_false()


func test_the_house_opens_and_closes_back_to_the_menus() -> void:
	var house := await _open_house()
	assert_object(house).is_not_null()
	assert_bool(_ui.visible).is_false()
	assert_int(house.world.rooms.size()).is_greater_equal(2)
	assert_str(house.room_title.text).is_equal(House.HALL_TITLE)
	house.back_button.pressed.emit()
	await await_millis(100)
	assert_object(_game_manager.house_manager.house).is_null()
	assert_bool(_ui.visible).is_true()


func test_a_closed_room_stays_closed_until_the_subject_is_started() -> void:
	var house := await _open_house()
	var room := house.world.room_of(_chemistry_key())
	assert_bool(room.open).is_false()


func test_the_inventory_lists_every_item_of_the_room() -> void:
	var mole := _item("MOLE")
	_unlock(mole)
	var house := await _open_house()
	house.player.global_position = house.world.spawn_position(_chemistry_key())
	await await_millis(200)
	assert_str(house.room_title.text).is_equal("Chimie")
	house.inventory_button.pressed.emit()
	assert_bool(house.inventory.visible).is_true()
	assert_int(house.inventory.rows_container.get_child_count()).is_equal(_game_manager.housing_state.catalog.items(_chemistry_key()).size())


func test_an_unlocked_item_can_be_placed_in_front_of_the_kid() -> void:
	var mole := _item("MOLE")
	_unlock(mole)
	_game_manager.housing_state.action_points = 3
	var house := await _open_house()
	house.player.global_position = house.world.spawn_position(_chemistry_key())
	await await_millis(200)
	house.carry(mole, false)
	await await_millis(100)
	assert_bool(house.primary_button.visible).is_true()
	house.primary_button.pressed.emit()
	assert_bool(_game_manager.housing_state.is_placed(_chemistry_key(), mole)).is_true()
	assert_int(_game_manager.housing_state.action_points).is_equal(2)
	assert_object(house.carried).is_null()


func test_play_opens_the_level_map_of_the_room() -> void:
	_unlock(_item("MOLE"))
	var house := await _open_house()
	house.player.global_position = house.world.spawn_position(_chemistry_key())
	await await_millis(200)
	house.play_button.pressed.emit()
	await await_millis(600)
	assert_object(_game_manager.house_manager.house).is_null()
	assert_bool(_ui.menu_levels.visible).is_true()
	assert_that(_game_manager.game_state.current_subject_key).is_equal(_chemistry_key())
