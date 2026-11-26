@tool
class_name TextUtil
extends RefCounted

const _ACCENTS := {
	"À": "A", "Â": "A", "Ä": "A", "Á": "A", "Ã": "A", "Å": "A",
	"Ç": "C",
	"É": "E", "È": "E", "Ê": "E", "Ë": "E",
	"Î": "I", "Ï": "I", "Í": "I", "Ì": "I",
	"Ô": "O", "Ö": "O", "Ó": "O", "Ò": "O", "Õ": "O",
	"Ù": "U", "Û": "U", "Ü": "U", "Ú": "U",
	"Ÿ": "Y", "Ñ": "N",
}


static func normalize_char(c: String) -> String:
	var upper := c.to_upper()
	return _ACCENTS.get(upper, upper)


static func is_letter(c: String) -> bool:
	var n := normalize_char(c)
	return n.length() == 1 and ((n >= "A" and n <= "Z") or (n >= "0" and n <= "9"))


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


static func is_word_char(c: String) -> bool:
	return is_letter(c) or c.to_upper() == "Œ" or c.to_upper() == "Æ"


static func word_spans(text: String) -> Array[Vector2i]:
	var spans: Array[Vector2i] = []
	var start := -1
	for index in text.length():
		if is_word_char(text[index]):
			if start < 0:
				start = index
		elif start >= 0:
			spans.append(Vector2i(start, index))
			start = -1
	if start >= 0:
		spans.append(Vector2i(start, text.length()))
	return spans


static func words(text: String) -> PackedStringArray:
	var out := PackedStringArray()
	for span in word_spans(text):
		out.append(to_answer(text.substr(span.x, span.y - span.x)))
	return out


static func word_at(text: String, index: int) -> String:
	for span in word_spans(text):
		if index >= span.x and index < span.y:
			return to_answer(text.substr(span.x, span.y - span.x))
	return ""
