extends PlayerState
## Channelled heal via the Sage's prayer beads. Long (`heal_time`), movement-locked, NO i-frames,
## and INTERRUPTIBLE: taking a hit cancels it. Focus is spent at the heal tick (commit point) and
## health is applied then. If interrupted BEFORE the tick, no Focus is consumed (you keep the charge).

var _t: float = 0.0
var _committed: bool = false  # true once Focus was spent + health applied

func enter(_msg: Dictionary = {}) -> void:
	_t = 0.0
	_committed = false
	player.disable_attack()
	# Plant in place.
	player.set_horizontal(0.0)

func physics_update(delta: float) -> void:
	_t += delta
	player.apply_gravity(delta)
	# Movement-locked: decelerate any residual horizontal velocity.
	player.apply_horizontal(0.0, delta)
	player.move()

	# The heal tick: spend Focus, apply healing. Guard in case Focus emptied since entry.
	if not _committed and _t >= player.heal_tick:
		if player.focus.spend(1):
			player.health.heal(player.heal_amount)
			_committed = true
		else:
			# No Focus left — abort cleanly, no consume.
			_finish()
			return

	if _t >= player.heal_time:
		_finish()

func handle_input(event: InputEvent) -> void:
	# Buffer the next action so it fires when the channel completes.
	player.buffer_input(event)

## Heal is interruptible: any incoming hit cancels it (no i-frames). If it hadn't committed yet,
## the Focus charge is preserved (it was never spent).
func on_hurt(hitbox: Hitbox) -> void:
	# Let the normal hit pipeline run; it routes us to 'staggered', which ends the heal.
	player.take_hit(hitbox)

func _finish() -> void:
	if not player.is_on_floor():
		change_state("fall")
	elif absf(move_axis()) > 0.01:
		change_state("run")
	else:
		change_state("idle")
