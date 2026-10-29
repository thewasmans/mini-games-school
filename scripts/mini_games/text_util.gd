@tool
class_name TextUtil
extends RefCounted
## Normalisation des lettres : majuscules sans accents, pour comparer les réponses.

const _ACCENTS := {
	"À": "A", "Â": "A", "Ä": "A", "Á": "A", "Ã": "A", "Å": "A",
	"Ç": "C",
	"É": "E", "È": "E", "Ê": "E", "Ë": "E",
	"Î": "I", "Ï": "I", "Í": "I", "Ì": "I",
	"Ô": "O", "Ö": "O", "Ó": "O", "Ò": "O", "Õ": "O",
	"Ù": "U", "Û": "U", "Ü": "U", "Ú": "U",
	"Ÿ": "Y", "Ñ": "N",
}


## "é" -> "E"
static func normalize_char(c: String) -> String:
	var upper := c.to_upper()
	return _ACCENTS.get(upper, upper)


## Vrai pour une lettre (accentuée ou non) ou un chiffre.
static func is_letter(c: String) -> bool:
	var n := normalize_char(c)
	return n.length() == 1 and ((n >= "A" and n <= "Z") or (n >= "0" and n <= "9"))


## Ne garde que les lettres, sans accents : "Cœur" -> "COEUR", "Arc-en-ciel" -> "ARCENCIEL".
static func to_answer(word: String) -> String:
	var out := ""
	for c in word:
		var upper := c.to_upper()
		if upper == "Œ":
			out += "OE"
		elif upper == "Æ":
			out += "AE"
		elif is_letter(c):
			out += normalize_char(c)
	return out
