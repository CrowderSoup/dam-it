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
##
## Every read runs a saved file's "save_version" through _migrate() before
## handing it back (see peek_slot()), so a save written by an older build
## upgrades to the current payload shape before anything else looks at it.
## SaveManager only owns the version number and dispatching to the right
## migration function - what actually goes in the payload is still entirely
## up to Main/GameState/ActOneController (see docs/design/dialogue-schema.md
## #save-load for the version 2 shape).

const SLOT_COUNT := 3
const AUTOSAVE_INTERVAL := 15.0
## Version 2 adds the "story" section (flags/objective progress/the active
## dialogue+line - see ActOneController.get_save_data() and
## docs/design/dialogue-schema.md#save-load). Version 1 is every save from
## before that existed; _migrate_v1_to_v2() upgrades one to the other.
const SAVE_VERSION := 2

## One explicit, testable function per supported upgrade, keyed by the
## version it upgrades *from*. Applied in sequence by _migrate() until the
## data reaches SAVE_VERSION - see peek_slot(). A version with no entry here
## has no known upgrade path; _migrate() treats that slot as unreadable
## rather than guessing, the documented player-safe fallback for a save this
## build genuinely doesn't know how to read.
const _MIGRATIONS := {
	1: "_migrate_v1_to_v2",
}

## Tests override this so they can never touch a player's real slots.
var storage_root := "user://"

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
	return storage_root.path_join("savegame_slot_%d.json" % slot)

func _temporary_slot_path(slot: int) -> String:
	return _slot_path(slot) + ".tmp"

func set_storage_root_for_tests(path: String) -> void:
	storage_root = path
	var error := DirAccess.make_dir_recursive_absolute(storage_root)
	assert(error == OK or error == ERR_ALREADY_EXISTS, "Could not create test save directory: %s" % storage_root)

func _is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= SLOT_COUNT

func has_save(slot: int) -> bool:
	return _is_valid_slot(slot) and FileAccess.file_exists(_slot_path(slot))

func delete_save(slot: int) -> void:
	if not _is_valid_slot(slot):
		push_error("Invalid save slot: %d" % slot)
		return
	if has_save(slot):
		var error := DirAccess.remove_absolute(_slot_path(slot))
		if error != OK:
			push_error("Could not delete save slot %d: error %d" % [slot, error])

## Called by the title screen once the player picks a slot, before
## switching to Main - load_into()/save_game() are no-ops until this runs.
func begin_session(slot: int) -> void:
	if not _is_valid_slot(slot):
		push_error("Invalid save slot: %d" % slot)
		return
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
	if not parsed is Dictionary:
		push_error("Save slot %d contains invalid JSON" % slot)
		return {}
	var data: Dictionary = parsed
	var version: Variant = data.get("save_version", 0)
	if not version is float and not version is int:
		push_error("Save slot %d has an invalid format version" % slot)
		return {}
	if int(version) > SAVE_VERSION:
		push_error("Save slot %d was created by a newer game version" % slot)
		return {}
	if int(version) < SAVE_VERSION:
		data = _migrate(data, int(version))
		if data.is_empty():
			push_error("Save slot %d could not be migrated to the current save version" % slot)
			return {}
	return data

## Applies each registered migration in turn until `data` reaches
## SAVE_VERSION, or returns an empty Dictionary (the documented player-safe
## fallback for "this save can't be read") the moment a version has no
## migration registered in _MIGRATIONS.
func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	var migrated := data
	var version := from_version
	while version < SAVE_VERSION:
		if not _MIGRATIONS.has(version):
			return {}
		migrated = call(_MIGRATIONS[version], migrated)
		version += 1
	migrated["save_version"] = SAVE_VERSION
	return migrated

## Version 1 saves predate story flags/objective progress and the
## mid-dialogue boundary entirely - there was no Act I content for a v1 save
## to have made progress against, so upgrading it just introduces the
## "story" section at its empty default (see ActOneController.load_from_save(),
## which already treats a missing/empty "story" section this way too - this
## migration exists so the stored payload's shape and its "save_version" tag
## are explicit and correct, rather than relying on that leniency forever).
func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	if not migrated.has("story"):
		migrated["story"] = {
			"flags": {},
			"objectives": {},
			"current_objective_id": "",
			"active_dialogue_id": "",
			"active_dialogue_line": -1,
			"active_dialogue_choice": "",
		}
	return migrated

func save_game() -> bool:
	if current_slot < 0:
		return false
	var main := get_tree().current_scene
	if main == null or not main.has_method("get_save_data"):
		return false
	var data: Dictionary = main.get_save_data()
	data["save_version"] = SAVE_VERSION
	var temporary_path := _temporary_slot_path(current_slot)
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open temporary save file: error %d" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	var error := DirAccess.rename_absolute(temporary_path, _slot_path(current_slot))
	if error != OK:
		push_error("Could not commit save slot %d: error %d" % [current_slot, error])
		return false
	return true

## Applies the active session's slot to `main` if it has a save. No-op if
## the slot is empty (fresh game) or no session has begun yet.
func load_into(main: Node) -> void:
	if current_slot < 0 or not has_save(current_slot):
		return
	var data := peek_slot(current_slot)
	if not data.is_empty() and main.has_method("apply_save_data"):
		main.apply_save_data(data)
