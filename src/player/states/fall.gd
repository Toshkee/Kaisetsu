extends PlayerState
## Falling portion of an airborne arc (or walking off a ledge). Honours coyote-time jumps and the
## jump buffer so a press just before landing still fires.

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	var dir := move_axis()
	player.set_facing_from(dir)
	player.apply_horizontal(dir, delta)
	player.move()

	# Coyote jump: pressed jump while briefly off a ledge.
	if player.consume_buffer("jump") and player.has_coyote():
		change_state("jump")
		return
	if _try_air_actions():
		return

	if player.is_on_floor():
		# Buffered jump landed: fire immediately for snappy hops.
		if player.consume_buffer("jump"):
			change_state("jump")
			return
		if absf(move_axis()) > 0.01:
			change_state("run")
		else:
			change_state("idle")

func handle_input(event: InputEvent) -> void:
	player.buffer_input(event)

func _try_air_actions() -> bool:
	if player.consume_buffer("dodge") and player.stamina.can_spend(player.dodge_stamina):
		change_state("dodge")
		return true
	if player.consume_buffer("attack"):
		change_state("charge")
		return true
	return false
