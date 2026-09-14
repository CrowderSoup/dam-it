class_name StoryEffect
extends Resource
## A state change applied when a DialogueLine is shown or a DialogueChoice is
## picked: set a story flag, or start/advance/complete an objective. See
## docs/design/dialogue-schema.md.

enum Type {
	SET_FLAG,
	CLEAR_FLAG,
	START_OBJECTIVE,
	ADVANCE_OBJECTIVE,
	COMPLETE_OBJECTIVE,
}

@export var type: Type = Type.SET_FLAG
## Flag name for SET_FLAG/CLEAR_FLAG, objective id for the OBJECTIVE_*
## effects. Always a snake_case identifier.
@export var target_id: String = ""
## Only read by ADVANCE_OBJECTIVE - how much progress to add.
@export var amount: int = 1

## Shape-only validation. ActOneController separately checks that an
## OBJECTIVE_* target_id names a registered objective.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if not StoryIdentifiers.is_valid(target_id):
		errors.append("StoryEffect.target_id is not a valid identifier: '%s'" % target_id)
	if type == Type.ADVANCE_OBJECTIVE and amount <= 0:
		errors.append("StoryEffect(ADVANCE_OBJECTIVE) amount must be positive, got %d" % amount)
	return errors
