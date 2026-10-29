@tool
class_name MiniGameData
extends Resource
## Base commune des mini-jeux (mots croisés, quiz, cryptogramme).

## Année scolaire, par exemple « S4 ».
@export var school_year: String = ""
## Titre du thème, affiché dans la grille des levels et le titre du level.
@export var theme_title: String = ""


func get_kind_name() -> String:
	return "Mini-jeu"
