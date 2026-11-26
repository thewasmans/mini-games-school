@tool
class_name HousingItemData
extends Resource

enum Slot { FLOOR, WALL, CEILING }

@export var word: String = ""
@export var variants: PackedStringArray = PackedStringArray()
@export var title: String = ""
@export_multiline var description: String = ""
@export_multiline var mnemonic: String = ""
@export var slot := Slot.FLOOR
@export var footprint := Vector2i.ONE
@export var model: PackedScene


func matching_words() -> PackedStringArray:
	var out := PackedStringArray([TextUtil.to_answer(word)])
	for variant in variants:
		out.append(TextUtil.to_answer(variant))
	return out


func cells_at(origin: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in footprint.x:
		for y in footprint.y:
			cells.append(origin + Vector2i(x, y))
	return cells
