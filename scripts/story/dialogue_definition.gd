class_name DialogueDefinition
extends Resource
## A speaker-led scene: an ordered list of DialogueLines, optionally
## branching into a few tonal response choices. Writers add new dialogue by
## creating one of these (a .tres resource) instead of editing gameplay
## scripts. See docs/design/dialogue-schema.md for the full schema and
## data/story/act1/dialogue_moss_intro.tres for a worked example.

@export var id: String = ""
## Default speaker for lines that don't override it - see speaker_for_line().
@export var speaker: String = ""
## Gates whether ActOneController.start_dialogue() may begin this dialogue.
@export var condition: StoryCondition = null
@export var lines: Array[DialogueLine] = []

func validate() -> Array[String]:
	var errors: Array[String] = []
	if not StoryIdentifiers.is_valid(id):
		errors.append("DialogueDefinition.id is not a valid identifier: '%s'" % id)
	if not StoryIdentifiers.is_known_speaker(speaker):
		errors.append("DialogueDefinition '%s' has an unknown speaker: '%s'" % [id, speaker])
	if lines.is_empty():
		errors.append("DialogueDefinition '%s' has no lines" % id)
	if condition != null:
		errors.append_array(condition.validate())
	for line in lines:
		if line == null:
			errors.append("DialogueDefinition '%s' has a null line" % id)
		else:
			errors.append_array(line.validate())
	return errors

func speaker_for_line(line: DialogueLine) -> String:
	return line.speaker if not line.speaker.is_empty() else speaker
