extends SceneTree
## Builds a SpriteFrames resource from LuizMelo's "Martial Hero" (CC0) horizontal strip sheets.
## Each sheet is N frames of 200x200 laid left-to-right. Animation names match the player's
## STATE_ANIM contract (idle/walk/jump/fall/attack/hurt/death; attack2 kept for future combos).
## Run: Godot --headless --path . --script res://tools/build_martial_hero.gd

const DIR := "res://assets/sprites/martial_hero/"
const OUT := "res://assets/sprites/martial_hero/martial_hero_frames.tres"
const FW := 200

const SHEETS := [
	{"anim": "idle", "file": "Idle.png", "loop": true, "fps": 10.0},
	{"anim": "walk", "file": "Run.png", "loop": true, "fps": 12.0},
	{"anim": "jump", "file": "Jump.png", "loop": false, "fps": 8.0},
	{"anim": "fall", "file": "Fall.png", "loop": false, "fps": 8.0},
	{"anim": "attack", "file": "Attack1.png", "loop": false, "fps": 14.0},
	{"anim": "attack2", "file": "Attack2.png", "loop": false, "fps": 14.0},
	{"anim": "hurt", "file": "Take Hit.png", "loop": false, "fps": 12.0},
	{"anim": "death", "file": "Death.png", "loop": false, "fps": 8.0},
]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var sf := SpriteFrames.new()
	for s in SHEETS:
		var tex := load(DIR + s["file"]) as Texture2D
		if tex == null:
			print("MISSING ", s["file"])
			continue
		var frames := int(tex.get_width() / FW)
		var anim: String = s["anim"]
		sf.add_animation(anim)
		sf.set_animation_loop(anim, s["loop"])
		sf.set_animation_speed(anim, s["fps"])
		for i in frames:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * FW, 0, FW, tex.get_height())
			sf.add_frame(anim, at)
	if sf.has_animation("default"):
		sf.remove_animation("default")
	var err := ResourceSaver.save(sf, OUT)
	print("SAVED ", OUT, " err=", err, "  anims=", sf.get_animation_names())
	quit(0 if err == OK else 1)
