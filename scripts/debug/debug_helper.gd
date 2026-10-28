class_name DebugHelper
extends CanvasLayer
## Barre de test (F1) en bas de la fenêtre, avec le thème par défaut de Godot.
## Ajoutée uniquement quand le jeu est lancé depuis l'éditeur.

const SCENE := "res://scenes/debug/debug_helper.tscn"

@onready var _bar: PanelContainer = $Bar
@onready var _auto_fill: CheckBox = $Bar/Row/AutoFill
@onready var _auto_validate: CheckBox = $Bar/Row/AutoValidate
@onready var _show_hints: CheckBox = $Bar/Row/ShowHints
@onready var _unlock_all: CheckBox = $Bar/Row/UnlockAll


static func create() -> DebugHelper:
	return load(SCENE).instantiate()


func _ready() -> void:
	# Le thème du jeu est le thème du projet : on impose celui de Godot à la barre.
	_bar.theme = ThemeDB.get_default_theme()
	for c: CheckBox in [_auto_fill, _auto_validate, _show_hints, _unlock_all]:
		c.toggled.connect(func(_on: bool) -> void: _apply())


func _apply() -> void:
	GameManager.set_debug(_auto_fill.button_pressed, _auto_validate.button_pressed, _show_hints.button_pressed, _unlock_all.button_pressed)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		_bar.visible = not _bar.visible
		get_viewport().set_input_as_handled()
