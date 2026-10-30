@abstract
class_name MiniGameUI
extends Control

signal completed
@warning_ignore("unused_signal")
signal progress_changed(completed_count: int, total_count: int)
signal mistake_made(mistake_count: int)

var is_completed := false
var mistake_count := 0


@abstract func initialize(mini_game_data: MiniGameData) -> void


@abstract func use_hint() -> bool


func _make_mistake() -> void:
	mistake_count += 1
	mistake_made.emit(mistake_count)


func _finish() -> void:
	if is_completed:
		return
	is_completed = true
	Sfx.play("win")
	Confetti.burst(self)
	completed.emit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
