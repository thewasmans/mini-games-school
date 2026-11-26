@tool
class_name HousingRoomData
extends Resource

@export var items: Array[HousingItemData] = []
@export var renovations: Array[HousingRenovationData] = []
@export var grid_size := Vector2i(8, 8)
