@tool
class_name GameManager
extends Node

signal initialized

@export var game_data: GameData
@export_category("Managers")
@export var game_ui_manager: GameUIManager
@export var level_manager: LevelManager

var game_state: GameState

var managers: Array[Manager]:
	get:
		return [game_ui_manager, level_manager]


func _ready() -> void:
	if Engine.is_editor_hint():
		child_entered_tree.connect(_on_children_changed)
		child_exiting_tree.connect(_on_children_changed)


func initialize() -> void:
	game_state = GameState.new(game_data)
	for manager in managers:
		manager.initialize(self)
	initialized.emit()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	for child in get_children():
		if child is Manager and child not in managers:
			warnings.append("%s n'est pas dans le getter « managers » : il ne sera jamais initialisé." % child.name)
	return warnings


func _on_children_changed(_child: Node) -> void:
	update_configuration_warnings.call_deferred()
