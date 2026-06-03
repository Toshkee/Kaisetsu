extends SceneTree
## Headless smoke test for the Mezame Shore slice. Loads Main.tscn, runs a few frames, then asserts
## the integration wiring actually happened. Run:
##   Godot --headless --path . --script res://tools/smoke_test.gd
## Prints PASS/FAIL per check and a final SMOKE line; exits 0 on all-pass, 1 otherwise.

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main_scene: PackedScene = load("res://src/scenes/Main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	# Let _ready + several physics frames run so the player settles on the floor.
	for i in 30:
		await process_frame
	await create_timer(0.3).timeout

	var checks: Array = []
	var players := get_nodes_in_group("player")
	checks.append(["player spawned & in 'player' group", players.size() == 1])
	var enemies := get_nodes_in_group("enemy")
	checks.append(["two Drift Husks present", enemies.size() == 2])

	var p: Node = players[0] if players.size() > 0 else null
	checks.append(["player exposes Health/Stamina/Focus", p != null and p.get("health") != null and p.get("stamina") != null and p.get("focus") != null])
	checks.append(["player rests on floor (didn't fall through)", p != null and p.global_position.y < 40.0 and p.global_position.y > -40.0])
	checks.append(["player camera limits applied", p != null and p.get("camera") != null and p.camera.limit_right == 1200])
	checks.append(["health full at spawn", p != null and p.health.current_health == p.health.max_health])

	var shrine_ok := main.find_child("Shrine", true, false) != null
	checks.append(["shrine present in room", shrine_ok])

	var all_pass := true
	for c in checks:
		print(("PASS  " if c[1] else "FAIL  ") + str(c[0]))
		if not c[1]:
			all_pass = false
	print("SMOKE: " + ("ALL PASS" if all_pass else "SOME FAILED"))
	quit(0 if all_pass else 1)
