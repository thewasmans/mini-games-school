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
	await assert_signal(level).is_emitted("validated", 4, 3.0)


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


func test_each_mistake_costs_a_tenth_of_a_star() -> void:
	var level := _start_level(0, TestData.memo(1))
	var memo := level.mini_game_ui as MemoUI
	memo.answer_buttons[1].pressed.emit()
	memo.answer_buttons[2].pressed.emit()
	assert_int(memo.mistake_count).is_equal(2)
	assert_float(level.stars).is_equal_approx(2.8, 0.001)
	assert_float(level.star_rating.value).is_equal_approx(2.8, 0.001)


func test_stars_never_drop_below_one() -> void:
	var level := _start_level(0, TestData.memo(1))
	for mistake in 40:
		level.mini_game_ui._make_mistake()
	assert_float(level.stars).is_equal(1.0)


func test_validating_after_mistakes_emits_the_stars() -> void:
	var level := _start_level(2, TestData.memo(1))
	var memo := level.mini_game_ui as MemoUI
	monitor_signals(level, false)
	memo.answer_buttons[3].pressed.emit()
	memo.answer_buttons[0].pressed.emit()
	@warning_ignore("redundant_await")
	await assert_signal(level).wait_until(TIMEOUT_MS).is_emitted("validation_available")
	level.validate_button.pressed.emit()
	@warning_ignore("redundant_await")
	await assert_signal(level).is_emitted("validated", 2, 2.9)


func test_hint_button_is_disabled_without_bonus() -> void:
	var level := _start_level(0, TestData.memo(1))
	level.set_bonus_count(0)
	assert_bool(level.hint_button.disabled).is_true()
	level.set_bonus_count(2)
	assert_bool(level.hint_button.disabled).is_false()
	assert_str(level.hint_button.text).is_equal("2")


func test_memo_hint_eliminates_a_wrong_answer() -> void:
	var level := _start_level(0, TestData.memo(1))
	var memo := level.mini_game_ui as MemoUI
	assert_bool(level.use_hint()).is_true()
	var disabled_count := memo.answer_buttons.filter(func(button: JuicyButton) -> bool: return button.disabled).size()
	assert_int(disabled_count).is_equal(1)
	assert_bool(memo.answer_buttons[0].disabled).is_false()
	assert_int(memo.mistake_count).is_equal(0)


func test_memo_hint_stops_when_only_the_right_answer_is_left() -> void:
	var level := _start_level(0, TestData.memo(1))
	for hint in 3:
		assert_bool(level.use_hint()).is_true()
	assert_bool(level.use_hint()).is_false()


func test_crypto_hint_reveals_a_letter_and_can_solve_the_sentence() -> void:
	var level := _start_level(0, TestData.crypto(["Le noyau contient l'ADN."]))
	var crypto := level.mini_game_ui as CryptoUI
	for hidden_index in crypto._hidden.size():
		assert_bool(level.use_hint()).is_true()
	assert_bool(crypto._solved).is_true()
	assert_int(crypto.mistake_count).is_equal(0)


func test_crossword_hint_reveals_a_letter_of_the_selected_word() -> void:
	var crossword_data := TestData.crossword(["CELLULE", "NOYAU"])
	CrosswordGenerator.generate(crossword_data)
	var level := _start_level(0, crossword_data)
	var crossword := level.mini_game_ui as CrosswordUI
	var cells: Array[Vector2i] = crossword._words[crossword._selected].cells
	var filled_before := cells.filter(func(p: Vector2i) -> bool: return (crossword._cells[p] as CrosswordCell).letter != "").size()
	assert_bool(level.use_hint()).is_true()
	var filled_after := cells.filter(func(p: Vector2i) -> bool: return (crossword._cells[p] as CrosswordCell).letter != "").size()
	assert_int(filled_after).is_equal(filled_before + 1)
	assert_int(crossword.mistake_count).is_equal(0)
