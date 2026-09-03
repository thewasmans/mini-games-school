class_name MiniGameCheat
extends RefCounted

const CHAR_INTERVAL := 0.06
const STEP_INTERVAL := 0.35

var ui

func _init(mini_game_ui: Node) -> void:
	ui = mini_game_ui

func hint_text() -> String:
	return ""

func autofill() -> void:
	pass

func _alive() -> bool:
	return is_instance_valid(ui) and ui.is_inside_tree()

func _wait(seconds: float) -> void:
	if not is_instance_valid(ui):
		return
	await ui.get_tree().create_timer(seconds).timeout
