extends PlayerState
## Grounded, moving horizontally. Same action gating as idle plus run<->idle handoff.

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	var dir := move_axis()
	player.set_facing_from(dir)
	player.apply_horizontal(dir, delta)
	player.move()

	if _try_action_transitions():
		return

	if not player.is_on_floor():
		change_state("fall")
		return
	if absf(dir) <= 0.01 and absf(player.velocity.x) < 5.0:
		change_state("idle")

func handle_input(event: InputEvent) -> void:
	player.buffer_input(event)

func _try_action_transitions() -> bool:
	if player.consume_buffer("jump") and (player.is_on_floor() or player.has_coyote()):
		change_state("jump")
		return true
	if player.consume_buffer("dodge") and player.stamina.can_spend(player.dodge_stamina):
		change_state("dodge")
		return true
	if player.consume_buffer("parry"):
		change_state("parry")
		return true
	if player.consume_buffer("attack"):
		change_state("charge")
		return true
	if Input.is_action_just_pressed(&"heal") and player.focus.can_spend(1):
		change_state("heal")
		return true
	return false
