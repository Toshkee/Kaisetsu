extends Area2D
class_name Hurtbox
## A damage-receiving volume. It MONITORS for Hitboxes and forwards them to its owner via the
## `hurt` signal — the owner decides what happens (take damage, parry, i-frame ignore). This
## keeps fairness logic (i-frames, parry window) in one place: the owner's state machine.
##
## Collision setup (see docs/CONVENTIONS.md):
##   Player hurtbox -> layer = player_hurtbox(4), mask = enemy_hitbox(7)
##   Enemy hurtbox  -> layer = enemy_hurtbox(5),  mask = player_hitbox(6)

signal hurt(hitbox: Hitbox)

## When false, incoming hits are ignored entirely (e.g. during dodge i-frames the owner can
## flip this off, or leave it on and decide in the `hurt` handler — both supported).
@export var active: bool = true

# Guards against the same hitbox registering twice in one physics frame.
var _hit_this_frame: Array[Hitbox] = []

func _ready() -> void:
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)

func _physics_process(_delta: float) -> void:
	if not _hit_this_frame.is_empty():
		_hit_this_frame.clear()

func _on_area_entered(area: Area2D) -> void:
	if not active:
		return
	if area is Hitbox:
		var hb: Hitbox = area
		if hb in _hit_this_frame:
			return
		_hit_this_frame.append(hb)
		hurt.emit(hb)
