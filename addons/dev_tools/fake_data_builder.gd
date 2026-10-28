@tool
class_name FakeDataBuilder
extends RefCounted
## Génère les données de test (data/game_data.tres + data/minigames/*.tres).
## ATTENTION : écrase data/game_data.tres. À lancer une fois, puis édite les données dans l'Inspector.
##
## Projet > Outils > Outils du jeu > Régénérer les données de test, ou :
##   godot --headless --path . --script res://addons/dev_tools/cli.gd -- fake_data
##
## Couverture des features :
## - Primaire : une seule année (P3) -> le menu des années est sauté ; une matière sans level.
## - Secondaire : S1 et S4 jouables, S2 renseignée mais vide, S3/S5/S6 vides -> « Bientôt disponible ».
## - Supérieur : aucun contenu -> bouton désactivé.
## - Les 3 mini-jeux, avec et sans image de quiz, et un chemin de 5 levels (serpent sur 2 rangées).

const OUT := "res://data/minigames/"
const DATA_PATH := "res://data/game_data.tres"


static func run() -> Error:
	return FakeDataBuilder.new()._build()


func _build() -> Error:
	var data := GameData.new()

	data.primary_3 = _year("P3", [
		_subject("Mathématiques", [
			_quiz("P3", "Les tables de multiplication", [
				["Combien font 3 × 4 ?", ["7", "12", "34", "9"], 1, ""],
				["Combien font 5 × 5 ?", ["10", "55", "25", "20"], 2, ""],
				["Combien font 2 × 9 ?", ["18", "11", "29", "16"], 0, ""],
			]),
			_crypto("P3", "Les formes géométriques", [
				["Un carré a quatre côtés égaux.", "Une forme à 4 côtés identiques"],
				["Un triangle a trois angles.", "Tri veut dire trois"],
			], 0.35),
		]),
		_subject("Français", [
			_crossword("P3", "Les animaux de la ferme", [
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
			_quiz("S1", "La Révolution française", [
				["Quel grand événement a marqué l'année 1789 en France ?", ["La prise de la Bastille", "L'invention du vaccin", "La découverte de l'Amérique", "Le couronnement de Charlemagne"], 0, ""],
				["Quel roi régnait en France en 1789 ?", ["Louis XIV", "Napoléon", "Louis XVI", "Henri IV"], 2, ""],
			]),
			_crossword("S1", "Le Moyen Âge", [
				["Château", "Demeure fortifiée du seigneur"],
				["Chevalier", "Guerrier à cheval au service d'un seigneur"],
				["Donjon", "La plus haute tour du château"],
				["Seigneur", "Il possède un fief"],
				["Moine", "Il vit dans un monastère"],
			]),
			_crypto("S1", "Napoléon", [
				["Napoléon devient empereur en 1804.", "Sacre à Notre-Dame de Paris"],
			], 0.4),
		]),
	])
	data.secondary_2 = _year("S2", [])
	data.secondary_4 = _year("S4", [
		_subject("Biologie", [
			_crossword("S4", "La cellule", [
				["Noyau", "Il contient l'ADN de la cellule"],
				["Membrane", "Elle entoure la cellule et la protège"],
				["Cytoplasme", "Substance gélatineuse qui remplit la cellule"],
				["Mitochondrie", "La centrale énergétique de la cellule"],
				["Ribosome", "Il fabrique les protéines"],
				["Vacuole", "Réserve d'eau, très grande chez les végétaux"],
				["Chloroplaste", "Siège de la photosynthèse"],
			]),
			_quiz("S4", "La cellule", [
				["Quelle est l'unité de base du vivant ?", ["L'atome", "La cellule", "L'organe", "Le tissu"], 1, "res://content/images/cellule.svg"],
				["Où se trouve l'ADN chez les eucaryotes ?", ["Dans le noyau", "Dans la membrane", "Dans la vacuole", "Dans la paroi"], 0, "res://content/images/cellule.svg"],
				["Quel organite produit l'énergie de la cellule ?", ["Le ribosome", "Le noyau", "La mitochondrie", "La vacuole"], 2, ""],
			]),
			_crypto("S4", "La photosynthèse", [
				["Les plantes fabriquent leur matière grâce à la lumière du Soleil.", "Le principe de la photosynthèse"],
				["La chlorophylle donne aux feuilles leur couleur verte.", "Un pigment vert"],
			], 0.4),
			_crossword("S4", "Le corps humain", [
				["Cœur", "Il pompe le sang"],
				["Poumon", "Organe de la respiration"],
				["Estomac", "Il digère les aliments"],
				["Cerveau", "Il commande tout le corps"],
				["Foie", "Le plus gros organe interne"],
				["Rein", "Il filtre le sang et produit l'urine"],
				["Squelette", "L'ensemble des os"],
			]),
			_quiz("S4", "La digestion", [
				["Où commence la digestion ?", ["Dans l'estomac", "Dans la bouche", "Dans l'intestin", "Dans le foie"], 1, ""],
			]),
		]),
		_subject("Chimie", [
			_quiz("S4", "L'atome", [
				["Qu'y a-t-il au centre d'un atome ?", ["Un électron", "Le noyau", "Un photon", "Rien"], 1, "res://content/images/atome.svg"],
				["Quelle particule a une charge négative ?", ["Le proton", "Le neutron", "L'électron", "Le noyau"], 2, "res://content/images/atome.svg"],
			]),
			_crypto("S4", "Les états de la matière", [
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

	data.take_over_path(DATA_PATH)
	var err := ResourceSaver.save(data, DATA_PATH)
	print("game_data.tres : ", error_string(err))
	return err


var _count := 0


func _save(mg: MiniGameData) -> MiniGameData:
	_count += 1
	var slug := ""
	for c in mg.theme_title:
		slug += TextUtil.normalize_char(c).to_lower() if TextUtil.is_letter(c) else "_"
	while slug.contains("__"):
		slug = slug.replace("__", "_")
	var path := OUT + "%02d_%s.tres" % [_count, slug.strip_edges().trim_suffix("_")]
	mg.take_over_path(path)
	var err := ResourceSaver.save(mg, path)
	print(path, " : ", error_string(err))
	return load(path) as MiniGameData


func _crossword(year: String, theme: String, pairs: Array) -> LevelData:
	var mg := CrosswordData.new()
	mg.school_year = year
	mg.theme_title = theme
	for p in pairs:
		var e := CrosswordEntry.new()
		e.word = p[0]
		e.clue = p[1]
		mg.entries.append(e)
	CrosswordGenerator.generate(mg)
	return _level(_save(mg))


func _quiz(year: String, theme: String, rows: Array) -> LevelData:
	var mg := MemoData.new()
	mg.school_year = year
	mg.theme_title = theme
	for r in rows:
		var q := MemoQuestion.new()
		q.question = r[0]
		q.answers = PackedStringArray(r[1])
		q.correct_index = r[2]
		if r[3] != "":
			q.image = load(r[3]) as Texture2D
		mg.questions.append(q)
	return _level(_save(mg))


func _crypto(year: String, theme: String, rows: Array, ratio: float) -> LevelData:
	var mg := CryptoData.new()
	mg.school_year = year
	mg.theme_title = theme
	mg.hidden_ratio = ratio
	for r in rows:
		var s := CryptoSentence.new()
		s.sentence = r[0]
		s.hint = r[1]
		mg.sentences.append(s)
	return _level(_save(mg))


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
