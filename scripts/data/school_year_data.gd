class_name SchoolYearData
extends Resource

@export var name: String = ""
@export var subjects: Array[SubjectData] = []

func has_levels() -> bool:
	return subjects.any(func(subject: SubjectData) -> bool: return subject.has_levels())
