class_name StoryCondition
extends Resource
## A gate on whether a DialogueDefinition, DialogueLine, or DialogueChoice is
## reachable right now. Attach one to require a story flag or an objective's
## status; leave the field null (the common case) for anything unconditional.
## See docs/design/dialogue-schema.md.

enum Type {
	FLAG_TRUE,
	FLAG_FALSE,
	OBJECTIVE_ACTIVE,
	OBJECTIVE_COMPLETE,
}

@export var type: Type = Type.FLAG_TRUE
## Flag name for FLAG_TRUE/FLAG_FALSE, objective id for
## OBJECTIVE_ACTIVE/OBJECTIVE_COMPLETE. Always a snake_case identifier.
@export var target_id: String = ""

## Shape-only validation (a valid identifier). ActOneController separately
## checks that an OBJECTIVE_* target_id names an objective that was actually
## registered - this Resource has no registry to check that against itself.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if not StoryIdentifiers.is_valid(target_id):
		errors.append("StoryCondition.target_id is not a valid identifier: '%s'" % target_id)
	return errors

func is_met(flags: Dictionary, objective_states: Dictionary) -> bool:
	match type:
		Type.FLAG_TRUE:
			return bool(flags.get(target_id, false))
		Type.FLAG_FALSE:
			return not bool(flags.get(target_id, false))
		Type.OBJECTIVE_ACTIVE:
			return objective_states.get(target_id, {}).get("status", "") == "active"
		Type.OBJECTIVE_COMPLETE:
			return objective_states.get(target_id, {}).get("status", "") == "completed"
		_:
			return false
