extends Node2D
## Main playable map, built from a PixelLab map export ("Untitled Map", 52x24 @ 32px).
##
## PixelLab ships terrain as one flat image (map-composite.png) with NO collision in its JSON,
## so we rebuild solid ground from it: each entry in RUNS is a horizontal run of filled 32px
## cells, derived offline from the composite's opaque terrain cells. At load each run becomes one
## box collider on the world physics layer (layer 1) — the layer the Player's mask collides with.
##
## The baked Sōji concept sprite that shipped in the corner of the export was erased from the
## composite (we already have a real Player), so what remains is pure terrain + the forest backdrop.

const CELL := 32

# [col_start, col_end, row] inclusive tile coords of solid terrain (character cell excluded).
const RUNS := [
	[1, 3, 2], [30, 32, 2],
	[1, 5, 3], [30, 34, 3],
	[33, 39, 4],
	[7, 10, 5], [13, 14, 5], [17, 20, 5], [22, 25, 5], [38, 42, 5],
	[7, 10, 6], [13, 14, 6], [17, 20, 6], [22, 27, 6], [40, 42, 6],
	[13, 14, 7], [17, 20, 7], [22, 27, 7], [42, 45, 7],
	[26, 32, 8], [45, 45, 8],
	[26, 37, 9], [45, 45, 9],
	[33, 37, 10], [45, 45, 10],
	[45, 45, 11],
	[41, 45, 12],
	[39, 43, 13],
	[31, 40, 14],
	[28, 30, 15],
	[28, 30, 16],
	[28, 30, 17],
	[28, 30, 18],
	[22, 27, 19],
	[11, 21, 22], [32, 32, 22], [35, 36, 22], [38, 38, 22], [40, 41, 22],
	[0, 51, 23],
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
