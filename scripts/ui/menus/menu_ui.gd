@abstract
class_name MenuUI
extends Control

signal back_pressed

@export var top_bar: TopBar

var game_manager: GameManager


func initialize(game_manager_: GameManager) -> void:
	game_manager = game_manager_


func show_menu() -> void:
	top_bar.set_progress(game_manager.game_state.total_progress())
	_refresh()


@abstract func _refresh() -> void


func _on_back_pressed() -> void:
	back_pressed.emit()
