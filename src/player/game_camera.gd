extends Camera2D
class_name GameCamera
## The player-follow camera. Smooth follow for a calm, deliberate feel; `shake()` for impact
## feedback (hits, parries, heavy attacks). Shake magnitude is scaled by Settings.screen_shake
## so the accessibility slider (0 == off) is respected without touching call sites.

@export var smoothing_speed: float = 6.0
@export var max_shake_offset: float = 12.0

var _shake_amount: float = 0.0      # current peak offset in pixels (post-settings)
var _shake_duration: float = 0.0
var _shake_elapsed: float = 0.0

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = smoothing_speed
	# Pixel-perfect: snap to integer pixels so the placeholder art stays crisp.
	# (Project sets pixel snap globally; this keeps shake offsets from sub-pixel jitter.)

func _process(delta: float) -> void:
	if _shake_duration <= 0.0:
		if offset != Vector2.ZERO:
			offset = Vector2.ZERO
		return
	_shake_elapsed += delta
	if _shake_elapsed >= _shake_duration:
		_shake_amount = 0.0
		_shake_duration = 0.0
		_shake_elapsed = 0.0
		offset = Vector2.ZERO
		return
	# Linear decay over the duration.
	var t := 1.0 - (_shake_elapsed / _shake_duration)
	var mag := _shake_amount * t
	offset = Vector2(randf_range(-mag, mag), randf_range(-mag, mag))

## Trigger a screen shake. `amount` is the peak pixel offset before the Settings multiplier.
func shake(amount: float, duration: float) -> void:
	var mult: float = Settings.screen_shake if Settings else 1.0
	if mult <= 0.0 or amount <= 0.0 or duration <= 0.0:
		return  # shake disabled or no-op
	var scaled := minf(amount * mult, max_shake_offset)
	# Stack: take the stronger/longer of any in-flight shake so chained hits keep punch.
	if scaled >= _shake_amount:
		_shake_amount = scaled
		_shake_duration = duration
		_shake_elapsed = 0.0
	else:
		_shake_duration = maxf(_shake_duration - _shake_elapsed, duration)
		_shake_elapsed = 0.0
