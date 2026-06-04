# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> This file has two halves. **This top half is the engineering/architecture brief.** The **second half
> (“Game Content & Zone Guide”)** is the canonical *design* bible — zones, bosses, characters, story. When a
> request is about *how the code works*, read this half + `docs/CONVENTIONS.md`; when it’s about *what the game
> is*, read the design bible below.

## What this is / toolchain

A **2D pixel-art soulslike built in Godot 4.6** (GDScript 2.0, **GL Compatibility** renderer). There is **no build
step, no package manager, no test suite, and no CI** — it’s an editor-driven Godot project. “Running” = launching the
Godot editor or the project binary. Verification is **manual play** (use the `run` / `verify` skills, or launch and
play); there are no automated tests to run.

The Godot 4.6 editor on this machine lives at `C:\Users\tosii\OneDrive\Desktop\Godot.exe`. Commands below use the
PowerShell call operator; substitute `godot` if it’s on PATH.

```powershell
# Open the project in the editor
& "C:\Users\tosii\OneDrive\Desktop\Godot.exe" --path . -e

# Run the game (boots run/main_scene = src/ui/TitleScreen.tscn)
& "C:\Users\tosii\OneDrive\Desktop\Godot.exe" --path .

# Run ONE scene directly (autoloads still load, so most scenes work in isolation)
& "C:\Users\tosii\OneDrive\Desktop\Godot.exe" --path . res://src/scenes/MezameShore.tscn

# Syntax-check a single script without opening the editor
& "C:\Users\tosii\OneDrive\Desktop\Godot.exe" --headless --path . --check-only --script res://src/player/player.gd

# Capture a PNG of a scene (renders ~95 frames then saves). Must run NON-headless (needs the renderer).
$env:SHOT_SCENE="res://src/scenes/MezameShore.tscn"; $env:SHOT_OUT="res://_preview.png"
& "C:\Users\tosii\OneDrive\Desktop\Godot.exe" --path . --script res://tools/screenshot.gd
```

> `tools/screenshot.gd`’s built-in default `SHOT_SCENE` is `res://src/scenes/Game.tscn`, which **does not exist** —
> always pass `SHOT_SCENE` explicitly (e.g. `MezameShore.tscn` or `Main.tscn`).

## Canonical docs (read these before changing systems)

- **`docs/CONVENTIONS.md`** — the **locked integration contract**: exact autoload names + APIs, input action names,
  the collision-layer bit assignments, the Hitbox/Hurtbox protocol, component APIs, the Player interface, and the
  exported tuning constants. New scripts/scenes **must** conform to it. This is the highest-authority engineering doc.
- **`docs/STYLE_GUIDE.md`** — palette (cold/desaturated), resolution, lighting/mood rules.
- **`KAISETSU_PLAN.md`** — research & locked decisions (Moonshire + Isadora’s-Edge inspiration, the intended art
  pipeline, open design questions). Contains dated decision notes when direction changes.
- **`docs/PARALLAX_AND_TILESET_GUIDE.md`** — how PixelLab tilesets/parallax strips get wired into Godot
  (TileMapLayer + Parallax2D), with the pixel-art import settings.

## Architecture (the big picture — requires several files to see)

**Three layers stacked: global autoloads → reusable components → actors that compose them.**

1. **Autoload backbone** (`src/autoload/`, registered in `project.godot`, reachable by name everywhere):
   `Settings` (assist sliders + audio bus volumes → `user://settings.cfg`), `GameState` (all run-scoped state: echoes,
   flags, lit shrines, respawn anchor, and the death/Echoes loop), `MusicManager` (null-safe — pass `""` to fade,
   missing files are no-ops, **don’t guard around it**), `SaveManager` (`user://save.json`), and `GameFlow` (the
   **single owner of scene changes** — every swap goes through it behind a persistent fade `Transition` + a `_busy`
   guard). Treat these as the only globals; everything else is scene-local.

2. **Component system** (`src/components/`, `class_name`’d nodes attached as children): `Health`, `Stamina`, `Focus`
   are signal-emitting resource pools (HUD binds their `*_changed` signals). The crucial pattern is the
   **Hitbox/Hurtbox combat seam**:
   - `Hitbox` (Area2D) is a *passive* damage volume — **it is detected, it never detects**. Its `active` flag toggles
     its shapes on only during attack frames; it carries `damage/knockback/parryable/attack_id`.
   - `Hurtbox` (Area2D) monitors for overlapping hitboxes and emits **`hurt(hitbox)`** to its owner. It does **not**
     apply damage.
   - **The owner decides what happens.** This is the key seam: the **Player routes `hurt` to its current *state*** (so
     i-frames, parry, and stagger fairness all live in the relevant state file), while the **Enemy base** applies
     damage/knockback directly. So “what happens when X gets hit” is always auditable in one place per actor.
   - Layers/masks are assigned **by bit** per CONVENTIONS §4 (e.g. player body `collision_mask = 517` = world+enemy+
     one_way). The 10 named layers are in `project.godot [layer_names]`.

3. **Player** (`src/player/`): a `CharacterBody2D` in group **`"player"`** (find via
   `get_tree().get_first_node_in_group("player")`) driving a **hierarchical state machine** — a `StateMachine` node
   delegates each physics frame to one of 11 `PlayerState` children in `states/` (idle/run/jump/fall/dodge/attack/
   charge/parry/heal/staggered/dead). `player.gd` owns tuning constants, movement helpers, input buffering, facing,
   and the combat seam. **Combat is movement-first** (the dodge is a *free* Isadora-style dash with full-duration
   i-frames, gated by cooldown — **not** stamina; stamina is currently de-emphasized — see the CONVENTIONS §7/§9
   note). **Charge = HOLD `attack`** (`charge.gd` is a hold-detector that releases into a light or commits a heavy).

4. **Enemies** (`src/enemies/`): an `enemy.gd` base (routes `hurt`→`Health`, knockback, hit-flash, death + Echo
   reward, and gates attacks off-screen via `VisibleOnScreenNotifier2D`) plus concrete enemies (Drift Husk, Tide
   Crawler), each a 5-state FSM (PATROL/CHASE/WINDUP/ATTACK/RECOVER) with red color-pop telegraphs. No bosses exist
   yet (`src/bosses/` is planned). Note: there is **no poise/interrupt system** and **`lock_on` is bound but unread**.

5. **The progression loop + the integrator split** (`src/world/` + `src/scenes/`): the soulslike loop is
   **Shrine rest → save + set respawn → full heal**, and **death → drop Echoes at the corpse → respawn at last lit
   shrine → reclaim via `EchoMarker`**. Critically, this loop is **wired by the integrator `src/scenes/Main.tscn` +
   `main.gd`**, which instances a *room scene* + the HUD + the pause/SettingsMenu and owns the death→respawn→marker
   cycle. A **room scene** (e.g. `MezameShore.tscn`) is just geometry + a `Shrine` + enemies + a `player_spawn`
   `Marker2D`; it is **not** self-sufficient. So: gameplay systems live in Main/autoloads; rooms are content.

6. **Scene flow:** `TitleScreen.tscn` → `GameFlow.start_new_game/continue_game` → `Main.tscn` → instances a room. The
   HUD re-binds to the (respawned) player’s component signals each time.

### Gotchas that will bite

- **Rooms are hand-authored scenes (no flat-image map anymore).** A *room* is a scene like **`MezameShore.tscn`** —
  geometry + a `Shrine` + enemies + a `player_spawn` `Marker2D` — reached via TitleScreen→`Main.tscn`. An earlier
  throwaway `Map.tscn`/`map.gd` that baked collision from a hardcoded `RUNS` array over a flat PixelLab image was
  **deleted on 2026-06-04** (`assets/maps/` is now empty). The path forward: author terrain with `TileMapLayer` +
  `TileSet` and depth with `Parallax2D` — see `docs/PARALLAX_AND_TILESET_GUIDE.md`.
- **Pixel-art rendering is already configured globally** — 640×360 viewport, integer stretch, GL Compatibility,
  `default_texture_filter=0` (Nearest), and 2D snap on. Leave per-node **Texture Filter = Inherit** — a per-node
  `texture_filter=1`/Linear override re-blurs pixel art, so don’t add one.

### House style (from CONVENTIONS.md)

GDScript 2.0 / Godot 4.6. **Indent with TABS.** One `class_name` per file. Files `snake_case.gd`, scenes
`PascalCase.tscn`. Static typing where cheap. Signals over polling; `@onready` for child refs; **never hard-code
absolute cross-scene node paths**. Placeholder visuals use `ColorRect`/`Polygon2D`/`_draw()` with the STYLE_GUIDE
palette (most enemies are still placeholders; Sōji has real PixelLab `AnimatedSprite2D` frames).

---

# KAISETSU — Game Content & Zone Guide

> **For Claude Code:** This file defines the game's structure, zone progression, enemies, bosses, and characters. Reference this at the start of each session. Goal: a 2D soulslike that feels like **MOONSHIRE** — atmospheric, melancholic, sectioned zones that flow into one another, deliberate combat, and a sense of lonely discovery.

---

## Core Feel (The MOONSHIRE Target)

- **Atmosphere first.** Quiet, melancholic, mysterious. The world feels abandoned and heavy with history.
- **Sectioned zones, interconnected.** Each zone is a distinct biome with its own look, enemies, and boss — but they link together so the world feels like one place.
- **Deliberate combat.** Stamina-based, dodge/parry, every hit has weight. Enemies are threats, not fodder.
- **Gated progression.** Each zone ends in a boss. Beating it opens the path forward (and often a shortcut back).
- **Environmental storytelling.** Ruins, corpses, item descriptions tell the story — not cutscenes.
- **Pixel art**, Hollow Knight / Silksong inspired (dark, muted palette, fluid animation).

---

## Protagonist — Sōji, the Last Disciple

**Who they are:** The youngest and last surviving disciple of the Sage's Order — the warrior-monks who kept KAISETSU's curse sealed for generations. "Sōji" (a humble word for sweeping/cleaning) was a gentle joke about the chores given to the newest student; by the end it reads as the one who _cleanses_ the islands.

**Personality:** Earnest, dutiful, quietly determined. Carries survivor's guilt — they lived only because they were away on a menial errand when the curse broke. Polite to a fault (bows to fallen foes). Naive hope hardens into resolve across the game.

**Look (pixel art):**

- Belted training robes of the Order; a straw kasa hat; the Sage's prayer beads around one wrist.
- An inherited longsword that's slightly too big for them.
- Warm earth-tone palette (ochre, faded indigo) that stands out against the cold, desaturated cursed world.
- Silhouette evolves — robes fray and recovered master-relics visibly accumulate on the belt as zones are cleared.

**Core hook:** Sōji believes they can re-seal the curse the way the Order once did — by re-lighting the Sealing Shrines across the islands. This makes the save-shrine system _diegetic_: every shrine you light is Sōji restoring the Order's work. In each zone they also recover a fallen master's relic.

**Arc per zone:**

- **Zone 0 – Mezame Shore:** Returns by boat from an herb-gathering errand to find the outer shrine cold. Re-lighting it = the tutorial. Roku once ferried the Order and recognizes the robes.
- **Zone 1 – Haikyo Village:** The village the Order protected. Kaida, an old shrine-tender, knew Sōji as a child. The Hollow Magistrate sealed villagers in out of panic when the curse hit — failed authority. Yuki, a half-cursed young fighter, is someone Sōji desperately wants to save. _Relic: a master's seal-tag._
- **Zone 2 – Midori Depths:** Where the Order gathered medicine (Sōji's old errand grounds). Kourin, the Verdant Beast, was a guardian-spirit the Order revered — now corrupted, so Sōji must strike down something sacred. Takeshi profiteers off the Order's abandoned supply caches. _Relic: the herbalist master's relic._
- **Zone 3 – Hibiki Caverns:** The deepest sealing site, where the curse is rooted. Akira, a former senior disciple, is chained and fighting the curse within — **can be spared** (→ ally, key to the true ending). The Weeping Golem holds the trapped souls of the Order's dead masters. _Relic: the swordmaster's blade._
- **Zone 4 – Tenkuu Sanctuary:** The Order's high sanctuary. The Hermit is Sōji's last living teacher, driven mad by the truth: the Order never _destroyed_ the curse — they only ever re-sealed it, generation after generation, because unmaking it required a price no one would pay. Raijin's Echo still guards the place out of duty. _Relic: the Sage's own relic / the truth._
- **Zone 5 – Gyokuza Throne:** The Sundered King was the Sage's closest friend and co-founder of the Order; his betrayal birthed the curse. Sōji faces the choice the Order always refused.

**Endings (tie-in):**

- **Seal** — Sōji re-seals the curse and becomes the new lone sealer (the next "Sage"), continuing the cycle. Honors the Order; fixes nothing permanently.
- **Absorb** — Sōji takes the curse into themselves to spare the islands, becoming the Sundered King's successor. Dark.
- **Transcend** — requires sparing Akira + the Hermit's truth; together they unmake the curse at its root, at great personal cost. True ending.

**Starting kit:**

- **Weapon:** the master's inherited longsword — slightly oversized; slower swing, reliable damage. The game's baseline "quality" weapon.
- **Healing:** the Sage's prayer beads (Estus-equivalent) — refilled by resting at / re-lighting shrines; lore-wise they channel the Order's sealing prayers into healing.
- **Curse Art (starter):** a single seal-tag talisman granting one basic ward/skill.
- **Attire:** kasa hat + training robes (light starting armor).
- **Stats:** balanced "quality" start (no specialization) so the player can branch toward any weapon type.

---

## Zone Progression Overview

| #   | Zone                 | Biome                   | Vibe                 | Boss                           |
| --- | -------------------- | ----------------------- | -------------------- | ------------------------------ |
| 0   | **Mezame Shore**     | Coastal ruins           | Tutorial, lonely     | _(Tutorial Warden — optional)_ |
| 1   | **Haikyo Village**   | Plains / ruined village | First real challenge | The Hollow Magistrate          |
| 2   | **Midori Depths**    | Jungle                  | Overgrown, alive     | Kourin, the Verdant Beast      |
| 3   | **Hibiki Caverns**   | Caves                   | Claustrophobic, dark | The Weeping Golem              |
| 4   | **Tenkuu Sanctuary** | Sky island              | Ascension, awe       | Raijin's Echo                  |
| 5   | **Gyokuza Throne**   | Citadel / final         | Climactic, tragic    | The Sundered King              |

Flow: **0 → 1 → 2 → 3 → 4 → 5**, with the hub (**Minato Harbor**) accessible after Zone 1 for resting, upgrades, and shortcuts.

---

## ZONE 0 — MEZAME SHORE (Tutorial)

**Biome:** Misty coastline, broken docks, a wrecked ship. Short and contained.
**Purpose:** Teach the basics — move, attack, dodge, heal, rest at a shrine.
**Length:** 5–10 minutes.

### Teaching Beats

1. Movement + jump → a gap to cross
2. Light attack → first weak enemy
3. Dodge roll → an enemy with a telegraphed swing
4. Rest at first shrine → heal + level explained
5. A locked gate → opens after a simple "first kill" or pulling a lever

### Enemies

- **Drift Husk** — slow, shambling drowned corpse. One attack. Pure punching bag to learn timing.
- **Tide Crawler** — small crab-like creature, quick but weak. Teaches dodging fast attacks.

### Optional Mini-Boss: **The Tutorial Warden** (Kishi no Nokori)

- A broken suit of armor half-buried in sand. Two attacks: overhead slam, horizontal sweep.
- Optional but rewards a weapon upgrade. Teaches the parry window.

### Characters

- **Roku** — old ferryman sitting by the wreck. First friendly face. Explains the islands are cursed, points you onward. Becomes your fast-travel NPC later.

---

## ZONE 1 — HAIKYO VILLAGE (First Real Zone)

**Biome:** Grassy plains, a crumbling village, outskirts of a dark forest. "Normal" starting-area feel before things get strange.
**Vibe:** Melancholy — a place where people once lived. Now hollow.

### Enemies

- **Hollow Villager** — former residents, slow, attack in small groups. Teach crowd management.
- **Stray Hound** — fast, low health, lunges. Teach spacing.
- **Bandit Scavenger** — human enemy with a shield; teaches breaking guard / circling.
- **Rooftop Archer** — ranged threat on buildings; teaches closing distance + using cover.

### Mini-Boss: **The Bell Keeper**

- A hollow monk guarding the village bell. Slow but heavy hits. Drops a key item or shortcut access.

### Main Boss: **The Hollow Magistrate** (Munashii Daikan)

- The corrupted village leader, draped in tattered official robes.
- **Phase 1:** Wide robe sweeps, slow telegraphs — beginner-friendly.
- **Phase 2:** Summons 2 Hollow Villagers, adds a lunging grab.
- **Theme:** Authority that failed its people. Sets the tragic tone.

### Characters

- **Kaida** — shrine keeper who survived the curse. Calm, cryptic. Guides the player, hints at secrets. Recurring NPC.
- **Yuki** — a hunter trapped in the village, half-cursed. Quest: find her lost blade. Pays off later.

---

## ZONE 2 — MIDORI DEPTHS (Jungle)

**Biome:** Dense, overgrown jungle. Bioluminescent plants, twisting roots, vertical canopy paths.
**Vibe:** Alive and watching. Nature reclaimed everything.

### Enemies

- **Thornling** — plant creature rooted in place; lashes out with vines. Teaches ranged plant hazards.
- **Beast-Hybrid (Boar)** — charges in straight lines; teaches sidestep dodging.
- **Spore Drifter** — floating fungal enemy; releases poison clouds on death. Teaches positioning.
- **Canopy Stalker** — drops from above; teaches looking up / reacting to ambush.

### Mini-Boss: **The Rootbound Knight**

- A warrior fused with the jungle, half-tree. Slow, tanky, area attacks via roots.

### Main Boss: **Kourin, the Verdant Beast** (Midori no Juu)

- A massive beast — part tiger, part ancient guardian, wrapped in glowing vines.
- **Phase 1:** Claw swipes, pounce.
- **Phase 2:** Summons spore clouds, gains a roar that staggers.
- **Theme:** The wilderness as both beautiful and lethal. First "big" spectacle fight.

### Characters

- **Takeshi** — a merchant who set up in the jungle ruins. Sells rare items. Shady, knows more than he says.

---

## ZONE 3 — HIBIKI CAVERNS (Caves)

**Biome:** Deep underground. Crystals, narrow passages, underground pools, total darkness in places (light mechanic optional).
**Vibe:** Claustrophobic, oppressive. The deepest part of the curse.

### Enemies

- **Cave Lurker** — blind creature that reacts to sound/movement; teaches careful pacing.
- **Crystal Crawler** — armored bug; weak spot on the back; teaches positioning.
- **Hollow Miner** — pickaxe-wielding former worker; aggressive; teaches aggression management.
- **Shrieker** — bat-swarm enemy; alerts others; teaches priority targeting.

### Mini-Boss: **The Echo Twins**

- Two fast, identical wraiths that attack in sync. Teaches handling multiple threats.

### Main Boss: **The Weeping Golem** (Nageki no Kyozou)

- A massive crystal-and-stone construct, glowing with trapped souls. Slow but devastating.
- **Phase 1:** Ground slams, falling debris.
- **Phase 2:** Crystals on its body shatter — ranged shard attacks; weak points exposed.
- **Theme:** Sorrow given form. The souls trapped inside "weep." Emotional gut-punch boss.

### Characters

- **Akira** — a corrupted warrior found chained in the depths. Boss-tier encounter that can be **spared** (moral choice). If spared, becomes an ally NPC.

---

## ZONE 4 — TENKUU SANCTUARY (Sky Island)

**Biome:** Floating islands above the clouds, ancient temples, wind currents, broken bridges. Bright but eerie.
**Vibe:** Awe and ascension. You've climbed out of the dark into something sacred and strange.

### Enemies

- **Wind Wisp** — fast flying enemy; erratic movement; teaches reaction.
- **Sky Sentinel** — armored flying guardian; teaches aerial combat / timing.
- **Gale Archer** — ranged enemy using wind arrows; teaches dodging projectiles mid-platforming.
- **Cloud Leaper** — agile creature that uses updrafts; teaches verticality.

### Mini-Boss: **The Gatekeeper of Wind**

- Guards the path to the summit. Uses wind gusts to push the player toward edges. Teaches arena awareness.

### Main Boss: **Raijin's Echo** (Raijin no Kodama)

- A spectral thunder guardian — the echo of an ancient protector.
- **Phase 1:** Lightning strikes at marked positions, dash attacks.
- **Phase 2:** Arena-wide lightning, summons wind tunnels, faster combos.
- **Theme:** A guardian still doing its duty long after its purpose died. Bittersweet.

### Characters

- **The Hermit** (unnamed) — a hooded figure living atop the sky island. Reveals the truth of the curse's origin. Major lore drop before the finale.

---

## ZONE 5 — GYOKUZA THRONE (Final Zone)

**Biome:** A grand ruined citadel, throne room, royal halls in decay. The epicenter of the curse.
**Vibe:** Climactic, tragic, heavy. Everything has been building to this.

### Enemies

- **Royal Guard (Hollow)** — elite armored knights; combine everything the player has learned.
- **Court Wraith** — fast spectral nobles; aggressive combos.
- **Cursed Champion** — mini-boss-tier elite enemies guarding key rooms.

### Mini-Boss: **The Twin Blades of the Court**

- Two elite duelists, fast and coordinated. A skill check before the finale.

### Final Boss: **The Sundered King** (Saketa Ou)

- The fallen ruler whose betrayal birthed the curse. The heart of the story.
- **Phase 1:** Noble swordsman — elegant, precise combos.
- **Phase 2:** The curse takes over — twisted form, area attacks, summons echoes of past bosses.
- **Phase 3 (true ending):** Purified form — a final, sorrowful duel.
- **Theme:** The tragedy at the center of everything. The player's choice decides the ending.

### Endings (Player Choice)

- **Seal the curse** — bittersweet, the islands sleep.
- **Absorb the curse** — dark, the player becomes the new cursed ruler.
- **Transcend the curse** — true ending, requires sparing Akira + finding the Hermit's truth.

---

## HUB — MINATO HARBOR (Safe Zone)

Unlocked after Zone 1. Central island where the curse is weakest.

- **Roku** — ferry / fast travel between unlocked zones.
- **Kaida** — shrine, leveling, lore.
- **Takeshi** — shop (if you found him in the jungle).
- **Yuki / Akira** — appear here if their quests progressed.
- Shortcuts open back to each zone as you clear them.
