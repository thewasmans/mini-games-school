class_name CryptoMasker
extends RefCounted

static func mask(phrase_data: CryptoPhraseData, hidden_letter_ratio: float, rng: RandomNumberGenerator = null) -> CryptoPuzzle:
	var random := rng
	if random == null:
		random = RandomNumberGenerator.new()
		random.randomize()
	var letter_indices: Array[int] = []
	for character_index in phrase_data.text.length():
		if _is_maskable(phrase_data.text[character_index]):
			letter_indices.append(character_index)
	var hidden_count := clampi(roundi(letter_indices.size() * hidden_letter_ratio), 0, letter_indices.size())
	_shuffle(letter_indices, random)
	var hidden_indices: Array[int] = letter_indices.slice(0, hidden_count)
	hidden_indices.sort()
	return CryptoPuzzle.new(phrase_data, hidden_indices)

static func _is_maskable(character: String) -> bool:
	return character.strip_edges() != "" and character.to_lower() != character.to_upper()

static func _shuffle(values: Array[int], random: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := random.randi_range(0, i)
		var temp := values[i]
		values[i] = values[j]
		values[j] = temp
