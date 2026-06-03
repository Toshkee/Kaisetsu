extends SceneTree
## Renders a scene for a moment and saves a PNG of the viewport. Parametrized via env vars:
##   SHOT_SCENE (default res://src/scenes/Game.tscn), SHOT_OUT (default res://_preview.png)
## Run NON-headless (needs the renderer):
##   SHOT_SCENE=... SHOT_OUT=... Godot --path . --script res://tools/screenshot.gd

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene_path := OS.get_environment("SHOT_SCENE")
	if scene_path == "":
		scene_path = "res://src/scenes/Game.tscn"
	var out_path := OS.get_environment("SHOT_OUT")
	if out_path == "":
		out_path = "res://_preview.png"
	var node: Node = load(scene_path).instantiate()
	root.add_child(node)
	for i in 95:
		await process_frame
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(out_path)
	print("SCREENSHOT SAVED ", out_path)
	quit()
