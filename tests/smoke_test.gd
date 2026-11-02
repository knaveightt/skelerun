extends SceneTree
## Run with a graphical display. Uses an isolated in-memory session.
const Main = preload("res://scenes/main.tscn")
const Session = preload("res://scripts/session.gd")
var app
var failures = 0
func check(value, message):
	if not value:
		failures += 1
		push_error(message)
func key(code):
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	app._unhandled_input(event)
func click(event):
	event.pressed = true
	app._unhandled_input(event)
	event.pressed = false
	app._unhandled_input(event)
func capture(name):
	if DisplayServer.get_name() == "headless": return
	app.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	image.save_png("user://preview_"+name+".png")
func _initialize(): call_deferred("run_test")
func run_test():
	app = Main.instantiate()
	root.add_child(app)
	await process_frame
	app.session = Session.new("",false)
	app.set_process(false)
	await capture("cell")
	key(KEY_B)
	check(not app.session.blacksmith_unlocked,"cannot afford workshop")
	key(KEY_ENTER)
	check(app.dungeon_selection and app.session.scene=="cell","leaving cell opens selection")
	await capture("dungeon_selection")
	key(KEY_ESCAPE)
	check(not app.dungeon_selection and app.session.scene=="cell","selection can be canceled")
	key(KEY_ENTER)
	key(KEY_DOWN)
	check(app.selected_dungeon==1,"selection arrows")
	key(KEY_1)
	key(KEY_ENTER)
	check(app.session.scene=="run" and app.game.dungeon_index==0,"enter starts selected dungeon")
	var game = app.game
	for x in range(10):
		if x<3 or x>6: game.board[19][x] = "S"
	game.piece = {"kind":"I","x":3,"y":18,"rotation":0}
	key(KEY_SPACE)
	app.paused = false
	app._process(0.016)
	check(game.resources.Iron==60 and game.resources.Platinum==40,"UI drop collects resources")
	await capture("run")
	key(KEY_P)
	check(app.paused,"pause")
	await capture("pause")
	key(KEY_P)
	game.lose("Smoke test defeat")
	app._process(0.016)
	check(app.session.scene=="cell" and app.session.summary.loot==100,"death brings materials home")
	await capture("return")
	app.session.resources.Iron = 550
	app.session.resources.Copper = 600
	key(KEY_B)
	check(app.session.blacksmith_unlocked and app.session.resources.Iron==50 and app.session.resources.Copper==100,"UI unlock")
	await capture("unlocked")
	root.size = Vector2i(800,1000)
	await process_frame
	# Godot's canvas stretch transforms mouse coordinates into the 500x800 viewport.
	var mouse = InputEventMouseButton.new()
	mouse.position = app.get_global_transform_with_canvas()*Vector2(250,706)
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	click(mouse)
	check(app.dungeon_selection,"resized mouse click opens selection")
	mouse.position = app.get_global_transform_with_canvas()*Vector2(250,126+5*88+35)
	click(mouse)
	check(app.selected_dungeon==5,"mouse selects throne room")
	mouse.position = app.get_global_transform_with_canvas()*Vector2(250,700)
	click(mouse)
	check(app.session.scene=="run" and app.game.dungeon_index==5,"mouse begins chosen run")
	app.game.resources.Tin += 20
	app.game.loot.Tin += 20
	var stash = app.session.resources.duplicate()
	key(KEY_P)
	mouse.position = app.get_global_transform_with_canvas()*Vector2(250,427)
	click(mouse)
	check(not app.paused and app.session.scene=="run","pause continue button resumes run")
	key(KEY_P)
	await capture("pause_abandon")
	mouse.position = app.get_global_transform_with_canvas()*Vector2(250,479)
	click(mouse)
	check(app.session.scene=="cell" and not app.paused,"pause abandon button returns to cell")
	check(app.session.resources==stash and app.session.summary.loot==20,"abandon keeps gathered materials and run summary")
	var time_before_return = app.game.elapsed
	app._process(0.1)
	check(app.game.elapsed==time_before_return,"abandoned run no longer advances")
	key(KEY_ENTER)
	key(KEY_ENTER)
	key(KEY_P)

	key(KEY_R)
	check(app.session.scene=="cell" and not app.paused,"pause R abandons run")
	for destination in range(6):
		key(KEY_ENTER)
		key(KEY_1+destination)
		key(KEY_ENTER)
		check(app.game.dungeon_index==destination,"all six choices begin runs")
		for number in range(app.game.dungeon().enemies.size()):
			app.game.enemy_index = number
			app.game.new_enemy()
			app.paused = false
			await capture("dungeon_%s_foe_%s" % [destination,number])
		app.game.lose("test")
		app.paused = false
		app._process(0.016)
		check(app.session.scene=="cell","every destination returns on loss")
	key(KEY_R)
	check(app.reset_confirmation,"cell R requests confirmation")
	check(app.session.blacksmith_unlocked and app.session.resources.Iron==50,"prompt does not erase progress")
	await capture("reset_confirmation")
	key(KEY_ENTER)
	key(KEY_B)
	check(app.session.scene=="cell" and app.reset_confirmation,"modal blocks cell actions")
	mouse.position = app.get_global_transform_with_canvas()*Vector2(250,706)
	click(mouse)
	check(app.session.scene=="cell" and app.reset_confirmation,"modal blocks dungeon mouse click")
	key(KEY_ESCAPE)
	check(not app.reset_confirmation and app.session.blacksmith_unlocked,"escape cancels safely")
	key(KEY_R)
	key(KEY_N)
	check(not app.reset_confirmation and app.session.resources.Iron==50,"N cancels safely")
	key(KEY_R)
	mouse.position = app.get_global_transform_with_canvas()*Vector2(150,465)
	click(mouse)
	check(not app.reset_confirmation and app.session.blacksmith_unlocked,"cancel button")
	key(KEY_R)
	mouse.position = app.get_global_transform_with_canvas()*Vector2(340,465)
	click(mouse)
	check(not app.reset_confirmation and not app.session.blacksmith_unlocked and app.game==null,"reset button clears progress")
	for value in app.session.resources.values(): check(value==0,"UI clears each resource")
	app.session.resources.Tin = 10
	key(KEY_R)
	key(KEY_Y)
	check(app.session.resources.Tin==0 and app.session.summary.is_empty(),"Y confirms reset")
	await capture("reset_complete")
	key(KEY_ENTER)
	key(KEY_ENTER)
	key(KEY_R)
	check(app.session.scene=="cell" and not app.reset_confirmation,"run R still returns to cell")
	key(KEY_ENTER)
	key(KEY_ENTER)
	var elapsed = app.game.elapsed
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	app._process(0.1)
	check(app.game.elapsed==elapsed,"pause freezes survival pressure")
	check(app.paused,"focus loss pauses")
	print("Godot graphical smoke: %s failures. Previews: %s" % [failures,OS.get_user_data_dir()])
	app.session.save_path = ""
	app.queue_free()
	await process_frame
	# Let the audio thread release stopped stream playbacks before engine shutdown.
	await create_timer(0.1).timeout
	quit(0 if failures==0 else 1)
