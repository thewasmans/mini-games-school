@abstract
class_name MiniGameUI
extends Control

signal completed
@warning_ignore("unused_signal")
signal progress_changed(completed_count: int, total_count: int)
signal mistake_made
signal answer_found(mistake_count: int, hinted: bool)

var is_completed := false
var answer_total := 0
var mistake_count := 0
var found_answers: Array[Dictionary] = []
var _missed_answers: Dictionary = {}
var _hinted_answers: Dictionary = {}


@abstract func initialize(mini_game_data: MiniGameData) -> void


@abstract func use_hint() -> bool


func _make_mistake(answer_key: Variant) -> void:
	mistake_count += 1
	_missed_answers[answer_key] = _missed_answers.get(answer_key, 0) + 1
	mistake_made.emit()


func _mark_hinted(answer_key: Variant) -> void:
	_hinted_answers[answer_key] = true


func answer_words(_answer_key: Variant) -> PackedStringArray:
	return PackedStringArray()


func _answer_found(answer_key: Variant) -> void:
	var missed: int = _missed_answers.get(answer_key, 0)
	var hinted := _hinted_answers.has(answer_key)
	found_answers.append({"words": answer_words(answer_key), "mistakes": missed, "hinted": hinted})
	answer_found.emit(missed, hinted)


func _finish() -> void:
	if is_completed:
		return
	is_completed = true
	Sfx.play("win")
	Confetti.burst(self)
	completed.emit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
