extends Resource
class_name GameData

@export var study_levels: Array[StudyLevelData]

func levels_of(study_level_index: int, subject_index: int) -> Array[LevelData]:
	return study_levels[study_level_index].subjects[subject_index].levels
