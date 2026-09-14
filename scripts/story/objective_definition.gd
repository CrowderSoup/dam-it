class_name ObjectiveDefinition
extends Resource
## A trackable Act I goal that ActOneController advances toward completion.
## A dialogue effect (see StoryEffect) starts one, and it either completes
## itself once a tracked GameState resource reaches a target amount, or
## waits for a dialogue/gameplay beat to complete it manually. See
## docs/design/dialogue-schema.md.

enum CompletionType {
	## Completed only via a StoryEffect(COMPLETE_OBJECTIVE) - use for
	## objectives resolved by a dialogue or scripted beat rather than a
	## counted resource.
	MANUAL,
	## Completed automatically once GameState's `resource` field reaches
	## `target_amount`. ActOneController watches GameState's changed signals
	## for this, so nothing else has to call advance_objective() by hand.
	RESOURCE_AT_LEAST,
}

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var completion_type: CompletionType = CompletionType.MANUAL
## Only read when completion_type is RESOURCE_AT_LEAST - one of
## StoryIdentifiers.KNOWN_RESOURCES ("wood", "stone", "berries").
@export var resource: String = ""
@export var target_amount: int = 0

func validate() -> Array[String]:
	var errors: Array[String] = []
	if not StoryIdentifiers.is_valid(id):
		errors.append("ObjectiveDefinition.id is not a valid identifier: '%s'" % id)
	if title.is_empty():
		errors.append("ObjectiveDefinition '%s' has no title" % id)
	if description.is_empty():
		errors.append("ObjectiveDefinition '%s' has no description" % id)
	if completion_type == CompletionType.RESOURCE_AT_LEAST:
		if not StoryIdentifiers.is_known_resource(resource):
			errors.append("ObjectiveDefinition '%s' names an unknown resource: '%s'" % [id, resource])
		if target_amount <= 0:
			errors.append("ObjectiveDefinition '%s' target_amount must be positive, got %d" % [id, target_amount])
	return errors
