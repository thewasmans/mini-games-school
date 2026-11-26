@tool
class_name HousingRenovationData
extends Resource

@export var title: String = ""
@export var cost := 3
@export var slot := HousingItemData.Slot.FLOOR
@export var cells: Array[Vector2i] = []
