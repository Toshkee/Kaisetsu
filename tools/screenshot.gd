extends SceneTree
## Renders Main.tscn for a moment and saves a PNG preview of the 640x360 viewport.
## Run NON-headless (needs the renderer):
##   Godot --path . --script res://tools/screenshot.gd --quit-after 90

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://src/scenes/Main.tscn").instantiate()
	root.add_child(main)
	for i in 50:
		await process_frame
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png("res://_preview.png")
	print("SCREENSHOT SAVED res://_preview.png")
	quit()
