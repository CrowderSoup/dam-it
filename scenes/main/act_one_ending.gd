class_name ActOneEnding
extends Node
## Discrete, save-safe Act I finale. Only durable story boundaries are saved;
## loads resume from the next boundary rather than attempting to restore time.

@export var safe_delay := 1.5
@export var beat_delay := 1.2
@export var banner_duration := 3.5

@onready var main = get_parent()
@onready var player = main.get_node("Player")
@onready var camera: Camera2D = main.get_node("Player/Camera2D")
@onready var hud = main.get_node("HUD")
@onready var game_menu = main.get_node("GameMenu")
@onready var journal = main.get_node("Journal")
@onready var bramble: BrambleEncounter = main.get_node("BrambleEncounter")
@onready var mud_pulse: CanvasItem = main.get_node("EndingMudPulse")
@onready var route: CanvasItem = main.get_node("UpstreamRoute")
@onready var group_frame: Marker2D = main.get_node("EndingMarkers/EndingGroupFrame")
@onready var bramble_frame: Marker2D = main.get_node("EndingMarkers/EndingBrambleExit")
@onready var route_frame: Marker2D = main.get_node("EndingMarkers/UpstreamRouteFrame")

var _generation := 0
var _active := false
var _base_zoom := Vector2.ONE

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_base_zoom = camera.zoom
	main.act_one_ending_eligibility_changed.connect(_on_eligibility_changed)
	bramble.approach_completed.connect(_on_bramble_approached)
	bramble.encounter_completed.connect(_reveal_route)
	ActOneController.dialogue_ended.connect(_on_dialogue_ended)
	call_deferred("restore_from_story_state")

func is_active() -> bool:
	return _active

func restore_from_story_state() -> void:
	_generation += 1
	route.visible = ActOneController.get_flag("act_one_route_revealed") or ActOneController.get_flag("act_one_complete")
	mud_pulse.hide()
	if ActOneController.get_flag("act_one_complete"):
		_finish(false)
	elif not ActOneController.get_flag("act_one_ending_started"):
		# BrambleEncounter's public API is independently testable and older or
		# hand-authored saves may contain its flags alone. They do not authorize
		# the chapter controller to seize control of ordinary play.
		if main.is_act_one_ending_eligible():
			_on_eligibility_changed(true)
	elif ActOneController.get_flag("act_one_route_revealed"):
		_lock_play()
		_complete_chapter.call_deferred()
	elif ActOneController.get_flag("bramble_intro_complete"):
		_lock_play()
		_reveal_route.call_deferred()
	elif ActOneController.get_flag("bramble_material_taken"):
		_lock_play()
		_frame(bramble_frame)
		if ActOneController.get_active_dialogue_id() != "bramble_willowbend_intro":
			main.begin_bramble_escape()
	elif ActOneController.get_flag("bramble_intro_started"):
		_lock_play()
		_on_bramble_approached.call_deferred()
	elif ActOneController.get_flag("act_one_ending_started"):
		_lock_play()
		_show_muddy_pulse.call_deferred()

func _on_eligibility_changed(eligible: bool) -> void:
	_generation += 1
	if not eligible:
		return
	var token := _generation
	await get_tree().create_timer(safe_delay).timeout
	if token == _generation and main.is_act_one_ending_eligible():
		_begin()

func _begin() -> void:
	ActOneController.set_flag("act_one_ending_started")
	_lock_play()
	Ambience.set_chapter_ending_active(true)
	if not ActOneController.get_flag("act_one_celebration_started"):
		ActOneController.set_flag("act_one_celebration_started")
	hud.show_toast("Willowbend meets at Reed's new Lodge.", beat_delay)
	_frame(group_frame)
	await get_tree().create_timer(beat_delay).timeout
	_show_muddy_pulse()

func _show_muddy_pulse() -> void:
	if ActOneController.get_flag("bramble_intro_started"):
		return
	_lock_play()
	Ambience.set_chapter_ending_active(true)
	mud_pulse.show()
	ActOneController.set_flag("act_one_muddy_pulse_seen")
	hud.show_toast("Mud and burned branches rush down the creek.", beat_delay)
	await get_tree().create_timer(beat_delay).timeout
	mud_pulse.hide()
	_frame(bramble_frame)
	main.start_bramble_introduction()

func _on_bramble_approached() -> void:
	if not _active or ActOneController.get_flag("bramble_material_taken"):
		return
	main.commit_bramble_material_take()
	ActOneController.start_dialogue("bramble_willowbend_intro")

func _on_dialogue_ended(dialogue_id: String) -> void:
	if dialogue_id == "bramble_willowbend_intro" and _active:
		main.begin_bramble_escape()

func _reveal_route() -> void:
	if not _active or ActOneController.get_flag("act_one_route_revealed"):
		return
	route.show()
	ActOneController.set_flag("act_one_route_revealed")
	_frame(route_frame)
	await get_tree().create_timer(beat_delay).timeout
	_complete_chapter()

func _complete_chapter() -> void:
	route.show()
	hud.show_chapter_banner("CHAPTER ONE COMPLETE", "Follow the water to Aspen Meadow")
	Ambience.play_chapter_complete_cue()
	if not ActOneController.get_flag("act_one_complete"):
		ActOneController.set_flag("act_one_complete")
		SaveManager.save_game()
	await get_tree().create_timer(banner_duration).timeout
	hud.hide_chapter_banner()
	_finish(true)

func _lock_play() -> void:
	_active = true
	player.set_input_enabled(false)
	game_menu.process_mode = Node.PROCESS_MODE_DISABLED
	journal.process_mode = Node.PROCESS_MODE_DISABLED

func _finish(animate_camera: bool) -> void:
	_active = false
	player.set_input_enabled(true)
	game_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	journal.process_mode = Node.PROCESS_MODE_ALWAYS
	Ambience.sync_from_game_state(not animate_camera)
	if animate_camera:
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(camera, "position", Vector2.ZERO, 0.6)
		tween.parallel().tween_property(camera, "zoom", _base_zoom, 0.6)
	else:
		camera.position = Vector2.ZERO
		camera.zoom = _base_zoom

func _frame(marker: Marker2D) -> void:
	var target: Vector2 = marker.global_position - player.global_position
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tween.tween_property(camera, "position", target, 0.6)
	tween.tween_property(camera, "zoom", _base_zoom * 1.12, 0.6)
