class_name DialogueLine
extends Resource
## One panel of a DialogueDefinition: a line of text, optionally gated by a
## StoryCondition, with effects that fire the moment it's shown and up to
## three response choices. See docs/design/dialogue-schema.md.

## Word count above which a line almost certainly isn't the "one or two
## sentences, ~25-30 words" dialogue-style.md calls for - catches a pasted
## wall of text rather than enforcing the guideline to the letter.
const MAX_WORDS := 40
const MAX_CHOICES := 3

## Speaker override for this line; empty means "use the DialogueDefinition's
## default speaker" (see DialogueDefinition.speaker_for_line()).
@export var speaker: String = ""
@export_multiline var text: String = ""
## Gates whether this line is reachable at all. Null means unconditional.
@export var condition: StoryCondition = null
## Applied as soon as the line is shown, before any choice is made.
@export var effects: Array[StoryEffect] = []
@export var choices: Array[DialogueChoice] = []

func validate() -> Array[String]:
	var errors: Array[String] = []
	if not speaker.is_empty() and not StoryIdentifiers.is_known_speaker(speaker):
		errors.append("DialogueLine speaker override is not a known speaker: '%s'" % speaker)
	if text.is_empty():
		errors.append("DialogueLine has no text")
	else:
		var word_count := text.split(" ", false).size()
		if word_count > MAX_WORDS:
			errors.append("DialogueLine text is too long (%d words): '%s'" % [word_count, text])
	if condition != null:
		errors.append_array(condition.validate())
	for effect in effects:
		if effect == null:
			errors.append("DialogueLine has a null effect")
		else:
			errors.append_array(effect.validate())
	if choices.size() > MAX_CHOICES:
		errors.append("DialogueLine has %d choices; dialogue-style.md allows at most %d" % [choices.size(), MAX_CHOICES])
	var seen_choice_ids: Dictionary = {}
	for choice in choices:
		if choice == null:
			errors.append("DialogueLine has a null choice")
			continue
		errors.append_array(choice.validate())
		if seen_choice_ids.has(choice.id):
			errors.append("Duplicate choice id on a DialogueLine: '%s'" % choice.id)
		seen_choice_ids[choice.id] = true
	return errors
