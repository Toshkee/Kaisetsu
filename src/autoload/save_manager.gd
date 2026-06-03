extends Node
## Autoload: SaveManager
## JSON save/load of GameState to user://save.json. Saving happens diegetically — when Sōji
## rests at / re-lights a Sealing Shrine (KAISETSU_PLAN A2 save anchors).

const SAVE_PATH := "user://save.json"

func save_game() -> bool:
	var data := GameState.to_dict()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: could not open save file for writing.")
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true

func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: save file was malformed.")
		return false
	GameState.from_dict(parsed)
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
