@tool
class_name CrosswordGenerator
extends RefCounted

const H := 1
const V := 2


static func generate(data: CrosswordData) -> void:
	var words: Array[CrosswordEntry] = []
	for e in data.entries:
		if e == null:
			continue
		e.answer = TextUtil.to_answer(e.word)
		e.placed = false
		e.number = 0
		e.x = 0
		e.y = 0
		if e.answer.length() >= 2:
			words.append(e)

	data.grid_width = 0
	data.grid_height = 0
	if words.is_empty():
		return

	var order := {}
	for i in words.size():
		order[words[i]] = i
	words.sort_custom(func(a: CrosswordEntry, b: CrosswordEntry) -> bool:
		if a.answer.length() != b.answer.length():
			return a.answer.length() > b.answer.length()
		return order[a] < order[b])

	var letters := {}
	var dirs := {}
	var pending: Array[CrosswordEntry] = words.duplicate()
	_place(letters, dirs, pending.pop_front(), Vector2i.ZERO, true)

	var progress := true
	while progress and not pending.is_empty():
		progress = false
		for e in pending.duplicate():
			var spot := _best_spot(letters, dirs, e.answer)
			if spot.is_empty():
				continue
			_place(letters, dirs, e, spot.start, spot.horizontal)
			pending.erase(e)
			progress = true

	for e in pending:
		var b := _bounds(letters)
		_place(letters, dirs, e, Vector2i(b.position.x, b.end.y + 1), true)

	var bounds := _bounds(letters)
	for e in words:
		e.x -= bounds.position.x
		e.y -= bounds.position.y
	data.grid_width = bounds.size.x
	data.grid_height = bounds.size.y
	_number(words)
	data.emit_changed()


static func analyze(data: CrosswordData) -> Dictionary:
	var letters := {}
	var owners := {}
	var conflicts: Array[Vector2i] = []
	for e in data.get_placed_entries():
		for k in e.answer.length():
			var p := _cell(e, k)
			if letters.has(p) and letters[p] != e.answer[k] and not conflicts.has(p):
				conflicts.append(p)
			letters[p] = e.answer[k]
			owners[p] = owners.get(p, 0) + 1
	var isolated: Array[CrosswordEntry] = []
	for e in data.get_placed_entries():
		var crossings := 0
		for k in e.answer.length():
			if owners[_cell(e, k)] > 1:
				crossings += 1
		if crossings == 0 and data.get_placed_entries().size() > 1:
			isolated.append(e)
	return {"isolated": isolated, "conflicts": conflicts}


static func _cell(e: CrosswordEntry, k: int) -> Vector2i:
	return Vector2i(e.x + k, e.y) if e.horizontal else Vector2i(e.x, e.y + k)


static func _place(letters: Dictionary, dirs: Dictionary, e: CrosswordEntry, start: Vector2i, horizontal: bool) -> void:
	var dir := Vector2i(1, 0) if horizontal else Vector2i(0, 1)
	for k in e.answer.length():
		var p := start + dir * k
		letters[p] = e.answer[k]
		dirs[p] = dirs.get(p, 0) | (H if horizontal else V)
	e.x = start.x
	e.y = start.y
	e.horizontal = horizontal
	e.placed = true


static func _best_spot(letters: Dictionary, dirs: Dictionary, word: String) -> Dictionary:
	var best := {}
	var best_score := -INF
	for cell: Vector2i in letters.keys():
		for i in word.length():
			if word[i] != letters[cell]:
				continue
			for horizontal: bool in [true, false]:
				var dir := Vector2i(1, 0) if horizontal else Vector2i(0, 1)
				var start: Vector2i = cell - dir * i
				var crossings := _fit(letters, dirs, word, start, horizontal)
				if crossings <= 0:
					continue
				var b := _bounds(letters).merge(Rect2i(start, dir * (word.length() - 1) + Vector2i.ONE))
				var score := crossings * 100.0 - maxi(b.size.x, b.size.y) * 6.0 - b.get_area() * 0.4
				if score > best_score:
					best_score = score
					best = {"start": start, "horizontal": horizontal}
	return best


static func _fit(letters: Dictionary, dirs: Dictionary, word: String, start: Vector2i, horizontal: bool) -> int:
	var dir := Vector2i(1, 0) if horizontal else Vector2i(0, 1)
	var perp := Vector2i(0, 1) if horizontal else Vector2i(1, 0)
	var mask := H if horizontal else V
	if letters.has(start - dir) or letters.has(start + dir * word.length()):
		return -1
	var crossings := 0
	for k in word.length():
		var p := start + dir * k
		if letters.has(p):
			if letters[p] != word[k] or (dirs[p] & mask) != 0:
				return -1
			crossings += 1
		elif letters.has(p + perp) or letters.has(p - perp):
			return -1
	return crossings


static func _bounds(letters: Dictionary) -> Rect2i:
	var first := true
	var lo := Vector2i.ZERO
	var hi := Vector2i.ZERO
	for p: Vector2i in letters.keys():
		if first:
			lo = p
			hi = p
			first = false
		else:
			lo = lo.min(p)
			hi = hi.max(p)
	return Rect2i(lo, hi - lo + Vector2i.ONE)


static func _number(words: Array[CrosswordEntry]) -> void:
	var placed := words.filter(func(e: CrosswordEntry) -> bool: return e.placed)
	placed.sort_custom(func(a: CrosswordEntry, b: CrosswordEntry) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	var starts := {}
	for e: CrosswordEntry in placed:
		var key := Vector2i(e.x, e.y)
		if not starts.has(key):
			starts[key] = starts.size() + 1
		e.number = starts[key]
