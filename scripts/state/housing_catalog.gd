class_name HousingCatalog
extends RefCounted

const POINTS_PER_LEVEL := 10
const MAX_COUNTED_LEVELS := 3

var _rooms: Dictionary[Vector3i, HousingRoomData] = {}
var _item_levels: Dictionary[HousingItemData, Array] = {}


func _init(game_data: GameData) -> void:
	for study_index in GameData.STUDY_NAMES.size():
		for year_index in game_data.get_existing_years(study_index):
			var school_year := game_data.get_year(study_index, year_index)
			for subject_index in school_year.subjects.size():
				var subject := school_year.subjects[subject_index]
				if subject.housing_room != null:
					_add_room(Vector3i(study_index, year_index, subject_index), subject)


static func subject_id(subject_key: Vector3i) -> String:
	return "%d/%d/%d" % [subject_key.x, subject_key.y, subject_key.z]


static func item_id(subject_key: Vector3i, item: HousingItemData) -> String:
	return "%s/%s" % [subject_id(subject_key), TextUtil.to_answer(item.word)]


func subject_keys() -> Array[Vector3i]:
	var keys: Array[Vector3i] = []
	keys.assign(_rooms.keys())
	return keys


func room(subject_key: Vector3i) -> HousingRoomData:
	return _rooms.get(subject_key)


func items(subject_key: Vector3i) -> Array[HousingItemData]:
	var room_data := room(subject_key)
	return room_data.items if room_data != null else [] as Array[HousingItemData]


func levels_with(item: HousingItemData) -> Array[int]:
	var levels: Array[int] = []
	levels.assign(_item_levels.get(item, []))
	return levels


func gauge_size(item: HousingItemData) -> int:
	return POINTS_PER_LEVEL * mini(levels_with(item).size(), MAX_COUNTED_LEVELS)


func _add_room(subject_key: Vector3i, subject: SubjectData) -> void:
	_rooms[subject_key] = subject.housing_room
	var level_words: Array[PackedStringArray] = []
	for level in subject.levels:
		level_words.append(level.mini_game.answer_words() if level != null and level.mini_game != null else PackedStringArray())
	for item in subject.housing_room.items:
		var levels: Array[int] = []
		for level_index in level_words.size():
			if _contains_any(level_words[level_index], item.matching_words()):
				levels.append(level_index)
		_item_levels[item] = levels


func _contains_any(words: PackedStringArray, candidates: PackedStringArray) -> bool:
	for candidate in candidates:
		if words.has(candidate):
			return true
	return false
