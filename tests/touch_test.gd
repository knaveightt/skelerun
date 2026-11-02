extends SceneTree
## Native InputEventScreenTouch/Drag integration; no keyboard or mouse required.
const Main = preload("res://scenes/main.tscn")
const Session = preload("res://scripts/session.gd")
var app
var phone
var checks = 0
var failures = 0
func check(value,message):
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func touch(point: Vector2, pressed: bool, id: int = 0, canceled: bool = false):
	var event = InputEventScreenTouch.new()
	event.index = id
	event.position = app.get_global_transform_with_canvas()*point
	event.pressed = pressed
	event.canceled = canceled
	app._unhandled_input(event)
func drag(point: Vector2, id: int = 0):
	var event = InputEventScreenDrag.new()
	event.index = id
	event.position = app.get_global_transform_with_canvas()*point
	app._unhandled_input(event)
func tap(point: Vector2, id: int = 0):
	touch(point,true,id)
	touch(point,false,id)
func button(rect: Rect2): tap(rect.get_center())
func swipe(start: Vector2, finish: Vector2, id: int = 0):
	touch(start,true,id)
	drag(finish,id)
	touch(finish,false,id)
func clean_piece(kind: String = "T"):
	app.pointer_input.clear()
	app.game.board.clear()
	for y in range(20): app.game.board.append(app.game.empty_row())
	app.game.status = "playing"
	app.game.spawn(kind)
	app.game.hold_used = false
	app.paused = false
func capture(name):
	if DisplayServer.get_name()=="headless": return
	app.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	phone.get_texture().get_image().save_png("user://touch_"+name+".png")
func _initialize(): call_deferred("run_test")
func run_test():
	# Offscreen phone viewport avoids desktop tiling and embedded-window DPI.
	phone = SubViewport.new()
	phone.world_2d = World2D.new()
	phone.size = Vector2i(360,800)
	phone.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(phone)
	app = Main.instantiate()
	phone.add_child(app)
	app.scale = Vector2(0.72,0.72)
	app.position = Vector2(0,112)
	await process_frame
	app.set_process(false)
	app.session = Session.new("",false)
	check(phone.size==Vector2i(360,800),"phone-sized viewport")
	button(app.CELL_SETTINGS)
	check(app.settings_open and app.touch_mode,"touch opens cell settings")
	await capture("settings_phone")
	var was_muted = app.muted
	button(app.SETTINGS_SOUND)
	check(app.muted!=was_muted,"touch sound toggle in settings")
	button(app.SETTINGS_RESET)
	check(app.reset_confirmation and not app.settings_open,"touch requests reset confirmation")
	await capture("reset_phone")
	button(app.RESET_CANCEL)
	check(not app.reset_confirmation,"touch cancels reset")
	app.session.resources.Iron = 500
	app.session.resources.Copper = 500
	tap(Vector2(315,280))
	check(app.session.blacksmith_unlocked and app.session.resources.Iron==0,"tap scene workshop unlocks blacksmith")
	tap(Vector2(250,590))
	check(app.cell_message.contains("open"),"tap card inspects unlocked workshop")
	await capture("cell_phone")
	button(app.CELL_SETTINGS)
	button(app.SETTINGS_RESET)
	touch(app.RESET_CANCEL.get_center(),true)
	drag(app.RESET_CONFIRM.get_center())
	touch(app.RESET_CONFIRM.get_center(),false)
	check(app.reset_confirmation and app.session.blacksmith_unlocked,"drag between reset buttons cannot confirm")
	button(app.RESET_CONFIRM)
	check(not app.session.blacksmith_unlocked and app.game==null,"touch confirms reset")
	for value in app.session.resources.values(): check(value==0,"touch reset zeros resource")
	button(app.CELL_SETTINGS)
	button(app.SETTINGS_BACK)
	check(not app.settings_open,"touch settings back")
	# Button actions happen on release, not on initial contact.
	touch(app.CELL_LEAVE.get_center(),true)
	check(not app.dungeon_selection,"touch-down does not activate a menu")
	touch(app.CELL_LEAVE.get_center(),false)
	check(app.dungeon_selection,"touch-up opens destinations")
	touch(Vector2(250,160),true)
	drag(Vector2(250,250))
	touch(Vector2(250,250),false)
	check(app.selected_dungeon==0,"drag between destination cards does not select")
	button(app.SELECT_BACK)
	check(not app.dungeon_selection,"touch destination back")
	tap(Vector2(430,270))
	check(app.dungeon_selection,"tap stairs opens destinations")
	for i in range(6):
		tap(Vector2(250,160+i*88))
		check(app.selected_dungeon==i,"touch selects each destination")
	await capture("selection_phone")
	button(app.SELECT_BEGIN)
	check(app.session.scene=="run" and app.game.dungeon_index==5,"touch begins chosen run")
	clean_piece()
	var x = app.game.piece.x
	touch(Vector2(237,500),true)
	drag(Vector2(287,500))
	check(app.game.piece.x==x+2,"horizontal swipe moves two columns immediately")
	drag(Vector2(262,500))
	touch(Vector2(262,500),false)
	check(app.game.piece.x==x+1,"horizontal swipe can reverse and release does not repeat")
	check(app.game.piece.rotation==0,"horizontal swipe does not rotate")
	swipe(Vector2(237,500),Vector2(246,505))
	check(app.game.piece.x==x+1,"small finger jitter ignored")
	swipe(Vector2(237,500),Vector2(267,530))
	check(app.game.piece.x==x+1 and app.game.piece.rotation==0,"ambiguous diagonal ignored")
	clean_piece()
	touch(Vector2(237,500),true)
	drag(Vector2(287,500))
	var serial = app.game.piece_serial
	drag(Vector2(300,650))
	touch(Vector2(300,650),false)
	check(app.game.piece_serial==serial,"horizontal gesture stays horizontal instead of dropping")
	clean_piece()
	touch(Vector2(237,520),true)
	drag(Vector2(237,460))
	check(app.game.piece.rotation==1,"up swipe rotates clockwise")
	drag(Vector2(237,410))
	touch(Vector2(237,410),false)
	check(app.game.piece.rotation==1,"up swipe rotates only once")
	button(app.RUN_REVERSE)
	check(app.game.piece.rotation==0,"touch reverse rotation button")
	clean_piece()
	serial = app.game.piece_serial
	touch(Vector2(237,420),true)
	drag(Vector2(237,490))
	check(app.game.piece_serial==serial+1,"down swipe hard-drops immediately")
	drag(Vector2(237,640))
	touch(Vector2(237,640),false)
	check(app.game.piece_serial==serial+1,"continued down swipe never drops the next piece")
	var blocks = 0
	for row in app.game.board:
		for kind in row:
			if kind!="": blocks += 1
	check(blocks==4,"one hard drop places four blocks")
	clean_piece()
	serial = app.game.piece_serial
	touch(Vector2(237,420),true)
	touch(Vector2(237,490),false)
	check(app.game.piece_serial==serial+1,"release position handles a swipe without intermediate drag events")
	clean_piece()
	app.game.drop()
	var active = app.game.piece.kind
	tap(Vector2(57,290))
	check(app.game.held==active and app.game.hold_used,"tap hold stores active piece")
	serial = app.game.piece_serial
	tap(Vector2(57,290))
	check(app.game.piece_serial==serial,"hold remains once per placement")
	app.game.drop()
	tap(Vector2(57,290))
	check(app.game.piece.kind==active,"tap hold swaps stored piece after placement")
	clean_piece()
	var initial_y = app.game.piece.y
	touch(app.RUN_SOFT.get_center(),true,1)
	check(app.pointer_input.soft_drop_active(),"press-and-hold soft drop begins")
	app._process(0.1)
	check(app.game.piece.y>=initial_y+2,"held soft drop speeds gravity")
	x = app.game.piece.x
	swipe(Vector2(237,500),Vector2(262,500),2)
	check(app.game.piece.x==x+1 and app.pointer_input.soft_drop_active(),"second finger can move while soft drop is held")
	touch(app.RUN_SOFT.get_center(),false,1)
	check(not app.pointer_input.soft_drop_active(),"release stops soft drop")
	touch(app.RUN_SOFT.get_center(),true,1)
	drag(app.RUN_SOFT.get_center()+Vector2(-55,0),1)
	check(not app.pointer_input.soft_drop_active(),"sliding off soft drop stops it")
	touch(app.RUN_SOFT.get_center(),false,1)
	clean_piece()
	touch(Vector2(237,500),true,1)
	touch(Vector2(237,500),true,2)
	x = app.game.piece.x
	drag(Vector2(287,500),2)
	check(app.game.piece.x==x,"second board finger cannot take over gesture")
	drag(Vector2(262,500),1)
	check(app.game.piece.x==x+1,"original board finger retains control")
	touch(Vector2(262,500),false,1)
	touch(Vector2(287,500),false,2)
	clean_piece()
	touch(Vector2(237,500),true)
	app.game.drop()
	x = app.game.piece.x
	drag(Vector2(312,500))
	touch(Vector2(312,500),false)
	check(app.game.piece.x==x,"gesture from locked piece cannot move next piece")
	clean_piece()
	serial = app.game.piece_serial
	touch(Vector2(237,500),true)
	touch(Vector2(237,570),false,0,true)
	check(app.game.piece_serial==serial and app.pointer_input.pointers.is_empty(),"canceled gesture does not drop")
	touch(app.RUN_PAUSE.get_center(),true)
	touch(app.RUN_PAUSE.get_center(),false,0,true)
	check(not app.paused,"canceled menu tap does not activate")
	tap(Vector2(450,400))
	check(app.game.piece_serial==serial,"swipes and taps outside board cannot drop")
	button(app.RUN_PAUSE)
	check(app.paused,"touch pause button")
	var elapsed = app.game.elapsed
	app._process(0.1)
	check(app.game.elapsed==elapsed,"touch pause stops retreat and timer")
	await capture("pause_phone")
	was_muted = app.muted
	button(app.PAUSE_SOUND)
	check(app.muted!=was_muted,"pause sound toggle")
	button(app.PAUSE_CONTINUE)
	check(not app.paused,"touch resumes run")
	app.game.resources.Tin += 30
	app.game.loot.Tin += 30
	button(app.RUN_PAUSE)
	button(app.PAUSE_ABANDON)
	check(app.session.scene=="cell" and app.session.resources.Tin==30,"touch abandon keeps resources")
	check(app.session.summary.loot==30 and not app.paused,"touch abandon keeps summary and clears pause")
	button(app.CELL_LEAVE)
	button(app.SELECT_BEGIN)
	clean_piece()
	await capture("run_phone")
	touch(app.RUN_SOFT.get_center(),true,1)
	touch(Vector2(237,500),true,2)
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(app.paused and app.pointer_input.pointers.is_empty() and not app.pointer_input.soft_drop_active(),"focus loss releases all fingers and pauses")
	serial = app.game.piece_serial
	touch(Vector2(237,600),false,2)
	check(app.game.piece_serial==serial,"stale finger release after pause does nothing")
	button(app.PAUSE_CONTINUE)
	app._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(app.paused,"Android back opens pause")
	button(app.PAUSE_ABANDON)
	button(app.CELL_LEAVE)
	app._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not app.dungeon_selection,"Android back cancels selection")
	button(app.CELL_SETTINGS)
	button(app.SETTINGS_RESET)
	app._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not app.reset_confirmation,"Android back cancels reset")
	button(app.CELL_SETTINGS)
	app._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not app.settings_open,"Android back dismisses settings")
	check(not ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch"),"touch-to-mouse emulation disabled to prevent double actions")
	# Check another narrow aspect ratio with the same transformed touch coordinates.
	phone.size = Vector2i(320,640)
	app.scale = Vector2(0.64,0.64)
	app.position = Vector2(0,64)
	await process_frame
	button(app.CELL_SETTINGS)
	check(app.settings_open,"touch hit testing survives narrow-window scaling")
	button(app.SETTINGS_BACK)
	print("%s native touch checks passed; %s failures. Phone previews: %s" % [checks-failures,failures,OS.get_user_data_dir()])
	phone.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit(0 if failures==0 else 1)
