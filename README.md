# KAISETSU

> A 2D soulslike of melancholic, sectioned islands. You are **Sōji**, the last disciple of the Sage's
> Order, returning to re-light the Sealing Shrines and re-bind a curse that has hollowed your home.
> Atmosphere first; deliberate, stamina-based combat; gated, interconnected zones. Built to feel like
> **MOONSHIRE**, inverted into Hollow-Knight desolation.

See **[CLAUDE.md](CLAUDE.md)** for the full game/zone bible and **[KAISETSU_PLAN.md](KAISETSU_PLAN.md)**
for the authoritative design + pipeline plan.

## Engine

- **Godot 4.6.3** (GL Compatibility renderer), GDScript 2.0.
- Pixel-art day-one config (`project.godot`): Nearest filter, 2D pixel snap, 640×360 viewport, integer scaling.

## Run it

Open the project folder in Godot, or from a terminal:

```sh
# adjust the path to your Godot binary if different
"/Users/toshkee/Downloads/Godot.app/Contents/MacOS/Godot" --path . 
```

The main scene is `src/scenes/Main.tscn` (the Mezame Shore vertical slice).

## Controls (keyboard / gamepad)

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Move | A / D, ← / → | Left stick / D-pad |
| Jump | Space | A |
| Dodge (i-frames, costs stamina) | Shift | B |
| Attack (tap = light, **hold = charge**) | J | X |
| Parry / riposte | K | RB |
| Heal (long, spends Focus) | F | LB |
| Interact / rest at shrine | E | Y |
| Lock-on | Tab | R-stick click |
| Pause / settings | Esc | Start |

## Project structure

```
project.godot            engine config (input map, layers, pixel-art settings, autoloads)
default_bus_layout.tres  audio buses: Master > Music / SFX / Ambience
icon.svg
src/autoload/   Settings (assist sliders + audio), GameState (flags/echoes/death-loop),
                MusicManager (crossfades), SaveManager (JSON save at shrines)
src/components/ Health, Stamina, Focus (shared heal+CurseArt pool), Hitbox, Hurtbox
src/player/     Player + strict state machine (idle/run/jump/fall/dodge/attack/charge/heal/parry/staggered/dead)
src/enemies/    Enemy base + Drift Husk (telegraphed, on-screen-only attacks)
src/world/      Shrine (diegetic save), EchoMarker (Echoes-on-death loop)
src/ui/         HUD (sparse, fades out of combat), SettingsMenu (assist + audio sliders)
src/scenes/     Main, MezameShore (Zone 0 slice)
docs/           STYLE_GUIDE.md (locked cold palette), CONVENTIONS.md (engineering contract)
assets/         sprites / audio / fonts / palettes (placeholder for now — see STYLE_GUIDE)
```

## Core systems (this slice)

- **Deliberate combat:** stamina governs dodge/attack/charge; dodge has tuned i-frames; attacks commit.
- **Parry + riposte:** short bright-flash window → hitstop, stamina refund, riposte.
- **Shared Focus/Ether pool:** the same scarce resource heals AND (later) powers Curse Arts.
- **Echoes-on-death loop:** die → drop Echoes at a marker → reclaim on touch → lose on a second death.
- **Shrines:** diegetic save + full restore + respawn anchor; the only warm light in a cold world.
- **Accessibility:** granular assist sliders (HP, damage in/out, stamina regen, speed, game-speed, screen-shake) from day one.

## Status

Milestone 0 (pipeline) + the combat core of Milestone 1 (Mezame Shore vertical slice). Placeholder
programmer-art (palette-correct shapes) — the art pipeline (PixelLab → LDtk) comes later per the plan.
