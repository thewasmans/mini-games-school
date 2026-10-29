class_name MenuSubjectsUI
extends MenuUI

signal subject_selected(subject_index: int)

@export var title_banner: TitleBanner
@export var panel: MenuPanel
@export var entries_container: Container
@export var coming_soon_label: Label
@export var choice_entry_prefab: PackedScene

@export_group("Réglages")
## Couleurs utilisées pour les matières qui n'ont pas de couleur dans leurs données.
@export var subject_colors: Array[Color] = [Color("3d84f2"), Color("ff9a1f"), Color("4cc24a"), Color("a855e0"), Color("ff5d8f"), Color("1fc6b4")]


func _refresh() -> void:
	var game_state := game_manager.game_state
	var game_data := game_manager.game_data
	var study_level := game_state.current_study_level
	var school_year := game_state.current_school_year
	title_banner.text = "%s - %s" % [GameData.STUDY_NAMES[study_level], game_data.get_year_name(study_level, school_year)]
	UIFeedback.pop_in(panel, 0.1, 0.85)
	for child in entries_container.get_children():
		entries_container.remove_child(child)
		child.queue_free()
	var year := game_data.get_year(study_level, school_year)
	var subjects: Array[SubjectData] = year.subjects if year != null else [] as Array[SubjectData]
	coming_soon_label.visible = subjects.is_empty()
	for subject_index in subjects.size():
		var subject := subjects[subject_index]
		var entry := choice_entry_prefab.instantiate() as ChoiceEntryUI
		entries_container.add_child(entry)
		entry.button.text = subject.name
		entry.set_color(subject.color if subject.color.a > 0 else subject_colors[subject_index % subject_colors.size()])
		entry.set_progress(game_state.completed_level_count(study_level, school_year, subject_index), subject.levels.size())
		entry.pressed.connect(subject_selected.emit.bind(subject_index))
		UIFeedback.pop_in(entry, 0.15 + subject_index * 0.08, 0.5)
