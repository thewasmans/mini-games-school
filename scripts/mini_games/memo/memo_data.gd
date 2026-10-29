@tool
class_name MemoData
extends MiniGameData
## Quiz (mémo) : une suite de questions à 4 réponses.

@export var questions: Array[MemoQuestion] = []


func get_kind_name() -> String:
	return "Quiz"
