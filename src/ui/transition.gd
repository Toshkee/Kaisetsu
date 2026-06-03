extends CanvasLayer
class_name Transition
## A reusable full-screen fade-to-black overlay (KAISETSU scene transitions).
##
## A single high-layer CanvasLayer holding one black ColorRect that covers the whole
## viewport. GameFlow reuses one persistent instance of this to mask scene swaps: fade the
## screen to black, change the scene, then fade back in. It runs with PROCESS_MODE_ALWAYS so
## the tween keeps advancing even while the tree is paused (pause menus, death screens, etc.).
##
## Self-contained and null-safe: drives its own tweens, exposes simple awaitable coroutines,
## and never reaches into other scenes.

## Black ink (#0f1117) — the cold-palette darkest, matching the project clear color.
const INK := Color(0.059, 0.067, 0.090, 1.0)
const DEFAULT_FADE := 0.4

@onready var _rect: ColorRect = $Rect

var _tween: Tween


func _ready() -> void:
	# Persist across scene changes and keep ticking while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	if _rect != null:
		_rect.color = INK
		# Start transparent and click-through; only the fade tween raises alpha.
		_rect.modulate.a = 0.0
		_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Returns true once the overlay is fully opaque (covers everything black).
func is_opaque() -> bool:
	return _rect != null and _rect.modulate.a >= 0.999


## Snap to fully black with no animation (e.g. before the very first fade-in).
func set_black() -> void:
	_kill_tween()
	if _rect != null:
		_rect.modulate.a = 1.0
		_rect.mouse_filter = Control.MOUSE_FILTER_STOP


## Snap to fully clear with no animation.
func set_clear() -> void:
	_kill_tween()
	if _rect != null:
		_rect.modulate.a = 0.0
		_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Fade the screen TO black over `duration`. Awaitable: `await fade_out()`.
func fade_out(duration: float = DEFAULT_FADE) -> void:
	await _fade_to(1.0, duration)
	if _rect != null:
		# While black, swallow input so half-loaded scenes can't be clicked.
		_rect.mouse_filter = Control.MOUSE_FILTER_STOP


## Fade the screen back IN from black over `duration`. Awaitable: `await fade_in()`.
func fade_in(duration: float = DEFAULT_FADE) -> void:
	if _rect != null:
		_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await _fade_to(0.0, duration)


func _fade_to(target_alpha: float, duration: float) -> void:
	if _rect == null:
		return
	_kill_tween()
	if duration <= 0.0:
		_rect.modulate.a = target_alpha
		return
	_tween = create_tween()
	# Process during pause so transitions work from menus/death; ignore time_scale so the
	# Game Speed assist slider can't stretch or skip the fade.
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.set_ignore_time_scale(true)
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_rect, "modulate:a", target_alpha, duration)
	await _tween.finished


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
