extends Node
## Owns Act I's story flags and objective progress, and steps through
## dialogue defined as data (DialogueDefinition/ObjectiveDefinition
## resources - see docs/design/dialogue-schema.md). Autoloaded as
## "ActOneController". This is chapter-level orchestration split out of
## GameState, which stays focused on resources/dam/Lodge/energy.
##
## Deliberately presentation-free: it tracks state and emits signals for a
## future dialogue/objective UI (issue #18) to render. It never touches a
## scene, node, or UI control directly.
##
## Content is not auto-loaded - call load_content() with the
## ObjectiveDefinitions and DialogueDefinitions to register (objectives
## first, since a dialogue's effects/conditions may reference an objective
## id). Malformed content - bad identifiers, an unknown speaker, a dialogue
## effect that targets an objective that was never registered - fails
## loudly via assert(), the same development-only safety net
## tests/smoke_test.gd relies on, rather than silently no-oping.

signal flag_changed(flag_name: String, value: bool)
signal objective_started(objective_id: String)
signal objective_progress_changed(objective_id: String, current: int, target: int)
signal objective_completed(objective_id: String)
signal dialogue_started(dialogue_id: String)
signal dialogue_line_shown(dialogue_id: String, line_index: int)
signal dialogue_choice_made(dialogue_id: String, choice_id: String, acknowledgement: String)
signal dialogue_ended(dialogue_id: String)

var _objectives: Dictionary = {}       # objective id -> ObjectiveDefinition
var _objective_state: Dictionary = {}  # objective id -> {"status": String, "current": int}
var _dialogues: Dictionary = {}        # dialogue id -> DialogueDefinition
var _flags: Dictionary = {}            # flag name -> bool

var _active_dialogue_id: String = ""
var _active_line_index: int = -1

## The most recently started objective - what a HUD's "current objective"
## display should call out. Set only by start_objective() (never cleared by
## completing it), so the display keeps showing the just-finished objective
## until a new one actually starts, rather than going blank the instant it
## completes. See get_current_objective_id().
var _current_objective_id: String = ""

func _ready() -> void:
	GameState.wood_changed.connect(_on_resource_changed.bind("wood"))
	GameState.stone_changed.connect(_on_resource_changed.bind("stone"))
	GameState.berries_changed.connect(_on_resource_changed.bind("berries"))

## --- Content loading ------------------------------------------------------

## Registers a batch of content in the right order (objectives before the
## dialogues that may reference them). See data/story/act1/ for the Act I
## fixture this is meant to load.
func load_content(objectives: Array[ObjectiveDefinition], dialogues: Array[DialogueDefinition]) -> void:
	for objective in objectives:
		register_objective(objective)
	for dialogue in dialogues:
		register_dialogue(dialogue)

func register_objective(objective: ObjectiveDefinition) -> void:
	assert(objective != null, "register_objective() called with a null ObjectiveDefinition")
	var errors := objective.validate()
	assert(errors.is_empty(), "Invalid ObjectiveDefinition '%s':\n%s" % [objective.id, "\n".join(errors)])
	assert(not _objectives.has(objective.id), "Duplicate objective id: '%s'" % objective.id)
	_objectives[objective.id] = objective
	_objective_state[objective.id] = {"status": "inactive", "current": 0}

func register_dialogue(dialogue: DialogueDefinition) -> void:
	assert(dialogue != null, "register_dialogue() called with a null DialogueDefinition")
	var errors := dialogue.validate()
	errors.append_array(_validate_cross_references(dialogue))
	assert(errors.is_empty(), "Invalid DialogueDefinition '%s':\n%s" % [dialogue.id, "\n".join(errors)])
	assert(not _dialogues.has(dialogue.id), "Duplicate dialogue id: '%s'" % dialogue.id)
	_dialogues[dialogue.id] = dialogue

## Checks identifiers that DialogueDefinition.validate() can't check on its
## own, since a bare Resource has no registry to confirm an objective id
## actually refers to something that was registered.
func _validate_cross_references(dialogue: DialogueDefinition) -> Array[String]:
	var errors: Array[String] = []
	if dialogue.condition != null:
		errors.append_array(_validate_condition_target(dialogue.condition, dialogue.id))
	for line in dialogue.lines:
		if line == null:
			continue
		if line.condition != null:
			errors.append_array(_validate_condition_target(line.condition, dialogue.id))
		for effect in line.effects:
			if effect != null:
				errors.append_array(_validate_effect_target(effect, dialogue.id))
		for choice in line.choices:
			if choice == null:
				continue
			for effect in choice.effects:
				if effect != null:
					errors.append_array(_validate_effect_target(effect, dialogue.id))
	return errors

func _validate_condition_target(condition: StoryCondition, dialogue_id: String) -> Array[String]:
	var targets_objective := condition.type == StoryCondition.Type.OBJECTIVE_ACTIVE \
		or condition.type == StoryCondition.Type.OBJECTIVE_COMPLETE
	if targets_objective and not _objectives.has(condition.target_id):
		return ["Dialogue '%s' has a condition referencing unknown objective '%s'" % [dialogue_id, condition.target_id]]
	return []

func _validate_effect_target(effect: StoryEffect, dialogue_id: String) -> Array[String]:
	var targets_objective := effect.type == StoryEffect.Type.START_OBJECTIVE \
		or effect.type == StoryEffect.Type.ADVANCE_OBJECTIVE \
		or effect.type == StoryEffect.Type.COMPLETE_OBJECTIVE
	if targets_objective and not _objectives.has(effect.target_id):
		return ["Dialogue '%s' has an effect referencing unknown objective '%s'" % [dialogue_id, effect.target_id]]
	return []

## Clears every registered flag/objective/dialogue and any in-progress
## dialogue. Tests use this to start each scenario from a clean slate.
func reset() -> void:
	_objectives.clear()
	_objective_state.clear()
	_dialogues.clear()
	_flags.clear()
	_active_dialogue_id = ""
	_active_line_index = -1
	_current_objective_id = ""

## --- Flags -----------------------------------------------------------------

func get_flag(flag_name: String) -> bool:
	return bool(_flags.get(flag_name, false))

## --- Objectives -------------------------------------------------------------

func has_objective(id: String) -> bool:
	return _objectives.has(id)

func has_dialogue(id: String) -> bool:
	return _dialogues.has(id)

func get_objective(id: String) -> ObjectiveDefinition:
	return _objectives.get(id)

func get_objective_status(id: String) -> String:
	return _objective_state.get(id, {}).get("status", "unknown")

func get_objective_progress(id: String) -> int:
	return _objective_state.get(id, {}).get("current", 0)

## The objective a "current objective" display (HUD, journal) should call
## out right now - the most recently started one, kept even after it
## completes until a new objective starts. Empty string if none has started
## yet.
func get_current_objective_id() -> String:
	return _current_objective_id

## Every registered objective's plain-language summary, in registration
## order, for a journal/history UI to render without reaching into private
## state. Includes objectives that haven't started yet (status "inactive") -
## callers that only want to list what the player has actually seen should
## filter those out themselves.
func get_objective_summaries() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for id in _objectives.keys():
		var objective: ObjectiveDefinition = _objectives[id]
		var state: Dictionary = _objective_state[id]
		summaries.append({
			"id": id,
			"title": objective.title,
			"description": objective.description,
			"status": state["status"],
			"current": state["current"],
			"target": objective.target_amount,
		})
	return summaries

func start_objective(id: String) -> void:
	assert(_objectives.has(id), "start_objective() on unknown objective '%s'" % id)
	var state: Dictionary = _objective_state[id]
	if state["status"] != "inactive":
		return
	state["status"] = "active"
	_current_objective_id = id
	objective_started.emit(id)
	# The tracked resource might already meet the target (e.g. the player
	# gathered wood before this objective existed) - check right away
	# instead of waiting for the next resource-changed signal.
	_sync_resource_objective(id)

func advance_objective(id: String, amount: int = 1) -> void:
	assert(_objectives.has(id), "advance_objective() on unknown objective '%s'" % id)
	var state: Dictionary = _objective_state[id]
	if state["status"] != "active":
		return
	state["current"] += amount
	objective_progress_changed.emit(id, state["current"], _objectives[id].target_amount)
	_check_objective_completion(id)

func complete_objective(id: String) -> void:
	assert(_objectives.has(id), "complete_objective() on unknown objective '%s'" % id)
	var state: Dictionary = _objective_state[id]
	if state["status"] == "completed":
		return
	state["status"] = "completed"
	objective_completed.emit(id)

func _check_objective_completion(id: String) -> void:
	var objective: ObjectiveDefinition = _objectives[id]
	var state: Dictionary = _objective_state[id]
	if state["status"] != "active":
		return
	if objective.completion_type != ObjectiveDefinition.CompletionType.RESOURCE_AT_LEAST:
		return
	if state["current"] >= objective.target_amount:
		complete_objective(id)

func _sync_resource_objective(id: String) -> void:
	var objective: ObjectiveDefinition = _objectives[id]
	if objective.completion_type != ObjectiveDefinition.CompletionType.RESOURCE_AT_LEAST:
		return
	var current_amount: int = 0
	match objective.resource:
		"wood":
			current_amount = GameState.wood
		"stone":
			current_amount = GameState.stone
		"berries":
			current_amount = GameState.berries
	var state: Dictionary = _objective_state[id]
	state["current"] = current_amount
	objective_progress_changed.emit(id, state["current"], objective.target_amount)
	_check_objective_completion(id)

func _on_resource_changed(new_amount: int, resource_name: String) -> void:
	for id in _objectives.keys():
		var objective: ObjectiveDefinition = _objectives[id]
		if objective.completion_type != ObjectiveDefinition.CompletionType.RESOURCE_AT_LEAST:
			continue
		if objective.resource != resource_name:
			continue
		var state: Dictionary = _objective_state[id]
		if state["status"] != "active":
			continue
		state["current"] = new_amount
		objective_progress_changed.emit(id, state["current"], objective.target_amount)
		_check_objective_completion(id)

## --- Dialogue ---------------------------------------------------------------

func get_active_dialogue_id() -> String:
	return _active_dialogue_id

## The DialogueLine currently on screen, or null if no dialogue is active.
func get_current_line() -> DialogueLine:
	if _active_dialogue_id.is_empty() or _active_line_index < 0:
		return null
	return _dialogues[_active_dialogue_id].lines[_active_line_index]

func get_current_speaker() -> String:
	var line := get_current_line()
	if line == null:
		return ""
	var dialogue: DialogueDefinition = _dialogues[_active_dialogue_id]
	return dialogue.speaker_for_line(line)

## Begins `id` if no dialogue is already active and its own condition (if
## any) is met. A no-op (not an error) if the condition blocks it - a
## caller like a resident's interact() is expected to check readiness itself
## before offering the dialogue at all.
func start_dialogue(id: String) -> void:
	assert(_dialogues.has(id), "start_dialogue() on unknown dialogue '%s'" % id)
	assert(_active_dialogue_id.is_empty(), "start_dialogue('%s') called while '%s' is still active" % [id, _active_dialogue_id])
	var dialogue: DialogueDefinition = _dialogues[id]
	if dialogue.condition != null and not dialogue.condition.is_met(_flags, _objective_state):
		return
	_active_dialogue_id = id
	_active_line_index = -1
	dialogue_started.emit(id)
	_advance_to_next_visible_line()

## Applies the chosen DialogueChoice's effects and reports its
## acknowledgement via dialogue_choice_made(); does not itself advance to the
## next line; dialogue-style.md's rule that "ordinary dialogue never
## auto-advances" applies here too, so callers advance explicitly.
func choose(choice_id: String) -> void:
	var line := get_current_line()
	assert(line != null, "choose() called with no active dialogue line")
	var chosen: DialogueChoice = null
	for choice in line.choices:
		if choice.id == choice_id:
			chosen = choice
			break
	assert(chosen != null, "choose('%s') does not match any choice on the current line" % choice_id)
	for effect in chosen.effects:
		_apply_effect(effect)
	dialogue_choice_made.emit(_active_dialogue_id, chosen.id, chosen.acknowledgement)

## Moves to the next reachable line, or ends the dialogue if none remain.
func advance_dialogue() -> void:
	assert(not _active_dialogue_id.is_empty(), "advance_dialogue() called with no active dialogue")
	_advance_to_next_visible_line()

func _advance_to_next_visible_line() -> void:
	var dialogue: DialogueDefinition = _dialogues[_active_dialogue_id]
	var next_index := _active_line_index + 1
	while next_index < dialogue.lines.size():
		var line: DialogueLine = dialogue.lines[next_index]
		if line.condition == null or line.condition.is_met(_flags, _objective_state):
			_active_line_index = next_index
			for effect in line.effects:
				_apply_effect(effect)
			dialogue_line_shown.emit(_active_dialogue_id, _active_line_index)
			return
		next_index += 1
	var finished_id := _active_dialogue_id
	_active_dialogue_id = ""
	_active_line_index = -1
	dialogue_ended.emit(finished_id)

## --- Save / load -------------------------------------------------------------
## Serializes the "story" section of the version 2 campaign save payload -
## see docs/design/dialogue-schema.md#save-load. Main.get_save_data()/
## apply_save_data() own assembling/dispatching the full payload; this is
## just ActOneController's own slice of it, the same split GameState uses
## for its own load_from_save().

## Flags/objective progress/the active dialogue+line, ready to drop under a
## "story" key in the save payload. The active dialogue's line index is the
## mid-dialogue boundary: a save always lands on a fully-applied line (never
## mid-effect, since choose()/_advance_to_next_visible_line() apply a line's
## effects synchronously before returning), so restoring it just needs to
## re-point at that same line - see load_from_save().
func get_save_data() -> Dictionary:
	var objectives_data: Dictionary = {}
	for id in _objective_state.keys():
		var state: Dictionary = _objective_state[id]
		objectives_data[id] = {"status": state["status"], "current": state["current"]}
	return {
		"flags": _flags.duplicate(),
		"objectives": objectives_data,
		"active_dialogue_id": _active_dialogue_id,
		"active_dialogue_line": _active_line_index,
	}

## Restores flags/objective progress/the active dialogue+line from a "story"
## save section. Must run after load_content() has registered this
## session's content, since objective/dialogue ids are only restored if
## they're still known - an id the save references that no longer exists
## (removed or renamed content, or a save from before any content is
## registered) is silently skipped rather than failing, the documented
## player-safe fallback: the player just sees that flag/objective/dialogue
## as never having happened, instead of a crash.
##
## Silent like GameState.load_from_save() - no signals fire here. There's no
## dialogue/objective UI yet to react to them (see dialogue-schema.md); when
## one exists (issue #18) it should read state via the getters below once,
## after loading, the same way HUD does via GameState.announce_loaded_state().
func load_from_save(data: Dictionary) -> void:
	_flags.clear()
	var saved_flags: Variant = data.get("flags", {})
	if saved_flags is Dictionary:
		for flag_name in saved_flags.keys():
			if flag_name is String and saved_flags[flag_name] is bool:
				_flags[flag_name] = saved_flags[flag_name]

	var saved_objectives: Variant = data.get("objectives", {})
	if saved_objectives is Dictionary:
		for id in saved_objectives.keys():
			if not (id is String) or not _objective_state.has(id):
				continue
			var entry: Variant = saved_objectives[id]
			if not entry is Dictionary:
				continue
			var status: Variant = entry.get("status", "inactive")
			if status is String and status in ["inactive", "active", "completed"]:
				_objective_state[id]["status"] = status
			var current: Variant = entry.get("current", 0)
			if current is int or current is float:
				_objective_state[id]["current"] = int(current)

	_active_dialogue_id = ""
	_active_line_index = -1
	var saved_dialogue_id: Variant = data.get("active_dialogue_id", "")
	if saved_dialogue_id is String and not saved_dialogue_id.is_empty() and _dialogues.has(saved_dialogue_id):
		var saved_line_index: Variant = data.get("active_dialogue_line", -1)
		var index: int = int(saved_line_index) if (saved_line_index is int or saved_line_index is float) else -1
		var dialogue: DialogueDefinition = _dialogues[saved_dialogue_id]
		if index >= 0 and index < dialogue.lines.size():
			_active_dialogue_id = saved_dialogue_id
			_active_line_index = index
		# else: out-of-range/malformed line index - same player-safe fallback
		# as an unknown id, drop back to no active dialogue rather than crash.

func _apply_effect(effect: StoryEffect) -> void:
	match effect.type:
		StoryEffect.Type.SET_FLAG:
			_flags[effect.target_id] = true
			flag_changed.emit(effect.target_id, true)
		StoryEffect.Type.CLEAR_FLAG:
			_flags[effect.target_id] = false
			flag_changed.emit(effect.target_id, false)
		StoryEffect.Type.START_OBJECTIVE:
			start_objective(effect.target_id)
		StoryEffect.Type.ADVANCE_OBJECTIVE:
			advance_objective(effect.target_id, effect.amount)
		StoryEffect.Type.COMPLETE_OBJECTIVE:
			complete_objective(effect.target_id)
