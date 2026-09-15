extends Node
## Owns long-running music/ambience separately from one-shot interaction
## sounds. Stable world state selects a loop; live transitions may add a
## sting. This distinction keeps loading a completed save from replaying the
## dam celebration.
## Autoloaded as "Ambience".

enum State {
	NONE,
	TITLE,
	DRY_WILLOWBEND,
	RESTORED_POND,
	CHAPTER_ENDING,
	CALM_POST_CHAPTER,
}

const SAMPLE_RATE := 22050
const LOOP_SECONDS := 2.0
const SILENT_DB := -60.0
const NORMAL_DB := -8.0
const DIALOGUE_DB := -18.0
const CROSSFADE_SECONDS := 0.6
const DUCK_SECONDS := 0.18

var _players: Array[AudioStreamPlayer] = []
var _active_player_index := -1
var _current_state := State.NONE
var _dialogue_ducked := false
var _mix_tween: Tween
var _loop_start_count := 0
var _transformation_sting_count := 0
var _transformation_player: AudioStreamPlayer
var _streams: Dictionary = {}
var _playback_available := DisplayServer.get_name() != "headless"

func _ready() -> void:
	# Dialogue pauses the SceneTree. The ambience owner and its fades must keep
	# processing so a conversation ducks smoothly instead of freezing a fade.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _index in 2:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = SILENT_DB
		add_child(player)
		_players.append(player)
	_transformation_player = AudioStreamPlayer.new()
	_transformation_player.bus = "Master"
	_transformation_player.stream = _make_sting()
	add_child(_transformation_player)

	GameState.dam_completed.connect(_on_live_dam_completed)
	ActOneController.dialogue_started.connect(_on_dialogue_started)
	ActOneController.dialogue_ended.connect(_on_dialogue_ended)
	ActOneController.flag_changed.connect(_on_story_flag_changed)

func _exit_tree() -> void:
	# Release active playback before AudioServer shuts down. This matters for
	# short-lived headless runs as well as clean desktop exits: a loop or sting
	# can otherwise retain its AudioStreamPlaybackWAV through engine teardown.
	_kill_mix_tween()
	for player in _players:
		player.stop()
		player.stream = null
	if _transformation_player != null:
		_transformation_player.stop()
		_transformation_player.stream = null
	_streams.clear()

## Idempotently select a durable presentation state. Returns true only when
## a new loop was actually started, which also makes the contract easy to
## verify without depending on an audio device in headless tests.
func set_state(state: State, immediate: bool = false) -> bool:
	if state == _current_state:
		return false
	_current_state = state
	_start_loop_for_state(state, immediate)
	return true

## Reconstruct stable ambience after Main has applied a save. This never
## plays a transition sting: completed saves go directly to the pond loop.
func sync_from_game_state(immediate: bool = true) -> void:
	var stable_state := State.DRY_WILLOWBEND
	if ActOneController.get_flag("act_one_complete"):
		stable_state = State.CALM_POST_CHAPTER
	elif GameState.is_dam_complete():
		stable_state = State.RESTORED_POND
	set_state(stable_state, immediate)
	set_dialogue_ducked(
		not ActOneController.get_active_dialogue_id().is_empty(),
		immediate
	)

## #21 owns when to enter/leave this state and the authored ending cue. The
## slot exists now so that work can use the same idempotent state API without
## adding another audio owner. Until then it deliberately keeps the restored
## Willowbend bed underneath the sequence.
func set_chapter_ending_active(active: bool) -> void:
	set_state(State.CHAPTER_ENDING if active else State.RESTORED_POND)

func set_dialogue_ducked(ducked: bool, immediate: bool = false) -> bool:
	if ducked == _dialogue_ducked:
		return false
	_dialogue_ducked = ducked
	_fade_current_mix(immediate)
	return true

func get_state() -> State:
	return _current_state

func is_dialogue_ducked() -> bool:
	return _dialogue_ducked

func get_target_volume_db() -> float:
	return DIALOGUE_DB if _dialogue_ducked else NORMAL_DB

func get_loop_start_count() -> int:
	return _loop_start_count

func get_transformation_sting_count() -> int:
	return _transformation_sting_count

func _start_loop_for_state(state: State, immediate: bool) -> void:
	var stream_state := state
	# The chapter-ending music itself remains unimplemented by design (#21).
	if state == State.CHAPTER_ENDING:
		stream_state = State.RESTORED_POND
	if state == State.NONE:
		_stop_all(immediate)
		return
	if not _streams.has(stream_state):
		_streams[stream_state] = _make_loop(stream_state)

	var old_index := _active_player_index
	var new_index := 0 if old_index != 0 else 1
	var new_player := _players[new_index]
	new_player.stream = _streams[stream_state]
	new_player.volume_db = SILENT_DB
	# Godot's Dummy audio driver never consumes playback objects, so starting
	# streams under --headless makes the engine itself retain them until exit.
	# State transitions still run for deterministic tests; real builds play.
	if _playback_available:
		new_player.play()
	_loop_start_count += 1
	_active_player_index = new_index

	_kill_mix_tween()
	var target_db := get_target_volume_db()
	if immediate:
		new_player.volume_db = target_db
		if old_index >= 0:
			_players[old_index].stop()
			_players[old_index].volume_db = SILENT_DB
		return
	_mix_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	_mix_tween.tween_property(new_player, "volume_db", target_db, CROSSFADE_SECONDS)
	if old_index >= 0:
		var old_player := _players[old_index]
		_mix_tween.tween_property(old_player, "volume_db", SILENT_DB, CROSSFADE_SECONDS)
		_mix_tween.chain().tween_callback(old_player.stop)

func _stop_all(immediate: bool) -> void:
	_kill_mix_tween()
	_active_player_index = -1
	# NONE is also the explicit clean-shutdown state, so an in-flight live
	# transition must not outlive the long-running beds.
	if _transformation_player != null:
		_transformation_player.stop()
	if immediate:
		for player in _players:
			player.stop()
			player.volume_db = SILENT_DB
		return
	_mix_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	for player in _players:
		_mix_tween.tween_property(player, "volume_db", SILENT_DB, CROSSFADE_SECONDS)
	_mix_tween.chain().tween_callback(_stop_inactive_players)

func _fade_current_mix(immediate: bool) -> void:
	if _active_player_index < 0:
		return
	_kill_mix_tween()
	if immediate:
		for index in _players.size():
			var player := _players[index]
			player.volume_db = get_target_volume_db() if index == _active_player_index else SILENT_DB
			if index != _active_player_index:
				player.stop()
		return
	# Retarget both sides if dialogue begins during a state crossfade. Killing
	# the old tween without fading its outgoing player would strand that loop
	# at an audible volume indefinitely.
	_mix_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	for index in _players.size():
		var player := _players[index]
		var target_db := get_target_volume_db() if index == _active_player_index else SILENT_DB
		_mix_tween.tween_property(player, "volume_db", target_db, DUCK_SECONDS)
	_mix_tween.chain().tween_callback(_stop_inactive_players)

func _stop_inactive_players() -> void:
	for index in _players.size():
		if index != _active_player_index:
			_players[index].stop()

func _kill_mix_tween() -> void:
	if _mix_tween != null and _mix_tween.is_valid():
		_mix_tween.kill()
	_mix_tween = null

func _on_live_dam_completed() -> void:
	# GameState emits this only for a live final build. Requiring the dry state
	# makes the sting one-shot even if a caller accidentally repeats the signal.
	if _current_state != State.DRY_WILLOWBEND:
		return
	set_state(State.RESTORED_POND)
	if _playback_available:
		_transformation_player.play()
	_transformation_sting_count += 1

func _on_dialogue_started(_dialogue_id: String) -> void:
	set_dialogue_ducked(true)

func _on_dialogue_ended(_dialogue_id: String) -> void:
	set_dialogue_ducked(false)

func _on_story_flag_changed(flag_name: String, value: bool) -> void:
	if flag_name == "act_one_complete" and value:
		set_state(State.CALM_POST_CHAPTER)

## Deterministic procedural beds: a little wind/water noise plus sparse tonal
## color. AudioStreamWAV looping avoids asset or codec differences on Web.
func _make_loop(state: State) -> AudioStreamWAV:
	var frame_count := int(SAMPLE_RATE * LOOP_SECONDS)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	for i in frame_count:
		var t := float(i) / SAMPLE_RATE
		# Integer/half-integer frequencies complete a whole number of cycles in
		# the two-second buffer, keeping the procedural loop seam click-free.
		var noise := sin(TAU * 277.0 * t) * sin(TAU * 157.0 * t) * 0.035
		var sample := 0.0
		match state:
			State.TITLE:
				sample = sin(TAU * 110.0 * t) * 0.025 + sin(TAU * 165.0 * t) * 0.018 + noise
			State.DRY_WILLOWBEND:
				var insects := pow(maxf(0.0, sin(TAU * 5.0 * t)), 12.0) * sin(TAU * 1420.0 * t)
				sample = noise * 0.55 + insects * 0.018 + sin(TAU * 98.0 * t) * 0.012
			State.RESTORED_POND:
				var ripple := sin(TAU * 1.5 * t) * noise * 1.8
				sample = noise + ripple + sin(TAU * 130.5 * t) * 0.025 + sin(TAU * 196.0 * t) * 0.015
			State.CALM_POST_CHAPTER:
				sample = noise * 0.8 + sin(TAU * 130.5 * t) * 0.02 + sin(TAU * 174.5 * t) * 0.012
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count
	stream.data = data
	return stream

func _make_sting() -> AudioStreamWAV:
	var frequencies := [392.0, 523.25, 659.25, 783.99]
	var note_seconds := 0.11
	var frames_per_note := int(SAMPLE_RATE * note_seconds)
	var data := PackedByteArray()
	data.resize(frames_per_note * frequencies.size() * 2)
	for note_index in frequencies.size():
		for i in frames_per_note:
			var t := float(i) / SAMPLE_RATE
			var envelope := 1.0 - float(i) / frames_per_note
			var sample := sin(TAU * frequencies[note_index] * t) * 0.35 * envelope
			data.encode_s16((note_index * frames_per_note + i) * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
