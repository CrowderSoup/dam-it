extends Node
## Tiny procedurally-generated sound effects — no audio assets needed.
## Autoloaded as "Sfx".

const SAMPLE_RATE := 22050

var _chop_player: AudioStreamPlayer
var _mine_player: AudioStreamPlayer
var _build_player: AudioStreamPlayer
var _complete_player: AudioStreamPlayer
var _footstep_player: AudioStreamPlayer
var _storm_player: AudioStreamPlayer
var _shoo_player: AudioStreamPlayer
var _steal_player: AudioStreamPlayer
var _eat_player: AudioStreamPlayer
var _rest_player: AudioStreamPlayer

func _ready() -> void:
	_chop_player = _make_player(_make_tone(220.0, 0.08, 0.5))
	_mine_player = _make_player(_make_tone(160.0, 0.05, 0.55))
	_build_player = _make_player(_make_tone(120.0, 0.18, 0.6))
	_complete_player = _make_player(_make_arpeggio([440.0, 554.0, 659.0, 880.0], 0.12))
	_footstep_player = _make_player(_make_tone(90.0, 0.04, 0.2))
	_storm_player = _make_player(_make_tone(70.0, 0.35, 0.45))
	_shoo_player = _make_player(_make_tone(320.0, 0.06, 0.4))
	_steal_player = _make_player(_make_arpeggio([320.0, 220.0], 0.08))
	_eat_player = _make_player(_make_arpeggio([180.0, 220.0], 0.05))
	_rest_player = _make_player(_make_arpeggio([392.0, 494.0, 587.0], 0.1))
	GameState.dam_completed.connect(play_complete)

func play_chop() -> void:
	_chop_player.play()

func play_mine() -> void:
	_mine_player.play()

func play_build() -> void:
	_build_player.play()

func play_complete() -> void:
	_complete_player.play()

func play_footstep() -> void:
	_footstep_player.play()

func play_storm() -> void:
	_storm_player.play()

func play_shoo() -> void:
	_shoo_player.play()

func play_steal() -> void:
	_steal_player.play()

func play_eat() -> void:
	_eat_player.play()

func play_rest() -> void:
	_rest_player.play()

func _make_player(stream: AudioStreamWAV) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	add_child(player)
	return player

## A single decaying sine tone.
func _make_tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var frame_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	for i in frame_count:
		var t := float(i) / SAMPLE_RATE
		var envelope := 1.0 - (float(i) / frame_count)
		var sample := sin(TAU * freq * t) * volume * envelope
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _wrap(data)

## A short sequence of decaying sine tones played back to back.
func _make_arpeggio(freqs: Array, note_duration: float) -> AudioStreamWAV:
	var frames_per_note := int(SAMPLE_RATE * note_duration)
	var data := PackedByteArray()
	data.resize(frames_per_note * freqs.size() * 2)
	for n in freqs.size():
		var freq: float = freqs[n]
		for i in frames_per_note:
			var t := float(i) / SAMPLE_RATE
			var envelope := 1.0 - (float(i) / frames_per_note)
			var sample := sin(TAU * freq * t) * 0.5 * envelope
			var idx := (n * frames_per_note + i) * 2
			data.encode_s16(idx, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _wrap(data)

func _wrap(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
