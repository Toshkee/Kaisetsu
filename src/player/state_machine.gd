extends Node
class_name PlayerStateMachine
## Owns the player's states (its child PlayerState nodes), keyed by lowercase node name.
## Delegates physics + input to the current state and enforces the two hard-cancels from the
## contract: death forces 'dead', and pause freezes everything.

@export var initial_state: String = "idle"

var player: Player
var current_state: PlayerState
var _states: Dictionary = {}

func _ready() -> void:
	# `player` is wired by Player._ready() before this runs its first frame; but guard anyway.
	for child in get_children():
		if child is PlayerState:
			var s: PlayerState = child
			_states[child.name.to_lower()] = s
			s.player = player
			s.sm = self

## Called by Player after it has set `player` on us, so states can rely on a valid owner.
func setup(owner_player: Player) -> void:
	player = owner_player
	for key in _states:
		_states[key].player = owner_player
		_states[key].sm = self

func start() -> void:
	if _states.is_empty():
		return
	current_state = _states.get(initial_state.to_lower(), null)
	if current_state == null:
		# Fall back to the first registered state.
		current_state = _states.values()[0]
	current_state.enter()
	if player:
		player.play_state_anim(current_state.name)

func has_state(state_name: String) -> bool:
	return _states.has(state_name.to_lower())

func change_state(state_name: String, msg: Dictionary = {}) -> void:
	var key := state_name.to_lower()
	if not _states.has(key):
		push_warning("PlayerStateMachine: unknown state '%s'" % state_name)
		return
	var next: PlayerState = _states[key]
	if current_state:
		current_state.exit()
	current_state = next
	current_state.enter(msg)
	if player:
		player.play_state_anim(current_state.name)

func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	if current_state == null:
		return
	# Death hard-cancel: nothing overrides dying.
	if player.is_dead() and current_state.name.to_lower() != "dead":
		change_state("dead")
		return
	current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if current_state == null:
		return
	if player.is_dead():
		return
	current_state.handle_input(event)
