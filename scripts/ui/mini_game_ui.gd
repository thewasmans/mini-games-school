@abstract
class_name MiniGameUI
extends Control

signal completed
signal progress_changed(completed_count: int, total_count: int)

var is_completed := false


@abstract func initialize(mini_game_data: MiniGameData) -> void


func _finish() -> void:
	if is_completed:
		return
	is_completed = true
	Sfx.play("win")
	Confetti.burst(self)
	completed.emit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
