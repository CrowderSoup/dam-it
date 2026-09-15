extends CanvasLayer
## Also owns the staged tutorial banner (see _show_tutorial()) that replaced
## the old single "opening hint" banner, and the compact current-objective
## display that surfaces ActOneController's state (see
## docs/design/dialogue-schema.md for that data model) - see
## _refresh_objective_display(). The full history behind that objective
## (completed + current, in plain language) lives in the Journal
## (scenes/ui/journal.gd); clicking this HUD's objective banner, or pressing
## the "journal" action, opens it - see journal_requested below, wired up by
## Main.

## Emitted when the player clicks the current-objective banner, asking
## whoever owns the Journal (Main) to open it - the mouse half of "keyboard,
## mouse, and gamepad can open... the journal" (the "journal" action covers
## the other two).
signal journal_requested

const TUTORIAL_DURATION := 6.0
const TOAST_DURATION := 6.0
const FAILURE_TOAST_DURATION := 2.5

## Staged tutorial ids - see _show_tutorial()'s call sites for when each one
## becomes relevant, and _tutorial_text() for its copy.
const TUTORIAL_MOVE := "move"
const TUTORIAL_INTERACT := "interact"
const TUTORIAL_JOURNAL := "journal"

@onready var energy_label: Label = $BottomMargin/ItemsHBox/EnergyGroup/EnergyLabel
@onready var wood_label: Label = $BottomMargin/ItemsHBox/WoodGroup/WoodLabel
@onready var stone_label: Label = $BottomMargin/ItemsHBox/StoneGroup/StoneLabel
@onready var berries_label: Label = $BottomMargin/ItemsHBox/BerriesGroup/BerriesLabel
@onready var dam_label: Label = $BottomMargin/ItemsHBox/DamGroup/DamLabel
@onready var lodge_label: Label = $BottomMargin/ItemsHBox/LodgeGroup/LodgeLabel
@onready var toast_label: Label = $ToastLabel
@onready var toast_background: Panel = $ToastBackground
@onready var tutorial_label: Label = $TutorialLabel
@onready var tutorial_background: Panel = $TutorialBackground
@onready var objective_label: Label = $ObjectiveLabel
@onready var objective_background: Panel = $ObjectiveBackground
@onready var storm_indicator: Control = $StormIndicator
@onready var raccoon_indicator: Control = $RaccoonIndicator
@onready var action_prompt_label: Label = $ActionPromptLabel
@onready var action_prompt_background: Panel = $ActionPromptBackground
@onready var chapter_banner: Panel = $ChapterBanner
@onready var chapter_title: Label = $ChapterBanner/Title
@onready var chapter_subtitle: Label = $ChapterBanner/Subtitle

var _toast_generation := 0
var _tutorial_generation := 0
var _current_tutorial_id := ""
var _pending_tutorial_ids: Array[String] = []

func _ready() -> void:
	GameState.wood_changed.connect(_on_wood_changed)
	GameState.stone_changed.connect(_on_stone_changed)
	GameState.berries_changed.connect(_on_berries_changed)
	GameState.dam_progress_changed.connect(_on_dam_progress_changed)
	GameState.dam_completed.connect(_on_dam_completed)
	GameState.lodge_stage_changed.connect(_on_lodge_stage_changed)
	GameState.energy_changed.connect(_on_energy_changed)
	GameState.pouch_upgraded.connect(_on_pouch_upgraded)
	GameState.pouch_full.connect(_on_pouch_full)
	ActOneController.objective_started.connect(_on_objective_changed)
	ActOneController.objective_progress_changed.connect(_on_objective_progress_changed)
	ActOneController.objective_completed.connect(_on_objective_changed)
	GameState.water_observed.connect(_on_water_observed)
	_on_wood_changed(GameState.wood)
	_on_stone_changed(GameState.stone)
	_on_berries_changed(GameState.berries)
	_on_dam_progress_changed(GameState.dam_pieces_built, GameState.dam_pieces_total)
	_on_lodge_stage_changed(GameState.lodge_stage)
	_on_energy_changed(GameState.energy)
	_refresh_objective_display()
	action_prompt_label.hide()
	action_prompt_background.hide()
	chapter_banner.hide()
	tutorial_label.hide()
	tutorial_background.hide()
	tutorial_background.gui_input.connect(_on_tutorial_gui_input)
	objective_background.gui_input.connect(_on_objective_gui_input)
	_show_tutorial(TUTORIAL_MOVE)

## Main calls this after its silent save restore. Child _ready() runs before
## Main can load GameState/ActOneController, so rebuild tutorial visibility
## and the objective banner from the restored state rather than leaving a
## returning player with fresh-game UI.
func restore_from_state() -> void:
	_current_tutorial_id = ""
	_pending_tutorial_ids.clear()
	_tutorial_generation += 1
	tutorial_label.hide()
	tutorial_background.hide()
	_refresh_objective_display()
	_show_tutorial(TUTORIAL_MOVE)
	if not ActOneController.get_current_objective_id().is_empty():
		_show_tutorial(TUTORIAL_JOURNAL)

## Dismisses whatever tutorial is currently showing the moment the player
## actually does the thing it was teaching - without consuming the event, so
## the same keypress still reaches Player/Journal normally. Movement,
## interaction, and opening the journal each cover their own tutorial; this
## also catches the (rare) case where a later tutorial overwrote an earlier
## one the player never got to act on.
func _unhandled_input(event: InputEvent) -> void:
	if _current_tutorial_id.is_empty():
		return
	if event.is_action_pressed("move_up") or event.is_action_pressed("move_down") \
			or event.is_action_pressed("move_left") or event.is_action_pressed("move_right") \
			or event.is_action_pressed("interact") or event.is_action_pressed("journal"):
		_dismiss_tutorial()

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

## Shows (or hides, for null) the persistent "what would pressing interact
## do right now" prompt - see interaction_option.gd and
## Player.interaction_option_changed. Grayed out and annotated with why when
## the action wouldn't currently succeed, so the player learns the reason
## before they even press the button rather than only after.
func set_action_prompt(option: InteractionOption) -> void:
	if option == null:
		action_prompt_label.hide()
		action_prompt_background.hide()
		return
	# The first time interacting with anything becomes possible is "the
	# moment" the interact tutorial is relevant - a fresh player is standing
	# next to their first tree/rock/etc. right now, prompt in hand.
	_show_tutorial(TUTORIAL_INTERACT)
	var text := "[%s] %s" % [InputSetup.interact_prompt(), option.label]
	var cost_text := option.cost_text()
	if not cost_text.is_empty():
		text += " (%s)" % cost_text
	if not option.available and not option.reason.is_empty():
		text += " - %s" % option.reason
	action_prompt_label.text = text
	if option.available:
		action_prompt_label.remove_theme_color_override("font_color")
	else:
		action_prompt_label.add_theme_color_override("font_color", Palette.ENERGY_LOW)
	action_prompt_label.show()
	action_prompt_background.show()

## A short, non-modal notice that the just-attempted interaction didn't
## succeed - see Player.interaction_failed. Shares the toast mechanism (and
## its "replacing a still-showing one just extends it" behavior) but with a
## much shorter default duration, since this is reacting to a button press
## rather than an ambient event.
func show_failure(reason: String) -> void:
	show_toast(reason, FAILURE_TOAST_DURATION)

func show_chapter_banner(title: String, subtitle: String) -> void:
	chapter_title.text = title
	chapter_subtitle.text = subtitle
	chapter_banner.show()

func hide_chapter_banner() -> void:
	chapter_banner.hide()

func _on_energy_changed(amount: float) -> void:
	energy_label.text = str(int(round(amount)))
	if GameState.is_tired():
		energy_label.add_theme_color_override("font_color", Palette.ENERGY_LOW)
	else:
		energy_label.remove_theme_color_override("font_color")

func _on_wood_changed(amount: int) -> void:
	wood_label.text = "%d/%d" % [amount, GameState.wood_capacity()]

func _on_stone_changed(amount: int) -> void:
	stone_label.text = "%d/%d" % [amount, GameState.stone_capacity()]

## The pouch capacity changed (an upgrade, or a load that restores one) -
## the resource labels' "/cap" half is stale until re-rendered, even
## though the carried amounts themselves didn't change.
func _on_pouch_upgraded(_tier: int) -> void:
	_on_wood_changed(GameState.wood)
	_on_stone_changed(GameState.stone)
	_on_berries_changed(GameState.berries)

func _on_pouch_full(kind: String) -> void:
	show_toast(GameState.pouch_full_message(kind), 3.0)

func _on_water_observed() -> void:
	show_toast("You read the water: the current runs strongest through the middle gap. Brace that one well.")

func _on_berries_changed(amount: int) -> void:
	berries_label.text = "%d/%d" % [amount, GameState.berry_capacity()]

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
	show_toast("Dam complete! Cattails and lilies are growing in the pond, and a Lodge site has appeared south of it.")
	# dam_progress_changed already flipped the "X / Y" dam counter, but the
	# Lodge counter's "Locked" text depends on dam completion too, and only
	# lodge_stage_changed normally refreshes it - without this it would keep
	# reading "Locked" until the player's first Lodge interaction.
	_on_lodge_stage_changed(GameState.lodge_stage)

## --- Current-objective display -------------------------------------------
## A compact, always-visible readout of ActOneController.get_current_
## objective_id() - the full completed+current history lives in the Journal
## (scenes/ui/journal.gd); clicking this banner or pressing "journal" opens
## it. Deliberately small and corner-anchored (see ObjectiveBackground's
## position in hud.tscn) so it states the goal without obscuring play.

func _on_objective_changed(_id: String) -> void:
	_refresh_objective_display()
	# A brand new objective existing is "the moment" the journal becomes
	# relevant - there's now something worth reviewing in it.
	_show_tutorial(TUTORIAL_JOURNAL)

func _on_objective_progress_changed(_id: String, _current: int, _target: int) -> void:
	_refresh_objective_display()

func _refresh_objective_display() -> void:
	var id := ActOneController.get_current_objective_id()
	if id.is_empty():
		objective_label.hide()
		objective_background.hide()
		return
	var objective: ObjectiveDefinition = ActOneController.get_objective(id)
	var status := ActOneController.get_objective_status(id)
	var text := objective.title
	if status == "completed":
		text = "[Done] " + text
	elif objective.target_amount > 0:
		text += " (%d/%d)" % [ActOneController.get_objective_progress(id), objective.target_amount]
	objective_label.text = text
	objective_label.show()
	objective_background.show()

func _on_objective_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		journal_requested.emit()

## --- Staged tutorials ------------------------------------------------------
## Replaces the old single "opening hint" banner with a handful of short,
## dismissible prompts that each surface once, right as their action becomes
## relevant (see the call sites of _show_tutorial() above and in
## set_action_prompt()) - and never again once GameState marks them seen,
## including after loading a save (see GameState.seen_tutorials).

func _tutorial_text(id: String) -> String:
	var gamepad := InputSetup.uses_gamepad()
	match id:
		TUTORIAL_MOVE:
			return "D-pad / left stick to move" if gamepad else "WASD / arrows to move"
		TUTORIAL_INTERACT:
			return "%s to chop, mine, build, and more" % ("A" if gamepad else "E")
		TUTORIAL_JOURNAL:
			return "%s to open your journal and see your objective" % ("Y" if gamepad else "J")
		_:
			return ""

## No-op if `id` was already seen or queued. A newly relevant tutorial waits
## behind the one already on screen instead of replacing it: Main starts the
## first objective during its own _ready(), just after this HUD presents the
## movement tutorial, so replacement would make a fresh player skip movement
## help entirely.
func _show_tutorial(id: String) -> void:
	if GameState.has_seen_tutorial(id) or _current_tutorial_id == id or id in _pending_tutorial_ids:
		return
	if not _current_tutorial_id.is_empty():
		_pending_tutorial_ids.append(id)
		return
	_current_tutorial_id = id
	_tutorial_generation += 1
	var my_generation := _tutorial_generation
	tutorial_label.text = _tutorial_text(id)
	tutorial_label.show()
	tutorial_background.show()
	get_tree().create_timer(TUTORIAL_DURATION).timeout.connect(func():
		if my_generation == _tutorial_generation:
			_dismiss_tutorial()
	)

func _dismiss_tutorial() -> void:
	if _current_tutorial_id.is_empty():
		return
	GameState.mark_tutorial_seen(_current_tutorial_id)
	_current_tutorial_id = ""
	tutorial_label.hide()
	tutorial_background.hide()
	_show_next_tutorial()

func _show_next_tutorial() -> void:
	while not _pending_tutorial_ids.is_empty():
		var next_id: String = _pending_tutorial_ids.pop_front()
		if not GameState.has_seen_tutorial(next_id):
			_show_tutorial(next_id)
			return

func _on_tutorial_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_dismiss_tutorial()
