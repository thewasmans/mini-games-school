extends GdUnitTestSuite

const SCANNED_FOLDERS: Array[String] = ["res://content", "res://data", "res://scenes"]
const RESOURCE_EXTENSIONS: Array[String] = ["tscn", "tres"]


func _resource_files(folder: String) -> Array[String]:
	var files: Array[String] = []
	for sub_folder in DirAccess.get_directories_at(folder):
		files.append_array(_resource_files(folder.path_join(sub_folder)))
	for file in DirAccess.get_files_at(folder):
		if file.get_extension() in RESOURCE_EXTENSIONS:
			files.append(folder.path_join(file))
	return files


func _all_resource_files() -> Array[String]:
	var files: Array[String] = []
	for folder in SCANNED_FOLDERS:
		files.append_array(_resource_files(folder))
	return files


func test_every_scene_and_resource_has_a_uid() -> void:
	var missing: Array[String] = []
	for path in _all_resource_files():
		if not FileAccess.get_file_as_string(path).get_slice("\n", 0).contains(" uid=\"uid://"):
			missing.append(path)
	assert_array(missing).is_empty()


func test_every_reference_uses_a_uid() -> void:
	var missing: Array[String] = []
	for path in _all_resource_files():
		for line in FileAccess.get_file_as_string(path).split("\n"):
			if line.begins_with("[ext_resource") and not line.contains(" uid=\"uid://"):
				missing.append("%s : %s" % [path, line])
	assert_array(missing).is_empty()


func test_every_reference_points_to_the_right_file() -> void:
	var stale: Array[String] = []
	for path in _all_resource_files():
		for line in FileAccess.get_file_as_string(path).split("\n"):
			if not line.begins_with("[ext_resource") or not line.contains(" uid=\"uid://"):
				continue
			var uid := line.get_slice(" uid=\"", 1).get_slice("\"", 0)
			var target := line.get_slice(" path=\"", 1).get_slice("\"", 0)
			var id := ResourceUID.text_to_id(uid)
			if not ResourceUID.has_id(id) or ResourceUID.get_id_path(id) != target:
				stale.append("%s : %s" % [path, target])
	assert_array(stale).is_empty()
