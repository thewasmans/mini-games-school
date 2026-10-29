class_name GameUI
extends Control

signal level_requested(level_index: int)
signal study_level_shown(study_level_index: int)

const NO_STUDY_LEVEL := -1

@export var menu_start: MenuStartUI
@export var menu_study_levels: MenuStudyLevelsUI
@export var menu_school_years: MenuSchoolYearsUI
@export var menu_subjects: MenuSubjectsUI
@export var menu_levels: MenuLevelsUI
@export var menu_credits: MenuCreditsUI

@export_group("Réglages")
## Distance de glissement des menus pendant une transition, en pixels.
@export var transition_offset := 90.0
## Durée de l'arrivée d'un menu, en secondes.
@export var transition_duration := 0.35

var _game_manager: GameManager
var _current: MenuUI
var _skipped_school_years := false


func initialize(game_manager: GameManager) -> void:
	_game_manager = game_manager
	for menu in _menus():
		menu.hide()
		menu.initialize(game_manager)
	menu_start.play_pressed.connect(_switch_to.bind(menu_study_levels))
	menu_start.credits_pressed.connect(_switch_to.bind(menu_credits))
	menu_credits.back_pressed.connect(_switch_to.bind(menu_start, false))
	menu_study_levels.back_pressed.connect(_switch_to.bind(menu_start, false))
	menu_study_levels.study_level_selected.connect(_on_study_level_selected)
	menu_school_years.back_pressed.connect(_switch_to.bind(menu_study_levels, false))
	menu_school_years.school_year_selected.connect(_on_school_year_selected)
	menu_subjects.back_pressed.connect(_on_menu_subjects_back)
	menu_subjects.subject_selected.connect(_on_subject_selected)
	menu_levels.back_pressed.connect(_switch_to.bind(menu_subjects, false))
	menu_levels.level_selected.connect(_on_level_selected)
	game_manager.game_state.level_unlocked.connect(_on_level_unlocked)
	game_manager.game_state.all_levels_unlocked.connect(_on_all_levels_unlocked)
	_switch_to(menu_start)


func show_levels_menu() -> void:
	menu_levels.show_menu()


func _menus() -> Array[MenuUI]:
	return [menu_start, menu_study_levels, menu_school_years, menu_subjects, menu_levels, menu_credits]


func _switch_to(menu: MenuUI, forward := true) -> void:
	var previous := _current
	_current = menu
	study_level_shown.emit(_study_level_of(menu))
	menu.show()
	menu.show_menu()
	if previous == null or previous == menu:
		return
	var direction := 1.0 if forward else -1.0
	menu.modulate.a = 0.0
	menu.position.x = transition_offset * direction
	var arrival := menu.create_tween().set_parallel()
	arrival.tween_property(menu, "position:x", 0.0, transition_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	arrival.tween_property(menu, "modulate:a", 1.0, transition_duration * 0.7)
	previous.process_mode = PROCESS_MODE_DISABLED
	var departure := create_tween().set_parallel()
	departure.tween_property(previous, "position:x", -transition_offset * direction, transition_duration * 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	departure.tween_property(previous, "modulate:a", 0.0, transition_duration * 0.6)
	departure.chain().tween_callback(_finish_departure.bind(previous))
	Sfx.play("whoosh")


func _finish_departure(menu: MenuUI) -> void:
	if menu == _current:
		return
	menu.hide()
	menu.position.x = 0.0
	menu.modulate.a = 1.0
	menu.process_mode = PROCESS_MODE_INHERIT


func _study_level_of(menu: MenuUI) -> int:
	if menu in [menu_school_years, menu_subjects, menu_levels]:
		return _game_manager.game_state.current_study_level
	return NO_STUDY_LEVEL


func _on_study_level_selected(study_level_index: int) -> void:
	var game_state := _game_manager.game_state
	game_state.select_study_level(study_level_index)
	var school_years := _game_manager.game_data.get_existing_years(study_level_index)
	_skipped_school_years = school_years.size() == 1
	if _skipped_school_years:
		game_state.select_school_year(school_years[0])
		_switch_to(menu_subjects)
	else:
		_switch_to(menu_school_years)


func _on_school_year_selected(school_year_index: int) -> void:
	_game_manager.game_state.select_school_year(school_year_index)
	_switch_to(menu_subjects)


func _on_menu_subjects_back() -> void:
	if _skipped_school_years:
		_switch_to(menu_study_levels, false)
	else:
		_switch_to(menu_school_years, false)


func _on_subject_selected(subject_index: int) -> void:
	_game_manager.game_state.select_subject(subject_index)
	_switch_to(menu_levels)


func _on_level_selected(level_index: int) -> void:
	_game_manager.game_state.select_level(level_index)
	level_requested.emit(level_index)


func _on_level_unlocked(level_index: int) -> void:
	menu_levels.pending_unlock = level_index


func _on_all_levels_unlocked() -> void:
	if _current == menu_levels:
		menu_levels.show_menu()
