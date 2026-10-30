class_name Level
extends Control

signal validated(level_index: int, stars: float)
signal exited
signal validation_available
signal hint_requested

@export var top_bar: TopBar
@export var title_banner: TitleBanner
@export var progress_bar: JuicyProgressBar
@export var star_rating: StarRating
@export var hint_button: JuicyButton
@export var mini_game_container: Control
@export var missing_mini_game_label: Label
@export var validate_button: JuicyButton
@export var mini_game_prefabs: MiniGamePrefabs
@export var victory_banner_prefab: PackedScene

@export_group("Réglages")
## Délai entre la fin du mini-jeu et l'apparition du bouton Valider, en secondes.
@export var validate_delay := 0.9
## Étoiles obtenues sans aucune erreur.
@export var max_stars := 3.0
## Étoiles minimales pour un level terminé, quel que soit le nombre d'erreurs.
@export var min_stars := 1.0
## Étoiles perdues à chaque erreur.
@export var stars_lost_per_mistake := 0.1

var level_index: int
var mini_game_ui: MiniGameUI
var _validated := false
var _bonus_count := 0

var stars: float:
	get:
		var mistake_count := mini_game_ui.mistake_count if mini_game_ui != null else 0
		return snappedf(clampf(max_stars - mistake_count * stars_lost_per_mistake, min_stars, max_stars), 0.01)


func initialize(level_index_: int, level_data: LevelData, title: String) -> void:
	level_index = level_index_
	title_banner.text = title
	validate_button.hide()
	var prefab := mini_game_prefabs.prefab_for(level_data.mini_game) if level_data.mini_game != null else null
	missing_mini_game_label.visible = prefab == null
	progress_bar.visible = prefab != null
	star_rating.visible = prefab != null
	hint_button.visible = prefab != null
	if prefab == null:
		return
	mini_game_ui = prefab.instantiate() as MiniGameUI
	mini_game_container.add_child(mini_game_ui)
	mini_game_ui.progress_changed.connect(_on_mini_game_progress_changed)
	mini_game_ui.mistake_made.connect(_on_mini_game_mistake_made)
	mini_game_ui.completed.connect(_on_mini_game_completed)
	mini_game_ui.initialize(level_data.mini_game)
	star_rating.value = stars
	_refresh_hint_button()


func set_bonus_count(bonus_count: int) -> void:
	_bonus_count = bonus_count
	_refresh_hint_button()


func use_hint() -> bool:
	return mini_game_ui != null and not mini_game_ui.is_completed and mini_game_ui.use_hint()


func validate() -> void:
	if _validated or not validate_button.visible:
		return
	_validated = true
	validated.emit(level_index, stars)


func _refresh_hint_button() -> void:
	hint_button.text = str(_bonus_count)
	hint_button.disabled = _bonus_count <= 0 or mini_game_ui == null or mini_game_ui.is_completed


func _on_mini_game_progress_changed(completed_count: int, total_count: int) -> void:
	progress_bar.set_value(completed_count / float(maxi(total_count, 1)))


func _on_mini_game_mistake_made(_mistake_count: int) -> void:
	star_rating.value = stars
	UIFeedback.punch(star_rating, 0.15, 0.35)


func _on_mini_game_completed() -> void:
	_refresh_hint_button()
	var victory_banner := victory_banner_prefab.instantiate() as VictoryBanner
	victory_banner.stars = stars
	add_child(victory_banner)
	await get_tree().create_timer(validate_delay).timeout
	validate_button.show()
	validate_button.set_shine(true)
	UIFeedback.pop_in(validate_button, 0.0, 0.3)
	validation_available.emit()
	await get_tree().create_timer(0.5).timeout
	UIFeedback.breathe(validate_button, 0.04, 1.0)


func _on_validate_button_pressed() -> void:
	validate()


func _on_hint_button_pressed() -> void:
	hint_requested.emit()


func _on_back_pressed() -> void:
	exited.emit()
