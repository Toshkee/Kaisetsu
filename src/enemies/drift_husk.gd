extends Enemy
class_name DriftHusk
## ZONE 0 "Drift Husk" — a slow, shambling drowned corpse. The game's first enemy and a pure
## timing-teacher: ONE heavily telegraphed attack, generous windup, low pressure. Beating it
## is about reading the color-pop tell and dodging once.
##
## FAIRNESS (STYLE_GUIDE line 12): never winds up while off-screen — gated by a
## VisibleOnScreenNotifier2D so nothing hits the player from nowhere.

enum State { PATROL, CHASE, WINDUP, ATTACK, RECOVER }

# --- Tuning (DriftHusk row in CONVENTIONS.md §9) ---
@export var move_speed: float = 35.0
@export var detect_range: float = 160.0     # starts shambling toward the player
@export var attack_range: float = 26.0      # close enough to commit a swing
@export var windup_time: float = 0.55       # telegraph: color-pop + small lift
@export var active_time: float = 0.18       # AttackHitbox live window
@export var recover_time: float = 0.70      # vulnerable cooldown after a swing
@export var attack_lift: float = 6.0        # px the sprite rises during windup

const CORPSE_COLOR := Color(0.333, 0.408, 0.478, 1.0)   # #55687a muted blue-grey drowned corpse

var _state: int = State.PATROL
var _timer: float = 0.0
var _sprite_rest_y: float = 0.0
var _on_screen: bool = true

@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _on_enemy_ready() -> void:
	set_base_color(CORPSE_COLOR)
	if sprite:
		_sprite_rest_y = sprite.position.y
	if screen_notifier:
		_on_screen = screen_notifier.is_on_screen()
		screen_notifier.screen_entered.connect(func() -> void: _on_screen = true)
		screen_notifier.screen_exited.connect(func() -> void: _on_screen = false)

func _think(delta: float) -> void:
	_timer = maxf(_timer - delta, 0.0)
	var player := get_player()

	match _state:
		State.PATROL:
			# Idle shamble in place; no horizontal drive until the player is noticed.
			velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0 * delta)
			if player and _can_see(player):
				_enter(State.CHASE)

		State.CHASE:
			if not player:
				_enter(State.PATROL)
				return
			face_toward(player.global_position.x)
			velocity.x = move_toward(velocity.x, float(facing) * move_speed, move_speed * 6.0 * delta)
			var dist := absf(player.global_position.x - global_position.x)
			# Only commit a swing while on-screen (fairness) and in range.
			if dist <= attack_range and _on_screen and is_on_floor():
				_enter(State.WINDUP)
			elif not _can_see(player):
				_enter(State.PATROL)

		State.WINDUP:
			# Plant feet and telegraph: pop danger-red and lift slightly.
			velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
			_drive_windup_visual()
			if _timer <= 0.0:
				_enter(State.ATTACK)

		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
			if _timer <= 0.0:
				_enter(State.RECOVER)

		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0 * delta)
			if _timer <= 0.0:
				# Re-evaluate: chase again if the player is still near, else patrol.
				if player and _can_see(player):
					_enter(State.CHASE)
				else:
					_enter(State.PATROL)

func _enter(next: int) -> void:
	# Leaving states: clean up the previous state's visuals/hitbox.
	if _state == State.WINDUP and next != State.ATTACK:
		_reset_windup_visual()
	if _state == State.ATTACK:
		attack_hitbox.active = false

	_state = next
	match next:
		State.WINDUP:
			_timer = windup_time
		State.ATTACK:
			_timer = active_time
			attack_hitbox.active = true
		State.RECOVER:
			_reset_windup_visual()
			_timer = recover_time
		_:
			_timer = 0.0

func _drive_windup_visual() -> void:
	# Color-pop to danger-red and ease the sprite up as the swing charges.
	var t: float = 1.0 - (_timer / windup_time)
	set_base_color(CORPSE_COLOR.lerp(DANGER_RED, t))
	if sprite:
		sprite.position.y = _sprite_rest_y - attack_lift * t

func _reset_windup_visual() -> void:
	set_base_color(CORPSE_COLOR)
	if sprite:
		sprite.position.y = _sprite_rest_y

func _can_see(player: Node2D) -> bool:
	return _on_screen and global_position.distance_to(player.global_position) <= detect_range

func _on_death() -> void:
	_reset_windup_visual()
