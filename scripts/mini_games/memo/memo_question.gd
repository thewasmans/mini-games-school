@tool
class_name MemoQuestion
extends Resource

@export_multiline var question: String = ""
@export var answers: PackedStringArray = PackedStringArray(["", "", "", ""])
@export_range(0, 3) var correct_index: int = 0
@export var image: Texture2D
