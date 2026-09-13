extends Node
## Persists progress to disk (user://savegame.json) so "Grow Your Pond" is
## actually persistent across sessions, not just within one running game.
## Autoloaded as "SaveManager".
##
## Saves periodically, when the dam is completed, and when the window is
## closed gracefully. The scene that owns the save data (Main) exposes
## get_save_data()/apply_save_data() - SaveManager itself only knows how to
## read/write the file and find the current scene.
##
## dam_completed is the only GameState signal wired to an immediate save:
## it is only ever emitted from real gameplay progression
## (spend_resources_on_dam_piece()), never from reset() or a save-file load,
## so it can't accidentally save a half-restored or just-reset scene over
## good data the way lodge_stage_changed or the wood/stone signals could
## (those fire during both loading and reset()).

const SAVE_PATH := "user://savegame.json"
const AUTOSAVE_INTERVAL := 15.0

func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = AUTOSAVE_INTERVAL
	timer.autostart = true
	timer.timeout.connect(save_game)
	add_child(timer)

	get_tree().root.close_requested.connect(save_game)
	GameState.dam_completed.connect(func(): save_game())

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)

func save_game() -> void:
	var main := get_tree().current_scene
	if main == null or not main.has_method("get_save_data"):
		return
	var data: Dictionary = main.get_save_data()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

## Applies a save file to `main` if one exists. No-op otherwise (fresh game).
func load_into(main: Node) -> void:
	if not has_save():
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary and main.has_method("apply_save_data"):
		main.apply_save_data(parsed)
