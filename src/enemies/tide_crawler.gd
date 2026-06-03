extends Enemy
class_name TideCrawler
## ZONE 0 "Tide Crawler" — a small, quick crab-like creature; weak but FAST. Where the Drift Husk
## is the slow timing-dummy, the Crawler is the reactive-dodge teacher: it skitters/patrols, then
## when the player is close it dash-lunges in with a SHORT (~0.3s) windup color-pop to danger-red,
## a brief active hit, and a short recovery. Snappier than the Husk so the player learns to react,
## not just pre-read.
##
## FAIRNESS (STYLE_GUIDE line 12): never winds up while off-screen — gated by a
## VisibleOnScreenNotifier2D so nothing lunges at the player from nowhere.

enum State { PATROL, CHASE, WINDUP, LUNGE, RECOVER }

# --- Tuning (Zone 0 Tide Crawler: small, ~18 hp, fast, short telegraph) ---
@export var move_speed: float = 70.0        # skitter/chase speed (fast vs Husk's 35)
@export var lunge_speed: float = 230.0       # burst speed during the dash-lunge
@export var patrol_speed: float = 28.0       # gentle drift while unaware
@export var detect_range: float = 140.0      # notices the player and starts chasing
@export var attack_range: float = 40.0       # close enough to commit a lunge
@export var windup_time: float = 0.30        # SHORT telegraph: color-pop to danger-red
@export var active_time: float = 0.16        # AttackHitbox live window during the dash
@export var recover_time: float = 0.45       # vulnerable cooldown after a lunge
@export var attack_crouch: float = 3.0       # px the sprite dips during windup (coil before the spring)

const SHELL_COLOR := Color(0.235, 0.286, 0.353, 1.0)   # #3c4a5a steel blue-grey shell (cold, low + wide)

var _state: int = State.PATROL
var _timer: float = 0.0
var _sprite_rest_y: float = 0.0
var _patrol_dir: int = 1
var _lunge_dir: int = 1
var _on_screen: bool = true

@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _on_enemy_ready() -> void:
	set_base_color(SHELL_COLOR)
	if sprite:
		_sprite_rest_y = sprite.position.y
	_patrol_dir = facing if facing != 0 else 1
	if screen_notifier:
		_on_screen = screen_notifier.is_on_screen()
		screen_notifier.screen_entered.connect(func() -> void: _on_screen = true)
		screen_notifier.screen_exited.connect(func() -> void: _on_screen = false)

func _think(delta: float) -> void:
	_timer = maxf(_timer - delta, 0.0)
	var player := get_player()

	match _state:
		State.PATROL:
			# Skitter back and forth; flip at walls so it never grinds into geometry.
			if is_on_wall():
				_patrol_dir = -_patrol_dir
			set_facing(_patrol_dir)
			velocity.x = move_toward(velocity.x, float(_patrol_dir) * patrol_speed, patrol_speed * 6.0 * delta)
			if player and _can_see(player):
				_enter(State.CHASE)

		State.CHASE:
			if not player:
				_enter(State.PATROL)
				return
			face_toward(player.global_position.x)
			velocity.x = move_toward(velocity.x, float(facing) * move_speed, move_speed * 8.0 * delta)
			var dist := absf(player.global_position.x - global_position.x)
			# Only commit a lunge while on-screen (fairness) and in range.
			if dist <= attack_range and _on_screen and is_on_floor():
				_enter(State.WINDUP)
			elif not _can_see(player):
				_enter(State.PATROL)

		State.WINDUP:
			# Coil: plant feet, pop danger-red, dip slightly. Snappy so it reads as "react now".
			velocity.x = move_toward(velocity.x, 0.0, move_speed * 12.0 * delta)
			_drive_windup_visual()
			if _timer <= 0.0:
				_enter(State.LUNGE)

		State.LUNGE:
			# Burst forward in the locked-in direction; keep driving until the active window ends.
			velocity.x = float(_lunge_dir) * lunge_speed
			if _timer <= 0.0:
				_enter(State.RECOVER)

		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, lunge_speed * 4.0 * delta)
			if _timer <= 0.0:
				# Re-evaluate: chase again if the player is still near, else patrol.
				if player and _can_see(player):
					_enter(State.CHASE)
				else:
					_enter(State.PATROL)

func _enter(next: int) -> void:
	# Leaving states: clean up the previous state's visuals/hitbox.
	if _state == State.WINDUP and next != State.LUNGE:
		_reset_windup_visual()
	if _state == State.LUNGE:
		attack_hitbox.active = false

	_state = next
	match next:
		State.WINDUP:
			_timer = windup_time
			# Lock in the lunge direction at the START of the telegraph so the player can read it.
			var player := get_player()
			if player:
				face_toward(player.global_position.x)
			_lunge_dir = facing
		State.LUNGE:
			_timer = active_time
			attack_hitbox.active = true
			_reset_windup_visual()
		State.RECOVER:
			_reset_windup_visual()
			_timer = recover_time
		_:
			_timer = 0.0

func _drive_windup_visual() -> void:
	# Color-pop to danger-red and dip the sprite as it coils for the spring.
	var t: float = 1.0 - (_timer / windup_time)
	set_base_color(SHELL_COLOR.lerp(DANGER_RED, t))
	if sprite:
		sprite.position.y = _sprite_rest_y + attack_crouch * t

func _reset_windup_visual() -> void:
	set_base_color(SHELL_COLOR)
	if sprite:
		sprite.position.y = _sprite_rest_y

func _can_see(player: Node2D) -> bool:
	return _on_screen and global_position.distance_to(player.global_position) <= detect_range

func _on_death() -> void:
	_reset_windup_visual()
