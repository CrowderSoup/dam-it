extends Node
## Tracks shared game progress: resources, dam completion, and the Lodge
## build-up that becomes available afterward. Autoloaded as "GameState".

signal wood_changed(new_amount: int)
signal stone_changed(new_amount: int)
signal dam_progress_changed(built: int, total: int)
signal dam_completed
signal lodge_stage_changed(stage: int)
signal lodge_completed

const WOOD_PER_DAM_PIECE := 2
const STONE_PER_DAM_PIECE := 1

## Index 0 is the cost of advancing FROM stage 0 TO stage 1, etc.
const LODGE_STAGE_COSTS := [
	{"wood": 4, "stone": 2},
	{"wood": 5, "stone": 3},
	{"wood": 6, "stone": 4},
]
const LODGE_MAX_STAGE := 3

var wood: int = 0
var stone: int = 0
var dam_pieces_total: int = 0
var dam_pieces_built: int = 0
var lodge_stage: int = 0

## Called by each DamSlot on _ready() so the total is derived from the
## scene instead of duplicated as a magic number.
func register_dam_slot() -> void:
	dam_pieces_total += 1
	dam_progress_changed.emit(dam_pieces_built, dam_pieces_total)

func add_wood(amount: int) -> void:
	wood += amount
	wood_changed.emit(wood)

func add_stone(amount: int) -> void:
	stone += amount
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

func can_afford_dam_piece() -> bool:
	return wood >= WOOD_PER_DAM_PIECE and stone >= STONE_PER_DAM_PIECE

func spend_resources_on_dam_piece() -> void:
	wood -= WOOD_PER_DAM_PIECE
	stone -= STONE_PER_DAM_PIECE
	wood_changed.emit(wood)
	stone_changed.emit(stone)
	dam_pieces_built += 1
	dam_progress_changed.emit(dam_pieces_built, dam_pieces_total)
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

## Generic spend for one-off cosmetic purchases (garden decorations) that
## don't need their own dedicated cost table like the dam/Lodge do.
func can_afford(wood_cost: int, stone_cost: int) -> bool:
	return wood >= wood_cost and stone >= stone_cost

func spend(wood_cost: int, stone_cost: int) -> void:
	wood -= wood_cost
	stone -= stone_cost
	wood_changed.emit(wood)
	stone_changed.emit(stone)

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
	if lodge_stage >= LODGE_MAX_STAGE:
		lodge_completed.emit()

## Restores the plain scalar fields from a save file, silently (no signals
## yet - Main hasn't finished restoring dam-slot/lodge scene state at this
## point, and SaveManager autosaves on some of these signals, so emitting
## early would save a still-half-restored scene over the real save data).
## Call announce_loaded_state() once Main has finished restoring everything.
func load_from_save(data: Dictionary) -> void:
	wood = data.get("wood", 0)
	stone = data.get("stone", 0)
	lodge_stage = data.get("lodge_stage", 0)

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
	dam_progress_changed.emit(dam_pieces_built, dam_pieces_total)
	lodge_stage_changed.emit(lodge_stage)

## Resets all progress (dam + Lodge) ahead of a scene reload;
## dam_pieces_total is rebuilt as the reloaded DamSlot instances
## re-register themselves.
func reset() -> void:
	wood = 0
	stone = 0
	dam_pieces_total = 0
	dam_pieces_built = 0
	lodge_stage = 0
	wood_changed.emit(wood)
	stone_changed.emit(stone)
	dam_progress_changed.emit(dam_pieces_built, dam_pieces_total)
	lodge_stage_changed.emit(lodge_stage)
