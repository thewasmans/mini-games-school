@tool
class_name CrosswordEntry
extends Resource
## Un mot du mot croisé. La position est calculée par CrosswordGenerator.

@export var word: String = ""
@export_multiline var clue: String = ""

@export_group("Grille (générée)")
## Le mot en majuscules, sans accents ni espaces.
@export var answer: String = ""
@export var x: int = 0
@export var y: int = 0
@export var horizontal: bool = true
@export var placed: bool = false
@export var number: int = 0
