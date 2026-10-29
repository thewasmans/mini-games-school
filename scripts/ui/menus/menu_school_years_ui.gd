class_name MenuSchoolYearsUI
extends MenuUI

signal school_year_selected(school_year_index: int)

@export var title_banner: TitleBanner
@export var panel: MenuPanel
@export var entries: Array[ChoiceEntryUI] = []

@export_group("Réglages")
## Couleur des boutons d'années, pour chaque niveau d'études (Primaire, Secondaire, Supérieur).
@export var study_level_colors: Array[Color] = [Color("ff9a1f"), Color("4cc24a"), Color("a855e0")]


func initialize(game_manager_: GameManager) -> void:
	super.initialize(game_manager_)
	for school_year_index in entries.size():
		entries[school_year_index].pressed.connect(school_year_selected.emit.bind(school_year_index))


func _refresh() -> void:
	var game_state := game_manager.game_state
	var game_data := game_manager.game_data
	var study_level := game_state.current_study_level
	title_banner.text = GameData.STUDY_NAMES[study_level].to_upper()
	UIFeedback.pop_in(panel, 0.1, 0.85)
	for school_year_index in entries.size():
		var entry := entries[school_year_index]
		entry.button.text = game_data.get_year_name(study_level, school_year_index)
		entry.set_color(study_level_colors[study_level])
		entry.set_progress(game_state.completed_level_count(study_level, school_year_index), game_state.level_count(study_level, school_year_index))
		UIFeedback.pop_in(entry, 0.15 + school_year_index * 0.06, 0.5)
