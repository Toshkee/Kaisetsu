extends PlayerState
## Hitstun. Brief loss of control after taking a hit; the knockback velocity (set by take_hit)
## carries through and decays. Recovers to idle/run/fall. Cannot act during stun, but a second hit
## still lands (re-enters stagger, refreshing the timer) — no stun-lock immunity here by design.

@export var stagger_time: float = 0.3

var _t: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	_t = 0.0
	player.disable_attack()
	# Cancels any channel (heal) implicitly by being a different state.

func physics_update(delta: float) -> void:
	_t += delta
	player.apply_gravity(delta)
	# Let knockback decay; no player-driven horizontal input during stun.
	player.apply_horizontal(0.0, delta)
	player.move()

	if _t >= stagger_time:
		_finish()

func handle_input(event: InputEvent) -> void:
	# Buffer so an action queued during stun fires the moment control returns.
	player.buffer_input(event)

## Another hit during stagger re-triggers it (refreshes the timer) — soulslike punish.
func on_hurt(hitbox: Hitbox) -> void:
	player.take_hit(hitbox)

func _finish() -> void:
	if not player.is_on_floor():
		change_state("fall")
	elif absf(move_axis()) > 0.01:
		change_state("run")
	else:
		change_state("idle")
