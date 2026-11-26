extends GdUnitTestSuite

const MAIN_SCENE := "res://scenes/main.tscn"
const SECONDARY := 1
const FOURTH_YEAR := 3

var _main: Main
var _game_manager: GameManager
var _ui: GameUI


func before_test() -> void:
	TestData.use_empty_save()
	var runner := scene_runner(MAIN_SCENE)
	_main = runner.scene() as Main
	_game_manager = _main.game_manager
	_ui = _game_manager.game_ui_manager._game_ui
	await await_millis(100)


func test_starts_on_the_start_menu() -> void:
	assert_bool(_ui.menu_start.visible).is_true()
	assert_bool(_ui.menu_study_levels.visible).is_false()


func test_play_then_study_level_then_year_reaches_the_subjects() -> void:
	_ui.menu_start.play_pressed.emit()
	_ui.menu_study_levels.study_level_selected.emit(SECONDARY)
	_ui.menu_school_years.school_year_selected.emit(FOURTH_YEAR)
	await await_millis(600)
	assert_bool(_ui.menu_subjects.visible).is_true()
	assert_bool(_ui.menu_school_years.visible).is_false()
	assert_int(_ui.menu_subjects.entries_container.get_child_count()).is_greater(0)


func test_choosing_a_level_hides_the_menus_and_validating_comes_back() -> void:
	_ui.menu_start.play_pressed.emit()
	_ui.menu_study_levels.study_level_selected.emit(SECONDARY)
	_ui.menu_school_years.school_year_selected.emit(FOURTH_YEAR)
	_ui.menu_subjects.subject_selected.emit(0)
	_ui.menu_levels.level_selected.emit(0)
	await await_millis(100)
	assert_bool(_ui.visible).is_false()
	var level := _game_manager.level_manager._level
	assert_object(level).is_not_null()
	assert_object(level.mini_game_ui).is_not_null()
	level.validate_button.show()
	level.validate()
	await await_millis(100)
	assert_bool(_ui.visible).is_false()
	assert_object(level._discovery_panel).is_not_null()
	level._discovery_panel.continue_button.pressed.emit()
	await await_millis(100)
	assert_bool(_ui.visible).is_true()
	assert_bool(_game_manager.game_state.is_level_completed(0)).is_true()
	assert_bool(_game_manager.game_state.is_level_unlocked(1)).is_true()
	assert_int(_game_manager.housing_state.action_points).is_equal(HousingState.FIRST_COMPLETION_POINTS)
