@tool
class_name ActionPointsPill
extends PanelContainer


func set_points(action_points: int) -> void:
	$Row/Inner/Count.text = str(action_points)
