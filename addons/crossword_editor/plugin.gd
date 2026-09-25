@tool
extends EditorPlugin

const CrosswordEditorPanel := preload("res://addons/crossword_editor/crossword_editor_panel.gd")

var _panel: CrosswordEditorPanel

func _enter_tree() -> void:
	_panel = CrosswordEditorPanel.new()
	EditorInterface.get_editor_main_screen().add_child(_panel)
	_make_visible(false)

func _exit_tree() -> void:
	_panel.queue_free()

func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if _panel != null:
		_panel.visible = visible

func _get_plugin_name() -> String:
	return "Mots croisés"

func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("GridContainer", "EditorIcons")
