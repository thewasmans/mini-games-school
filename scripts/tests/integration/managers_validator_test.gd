extends GdUnitTestSuite

const MAIN_SCENE := "res://scenes/main.tscn"


class ForgottenManager extends Manager:
	pass


var _game_manager: GameManager
var _validator: ManagersValidator


func before_test() -> void:
	var main := scene_runner(MAIN_SCENE).scene() as Main
	_game_manager = main.game_manager
	_validator = main.get_node("Global/ManagersValidator") as ManagersValidator


func test_main_scene_has_no_warning() -> void:
	assert_array(_validator._get_configuration_warnings()).is_empty()


func test_every_manager_child_is_initialized() -> void:
	for child in _game_manager.get_children():
		if child is Manager:
			assert_array(_game_manager.managers).contains([child])


func test_typed_accessors_find_their_manager_in_the_list() -> void:
	assert_object(_game_manager.game_ui_manager).is_instanceof(GameUIManager)
	assert_object(_game_manager.level_manager).is_instanceof(LevelManager)


func test_forgotten_manager_is_reported() -> void:
	var forgotten := ForgottenManager.new()
	forgotten.name = "ForgottenManager"
	_game_manager.add_child(forgotten)
	var warnings := _validator._get_configuration_warnings()
	assert_int(warnings.size()).is_equal(1)
	assert_str(warnings[0]).starts_with("ForgottenManager n'est pas dans la liste")
	forgotten.queue_free()


func test_manager_listed_twice_is_reported() -> void:
	_game_manager.managers.append(_game_manager.level_manager)
	var warnings := _validator._get_configuration_warnings()
	_game_manager.managers.pop_back()
	assert_int(warnings.size()).is_equal(1)
	assert_str(warnings[0]).starts_with("LevelManager est 2 fois")
