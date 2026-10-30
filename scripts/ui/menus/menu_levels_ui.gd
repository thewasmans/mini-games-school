class_name MenuLevelsUI
extends MenuUI

signal level_selected(level_index: int)

@export var title_banner: TitleBanner
@export var info_pill: Pill
@export var bonus_pill: Pill
@export var level_map: LevelMap

var pending_unlock := -1


func _ready() -> void:
	level_map.level_pressed.connect(_on_level_pressed)
	level_map.island_pressed.connect(_on_island_pressed)


func initialize(game_manager_: GameManager) -> void:
	super.initialize(game_manager_)
	game_manager.game_state.bonus_count_changed.connect(func(_bonus_count: int) -> void: _refresh_bonus_pill())


func _refresh() -> void:
	var game_state := game_manager.game_state
	var game_data := game_manager.game_data
	var study_level := game_state.current_study_level
	var school_year := game_state.current_school_year
	var levels := game_state.current_levels
	title_banner.text = game_data.get_subject(study_level, school_year, game_state.current_subject).name
	info_pill.text = "%s - %s   •   %d / %d" % [GameData.STUDY_NAMES[study_level], game_data.get_year_name(study_level, school_year),
		game_state.completed_level_count(study_level, school_year, game_state.current_subject), levels.size()]
	_refresh_bonus_pill()
	level_map.build(levels, game_state)
	var unlock_index := pending_unlock
	pending_unlock = -1
	if unlock_index >= 0:
		level_map.prepare_unlock(unlock_index)
	if levels.is_empty():
		return
	level_map.focus_level(clampi(unlock_index if unlock_index >= 0 else game_state.current_level, 0, levels.size() - 1), true)
	if unlock_index >= 0:
		await get_tree().create_timer(0.3).timeout
		level_map.play_unlock(unlock_index)


func _refresh_bonus_pill() -> void:
	var bonus_count := game_manager.game_state.bonus_count
	bonus_pill.text = "%d indice%s" % [bonus_count, "s" if bonus_count > 1 else ""]


func _on_level_pressed(level_index: int) -> void:
	if not game_manager.game_state.is_level_unlocked(level_index):
		Sfx.play("locked")
		level_map.level_markers[level_index].shake()
		return
	Sfx.play("pop")
	level_selected.emit(level_index)


func _on_island_pressed(island_index: int) -> void:
	var game_state := game_manager.game_state
	if not game_state.is_island_reached(island_index):
		Sfx.play("locked")
		level_map.island_markers[island_index].shake()
		return
	var gained := game_state.claim_island(island_index)
	if gained <= 0:
		Sfx.play("click")
		level_map.island_markers[island_index].shake()
		return
	Sfx.play("unlock")
	level_map.celebrate_island(island_index, gained)
	level_map.refresh(game_state)
	_refresh_bonus_pill()
	UIFeedback.punch(bonus_pill, 0.2, 0.5)
