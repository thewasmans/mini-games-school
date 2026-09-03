class_name WordData
extends Resource

@export var word: String = "":
	set(value):
		word = value.to_upper().strip_edges()

@export var hint: String = ""
