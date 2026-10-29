extends GdUnitTestSuite

const LEVEL_SCENE := "res://content/prefabs/ui/level/level.tscn"
const TIMEOUT_MS := 6000


func _start_level(level_index: int, mini_game: MiniGameData) -> Level:
	var runner := scene_runner(LEVEL_SCENE)
	var level := runner.scene() as Level
	var level_data := LevelData.new()
	level_data.mini_game = mini_game
	level.initialize(level_index, level_data, "Titre de test")
	return level


func test_level_shows_the_title_and_the_mini_game() -> void:
	var level := _start_level(0, TestData.memo(1))
	assert_str(level.title_banner.text).is_equal("Titre de test")
	assert_object(level.mini_game_ui).is_instanceof(MemoUI)
	assert_bool(level.validate_button.visible).is_false()
	assert_bool(level.missing_mini_game_label.visible).is_false()


func test_level_without_mini_game_says_so() -> void:
	var level := _start_level(0, null)
	assert_bool(level.missing_mini_game_label.visible).is_true()
	assert_object(level.mini_game_ui).is_null()


func test_answering_every_question_then_validating_emits_validated() -> void:
	var level := _start_level(4, TestData.memo(2))
	var memo := level.mini_game_ui as MemoUI
	monitor_signals(level, false)
	memo.answer_buttons[0].pressed.emit()
	await await_millis(1800)
	memo.answer_buttons[0].pressed.emit()
	@warning_ignore("redundant_await")
	await assert_signal(level).wait_until(TIMEOUT_MS).is_emitted("validation_available")
	assert_bool(level.validate_button.visible).is_true()
	level.validate_button.pressed.emit()
	@warning_ignore("redundant_await")
	await assert_signal(level).is_emitted("validated", 4)


func test_wrong_answer_disables_the_choice_without_progress() -> void:
	var level := _start_level(0, TestData.memo(1))
	var memo := level.mini_game_ui as MemoUI
	memo.answer_buttons[2].pressed.emit()
	assert_bool(memo.answer_buttons[2].disabled).is_true()
	await await_millis(300)
	assert_float(level.progress_bar.value).is_equal(0.0)


func test_back_button_emits_exited() -> void:
	var level := _start_level(0, TestData.memo(1))
	monitor_signals(level, false)
	level.top_bar.back_button.pressed.emit()
	@warning_ignore("redundant_await")
	await assert_signal(level).is_emitted("exited")
