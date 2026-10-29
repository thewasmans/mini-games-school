@tool
class_name CrosswordEntry
extends Resource

@export var word: String = ""
@export_multiline var clue: String = ""

@export_group("Grille (générée)")
@export var answer: String = ""
@export var x: int = 0
@export var y: int = 0
@export var horizontal: bool = true
@export var placed: bool = false
@export var number: int = 0
