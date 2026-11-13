class_name LetterNormalizer
extends RefCounted

const KEYBOARD_LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const BASE_LETTERS := {
	"À": "A", "Á": "A", "Â": "A", "Ã": "A", "Ä": "A",
	"Ç": "C",
	"È": "E", "É": "E", "Ê": "E", "Ë": "E",
	"Ì": "I", "Í": "I", "Î": "I", "Ï": "I",
	"Ñ": "N",
	"Ò": "O", "Ó": "O", "Ô": "O", "Õ": "O", "Ö": "O",
	"Ù": "U", "Ú": "U", "Û": "U", "Ü": "U",
	"Ý": "Y", "Ÿ": "Y",
}

static func base_letter(character: String) -> String:
	var upper := character.to_upper()
	return BASE_LETTERS.get(upper, upper)

static func is_typeable(character: String) -> bool:
	var base := base_letter(character)
	return base.length() == 1 and KEYBOARD_LETTERS.contains(base)

static func base_text(text: String) -> String:
	var result := ""
	for character in text:
		result += base_letter(character)
	return result

static func matches(typed_text: String, expected_text: String) -> bool:
	return base_text(typed_text) == base_text(expected_text)
