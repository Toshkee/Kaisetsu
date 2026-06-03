extends PlayerState
## Light attack. Commits for `light_attack_time` (no cancel). The AttackHitbox is active only
## during the active-frame window. A small forward nudge sells the lunge. Costs stamina on entry.

var _t: float = 0.0
var _hit_done: bool = false

func enter(_msg: Dictionary = {}) -> void:
	_t = 0.0
	_hit_done = false
	player.set_facing_from(move_axis())
	# Small forward nudge.
	player.set_horizontal(player.facing * 90.0)
	player.disable_attack()

func exit() -> void:
	player.disable_attack()

func physics_update(delta: float) -> void:
	_t += delta
	player.apply_gravity(delta)
	# Movement-locked horizontally beyond the entry nudge (decelerate to a stop).
	player.apply_horizontal(0.0, delta)
	player.move()

	var active := _t >= player.light_attack_active_start and _t <= player.light_attack_active_end
	if active and not player.attack_hitbox.active:
		player.enable_attack(player.light_attack_damage, 220.0, false)
		if not _hit_done:
			player.apply_hitstop(0.025)
			_hit_done = true
	elif not active and player.attack_hitbox.active:
		player.disable_attack()

	if _t >= player.light_attack_time:
		player.disable_attack()
		_finish()

func handle_input(event: InputEvent) -> void:
	# Buffer the next action so it fires the instant the commit ends (combo feel).
	player.buffer_input(event)

func _finish() -> void:
	if not player.is_on_floor():
		change_state("fall")
	elif absf(move_axis()) > 0.01:
		change_state("run")
	else:
		change_state("idle")
