extends Node2D
## Standalone sandbox for trying the imported asset packs. There is no GameFlow/Main here, so this
## script just wires the one thing the integrator normally owns: it reloads the room a moment after
## Sōji dies, so death doesn't soft-lock. The Player is instanced directly and brings its own camera.

@export var respawn_delay: float = 1.4

func _ready() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p and p.has_signal("died"):
		p.died.connect(_on_player_died)

func _on_player_died() -> void:
	await get_tree().create_timer(respawn_delay).timeout
	get_tree().reload_current_scene()
