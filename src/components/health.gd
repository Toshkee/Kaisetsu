extends Node
class_name Health
## Reusable health pool. Attach as a child of any damageable body (player, enemy, boss).
## Damage routing goes through a Hurtbox -> owner -> this. Assist multipliers are applied
## by the OWNER (player) before calling take_damage, so Health stays generic.

signal health_changed(current: float, max_health: float)
signal damaged(amount: float, source: Node)
signal healed(amount: float)
signal died

@export var max_health: float = 100.0
@export var invulnerable: bool = false

var current_health: float

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func take_damage(amount: float, source: Node = null) -> void:
	if invulnerable or is_dead() or amount <= 0.0:
		return
	current_health = maxf(current_health - amount, 0.0)
	damaged.emit(amount, source)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		died.emit()

func heal(amount: float) -> void:
	if is_dead() or amount <= 0.0:
		return
	current_health = minf(current_health + amount, max_health)
	healed.emit(amount)
	health_changed.emit(current_health, max_health)

func set_max_health(value: float, refill: bool = false) -> void:
	max_health = maxf(value, 1.0)
	if refill:
		current_health = max_health
	else:
		current_health = minf(current_health, max_health)
	health_changed.emit(current_health, max_health)

func fraction() -> float:
	return current_health / max_health if max_health > 0.0 else 0.0

func is_dead() -> bool:
	return current_health <= 0.0

func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
