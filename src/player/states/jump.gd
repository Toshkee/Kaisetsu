extends PlayerState
## Rising portion of an airborne arc. Allows air control, dodge, and air attacks; variable jump
## height via releasing `jump` early (short-hop). Transitions to fall when velocity turns downward.

func enter(msg: Dictionary = {}) -> void:
	# An air (double) jump has already launched via try_air_jump(); a ground jump launches here.
	if not msg.get("air", false):
		player.do_jump()

func physics_update(delta: float) -> void:
	# Variable jump height: cut the rise short if the player releases jump.
	if player.velocity.y < 0.0 and not Input.is_action_pressed(&"jump"):
		player.velocity.y *= 0.5

	player.apply_gravity(delta)
	var dir := move_axis()
	player.set_facing_from(dir)
	player.apply_horizontal(dir, delta)
	player.move()

	# Double jump: a fresh press mid-rise spends an air-jump charge and re-launches.
	if player.peek_buffer("jump") and player.try_air_jump():
		player.consume_buffer("jump")
		change_state("jump", {"air": true})
		return

	if _try_air_actions():
		return

	if player.velocity.y >= 0.0:
		change_state("fall")
		return
	if player.is_on_floor():
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
