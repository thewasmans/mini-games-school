class_name MenuStudyLevelsUI
extends MenuUI

signal study_level_selected(study_level_index: int)

@export var panel: MenuPanel
@export var entries: Array[ChoiceEntryUI] = []


func initialize(game_manager_: GameManager) -> void:
	super.initialize(game_manager_)
	for study_level_index in entries.size():
		entries[study_level_index].pressed.connect(study_level_selected.emit.bind(study_level_index))


func _refresh() -> void:
	var game_state := game_manager.game_state
	UIFeedback.pop_in(panel, 0.1, 0.85)
	for study_level_index in entries.size():
		var entry := entries[study_level_index]
		entry.set_progress(game_state.completed_level_count(study_level_index), game_state.level_count(study_level_index))
		UIFeedback.pop_in(entry, 0.2 + study_level_index * 0.1, 0.5)
