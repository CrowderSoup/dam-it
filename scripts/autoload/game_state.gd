extends Node
## Tracks shared game progress: resources gathered and dam completion.
## Autoloaded as "GameState" (see project.godot).

signal wood_changed(new_amount: int)
signal dam_progress_changed(built: int, total: int)
signal dam_completed

const WOOD_PER_DAM_PIECE := 3

var wood: int = 0
var dam_pieces_total: int = 0
var dam_pieces_built: int = 0

## Called by each DamSlot on _ready() so the total is derived from the
## scene instead of duplicated as a magic number.
func register_dam_slot() -> void:
	dam_pieces_total += 1
	dam_progress_changed.emit(dam_pieces_built, dam_pieces_total)

func add_wood(amount: int) -> void:
	wood += amount
	wood_changed.emit(wood)

func can_afford_dam_piece() -> bool:
	return wood >= WOOD_PER_DAM_PIECE

## Zeroes progress ahead of a scene reload; dam_pieces_total is rebuilt as
## the reloaded DamSlot instances re-register themselves.
func reset() -> void:
	wood = 0
	dam_pieces_total = 0
	dam_pieces_built = 0
	wood_changed.emit(wood)
	dam_progress_changed.emit(dam_pieces_built, dam_pieces_total)

func spend_wood_on_dam_piece() -> void:
	wood -= WOOD_PER_DAM_PIECE
	wood_changed.emit(wood)
	dam_pieces_built += 1
	dam_progress_changed.emit(dam_pieces_built, dam_pieces_total)
	if dam_pieces_total > 0 and dam_pieces_built >= dam_pieces_total:
		dam_completed.emit()
