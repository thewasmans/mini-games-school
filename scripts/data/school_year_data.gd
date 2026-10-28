@tool
class_name SchoolYearData
extends Resource
## Une année (P1…P6, S1…S6, Q1…Q6) et ses matières.

## Nom affiché dans les menus et le titre des levels, par exemple « S5 ».
@export var name: String = ""
@export var subjects: Array[SubjectData] = []


func count_levels() -> int:
	var n := 0
	for subject in subjects:
		if subject != null:
			n += subject.count_levels()
	return n
