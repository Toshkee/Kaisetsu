# KAISETSU — Visual Style Guide (locked v1)

> The force-multiplier is **palette discipline** (KAISETSU_PLAN A3). We invert Moonshire's warm
> cozy 16-bit look into **cold, desaturated, melancholic** desolation — same techniques, opposite mood.

## The 12 lines (commit these)

1. **Tile size:** 32×32. **Characters are multi-tile** (bigger than one tile): **Sōji = ~64px tall in a 48×64 frame** (character ~56–60px, leaving headroom for the kasa hat + oversized longsword silhouette). Bosses 96–128px. 16×16 only for tiny pickups/Echoes. (Locked; revises Open Decision #1 which conflated tile and character size.)
2. **Render resolution:** 640×360 viewport, **integer-scaled** at the camera (2×=720p, 3×=1080p, 4×=1440p, 6×=4K — all crisp). Never bake scale into art. A 64px-tall Sōji occupies ~1/6 of screen height.
3. **Texture filter:** Nearest. **Snap 2D transforms + vertices to pixel:** On. (Set in project.godot.)
4. **Outline rule:** selective dark outline (1px, color `#0f1117`) on hero/enemy silhouettes; tiles use interior shading, not full outlines.
5. **Shading ramps:** 3-step per material (shadow / mid / light). Light source = top, slightly camera-left.
6. **Master palette:** cold/desaturated — deep blues, slate greys, sickly greens, muted purples (see hex below).
7. **Signature hero accent:** ONE warm color reserved for Sōji (ochre `#d8a657`) — a small warm figure against the cold world.
8. **Second accent:** muted red `#c25a4e` reserved for **danger/enemy tells + bosses-turn-red** feedback. Used nowhere decorative.
9. **Shrine warmth:** shrines emit the ONLY warm light in a cold zone (`#f2a65a` glow) — the emotional/audio anchor.
10. **Per-zone sub-palette:** 8–16 colors drawn from the master set, enforced by a single per-zone color-grade (LUT) later.
11. **Lighting > sprite detail:** iterate readability/mood in Godot (CanvasModulate + PointLight2D), not in the pixels.
12. **Readability is a first-class pillar:** nothing hits from off-screen; every attack telegraphed (windup pose + color-pop + audio).

## Locked master palette (hex)

Cold structural colors:
```
#0f1117  ink (darkest, outlines, clear color)
#1b1f2a  deep blue-grey
#2a3340  slate
#3c4a5a  steel blue
#55687a  muted blue-grey
#74879a  fog blue
#9fb0bd  pale cold highlight
#c0cad6  cold near-white
```
Sickly greens / muted purples (biome accents):
```
#1a2a26  deep green-black
#2f4438  muted forest
#4a6b54  sickly green
#6f8f6a  moss highlight
#2a2336  purple-black
#45375a  muted purple
#6b5a82  dusk purple
```
Warm accents (used sparingly, with intent):
```
#d8a657  Sōji ochre (player signature)
#e8c07d  Sōji light
#f2a65a  shrine glow (warm light)
#ffcf8a  shrine highlight
#c25a4e  danger / enemy-tell / boss-red
```

## Placeholder-art rule (current milestone)

No PixelLab assets yet. Prototype with **Godot-drawn shapes** (`ColorRect`, `Polygon2D`, `_draw()`) using the
palette above — this is enough to tune the COMBAT FEEL (the real goal of the slice). Swap to PixelLab sprites later
without touching gameplay code. Hero = ochre rectangle; enemies = muted-red-tinted shapes; shrine = warm glow.
