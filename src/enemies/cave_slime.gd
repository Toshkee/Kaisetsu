extends CharacterBody2D
## Sandbox enemy for the imported Slime art. Drives a native AnimatedSprite2D (so it can't extend
## enemy.gd, which assumes a ColorRect). Reuses Health + Hurtbox so Sōji's attacks kill it through the
## normal combat seam. It's a real, FAIR threat via a TELEGRAPHED LUNGE:
##   PATROL -> CHASE -> WINDUP (coils + reddens) -> LUNGE (hops forward, AttackHitbox live ONLY here)
##   -> RECOVER (vulnerable). Striking it during the wind-up cancels the lunge. Tune per variant in scene.

enum St { PATROL, CHASE, WINDUP, LUNGE, RECOVER }

@export var move_speed: float = 26.0
@export var chase_speed: float = 62.0
@export var gravity: float = 980.0
@export var reward_echoes: int = 3
@export var sense_range: float = 240.0
@export var sense_height: float = 80.0
@export var lunge_range: float = 98.0
@export var windup_time: float = 0.5
@export var lunge_speed: float = 280.0
@export var lunge_hop: float = 135.0
@export var lunge_time: float = 0.34
@export var recover_time: float = 0.6

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var attack_hitbox: Hitbox = get_node_or_null("AttackHitbox")

const DANGER := Color(1.7, 0.5, 0.45, 1.0)

var _state: St = St.PATROL
var _t: float = 0.0
var _dir: int = -1
var _dead: bool = false
var _flash: float = 0.0
var _knock: float = 0.0
var _hitstun: float = 0.0
var _base_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	add_to_group("enemy")
	if sprite:
		_base_scale = sprite.scale
	if hurtbox:
		hurtbox.hurt.connect(_on_hurt)
	if health:
		health.died.connect(_die)
	if attack_hitbox:
		attack_hitbox.active = false
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	if _flash > 0.0:
		_flash = maxf(_flash - delta, 0.0)

	if _dead:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		move_and_slide()
		return

	# Knockback owns motion for a short hitstun window.
	if _hitstun > 0.0:
		_hitstun -= delta
		velocity.x = _knock
		_knock = move_toward(_knock, 0.0, 900.0 * delta)
		move_and_slide()
		_update_visual()
		return

	_t += delta
	match _state:
		St.PATROL: _do_patrol()
		St.CHASE: _do_chase()
		St.WINDUP: _do_windup(delta)
		St.LUNGE: _do_lunge()
		St.RECOVER: _do_recover(delta)

	move_and_slide()
	_update_visual()

func _do_patrol() -> void:
	velocity.x = float(_dir) * move_speed
	if is_on_wall():
		_dir = -_dir
	if _sensed_player() != null:
		_enter(St.CHASE)

func _do_chase() -> void:
	var p := _sensed_player()
	if p == null:
		_enter(St.PATROL)
		return
	_dir = 1 if p.global_position.x >= global_position.x else -1
	if absf(p.global_position.x - global_position.x) <= lunge_range and is_on_floor():
		_enter(St.WINDUP)
		return
	velocity.x = float(_dir) * chase_speed

func _do_windup(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	if _t >= windup_time:
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if p != null:
			_dir = 1 if p.global_position.x >= global_position.x else -1
		_enter(St.LUNGE)

func _do_lunge() -> void:
	velocity.x = float(_dir) * lunge_speed
	if _t >= lunge_time:
		_enter(St.RECOVER)

func _do_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
	if _t >= recover_time:
		_enter(St.CHASE if _sensed_player() != null else St.PATROL)

func _enter(s: St) -> void:
	_state = s
	_t = 0.0
	if s == St.LUNGE:
		velocity.y = -lunge_hop
		velocity.x = float(_dir) * lunge_speed
		if attack_hitbox:
			attack_hitbox.active = true
	else:
		if attack_hitbox:
			attack_hitbox.active = false
		if s == St.WINDUP:
			velocity.x = 0.0

func _sensed_player() -> Node2D:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null:
		return null
	if absf(p.global_position.x - global_position.x) <= sense_range \
			and absf(p.global_position.y - global_position.y) <= sense_height:
		return p
	return null

func _update_visual() -> void:
	if not sprite:
		return
	if _state != St.LUNGE:
		sprite.flip_h = _dir > 0
	# Coil tell while winding up.
	sprite.scale = _base_scale * (Vector2(1.18, 0.82) if _state == St.WINDUP else Vector2.ONE)
	# Modulate priority: white hit-pop > wind-up red tell > normal.
	if _flash > 0.0:
		sprite.modulate = Color(1, 1, 1).lerp(Color(1.8, 1.8, 1.8), _flash / 0.16)
	elif _state == St.WINDUP:
		sprite.modulate = Color(1, 1, 1).lerp(DANGER, clampf(_t / windup_time, 0.0, 1.0))
	else:
		sprite.modulate = Color(1, 1, 1)

func _on_hurt(hb: Hitbox) -> void:
	if _dead or hb == null:
		return
	var mult: float = Settings.assist_damage_dealt_mult if Settings else 1.0
	if health:
		health.take_damage(hb.damage * mult, _source(hb))
	var dir: Vector2 = hb.knockback_dir_to(global_position)
	if dir == Vector2.ZERO:
		dir = Vector2(float(-_dir), 0.0)
	_knock = signf(dir.x) * hb.knockback
	_hitstun = 0.16
	_flash = 0.16
	# Reward aggression: a hit during the wind-up cancels the lunge.
	if _state == St.WINDUP:
		if attack_hitbox:
			attack_hitbox.active = false
		_state = St.RECOVER
		_t = recover_time * 0.4

func _source(h: Hitbox) -> Node:
	return h.owner if h.owner != null else h.get_parent()

func _die() -> void:
	if _dead:
		return
	_dead = true
	if GameState:
		GameState.add_echoes(reward_echoes)
	set_collision_layer_value(3, false)
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
	if attack_hitbox:
		attack_hitbox.active = false
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)
