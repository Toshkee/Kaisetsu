extends CharacterBody2D
class_name Enemy
## Base class for all KAISETSU enemies. Owns the shared combat seam: it connects its
## Hurtbox's `hurt` signal, applies damage through the Health component, does knockback +
## a readable hit-flash, and on death awards Echoes to the run economy then frees itself.
##
## Collision contract (docs/CONVENTIONS.md):
##   body         -> layer = enemy(4),         mask = world(1)+one_way(512) = 513
##   Hurtbox      -> layer = enemy_hurtbox(16), mask = player_hitbox(32)
##   AttackHitbox -> layer = enemy_hitbox(64),  mask = 0, active=false until attack frames
##
## Subclasses override `_think(delta)` for their AI. The base keeps damage/death generic.

signal died

const DANGER_RED := Color(0.761, 0.353, 0.306, 1.0)   # #c25a4e enemy-tell / hit tint
const HIT_FLASH := Color(1.0, 1.0, 1.0, 1.0)           # bright pop on contact

@export var gravity: float = 980.0
@export var reward_echoes: int = 5
@export var knockback_resist: float = 1.0   # 1.0 = full knockback, 0 = immovable

# Set by subclasses / scenes; the base only stores the resting color so flashes restore it.
var facing: int = 1
var _is_dead: bool = false
var _base_color: Color = Color(1, 1, 1, 1)
var _flash_timer: float = 0.0
var _knockback: Vector2 = Vector2.ZERO

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var attack_hitbox: Hitbox = $AttackHitbox
@onready var sprite: ColorRect = $Sprite

func _ready() -> void:
	add_to_group("enemy")
	if sprite:
		_base_color = sprite.color
	if hurtbox:
		hurtbox.hurt.connect(_on_hurt)
	if health:
		health.died.connect(die)
	if attack_hitbox:
		attack_hitbox.active = false
	_on_enemy_ready()

## Subclass hook: run after the base wiring is done (replaces overriding _ready directly).
func _on_enemy_ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if _is_dead:
		# Let a dead body settle to the ground; no AI.
		velocity.y += gravity * delta
		move_and_slide()
		return

	_tick_flash(delta)

	# Gravity is always applied; horizontal motion is the subclass's job via _think.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Decaying knockback impulse layered on top of AI-driven velocity.
	if _knockback != Vector2.ZERO:
		velocity.x = _knockback.x
		_knockback = _knockback.move_toward(Vector2.ZERO, 900.0 * delta)

	_think(delta)
	move_and_slide()

## Virtual: subclasses implement their FSM here. Base does nothing (a stationary dummy).
func _think(_delta: float) -> void:
	pass

# ---------------------------------------------------------------------------
# Damage in
# ---------------------------------------------------------------------------
func _on_hurt(hitbox: Hitbox) -> void:
	if _is_dead or hitbox == null:
		return
	var source: Node = _hit_source(hitbox)
	# Damage dealt TO an enemy by the player respects the assist multiplier.
	var mult: float = Settings.assist_damage_dealt_mult if Settings else 1.0
	if health:
		health.take_damage(hitbox.damage * mult, source)
	_apply_knockback(hitbox)
	_start_flash()

## Resolve the attacking node from a Hitbox (its owner, else its parent chain).
func _hit_source(hitbox: Hitbox) -> Node:
	if hitbox.owner != null:
		return hitbox.owner
	return hitbox.get_parent()

func _apply_knockback(hitbox: Hitbox) -> void:
	if knockback_resist <= 0.0 or hitbox.knockback <= 0.0:
		return
	var dir: Vector2 = hitbox.knockback_dir_to(global_position)
	if dir == Vector2.ZERO:
		dir = Vector2(float(-facing), 0.0)
	_knockback = Vector2(dir.x, 0.0).normalized() * hitbox.knockback * knockback_resist

# ---------------------------------------------------------------------------
# Hit-flash (readable feedback): pop toward white/danger-red, then ease back.
# ---------------------------------------------------------------------------
func _start_flash() -> void:
	_flash_timer = 0.14
	if sprite:
		sprite.color = HIT_FLASH

func _tick_flash(delta: float) -> void:
	if _flash_timer <= 0.0:
		return
	_flash_timer = maxf(_flash_timer - delta, 0.0)
	if not sprite:
		return
	# Ease from the bright pop, through danger-red, back to the resting color.
	var t: float = 1.0 - (_flash_timer / 0.14)
	if t < 0.5:
		sprite.color = HIT_FLASH.lerp(DANGER_RED, t / 0.5)
	else:
		sprite.color = DANGER_RED.lerp(_base_color, (t - 0.5) / 0.5)
	if _flash_timer <= 0.0:
		sprite.color = _base_color

## Lets subclasses set the resting color (e.g. after a windup color-pop) so flashes restore it.
func set_base_color(c: Color) -> void:
	_base_color = c
	if sprite and _flash_timer <= 0.0:
		sprite.color = c

# ---------------------------------------------------------------------------
# Facing — flips the sprite and the attack hitbox so swings land on the side faced.
# ---------------------------------------------------------------------------
func set_facing(dir: int) -> void:
	if dir == 0 or dir == facing:
		return
	facing = sign(dir)
	_apply_facing()

func _apply_facing() -> void:
	# Mirror the attack hitbox around the body origin.
	if attack_hitbox:
		attack_hitbox.position.x = absf(attack_hitbox.position.x) * facing
		attack_hitbox.scale.x = absf(attack_hitbox.scale.x) * facing

func face_toward(target_x: float) -> void:
	set_facing(1 if target_x >= global_position.x else -1)

# ---------------------------------------------------------------------------
# Death
# ---------------------------------------------------------------------------
func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	# Award the run economy, then announce + clean up.
	if GameState:
		GameState.add_echoes(reward_echoes)
	died.emit()

	# Stop being a threat / a target immediately.
	if attack_hitbox:
		attack_hitbox.active = false
	if hurtbox:
		hurtbox.active = false
		hurtbox.set_deferred("monitoring", false)
	set_collision_layer_value(3, false)   # leave the enemy collision layer
	_on_death()

	# Brief fade, then free.
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(queue_free)

## Subclass hook for death-specific behaviour (drops, sfx, etc).
func _on_death() -> void:
	pass

func is_dead() -> bool:
	return _is_dead

# ---------------------------------------------------------------------------
# Helpers shared by subclasses
# ---------------------------------------------------------------------------
func get_player() -> Node2D:
	var p := get_tree().get_first_node_in_group("player")
	return p as Node2D
