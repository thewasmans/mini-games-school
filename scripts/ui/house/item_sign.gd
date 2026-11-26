class_name ItemSign
extends Control

signal replay_requested(item: HousingItemData)

@export var panel: TitledPanel
@export var description_label: Label
@export var mnemonic_label: Label
@export var replay_button: JuicyButton
@export var close_button: JuicyButton

var _item: HousingItemData


func _ready() -> void:
	close_button.pressed.connect(hide)
	replay_button.pressed.connect(func() -> void: replay_requested.emit(_item))


func show_item(item: HousingItemData) -> void:
	_item = item
	panel.title = item.title
	description_label.text = item.description
	description_label.visible = not item.description.is_empty()
	mnemonic_label.text = item.mnemonic
	mnemonic_label.visible = not item.mnemonic.is_empty()
	show()
	UIFeedback.pop_in(panel, 0.0, 0.85)
