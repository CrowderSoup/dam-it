class_name InteractionOption
extends RefCounted
## The shared interaction contract every interactable world object exposes
## through get_interaction(): a plain, disposable snapshot of what pressing
## "interact" would do to it right now - see Interactable.get_interaction()
## for the default (no-op) implementation and Tree/Rock/DamSlot/Lodge/etc.
## for real ones.
##
## This is deliberately dumb data (plus one bound Callable) rather than a
## Resource: it's built fresh every time it's asked for, never saved to
## disk, and just needs to travel from a world object up to Player and HUD
## without either of them branching on node groups/types to figure out
## what "interact" means here. The actual gameplay rules (cost math,
## whether an action is currently possible) stay on the world object that
## builds the option - see Player._try_interact() and HUD.set_action_prompt().

## Short verb phrase for the action prompt, e.g. "Chop", "Build Dam Piece".
var label: String
## The method to invoke if the player commits to this action. Always safe
## to call unconditionally - every implementation re-checks its own
## availability internally, the same way chop()/mine() always have - so
## this contract only ever *predicts* success for display purposes.
var perform: Callable
## Whether performing this action right now is expected to actually do
## something (enough resources, not already maxed out, etc).
var available: bool
## Concise, player-facing reason `perform` won't succeed right now (e.g.
## "Not enough wood or stone", "Wood pouch is full"). Empty when `available`
## is true.
var reason: String
## Resource cost to show alongside the label, e.g. {"wood": 2, "stone": 1}.
## Omitted keys/zero amounts are treated as "no cost of that kind" - see
## cost_text(). Empty for actions that don't cost resources (chop, mine,
## harvest, eat).
var cost: Dictionary

func _init(p_label: String, p_perform: Callable, p_available: bool, p_reason: String = "", p_cost: Dictionary = {}) -> void:
	label = p_label
	perform = p_perform
	available = p_available
	reason = p_reason
	cost = p_cost

## Renders `cost` as a short, human-readable list like "2 Wood, 1 Stone",
## for the HUD's action prompt. Empty string if this action has no cost.
func cost_text() -> String:
	var parts := PackedStringArray()
	if cost.get("wood", 0) > 0:
		parts.append("%d Wood" % cost["wood"])
	if cost.get("stone", 0) > 0:
		parts.append("%d Stone" % cost["stone"])
	if cost.get("berries", 0) > 0:
		parts.append("%d Berries" % cost["berries"])
	return ", ".join(parts)
