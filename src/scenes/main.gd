extends Node2D
## The game/integration root for the Mezame Shore vertical slice. Spawns the player, binds the HUD,
## and owns the death -> respawn -> Echoes-marker loop (KAISETSU_PLAN Open Decision #4). Rooms,
## enemies, shrines, and UI are each self-contained; Main only wires the seams between them.

const PLAYER_SCENE: PackedScene = preload("res://src/player/Player.tscn")
const ECHO_MARKER_SCENE: PackedScene = preload("res://src/world/EchoMarker.tscn")
const RESPAWN_DELAY: float = 1.6

# Camera bounds in the room's LOCAL space (left, top, width, height); offset by the room's
# actual global_position at runtime so it stays correct even if the room is moved in the editor.
const CAM_LIMIT := Rect2(-240, -360, 1440, 560)

@onready var world: Node2D = $World
@onready var hud: CanvasLayer = $HUD
@onready var room: Node2D = get_node_or_null("World/MezameShore")

var player: Player
var _spawn_point: Vector2
var _respawning: bool = false

func _ready() -> void:
	var marker := get_tree().get_first_node_in_group("player_spawn")
	_spawn_point = (marker as Node2D).global_position if marker != null else Vector2.ZERO
	_spawn_player(_spawn_point)
	# Music/ambience intent — null-safe, stays silent until audio packs are added.
	MusicManager.set_ambience("")
	MusicManager.play_zone("")
	# If we returned after a death elsewhere, drop the Echoes marker back into the world.
	_maybe_spawn_echo_marker()

func _spawn_player(at: Vector2) -> void:
	player = PLAYER_SCENE.instantiate()
	world.add_child(player)
	player.global_position = at
	if not player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died)
	hud.bind_player(player)
	_apply_camera_limits()

func _apply_camera_limits() -> void:
	if player == null or player.camera == null:
		return
	var base: Vector2 = room.global_position if room != null else Vector2.ZERO
	var c := player.camera
	c.limit_left = int(base.x + CAM_LIMIT.position.x)
	c.limit_top = int(base.y + CAM_LIMIT.position.y)
	c.limit_right = int(base.x + CAM_LIMIT.position.x + CAM_LIMIT.size.x)
	c.limit_bottom = int(base.y + CAM_LIMIT.position.y + CAM_LIMIT.size.y)

func _on_player_died() -> void:
	if _respawning:
		return
	_respawning = true
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	var pos := GameState.respawn_position if GameState.has_respawn else _spawn_point
	player.respawn(pos)
	hud.bind_player(player)
	_apply_camera_limits()
	_maybe_spawn_echo_marker()
	_respawning = false

func _maybe_spawn_echo_marker() -> void:
	if not GameState.has_dropped_echoes or GameState.dropped_echoes <= 0:
		return
	var marker := ECHO_MARKER_SCENE.instantiate()
	world.add_child(marker)
	(marker as Node2D).global_position = GameState.dropped_echo_position
	if marker.has_method("setup"):
		marker.setup(GameState.dropped_echoes)
