extends Node
class_name PlayerState
## Base class for every player state. States live as children of the PlayerStateMachine and
## receive `enter`/`exit` lifecycle calls plus per-frame `physics_update` and `handle_input`.
## They drive the Player through its public helpers — they do NOT touch physics directly except
## through `player`'s movement helpers, keeping the FEEL logic in one auditable place.

var player: Player
var sm: PlayerStateMachine

## Called once when the state becomes active. `msg` carries optional handoff data between states.
func enter(_msg: Dictionary = {}) -> void:
	pass

## Called once when the state is left.
func exit() -> void:
	pass

## Per-physics-frame update. Delegated to by the state machine.
func physics_update(_delta: float) -> void:
	pass

## Unhandled input, delegated to by the state machine.
func handle_input(_event: InputEvent) -> void:
	pass

## Routed from the player's Hurtbox via the state machine. Default behaviour: just take the hit.
## States that grant i-frames / parry override this.
func on_hurt(hitbox: Hitbox) -> void:
	player.take_hit(hitbox)

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------
## Horizontal input axis in [-1, 1].
func move_axis() -> float:
	return Input.get_axis(&"move_left", &"move_right")

## Convenience: switch states.
func change_state(state_name: String, msg: Dictionary = {}) -> void:
	sm.change_state(state_name, msg)
