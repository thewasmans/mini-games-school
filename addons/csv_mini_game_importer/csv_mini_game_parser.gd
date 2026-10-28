@tool
class_name CsvMiniGameParser
extends RefCounted
## Lit un CSV et construit la ressource du mini-jeu correspondant.
## Détection : en-tête (mot / question / phrase), ligne « ratio », nombre de colonnes.

const IMAGE_DIR := "res://content/images"
const IMAGE_EXTENSIONS: Array[String] = ["png", "jpg", "jpeg", "webp", "svg"]

const KIND_CROSSWORD := "Mots croisés"
const KIND_QUIZ := "Quiz"
const KIND_CRYPTO := "Cryptogramme"


## Renvoie { ok, error, kind, resource, entries: Array[String], warnings: Array[String] }
static func parse(path: String) -> Dictionary:
	var result := {"ok": false, "error": "", "kind": "", "resource": null,
		"entries": [], "warnings": []}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		result.error = "Impossible d'ouvrir le fichier (%s)." % error_string(FileAccess.get_open_error())
		return result
	var text := file.get_as_text()
	if text.begins_with("﻿"):
		text = text.substr(1)

	var lines := PackedStringArray()
	for raw in text.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
		if raw.strip_edges() != "" and not raw.strip_edges().begins_with("#"):
			lines.append(raw)
	if lines.is_empty():
		result.error = "Le fichier est vide."
		return result
	var sep := ";" if lines[0].count(";") > 0 else ("\t" if lines[0].count("\t") > 0 else ",")
	var rows: Array[PackedStringArray] = []
	for line in lines:
		rows.append(_split(line, sep))

	# Ratio optionnel (cryptogramme)
	var ratio := -1.0
	for row in rows.duplicate():
		if row[0].strip_edges().to_lower() == "ratio":
			ratio = float(row[1]) if row.size() > 1 else 0.4
			rows.erase(row)

	# En-tête
	var kind := ""
	var first := rows[0][0].strip_edges().to_lower() if not rows.is_empty() else ""
	if first in ["mot", "mots", "word"]:
		kind = KIND_CROSSWORD
		rows.remove_at(0)
	elif first in ["question", "questions"]:
		kind = KIND_QUIZ
		rows.remove_at(0)
	elif first in ["phrase", "phrases", "sentence"]:
		kind = KIND_CRYPTO
		rows.remove_at(0)
	if kind == "":
		kind = _guess_kind(rows, ratio)
	result.kind = kind
	if rows.is_empty():
		result.error = "Aucune entrée trouvée."
		return result

	var title := path.get_file().get_basename().replace("_", " ").replace("-", " ").strip_edges()
	title = title.left(1).to_upper() + title.substr(1)
	var res: MiniGameData
	match kind:
		KIND_CROSSWORD:
			res = _build_crossword(rows, result)
		KIND_QUIZ:
			res = _build_quiz(rows, result)
		KIND_CRYPTO:
			res = _build_crypto(rows, ratio, result)
	res.theme_title = title
	(result.warnings as Array).append("Titre du thème déduit du nom du fichier : « %s » (modifiable dans l'Inspector)." % title)
	result.resource = res
	result.ok = true
	return result


static func _guess_kind(rows: Array[PackedStringArray], ratio: float) -> String:
	if ratio >= 0.0:
		return KIND_CRYPTO
	var max_cols := 0
	var with_spaces := 0
	for row in rows:
		max_cols = maxi(max_cols, row.size())
		if row[0].strip_edges().contains(" "):
			with_spaces += 1
	if max_cols >= 6:
		return KIND_QUIZ
	return KIND_CRYPTO if with_spaces * 2 > rows.size() else KIND_CROSSWORD


static func _build_crossword(rows: Array[PackedStringArray], result: Dictionary) -> CrosswordData:
	var data := CrosswordData.new()
	var warnings: Array = result.warnings
	var seen := {}
	for i in rows.size():
		var row := rows[i]
		var word := row[0].strip_edges()
		var clue := row[1].strip_edges() if row.size() > 1 else ""
		var answer := TextUtil.to_answer(word)
		if answer.length() < 2:
			warnings.append("Ligne %d : mot « %s » trop court, ignoré." % [i + 1, word])
			continue
		if seen.has(answer):
			warnings.append("Ligne %d : « %s » est en double, ignoré." % [i + 1, word])
			continue
		seen[answer] = true
		if clue == "":
			warnings.append("Ligne %d : indice manquant pour « %s »." % [i + 1, word])
		var e := CrosswordEntry.new()
		e.word = word
		e.clue = clue
		data.entries.append(e)
		(result.entries as Array).append("%s — %s" % [answer, clue if clue != "" else "(sans indice)"])
	CrosswordGenerator.generate(data)
	var analysis := CrosswordGenerator.analyze(data)
	for e: CrosswordEntry in analysis.isolated:
		warnings.append("Mot isolé (sans croisement) : %s." % e.answer)
	warnings.append("Grille générée : %d × %d." % [data.grid_width, data.grid_height])
	return data


static func _build_quiz(rows: Array[PackedStringArray], result: Dictionary) -> MemoData:
	var data := MemoData.new()
	var warnings: Array = result.warnings
	for i in rows.size():
		var row := rows[i]
		while row.size() < 7:
			row.append("")
		var q := MemoQuestion.new()
		q.question = row[0].strip_edges()
		q.answers = PackedStringArray([row[1].strip_edges(), row[2].strip_edges(), row[3].strip_edges(), row[4].strip_edges()])
		if q.question == "":
			warnings.append("Ligne %d : question vide, ignorée." % (i + 1))
			continue
		for k in 4:
			if q.answers[k] == "":
				warnings.append("Ligne %d : réponse %s vide." % [i + 1, "ABCD"[k]])
		var correct := _answer_index(row[5].strip_edges(), q.answers)
		if correct < 0:
			warnings.append("Ligne %d : réponse « %s » non reconnue (A, B, C, D ou le texte exact). A par défaut." % [i + 1, row[5]])
			correct = 0
		q.correct_index = correct
		var image_name := row[6].strip_edges()
		if image_name != "":
			q.image = find_image(image_name)
			if q.image == null:
				warnings.append("Ligne %d : image « %s » introuvable dans %s (image par défaut)." % [i + 1, image_name, IMAGE_DIR])
		data.questions.append(q)
		(result.entries as Array).append("%s → %s" % [q.question, q.answers[correct]])
	return data


static func _build_crypto(rows: Array[PackedStringArray], ratio: float, result: Dictionary) -> CryptoData:
	var data := CryptoData.new()
	var warnings: Array = result.warnings
	if ratio >= 0.0:
		data.hidden_ratio = clampf(ratio, 0.05, 1.0)
	for i in rows.size():
		var row := rows[i]
		var s := CryptoSentence.new()
		s.sentence = row[0].strip_edges()
		s.hint = row[1].strip_edges() if row.size() > 1 else ""
		if s.sentence == "":
			continue
		if s.hint == "":
			warnings.append("Ligne %d : indice manquant." % (i + 1))
		data.sentences.append(s)
		(result.entries as Array).append(s.sentence)
	warnings.append("Proportion de lettres cachées : %d %%." % roundi(data.hidden_ratio * 100))
	return data


static func _answer_index(value: String, answers: PackedStringArray) -> int:
	var v := value.to_upper()
	if v.length() == 1 and "ABCD".contains(v):
		return "ABCD".find(v)
	if v.is_valid_int() and int(v) >= 1 and int(v) <= 4:
		return int(v) - 1
	for k in answers.size():
		if answers[k].strip_edges().to_lower() == value.to_lower():
			return k
	return -1


## Cherche une image par nom (avec ou sans extension) dans IMAGE_DIR et ses sous-dossiers.
static func find_image(image_name: String) -> Texture2D:
	if image_name.begins_with("res://"):
		return load(image_name) as Texture2D if ResourceLoader.exists(image_name) else null
	var path := _search(IMAGE_DIR, image_name.to_lower())
	return load(path) as Texture2D if path != "" else null


static func _search(dir_path: String, wanted: String) -> String:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return ""
	for f in dir.get_files():
		var ext := f.get_extension().to_lower()
		if not ext in IMAGE_EXTENSIONS:
			continue
		if f.to_lower() == wanted or f.get_basename().to_lower() == wanted.get_basename():
			return dir_path.path_join(f)
	for sub in dir.get_directories():
		var found := _search(dir_path.path_join(sub), wanted)
		if found != "":
			return found
	return ""


## Découpe une ligne CSV en respectant les guillemets ("a;b" reste un seul champ).
static func _split(line: String, sep: String) -> PackedStringArray:
	var out := PackedStringArray()
	var field := ""
	var quoted := false
	var i := 0
	while i < line.length():
		var c := line[i]
		if quoted:
			if c == "\"":
				if i + 1 < line.length() and line[i + 1] == "\"":
					field += "\""
					i += 1
				else:
					quoted = false
			else:
				field += c
		elif c == "\"":
			quoted = true
		elif c == sep:
			out.append(field)
			field = ""
		else:
			field += c
		i += 1
	out.append(field)
	return out
