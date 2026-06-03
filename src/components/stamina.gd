extends Node
class_name Stamina
## Stamina pool governing dodge / attack / charge (KAISETSU's deliberate-combat addition,
## see KAISETSU_PLAN A1). Regenerates after a short delay following any spend.
## Respects Settings.assist_stamina_regen_mult.

signal stamina_changed(current: float, max_stamina: float)
signal stamina_empty

@export var max_stamina: float = 100.0
@export var regen_rate: float = 50.0      # points per second
@export var regen_delay: float = 0.45     # seconds to wait after a spend before regen

var current: float
var _delay_timer: float = 0.0

func _ready() -> void:
	current = max_stamina
	stamina_changed.emit(current, max_stamina)

func _process(delta: float) -> void:
	if _delay_timer > 0.0:
		_delay_timer = maxf(_delay_timer - delta, 0.0)
		return
	if current < max_stamina:
		var mult: float = Settings.assist_stamina_regen_mult if Settings else 1.0
		current = minf(current + regen_rate * mult * delta, max_stamina)
		stamina_changed.emit(current, max_stamina)

func can_spend(amount: float) -> bool:
	return current >= amount

func spend(amount: float) -> bool:
	if current < amount:
		return false
	current -= amount
	_delay_timer = regen_delay
	stamina_changed.emit(current, max_stamina)
	if current <= 0.0:
		stamina_empty.emit()
	return true

func restore(amount: float) -> void:
	current = minf(current + amount, max_stamina)
	stamina_changed.emit(current, max_stamina)

func refill() -> void:
	current = max_stamina
	stamina_changed.emit(current, max_stamina)

func fraction() -> float:
	return current / max_stamina if max_stamina > 0.0 else 0.0
