class_name StoryIdentifiers
extends RefCounted
## Shared identifier rules and small known-value registries for the Act I
## story data schema (StoryCondition, StoryEffect, DialogueLine,
## DialogueDefinition, ObjectiveDefinition - see
## docs/design/dialogue-schema.md). Kept separate from ActOneController so
## the schema Resources can validate their own shape without depending on
## the autoload or a live content registry.

## Every speaker id a DialogueDefinition or DialogueLine may name - see
## docs/design/cast.md. Keep in sync with the cast; a typo here should fail
## fixture validation loudly rather than silently accepting an unknown name.
const KNOWN_SPEAKERS: PackedStringArray = [
	"reed", "moss", "marnie", "eddy", "clover", "saffron", "bramble", "hazel",
]

## GameState resources an ObjectiveDefinition's RESOURCE_AT_LEAST completion
## may track. Keep in sync with GameState's wood/stone/berries fields.
const KNOWN_RESOURCES: PackedStringArray = ["wood", "stone", "berries"]

static var _identifier_regex: RegEx

## True for a lowercase snake_case identifier such as "gather_starter_wood" -
## the shape every flag, objective id, dialogue id, and choice id must take
## so a malformed or empty identifier fails validation instead of silently
## becoming a no-op lookup at runtime.
static func is_valid(id: String) -> bool:
	if id.is_empty():
		return false
	if _identifier_regex == null:
		_identifier_regex = RegEx.new()
		var compile_error := _identifier_regex.compile("^[a-z][a-z0-9_]*$")
		assert(compile_error == OK, "StoryIdentifiers regex failed to compile")
	return _identifier_regex.search(id) != null

static func is_known_speaker(id: String) -> bool:
	return KNOWN_SPEAKERS.has(id)

static func is_known_resource(id: String) -> bool:
	return KNOWN_RESOURCES.has(id)
