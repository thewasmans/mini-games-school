@tool
class_name FakeDataBuilder
extends RefCounted

const DATA_DIR := "res://data/"
const STUDY_FOLDERS: Array[String] = ["primaire", "secondaire", "superieur"]
const DATA_PATH := "res://data/game_data.tres"


static func run() -> Error:
	return FakeDataBuilder.new()._build()


func _build() -> Error:
	var data := GameData.new()

	data.primary_3 = _year("P3", [
		_subject("Mathématiques", [
			_quiz("Les tables de multiplication", [
				["Combien font 3 × 4 ?", ["7", "12", "34", "9"], 1, ""],
				["Combien font 5 × 5 ?", ["10", "55", "25", "20"], 2, ""],
				["Combien font 2 × 9 ?", ["18", "11", "29", "16"], 0, ""],
			]),
			_crypto("Les formes géométriques", [
				["Un carré a quatre côtés égaux.", "Une forme à 4 côtés identiques"],
				["Un triangle a trois angles.", "Tri veut dire trois"],
			], 0.35),
		]),
		_subject("Français", [
			_crossword("Les animaux de la ferme", [
				["Vache", "Elle donne du lait"],
				["Cheval", "On peut le monter et il hennit"],
				["Mouton", "Sa laine tient chaud"],
				["Poule", "Elle pond des œufs"],
				["Cochon", "Il adore se rouler dans la boue"],
				["Canard", "Il fait coin-coin"],
			]),
		]),
		_subject("Éveil", []),
	])

	data.secondary_1 = _year("S1", [
		_subject("Histoire", [
			_quiz("La Révolution française", [
				["Quel grand événement a marqué l'année 1789 en France ?", ["La prise de la Bastille", "L'invention du vaccin", "La découverte de l'Amérique", "Le couronnement de Charlemagne"], 0, ""],
				["Quel roi régnait en France en 1789 ?", ["Louis XIV", "Napoléon", "Louis XVI", "Henri IV"], 2, ""],
			]),
			_crossword("Le Moyen Âge", [
				["Château", "Demeure fortifiée du seigneur"],
				["Chevalier", "Guerrier à cheval au service d'un seigneur"],
				["Donjon", "La plus haute tour du château"],
				["Seigneur", "Il possède un fief"],
				["Moine", "Il vit dans un monastère"],
			]),
			_crypto("Napoléon", [
				["Napoléon devient empereur en 1804.", "Sacre à Notre-Dame de Paris"],
			], 0.4),
		]),
	])
	data.secondary_2 = _year("S2", [])
	data.secondary_4 = _year("S4", [
		_subject("Biologie", [
			_crossword("La cellule", [
				["Noyau", "Il contient l'ADN de la cellule"],
				["Membrane", "Elle entoure la cellule et la protège"],
				["Cytoplasme", "Substance gélatineuse qui remplit la cellule"],
				["Mitochondrie", "La centrale énergétique de la cellule"],
				["Ribosome", "Il fabrique les protéines"],
				["Vacuole", "Réserve d'eau, très grande chez les végétaux"],
				["Chloroplaste", "Siège de la photosynthèse"],
			]),
			_quiz("La cellule", [
				["Quelle est l'unité de base du vivant ?", ["L'atome", "La cellule", "L'organe", "Le tissu"], 1, "res://content/images/cellule.svg"],
				["Où se trouve l'ADN chez les eucaryotes ?", ["Dans le noyau", "Dans la membrane", "Dans la vacuole", "Dans la paroi"], 0, "res://content/images/cellule.svg"],
				["Quel organite produit l'énergie de la cellule ?", ["Le ribosome", "Le noyau", "La mitochondrie", "La vacuole"], 2, ""],
			]),
			_crypto("La photosynthèse", [
				["Les plantes fabriquent leur matière grâce à la lumière du Soleil.", "Le principe de la photosynthèse"],
				["La chlorophylle donne aux feuilles leur couleur verte.", "Un pigment vert"],
			], 0.4),
			_crossword("Le corps humain", [
				["Cœur", "Il pompe le sang"],
				["Poumon", "Organe de la respiration"],
				["Estomac", "Il digère les aliments"],
				["Cerveau", "Il commande tout le corps"],
				["Foie", "Le plus gros organe interne"],
				["Rein", "Il filtre le sang et produit l'urine"],
				["Squelette", "L'ensemble des os"],
			]),
			_quiz("La digestion", [
				["Où commence la digestion ?", ["Dans l'estomac", "Dans la bouche", "Dans l'intestin", "Dans le foie"], 1, ""],
			]),
		]),
		_subject("Chimie", [
			_quiz("L'atome", [
				["Qu'y a-t-il au centre d'un atome ?", ["Un électron", "Le noyau", "Un photon", "Rien"], 1, "res://content/images/atome.svg"],
				["Quelle particule a une charge négative ?", ["Le proton", "Le neutron", "L'électron", "Le noyau"], 2, "res://content/images/atome.svg"],
			]),
			_crypto("Les états de la matière", [
				["L'eau peut être solide, liquide ou gazeuse.", "Glace, eau, vapeur"],
			], 0.5),
		]),
		_subject("Physique", []),
	])

	var credits := CreditsData.new()
	credits.contributors = PackedStringArray([
		"Conception pédagogique — Équipe enseignante",
		"Développement — Studio Exemple",
		"Illustrations — Collectif Graphique",
		"Tests — Les élèves de 4e B",
	])
	credits.partner_names = PackedStringArray(["École Exemple", "Partenaire B", "Partenaire C"])
	credits.partner_logos.assign([load("res://content/images/logo_partenaire.svg")])
	data.credits = credits

	for study in STUDY_FOLDERS.size():
		for year_index in GameData.YEARS_PER_STUDY:
			var year := data.get_year(study, year_index)
			if year != null:
				_save_year(year, DATA_DIR.path_join(STUDY_FOLDERS[study]).path_join(_slug(year.name)))
	return _save(data, DATA_PATH)


func _save_year(year: SchoolYearData, year_dir: String) -> void:
	for subject in year.subjects:
		var subject_dir := year_dir.path_join(_slug(subject.name))
		DirAccess.make_dir_recursive_absolute(subject_dir)
		for level_index in subject.levels.size():
			var level := subject.levels[level_index]
			var prefix := "%02d_" % (level_index + 1)
			_save(level.mini_game, subject_dir.path_join(prefix + _slug(level.mini_game.theme_title) + ".tres"))
			_save(level, subject_dir.path_join("level_%02d.tres" % (level_index + 1)))
		_save(subject, subject_dir.path_join(_slug(subject.name) + ".tres"))
	_save(year, year_dir.path_join(_slug(year.name) + ".tres"))


func _save(resource: Resource, path: String) -> Error:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	resource.take_over_path(path)
	var err := ResourceSaver.save(resource, path)
	print(path, " : ", error_string(err))
	return err


func _slug(text: String) -> String:
	var slug := ""
	for c in text:
		slug += TextUtil.normalize_char(c).to_lower() if TextUtil.is_letter(c) or c.is_valid_int() else "_"
	while slug.contains("__"):
		slug = slug.replace("__", "_")
	return slug.trim_prefix("_").trim_suffix("_")


func _crossword(theme: String, pairs: Array) -> LevelData:
	var mg := CrosswordData.new()
	mg.theme_title = theme
	for p in pairs:
		var e := CrosswordEntry.new()
		e.word = p[0]
		e.clue = p[1]
		mg.entries.append(e)
	CrosswordGenerator.generate(mg)
	return _level(mg)


func _quiz(theme: String, rows: Array) -> LevelData:
	var mg := MemoData.new()
	mg.theme_title = theme
	for r in rows:
		var q := MemoQuestion.new()
		q.question = r[0]
		q.answers = PackedStringArray(r[1])
		q.correct_index = r[2]
		if r[3] != "":
			q.image = load(r[3]) as Texture2D
		mg.questions.append(q)
	return _level(mg)


func _crypto(theme: String, rows: Array, ratio: float) -> LevelData:
	var mg := CryptoData.new()
	mg.theme_title = theme
	mg.hidden_ratio = ratio
	for r in rows:
		var s := CryptoSentence.new()
		s.sentence = r[0]
		s.hint = r[1]
		mg.sentences.append(s)
	return _level(mg)


func _level(mg: MiniGameData) -> LevelData:
	var level := LevelData.new()
	level.mini_game = mg
	return level


func _subject(name: String, levels: Array) -> SubjectData:
	var s := SubjectData.new()
	s.name = name
	s.levels.assign(levels)
	return s


func _year(name: String, subjects: Array) -> SchoolYearData:
	var y := SchoolYearData.new()
	y.name = name
	y.subjects.assign(subjects)
	return y
