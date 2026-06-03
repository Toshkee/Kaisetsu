extends Node2D
class_name Shrine
## A Sealing Shrine — KAISETSU's diegetic save point (KAISETSU_PLAN A2). Lighting it is Sōji
## restoring the Order's sealing work: it saves the game, sets the respawn anchor, fully
## restores the player, and emits the ONLY warm light in a cold zone.
##
## Collision (see docs/CONVENTIONS.md): InteractZone is layer=interactable(8), mask=interactor(9).
## The player's interaction probe (layer interactor) enters it; while in range, pressing the
## `interact` action rests at the shrine.

signal rested

## Stable identifier used by GameState.set_respawn / is_shrine_lit to track lit shrines.
@export var shrine_id: String = "shrine_default"
## If true the shrine begins already lit (e.g. the first shrine in a tutorial).
@export var starts_lit: bool = false

# --- Visual tuning -----------------------------------------------------------
const COLD_STONE := Color(0.235, 0.282, 0.353, 1.0)   # #3c4a5a-ish cold slate, unlit
const WARM_GLOW := Color(0.949, 0.651, 0.353, 1.0)    # #f2a65a shrine glow, lit
const LIGHT_ENERGY_UNLIT := 0.25
const LIGHT_ENERGY_LIT := 1.4
const PULSE_SPEED := 2.2
const PULSE_AMOUNT := 0.18

@onready var _sprite: CanvasItem = $Sprite
@onready var _light: PointLight2D = $PointLight2D
@onready var _interact_zone: Area2D = $InteractZone
@onready var _prompt_label: Label = $PromptLabel
@onready var _rest_label: Label = $RestLabel

var _is_lit: bool = false
var _player_in_range: bool = false
var _pulse_time: float = 0.0

func _ready() -> void:
	_prompt_label.visible = false
	_rest_label.visible = false
	# A shrine counts as lit if it starts lit OR it was lit earlier this run (persisted save).
	if starts_lit or GameState.is_shrine_lit(shrine_id):
		_apply_lit(false)
	else:
		_apply_unlit()
	_interact_zone.area_entered.connect(_on_zone_entered)
	_interact_zone.area_exited.connect(_on_zone_exited)

func _process(delta: float) -> void:
	if _is_lit:
		_pulse_time += delta * PULSE_SPEED
		_light.energy = LIGHT_ENERGY_LIT + sin(_pulse_time) * PULSE_AMOUNT
	if _player_in_range and Input.is_action_just_pressed("interact"):
		_rest()

# ---------------------------------------------------------------------------
# Interaction
# ---------------------------------------------------------------------------
func _on_zone_entered(area: Area2D) -> void:
	# Only the player's interaction probe is on the interactor layer / masked here.
	if not _is_player_interactor(area):
		return
	_player_in_range = true
	_prompt_label.visible = true

func _on_zone_exited(area: Area2D) -> void:
	if not _is_player_interactor(area):
		return
	_player_in_range = false
	_prompt_label.visible = false

func _is_player_interactor(area: Area2D) -> bool:
	# The interactor probe belongs to the player (or one of its descendants).
	var node: Node = area
	while node != null:
		if node.is_in_group("player"):
			return true
		node = node.get_parent()
	return false

func _rest() -> void:
	if not _is_lit:
		_apply_lit(true)

	# Persist + set respawn anchor (diegetic save).
	SaveManager.save_game()
	var scene_path: String = ""
	var current_scene: Node = get_tree().current_scene
	if current_scene != null:
		scene_path = current_scene.scene_file_path
	GameState.set_respawn(global_position, scene_path, shrine_id)

	# Refill the player fully.
	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("full_restore"):
		player.full_restore()

	# Warm shrine motif (null-safe per MusicManager contract).
	MusicManager.play_shrine("")

	_show_rest_message()
	rested.emit()

# ---------------------------------------------------------------------------
# Visual state
# ---------------------------------------------------------------------------
func _apply_unlit() -> void:
	_is_lit = false
	_sprite.modulate = COLD_STONE
	_light.color = WARM_GLOW
	_light.energy = LIGHT_ENERGY_UNLIT

func _apply_lit(animate: bool) -> void:
	_is_lit = true
	_light.color = WARM_GLOW
	if animate:
		_sprite.modulate = COLD_STONE
		_light.energy = LIGHT_ENERGY_UNLIT
		var tween := create_tween()
		tween.tween_property(_sprite, "modulate", WARM_GLOW, 0.6)
		tween.parallel().tween_property(_light, "energy", LIGHT_ENERGY_LIT, 0.6)
	else:
		_sprite.modulate = WARM_GLOW
		_light.energy = LIGHT_ENERGY_LIT

func _show_rest_message() -> void:
	_rest_label.text = "The shrine is lit. You rest."
	_rest_label.visible = true
	_rest_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.6)
	tween.tween_property(_rest_label, "modulate:a", 0.0, 1.2)
	tween.tween_callback(func() -> void: _rest_label.visible = false)
