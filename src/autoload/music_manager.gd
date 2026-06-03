extends Node
## Autoload: MusicManager
## Zone-scoped music + distinct boss / shrine tracks, cross-faded (~1.5s). A separate Ambience
## player carries the loneliness (KAISETSU_PLAN A4). Fully NULL-SAFE: with no audio packs yet,
## every call is a no-op that just remembers intent, so the game runs silent without errors.

const CROSSFADE_TIME := 1.5

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_is_a := true
var _ambience: AudioStreamPlayer
var _tween: Tween

var current_track_path := ""
var current_ambience_path := ""

func _ready() -> void:
	_music_a = _make_player("Music")
	_music_b = _make_player("Music")
	_ambience = _make_player("Ambience")

func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	p.process_mode = Node.PROCESS_MODE_ALWAYS  # keep playing while paused (shrine menus etc.)
	add_child(p)
	return p

# ---------------------------------------------------------------------------
# Public API — pass a res:// path to an AudioStream, or "" to fade to silence.
# ---------------------------------------------------------------------------
func play_zone(track_path: String) -> void:
	_crossfade_to(track_path)

func play_boss(track_path: String) -> void:
	_crossfade_to(track_path)

func play_shrine(track_path: String) -> void:
	_crossfade_to(track_path)

func stop() -> void:
	_crossfade_to("")

func set_ambience(ambience_path: String) -> void:
	if ambience_path == current_ambience_path:
		return
	current_ambience_path = ambience_path
	var stream := _load_stream(ambience_path)
	_ambience.stream = stream
	if stream != null:
		_ambience.play()
	else:
		_ambience.stop()

# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------
func _crossfade_to(track_path: String) -> void:
	if track_path == current_track_path:
		return
	current_track_path = track_path
	var stream := _load_stream(track_path)

	var incoming := _music_b if _active_is_a else _music_a
	var outgoing := _music_a if _active_is_a else _music_b
	_active_is_a = not _active_is_a

	if _tween != null and _tween.is_valid():
		_tween.kill()

	incoming.stream = stream
	if stream != null:
		incoming.volume_db = -80.0
		incoming.play()

	_tween = create_tween().set_parallel(true)
	if stream != null:
		_tween.tween_property(incoming, "volume_db", 0.0, CROSSFADE_TIME)
	_tween.tween_property(outgoing, "volume_db", -80.0, CROSSFADE_TIME)
	_tween.chain().tween_callback(outgoing.stop)

func _load_stream(path: String) -> AudioStream:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var res := load(path)
	return res as AudioStream
