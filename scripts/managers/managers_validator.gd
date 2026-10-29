@tool
class_name ManagersValidator
extends Node

const REFRESH_INTERVAL := 1.0

@export var game_manager: GameManager

var _refresh_countdown := 0.0


func _ready() -> void:
	set_process(Engine.is_editor_hint())


func _process(delta: float) -> void:
	_refresh_countdown -= delta
	if _refresh_countdown <= 0.0:
		_refresh_countdown = REFRESH_INTERVAL
		update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	var listed := _referenced_nodes(game_manager.get(&"managers"))
	if listed.has(null):
		warnings.append("La liste « managers » du GameManager contient une entrée vide.")
	for child in game_manager.get_children():
		if not child is Manager:
			continue
		var count := listed.count(child)
		if count == 0:
			warnings.append("%s n'est pas dans la liste « managers » du GameManager : il ne sera jamais initialisé." % child.name)
		elif count > 1:
			warnings.append("%s est %d fois dans la liste « managers » du GameManager : il sera initialisé plusieurs fois." % [child.name, count])
	return warnings


func _referenced_nodes(values: Variant) -> Array[Node]:
	var nodes: Array[Node] = []
	if values == null:
		return nodes
	for value in values:
		if value is NodePath:
			nodes.append(game_manager.get_node_or_null(value))
		else:
			nodes.append(value as Node)
	return nodes
