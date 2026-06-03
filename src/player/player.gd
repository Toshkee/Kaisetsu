extends CharacterBody2D
class_name Player
## Sōji, the last disciple. The heart of KAISETSU's FEEL: deliberate, weighty, crisp.
##
## This script owns the physics body, the tuning constants, movement helpers the states call,
## input buffering, facing, and the combat seam (Hurtbox -> current state -> take_hit). The
## actual moment-to-moment behaviour lives in the state machine under src/player/states/.
##
## Other systems find the player via group "player" and rely on the interface in CONVENTIONS.md
## §7: `health`, `stamina`, `focus`, `facing`, `is_dead()`, `is_invulnerable()`, `respawn()`,
## `full_restore()`, and the `died` / `stats_changed` signals.

signal died
signal stats_changed

# ---------------------------------------------------------------------------
# Tuning constants (CONVENTIONS.md §9 — exported so they're editable in the inspector)
# ---------------------------------------------------------------------------
@export_group("Movement")
@export var speed: float = 130.0
@export var accel: float = 1000.0
@export var friction: float = 1100.0
@export var jump_velocity: float = -300.0
@export var gravity: float = 980.0
@export var max_fall_speed: float = 600.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.12
@export var max_air_jumps: int = 1   # extra mid-air jumps after the first (1 = double jump)

@export_group("Dodge")
@export var dodge_speed: float = 260.0
@export var dodge_time: float = 0.40
@export var dodge_iframe_start: float = 0.05
@export var dodge_iframe_end: float = 0.32
@export var dodge_stamina: float = 25.0

@export_group("Attack")
@export var light_attack_stamina: float = 12.0
@export var light_attack_damage: float = 18.0
@export var light_attack_time: float = 0.35
@export var light_attack_active_start: float = 0.10
@export var light_attack_active_end: float = 0.22
@export var charge_time: float = 0.45
@export var charge_damage: float = 40.0
@export var charge_stamina: float = 22.0

@export_group("Parry")
@export var parry_window: float = 0.16
@export var parry_recovery: float = 0.18
@export var parry_riposte_damage: float = 50.0
@export var parry_stamina_refund: float = 25.0

@export_group("Heal")
@export var heal_amount: float = 45.0
@export var heal_time: float = 0.9
@export var heal_tick: float = 0.55  # when in the heal animation the Focus is spent + health applied

@export_group("Feel")
@export var buffer_time: float = 0.12        # input buffer window for attack/dodge/jump/parry
@export var hit_flash_time: float = 0.12
@export var knockback_resistance: float = 1.0  # 1.0 = full knockback applied

# ---------------------------------------------------------------------------
# Child references
# ---------------------------------------------------------------------------
@onready var health: Health = $Health
@onready var stamina: Stamina = $Stamina
@onready var focus: Focus = $Focus
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var attack_hitbox: Hitbox = $AttackHitbox
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var interactor: Area2D = $Interactor
@onready var camera: Camera2D = $Camera2D

# ---------------------------------------------------------------------------
# Runtime state
# ---------------------------------------------------------------------------
var facing: int = 1
var _invulnerable: bool = false      # set by states with i-frames (dodge)
var _dead: bool = false

# Feel timers
var _coyote_timer: float = 0.0
var _flash_timer: float = 0.0
var _hitstop_timer: float = 0.0
var _air_jumps_used: int = 0   # reset on landing; spent by mid-air (double) jumps

# Buffered inputs: action_name -> seconds remaining.
var _buffers: Dictionary = {
	"jump": 0.0,
	"dodge": 0.0,
	"attack": 0.0,
	"parry": 0.0,
}

const _DANGER_TINT: Color = Color(0.761, 0.353, 0.306, 1.0)  # #c25a4e

## Which SpriteFrames animation each state plays. States without a bespoke clip reuse a close one
## (jump/fall/heal/parry -> idle, charge -> attack, staggered/dead -> hurt until a death clip lands).
const STATE_ANIM := {
	"idle": "idle", "run": "walk", "jump": "idle", "fall": "idle",
	"dodge": "dodge", "attack": "attack", "charge": "attack",
	"heal": "idle", "parry": "idle", "staggered": "hurt", "dead": "death",
}
const _ATTACK_HITBOX_OFFSET_X: float = 24.0  # AttackHitbox local x for facing +1

func _ready() -> void:
	add_to_group("player")
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
	# Wire the state machine to us, then start it.
	state_machine.setup(self)
	# Combat seam: hurt is routed to whatever state is active so fairness logic stays in states.
	hurtbox.hurt.connect(_on_hurt)
	# Death funnels through the state machine into the 'dead' state.
	health.died.connect(_on_health_died)
	# Re-broadcast component changes as a single "something changed" pulse for the HUD.
	health.health_changed.connect(_on_stat_changed)
	stamina.stamina_changed.connect(_on_stat_changed)
	focus.focus_changed.connect(_on_stat_changed)
	# Apply the max-health assist multiplier once at startup.
	health.set_max_health(health.max_health * _safe_mult(Settings.assist_max_health_mult), true)
	attack_hitbox.active = false
	_apply_facing()
	state_machine.start()

func _physics_process(delta: float) -> void:
	# Hitstop: freeze gameplay velocity briefly on impactful hits for that crunchy soulslike feel.
	if _hitstop_timer > 0.0:
		_hitstop_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _coyote_timer > 0.0:
		_coyote_timer -= delta
	if is_on_floor():
		_coyote_timer = coyote_time
		_air_jumps_used = 0

	_tick_buffers(delta)
	_tick_flash(delta)
	# The state machine runs its own _physics_process and drives velocity + move_and_slide.

# ---------------------------------------------------------------------------
# Movement helpers — states call these so the platformer math lives in ONE place.
# ---------------------------------------------------------------------------
func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

## Accelerate horizontal velocity toward `dir` (-1..1) * top speed, or decelerate to 0 when dir==0.
func apply_horizontal(dir: float, delta: float) -> void:
	var target := dir * speed * _safe_mult(Settings.assist_player_speed_mult)
	if absf(dir) > 0.01:
		velocity.x = move_toward(velocity.x, target, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

## Hard-set horizontal velocity (used by dodge / attack nudge).
func set_horizontal(vx: float) -> void:
	velocity.x = vx

func do_jump() -> void:
	velocity.y = jump_velocity
	_coyote_timer = 0.0

## Spend a mid-air jump charge if any remain. Returns true and launches Sōji upward on success.
func try_air_jump() -> bool:
	if _air_jumps_used >= max_air_jumps:
		return false
	_air_jumps_used += 1
	velocity.y = jump_velocity
	_coyote_timer = 0.0
	return true

func has_coyote() -> bool:
	return _coyote_timer > 0.0

func move() -> void:
	move_and_slide()

## Set facing from a horizontal input/intent; ignores 0.
func set_facing_from(dir: float) -> void:
	if dir > 0.01:
		set_facing(1)
	elif dir < -0.01:
		set_facing(-1)

func set_facing(dir: int) -> void:
	if dir == 0 or dir == facing:
		return
	facing = dir
	_apply_facing()

func _apply_facing() -> void:
	if attack_hitbox:
		attack_hitbox.position.x = _ATTACK_HITBOX_OFFSET_X * facing
	if interactor:
		interactor.position.x = absf(interactor.position.x) * facing
	# Flip the sprite horizontally for facing (mirrors around its offset origin).
	if sprite:
		sprite.flip_h = facing < 0

## Play the SpriteFrames clip mapped to a state (called by the StateMachine on every transition).
## Falls back gracefully if the clip isn't present yet (e.g. death still rendering -> uses hurt).
func play_state_anim(state_name: String) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var anim: String = STATE_ANIM.get(state_name.to_lower(), "idle")
	if not sprite.sprite_frames.has_animation(anim):
		anim = "hurt" if (state_name.to_lower() == "dead" and sprite.sprite_frames.has_animation("hurt")) else "idle"
	if not sprite.sprite_frames.has_animation(anim):
		return
	# Restart non-looping clips (attack/dodge) even if re-entering the same state; let looping
	# clips keep their phase if already playing.
	if sprite.animation != anim or not sprite.sprite_frames.get_animation_loop(anim):
		sprite.play(anim)

# ---------------------------------------------------------------------------
# Input buffering — states poll these; window keeps a tap alive ~buffer_time.
# ---------------------------------------------------------------------------
func buffer_input(event: InputEvent) -> void:
	for action in _buffers.keys():
		if event.is_action_pressed(action):
			_buffers[action] = buffer_time

## True if the action was pressed within the buffer window. Optionally consume it.
func consume_buffer(action: String) -> bool:
	if _buffers.get(action, 0.0) > 0.0:
		_buffers[action] = 0.0
		return true
	return false

func peek_buffer(action: String) -> bool:
	return _buffers.get(action, 0.0) > 0.0

func clear_buffers() -> void:
	for action in _buffers.keys():
		_buffers[action] = 0.0

func _tick_buffers(delta: float) -> void:
	for action in _buffers.keys():
		if _buffers[action] > 0.0:
			_buffers[action] = maxf(_buffers[action] - delta, 0.0)

# ---------------------------------------------------------------------------
# Combat seam
# ---------------------------------------------------------------------------
func _on_hurt(hitbox: Hitbox) -> void:
	if _dead:
		return
	# Route to the active state; it decides (i-frame ignore / parry / take damage).
	if state_machine.current_state:
		state_machine.current_state.on_hurt(hitbox)

## Default damage application, called by states that don't special-case the hit.
func take_hit(hitbox: Hitbox) -> void:
	if _dead or _invulnerable:
		return
	var source: Node = _hit_source(hitbox)
	var dmg := hitbox.damage * _safe_mult(Settings.assist_damage_taken_mult)
	health.take_damage(dmg, source)
	if _dead:
		return  # death routed via health.died
	_apply_knockback(hitbox)
	hit_flash()
	apply_hitstop(0.08)
	# Light hits keep you grounded but staggered; the staggered state recovers to idle.
	state_machine.change_state("staggered", {"hitbox": hitbox})

## Knockback away from the hitbox along its facing toward us.
func _apply_knockback(hitbox: Hitbox) -> void:
	var dir := hitbox.knockback_dir_to(global_position)
	if dir == Vector2.ZERO:
		dir = Vector2(-facing, 0)
	velocity = dir * hitbox.knockback * knockback_resistance
	# Keep a little upward pop so knockback reads on the ground.
	if is_on_floor() and velocity.y >= 0.0:
		velocity.y = -80.0

## Resolve the attacking node from a hitbox (its owner, or its parent chain).
func _hit_source(hitbox: Hitbox) -> Node:
	if hitbox.owner:
		return hitbox.owner
	return hitbox.get_parent()

# ---------------------------------------------------------------------------
# Attack hitbox control (used by attack / charge states)
# ---------------------------------------------------------------------------
func enable_attack(damage: float, knockback: float = 220.0, parryable: bool = false) -> void:
	attack_hitbox.damage = damage * _safe_mult(Settings.assist_damage_dealt_mult)
	attack_hitbox.knockback = knockback
	attack_hitbox.parryable = parryable
	attack_hitbox.active = true

func disable_attack() -> void:
	attack_hitbox.active = false

# ---------------------------------------------------------------------------
# I-frames & juice
# ---------------------------------------------------------------------------
func set_invulnerable(v: bool) -> void:
	_invulnerable = v

func is_invulnerable() -> bool:
	return _invulnerable or health.invulnerable

func hit_flash() -> void:
	_flash_timer = hit_flash_time
	if sprite:
		sprite.modulate = Color(1.9, 0.7, 0.6)  # bright red pop

func flash_bright() -> void:
	# Parry flash: pop to shrine highlight #ffcf8a momentarily.
	_flash_timer = hit_flash_time
	if sprite:
		sprite.modulate = Color(2.2, 1.9, 1.3)  # bright gold parry pop

func _tick_flash(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0 and sprite:
			sprite.modulate = Color(1, 1, 1, 1)

## Brief freeze that makes impacts feel weighty. Camera continues; only gameplay velocity pauses.
func apply_hitstop(duration: float) -> void:
	_hitstop_timer = maxf(_hitstop_timer, duration)

func shake_camera(amount: float, duration: float) -> void:
	if camera and camera.has_method("shake"):
		camera.shake(amount, duration)

# ---------------------------------------------------------------------------
# Interaction
# ---------------------------------------------------------------------------
## Returns the nearest interactable overlapping the probe, or null.
func current_interactable() -> Node:
	if interactor == null:
		return null
	var areas := interactor.get_overlapping_areas()
	for a in areas:
		if a.has_method("interact"):
			return a
		var p := a.get_parent()
		if p and p.has_method("interact"):
			return p
	return areas[0] if not areas.is_empty() else null

# ---------------------------------------------------------------------------
# Public lifecycle interface (CONVENTIONS.md §7)
# ---------------------------------------------------------------------------
func is_dead() -> bool:
	return _dead or health.is_dead()

func mark_dead() -> void:
	_dead = true

func respawn(at: Vector2) -> void:
	_dead = false
	_invulnerable = false
	_hitstop_timer = 0.0
	_flash_timer = 0.0
	clear_buffers()
	global_position = at
	velocity = Vector2.ZERO
	full_restore()
	if sprite:
		sprite.modulate = Color(1, 1, 1, 1)
	attack_hitbox.active = false
	hurtbox.active = true
	state_machine.change_state("idle")
	stats_changed.emit()

## Refill every pool — used by shrines and on respawn.
func full_restore() -> void:
	health.reset()
	stamina.refill()
	focus.refill()
	stats_changed.emit()

# ---------------------------------------------------------------------------
# Internal signal handlers
# ---------------------------------------------------------------------------
func _on_health_died() -> void:
	if _dead:
		return
	state_machine.change_state("dead")

func _on_stat_changed(_a = null, _b = null) -> void:
	stats_changed.emit()

func _safe_mult(v: float) -> float:
	return v if v > 0.0 else 1.0
