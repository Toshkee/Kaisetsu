# KAISETSU — Parallax & Tileset Guide (Godot 4.6, beginner-friendly)

> **Goal:** take the **tilesets** and **parallax background strips** you're making in PixelLab and wire them into
> the game. Two recipes: a gentle **parallax** warm-up (half-day, purely additive) and the bigger **tileset →
> TileMapLayer** migration (full-day, the real unlock for building Zones 1–5).
>
> **Where to do this:** `src/scenes/MezameShore.tscn` — the **live room** (Play goes Title → Main → **MezameShore**).
> The old flat-image `Map.tscn` / `map.gd` map (hand-baked `RUNS` colliders) was **deleted** on 2026-06-04, and
> `assets/maps/` is now empty and ready for your new tilesets.

The project is already configured pixel-perfect, so you don't fight blur:
`default_texture_filter = 0` (Nearest), `snap_2d_transforms/vertices = true`, 640×360 viewport, integer stretch.
**Tile size for everything: 32×32 px** (matches the existing grid and Sōji's ~1.75-tile-tall body).

---

## Part 0 — PixelLab export checklist (do this first, in PixelLab)

**Lock ONE cold/muted master palette and pass it to every generation** (tiles, parallax, props) so the world reads as
one place. Sōji's warm ochre is meant to be the *only* warm thing against the cold ground.

**Terrain tileset** (`mcp__pixellab__create_sidescroller_tileset`):
- Tile size **32×32**.
- Core set: ground **top/cap**, **dirt/stone fill**, **left edge**, **right edge**, **inner corners**, and a **slope**
  if you can get one (slopes are the payoff tiles the old `RUNS` array could never do).
- Export the atlas PNG to `res://assets/maps/grass/tileset_grass.png` (create the `grass/` folder — `assets/maps/` is empty now).

**Parallax strips** (separate depth layers, back → front):
- Each strip **horizontally seamless** (tileable left↔right) or you'll see a vertical seam every repeat.
- Each strip **at least 360–512 px tall** to cover the 360-px viewport height.
- Make them **progressively cooler / darker / lower-contrast the further back** they go (far = most desaturated,
  fewest details). This reinforces depth and the MOONSHIRE melancholy.
- Suggested four: `far_sky.png`, `far_trees.png`, `mid_forest.png`, `near_mist.png` →
  save under `res://assets/maps/grass/parallax/`.
- **Export at native low-res — do NOT upscale.** The game renders at 640×360 with integer stretch, so 1 art pixel =
  1 screen pixel. Upscaled art double-scales and breaks the crisp grid.

**Every PNG, before use:** click it in Godot's *FileSystem* dock → **Import** tab → set **Mipmaps > Generate = OFF**,
**Compress > Mode = Lossless** → click **Reimport**. (Filtering is already global Nearest — leave it.)

---

## Part 1 — Parallax background (warm-up, ~half-day, purely additive)

We use **`Parallax2D`** (one node per layer), the modern Godot 4.3+ node — **not** the legacy
`ParallaxBackground` + `ParallaxLayer` pair (which fights the Camera2D limits that `game_camera.gd` uses). `Parallax2D`
auto-detects the active camera (the camera lives on the Player), so there's almost no wiring.

### Layer plan

| Node name | `scroll_scale` (x, y) | `z_index` | Strip |
|---|---|---|---|
| `PX_FarSky` | (0.05, 0.05) | -120 | `far_sky.png` (nearly static) |
| `PX_FarTrees` | (0.20, 0.10) | -110 | `far_trees.png` (darkest) |
| `PX_MidForest` | (0.45, 0.20) | -105 | `mid_forest.png` |
| `PX_NearMist` | (0.70, 0.35) | -101 | `near_mist.png` (just behind play) |
| *(optional)* `PX_Foreground` | (1.15, 0.50) | **+10** | near branches/grass — drifts *faster*, passes **in front** |

Rule of thumb: **`scroll_scale` < 1 = looks far away & moves less; = 1 moves with the world; > 1 = foreground that
overtakes the camera.** Keep the **y** value small (0.05–0.35) so jumping doesn't make the sky lurch.

### Steps (in `MezameShore.tscn`)

1. Open `MezameShore.tscn`. The current fake-depth nodes are `Backdrop` (Polygon2D, z=-100), `FogFar` (z=-50), and
   `FogNear` (z=-40). Leave them for now; you'll delete them at the end once parallax looks better.
2. Select the root `MezameShore` node → **Add Child Node → `Parallax2D`**. Rename it `PX_FarSky`.
3. In the Inspector: **Scroll → Scale = (0.05, 0.05)**. **Repeat → Size = (W, 0)** where **W = the strip's pixel
   width** (e.g. `(640, 0)`) — this tiles it sideways only. Set **z_index = -120** (CanvasItem → Ordering).
4. Give it a sprite: select `PX_FarSky` → **Add Child Node → `Sprite2D`** → drag `far_sky.png` onto **Texture** →
   **uncheck `Centered`** (so its top-left is the origin). Nudge the Sprite2D's Y so the strip sits where you want the
   horizon. **Leave its Texture Filter = Inherit** (don't set Linear).
5. Repeat steps 2–4 for `PX_FarTrees`, `PX_MidForest`, `PX_NearMist` using the table values.
6. *(Optional)* Add `PX_Foreground` with scale (1.15, 0.5), **z_index = +10**, and a mostly-transparent near strip so
   it passes in front of Sōji. Keep it sparse so it never hides gameplay.
7. Press **F5**. Walk left/right: far layers should crawl, near layers track closer to you. If a layer doesn't move,
   confirm it's a `Parallax2D` (not a plain Sprite2D) and `scroll_scale` is non-zero.
8. Once it reads well, **delete `Backdrop`, `FogFar`, `FogNear`** (the flat Polygon2D bands). Keep `CanvasModulate`
   (the mood tint), `Mist` (particles), and `Silhouettes` (or move the ship/dock silhouettes onto a near parallax layer).

### Parallax gotchas
- **Every background layer needs a NEGATIVE `z_index`** (terrain is at z=0). Only the optional foreground gets positive.
- **Seamless or bust:** if you see a vertical seam every repeat, the strip's left/right edges don't match — fix in
  PixelLab. Set **only** the x of Repeat Size (leave y = 0) so it tiles sideways, not vertically.
- **Strips must be the right shape:** a single full-screen still (e.g. a 1080p background) won't tile — you need short,
  horizontally-seamless strips ~360–512 px tall. Generate these fresh in PixelLab.
- **Don't add a per-node `texture_filter = 1` (Linear)** to your sprites — it blurs pixel art. Leave Texture Filter at
  **Inherit** (the project default is global Nearest).

---

## Part 2 — Tileset → TileMapLayer (the big one, ~full day)

This replaces the hand-placed collision boxes in `MezameShore` with **collision that comes free from the tiles** —
so the floor you *see* and the floor you *stand on* can never drift apart, and you can author slopes/ledges visually.

### Steps

1. **Import** `tileset_grass.png` pixel-perfect (Part 0: Mipmaps OFF, Lossless, Reimport).
2. In `MezameShore.tscn`, select the root → **Add Child Node → `TileMapLayer`** (the 4.3+ node — *not* the old
   `TileMap`). Name it `Terrain_Tiles`.
3. With it selected, Inspector → **Tile Set → `<empty>` → New TileSet**. Click the new resource; confirm
   **Tile Size = 32×32** (change it if it defaulted to 16×16).
4. Open the **TileSet panel** (bottom of the editor) → **Tiles** tab → **`+` (Add Source) → Atlas** → drag
   `tileset_grass.png` in → when asked "automatically create tiles?" click **Yes** (it slices into 32×32 tiles).
5. **Add collision that matches the player.** Select the TileSet resource → expand **Physics Layers** → Add Element →
   set its **Collision Layer to bit 1 = `world`** only. *(Why: the Player body has `collision_mask = 517 = bits
   1+3+10`, so a tile collider on layer 1 is detected with **zero** player-code changes.)*
6. **Author per-tile collision:** TileSet panel → **Select** tab → pick the Physics Layer → select your solid ground
   tiles → press **F** to add a full-cell rectangle collider to each. For **slopes/ledge edges**, draw the collision
   polygon by hand to match the *visible* surface (else Sōji floats or sinks).
7. *(Optional, recommended)* Add a **second** Physics Layer on **bit 10 = `one_way`** for thin drop-through platforms,
   and enable **One Way Collision** on those tiles. The player already masks bit 10, so it just works.
8. *(Optional, from the plan)* Add **Custom Data Layers** on the TileSet — `hazard` (bool), `is_ladder` (bool),
   `sfx_material` (string) — and set them per tile. Code can later read
   `get_cell_tile_data(coords).get_custom_data("hazard")`. Nearly free to define now, impossible with the flat image.
9. **Paint the room.** Select `Terrain_Tiles`, pick the atlas in the bottom panel, and paint the floor / walls / ledge
   to match the existing placeholder footprints (see reference below).
10. **Delete the placeholders.** Once tiles are painted and you collide with them, delete the whole **`Terrain`
    `StaticBody2D`** (its `FloorVisual`/`FloorEdge`/`WallLeftVisual`/`WallRightVisual`/`LedgeVisual`/`LedgeEdge`
    Polygon2D visuals **and** its `Floor`/`WallLeft`/`WallRight`/`Ledge` CollisionShape2D nodes). Keep `PlayerSpawn`,
    `Shrine`, and the two `DriftHusk`s. Press Play and walk — you should stand on the painted tiles.

### Layout reference (current MezameShore footprints, for painting)
- **Floor:** top surface at **y = 0**, spanning roughly **x = -240 → 1200** (~45 tiles wide).
- **Left wall:** vertical column around **x = -240**; **Right wall:** around **x = 1200** (each ~14 tiles tall).
- **Ledge:** a small platform ~**40 px above the floor** on the right, **x ≈ 850 → 1110** (~8 tiles).
- Sōji spawns at **(40, 0)**, the Shrine sits at **(-100, 0)**.

### No old collision to migrate
The previous flat-image map (`Map.tscn` + `map.gd`'s hand-baked `RUNS` colliders) has been **removed**, so there's
nothing to port. You're simply authoring `MezameShore`'s terrain fresh as tiles — the TileMapLayer's per-tile collision
replaces the room's placeholder `Polygon2D` visuals + hand-placed `CollisionShape2D` boxes (step 10).

### Tileset gotchas
- **Collision layer MUST be bit 1 (`world`).** Wrong bit = Sōji falls through the floor.
- **TileMapLayer, not the legacy TileMap node.** One layer per node; add more TileMapLayers for background/foreground
  tile detail if you want.
- **Keep 32 everywhere:** PixelLab export, TileSet Tile Size, and the project's grid must all agree, or tiles misalign.
- **Atlas seams:** Nearest + Mipmaps-OFF fixes most. If a faint line persists at tile borders, enable the atlas
  source's **Use Texture Padding**.
- **`F` adds a square collider** — fine for blocks, but slopes/curved tiles need the polygon drawn by hand.

---

## Suggested order for today
1. ✅ Boot scene fixed (done — Play now launches the real game).
2. **Parallax first** (Part 1) — additive, no collision to break, instant atmosphere payoff. Confidence warm-up.
3. **Then the tileset** (Part 2) — the bigger skill, and the real unlock for every future zone. The finished
   MezameShore (tiled floor + parallax) becomes your **template** for Zones 1–5.

## PixelLab tool reference
- `mcp__pixellab__create_sidescroller_tileset` — terrain tiles **and** background strips (32×32 tiles; tall seamless
  strips for parallax).
- `mcp__pixellab__list_sidescroller_tilesets` / `get_sidescroller_tileset` — fetch & re-import iterations without
  regenerating; `delete_sidescroller_tileset` to prune rejects.
- Keep the chosen palette swatch handy so later zones (Haikyo plains, Midori jungle) can share the master palette.
