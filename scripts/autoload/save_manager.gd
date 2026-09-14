extends Node
## Persists progress to disk across SLOT_COUNT independent save slots, so
## the player can have a few different games going at once. Autoloaded as
## "SaveManager".
##
## The title screen picks a slot (an empty one starts fresh, an occupied
## one continues) and calls begin_session() before switching to Main -
## nothing auto-loads before that happens. From then on, current_slot says
## which file save_game()/load_into() read and write; Main itself doesn't
## need to know the slot number.
##
## Saves periodically, when the dam is completed, and when the window is
## closed gracefully - all three are no-ops while current_slot is unset
## (i.e. still on the title screen), so nothing gets written before a slot
## is chosen. The scene that owns the save data (Main) exposes
## get_save_data()/apply_save_data() - SaveManager itself only knows how to
## read/write files and find the current scene.
##
## dam_completed is the only GameState signal wired to an immediate save:
## it is only ever emitted from real gameplay progression
## (spend_resources_on_dam_piece()), never from reset() or a save-file load,
## so it can't accidentally save a half-restored or just-reset scene over
## good data the way lodge_stage_changed or the wood/stone signals could
## (those fire during both loading and reset()).

const SLOT_COUNT := 3
const AUTOSAVE_INTERVAL := 15.0

## Which slot the current play session reads/writes. -1 means no session
## is active yet (the title screen, before a slot is picked).
var current_slot: int = -1

func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = AUTOSAVE_INTERVAL
	timer.autostart = true
	timer.timeout.connect(save_game)
	add_child(timer)

	get_tree().root.close_requested.connect(save_game)
	GameState.dam_completed.connect(func(): save_game())

func _slot_path(slot: int) -> String:
	return "user://savegame_slot_%d.json" % slot

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))

func delete_save(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(_slot_path(slot))

## Called by the title screen once the player picks a slot, before
## switching to Main - load_into()/save_game() are no-ops until this runs.
func begin_session(slot: int) -> void:
	current_slot = slot

## Reads a slot's saved data without starting a session or touching a live
## scene - used by the title screen to show what's in each slot. Returns
## an empty Dictionary if the slot has no save.
func peek_slot(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var file := FileAccess.open(_slot_path(slot), FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}

func save_game() -> void:
	if current_slot < 0:
		return
	var main := get_tree().current_scene
	if main == null or not main.has_method("get_save_data"):
		return
	var data: Dictionary = main.get_save_data()
	var file := FileAccess.open(_slot_path(current_slot), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

## Applies the active session's slot to `main` if it has a save. No-op if
## the slot is empty (fresh game) or no session has begun yet.
func load_into(main: Node) -> void:
	if current_slot < 0 or not has_save(current_slot):
		return
	var file := FileAccess.open(_slot_path(current_slot), FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary and main.has_method("apply_save_data"):
		main.apply_save_data(parsed)
