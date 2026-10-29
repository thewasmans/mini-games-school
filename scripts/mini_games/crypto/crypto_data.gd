@tool
class_name CryptoData
extends MiniGameData
## Cryptogramme : des phrases dont une partie des lettres est cachée.

@export var sentences: Array[CryptoSentence] = []
## Proportion de lettres cachées, tirées au hasard à chaque partie.
@export_range(0.05, 1.0, 0.05) var hidden_ratio: float = 0.4


func get_kind_name() -> String:
	return "Cryptogramme"
