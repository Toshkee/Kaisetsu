# KAISETSU — Authoritative Planning Document
*Lead Designer/Architect synthesis · v1.0 · 2026-06-02*
*Source: 15-agent research workflow (Moonshire deep-dive + maps/zones tooling), with a skeptic fact-check pass.*

> **How to read this doc.** Part A decodes our inspiration **Moonshire by Challacade** and maps every facet onto KAISETSU. Part B is the **maps/zones art pipeline** (PixelLab + LDtk + Godot). Part C is the **phased build plan**. Part D is the **open decisions** the dev must make before we build.

---

# PART A — Moonshire (Challacade), decoded

## Confidence & sourcing note (READ FIRST)

Moonshire is a **real, confirmed, in-development** game (Steam App **2542170**, dev/publisher **Challacade** = Kyle Schaub, built in **LÖVE2D/Lua**). Documentation is **moderate** and skews toward a small, engaged playtest community.

**Solidly verified (trust as fact):**
- The official Steam premise and the **weapon-as-resource system** (verbatim store copy).
- Developer identity + engine (LÖVE/Lua).
- The **"Souls-like" label** (corroborated by Steam user tags AND Playtester) — but Moonshire is fundamentally a **Zelda-structured action-adventure**, NOT a literal Soulsborne.
- The full **jewelry/gem + assist-options + ambience + memory-dialogue + charge-attack + boss-turns-red** feature set — confirmed verbatim against dated dev Steam announcements (builds 0.2.2 → 0.3.1).

**Demo-derived / single-source (directional, may change):** sunflowers-as-save-points; "world layout overhaul / cave connects town to ruins"; feel numbers ("~40 deaths in 45 min"); per-boss teaching specifics (these came from a *player* named "Dean," not the dev).

**Genuinely UNKNOWN (never assert):** death/respawn penalty; stamina bar; parry/riposte; endings; exact release date (2026 vs 2027 — sources disagree); musical style; native resolution; tile size; animation frame counts.

> ⚠️ **Non-negotiable framing:** KAISETSU's **stamina bar, parry/riposte, Echoes-dropped-on-death, Curse Arts, and three endings are OUR original additions.** Moonshire has none of them confirmed. We borrow Moonshire's **feel, world-structure, and risk/reward instinct** — never a 1:1 mechanic.

---

## A1 — Combat / core verbs

Moonshire's combat is **Zelda-style real-time action**, not Soulsborne. Confirmed verbs: move, **melee swing** (tap), **charge attack** (hold attack — universal, some launch projectiles), **roll-dodge with i-frames**, **throw weapon**, and **sacrifice weapon to heal** (hold Pickup to break the equipped weapon and heal).

The **signature mechanic** is the **weapon-as-consumable economy**. Verbatim Steam copy: *"Each weapon enhances your defense when equipped, and can also be strategically employed — sacrifice it to restore health, or throw it as a projectile for long-range damage."* Your single equipped weapon is **damage, shield, potion, and ranged option at once** — using one spends the others. Weapons: spears, longswords, boomerangs, the magical Lightning Rod. **Healing is a committed offensive act** (breaking a weapon triggers an AoE lightning burst; long animation; real cost). **Roll-dodge is the defensive spine** — tuned so "if invincibility is demanded, it doesn't feel like you're exploiting a glitch." **No confirmed block, stamina bar, or parry.** Attacks commit (no free cancels). You carry **one weapon at a time** (causes hoarding).

**→ For KAISETSU:**
- **COPY:** Roll-dodge with clean intentional i-frames as the defensive backbone — then **add a stamina cost on top**; that single addition converts Moonshire's free roll into our deliberate stamina combat.
- **ADAPT:** Re-skin "weapon-as-consumable" as a **shared scarce resource (Focus/Ether)** powering BOTH healing AND Curse Arts — healing means *not* casting and vice-versa.
- **ADAPT:** Heal = **long, interruptible, punishable animation** (movement-locked, no i-frames) so you must dodge to create space first.
- **COPY:** Tap = light / hold = charged-heavy; attack commitment (no free cancels) — what makes combat read as weighty.
- **AVOID:** Single-weapon hoarding frustration — keep at least primary + sidearm.
- **BUILD OURSELVES (not in Moonshire):** stamina bar, **parry + riposte**, Echoes-on-death. Reference Dark Souls / Hollow Knight / Salt and Sanctuary for these.

> **⚙️ Combat-direction update — 2026-06-04 (supersedes the stamina-cost-on-roll decision in the COPY bullet above):**
> The build has pivoted to a **movement-first, _Isadora's Edge_-style dodge** — a *free* dash with i-frames for its
> whole duration, gated by a short cooldown, **NOT** stamina. Stamina is currently **de-emphasized**: attacks don't
> spend it and the HUD bar is hidden (the `Stamina` component remains in code for possible future use). Attack
> commitment (tap = light / hold = charge, no free cancel) and parry + riposte are unchanged in intent. So "add a
> stamina cost on top … converts the free roll into deliberate stamina combat" is **no longer the direction** — the
> free dash _is_ the dodge. (Parry is built but not yet wired into the input transitions; see backlog.)

---

## A2 — World & level design *(deepest section — what the dev loves most)*

Moonshire is **one continuous, hand-authored, non-linear, interconnected overworld** of sectioned zones — NOT open-world, NOT hub-and-spoke, NOT strictly linear. Official copy: *"a non-linear world full of many challenges,"* where beating *"dungeons, bosses, and battles… you'll uncover exciting new items and abilities that improve your options in combat, while also opening up new areas to explore."* DNA is *A Link to the Past*; a playtester called it *"Zelda-like, Hollow Knight-like."* **New abilities fold the map back open = Metroidvania ability-gating.**

The early spine was deliberately re-paced to **funnel-then-bloom** *(demo-derived)*:
> **Safe Town hub → tutorialized early area (teaches dodge + heal) → Cave (connective corridor linking Town to Ruins) → Ruins → world fans open non-linearly.**

**Boss-gating works two ways:** (1) **spatial lock** — a boss stands at a dungeon entrance; (2) **capstone lock** — the demo's flower-worm requires all other content cleared first.

**Confirmed biomes:** grassy overworld + **Town** (shop, NPCs, breakable props); **Caves** (water-crossing + a **torch/light mechanic**); **Ruins**; a **Sky/Cloud level**; at least one **Dungeon**. Mood shifts by zone; **bosses are themed to their biome.** Secrets via **breakable walls** + destructible props; a **diegetic resource economy** (seeds from trees, ore from exploding rocks, fish from water). **Navigation:** an inventory map item (buggy); **no player fast-travel** (only a dev debug warp). **Save = sunflowers** (discrete in-world anchors). **Authoring:** hand-built via a custom level editor, iterated publicly — **not procedural.**

**→ For KAISETSU:**
- **COPY the macro-shape:** one continuous, hand-authored, interconnected world of named sectioned zones, no loading-screen hub-and-spoke. Mirror the spine: *safe shrine → linear tutorial corridor (dodge/parry/stamina/heal) → mandatory connective corridor → first boss-gated dungeon → bloom open.*
- **COPY both gate types**; make each boss-won **Curse Art / traversal ability double as a world-key** (a boss kill = new combat option + new geography).
- **ADAPT the connective "Cave":** a dark zone where a **light/curse mechanic governs visibility**, a shrine the only safe pocket — produces the lonely tense feeling. Mandatory first pass, shortcut-able later.
- **COPY save anchors:** shrines = sunflowers. Discrete, sparse, at zone thresholds + before bosses; give resting a tangible perk (refill heals/Echoes, re-light a lantern).
- **COPY shortcuts-as-fast-travel, NOT teleport** (Dark Souls 1 / Hollow Knight loop-back model); reserve shrine-to-shrine warp for very late game.
- **COPY + IMPROVE the secret economy:** train players that breakable walls / dead-ends / water crossings hide things — then **pay off ~70%+** (Moonshire got dinged for an empty waterfall).
- **COPY biome-themed bosses & mood-by-zone** — differentiate via **lighting, color-grade, ambient audio, silhouette density** rather than bright color. Keep a vertiginous "sky"-style change-up zone.
- **COPY funnel-then-bloom:** gate the first ~30–45 min into a near-linear teaching corridor, THEN release. **Budget an explicit world-layout re-pacing pass** — Moonshire's first connection graph was wrong and got overhauled; ours will be too.
- **AVOID** an unreliable inventory-only map; give a clean discovery-revealed map early.

---

## A3 — Art direction

Moonshire's surface is a **faithful 16-bit SNES-Zelda / *A Link to the Past* top-down look** ("Colorful," "Cute," "Retro," "Old School") — **warm and cozy, the OPPOSITE of KAISETSU's melancholic desolation.** We import its **techniques and discipline, not its palette.**

Highest-leverage techniques (well-sourced): **palette = emotion, per biome**; **dynamic player-anchored 2D lighting** (cave torch radius, iterated heavily); **signature-color hero** (a small figure in a distinctive **red** cloak against muted environments); **readability-first feedback** (bosses **turn red** as they take damage; clearly telegraphed attacks; per-encounter camera zoom); **minimal diegetic UI** (hearts, sunflower saves, sparse HUD). Custom non-integer scaler ("sunscreen"); animation frame counts undocumented.

**→ For KAISETSU:**
- **ADAPT (palette inversion, same discipline):** master palette (~32–48 colors) skewed **cold/desaturated** (deep blues, greys, sickly greens, muted purples); per-zone ~8–16-color sub-palette; enforce with a **single per-zone color-grade shader** (LUT on a CanvasLayer).
- **COPY signature-color hero:** ONE high-saturation accent for the player (a cold lantern glow); a **second accent reserved for interactables/enemy tells.**
- **COPY player-anchored 2D lighting — biggest atmosphere multiplier:** soft `PointLight2D` on player, placed shrine/torch lights, dark `CanvasModulate` per zone, **normal-mapped tiles/sprites.** Budget iteration time on radius/intensity.
- **COPY diegetic save anchors:** shrines as strong silhouettes emitting the **only warm light** in a cold zone.
- **COPY readability-first feedback, themed:** hit-flash, distinct windup poses, **1–3 frame full-bright flash + hitstop on the parry window** (teaches parry visually).
- **COPY sparse diegetic HUD:** thin desaturated stamina+health bars that fade out of combat; Echoes as a brief pop, not a permanent counter.
- **EXCEED Moonshire (we're side-on):** 3–5 `Parallax2D` layers (far fog → mid → gameplay → foreground occluders) + `GPUParticles2D` ash/dust/embers + vignette + dither.
- **PIPELINE for a new pixel artist:** **palette discipline is the force-multiplier** — re-index every PixelLab asset to the cold master palette; iterate lighting/readability **in Godot, not in the sprite.**

---

## A4 — Audio

Challacade **does not compose** — he **licenses** music/SFX/sprites. **No named composer; musical style undocumented** (don't assume chiptune). Confirmed architecture: **ambience is a separate mixable bus** (wind/rain + its own slider, 0.3.0); **music is zone-scoped**; **audio is the most-iterated/weakest pillar** (a player thread: *"Music is annoying and sounds need more oomph"*).

**→ For KAISETSU:**
- **COPY:** three `AudioServer` buses — **Music / SFX / Ambience** — each with a slider. The **Ambience bus carries the loneliness** (low wind, drips, distant tones, embers near shrines), per-zone, cross-faded on transitions.
- **COPY:** zone-scoped music + distinct **boss track** + calm **shrine track**, cross-faded (~1.5s) via a `MusicManager` autoload. Lean sparse, slow, minor-key; **drop music to pure ambience** in the most desolate corridors.
- **AVOID Moonshire's mistake:** budget an explicit **SFX-"oomph" pass** (2 samples per impact: sharp transient + low body). Signature sounds per verb: dodge whoosh, **parry "ting"** + hitstop, riposte thud+crunch, stamina-empty gasp, Curse Art cast.
- **COPY the sourcing model:** buy **one cohesive dark-ambient music pack + one meaty melee/magic SFX pack**; commission only a few bespoke boss themes; filter everything to ONE sonic palette.
- **COPY:** shrines as the **audio-emotional anchor** — duck ambience, swap to a quiet safe theme + a "rest" leitmotif stinger.

---

## A5 — Narrative

Premise: you are the **Sage's Apprentice**, forced to **flee your homeland** by an "ominous, unknown threat"; goal = uncover the mystery and **save Moonshire**. Tone is a **fusion** (warm surface + real danger + comedic beats) — **NOT relentlessly grim.** Delivery: **light cutscenes + NPCs + exploration** (boss intro cutscenes + unique death scenes; dungeon stories via a new NPC); **story told through world structure** (abilities reopening areas). **Stateful dialogue** (NPCs remember prior conversations + branching choices, 0.2.5). Weakness: currently **text-heavy** and world felt **"disconnected."** **Endings undocumented.**

**→ For KAISETSU:**
- **ADAPT the emotional skeleton:** "displaced, seeking to understand an ominous threat, restore what's lost" — but **invert to Hollow-Knight desolation**: a home **already fallen.**
- **COPY exploration-first delivery + ability-gated world-reopening as the story engine**; environmental storytelling along reopened paths; **keep on-screen text light.**
- **COPY short reusable boss intro cutscenes + unique death scenes** (lock input, camera move, title card, music sting).
- **COPY stateful dialogue:** a `DialogueState` autoload with flags (`bosses_killed`, `times_died`, `ability_unlocked`); **few but reactive NPCs sell desolation.**
- **COPY the tonal-contrast lesson — do NOT go 100% grim:** one warm shrine theme, one bittersweet NPC, a moment of beauty between desolate stretches.
- **ANCHOR the three endings** on how you relate to the lost home (restore / abandon / be consumed) — our addition.

---

## A6 — Progression / systems

**No XP / no numeric level** — growth is **item/ability/gem/heart-based**; saves track **completion %**. **Two-tier economy:** common coins (breakables; world resources respawn ~10 min) + rare **diamonds** traded for **gemstones**. **Jewelry + gem = permanent passives** (verbatim): Ruby+Necklace = invincibility while healing; Emerald+Ring = 10% crit; Amethyst+Necklace = breaking weapons produces money. **Synergy loops** (salvage turns weapon-break into income; Lightning Rod makes healing deal AoE). **Stat trade-offs** (trade a heart for ether/cash). **Assist options** (max HP, weapon damage, move speed, whole-game speed). **Death penalty UNDOCUMENTED.**

**→ For KAISETSU:**
- **ADAPT a two-tier economy:** common **Echoes** + a rare second token (**relic shard**) spent at shrines for permanent build-defining unlocks.
- **ADAPT jewelry as charms/relics:** few, **strong, legible** passive `Resource` modifiers (one clear effect each).
- **COPY synergy-into-resource loops** ("parries refund stamina," "spending a heal damages nearby enemies," "killing at low HP yields bonus Echoes").
- **COPY item/ability growth doubling as world-keys** + **explicit stat trade-offs**; gate strongest relics behind boss drops/shrines.
- **COPY assist sliders from day one** (max HP, damage in/out, stamina regen, `Engine.time_scale`, player speed) via a settings autoload.
- **BUILD OURSELVES — biggest divergence:** the **Echoes-on-death loop** (drop at a corpse marker; reclaim on touch; lose on a second death).
- **COPY environmental currency feeders** (breakables/chests with respawn timers near shrines).

---

## A7 — Distinctive feel

The defining quality is a **fusion**: warm 16-bit *A Link to the Past* surface over **modern deliberate souls-like design**. **The world is the star.** Vibe = cute-retro charm + genuine danger + an undercurrent of loss. Most-remembered: the **disposable-weapon system**, **genuinely hard** ("~40 deaths in 45 min"), **roll-dodge that feels GREAT**, **bosses that each teach one mechanic**, and **readability as a divisive battleground** (zoomed cameras hid attacks; off-screen enemies were the #1 fairness complaint).

**→ For KAISETSU:**
- **COPY the two headline pillars:** (1) risk/reward resource-as-combat (recast onto Echoes/Curse Arts/stamina); (2) every boss teaches one mechanic + dodge-first crisp i-frames.
- **ELEVATE legibility to a first-class pillar from day one** — Moonshire's most divisive area, and **our dark muted palette makes it strictly harder.** Steal the fixes: bosses change color at HP thresholds; careful per-boss camera zoom; bright VFX/audio tells; **hard rule: nothing hits from off-screen.**
- **ADAPT the fusion by inverting tone:** keep the structure, swap cozy warmth for **melancholic Hollow-Knight desolation.**
- **COPY high encounter density + short shrine-to-shrine loops** so the retry cadence stays fast.

---

## A8 — Reception & lessons

Sentiment: **positive/affectionate** in a small playtest community (NO critic reviews yet). Strengths AND weaknesses **recur across the dev's earlier *Legend of Lua*** → reliable patterns. Praised: juicy responsive combat, satisfying roll, boss-as-tutorial, weapon-sacrifice, art, "boss turns red" feedback.

**Recurring complaints = our pre-mortem checklist:** (1) punishing difficulty with abrupt enemy intros; (2) fairness — undodgeable/off-screen attacks; (3) camera zoom hid attacks; (4) controls — 4-dir vs 360° aim conflict, roll too far, wall bounce, ledge falls; (5) tutorial too late; (6) tedious boss retry loop; (7) excessive screen shake; (8) sparse world / flat NPCs; (9) no early enemy drops → players avoided combat; (10) the many weapon verbs spawned exploits.

**→ For KAISETSU:**
- **COPY the praised core:** juicy, readable, responsive combat (hitstop, input buffering); committal-but-not-floaty dodge (tune distance + i-frames as exported constants).
- **COPY accessibility sliders from day one** (granular multipliers, not Easy/Normal/Hard).
- **FIX fairness:** every attack on-screen + telegraphed (windup + color-pop + audio + ranged aim indicator); introduce one new enemy at a time before combining.
- **FIX camera per boss**; **FIX tutorial placement** (front-load a diegetic Sage-trains-apprentice zone teaching stamina/dodge/parry); **FIX retry friction** (short run-back, skippable boss intros on retry).
- **RESTRAIN juice** to suit melancholy (expose shake as a setting); **DENSIFY the world** + a few characterful NPCs; **make combat worth it** (frequent micro-rewards).
- **HARDEN SYSTEM SEAMS:** strict player **state machine** (alive/dead/staggered/casting/healing); death + pause hard-cancel everything; our system web is *more* complex than Moonshire's.
- **CONTROLLER-FIRST with lock-on** (sidesteps Moonshire's worst control friction).
- **DEVELOP IN THE OPEN:** early free demo + tight feedback→patch loop (Challacade's proven solo-dev path).

---

# PART B — Maps & Zones: the recommended pipeline

## B1 — PixelLab Pro verdict: what to use it FOR and NOT

**USE PixelLab Pro as the ART FACTORY ONLY:**
- ✅ **Terrain tilesets** via **Create Tileset** (its strongest, most Godot-ready output) — inner/transition/outer prompts, exported as **Wang / dual-grid / 3×3 / Blob**, with a **Target palette** lock + **Seed** for reproducibility.
- ✅ **Characters** (player/enemies/bosses) — 4/8-dir sprites + walk/run/idle/attack/dodge, with **reference-image style locking**.
- ✅ **Props / set-dressing / shrines / lore objects** (transparent-background PNGs).
- ✅ **Draft animations** (text-animation ≤4 frames/cycle; skeleton animation), then hand-finish.

**Do NOT use PixelLab for:**
- ❌ **Level layout.** The **"Create Map" tool outputs a flat pixel-art IMAGE, not structured tile/collision data** — concept art at best, NOT a shippable level.
- ❌ **Final ≤16×16 hero/enemy/boss sprites** — PixelLab is documented to struggle at 16×16. Author characters at **32–64px**.
- ❌ **One-click finished combat animation** — auto-skeletons need hand cleanup.

**Tier note:** all needed features unlock at **Tier 1**, so the existing **Pro subscription already covers KAISETSU** (commercial license on all paid tiers). Tier 2 only matters for the 400×400 ceiling + priority queue on large boss/environment art.

## B2 — Recommended LEVEL-LAYOUT tool: **LDtk** (primary)

**LDtk + the `heygleeson/godot-ldtk-importer` plugin is the primary layout tool**, with **Godot-native TileMapLayer** as the prototyping/fallback path and **Sprite Fusion** as an optional fast bootstrap.

**Why LDtk wins for KAISETSU:**
- By **Sébastien Benard (director of Dead Cells)** — built for exactly this.
- **"Grid-vania" world layout** + drag-and-drop **Levels** + an auto-computed **`__neighbours` adjacency array** maps **1:1 onto our "sectioned zones that interconnect"** goal — you lay rooms out spatially and the editor *tracks adjacency for you*.
- **IntGrid layers + rule-based Auto-Layers** let a **non-artist** paint "ground/wall" and get edges/corners auto-placed.
- **Typed Entity fields** model shrines, Echoes pickups, Curse-Art unlocks, boss gates/fog walls, enemy spawns, lore inspectables, transitions → become `LDTKEntity` placeholders swapped for real scenes via the **Entity post-import hook.**
- **Direct `.aseprite` live-reload** + crash recovery.

**The one real cost:** the importer **does NOT auto-generate collisions** — you add **Physics Layers manually on the generated TileSet** (one-time per tileset; persists across reimports).

**Why not the alternatives as primary:** Godot-native has **no built-in multi-room world adjacency** (use it for prototyping/first room); Tiled centers on **one map per file** (weakest fit for connected zones); Sprite Fusion is great to **bootstrap the first room** but isn't a world manager.

> Consider **KoBeWi's "Metroidvania System" addon** (Godot 4.6+) for in-engine room-stitching + save-aware minimap, complementing LDtk.

## B3 — End-to-end pipeline (numbered)

1. **Lock the master palette FIRST** — one cold/muted 16-color palette + one warm shrine accent. Write a 12-line style guide (tile size, palette hex, outline rule, shading ramps, light direction, frame counts, pixels-per-unit) and commit it.
2. **Generate terrain in PixelLab → Create Tileset** with 80/20 prompt anchoring (80% static style + 20% subject), **Target palette** set, saved **Seed**; export **Wang/Blob**.
3. **(Bootstrap path)** Drop the tileset into **Sprite Fusion**, paint the room, mark a collider layer, one-click export `.tscn` → Godot. *(First test room only.)*
4. **(Primary path)** Author zones in **LDtk**: paint an **IntGrid**, let **Auto-Layers** skin it, place **typed Entities**, lay out **separate Levels in Grid-vania mode** so `__neighbours` tracks adjacency.
5. **Import to Godot** via `godot-ldtk-importer` → generates `TileMapLayer` + `TileSet`. **Manually add Physics Layers** (press **F** for default rect collision; mark one-way platforms; add **Custom Data layers** `hazard`/`is_ladder`/`sfx_material`). Use the **Entity post-import hook** to swap placeholders for `Shrine.tscn`, `Enemy.tscn`, etc.
6. **Configure Godot for pixel art (day one):** Rendering → Textures → **Default Texture Filter = Nearest**; 2D → **Snap 2D Transforms to Pixel = On**; base viewport **640×360** integer-scaled; import sprites **Lossless**; **Use Texture Padding** on TileSets.
7. **Lighting/mood pass:** **`CanvasModulate`** (dim desaturated blue-grey, NOT pure black) → sparse **`PointLight2D`** pools (warm at shrines, cold elsewhere) + a cold **`DirectionalLight2D`** → **`LightOccluder2D`** polygons → shadow filter None + Nearest.
8. **Normal-map polish (later, hero assets only):** **Laigter** (free) → **invert Y for Godot** → assign via Normal Map / `CanvasTexture` / shader → raise `PointLight2D` Height.
9. **Parallax/atmosphere:** 3–5 **`Parallax2D`** layers + **`GPUParticles2D`** ash/dust/embers + vignette + dither.
10. **Camera transitions:** per-room **`Area2D`** borders rewrite the active **`Camera2D`** `limit_*` (tween slide / snap cut); tight `position_smoothing` + drag margins.

## B4 — Tool comparison

| Tool | Strengths | Weaknesses | Verdict |
|---|---|---|---|
| **PixelLab Pro** | First-class sidescroller tilesets + characters/props; Target-palette lock + seeds; Aseprite extension; MCP server | Weakest at ≤16×16; short clips + imperfect auto-skeletons; "Create Map" = flat image; burns credits | **ART FACTORY ONLY** |
| **LDtk** + importer | **Grid-vania** + auto **`__neighbours`** = perfect for interconnected zones; IntGrid auto-tiling; typed Entities; `.aseprite` live reload | Collisions NOT auto-generated; reimport quirks | **PRIMARY LAYOUT TOOL** |
| **Godot-native TileMapLayer** | Zero import friction; instant edit-and-play; full physics/nav/occlusion | No built-in multi-room adjacency/streaming | **Prototype / first room / fallback** |
| **Sprite Fusion** | Free; natively supports PixelLab tilesets; one-click `.tscn` + collisions | Single-map focus | **Bootstrap first room only** |
| **Tiled + YATI** | Mature; object layers; scripting | One-map-per-file; weak fit for connected zones | Only if you need Tiled scripting |

## B5 — Tile-size & resolution decision

**Decision: author at a 32×32 base for tiles + player + bosses; 16×16 only for tiny pickups/Echoes. Render through a 640×360 viewport, integer-scaled. Upscale at the camera, never baked into art.**

**Rationale:** the brief says "~16×16," but **PixelLab is documented to struggle at exactly 16×16** (our primary art tool is weakest at our stated base); **32×32 is the cited sweet spot** (4× the pixels) and **reads far better for soulslike detail + dark-palette readability** (our hardest problem); text-animation already nudges characters toward 64px. **This revisits the brief's 16×16 assumption — 32×32 is the safer call.** *(Open Decision #1.)*

---

# PART C — Phased build plan

## Milestone 0 — "One Test Room" (proof of pipeline)
**Goal:** validate the entire art→engine pipeline with a walkable, collidable room. No combat.
1. Lock master palette + write the 12-line style guide.
2. PixelLab → Create Tileset (dark prompts: inner "cracked stone floor", transition "mossy ledge", outer "ashen ground"), Target palette, 32×32, export Wang/Blob.
3. Bootstrap via **Sprite Fusion** → paint a ~20×12 room, mark collider, export `.tscn`.
4. In Godot: pixel-art settings (Nearest, Snap 2D, 640×360, Texture Padding); confirm `TileMapLayer` + collisions.
5. Placeholder `CharacterBody2D` walks + collides; add `CanvasModulate` + one warm `PointLight2D` to confirm mood.

**Art needed:** 1 terrain tileset (32×32), 1 placeholder player.

## Milestone 1 — Zone 0 vertical slice: **Mezame Shore**
**Goal:** a complete, atmospheric vertical slice proving combat + save + first teaching boss — the "is the game good?" gate.
- **Player controller** (`CharacterBody2D` + `AnimationTree`) with a **strict state machine** (idle/run/jump/dodge/attack/charge/heal/parry/staggered/dead); all actions gated; death + pause hard-cancel everything.
- **Stamina system** governing dodge + attack + charge.
- **Dodge** with tuned i-frame window (~0.25–0.4s of a longer roll) + stamina cost.
- **Light/heavy attack** (tap/hold charge) with attack commitment.
- **Parry + riposte** (our addition): 1–3 frame bright-flash + hitstop teaching window.
- **Heal** as a long, interruptible, movement-locked state drawing from the shared **Focus/Ether** pool.
- **Shrine save point** (`Area2D`): save, refill, warm light + "rest" leitmotif; respawn anchor.
- **Echoes-on-death loop:** corpse marker, reclaim on touch, lost on second death.
- **Drift Husk enemy:** telegraphed windup→hitbox→recovery; on-screen only.
- **Tutorial Warden (first boss):** teaches dodge timing; HP-threshold color shift; bespoke camera zoom; intro cutscene + unique death scene; skippable intro on retry; drops a Curse Art that's also a world-key.
- **Audio:** 3 buses + sliders; zone ambience; boss track; shrine theme; punchy SFX pass.
- **Assist sliders** + **diegetic HUD** (fade out of combat).

**Art needed:** Mezame Shore tileset; player full animation set; Drift Husk; Tutorial Warden; shrine prop; Curse Art VFX; fog-gate; props/lore; parallax fog.

## Milestone 2 — First full zone (funnel-then-bloom proof)
**Goal:** a complete interconnected zone proving the world-structure thesis: linear tutorial corridor → connective dark corridor → boss-gated dungeon → loop-back shortcut.
- Author in **LDtk Grid-vania** (multiple Levels, `__neighbours`); import + manual Physics Layers; Entity-hook scene swapping.
- Near-linear teaching corridor (dodge → parry → stamina → heal → shrine → first Curse Art).
- Connective dark corridor (light/curse visibility mechanic + one mid-shrine).
- First boss-gated dungeon (second boss teaches parry/Curse-Art; reward reopens an earlier barrier).
- One loop-back shortcut.
- Breakable-wall secrets (pay off ~70%+) + destructible props + environmental harvesting.
- Map/minimap (consider KoBeWi's addon), discovery-revealed.
- 2–3 enemy types introduced one at a time; environmental-storytelling pass; 1–2 reactive NPCs.
- **Re-pacing playtest pass** (budget it).

**Art needed:** full zone tileset family (3 sub-palettes sharing the master); 2–3 enemy sets; 1 new boss; second shrine variant; secret-cache props; 1–2 NPCs + portraits; shortcut props; zone parallax + particles.

---

# PART D — Open decisions for the dev

1. **Tile/sprite resolution: 16×16 vs 32×32?** → **32×32** (tiles + player + bosses), 16×16 only for tiny pickups. PixelLab struggles at 16×16; 32 reads better for dark soulslike detail. Render via 640×360 integer-scaled.
2. **Primary layout tool: LDtk vs Godot-native vs Sprite Fusion?** → **LDtk** primary (Grid-vania + auto-`__neighbours`); Godot-native for prototyping; Sprite Fusion to bootstrap Milestone 0.
3. **Shared resource for healing + Curse Arts?** → **YES, one shared Focus/Ether pool** (Moonshire's best transferable idea). Keep stamina separate.
4. **Death penalty?** → **Full Echoes-on-death loop** (corpse marker, reclaim-or-lose); short run-back. (No Moonshire basis — Dark Souls reference.)
5. **Weapon system: single vs loadout?** → **Primary + sidearm loadout**, throw/sacrifice from the shared pool (avoids Moonshire's hoarding frustration).
6. **Build variety: stat screen vs charm/relic passives?** → **Charm/relic passives** + two-tier economy (Echoes + relic-shards). No XP/levels.
7. **Audio sourcing?** → **Licensed packs under ONE cohesive dark-ambient palette**; commission a few boss themes. Ship 3 buses + sliders day one; budget an SFX-"oomph" pass.
8. **Input priority?** → **Controller-first with lock-on**, fully gamepad-navigable menus.
9. **Camera transitions?** → **Smooth slides for traversal, hard snap + bespoke locked zoom for bosses** (every startup visible).
10. **Normal-mapped lighting: MVP or polish?** → **Polish pass (post-slice), hero assets only.** `CanvasModulate` + `PointLight2D` + occluders first.
11. **KoBeWi Metroidvania System addon?** → **Evaluate and likely adopt** for room-stitching + minimap (confirm 4.6+ compat).
12. **PixelLab MCP integration: now or later?** → **Later.** Learn the manual PixelLab→LDtk/Godot loop first.

---

## Key sources
- [MOONSHIRE on Steam (App 2542170)](https://store.steampowered.com/app/2542170/MOONSHIRE/)
- [Challacade — developer site](https://www.challacade.com/) · [GitHub (Kyle Schaub)](https://github.com/challacade) · [moonshire-archive](https://github.com/challacade/moonshire-archive)
- [Steambase metadata](https://steambase.io/games/moonshire/info) · [Playtester demo coverage](https://playtester.io/moonshire) · [GamingBible feature](https://www.gamingbible.com/news/platform/steam/zelda-new-steam-rpg-free-demo-244459-20250814)
