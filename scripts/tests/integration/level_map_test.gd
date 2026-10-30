extends GdUnitTestSuite

const MAIN_SCENE := "res://scenes/main.tscn"
const SECONDARY := 1
const FOURTH_YEAR := 3

var _game_manager: GameManager
var _menu_levels: MenuLevelsUI


func before_test() -> void:
	var main := scene_runner(MAIN_SCENE).scene() as Main
	_game_manager = main.game_manager
	var ui := _game_manager.game_ui_manager._game_ui
	_menu_levels = ui.menu_levels
	await await_millis(100)
	ui.menu_start.play_pressed.emit()
	ui.menu_study_levels.study_level_selected.emit(SECONDARY)
	ui.menu_school_years.school_year_selected.emit(FOURTH_YEAR)
	ui.menu_subjects.subject_selected.emit(0)
	await await_millis(200)


func test_map_has_a_marker_per_level_and_per_bonus_island() -> void:
	var game_state := _game_manager.game_state
	assert_int(_menu_levels.level_map.level_markers.size()).is_equal(game_state.current_levels.size())
	assert_int(_menu_levels.level_map.island_markers.size()).is_equal(game_state.island_count)
	assert_int(game_state.island_count).is_greater(0)


func test_only_the_first_level_marker_is_open_at_start() -> void:
	var markers := _menu_levels.level_map.level_markers
	assert_int(markers[0].state).is_equal(LevelMarker.State.CURRENT)
	assert_int(markers[1].state).is_equal(LevelMarker.State.LOCKED)


func test_pressing_a_locked_level_does_not_start_it() -> void:
	monitor_signals(_menu_levels, false)
	_menu_levels.level_map.level_pressed.emit(1)
	@warning_ignore("redundant_await")
	await assert_signal(_menu_levels).wait_until(200).is_not_emitted("level_selected")


func test_claiming_a_reached_island_adds_bonuses() -> void:
	var game_state := _game_manager.game_state
	for level_index in game_state.island_levels(0):
		game_state.complete_level(level_index, 3.0)
	_menu_levels.show_menu()
	await await_millis(100)
	_menu_levels.level_map.island_pressed.emit(0)
	assert_int(game_state.bonus_count).is_equal(3)
	assert_int(_menu_levels.level_map.island_markers[0].state).is_equal(BonusIslandMarker.State.CLAIMED)
	assert_str(_menu_levels.bonus_pill.text).is_equal("3 indices")


func test_clicking_a_marker_on_screen_selects_its_level() -> void:
	await await_millis(300)
	monitor_signals(_menu_levels.level_map, false)
	var marker := _menu_levels.level_map.level_markers[0]
	var holder := marker.get_parent() as Control
	_menu_levels.level_map._click(holder.position + holder.pivot_offset)
	@warning_ignore("redundant_await")
	await assert_signal(_menu_levels.level_map).is_emitted("level_pressed", 0)
