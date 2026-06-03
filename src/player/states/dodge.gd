extends PlayerState
## The roll. Commits for `dodge_time`; cannot be cancelled except by death. Grants i-frames in a
## window inside the roll (dodge_iframe_start..dodge_iframe_end) during which incoming hits are
## ignored. Costs stamina on entry. Drives a fixed horizontal burst along facing.

var _t: float = 0.0
var _iframes: bool = false

func enter(_msg: Dictionary = {}) -> void:
	_t = 0.0
	_iframes = false
	player.disable_attack()
	# Spend stamina (callers gate on can_spend; double-check to be safe).
	player.stamina.spend(player.dodge_stamina)
	# Aim the roll: along current movement intent if any, else along facing.
	var dir := move_axis()
	if absf(dir) > 0.01:
		player.set_facing_from(dir)
	player.set_horizontal(player.facing * player.dodge_speed)

func exit() -> void:
	player.set_invulnerable(false)
	_iframes = false

func physics_update(delta: float) -> void:
	_t += delta
	# Maintain the burst, gently decaying so it eases out of the roll.
	var roll_progress := clampf(_t / player.dodge_time, 0.0, 1.0)
	var speed := player.dodge_speed * (1.0 - 0.35 * roll_progress)
	player.set_horizontal(player.facing * speed)
	player.apply_gravity(delta)
	player.move()

	# Toggle the i-frame window.
	var want_iframes := _t >= player.dodge_iframe_start and _t <= player.dodge_iframe_end
	if want_iframes != _iframes:
		_iframes = want_iframes
		player.set_invulnerable(_iframes)

	if _t >= player.dodge_time:
		_finish()

func handle_input(event: InputEvent) -> void:
	# Buffer for the action that follows the roll (snappy chaining out of dodge).
	player.buffer_input(event)

## During i-frames the contract says ignore the hit entirely. Outside the window, take it.
func on_hurt(hitbox: Hitbox) -> void:
	if _iframes or player.is_invulnerable():
		return
	# Dodge can't be cancelled except by death, but a connecting hit should still register.
	player.take_hit(hitbox)

func _finish() -> void:
	if not player.is_on_floor():
		change_state("fall")
	elif absf(move_axis()) > 0.01:
		change_state("run")
	else:
		change_state("idle")
