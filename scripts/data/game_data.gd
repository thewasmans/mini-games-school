extends Resource
class_name GameData

@export var study_levels: Array[StudyLevelData]

func school_year_of(study_level_index: int, school_year_index: int) -> SchoolYearData:
	return study_levels[study_level_index].school_years[school_year_index]

func levels_of(study_level_index: int, school_year_index: int, subject_index: int) -> Array[LevelData]:
	return school_year_of(study_level_index, school_year_index).subjects[subject_index].levels
