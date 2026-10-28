extends Node
## Progression du joueur, en mémoire uniquement : elle repart de zéro à chaque lancement.
## Suivie séparément pour chaque combinaison niveau d'études / année / matière.

signal level_completed(key: String, index: int)

## Helper F1 : débloque tout sans compter les levels comme terminés.
var unlock_all := false
## Level fraîchement débloqué, que la grille anime à son prochain affichage.
var pending_unlock := {}

var _completed := {}  # clé -> { index: true }
var _selected := {}   # clé -> index


static func make_key(study: int, year: int, subject: int) -> String:
	return "%d/%d/%d" % [study, year, subject]


func reset() -> void:
	unlock_all = false
	pending_unlock = {}
	_completed.clear()
	_selected.clear()


func is_completed(key: String, index: int) -> bool:
	return _completed.get(key, {}).has(index)


func is_unlocked(key: String, index: int) -> bool:
	return index == 0 or unlock_all or is_completed(key, index) or is_completed(key, index - 1)


func completed_count(key: String) -> int:
	return _completed.get(key, {}).size()


func get_selected(key: String) -> int:
	return _selected.get(key, 0)


func select(key: String, index: int) -> void:
	_selected[key] = index


## Termine un level, débloque le suivant et le sélectionne.
func complete_level(key: String, index: int, level_count: int) -> void:
	if not _completed.has(key):
		_completed[key] = {}
	var first_time: bool = not _completed[key].has(index)
	_completed[key][index] = true
	if index + 1 < level_count:
		_selected[key] = index + 1
		if first_time:
			pending_unlock = {"key": key, "index": index + 1}
	level_completed.emit(key, index)
