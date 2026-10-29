@tool
class_name MemoData
extends MiniGameData

@export var questions: Array[MemoQuestion] = []


func get_kind_name() -> String:
	return "Quiz"


func get_kind_id() -> String:
	return "memo"
