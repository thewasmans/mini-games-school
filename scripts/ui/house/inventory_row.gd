class_name InventoryRow
extends PanelContainer

signal take_pressed(item: HousingItemData)
signal play_pressed(item: HousingItemData)

@export var title_label: Label
@export var status_label: Label
@export var bar: JuicyProgressBar
@export var value_label: Label
@export var action_button: JuicyButton

var item: HousingItemData
var _unlocked := false


func _ready() -> void:
	action_button.pressed.connect(_on_action_button_pressed)


func initialize(item_data: HousingItemData, gauge: Vector2i, unlocked: bool, placed: bool, levels: Array[int]) -> void:
	item = item_data
	_unlocked = unlocked
	title_label.text = item_data.title if unlocked else "???"
	modulate = Color.WHITE if unlocked else Color(0.75, 0.78, 0.85)
	bar.set_value(gauge.x / float(maxi(gauge.y, 1)), false)
	value_label.text = "%d / %d" % [gauge.x, gauge.y]
	action_button.visible = not placed
	action_button.text = "PRENDRE" if unlocked else "JOUER"
	if placed:
		status_label.text = "Posé dans la pièce"
	elif unlocked:
		status_label.text = "Prêt à être posé"
	elif levels.is_empty():
		status_label.text = "Pas encore dans les levels"
		action_button.hide()
	else:
		var numbers := PackedStringArray()
		for level_index in levels:
			numbers.append(str(level_index + 1))
		status_label.text = "À découvrir dans les levels " + ", ".join(numbers)


func _on_action_button_pressed() -> void:
	if _unlocked:
		take_pressed.emit(item)
	else:
		play_pressed.emit(item)
