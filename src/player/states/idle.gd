extends PlayerState
## Grounded, not moving. Watches for action inputs and the start of movement.

func enter(_msg: Dictionary = {}) -> void:
	player.disable_attack()

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	var dir := move_axis()
	player.apply_horizontal(0.0, delta)  # decelerate to rest
	player.move()

	if _try_action_transitions():
		return

	if not player.is_on_floor():
		change_state("fall")
		return
	if absf(dir) > 0.01:
		change_state("run")

func handle_input(event: InputEvent) -> void:
	player.buffer_input(event)

## Shared: jump/dodge/attack/charge/parry/heal gating. Returns true if a transition happened.
func _try_action_transitions() -> bool:
	if player.consume_buffer("jump") and (player.is_on_floor() or player.has_coyote()):
		change_state("jump")
		return true
	if player.consume_buffer("dodge") and player.can_dodge():
		change_state("dodge")
		return true
	if player.consume_buffer("attack"):
		# `charge` is the hold-detector: a quick release => light attack, a long hold => heavy.
		change_state("charge")
		return true
	if Input.is_action_just_pressed(&"heal") and player.focus.can_spend(1):
		change_state("heal")
		return true
	return false
