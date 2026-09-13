extends CanvasLayer

const HINT_DURATION := 6.0
const TOAST_DURATION := 6.0

@onready var wood_label: Label = $BottomMargin/ItemsHBox/WoodGroup/WoodLabel
@onready var stone_label: Label = $BottomMargin/ItemsHBox/StoneGroup/StoneLabel
@onready var dam_label: Label = $BottomMargin/ItemsHBox/DamGroup/DamLabel
@onready var lodge_label: Label = $BottomMargin/ItemsHBox/LodgeGroup/LodgeLabel
@onready var toast_label: Label = $ToastLabel
@onready var toast_background: Panel = $ToastBackground
@onready var hint_label: Label = $HintLabel
@onready var hint_background: Panel = $HintBackground
@onready var storm_indicator: Control = $StormIndicator
@onready var raccoon_indicator: Control = $RaccoonIndicator

var _toast_generation := 0

func _ready() -> void:
	GameState.wood_changed.connect(_on_wood_changed)
	GameState.stone_changed.connect(_on_stone_changed)
	GameState.dam_progress_changed.connect(_on_dam_progress_changed)
	GameState.dam_completed.connect(_on_dam_completed)
	GameState.lodge_stage_changed.connect(_on_lodge_stage_changed)
	_on_wood_changed(GameState.wood)
	_on_stone_changed(GameState.stone)
	_on_dam_progress_changed(GameState.dam_pieces_built, GameState.dam_pieces_total)
	_on_lodge_stage_changed(GameState.lodge_stage)
	var hide_hint := func():
		hint_label.hide()
		hint_background.hide()
	get_tree().create_timer(HINT_DURATION).timeout.connect(hide_hint)

func set_camera(camera: Camera2D) -> void:
	storm_indicator.set_camera(camera)
	raccoon_indicator.set_camera(camera)

func point_to_storm(target: Node2D) -> void:
	storm_indicator.point_to(target)

func clear_storm_indicator() -> void:
	storm_indicator.clear()

func point_to_raccoon(target: Node2D) -> void:
	raccoon_indicator.point_to(target)

func clear_raccoon_indicator() -> void:
	raccoon_indicator.clear()

## A brief announcement (dam complete, a storm hit, the raccoon showed up).
## Replacing a still-showing toast just extends it - an earlier toast's
## timer becoming a no-op once the generation no longer matches.
func show_toast(text: String, duration: float = TOAST_DURATION) -> void:
	_toast_generation += 1
	var my_generation := _toast_generation
	toast_label.text = text
	toast_label.show()
	toast_background.show()
	get_tree().create_timer(duration).timeout.connect(func():
		if my_generation == _toast_generation:
			toast_label.hide()
			toast_background.hide()
	)

func _on_wood_changed(amount: int) -> void:
	wood_label.text = str(amount)

func _on_stone_changed(amount: int) -> void:
	stone_label.text = str(amount)

func _on_dam_progress_changed(built: int, total: int) -> void:
	dam_label.text = "%d / %d" % [built, total]

func _on_lodge_stage_changed(stage: int) -> void:
	if GameState.dam_pieces_total == 0 or GameState.dam_pieces_built < GameState.dam_pieces_total:
		lodge_label.text = "Locked"
	elif stage >= GameState.LODGE_MAX_STAGE:
		lodge_label.text = "Done!"
	else:
		lodge_label.text = "%d / %d" % [stage, GameState.LODGE_MAX_STAGE]

func _on_dam_completed() -> void:
	show_toast("Dam complete! A Lodge site has appeared south of the pond.")
	# dam_progress_changed already flipped the "X / Y" dam counter, but the
	# Lodge counter's "Locked" text depends on dam completion too, and only
	# lodge_stage_changed normally refreshes it - without this it would keep
	# reading "Locked" until the player's first Lodge interaction.
	_on_lodge_stage_changed(GameState.lodge_stage)
