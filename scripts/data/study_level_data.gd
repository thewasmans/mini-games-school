class_name StudyLevelData
extends RefCounted

var name: String
var school_years: Array[SchoolYearData]

func _init(study_level_name: String, study_level_school_years: Array[SchoolYearData]) -> void:
	name = study_level_name
	school_years = study_level_school_years
