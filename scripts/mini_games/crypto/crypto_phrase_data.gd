class_name CryptoPhraseData
extends Resource

@export var text: String = "":
	set(value):
		text = value.strip_edges()

@export var hint: String = ""
