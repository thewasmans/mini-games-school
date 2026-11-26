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
	assert_float(level.star_gauge.bar.value).is_equal(0.0)


func test_back_button_emits_exited() -> void:
	var level := _start_level(0, TestData.memo(1))
	monitor_signals(level, false)
	level.top_bar.back_button.pressed.emit()
	@warning_ignore("redundant_await")
	await assert_signal(level).is_emitted("exited")


func test_a_mistake_is_not_punished_until_the_answer_is_found() -> void:
	var level := _start_level(0, TestData.memo(1))
	var memo := level.mini_game_ui as MemoUI
	memo.answer_buttons[1].pressed.emit()
	memo.answer_buttons[2].pressed.emit()
	assert_int(memo.mistake_count).is_equal(2)
	assert_float(level.score_ratio).is_equal(0.0)
	memo.answer_buttons[0].pressed.emit()
	assert_int(level.score).is_equal(level.points_by_mistakes[2])
	assert_int(level.max_score).is_equal(level.points_by_mistakes[0])
	assert_float(level.stars).is_equal(0.0)


func test_too_many_mistakes_earn_no_star() -> void:
	var level := _start_level(0, TestData.memo(1))
	var memo := level.mini_game_ui as MemoUI
	for answer_index in [1, 2, 3, 0]:
		memo.answer_buttons[answer_index].pressed.emit()
	assert_int(level.score).is_equal(0)
	assert_float(level.stars).is_equal(0.0)


func test_points_drop_with_each_mistake_on_the_same_answer() -> void:
	var level := _start_level(0, TestData.memo(1))
	assert_int(level.points_for(0, false)).is_equal(10)
	assert_int(level.points_for(1, false)).is_equal(5)
	assert_int(level.points_for(2, false)).is_equal(2)
	assert_int(level.points_for(3, false)).is_equal(0)
	assert_int(level.points_for(8, false)).is_equal(0)
	assert_int(level.points_for(0, true)).is_equal(level.hint_points)
	assert_int(level.points_for(2, true)).is_equal(2)


func test_the_gauge_fills_with_good_answers_and_reaches_the_stars() -> void:
	var level := _start_level(0, TestData.memo(2))
	var memo := level.mini_game_ui as MemoUI
	assert_int(level.max_score).is_equal(2 * level.points_by_mistakes[0])
	assert_float(level.star_gauge.bar.value).is_equal(0.0)
	assert_int(level.star_gauge.reached_count).is_equal(0)
	memo.answer_buttons[0].pressed.emit()
	assert_float(level.star_gauge.bar.value).is_equal_approx(0.5, 0.001)
	assert_float(level.stars).is_equal(1.0)
	await await_millis(1000)
	assert_int(level.star_gauge.reached_count).is_equal(1)


func test_an_answer_found_with_a_hint_earns_hint_points() -> void:
	var level := _start_level(0, TestData.memo(1))
	var memo := level.mini_game_ui as MemoUI
	assert_bool(level.use_hint()).is_true()
	memo.answer_buttons[0].pressed.emit()
	assert_int(level.score).is_equal(level.hint_points)
	assert_float(level.stars).is_equal(1.0)


func test_stars_follow_the_score_thresholds() -> void:
	var level := _start_level(0, TestData.memo(1))
	level.mini_game_ui.answer_total = 10
	for case: Array in [[100, 3.0], [90, 3.0], [89, 2.0], [60, 2.0], [59, 1.0], [30, 1.0], [29, 0.0], [0, 0.0]]:
		level.score = case[0]
		assert_float(level.stars).is_equal(case[1])


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
	await assert_signal(level).is_emitted("validated", 2, 1.0)


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
	assert_int(level.score).is_equal(crypto._hidden.size() * level.hint_points)


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


func test_word_points_keep_the_score_of_the_answer_that_found_the_word() -> void:
	var words: Array[String] = ["la mole", "la densité"]
	var level := _start_level(0, TestData.memo_about(words))
	var memo := level.mini_game_ui as MemoUI
	memo.answer_buttons[0].pressed.emit()
	await await_millis(1800)
	memo.answer_buttons[1].pressed.emit()
	memo.answer_buttons[0].pressed.emit()
	var word_points := level.word_points()
	assert_int(word_points["MOLE"]).is_equal(10)
	assert_int(word_points["DENSITE"]).is_equal(5)


func test_crypto_answer_covers_the_word_of_the_hidden_letter() -> void:
	var level := _start_level(0, TestData.crypto(["La mole est une unité"]))
	var crypto := level.mini_game_ui as CryptoUI
	var hidden_index: int = crypto._hidden[0]
	var text := "La mole est une unité"
	var words := Array(crypto.answer_words(Vector2i(0, hidden_index)))
	assert_array(words).contains([TextUtil.word_at(text, hidden_index)])


func test_rewards_show_the_points_and_a_gauge_per_item() -> void:
	var level := _start_level(0, TestData.memo(1))
	var progress: Array[Dictionary] = [
		{"item": TestData.housing_item("MOLE"), "before": 10, "after": 20, "size": 30},
		{"item": TestData.housing_item("CNTP"), "before": 0, "after": 10, "size": 10},
	]
	level.show_rewards(3, 7, progress)
	var panel := level._discovery_panel
	assert_bool(panel.points_label.visible).is_true()
	assert_str(panel.points_label.text).contains("+3")
	assert_int(panel.rows.size()).is_equal(2)
	assert_bool(panel.rows[0].is_unlocked()).is_false()
	assert_bool(panel.rows[1].is_unlocked()).is_true()
	await await_millis(1500)
	assert_bool(panel.rows[1].new_label.visible).is_true()


func test_continuing_closes_the_rewards() -> void:
	var level := _start_level(0, TestData.memo(1))
	level.show_rewards(2, 2, [] as Array[Dictionary])
	assert_bool(level._discovery_panel.objects_title.visible).is_false()
	monitor_signals(level, false)
	level._discovery_panel.continue_button.pressed.emit()
	@warning_ignore("redundant_await")
	await assert_signal(level).is_emitted("rewards_closed")


func test_a_word_found_with_a_hint_earns_hint_points() -> void:
	var words: Array[String] = ["la mole"]
	var level := _start_level(0, TestData.memo_about(words))
	var memo := level.mini_game_ui as MemoUI
	assert_bool(level.use_hint()).is_true()
	memo.answer_buttons[0].pressed.emit()
	assert_int(level.word_points()["MOLE"]).is_equal(level.hint_points)


func test_a_level_without_mini_game_has_no_word_points() -> void:
	var level := _start_level(0, null)
	assert_bool(level.word_points().is_empty()).is_true()
