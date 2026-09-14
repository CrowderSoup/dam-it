extends Node
## Tracks shared game progress: resources, dam completion, the Lodge
## build-up that becomes available afterward, and the beaver's energy.
## Autoloaded as "GameState".

signal wood_changed(new_amount: int)
signal stone_changed(new_amount: int)
signal dam_progress_changed(built: int, total: int)
signal dam_completed
signal lodge_stage_changed(stage: int)
signal lodge_completed
signal energy_changed(new_amount: float)
signal berries_changed(new_amount: int)
signal pouch_upgraded(tier: int)
## Emitted when a chop/mine is blocked because the pouch has no room left
## for that resource - "wood" or "stone". HUD listens to surface a toast;
## nothing else needs to react.
signal pouch_full(kind: String)

const WOOD_PER_DAM_PIECE := 2
const STONE_PER_DAM_PIECE := 1

## How much wood/stone the beaver's pouch can hold at once, before any
## upgrades - gathering past this does nothing until some is spent or the
## pouch is upgraded (see POUCH_UPGRADE_COSTS below, bought at a finished
## Lodge - Lodge.can_upgrade_pouch()).
const POUCH_BASE_CAPACITY := 10
const POUCH_CAPACITY_PER_TIER := 5
const POUCH_MAX_TIER := 3
## Index 0 is the cost of upgrading FROM tier 0 TO tier 1, etc. Each cost is
## always affordable at the capacity it's bought at (10/15/20), so an
## upgrade is never out of reach because of the very cap it raises.
const POUCH_UPGRADE_COSTS := [
	{"wood": 6, "stone": 3},
	{"wood": 10, "stone": 6},
	{"wood": 14, "stone": 9},
]

## Index 0 is the cost of advancing FROM stage 0 TO stage 1, etc.
const LODGE_STAGE_COSTS := [
	{"wood": 4, "stone": 2},
	{"wood": 5, "stone": 3},
	{"wood": 6, "stone": 4},
]
const LODGE_MAX_STAGE := 3

## Energy: a soft, never-fail meter. Being "tired" only ever slows the
## beaver down (see Player.TIRED_SPEED_MULTIPLIER) - it never blocks
## chopping, mining, building, or anything else.
const ENERGY_MAX := 100.0
const ENERGY_TIRED_THRESHOLD := 25.0
const CHOP_ENERGY_COST := 3.0
const MINE_ENERGY_COST := 3.0
const BUILD_ENERGY_COST := 5.0

var wood: int = 0
var stone: int = 0
var berries: int = 0
var dam_pieces_total: int = 0
var dam_pieces_built: int = 0
var lodge_stage: int = 0
var energy: float = ENERGY_MAX
var pouch_tier: int = 0

func wood_capacity() -> int:
	return POUCH_BASE_CAPACITY + pouch_tier * POUCH_CAPACITY_PER_TIER

func stone_capacity() -> int:
	return POUCH_BASE_CAPACITY + pouch_tier * POUCH_CAPACITY_PER_TIER

func has_wood_room() -> bool:
	return wood < wood_capacity()

func has_stone_room() -> bool:
	return stone < stone_capacity()

## Shared wording for a full pouch, used both by the pouch_full signal's HUD
## toast and by Tree/Rock's get_interaction() failure reason, so a chop/mine
## attempted through Player and one called directly always read the same.
func pouch_full_message(kind: String) -> String:
	var noun: String = "Wood" if kind == "wood" else "Stone"
	return "%s pouch is full! Build something or upgrade your pouch at the Lodge." % noun

## Called by each DamSlot on _ready() so the total is derived from the
## scene instead of duplicated as a magic number.
func register_dam_slot() -> void:
	dam_pieces_total += 1
	dam_progress_changed.emit(dam_pieces_built, dam_pieces_total)

## Clamped to the pouch capacity - callers that need to know whether a
## gather actually happened (tree.gd/rock.gd, which gate chop()/mine() on
## has_wood_room()/has_stone_room() instead) can ignore the small excess
## this discards, since it only ever fires from an already-checked hit.
func add_wood(amount: int) -> void:
	wood = mini(wood + amount, wood_capacity())
	wood_changed.emit(wood)

func add_stone(amount: int) -> void:
	stone = mini(stone + amount, stone_capacity())
	stone_changed.emit(stone)

## Clamped removal for the raccoon's raids - never goes below zero. Returns
## the amount actually taken, in case a caller wants to react to it.
func remove_wood(amount: int) -> int:
	var removed: int = min(amount, wood)
	wood -= removed
	wood_changed.emit(wood)
	return removed

func remove_stone(amount: int) -> int:
	var removed: int = min(amount, stone)
	stone -= removed
	stone_changed.emit(stone)
	return removed

## Berries are harvested from bushes and spent feeding raccoons to shoo them
## off - see BerryBush.harvest() and Raccoon.feed().
func add_berries(amount: int) -> void:
	berries += amount
	berries_changed.emit(berries)

func remove_berries(amount: int) -> int:
	var removed: int = min(amount, berries)
	berries -= removed
	berries_changed.emit(berries)
	return removed

func can_afford_dam_piece() -> bool:
	return wood >= WOOD_PER_DAM_PIECE and stone >= STONE_PER_DAM_PIECE

func spend_resources_on_dam_piece() -> void:
	wood -= WOOD_PER_DAM_PIECE
	stone -= STONE_PER_DAM_PIECE
	wood_changed.emit(wood)
	stone_changed.emit(stone)
	dam_pieces_built += 1
	dam_progress_changed.emit(dam_pieces_built, dam_pieces_total)
	# No energy cost here, unlike the other spend_resources_on_*() calls below:
	# this is the initial dam build, before the pond (and any food source)
	# exists - see the matching comment on Player/tree.gd/rock.gd.
	if dam_pieces_total > 0 and dam_pieces_built >= dam_pieces_total:
		dam_completed.emit()

## Same cost as building a fresh piece, but for patching a leak on one
## that's already built - must NOT touch dam_pieces_built/dam_completed,
## unlike spend_resources_on_dam_piece().
func spend_resources_on_repair() -> void:
	wood -= WOOD_PER_DAM_PIECE
	stone -= STONE_PER_DAM_PIECE
	wood_changed.emit(wood)
	stone_changed.emit(stone)
	spend_energy(BUILD_ENERGY_COST)

## Generic spend for one-off cosmetic purchases (garden decorations) that
## don't need their own dedicated cost table like the dam/Lodge do.
func can_afford(wood_cost: int, stone_cost: int) -> bool:
	return wood >= wood_cost and stone >= stone_cost

func spend(wood_cost: int, stone_cost: int) -> void:
	wood -= wood_cost
	stone -= stone_cost
	wood_changed.emit(wood)
	stone_changed.emit(stone)
	spend_energy(BUILD_ENERGY_COST)

func can_afford_lodge_stage() -> bool:
	if lodge_stage >= LODGE_MAX_STAGE:
		return false
	var cost: Dictionary = LODGE_STAGE_COSTS[lodge_stage]
	return wood >= cost["wood"] and stone >= cost["stone"]

func advance_lodge_stage() -> void:
	if lodge_stage >= LODGE_MAX_STAGE:
		return
	var cost: Dictionary = LODGE_STAGE_COSTS[lodge_stage]
	wood -= cost["wood"]
	stone -= cost["stone"]
	wood_changed.emit(wood)
	stone_changed.emit(stone)
	lodge_stage += 1
	lodge_stage_changed.emit(lodge_stage)
	spend_energy(BUILD_ENERGY_COST)
	if lodge_stage >= LODGE_MAX_STAGE:
		lodge_completed.emit()

func can_afford_pouch_upgrade() -> bool:
	if pouch_tier >= POUCH_MAX_TIER:
		return false
	var cost: Dictionary = POUCH_UPGRADE_COSTS[pouch_tier]
	return wood >= cost["wood"] and stone >= cost["stone"]

func purchase_pouch_upgrade() -> void:
	if not can_afford_pouch_upgrade():
		return
	var cost: Dictionary = POUCH_UPGRADE_COSTS[pouch_tier]
	wood -= cost["wood"]
	stone -= cost["stone"]
	wood_changed.emit(wood)
	stone_changed.emit(stone)
	pouch_tier += 1
	pouch_upgraded.emit(pouch_tier)
	spend_energy(BUILD_ENERGY_COST)

## The pond doesn't exist, and nothing threatens the beaver, until every dam
## slot is built. Player uses this to hold off ambient energy drain until
## then - see the AMBIENT_DRAIN comment on Player.
func is_dam_complete() -> bool:
	return dam_pieces_total > 0 and dam_pieces_built >= dam_pieces_total

func is_tired() -> bool:
	return energy <= ENERGY_TIRED_THRESHOLD

func spend_energy(amount: float) -> void:
	energy = maxf(0.0, energy - amount)
	energy_changed.emit(energy)

func restore_energy(amount: float) -> void:
	energy = minf(ENERGY_MAX, energy + amount)
	energy_changed.emit(energy)

func restore_energy_fully() -> void:
	energy = ENERGY_MAX
	energy_changed.emit(energy)

## Restores the plain scalar fields from a save file, silently (no signals
## yet - Main hasn't finished restoring dam-slot/lodge scene state at this
## point, and SaveManager autosaves on some of these signals, so emitting
## early would save a still-half-restored scene over the real save data).
## Call announce_loaded_state() once Main has finished restoring everything.
func load_from_save(data: Dictionary) -> void:
	pouch_tier = _saved_int(data, "pouch_tier", 0, 0, POUCH_MAX_TIER)
	wood = _saved_int(data, "wood", 0, 0, wood_capacity())
	stone = _saved_int(data, "stone", 0, 0, stone_capacity())
	berries = _saved_int(data, "berries", 0, 0, 999999)
	lodge_stage = _saved_int(data, "lodge_stage", 0, 0, LODGE_MAX_STAGE)
	energy = _saved_float(data, "energy", ENERGY_MAX, 0.0, ENERGY_MAX)

func _saved_int(data: Dictionary, key: String, default_value: int, minimum: int, maximum: int) -> int:
	var value: Variant = data.get(key, default_value)
	if value is int or value is float:
		return clampi(int(value), minimum, maximum)
	return default_value

func _saved_float(data: Dictionary, key: String, default_value: float, minimum: float, maximum: float) -> float:
	var value: Variant = data.get(key, default_value)
	if value is int or value is float:
		return clampf(float(value), minimum, maximum)
	return default_value

## Dam-slot state is scene-shaped, not GameState-shaped, so Main restores
## that directly and reports back the resulting count here (silently, see
## load_from_save()).
func restore_dam_progress(built: int) -> void:
	dam_pieces_built = built

## Fires every progress signal once, reflecting whatever state is currently
## set. Used after a full load (see load_from_save()) so every listener
## (HUD, critters, SaveManager's autosave-on-signal) reacts to the final
## restored state exactly once, instead of to each field as it's restored.
func announce_loaded_state() -> void:
	wood_changed.emit(wood)
	stone_changed.emit(stone)
	berries_changed.emit(berries)
	dam_progress_changed.emit(dam_pieces_built, dam_pieces_total)
	lodge_stage_changed.emit(lodge_stage)
	energy_changed.emit(energy)
	pouch_upgraded.emit(pouch_tier)

## Resets all progress (dam + Lodge + energy + pouch) ahead of a scene
## reload; dam_pieces_total is rebuilt as the reloaded DamSlot instances
## re-register themselves.
func reset() -> void:
	wood = 0
	stone = 0
	berries = 0
	dam_pieces_total = 0
	dam_pieces_built = 0
	lodge_stage = 0
	energy = ENERGY_MAX
	pouch_tier = 0
	wood_changed.emit(wood)
	stone_changed.emit(stone)
	berries_changed.emit(berries)
	dam_progress_changed.emit(dam_pieces_built, dam_pieces_total)
	lodge_stage_changed.emit(lodge_stage)
	energy_changed.emit(energy)
	pouch_upgraded.emit(pouch_tier)
