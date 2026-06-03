extends SceneTree
## Prints the non-transparent bounding box of sprite frames so we can align feet to the origin.
func _initialize() -> void:
	var paths := [
		"res://assets/sprites/soji/idle/0.png",
		"res://assets/sprites/soji/walk/0.png",
		"res://assets/sprites/soji/walk/3.png",
		"res://assets/sprites/soji/attack/3.png",
		"res://assets/sprites/soji/dodge/3.png",
		"res://assets/sprites/soji/east.png",
	]
	for p in paths:
		var img := Image.load_from_file(ProjectSettings.globalize_path(p))
		if img == null:
			print(p, "  FAILED")
			continue
		var r := img.get_used_rect()
		var cx := r.position.x + r.size.x / 2.0
		var feet := r.position.y + r.size.y
		print(p.get_file(), "  size=", img.get_size(), "  used=", r, "  center_x=", cx, "  feet_y=", feet)
	quit()
