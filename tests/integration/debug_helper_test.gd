extends GdUnitTestSuite

const MAIN_SCENE := "res://scenes/main.tscn"
const SECONDARY := 1
const FOURTH_YEAR := 3
const TIMEOUT_MS := 30000

var _game_manager: GameManager
var _debug_helper: DebugHelper


func before_test() -> void:
	var main := scene_runner(MAIN_SCENE).scene() as Main
	_game_manager = main.game_manager
	_debug_helper = main.find_children("*", "CanvasLayer", false, false)[0] as DebugHelper
	await await_millis(100)
	var game_state := _game_manager.game_state
	game_state.select_study_level(SECONDARY)
	game_state.select_school_year(FOURTH_YEAR)
	game_state.select_subject(0)
	game_state.unlock_all_levels()
	_debug_helper.auto_fill_check.button_pressed = true
	_debug_helper.auto_validate_check.button_pressed = true


func _level_index_of(kind_id: String) -> int:
	var levels := _game_manager.game_state.current_levels
	for level_index in levels.size():
		if levels[level_index].mini_game.get_kind_id() == kind_id:
			return level_index
	return -1


func _assert_cheat_completes(kind_id: String) -> void:
	var level_index := _level_index_of(kind_id)
	assert_int(level_index).is_not_negative()
	_game_manager.game_state.select_level(level_index)
	_game_manager.level_manager.start_level(level_index)
	await assert_func(_game_manager.game_state, "is_level_completed", [level_index]).wait_until(TIMEOUT_MS).is_true()


func test_crossword_cheat_completes_the_level() -> void:
	await _assert_cheat_completes("crossword")


func test_memo_cheat_completes_the_level() -> void:
	await _assert_cheat_completes("memo")


func test_crypto_cheat_completes_the_level() -> void:
	await _assert_cheat_completes("crypto")


func test_show_hints_displays_the_answer() -> void:
	var level_index := _level_index_of("memo")
	_debug_helper.auto_fill_check.button_pressed = false
	_debug_helper.show_hints_check.button_pressed = true
	_game_manager.level_manager.start_level(level_index)
	await await_millis(500)
	assert_bool(_debug_helper.hint_label.visible).is_true()
	assert_str(_debug_helper.hint_label.text).starts_with("Réponse : ")
