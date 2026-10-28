extends Control
## Point d'entrée : charge les données puis affiche l'interface.


func _ready() -> void:
	GameManager.initialize()
	add_child(GameUI.new())
