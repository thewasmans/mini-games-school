class_name MenuLevelsUI
extends MenuUI

signal level_selected(level_index: int)

@export var title_banner: TitleBanner
@export var info_pill: Pill
@export var scroll: ScrollContainer
@export var level_path: LevelPath

var pending_unlock := -1


func _ready() -> void:
	scroll.resized.connect(func() -> void: level_path.fit_height(scroll.size.y))
	level_path.level_pressed.connect(_on_level_pressed)


func _refresh() -> void:
	var game_state := game_manager.game_state
	var game_data := game_manager.game_data
	var study_level := game_state.current_study_level
	var school_year := game_state.current_school_year
	var levels := game_state.current_levels
	title_banner.text = game_data.get_subject(study_level, school_year, game_state.current_subject).name
	info_pill.text = "%s - %s   •   %d / %d" % [GameData.STUDY_NAMES[study_level], game_data.get_year_name(study_level, school_year),
		game_state.completed_level_count(study_level, school_year, game_state.current_subject), levels.size()]
	level_path.build(levels, game_state)
	var unlock_index := pending_unlock
	pending_unlock = -1
	if unlock_index >= 0:
		level_path.prepare_unlock(unlock_index)
	await get_tree().process_frame
	await get_tree().process_frame
	if levels.is_empty():
		return
	var focus := clampi(unlock_index if unlock_index >= 0 else game_state.current_level, 0, levels.size() - 1)
	scroll.scroll_vertical = int(level_path.node_center(focus).y - scroll.size.y / 2)
	if unlock_index >= 0:
		await get_tree().create_timer(0.3).timeout
		level_path.play_unlock(unlock_index)


func _on_level_pressed(level_index: int) -> void:
	if not game_manager.game_state.is_level_unlocked(level_index):
		Sfx.play("locked")
		level_path.nodes[level_index].shake()
		return
	Sfx.play("pop")
	level_selected.emit(level_index)
