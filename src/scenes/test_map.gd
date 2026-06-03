extends Node2D
## Playable test level built from a PixelLab map export ("Untitled Map").
##
## PixelLab's map export ships the painted terrain as a flat image (map-composite.png) with NO
## collision data in its JSON. So the visual is just that composite sprite, and we rebuild solid
## ground from it: each entry in RUNS is a horizontal run of filled 32px cells (extracted from the
## composite's opaque cells, a 47x11 grid). At load we turn each run into one box collider on the
## terrain physics layer (layer 1), which is what the Player's mask collides with.
##
## This is a throwaway harness to FEEL the movement on real art — not the final level pipeline
## (that will be LDtk -> Godot TileMapLayer with authored collision).

const CELL := 32

# [col_start, col_end, row] inclusive tile coords of solid terrain.
const RUNS := [
	[43, 46, 0],
	[28, 34, 1], [43, 46, 1],
	[26, 34, 2], [42, 46, 2],
	[25, 34, 3], [41, 46, 3],
	[24, 37, 4], [40, 46, 4],
	[0, 7, 5], [18, 37, 5], [39, 46, 5],
	[8, 27, 6], [35, 46, 6],
	[8, 17, 7], [37, 46, 7],
	[37, 46, 8],
	[37, 42, 9],
	[39, 42, 10],
]

@onready var _solid: StaticBody2D = $Solid

func _ready() -> void:
	for run in RUNS:
		var a: int = run[0]
		var b: int = run[1]
		var r: int = run[2]
		var n := b - a + 1
		var shape := RectangleShape2D.new()
		shape.size = Vector2(n * CELL, CELL)
		var cs := CollisionShape2D.new()
		cs.shape = shape
		# Box centre, in the same world space as the composite sprite (top-left at origin).
		cs.position = Vector2(a * CELL + n * CELL / 2.0, r * CELL + CELL / 2.0)
		_solid.add_child(cs)
