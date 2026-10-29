@tool
class_name GameData
extends Resource

const STUDY_NAMES: Array[String] = ["Primaire", "Secondaire", "Supérieur"]
const YEAR_PREFIXES: Array[String] = ["P", "S", "Q"]
const YEAR_FIELDS: Array[String] = ["primary_", "secondary_", "quadrimester_"]
const YEARS_PER_STUDY := 6

@export_group("Level Primary")
@export var primary_1: SchoolYearData
@export var primary_2: SchoolYearData
@export var primary_3: SchoolYearData
@export var primary_4: SchoolYearData
@export var primary_5: SchoolYearData
@export var primary_6: SchoolYearData

@export_group("Level Secondary")
@export var secondary_1: SchoolYearData
@export var secondary_2: SchoolYearData
@export var secondary_3: SchoolYearData
@export var secondary_4: SchoolYearData
@export var secondary_5: SchoolYearData
@export var secondary_6: SchoolYearData

@export_group("Level Higher")
@export var quadrimester_1: SchoolYearData
@export var quadrimester_2: SchoolYearData
@export var quadrimester_3: SchoolYearData
@export var quadrimester_4: SchoolYearData
@export var quadrimester_5: SchoolYearData
@export var quadrimester_6: SchoolYearData

@export_group("Crédits")
@export var credits: CreditsData


func get_year(study: int, index: int) -> SchoolYearData:
	return get(YEAR_FIELDS[study] + str(index + 1)) as SchoolYearData


func get_year_name(study: int, index: int) -> String:
	var year := get_year(study, index)
	if year != null and not year.name.strip_edges().is_empty():
		return year.name
	return YEAR_PREFIXES[study] + str(index + 1)


func get_existing_years(study: int) -> Array[int]:
	var out: Array[int] = []
	for i in YEARS_PER_STUDY:
		if get_year(study, i) != null:
			out.append(i)
	return out


func get_subject(study: int, year: int, subject: int) -> SubjectData:
	var y := get_year(study, year)
	if y == null or subject < 0 or subject >= y.subjects.size():
		return null
	return y.subjects[subject]
