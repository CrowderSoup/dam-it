extends CanvasLayer

@onready var wood_label: Label = $Margin/VBox/WoodLabel
@onready var dam_label: Label = $Margin/VBox/DamLabel
@onready var complete_label: Label = $CompleteLabel

func _ready() -> void:
	GameState.wood_changed.connect(_on_wood_changed)
	GameState.dam_progress_changed.connect(_on_dam_progress_changed)
	GameState.dam_completed.connect(_on_dam_completed)
	_on_wood_changed(GameState.wood)
	_on_dam_progress_changed(GameState.dam_pieces_built, GameState.dam_pieces_total)
	complete_label.hide()

func _on_wood_changed(amount: int) -> void:
	wood_label.text = "Wood: %d" % amount

func _on_dam_progress_changed(built: int, total: int) -> void:
	dam_label.text = "Dam pieces: %d / %d" % [built, total]

func _on_dam_completed() -> void:
	complete_label.show()
