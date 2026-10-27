extends Resource
class_name GameData

@export_category("Level Primary")
@export var primary_1: SchoolYearData
@export var primary_2: SchoolYearData
@export var primary_3: SchoolYearData
@export var primary_4: SchoolYearData
@export var primary_5: SchoolYearData
@export var primary_6: SchoolYearData

@export_category("Level Secondary")
@export var secondary_1: SchoolYearData
@export var secondary_2: SchoolYearData
@export var secondary_3: SchoolYearData
@export var secondary_4: SchoolYearData
@export var secondary_5: SchoolYearData
@export var secondary_6: SchoolYearData

var _study_levels: Array[StudyLevelData] = []

var study_levels: Array[StudyLevelData]:
	get:
		if _study_levels.is_empty():
			_study_levels = [
				StudyLevelData.new("Primaire", [primary_1, primary_2, primary_3, primary_4, primary_5, primary_6]),
				StudyLevelData.new("Secondaire", [secondary_1, secondary_2, secondary_3, secondary_4, secondary_5, secondary_6]),
				StudyLevelData.new("Supérieur", []),
			]
		return _study_levels

func school_year_of(study_level_index: int, school_year_index: int) -> SchoolYearData:
	return study_levels[study_level_index].school_years[school_year_index]

func levels_of(study_level_index: int, school_year_index: int, subject_index: int) -> Array[LevelData]:
	return school_year_of(study_level_index, school_year_index).subjects[subject_index].levels
