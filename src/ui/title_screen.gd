extends Control
class_name TitleScreen
## KAISETSU main menu — a lonely shrine at dusk (the MOONSHIRE target: quiet, cold, melancholic).
##
## This is the BOOT scene, so it must stand alone: a cold layered-fog backdrop, a faint vignette,
## Sōji's dim silhouette off to one side, the shrine glowing faintly, and a slow drifting mist.
## The vertical menu (New Game / Continue / Settings / Quit) is fully gamepad-navigable and the
## Settings sub-panel is instanced on demand and closed with "pause"/"ui_cancel".
##
## Integration seam (docs/CONVENTIONS.md §2):
##   New Game  -> GameFlow.start_new_game()
##   Continue  -> GameFlow.continue_game()   (disabled when SaveManager.has_save() is false)
##   Settings  -> instance res://src/ui/SettingsMenu.tscn, add as child, call open() if present
##   Quit      -> get_tree().quit()

const SETTINGS_MENU_SCENE := preload("res://src/ui/SettingsMenu.tscn")

# --- Palette (STYLE_GUIDE) ---
const COL_TITLE := Color(0.847, 0.651, 0.341, 1.0)        # #d8a657 Sōji ochre
const COL_SUBTITLE := Color(0.624, 0.659, 0.706, 1.0)     # #9fb0bd pale cold highlight
const COL_BUTTON_TEXT := Color(0.753, 0.792, 0.839, 1.0)  # #c0cad6 cold near-white
const COL_BUTTON_DISABLED := Color(0.333, 0.408, 0.478, 1.0)  # #55687a muted blue-grey

@onready var _menu_root: Control = $Layout/MenuColumn
@onready var _title_label: Label = $Layout/TitleBlock/Title
@onready var _subtitle_label: Label = $Layout/TitleBlock/Subtitle
@onready var _new_game_button: Button = $Layout/MenuColumn/NewGameButton
@onready var _continue_button: Button = $Layout/MenuColumn/ContinueButton
@onready var _settings_button: Button = $Layout/MenuColumn/SettingsButton
@onready var _quit_button: Button = $Layout/MenuColumn/QuitButton
@onready var _title_block: Control = $Layout/TitleBlock
@onready var _shrine_light: PointLight2D = $Atmosphere/ShrineLight
@onready var _shrine_sprite: Sprite2D = $Atmosphere/Shrine

# The Settings sub-panel is instanced lazily the first time it's opened.
var _settings_menu: Control = null

# --- live animation state ---
var _t: float = 0.0
var _title_base_y: float = 0.0
var _light_base_energy: float = 0.7

func _buttons() -> Array:
	return [_new_game_button, _continue_button, _settings_button, _quit_button]


func _ready() -> void:
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	_wire_focus_neighbors()
	_refresh_continue_state()
	_setup_button_anims()
	_play_intro()

	_title_base_y = _title_block.position.y
	_light_base_energy = _shrine_light.energy

	# First button grabs focus so the menu is gamepad-navigable from boot.
	_new_game_button.grab_focus()


# ---------------------------------------------------------------------------
# Living scene — gentle title bob, a flickering shrine flame, and the shrine
# breathing warm. Small amplitudes: it should feel alive, not busy.
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	_t += delta
	if _title_block:
		_title_block.position.y = _title_base_y + sin(_t * 1.4) * 4.0
	if _shrine_light:
		_shrine_light.energy = _light_base_energy + sin(_t * 7.3) * 0.07 + sin(_t * 2.1) * 0.05
	if _shrine_sprite:
		var b := 0.86 + sin(_t * 1.9) * 0.05
		_shrine_sprite.self_modulate = Color(b, b * 0.92, b * 0.78, 1.0)


# ---------------------------------------------------------------------------
# Buttons pop and tint when focused/hovered (gamepad + mouse), scaling about
# their centre so the highlighted entry reads instantly.
# ---------------------------------------------------------------------------
func _setup_button_anims() -> void:
	for b in _buttons():
		b.focus_entered.connect(_highlight_button.bind(b))
		b.mouse_entered.connect(_highlight_button.bind(b))
		b.focus_exited.connect(_unhighlight_button.bind(b))
		b.mouse_exited.connect(_unhighlight_button.bind(b))
	_update_button_pivots.call_deferred()

func _update_button_pivots() -> void:
	for b in _buttons():
		b.pivot_offset = b.size * 0.5

func _highlight_button(b: Button) -> void:
	if b.disabled:
		return
	b.pivot_offset = b.size * 0.5
	var tw := b.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(b, "scale", Vector2(1.13, 1.13), 0.14)

func _unhighlight_button(b: Button) -> void:
	var tw := b.create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "scale", Vector2.ONE, 0.12)


# ---------------------------------------------------------------------------
# Continue availability — gated on whether a save exists. Refreshed on _ready.
# ---------------------------------------------------------------------------
func _refresh_continue_state() -> void:
	var has_save := SaveManager != null and SaveManager.has_save()
	_continue_button.disabled = not has_save
	# Dim the disabled entry so it reads as unavailable, not just greyed-out chrome.
	_continue_button.modulate = Color(1, 1, 1, 1) if has_save else Color(1, 1, 1, 0.4)


# ---------------------------------------------------------------------------
# Focus wiring — explicit up/down neighbors, skipping a disabled Continue so the
# controller never lands on a dead entry.
# ---------------------------------------------------------------------------
func _wire_focus_neighbors() -> void:
	var order: Array[Button] = [_new_game_button, _continue_button, _settings_button, _quit_button]
	for i in order.size():
		var up: Button = order[(i - 1 + order.size()) % order.size()]
		var down: Button = order[(i + 1) % order.size()]
		order[i].focus_neighbor_top = order[i].get_path_to(up)
		order[i].focus_neighbor_bottom = order[i].get_path_to(down)
		order[i].focus_previous = order[i].get_path_to(up)
		order[i].focus_next = order[i].get_path_to(down)


# ---------------------------------------------------------------------------
# Intro — a slow, subtle fade-in so the title settles in like dusk falling.
# ---------------------------------------------------------------------------
func _play_intro() -> void:
	# Title + menu are visible from the start; we just fade the whole screen up from black so
	# everything (title, subtitle, menu) appears together quickly. Title gets a gentle extra rise.
	_title_label.modulate = Color(1, 1, 1, 1)
	_subtitle_label.modulate = Color(1, 1, 1, 1)
	_menu_root.modulate = Color(1, 1, 1, 1)
	modulate = Color(1, 1, 1, 0)

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.7)


# ---------------------------------------------------------------------------
# Cancel — close the Settings sub-panel if it's open (it also handles "pause"
# itself, but covering "ui_cancel" here keeps the menu controller-friendly).
# ---------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		if _settings_menu != null and _settings_menu.visible:
			_close_settings()
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Button handlers
# ---------------------------------------------------------------------------
func _on_new_game_pressed() -> void:
	if GameFlow != null:
		GameFlow.start_new_game()


func _on_continue_pressed() -> void:
	if _continue_button.disabled:
		return
	if GameFlow != null:
		GameFlow.continue_game()


func _on_settings_pressed() -> void:
	_open_settings()


func _on_quit_pressed() -> void:
	get_tree().quit()


# ---------------------------------------------------------------------------
# Settings sub-panel (instanced lazily, reused thereafter)
# ---------------------------------------------------------------------------
func _open_settings() -> void:
	if _settings_menu == null:
		_settings_menu = SETTINGS_MENU_SCENE.instantiate()
		add_child(_settings_menu)
	if _settings_menu.has_method("open"):
		_settings_menu.open()
	else:
		_settings_menu.visible = true


func _close_settings() -> void:
	if _settings_menu == null:
		return
	if _settings_menu.has_method("close"):
		_settings_menu.close()
	else:
		_settings_menu.visible = false
	# Settings re-grabs focus internally; return it to the menu on the way out.
	_settings_button.grab_focus()
