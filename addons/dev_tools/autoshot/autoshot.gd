extends Node

const STUDY_LEVEL := 1
const SCHOOL_YEAR := 3
const SUBJECT := 0

var _out := "user://shots"
var _game_manager: GameManager
var _ui: GameUI


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	var main: Main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await _wait(0.5)
	_game_manager = main.game_manager
	_ui = _game_manager.game_ui_manager._game_ui
	await _wait(1.6)
	await _shot("01_main")

	_ui.menu_start.play_pressed.emit()
	await _wait(1.5)
	await _shot("02_study")

	_ui.menu_study_levels.study_level_selected.emit(STUDY_LEVEL)
	await _wait(1.2)
	await _shot("03_years")

	_ui.menu_school_years.school_year_selected.emit(SCHOOL_YEAR)
	await _wait(1.2)
	await _shot("04_subjects")

	var game_state := _game_manager.game_state
	game_state.select_subject(SUBJECT)
	game_state.complete_level(0)
	_ui.menu_subjects.subject_selected.emit(SUBJECT)
	await _wait(0.5)
	await _shot("05_grid_unlocking")
	await _wait(1.5)
	await _shot("06_grid")

	var crossword := await _open_level(0) as CrosswordUI
	for letter in "NOYAU":
		crossword._type(letter)
	await _wait(0.3)
	var second := crossword._next_open(crossword._selected)
	crossword._select_word(second)
	for i in (crossword._words[second].cells as Array).size():
		crossword._type("X")
	await _wait(0.15)
	await _shot("07_crossword")
	await _close_level()

	var quiz := await _open_level(1) as MemoUI
	quiz._on_answer(3)
	await _wait(0.6)
	await _shot("08_quiz")
	quiz._on_answer(0)
	await _wait(0.3)
	await _shot("09_quiz_good")
	await _close_level()

	var crypto := await _open_level(2) as CryptoUI
	await _shot("10_crypto")
	for i in crypto._hidden.size():
		crypto._type("E" if i % 3 == 0 else TextUtil.normalize_char(crypto._cells[crypto._hidden[i]].original))
	await _wait(0.6)
	await _shot("11_crypto_errors")
	crypto._fix_errors()
	for k in crypto._hidden:
		if crypto._cells[k].state == CryptoCell.State.EMPTY:
			crypto._type(TextUtil.normalize_char(crypto._cells[k].original))
	await _wait(0.4)
	await _shot("12_crypto_solved")
	while not crypto.is_completed:
		crypto._next_sentence()
		await _wait(0.5)
		for k in crypto._hidden.duplicate():
			if crypto._cells[k].state != CryptoCell.State.CORRECT:
				crypto._type(TextUtil.normalize_char(crypto._cells[k].original))
		await _wait(0.3)
	await _wait(0.2)
	await _shot("13_victory")
	await _wait(1.6)
	await _shot("14_validate")
	_game_manager.level_manager._level.validate()
	await _wait(1.6)
	await _shot("15_grid_after_level")

	_ui._switch_to(_ui.menu_credits)
	await _wait(1.3)
	await _shot("16_credits")
	get_tree().quit()


func _open_level(level_index: int) -> MiniGameUI:
	_ui.menu_levels.level_selected.emit(level_index)
	await _wait(1.2)
	return _game_manager.level_manager._level.mini_game_ui


func _close_level() -> void:
	_game_manager.level_manager._level.exited.emit()
	await _wait(0.8)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out.path_join(shot_name + ".png"))
	print("shot ", shot_name)
