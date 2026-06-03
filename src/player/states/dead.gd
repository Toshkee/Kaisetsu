extends PlayerState
## Terminal state. Locks input, dims the sprite into a death pose, notifies GameState (which runs
## the Echoes-on-death loop) and emits the player's `died` signal. Main handles respawn from here.

var _notified: bool = false

func enter(_msg: Dictionary = {}) -> void:
	_notified = false
	player.mark_dead()
	player.disable_attack()
	player.set_invulnerable(false)
	# Stop monitoring incoming hits — already dead.
	player.hurtbox.active = false
	# Death pose: dim the sprite toward ink.
	if player.sprite:
		player.sprite.modulate = Color(0.45, 0.45, 0.5, 1.0)
	# Kill momentum.
	player.velocity = Vector2.ZERO

	# Notify the world ONCE. GameState drops Echoes + records the death scene/position.
	var scene_path := ""
	if player.get_tree().current_scene:
		scene_path = player.get_tree().current_scene.scene_file_path
	GameState.on_player_death(player.global_position, scene_path)
	player.died.emit()
	_notified = true

func physics_update(delta: float) -> void:
	# Settle to the floor; otherwise inert.
	player.apply_gravity(delta)
	player.apply_horizontal(0.0, delta)
	player.move()

func handle_input(_event: InputEvent) -> void:
	pass  # input locked

func on_hurt(_hitbox: Hitbox) -> void:
	pass  # immune once dead
