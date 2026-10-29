@tool
class_name MemoQuestion
extends Resource
## Une question du quiz : 4 réponses, dont une juste.

@export_multiline var question: String = ""
@export var answers: PackedStringArray = PackedStringArray(["", "", "", ""])
## Index de la bonne réponse (0 = A, 3 = D).
@export_range(0, 3) var correct_index: int = 0
## Image optionnelle. Sans image, l'image par défaut s'affiche.
@export var image: Texture2D
