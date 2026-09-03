class_name MiniGameCheat
extends RefCounted

const CHAR_INTERVAL := 0.06
const STEP_INTERVAL := 0.35

var ui
var _cancelled := false

func _init(mini_game_ui: Node) -> void:
	ui = mini_game_ui

func hint_text() -> String:
	return ""

func arm() -> void:
	_cancelled = false

func cancel() -> void:
	_cancelled = true

func autofill() -> void:
	pass

func _running() -> bool:
	return not _cancelled and is_instance_valid(ui) and ui.is_inside_tree()

func _wait(seconds: float) -> void:
	if not is_instance_valid(ui):
		return
	await ui.get_tree().create_timer(seconds).timeout
