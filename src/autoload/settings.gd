extends Node
## Autoload: Settings
## Global audio + accessibility "assist" multipliers, persisted to user://settings.cfg.
## KAISETSU_PLAN A6/A8: granular assist sliders from day one (NOT Easy/Normal/Hard).
## Loaded first (see [autoload] order) so every other system can read the multipliers.

signal settings_changed

const CONFIG_PATH := "user://settings.cfg"

# --- Audio (linear 0..1, applied to AudioServer buses) ---
var master_volume: float = 1.0: set = set_master_volume
var music_volume: float = 0.8: set = set_music_volume
var sfx_volume: float = 0.9: set = set_sfx_volume
var ambience_volume: float = 0.7: set = set_ambience_volume

# --- Assist / accessibility multipliers (1.0 == default difficulty) ---
var assist_max_health_mult: float = 1.0
var assist_damage_dealt_mult: float = 1.0
var assist_damage_taken_mult: float = 1.0
var assist_stamina_regen_mult: float = 1.0
var assist_player_speed_mult: float = 1.0
var assist_game_speed: float = 1.0: set = set_game_speed
var screen_shake: float = 1.0   # 0 disables all shake

func _ready() -> void:
	load_settings()
	_apply_all_audio()

# ---------------------------------------------------------------------------
# Audio setters — apply to the AudioServer immediately, then notify listeners.
# ---------------------------------------------------------------------------
func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	_apply_bus("Master", master_volume)
	settings_changed.emit()

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_apply_bus("Music", music_volume)
	settings_changed.emit()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_apply_bus("SFX", sfx_volume)
	settings_changed.emit()

func set_ambience_volume(v: float) -> void:
	ambience_volume = clampf(v, 0.0, 1.0)
	_apply_bus("Ambience", ambience_volume)
	settings_changed.emit()

func set_game_speed(v: float) -> void:
	assist_game_speed = clampf(v, 0.25, 2.0)
	Engine.time_scale = assist_game_speed
	settings_changed.emit()

func _apply_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear) if linear > 0.0 else -80.0)

func _apply_all_audio() -> void:
	_apply_bus("Master", master_volume)
	_apply_bus("Music", music_volume)
	_apply_bus("SFX", sfx_volume)
	_apply_bus("Ambience", ambience_volume)

# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------
func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("audio", "ambience", ambience_volume)
	cfg.set_value("assist", "max_health", assist_max_health_mult)
	cfg.set_value("assist", "damage_dealt", assist_damage_dealt_mult)
	cfg.set_value("assist", "damage_taken", assist_damage_taken_mult)
	cfg.set_value("assist", "stamina_regen", assist_stamina_regen_mult)
	cfg.set_value("assist", "player_speed", assist_player_speed_mult)
	cfg.set_value("assist", "game_speed", assist_game_speed)
	cfg.set_value("assist", "screen_shake", screen_shake)
	cfg.save(CONFIG_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	master_volume = cfg.get_value("audio", "master", master_volume)
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	ambience_volume = cfg.get_value("audio", "ambience", ambience_volume)
	assist_max_health_mult = cfg.get_value("assist", "max_health", assist_max_health_mult)
	assist_damage_dealt_mult = cfg.get_value("assist", "damage_dealt", assist_damage_dealt_mult)
	assist_damage_taken_mult = cfg.get_value("assist", "damage_taken", assist_damage_taken_mult)
	assist_stamina_regen_mult = cfg.get_value("assist", "stamina_regen", assist_stamina_regen_mult)
	assist_player_speed_mult = cfg.get_value("assist", "player_speed", assist_player_speed_mult)
	assist_game_speed = cfg.get_value("assist", "game_speed", assist_game_speed)
	screen_shake = cfg.get_value("assist", "screen_shake", screen_shake)
