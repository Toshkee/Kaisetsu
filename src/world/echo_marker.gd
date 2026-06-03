extends Node2D
class_name EchoMarker
## The dropped-Echoes marker (Dark Souls "bloodstain"). Main spawns this at the player's death
## position whenever GameState.has_dropped_echoes. Touching it with the player's interaction
## probe reclaims the Echoes, shimmers, and frees itself.
##
## Collision (see docs/CONVENTIONS.md): Area2D is layer=interactable(8), mask=interactor(9).

signal reclaimed(amount: int)

const COLD_PALE := Color(0.624, 0.690, 0.741, 1.0)   # #9fb0bd pale cold highlight
const LIGHT_ENERGY := 0.5
const PULSE_SPEED := 3.0
const PULSE_AMOUNT := 0.25

@onready var _sprite: CanvasItem = $Sprite
@onready var _light: PointLight2D = $PointLight2D
@onready var _area: Area2D = $Area2D
@onready var _label: Label = $AmountLabel

var _amount: int = 0
var _pulse_time: float = 0.0
var _claimed: bool = false

func _ready() -> void:
	if _label != null:
		_label.visible = false
	_area.area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	_pulse_time += delta * PULSE_SPEED
	var s := 1.0 + sin(_pulse_time) * PULSE_AMOUNT
	_sprite.scale = Vector2(s, s)
	_light.energy = LIGHT_ENERGY + sin(_pulse_time) * (PULSE_AMOUNT * 0.5)

## Optionally label/scale the marker by the Echo amount it holds.
func setup(amount: int) -> void:
	_amount = amount
	if _label != null:
		_label.text = str(amount)
		_label.visible = amount > 0
	# Bigger hoards glow a touch larger (clamped so it never dominates).
	var bonus := clampf(float(amount) / 200.0, 0.0, 0.6)
	scale = Vector2.ONE * (1.0 + bonus)

func _on_area_entered(area: Area2D) -> void:
	if _claimed:
		return
	if not _is_player_interactor(area):
		return
	_claimed = true
	var amount: int = GameState.reclaim_dropped_echoes()
	reclaimed.emit(amount)
	_shimmer_and_free()

func _is_player_interactor(area: Area2D) -> bool:
	var node: Node = area
	while node != null:
		if node.is_in_group("player"):
			return true
		node = node.get_parent()
	return false

func _shimmer_and_free() -> void:
	# Disable further pickups while the shimmer plays out.
	set_process(false)
	_area.set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2(2.0, 2.0), 0.25)
	tween.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(_light, "energy", 0.0, 0.25)
	tween.tween_callback(queue_free)
