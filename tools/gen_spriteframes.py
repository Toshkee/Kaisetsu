#!/usr/bin/env python3
"""Generate a Godot SpriteFrames .tres for Soji from the downloaded PixelLab frames.
Re-run whenever new animations (e.g. death) are downloaded into assets/sprites/soji/<anim>/.
"""
import os, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOJI = os.path.join(ROOT, "assets", "sprites", "soji")

# (folder, animation_name, fps, loop)
ANIMS = [
    ("idle", "idle", 6.0, True),
    ("walk", "walk", 10.0, True),
    ("attack", "attack", 14.0, False),
    ("dodge", "dodge", 16.0, False),
    ("hurt", "hurt", 12.0, False),
    ("death", "death", 8.0, False),
]

ext_lines, anim_blocks, idc = [], [], 0
for folder, name, fps, loop in ANIMS:
    d = os.path.join(SOJI, folder)
    files = sorted(glob.glob(os.path.join(d, "*.png")),
                   key=lambda p: int(os.path.splitext(os.path.basename(p))[0]))
    if not files:
        continue  # skip animations not yet downloaded (e.g. death still rendering)
    frame_entries = []
    for f in files:
        rid = f"f{idc}"
        rel = "res://" + os.path.relpath(f, ROOT).replace(os.sep, "/")
        ext_lines.append(f'[ext_resource type="Texture2D" path="{rel}" id="{rid}"]')
        frame_entries.append(f'{{"duration": 1.0, "texture": ExtResource("{rid}")}}')
        idc += 1
    anim_blocks.append(
        '{\n"frames": [' + ", ".join(frame_entries) + '],\n"loop": '
        + ("true" if loop else "false") + ',\n"name": &"' + name + '",\n"speed": ' + str(fps) + '\n}'
    )

out = [f'[gd_resource type="SpriteFrames" load_steps={idc + 1} format=3]', ""]
out += ext_lines
out += ["", "[resource]", "animations = [" + ", ".join(anim_blocks) + "]", ""]
with open(os.path.join(SOJI, "soji_frames.tres"), "w") as fh:
    fh.write("\n".join(out))
print(f"wrote soji_frames.tres: {idc} frames across {len(anim_blocks)} animations")
