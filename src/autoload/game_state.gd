extends Node
## Autoload: GameState
## Persistent run + story state: stateful dialogue flags (KAISETSU_PLAN A5), completion
## tracking, the two-tier Echoes economy, and the Echoes-on-death loop (Open Decision #4).

signal echoes_changed(value: int)
signal flag_changed(flag: String, value: Variant)
signal player_died

# --- Story / dialogue flags (e.g. "bosses_killed", "ability_unlocked", "akira_spared") ---
var flags: Dictionary = {}
var times_died: int = 0

# --- Two-tier economy ---
var echoes: int = 0           # common currency
var relic_shards: int = 0     # rare currency, spent at shrines for build-defining unlocks

# --- Echoes-on-death loop ---
var has_dropped_echoes: bool = false
var dropped_echoes: int = 0
var dropped_echo_position: Vector2 = Vector2.ZERO
var dropped_echo_scene: String = ""

# --- Respawn anchor (set when resting at / lighting a shrine) ---
var has_respawn: bool = false
var respawn_position: Vector2 = Vector2.ZERO
var respawn_scene: String = ""
var lit_shrines: Array[String] = []

# ---------------------------------------------------------------------------
# Flags
# ---------------------------------------------------------------------------
func set_flag(flag: String, value: Variant = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)

func get_flag(flag: String, default_value: Variant = null) -> Variant:
	return flags.get(flag, default_value)

func has_flag(flag: String) -> bool:
	return flags.has(flag) and flags[flag]

func add_to_list_flag(flag: String, value: Variant) -> void:
	var list: Array = flags.get(flag, [])
	if value not in list:
		list.append(value)
	flags[flag] = list
	flag_changed.emit(flag, list)

# ---------------------------------------------------------------------------
# Economy
# ---------------------------------------------------------------------------
func add_echoes(amount: int) -> void:
	echoes = maxi(echoes + amount, 0)
	echoes_changed.emit(echoes)

func spend_echoes(amount: int) -> bool:
	if echoes < amount:
		return false
	echoes -= amount
	echoes_changed.emit(echoes)
	return true

# ---------------------------------------------------------------------------
# Death loop
# ---------------------------------------------------------------------------
## Called by the player on death. Drops currently-held Echoes at the death spot; if Echoes
## were already on the ground elsewhere, those are lost (Dark Souls rule).
func on_player_death(death_position: Vector2, scene_path: String) -> void:
	times_died += 1
	has_dropped_echoes = echoes > 0
	dropped_echoes = echoes
	dropped_echo_position = death_position
	dropped_echo_scene = scene_path
	echoes = 0
	echoes_changed.emit(echoes)
	player_died.emit()

## Called when the player touches their dropped-Echoes marker.
func reclaim_dropped_echoes() -> int:
	var reclaimed := dropped_echoes
	add_echoes(reclaimed)
	has_dropped_echoes = false
	dropped_echoes = 0
	return reclaimed

# ---------------------------------------------------------------------------
# Shrines / respawn
# ---------------------------------------------------------------------------
func set_respawn(position: Vector2, scene_path: String, shrine_id: String) -> void:
	has_respawn = true
	respawn_position = position
	respawn_scene = scene_path
	if shrine_id != "" and shrine_id not in lit_shrines:
		lit_shrines.append(shrine_id)

func is_shrine_lit(shrine_id: String) -> bool:
	return shrine_id in lit_shrines

# ---------------------------------------------------------------------------
# Serialization (used by SaveManager)
# ---------------------------------------------------------------------------
func to_dict() -> Dictionary:
	return {
		"flags": flags,
		"times_died": times_died,
		"echoes": echoes,
		"relic_shards": relic_shards,
		"lit_shrines": lit_shrines,
		"respawn_position": [respawn_position.x, respawn_position.y],
		"respawn_scene": respawn_scene,
		"has_respawn": has_respawn,
	}

func from_dict(data: Dictionary) -> void:
	flags = data.get("flags", {})
	times_died = int(data.get("times_died", 0))
	echoes = int(data.get("echoes", 0))
	relic_shards = int(data.get("relic_shards", 0))
	var ls: Array = data.get("lit_shrines", [])
	lit_shrines.clear()
	for s in ls:
		lit_shrines.append(str(s))
	var rp: Array = data.get("respawn_position", [0, 0])
	respawn_position = Vector2(rp[0], rp[1]) if rp.size() >= 2 else Vector2.ZERO
	respawn_scene = str(data.get("respawn_scene", ""))
	has_respawn = bool(data.get("has_respawn", false))
	echoes_changed.emit(echoes)
