extends Area2D
class_name Hitbox
## A damage-dealing volume. Carries the data for one hit; it is DETECTED by Hurtboxes
## (it does not detect anything itself). Toggle `active` on/off per attack frame window.
##
## Collision setup (see docs/CONVENTIONS.md):
##   Player attack hitbox -> layer = player_hitbox(6),  mask = 0
##   Enemy attack hitbox  -> layer = enemy_hitbox(7),   mask = 0
## Hurtboxes do the monitoring.

@export var damage: float = 10.0
@export var knockback: float = 220.0
@export var parryable: bool = true
@export var attack_id: StringName = &""
## When false the volume is disabled (no collision shapes report).
@export var active: bool = false: set = set_active

func _ready() -> void:
	monitorable = true
	monitoring = false
	set_active(active)

func set_active(value: bool) -> void:
	active = value
	# Defer so it's safe to toggle from physics callbacks.
	if not is_inside_tree():
		return
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", not value)
	set_deferred("monitorable", value)

## Direction from this hitbox's owner toward a target, for knockback.
func knockback_dir_to(target_global_pos: Vector2) -> Vector2:
	return (target_global_pos - global_position).normalized()
