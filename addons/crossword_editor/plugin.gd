@tool
extends EditorPlugin

const CrosswordPanel := preload("res://addons/crossword_editor/crossword_panel.gd")

var _panel: CrosswordPanel


func _enter_tree() -> void:
	_panel = CrosswordPanel.new()
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	EditorInterface.get_editor_main_screen().add_child(_panel)
	_make_visible(false)


func _exit_tree() -> void:
	if is_instance_valid(_panel):
		_panel.queue_free()


func _has_main_screen() -> bool:
	return true


func _get_plugin_name() -> String:
	return "Crossword"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("GridContainer", "EditorIcons")


func _make_visible(visible: bool) -> void:
	if is_instance_valid(_panel):
		_panel.visible = visible


func _handles(object: Object) -> bool:
	return object is CrosswordData


func _edit(object: Object) -> void:
	if object is CrosswordData:
		_panel.open(object)
