@tool
class_name MiniGameData
extends Resource

@export var theme_title: String = ""


func get_kind_name() -> String:
	return "Mini-jeu"


func get_kind_id() -> String:
	return ""


func answer_words() -> PackedStringArray:
	return PackedStringArray()
