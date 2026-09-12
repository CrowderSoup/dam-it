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
