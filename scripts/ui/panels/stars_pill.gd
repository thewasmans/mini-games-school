@tool
class_name StarsPill
extends PanelContainer


func set_progress(progress: Vector2i) -> void:
	$Row/Inner/Count.text = "%d / %d" % [progress.x, progress.y]
