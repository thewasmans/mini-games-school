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

@export_category("Level Higher")
@export var quadrimester_1: SchoolYearData
@export var quadrimester_2: SchoolYearData
@export var quadrimester_3: SchoolYearData
@export var quadrimester_4: SchoolYearData
@export var quadrimester_5: SchoolYearData
@export var quadrimester_6: SchoolYearData

var _study_levels: Array[StudyLevelData] = []

var study_levels: Array[StudyLevelData]:
	get:
		if _study_levels.is_empty():
			_study_levels = [
				StudyLevelData.new("Primaire", _school_years_or_empty("P", [primary_1, primary_2, primary_3, primary_4, primary_5, primary_6])),
				StudyLevelData.new("Secondaire", _school_years_or_empty("S", [secondary_1, secondary_2, secondary_3, secondary_4, secondary_5, secondary_6])),
				StudyLevelData.new("Supérieur", _school_years_or_empty("Q", [quadrimester_1, quadrimester_2, quadrimester_3, quadrimester_4, quadrimester_5, quadrimester_6])),
			]
		return _study_levels

func _school_years_or_empty(name_prefix: String, school_years: Array[SchoolYearData]) -> Array[SchoolYearData]:
	var filled_school_years: Array[SchoolYearData] = []
	for school_year_index in school_years.size():
		var school_year := school_years[school_year_index]
		if school_year == null:
			school_year = SchoolYearData.new()
			school_year.name = "%s%d" % [name_prefix, school_year_index + 1]
		filled_school_years.append(school_year)
	return filled_school_years

func school_year_of(study_level_index: int, school_year_index: int) -> SchoolYearData:
	return study_levels[study_level_index].school_years[school_year_index]

func levels_of(study_level_index: int, school_year_index: int, subject_index: int) -> Array[LevelData]:
	return school_year_of(study_level_index, school_year_index).subjects[subject_index].levels
