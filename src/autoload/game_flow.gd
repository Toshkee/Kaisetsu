extends Node
## Autoload: GameFlow
## The scene/game-flow manager. Owns the high-level transitions between the title screen and
## the gameplay root, and resets/loads run state on the way in. The title screen and the
## integrator call into this; it is the single place that calls `change_scene_to_file`.
##
## Every swap is masked by a reusable fade-to-black overlay (src/ui/Transition.tscn): fade out,
## change scene, fade back in. A persistent Transition instance is parented under this autoload
## so it survives scene changes. A `_busy` guard serializes transitions so a double-click or a
## rapid menu input can't race two scene changes.
##
## Self-contained and null-safe — it never reaches into the scenes it loads.

const TITLE_SCENE := "res://src/ui/TitleScreen.tscn"
const GAMEPLAY_SCENE := "res://src/scenes/Main.tscn"
const TRANSITION_SCENE: PackedScene = preload("res://src/ui/Transition.tscn")

const FADE_TIME := 0.4

var _transition: Transition
var _busy: bool = false


func _ready() -> void:
	# Keep flowing even while the tree is paused (transitions can fire from a pause menu).
	process_mode = Node.PROCESS_MODE_ALWAYS


# ---------------------------------------------------------------------------
# Public flow API (called by the title screen + integrator)
# ---------------------------------------------------------------------------

## Begin a fresh run: wipe run-scoped GameState, then fade into the gameplay root. Main reads
## a cleared GameState (no respawn anchor / no dropped Echoes), so it spawns at the room's
## default spawn point.
func start_new_game() -> void:
	_reset_run_state()
	await _change_scene_faded(GAMEPLAY_SCENE)


## Continue from disk if a save exists; otherwise start fresh. On a successful load Main reads
## GameState.respawn_* to place the player at the last lit shrine.
func continue_game() -> void:
	if SaveManager != null and SaveManager.has_save():
		SaveManager.load_game()
		await _change_scene_faded(GAMEPLAY_SCENE)
	else:
		await start_new_game()


## Return to the title screen (e.g. "Quit to Title" from the pause menu).
func goto_title() -> void:
	await _change_scene_faded(TITLE_SCENE)


# ---------------------------------------------------------------------------
# Run-state reset
# ---------------------------------------------------------------------------
func _reset_run_state() -> void:
	if GameState == null:
		return
	GameState.flags.clear()
	GameState.echoes = 0
	GameState.times_died = 0
	GameState.has_respawn = false
	GameState.has_dropped_echoes = false
	# Clear the matching payloads so stale data can't leak into the new run.
	GameState.dropped_echoes = 0
	GameState.dropped_echo_position = Vector2.ZERO
	GameState.respawn_position = Vector2.ZERO
	GameState.respawn_scene = ""
	GameState.lit_shrines.clear()
	GameState.echoes_changed.emit(0)


# ---------------------------------------------------------------------------
# Faded scene change
# ---------------------------------------------------------------------------
## Fade to black, swap to `path`, fade back in. Guarded by `_busy` so overlapping calls are
## dropped rather than racing two scene changes.
func _change_scene_faded(path: String) -> void:
	if _busy:
		return
	_busy = true

	var fade := _ensure_transition()
	if fade != null:
		await fade.fade_out(FADE_TIME)

	var tree := get_tree()
	if tree != null:
		var err := tree.change_scene_to_file(path)
		if err != OK:
			push_warning("GameFlow: change_scene_to_file failed for '%s' (err %d)." % [path, err])
		# Let the new scene finish entering the tree before we lift the curtain.
		await tree.process_frame

	if fade != null:
		await fade.fade_in(FADE_TIME)

	_busy = false


## Lazily build (and re-build, if it was ever freed) the persistent fade overlay, parenting it
## under this autoload so it outlives scene swaps and sits above gameplay/menus.
func _ensure_transition() -> Transition:
	if _transition != null and is_instance_valid(_transition):
		return _transition
	_transition = TRANSITION_SCENE.instantiate() as Transition
	if _transition != null:
		add_child(_transition)
	return _transition
