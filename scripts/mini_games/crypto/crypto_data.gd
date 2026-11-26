@tool
class_name CryptoData
extends MiniGameData

@export var sentences: Array[CryptoSentence] = []
@export_range(0.05, 1.0, 0.05) var hidden_ratio: float = 0.4


func get_kind_name() -> String:
	return "Cryptogramme"


func get_kind_id() -> String:
	return "crypto"


func answer_words() -> PackedStringArray:
	var out := PackedStringArray()
	for sentence in sentences:
		out.append_array(TextUtil.words(sentence.sentence))
	return out
