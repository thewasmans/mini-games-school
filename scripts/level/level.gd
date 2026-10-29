class_name Level
extends Control

signal validated(level_index: int)
signal exited
signal validation_available

@export var top_bar: TopBar
@export var title_banner: TitleBanner
@export var progress_bar: JuicyProgressBar
@export var mini_game_container: Control
@export var missing_mini_game_label: Label
@export var validate_button: JuicyButton
@export var mini_game_prefabs: MiniGamePrefabs
@export var victory_banner_prefab: PackedScene

@export_group("Réglages")
## Délai entre la fin du mini-jeu et l'apparition du bouton Valider, en secondes.
@export var validate_delay := 0.9

var level_index: int
var mini_game_ui: MiniGameUI
var _validated := false


func initialize(level_index_: int, level_data: LevelData, title: String) -> void:
	level_index = level_index_
	title_banner.text = title
	validate_button.hide()
	var prefab := mini_game_prefabs.prefab_for(level_data.mini_game) if level_data.mini_game != null else null
	missing_mini_game_label.visible = prefab == null
	progress_bar.visible = prefab != null
	if prefab == null:
		return
	mini_game_ui = prefab.instantiate() as MiniGameUI
	mini_game_container.add_child(mini_game_ui)
	mini_game_ui.progress_changed.connect(_on_mini_game_progress_changed)
	mini_game_ui.completed.connect(_on_mini_game_completed)
	mini_game_ui.initialize(level_data.mini_game)


func validate() -> void:
	if _validated or not validate_button.visible:
		return
	_validated = true
	validated.emit(level_index)


func _on_mini_game_progress_changed(completed_count: int, total_count: int) -> void:
	progress_bar.set_value(completed_count / float(maxi(total_count, 1)))


func _on_mini_game_completed() -> void:
	add_child(victory_banner_prefab.instantiate())
	await get_tree().create_timer(validate_delay).timeout
	validate_button.show()
	validate_button.set_shine(true)
	UIFeedback.pop_in(validate_button, 0.0, 0.3)
	validation_available.emit()
	await get_tree().create_timer(0.5).timeout
	UIFeedback.breathe(validate_button, 0.04, 1.0)


func _on_validate_button_pressed() -> void:
	validate()


func _on_back_pressed() -> void:
	exited.emit()
