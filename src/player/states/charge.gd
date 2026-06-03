extends PlayerState
## The hold-detector AND the heavy swing.
##
## Entered when `attack` is pressed. While the button is held we wind up; the moment held time
## crosses `charge_time` the swing becomes a HEAVY. If the player releases BEFORE that threshold,
## we hand off to the light `attack` state (a quick tap). Once a heavy commits, it is movement-
## locked and cannot be cancelled (soulslike commitment).

enum Phase { WINDUP, SWING, RECOVERY }

var _phase: int = Phase.WINDUP
var _t: float = 0.0
var _hit_done: bool = false

# Heavy timing (windup is the charge hold itself; these gate the swing/recovery once released).
const SWING_ACTIVE_START: float = 0.08
const SWING_ACTIVE_END: float = 0.22
const SWING_TOTAL: float = 0.30
const RECOVERY_TIME: float = 0.20

func enter(_msg: Dictionary = {}) -> void:
	_phase = Phase.WINDUP
	_t = 0.0
	_hit_done = false
	player.disable_attack()
	# Face the way the player is aiming when the swing starts.
	player.set_facing_from(move_axis())

func exit() -> void:
	player.disable_attack()

func physics_update(delta: float) -> void:
	_t += delta
	# Windup is movement-soft (can still drift / turn) until the swing commits.
	match _phase:
		Phase.WINDUP:
			_update_windup(delta)
		Phase.SWING:
			_update_swing(delta)
		Phase.RECOVERY:
			_update_recovery(delta)

func _update_windup(delta: float) -> void:
	# Light, draggy movement during windup; lets you still position before a heavy.
	player.apply_gravity(delta)
	player.apply_horizontal(move_axis() * 0.4, delta)
	player.set_facing_from(move_axis())
	player.move()

	# Released early -> light attack (the "tap").
	if not Input.is_action_pressed(&"attack") and _t < player.charge_time:
		change_state("attack")
		return

	# Held past the threshold -> commit the heavy.
	if _t >= player.charge_time:
		_phase = Phase.SWING
		_t = 0.0
		# Forward nudge into the heavy.
		player.set_horizontal(player.facing * 70.0)

func _update_swing(delta: float) -> void:
	# Movement-locked during the heavy swing (commitment).
	player.apply_gravity(delta)
	player.apply_horizontal(0.0, delta)
	player.move()

	var active := _t >= SWING_ACTIVE_START and _t <= SWING_ACTIVE_END
	if active and not player.attack_hitbox.active:
		player.enable_attack(player.charge_damage, 320.0, false)
		if not _hit_done:
			player.apply_hitstop(0.04)
			player.shake_camera(5.0, 0.18)
			_hit_done = true
	elif not active and player.attack_hitbox.active:
		player.disable_attack()

	if _t >= SWING_TOTAL:
		player.disable_attack()
		_phase = Phase.RECOVERY
		_t = 0.0

func _update_recovery(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_horizontal(0.0, delta)
	player.move()
	if _t >= RECOVERY_TIME:
		_to_neutral()

func handle_input(event: InputEvent) -> void:
	# Only buffer once committed to the heavy, so the next action chains after recovery.
	if _phase != Phase.WINDUP:
		player.buffer_input(event)

func _to_neutral() -> void:
	if not player.is_on_floor():
		change_state("fall")
	elif absf(move_axis()) > 0.01:
		change_state("run")
	else:
		change_state("idle")
