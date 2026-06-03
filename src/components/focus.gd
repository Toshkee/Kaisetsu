extends Node
class_name Focus
## The shared Focus/Ether pool (KAISETSU_PLAN Open Decision #3): ONE scarce resource that
## powers BOTH healing AND Curse Arts. Spending a charge on a heal means NOT casting, and
## vice-versa. Measured in discrete charges (like Estus), refilled at shrines.

signal focus_changed(current: float, max_focus: float)
signal focus_empty

@export var max_focus: float = 3.0
@export var heal_cost: float = 1.0

var current: float

func _ready() -> void:
	current = max_focus
	focus_changed.emit(current, max_focus)

func can_spend(amount: float = 1.0) -> bool:
	return current >= amount

func spend(amount: float = 1.0) -> bool:
	if current < amount:
		return false
	current -= amount
	focus_changed.emit(current, max_focus)
	if current <= 0.0:
		focus_empty.emit()
	return true

func restore(amount: float = 1.0) -> void:
	current = minf(current + amount, max_focus)
	focus_changed.emit(current, max_focus)

func refill() -> void:
	current = max_focus
	focus_changed.emit(current, max_focus)

func set_max_focus(value: float, refill_now: bool = true) -> void:
	max_focus = maxf(value, 0.0)
	if refill_now:
		current = max_focus
	else:
		current = minf(current, max_focus)
	focus_changed.emit(current, max_focus)

func fraction() -> float:
	return current / max_focus if max_focus > 0.0 else 0.0
