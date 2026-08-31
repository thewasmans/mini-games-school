class_name CryptoPuzzle
extends RefCounted

var phrase_data: CryptoPhraseData
var hidden_indices: Array[int]

func _init(_phrase_data: CryptoPhraseData, _hidden_indices: Array[int]) -> void:
	phrase_data = _phrase_data
	hidden_indices = _hidden_indices

func solution() -> String:
	return phrase_data.text

func is_hidden(character_index: int) -> bool:
	return character_index in hidden_indices

func masked_text(placeholder: String = "_") -> String:
	var result := ""
	for character_index in phrase_data.text.length():
		result += placeholder if is_hidden(character_index) else phrase_data.text[character_index]
	return result
