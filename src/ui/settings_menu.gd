extends Control
## Pause / settings menu (KAISETSU_PLAN A6/A8: granular assist sliders from day one,
## fully gamepad-navigable — NOT Easy/Normal/Hard).
##
## Toggled by the "pause" input action. Opening pauses the tree and grabs focus on the
## first control; closing unpauses. Each slider is two-way bound to a Settings property:
## moving it writes the property and persists via Settings.save_settings(); when opened we
## pull the live Settings values back onto the sliders.
##
## Runs while paused (PROCESS_MODE_WHEN_PAUSED) and the backdrop blocks mouse input.

const COL_BACKDROP := Color(0.059, 0.067, 0.090, 0.82)  # #0f1117 dim, semi-transparent
const COL_TITLE := Color(0.847, 0.651, 0.341, 1.0)      # #d8a657 ochre
const COL_LABEL := Color(0.624, 0.659, 0.706, 1.0)      # #9fb0bd cold

## One row per slider. property = Settings var name, min/max = slider range.
## "audio" rows go through Settings setters (which apply to buses); "assist" rows are
## plain vars set directly. Both then call save_settings().
const ROWS := [
	{"key": "master_volume",             "label": "Master Volume",  "min": 0.0, "max": 1.0, "kind": "audio"},
	{"key": "music_volume",              "label": "Music Volume",   "min": 0.0, "max": 1.0, "kind": "audio"},
	{"key": "sfx_volume",                "label": "SFX Volume",     "min": 0.0, "max": 1.0, "kind": "audio"},
	{"key": "ambience_volume",           "label": "Ambience Volume","min": 0.0, "max": 1.0, "kind": "audio"},
	{"key": "assist_max_health_mult",    "label": "Max Health",     "min": 0.5, "max": 1.5, "kind": "assist"},
	{"key": "assist_damage_dealt_mult",  "label": "Damage Dealt",   "min": 0.5, "max": 1.5, "kind": "assist"},
	{"key": "assist_damage_taken_mult",  "label": "Damage Taken",   "min": 0.5, "max": 1.5, "kind": "assist"},
	{"key": "assist_stamina_regen_mult", "label": "Stamina Regen",  "min": 0.5, "max": 2.0, "kind": "assist"},
	{"key": "assist_player_speed_mult",  "label": "Player Speed",   "min": 0.5, "max": 2.0, "kind": "assist"},
	{"key": "assist_game_speed",         "label": "Game Speed",     "min": 0.5, "max": 1.5, "kind": "assist"},
	{"key": "screen_shake",              "label": "Screen Shake",   "min": 0.0, "max": 1.0, "kind": "assist"},
]

@onready var _resume_button: Button = $Backdrop/Panel/Margin/VBox/ResumeButton
@onready var _rows_box: VBoxContainer = $Backdrop/Panel/Margin/VBox/Rows

# key -> {slider, readout}
var _controls: Dictionary = {}
# Guards against feedback when we push Settings values back onto sliders.
var _syncing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	($Backdrop as ColorRect).color = COL_BACKDROP
	visible = false
	_build_rows()


func _build_rows() -> void:
	for row in ROWS:
		var line := VBoxContainer.new()
		line.add_theme_constant_override("separation", 1)

		var header := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = row["label"]
		name_label.add_theme_color_override("font_color", COL_LABEL)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(name_label)

		var readout := Label.new()
		readout.add_theme_color_override("font_color", COL_LABEL)
		readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		readout.custom_minimum_size = Vector2(48, 0)
		header.add_child(readout)
		line.add_child(header)

		var slider := HSlider.new()
		slider.min_value = row["min"]
		slider.max_value = row["max"]
		slider.step = 0.05
		slider.custom_minimum_size = Vector2(300, 0)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var key: String = row["key"]
		var kind: String = row["kind"]
		slider.value_changed.connect(_on_slider_changed.bind(key, kind, readout))
		line.add_child(slider)

		_rows_box.add_child(line)
		_controls[key] = {"slider": slider, "readout": readout}


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Open / close
# ---------------------------------------------------------------------------
func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	_pull_from_settings()
	visible = true
	get_tree().paused = true
	# First control grabs focus for controller navigation.
	var first := _first_focusable()
	if first:
		first.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false


func _first_focusable() -> Control:
	for row in ROWS:
		var entry: Dictionary = _controls.get(row["key"], {})
		if entry.has("slider"):
			return entry["slider"]
	return _resume_button


# ---------------------------------------------------------------------------
# Two-way binding
# ---------------------------------------------------------------------------
func _pull_from_settings() -> void:
	if Settings == null:
		return
	_syncing = true
	for row in ROWS:
		var key: String = row["key"]
		var entry: Dictionary = _controls.get(key, {})
		if entry.is_empty():
			continue
		var value: float = float(Settings.get(key))
		(entry["slider"] as HSlider).value = value
		_update_readout(entry["readout"], value)
	_syncing = false


func _on_slider_changed(value: float, key: String, kind: String, readout: Label) -> void:
	_update_readout(readout, value)
	if _syncing or Settings == null:
		return
	# Audio rows go through setters (apply to buses); assist rows are plain vars.
	# Both are reachable via Object.set(), which honours declared setters.
	Settings.set(key, value)
	Settings.save_settings()


func _update_readout(readout: Label, value: float) -> void:
	readout.text = "%.2f" % value


func _on_resume_pressed() -> void:
	close()
