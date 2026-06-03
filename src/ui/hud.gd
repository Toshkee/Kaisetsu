extends CanvasLayer
## Sparse, diegetic combat HUD (KAISETSU_PLAN A3).
## Thin desaturated bars (health + stamina) that FADE OUT after a few seconds of no
## combat activity, plus 3 Focus pips and a small Echoes count that pops on change.
## Survives pauses (PROCESS_MODE_ALWAYS) so the count is still visible behind menus.
##
## Binds to the player found via group "player": health / stamina / focus component
## signals, plus GameState.echoes_changed. Call bind_player(p) again after a respawn
## to rewire onto a fresh Player instance.

# --- Palette (STYLE_GUIDE hex, normalized) ---
const COL_HEALTH := Color(0.761, 0.353, 0.306, 1.0)   # #c25a4e muted danger-red, kept dim
const COL_HEALTH_BG := Color(0.106, 0.122, 0.165, 1.0) # #1b1f2a deep blue-grey track
const COL_STAMINA := Color(0.624, 0.659, 0.706, 1.0)   # #9fb0bd pale cold highlight
const COL_STAMINA_BG := Color(0.106, 0.122, 0.165, 1.0)
const COL_PIP_ON := Color(0.847, 0.651, 0.341, 1.0)    # #d8a657 Sōji ochre
const COL_PIP_OFF := Color(0.235, 0.290, 0.353, 1.0)   # #3c4a5a steel blue (spent)
const COL_ECHO := Color(0.624, 0.659, 0.706, 1.0)      # #9fb0bd cold

# --- Fade behaviour ---
const IDLE_FADE_DELAY := 3.0      # seconds of no combat activity before fading
const FADED_ALPHA := 0.25         # bars rest at this alpha out of combat
const ACTIVE_ALPHA := 1.0
const FADE_OUT_TIME := 0.6        # tween duration when fading down

# --- Echo pop animation ---
const ECHO_POP_SCALE := Vector2(1.45, 1.45)
const ECHO_POP_TIME := 0.18

# Full pixel width of each bar fill (matches the .tscn fill rects).
const BAR_FULL_WIDTH := 120.0

@onready var _bars: Control = $Bars
@onready var _health_fill: ColorRect = $Bars/HealthBar/Fill
@onready var _stamina_fill: ColorRect = $Bars/StaminaBar/Fill
@onready var _focus_pips: HBoxContainer = $Bars/FocusPips
@onready var _echo_label: Label = $Bars/EchoCount

var _player: Node = null
var _health: Health = null
var _stamina: Stamina = null
var _focus: Focus = null

var _idle_timer: float = 0.0
var _fade_tween: Tween = null
var _echo_tween: Tween = null

# Cached fractions so a re-bind / refresh can repaint without a fresh signal.
var _health_frac: float = 1.0
var _stamina_frac: float = 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_palette()
	# Stamina is no longer a gameplay resource (Isadora-style movement-first); hide its bar.
	var stamina_bar := $Bars/StaminaBar
	if stamina_bar:
		stamina_bar.visible = false
	# Start visible; idle timer will fade us out if nothing happens.
	_bars.modulate.a = ACTIVE_ALPHA
	_idle_timer = IDLE_FADE_DELAY
	# Reflect any pre-existing echo count immediately.
	if GameState:
		if not GameState.echoes_changed.is_connected(_on_echoes_changed):
			GameState.echoes_changed.connect(_on_echoes_changed)
		_set_echo_text(GameState.echoes)
	bind_player(get_tree().get_first_node_in_group("player"))


func _process(delta: float) -> void:
	if _idle_timer > 0.0:
		_idle_timer = maxf(_idle_timer - delta, 0.0)
		if _idle_timer == 0.0:
			_fade_to(FADED_ALPHA, FADE_OUT_TIME)


# ---------------------------------------------------------------------------
# Binding — safe to call repeatedly (e.g. Main rebinds after respawn).
# ---------------------------------------------------------------------------
func bind_player(p: Node) -> void:
	if p == _player and p != null:
		return
	_disconnect_player()
	_player = p
	if _player == null:
		return
	_health = _player.get("health") as Health
	_stamina = _player.get("stamina") as Stamina
	_focus = _player.get("focus") as Focus

	if _health and not _health.health_changed.is_connected(_on_health_changed):
		_health.health_changed.connect(_on_health_changed)
	if _stamina and not _stamina.stamina_changed.is_connected(_on_stamina_changed):
		_stamina.stamina_changed.connect(_on_stamina_changed)
	if _focus and not _focus.focus_changed.is_connected(_on_focus_changed):
		_focus.focus_changed.connect(_on_focus_changed)

	# Paint current values right away (don't wait for the next change).
	if _health:
		_on_health_changed(_health.current_health, _health.max_health)
	if _stamina:
		_on_stamina_changed(_stamina.current, _stamina.max_stamina)
	if _focus:
		_on_focus_changed(_focus.current, _focus.max_focus)
	# A fresh bind counts as activity so the player can see their state.
	_register_activity()


func _disconnect_player() -> void:
	if _health and _health.health_changed.is_connected(_on_health_changed):
		_health.health_changed.disconnect(_on_health_changed)
	if _stamina and _stamina.stamina_changed.is_connected(_on_stamina_changed):
		_stamina.stamina_changed.disconnect(_on_stamina_changed)
	if _focus and _focus.focus_changed.is_connected(_on_focus_changed):
		_focus.focus_changed.disconnect(_on_focus_changed)
	_health = null
	_stamina = null
	_focus = null
	_player = null


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------
func _on_health_changed(current: float, max_health: float) -> void:
	var new_frac: float = current / max_health if max_health > 0.0 else 0.0
	# Damage or heal both count as combat activity.
	if not is_equal_approx(new_frac, _health_frac):
		_register_activity()
	_health_frac = new_frac
	_health_fill.size.x = BAR_FULL_WIDTH * clampf(new_frac, 0.0, 1.0)


func _on_stamina_changed(current: float, max_stamina: float) -> void:
	var new_frac: float = current / max_stamina if max_stamina > 0.0 else 0.0
	# Spending stamina (a drop) is activity; passive regen back up is not.
	if new_frac < _stamina_frac - 0.001:
		_register_activity()
	_stamina_frac = new_frac
	_stamina_fill.size.x = BAR_FULL_WIDTH * clampf(new_frac, 0.0, 1.0)


func _on_focus_changed(current: float, _max_focus: float) -> void:
	var lit: int = int(roundf(current))
	var pip_count: int = _focus_pips.get_child_count()
	for i in pip_count:
		var pip := _focus_pips.get_child(i) as ColorRect
		if pip:
			pip.color = COL_PIP_ON if i < lit else COL_PIP_OFF


func _on_echoes_changed(value: int) -> void:
	_set_echo_text(value)
	_pop_echo()


# ---------------------------------------------------------------------------
# Fade / activity
# ---------------------------------------------------------------------------
func _register_activity() -> void:
	_idle_timer = IDLE_FADE_DELAY
	# Snap back to full alpha instantly on activity.
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
		_fade_tween = null
	_bars.modulate.a = ACTIVE_ALPHA


func _fade_to(target_alpha: float, duration: float) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_bars, "modulate:a", target_alpha, duration)


# ---------------------------------------------------------------------------
# Echoes display
# ---------------------------------------------------------------------------
func _set_echo_text(value: int) -> void:
	_echo_label.text = "echoes %d" % value


func _pop_echo() -> void:
	if _echo_tween and _echo_tween.is_valid():
		_echo_tween.kill()
	_echo_label.pivot_offset = _echo_label.size * 0.5
	_echo_label.scale = ECHO_POP_SCALE
	_echo_tween = create_tween()
	_echo_tween.tween_property(_echo_label, "scale", Vector2.ONE, ECHO_POP_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------------------
# Palette wiring (in case .tscn defaults drift — single source of truth here).
# ---------------------------------------------------------------------------
func _apply_palette() -> void:
	_health_fill.color = COL_HEALTH
	(_health_fill.get_parent() as ColorRect).color = COL_HEALTH_BG
	_stamina_fill.color = COL_STAMINA
	(_stamina_fill.get_parent() as ColorRect).color = COL_STAMINA_BG
	_echo_label.add_theme_color_override("font_color", COL_ECHO)
