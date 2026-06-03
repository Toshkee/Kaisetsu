extends PlayerState
## The parry. A short active window (`parry_window`); if a PARRYABLE hit lands during it, the
## parry succeeds: bright flash, hitstop, stamina refund, and a riposte that damages the source.
## If the window elapses with no hit, a short recovery plays. Hits arriving AFTER the window (in
## recovery) hurt normally.

var _t: float = 0.0
var _active: bool = false
var _recovering: bool = false

func enter(_msg: Dictionary = {}) -> void:
	_t = 0.0
	_active = true
	_recovering = false
	player.disable_attack()
	player.set_facing_from(move_axis())
	# Plant: kill horizontal drift so the parry reads as a deliberate stand.
	player.set_horizontal(player.velocity.x * 0.3)

func physics_update(delta: float) -> void:
	_t += delta
	player.apply_gravity(delta)
	player.apply_horizontal(0.0, delta)
	player.move()

	if _active and _t >= player.parry_window:
		_active = false
		_recovering = true
		_t = 0.0
	elif _recovering and _t >= player.parry_recovery:
		_finish()

func handle_input(event: InputEvent) -> void:
	if _recovering:
		player.buffer_input(event)

func on_hurt(hitbox: Hitbox) -> void:
	if _active and hitbox.parryable:
		_succeed(hitbox)
	elif _active and not hitbox.parryable:
		# Unparryable attack during the window still hurts (e.g. grabs) — fairness/readability.
		player.take_hit(hitbox)
	else:
		# Outside the window (recovery): normal damage.
		player.take_hit(hitbox)

func _succeed(hitbox: Hitbox) -> void:
	# Juice.
	player.flash_bright()
	player.apply_hitstop(0.12)
	player.shake_camera(4.0, 0.15)
	# Refund stamina for a successful read.
	player.stamina.restore(player.parry_stamina_refund)
	# Riposte: deal heavy damage to the attacker if it has a Health child.
	var source := _resolve_source(hitbox)
	_riposte(source)
	_active = false
	_finish()

## Find the attacking body from a hitbox.
func _resolve_source(hitbox: Hitbox) -> Node:
	if hitbox.owner:
		return hitbox.owner
	return hitbox.get_parent()

func _riposte(source: Node) -> void:
	if source == null:
		return
	var hp := _find_health(source)
	if hp:
		hp.take_damage(player.parry_riposte_damage, player)

## Look for a Health child on the source (or the source itself).
func _find_health(node: Node) -> Health:
	if node is Health:
		return node
	for child in node.get_children():
		if child is Health:
			return child
	# Try a method-based accessor some bodies may expose.
	if node.has_method("get") and node.get("health") is Health:
		return node.get("health")
	return null

func _finish() -> void:
	if not player.is_on_floor():
		change_state("fall")
	elif absf(move_axis()) > 0.01:
		change_state("run")
	else:
		change_state("idle")
