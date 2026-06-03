extends PlayerState
## The dash — KAISETSU's Isadora-style dodge. A free, snappy horizontal burst that grants
## invincibility for its ENTIRE duration (no inner window). Commits for `dodge_time`, then hands
## back to a neutral state. Gated only by a brief cooldown (`dodge_cooldown`), NOT stamina — the
## dash IS the dodge, so movement stays free-flowing.

var _t: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	_t = 0.0
	player.disable_attack()
	# I-frames for the WHOLE dash.
	player.set_invulnerable(true)
	player.start_dodge_cooldown()
	# Aim along movement intent if any, else along current facing.
	var dir := move_axis()
	if absf(dir) > 0.01:
		player.set_facing_from(dir)
	# Flat, gravity-free burst — reads as a deliberate dash and lets you cross gaps.
	player.velocity.y = 0.0
	player.set_horizontal(player.facing * player.dodge_speed)

func exit() -> void:
	player.set_invulnerable(false)

func physics_update(delta: float) -> void:
	_t += delta
	# Hold the burst flat; a gentle decay eases out without killing the snap.
	var progress := clampf(_t / player.dodge_time, 0.0, 1.0)
	var speed := player.dodge_speed * (1.0 - 0.2 * progress)
	player.set_horizontal(player.facing * speed)
	player.velocity.y = 0.0
	player.move()

	if _t >= player.dodge_time:
		_finish()

func handle_input(event: InputEvent) -> void:
	# Buffer the action that follows the dash (snappy chaining out of it).
	player.buffer_input(event)

## I-frames span the whole dash, so incoming hits are ignored. (Kept defensive.)
func on_hurt(hitbox: Hitbox) -> void:
	if player.is_invulnerable():
		return
	player.take_hit(hitbox)

func _finish() -> void:
	if not player.is_on_floor():
		change_state("fall")
	elif absf(move_axis()) > 0.01:
		change_state("run")
	else:
		change_state("idle")
