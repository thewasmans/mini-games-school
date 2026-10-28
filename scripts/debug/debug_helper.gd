class_name DebugHelper
extends CanvasLayer
## Panneau de test (F1). Ajouté uniquement quand le jeu est lancé depuis l'éditeur.

var _panel: PanelContainer
var _auto_fill: CheckBox
var _auto_validate: CheckBox
var _show_hints: CheckBox
var _unlock_all: CheckBox


func _ready() -> void:
	layer = 90
	_panel = PanelContainer.new()
	_panel.theme = UIStyle.theme()
	var sb := UIStyle.box(Color(0.05, 0.07, 0.2, 0.92), 18, 0, 3, UIStyle.YELLOW)
	sb.set_content_margin_all(18)
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.position = Vector2(20, 120)
	_panel.visible = false
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)
	var title := UIStyle.label("Helper de test (F1)", 26, UIStyle.YELLOW, 6)
	box.add_child(title)
	_auto_fill = _check(box, "Auto select / prefill")
	_auto_validate = _check(box, "Auto validate")
	_show_hints = _check(box, "Show hints")
	_unlock_all = _check(box, "Unlock all levels")
	var note := UIStyle.label("Unlock all : effet visible au prochain\naffichage de la grille.", 16, Color("c8d2ff"), 0)
	box.add_child(note)


func _check(parent: Control, text: String) -> CheckBox:
	var c := CheckBox.new()
	c.text = text
	c.focus_mode = Control.FOCUS_NONE
	c.add_theme_font_size_override("font_size", 22)
	c.add_theme_constant_override("outline_size", 4)
	c.toggled.connect(func(_on: bool) -> void: _apply())
	parent.add_child(c)
	return c


func _apply() -> void:
	GameManager.set_debug(_auto_fill.button_pressed, _auto_validate.button_pressed, _show_hints.button_pressed, _unlock_all.button_pressed)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		_panel.visible = not _panel.visible
		if _panel.visible:
			UIFeedback.pop_in(_panel, 0.0, 0.8)
		get_viewport().set_input_as_handled()
