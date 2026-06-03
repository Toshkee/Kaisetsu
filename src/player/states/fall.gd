extends PlayerState
## Falling portion of an airborne arc (or walking off a ledge). Honours coyote-time jumps and the
## jump buffer so a press just before landing still fires.

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	var dir := move_axis()
	player.set_facing_from(dir)
	player.apply_horizontal(dir, delta)
	player.move()

	# Jump while airborne: a coyote-time jump (free) if just off a ledge, else a double jump.
	if player.peek_buffer("jump"):
		if player.has_coyote():
			player.consume_buffer("jump")
			change_state("jump")
			return
		elif player.try_air_jump():
			player.consume_buffer("jump")
			change_state("jump", {"air": true})
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
	if player.consume_buffer("dodge") and player.can_dodge():
		change_state("dodge")
		return true
	if player.consume_buffer("attack"):
		change_state("charge")
		return true
	return false
