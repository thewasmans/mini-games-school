class_name Level
extends Control

signal validated(level_index: int, stars: float)
signal exited
signal validation_available
signal hint_requested

@export var top_bar: TopBar
@export var title_banner: TitleBanner
@export var star_gauge: StarGauge
@export var hint_button: JuicyButton
@export var mini_game_container: Control
@export var missing_mini_game_label: Label
@export var validate_button: JuicyButton
@export var mini_game_prefabs: MiniGamePrefabs
@export var victory_banner_prefab: PackedScene

@export_group("Réglages")
## Délai entre la fin du mini-jeu et l'apparition du bouton Valider, en secondes.
@export var validate_delay := 0.9
## Points d'une bonne réponse selon le nombre d'erreurs faites dessus : sans erreur, après 1 erreur, après 2... La dernière valeur vaut pour toutes les erreurs suivantes.
@export var points_by_mistakes: Array[int] = [10, 5, 2, 0]
## Points maximum d'une bonne réponse obtenue avec un indice.
@export var hint_points := 4
## Part du score maximum où se trouve la 1re étoile sur la jauge.
@export_range(0.0, 1.0) var one_star_ratio := 0.3
## Part du score maximum où se trouve la 2e étoile sur la jauge.
@export_range(0.0, 1.0) var two_stars_ratio := 0.6
## Part du score maximum où se trouve la 3e étoile sur la jauge.
@export_range(0.0, 1.0) var three_stars_ratio := 0.9

var level_index: int
var mini_game_ui: MiniGameUI
var _validated := false
var _bonus_count := 0
var score := 0

var max_score: int:
	get:
		return mini_game_ui.answer_total * points_by_mistakes[0] if mini_game_ui != null else 0

var score_ratio: float:
	get:
		return score / float(max_score) if max_score > 0 else 0.0

var stars: float:
	get:
		var reached := 0
		for threshold in star_thresholds():
			if score_ratio >= threshold - 0.0001:
				reached += 1
		return float(reached)


func initialize(level_index_: int, level_data: LevelData, title: String) -> void:
	level_index = level_index_
	title_banner.text = title
	validate_button.hide()
	var prefab := mini_game_prefabs.prefab_for(level_data.mini_game) if level_data.mini_game != null else null
	missing_mini_game_label.visible = prefab == null
	star_gauge.visible = prefab != null
	hint_button.visible = prefab != null
	if prefab == null:
		return
	mini_game_ui = prefab.instantiate() as MiniGameUI
	mini_game_container.add_child(mini_game_ui)
	mini_game_ui.answer_found.connect(_on_mini_game_answer_found)
	mini_game_ui.completed.connect(_on_mini_game_completed)
	mini_game_ui.initialize(level_data.mini_game)
	star_gauge.initialize(star_thresholds())
	star_gauge.star_reached.connect(_on_star_reached)
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


func star_thresholds() -> Array[float]:
	return [one_star_ratio, two_stars_ratio, three_stars_ratio]


func _refresh_hint_button() -> void:
	hint_button.text = str(_bonus_count)
	hint_button.disabled = _bonus_count <= 0 or mini_game_ui == null or mini_game_ui.is_completed


func points_for(mistake_count: int, hinted: bool) -> int:
	var points := points_by_mistakes[mini(mistake_count, points_by_mistakes.size() - 1)]
	return mini(points, hint_points) if hinted else points


func _on_mini_game_answer_found(mistake_count: int, hinted: bool) -> void:
	score += points_for(mistake_count, hinted)
	star_gauge.set_value(score_ratio)


func _on_star_reached(_star_index: int) -> void:
	Sfx.play("unlock")


func _on_mini_game_completed() -> void:
	_refresh_hint_button()
	var victory_banner := victory_banner_prefab.instantiate() as VictoryBanner
	victory_banner.stars = stars
	victory_banner.score = score
	victory_banner.max_score = max_score
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
