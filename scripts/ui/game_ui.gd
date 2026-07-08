class_name GameUI
extends Control

@export var respawn_button: Button

var _game_manager:GameManager

func initialize(game_manager:GameManager):
	_game_manager = game_manager
	respawn_button.pressed.connect(_on_respawn_button_pressed)	
	
func _on_respawn_button_pressed():
	_game_manager.demo_manager.respawn_player()
