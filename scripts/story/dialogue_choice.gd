class_name DialogueChoice
extends Resource
## One concise response option on a DialogueLine. Per
## docs/design/dialogue-style.md: at most three tonal options
## (earnest/practical/playful), and every choice gets a character-specific
## acknowledgement without hiding a "wrong answer" or branching the plot -
## so, unlike DialogueLine, a choice has no condition of its own beyond what
## the line already gates.

enum Tone { EARNEST, PRACTICAL, PLAYFUL }

@export var id: String = ""
@export var tone: Tone = Tone.EARNEST
@export var text: String = ""
## The speaker's reply to picking this choice.
@export var acknowledgement: String = ""
@export var effects: Array[StoryEffect] = []

func validate() -> Array[String]:
	var errors: Array[String] = []
	if not StoryIdentifiers.is_valid(id):
		errors.append("DialogueChoice.id is not a valid identifier: '%s'" % id)
	if text.is_empty():
		errors.append("DialogueChoice '%s' has no text" % id)
	if acknowledgement.is_empty():
		errors.append("DialogueChoice '%s' has no acknowledgement" % id)
	for effect in effects:
		if effect == null:
			errors.append("DialogueChoice '%s' has a null effect" % id)
		else:
			errors.append_array(effect.validate())
	return errors
