# KAISETSU — Engineering Conventions & API Contract (locked v1)

> Every script/scene MUST conform to this. It is the integration contract: autoload names, input
> actions, collision layers, the hitbox/hurtbox protocol, component APIs, and the player interface.
> Godot **4.6.3**, GDScript 2.0. **Indent with TABS.** One `class_name` per file. Files: `snake_case.gd`,
> scenes `PascalCase.tscn`. Static typing everywhere it's cheap.

## 1. Directory layout
```
src/autoload/    settings.gd game_state.gd music_manager.gd save_manager.gd   (registered autoloads)
src/components/  health.gd stamina.gd focus.gd hitbox.gd hurtbox.gd           (reusable, class_name'd)
src/player/      player.gd Player.tscn   states/ (one file per state)
src/enemies/     enemy.gd Enemy.tscn  drift_husk.gd DriftHusk.tscn
src/bosses/      (later)
src/world/       shrine.gd Shrine.tscn  echo_marker.gd EchoMarker.tscn  room.gd
src/ui/          hud.gd HUD.tscn  settings_menu.gd SettingsMenu.tscn
src/scenes/      Main.tscn  MezameShore.tscn
```

## 2. Autoloads (always available globally, by name)
- **Settings** — `assist_max_health_mult`, `assist_damage_dealt_mult`, `assist_damage_taken_mult`,
  `assist_stamina_regen_mult`, `assist_player_speed_mult`, `assist_game_speed`, `screen_shake` (all float, 1.0 default;
  shake 0..n). Audio: `master/music/sfx/ambience_volume` (0..1 setters apply to buses). `save_settings()`, `load_settings()`.
  Signal `settings_changed`.
- **GameState** — flags API: `set_flag(name, value=true)`, `has_flag(name)->bool`, `get_flag(name, default)`,
  `add_to_list_flag(name, value)`. Economy: `echoes:int`, `add_echoes(n)`, `spend_echoes(n)->bool`, signal `echoes_changed(value)`.
  Death loop: `on_player_death(pos:Vector2, scene_path:String)`, `reclaim_dropped_echoes()->int`,
  `has_dropped_echoes`, `dropped_echoes`, `dropped_echo_position`. Respawn: `set_respawn(pos, scene_path, shrine_id)`,
  `has_respawn`, `respawn_position`, `respawn_scene`, `is_shrine_lit(id)->bool`. Signal `player_died`.
- **MusicManager** — `play_zone(path)`, `play_boss(path)`, `play_shrine(path)`, `stop()`, `set_ambience(path)`. Null-safe
  (pass `""` to fade out; missing files are no-ops — DO NOT guard around it, just call).
- **SaveManager** — `save_game()->bool`, `load_game()->bool`, `has_save()->bool`. (Called by shrines.)

## 3. Input actions (already in project.godot — use these exact names)
`move_left`, `move_right`, `move_up`, `move_down`, `jump`, `dodge`, `attack`, `parry`, `heal`, `interact`,
`lock_on`, `pause`. Controller-first: each has keyboard + gamepad bindings. **Charge = HOLD `attack`** (no separate action;
measure hold time). Read with `Input.is_action_pressed/just_pressed`. Buffer `attack`/`dodge`/`jump`/`parry` ~0.12s.

## 4. Collision layers (names set in project.godot)
```
1 world         2 player        3 enemy
4 player_hurtbox  5 enemy_hurtbox  6 player_hitbox  7 enemy_hitbox
8 interactable    9 interactor     10 one_way
```
Set layers/masks by BIT NUMBER (layer 1 = value 1, layer 4 = value 8 ...). Helper: layer N -> `1 << (N-1)`.

- Player body (CharacterBody2D): collision_layer = player(2), mask = world(1)+enemy(3)+one_way(10).
- Enemy body: layer = enemy(3), mask = world(1)+one_way(10).
- Player Hitbox (Area2D): layer = player_hitbox(6), mask = 0, monitorable=true.
- Enemy Hitbox: layer = enemy_hitbox(7), mask = 0, monitorable=true.
- Player Hurtbox (Area2D): layer = player_hurtbox(4), mask = enemy_hitbox(7), monitoring=true.
- Enemy Hurtbox: layer = enemy_hurtbox(5), mask = player_hitbox(6), monitoring=true.
- Shrine/EchoMarker (Area2D): layer = interactable(8), mask = interactor(9).
- Player interaction probe (Area2D): layer = interactor(9), mask = interactable(8).

## 5. Hitbox/Hurtbox protocol (THE combat seam)
- `Hitbox` (class_name, extends Area2D): `@export damage, knockback, parryable, attack_id`, `active:bool` (toggles
  shapes + monitorable). It is **detected**, never detects. Toggle `active=true` only during the active attack frames.
- `Hurtbox` (class_name, extends Area2D): monitors hitboxes; on contact emits `hurt(hitbox: Hitbox)`. It does NOT apply
  damage. **The owner connects `hurt` and decides**: if dodging/i-framing → ignore; if in parry window and
  `hitbox.parryable` → trigger parry/riposte; else `health.take_damage(hitbox.damage * assist, source)` + knockback.
- Owners read `Hitbox.get_parent()` chain or `hitbox.owner` for the source node.

## 6. Components (class_name, attach as child nodes)
- `Health`: `@export max_health`, `take_damage(amount, source=null)`, `heal(amount)`, `is_dead()->bool`, `fraction()->float`,
  `reset()`, `set_max_health(v, refill=false)`. Signals `health_changed(cur,max)`, `damaged(amount,source)`, `healed(amount)`, `died`.
- `Stamina`: `@export max_stamina, regen_rate, regen_delay`, `can_spend(a)->bool`, `spend(a)->bool`, `restore(a)`, `refill()`,
  `fraction()`. Signals `stamina_changed(cur,max)`, `stamina_empty`. Regen auto-respects assist mult.
- `Focus` (shared heal+CurseArt pool): `@export max_focus, heal_cost`, `can_spend(a=1)->bool`, `spend(a=1)->bool`,
  `restore(a=1)`, `refill()`, `fraction()`. Signal `focus_changed(cur,max)`.

## 7. Player interface (other systems rely on this)
- Player script `class_name Player`, root is `CharacterBody2D`, in group **"player"**. Find via
  `get_tree().get_first_node_in_group("player")`.
- Exposes: `health: Health`, `stamina: Stamina`, `focus: Focus` (child nodes, also accessible as properties).
- Exposes `facing: int` (+1 right / -1 left), `is_dead() -> bool`, `is_invulnerable() -> bool`,
  signals: `died`, `stats_changed`. HUD binds to player's component signals.
- State machine: child `StateMachine` node + `states/` children. States: `idle run jump fall dodge attack charge heal
  parry staggered dead`. Strict gating; **death + pause hard-cancel everything**. Dodge has an i-frame window
  (~0.3s inside a longer roll) and a stamina cost. Attacks commit (no free cancel). Heal = long, movement-locked,
  interruptible, no i-frames, spends 1 Focus. Parry = short bright-flash window; success → riposte + refund stamina.

## 8. Scene/runtime conventions
- Placeholder art ONLY (no external image files): use `ColorRect`/`Polygon2D`/`_draw()` with STYLE_GUIDE palette.
  Player = ochre `#d8a657`; enemies tinted danger-red `#c25a4e`; shrine = warm `#f2a65a` glow via `PointLight2D`.
- Mood: each room has a `CanvasModulate` (dim desaturated blue-grey `Color(0.30,0.34,0.42)`, NOT pure black) and a
  soft `PointLight2D` on the player (cold) + warm ones at shrines.
- Signals over polling; `@onready` for child refs; never hard-code absolute node paths across scenes.
- All gameplay nodes `process_mode` default; pause menu uses `PROCESS_MODE_WHEN_PAUSED`. `get_tree().paused` for pause.
- Emit progress via groups, not singletons-reaching-into-scenes.

## 9. Tuning constants (exported, starting values — tune later)
Player: speed 110, accel 900, friction 1100, jump_velocity -300, gravity 980, dodge_speed 260, dodge_time 0.40,
dodge_iframe_start 0.05, dodge_iframe_end 0.32, dodge_stamina 25, light_attack_stamina 12, light_attack_damage 18,
charge_time 0.45, charge_damage 40, charge_stamina 22, parry_window 0.16, heal_amount 45, heal_time 0.9, max_health 100,
max_stamina 100, max_focus 3. DriftHusk: speed 35, health 40, contact/swing damage 12, windup 0.55, active 0.18, recovery 0.7.
