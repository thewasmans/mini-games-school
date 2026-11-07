@tool
extends EditorPlugin

const CrosswordEditorPanel := preload("res://addons/crossword/crossword_editor_panel.gd")

var _panel: CrosswordEditorPanel

func _enter_tree() -> void:
	_panel = CrosswordEditorPanel.new()
	EditorInterface.get_editor_main_screen().add_child(_panel)
	_make_visible(false)

func _exit_tree() -> void:
	_panel.queue_free()

func _has_main_screen() -> bool:
	return true

func _handles(object: Object) -> bool:
	return object is CrosswordData

func _edit(object: Object) -> void:
	if object == null:
		return
	EditorInterface.set_main_screen_editor(_get_plugin_name())
	_panel.open_crossword(object)

func _make_visible(visible: bool) -> void:
	if _panel != null:
		_panel.visible = visible

func _get_plugin_name() -> String:
	return "Crossword"

func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("GridContainer", "EditorIcons")
