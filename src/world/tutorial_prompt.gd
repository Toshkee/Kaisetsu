extends Node2D
class_name TutorialPrompt
## A sparse, diegetic teaching prompt. A trigger Area2D ("Zone") detects the player BODY; when the
## player enters, a small dark panel fades in showing a title (Sōji ochre) + a line of guidance text
## (cold near-white). It fades back out a few seconds after the player leaves (or after a dwell), and
## if `once` it frees its trigger after the first show — the world stays uncluttered.
##
## The integrator sets `title` / `text` / `size` / `position` per-instance from the level data.
##
## Collision (docs/CONVENTIONS.md): the Zone is a passive detector — collision_layer = 0 (nothing
## monitors it), collision_mask = player(2) so it sees the player's CharacterBody2D.

## Heading line — the action being taught (e.g. "DODGE").
@export_multiline var title: String = "":
	set(value):
		title = value
		_apply_text()
## Body line — the short how-to (e.g. "Press the dodge button to roll through attacks").
@export_multiline var text: String = "":
	set(value):
		text = value
		_apply_text()
## Trigger volume size, applied to the Zone's RectangleShape2D in _ready.
@export var size: Vector2 = Vector2(120, 80)
## If true, after the player has entered+left this phase once, the trigger retires (won't
## re-show on backtrack). Default false: the instruction is tied to the PHASE — it fades in
## whenever Sōji is in this area and fades out when he leaves it.
@export var once: bool = false
## Short grace after leaving before the panel fades out (keeps quick in-and-out from flickering).
@export var linger_time: float = 0.25
## If > 0, the panel auto-dismisses this many seconds after it first appears, even if the
## player is still inside — a "dwell" timeout so a prompt never overstays its welcome.
@export var dwell_time: float = 0.0

const OCHRE := Color(0.847, 0.651, 0.341, 1.0)        # #d8a657 Sōji ochre — the title accent
const COLD_TEXT := Color(0.753, 0.792, 0.839, 1.0)    # #c0cad6 cold near-white — body text
const PANEL_INK := Color(0.106, 0.122, 0.165, 0.82)   # #1b1f2a dark slate panel, slightly transparent
const PANEL_EDGE := Color(0.235, 0.286, 0.353, 0.9)   # #3c4a5a steel-blue hairline border
const FADE_IN := 0.35
const FADE_OUT := 0.6

var _shown_once: bool = false
var _inside: bool = false
var _linger_timer: float = 0.0
var _dwell_timer: float = 0.0
var _fade_tween: Tween

@onready var zone: Area2D = $Zone
@onready var zone_shape: CollisionShape2D = $Zone/CollisionShape2D
@onready var panel: Control = $Panel
@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var text_label: Label = $Panel/Margin/VBox/Body

func _ready() -> void:
	# Size the trigger from the export (own a unique shape so instances don't share one).
	if zone_shape:
		var rect := RectangleShape2D.new()
		rect.size = size
		zone_shape.shape = rect
	_apply_text()
	if panel:
		panel.modulate.a = 0.0
		panel.visible = false
	if zone:
		zone.body_entered.connect(_on_body_entered)
		zone.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	# Dwell timeout: hide while the player is still inside after a set time.
	if _inside and dwell_time > 0.0 and _dwell_timer > 0.0:
		_dwell_timer = maxf(_dwell_timer - delta, 0.0)
		if _dwell_timer <= 0.0:
			_hide()
	# Linger-then-fade after the player has left.
	if not _inside and _linger_timer > 0.0:
		_linger_timer = maxf(_linger_timer - delta, 0.0)
		if _linger_timer <= 0.0:
			_hide()

func _apply_text() -> void:
	if title_label:
		title_label.text = title
		title_label.add_theme_color_override("font_color", OCHRE)
		title_label.visible = not title.is_empty()
	if text_label:
		text_label.text = text
		text_label.add_theme_color_override("font_color", COLD_TEXT)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if once and _shown_once:
		return
	_inside = true
	_linger_timer = 0.0
	_shown_once = true
	if dwell_time > 0.0:
		_dwell_timer = dwell_time
	_show()

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_inside = false
	# Start the linger countdown; the panel fades out when it elapses.
	if panel and panel.visible:
		_linger_timer = linger_time

func _show() -> void:
	if not panel:
		return
	panel.visible = true
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(panel, "modulate:a", 1.0, FADE_IN)

func _hide() -> void:
	_linger_timer = 0.0
	_dwell_timer = 0.0
	if not panel:
		return
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(panel, "modulate:a", 0.0, FADE_OUT)
	_fade_tween.tween_callback(_on_faded_out)

func _on_faded_out() -> void:
	if panel:
		panel.visible = false
	# One-shot prompts retire their trigger after the visual has finished.
	if once and zone:
		zone.queue_free()
