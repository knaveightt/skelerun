extends Node2D
const Session = preload("res://scripts/session.gd")
const Art = preload("res://scripts/pixel_art.gd")
const DungeonRun = preload("res://scripts/run.gd")
const Dungeons = preload("res://scripts/dungeons.gd")
const TouchInput = preload("res://scripts/touch_input.gd")
const PAUSE_CONTINUE = Rect2(79,390,342,64)
const PAUSE_ABANDON = Rect2(79,466,342,64)
const PAUSE_SOUND = Rect2(79,542,342,64)
const RUN_PAUSE = Rect2(377,508,107,72)
const RUN_REVERSE = Rect2(377,588,107,72)
const RUN_SOFT = Rect2(377,668,107,72)
const CELL_SETTINGS = Rect2(382,55,102,64)
const SETTINGS_SOUND = Rect2(79,330,342,64)
const SETTINGS_RESET = Rect2(79,410,342,64)
const SETTINGS_BACK = Rect2(79,490,342,64)
const RESET_CANCEL = Rect2(68,446,170,64)
const RESET_CONFIRM = Rect2(252,446,180,64)
const SELECT_BEGIN = Rect2(16,664,468,60)
const SELECT_BACK = Rect2(16,734,468,64)
const CELL_LEAVE = Rect2(16,678,468,64)
var pointer_input = TouchInput.new()
var touch_mode = false
var settings_open = false
var session
var game
var art
var paused = false
var muted = false
var cell_message = ""
var reset_confirmation = false
var dungeon_selection = false
var selected_dungeon = 0
var clock = 0.0
var particles = []
var notices = []
var shake = 0.0
var hit_flash = 0.0
var clear_flash = 0.0
var repeat_direction = 0
var repeat_time = 0.0
var repeating = false
var players = {}

func _ready():
	session = Session.new()
	art = Art.new(self)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	get_window().min_size = Vector2i(320,512)
	touch_mode = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	get_tree().auto_accept_quit = false
	build_sounds()

func build_sounds():
	var definitions = {"lock":[100,0.08,-80],"rotate":[340,0.045,300],"hold":[260,0.08,500],"clear":[520,0.22,900],"hit":[95,0.22,-100],"kill":[650,0.3,900],"lost":[180,0.7,-120]}
	for name in definitions:
		var values = definitions[name]
		var rate = 22050
		var count = int(rate*values[1])
		var bytes = PackedByteArray()
		bytes.resize(count*2)
		for i in range(count):
			var u = float(i)/rate
			var phase = u*values[0]+values[2]*u*u
			var sample = (1.0 if fmod(phase,1.0)<0.5 else -1.0)*0.065*pow(1-u/values[1],2)
			bytes.encode_s16(i*2,int(sample*32767))
		var wav = AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = rate
		wav.data = bytes
		var player = AudioStreamPlayer.new()
		player.stream = wav
		add_child(player)
		players[name] = player

func play(name):
	if not muted and players.has(name): players[name].play()

func open_dungeon_selection():
	pointer_input.clear()
	dungeon_selection = true
	repeat_direction = 0

func start_run():
	pointer_input.clear()
	game = session.start_run(-1,selected_dungeon)
	dungeon_selection = false
	if game == null: return
	paused = false
	cell_message = ""
	particles.clear()
	notices.clear()
	shake = 0.0
	hit_flash = 0.0
	clear_flash = 0.0
	repeat_direction = 0

func unlock_blacksmith():
	var was_unlocked = session.blacksmith_unlocked
	cell_message = session.unlock_blacksmith()
	play("kill" if not was_unlocked and session.blacksmith_unlocked else "hold")

func abandon_run():
	pointer_input.clear()
	if session.scene != "run": return
	session.return_to_cell()
	paused = false
	repeat_direction = 0
	repeat_time = 0.0
	repeating = false

func burst(x,y,c,n):
	for i in range(n):
		particles.append({"p":Vector2(x,y),"v":Vector2(randf_range(-80,80),randf_range(-95,20)),"life":randf_range(0.6,1.0),"c":c})

func handle_event(event):
	play(event.kind)
	match event.kind:
		"clear":
			var n = event.data.lines
			clear_flash = 0.22
			shake = 5.0 if n == 4 else 2.0
			var label = ["SINGLE","DOUBLE","TRIPLE","TETRIS! CRITICAL"][n-1]
			notices.append({"label":label+"   -"+str(event.data.damage)+" HP","life":1.6,"c":"gold" if n==4 else "green"})
			burst(380,102,"gold",24)
			burst(250,530,game.piece.kind,20)
			session.save()
		"hit":
			hit_flash = 0.35
			shake = 6.0
			burst(100+game.position*230,104,"red",14)
		"kill": burst(390,102,"gold",28)

func _process(dt):
	clock += dt
	art.time = clock
	if session.scene == "run" and not paused:
		game.update(dt,pointer_input.soft_drop_active() or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S))
		if game.status == "playing" and repeat_direction != 0:
			repeat_time += dt
			var delay = 0.055 if repeating else 0.16
			while repeat_time >= delay:
				repeat_time -= delay
				repeating = true
				game.move(repeat_direction,0)
				delay = 0.055
		for event in game.events: handle_event(event)
		game.events.clear()
		if game.status != "playing":
			session.return_to_cell()
			pointer_input.clear()
			repeat_direction = 0
	shake = maxf(0,shake-dt*20)
	hit_flash = maxf(0,hit_flash-dt)
	clear_flash = maxf(0,clear_flash-dt)
	for i in range(particles.size()-1,-1,-1):
		var p = particles[i]
		p.life -= dt
		p.p += p.v*dt
		p.v.y += 160*dt
		if p.life <= 0: particles.remove_at(i)
	for i in range(notices.size()-1,-1,-1):
		notices[i].life -= dt
		if notices[i].life <= 0: notices.remove_at(i)
	queue_redraw()

func input_context() -> String:
	if reset_confirmation: return "reset"
	if settings_open: return "settings"
	if dungeon_selection: return "selection"
	if session.scene == "cell": return "cell"
	return "pause" if paused else "run"

func current_piece_serial() -> int:
	return game.piece_serial if game != null else -1

func action_at(point: Vector2) -> String:
	match input_context():
		"reset":
			if RESET_CANCEL.has_point(point): return "cancel_reset"
			if RESET_CONFIRM.has_point(point): return "confirm_reset"
		"settings":
			if SETTINGS_SOUND.has_point(point): return "mute"
			if SETTINGS_RESET.has_point(point): return "request_reset"
			if SETTINGS_BACK.has_point(point): return "close_settings"
		"selection":
			for i in range(6):
				if Rect2(16,126+i*88,468,78).has_point(point): return "select_"+str(i)
			if SELECT_BEGIN.has_point(point): return "begin"
			if SELECT_BACK.has_point(point): return "cancel_selection"
		"pause":
			if PAUSE_CONTINUE.has_point(point): return "resume"
			if PAUSE_ABANDON.has_point(point): return "abandon"
			if PAUSE_SOUND.has_point(point): return "mute"
		"cell":
			if CELL_SETTINGS.has_point(point): return "settings"
			if CELL_LEAVE.has_point(point) or Rect2(402,178,64,174).has_point(point): return "choose"
			if Rect2(16,528,468,139).has_point(point) or Rect2(250,160,133,190).has_point(point): return "blacksmith"
		"run":
			if RUN_PAUSE.has_point(point): return "pause"
			if RUN_REVERSE.has_point(point): return "reverse"
			if RUN_SOFT.has_point(point): return "soft_drop"
			if Rect2(16,249,82,87).has_point(point): return "hold"
	return ""

func toggle_mute():
	muted = not muted
	if muted:
		for player in players.values(): player.stop()

func set_paused(value: bool):
	paused = value
	repeat_direction = 0
	pointer_input.clear()

func activate(action: String):
	match action:
		"choose": open_dungeon_selection()
		"begin": start_run()
		"cancel_selection": dungeon_selection = false
		"settings": settings_open = true
		"close_settings": settings_open = false
		"request_reset":
			settings_open = false
			reset_confirmation = true
		"cancel_reset": reset_confirmation = false
		"confirm_reset": confirm_reset()
		"blacksmith": unlock_blacksmith()
		"pause": set_paused(true)
		"resume": set_paused(false)
		"abandon": abandon_run()
		"mute": toggle_mute()
		"hold":
			if session.scene=="run" and not paused: game.hold()
		"reverse":
			if session.scene=="run" and not paused: game.rotate(-1)
		_:
			if action.begins_with("select_"): selected_dungeon = int(action.trim_prefix("select_"))
	queue_redraw()

func perform_pointer_actions(actions: Array):
	for action in actions:
		if action.action in ["move","rotate","drop"]:
			if session.scene!="run" or paused or game.status!="playing": continue
			match action.action:
				"move": game.move(action.direction,0)
				"rotate": game.rotate(1)
				"drop": game.drop()
		else: activate(action.action)

func _unhandled_input(event):
	if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton or event is InputEventMouseMotion:
		var is_touch = event is InputEventScreenTouch or event is InputEventScreenDrag
		if is_touch: touch_mode = true
		var id = event.index if is_touch else -1
		var point = get_global_transform_with_canvas().affine_inverse()*event.position
		if event is InputEventScreenTouch and event.canceled:
			pointer_input.cancel(id)
		elif event is InputEventScreenDrag or (event is InputEventMouseMotion and pointer_input.pointers.has(id)):
			perform_pointer_actions(pointer_input.motion(id,point,input_context(),current_piece_serial()))
		elif event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT):
			if event.pressed:
				pointer_input.begin(id,point,input_context(),action_at(point),input_context()=="run" and game.status=="playing",current_piece_serial())
			else:
				perform_pointer_actions(pointer_input.finish(id,point,input_context(),action_at(point),current_piece_serial()))
		queue_redraw()
		return
	if not event is InputEventKey: return
	var key = event.physical_keycode
	if not event.pressed:
		if (repeat_direction == -1 and key in [KEY_LEFT,KEY_A]) or (repeat_direction == 1 and key in [KEY_RIGHT,KEY_D]): repeat_direction = 0
		return
	if event.echo: return
	if reset_confirmation:
		if key == KEY_Y: activate("confirm_reset")
		elif key in [KEY_N,KEY_ESCAPE]: activate("cancel_reset")
		return
	if key == KEY_M:
		toggle_mute()
		return
	if settings_open:
		if key in [KEY_ESCAPE,KEY_BACKSPACE]: activate("close_settings")
		elif key == KEY_R: activate("request_reset")
		return
	if dungeon_selection:
		if key in [KEY_ESCAPE,KEY_BACKSPACE]: activate("cancel_selection")
		elif key in [KEY_UP,KEY_W]: selected_dungeon = posmod(selected_dungeon-1,6)
		elif key in [KEY_DOWN,KEY_S]: selected_dungeon = (selected_dungeon+1)%6
		elif key>=KEY_1 and key<=KEY_6: selected_dungeon = key-KEY_1
		elif key in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]: start_run()
		return
	if session.scene == "cell":
		if key in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]: open_dungeon_selection()
		elif key == KEY_B: unlock_blacksmith()
		elif key == KEY_R: activate("request_reset")
		return
	if key in [KEY_ESCAPE,KEY_P]:
		set_paused(not paused)
		return
	if key == KEY_R:
		abandon_run()
		return
	if paused or game.status != "playing": return
	if key in [KEY_LEFT,KEY_A,KEY_RIGHT,KEY_D]:
		repeat_direction = -1 if key in [KEY_LEFT,KEY_A] else 1
		repeat_time = 0
		repeating = false
		game.move(repeat_direction,0)
	elif key in [KEY_UP,KEY_W,KEY_X]: game.rotate(1)
	elif key == KEY_Z: game.rotate(-1)
	elif key == KEY_SPACE: game.drop()
	elif key in [KEY_C,KEY_SHIFT]: game.hold()

func _notification(what):
	if session == null: return
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		session.save()
		get_tree().quit()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		pointer_input.clear()
		if reset_confirmation: activate("cancel_reset")
		elif settings_open: activate("close_settings")
		elif dungeon_selection: activate("cancel_selection")
		elif session.scene=="run": set_paused(true)
		else: activate("settings")
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		pointer_input.clear()
		if session.scene == "run":
			set_paused(true)
			session.save()

func header():
	art.text("SKELERUN",16,12,26,"gold")
	art.text(game.dungeon().name.to_upper() if session.scene=="run" else "THE SUNKEN KEEP",262,17,11,"dim",222,HORIZONTAL_ALIGNMENT_RIGHT)

func draw_cell():
	header()
	art.text("YOUR CELL",16,62,20)
	art.text("Rest. Rebuild. Descend again.",16,94,12,"dim")
	draw_button(CELL_SETTINGS,"SETTINGS","gold",12)
	art.panel(16,120,468,278)
	art.bricks(18,122,464,229)
	art.rect(63,148,68,77,"edge")
	art.rect(68,153,58,67,"ink")
	art.rect(74,158,46,56,Color(0.12,0.18,0.28))
	art.rect(102,166,9,12,Color(0.67,0.75,0.75))
	for i in range(4): art.rect(76+i*12,153,4,67,"edge")
	art.rect(68,179,58,4,"edge")
	art.rect(65,333,98,13,Color(0.30,0.21,0.19))
	art.rect(67,345,6,17,"edge")
	art.rect(152,345,6,17,"edge")
	art.rect(67,324,93,12,Color(0.45,0.36,0.32))
	art.rect(76,320,31,7,Color(0.68,0.63,0.49))
	art.rect(108,325,49,8,Color(0.35,0.42,0.44))
	var open = session.blacksmith_unlocked
	art.rect(254,181,125,163,Color(0.09,0.095,0.13))
	art.rect(250,178,133,9,"edge")
	art.rect(250,187,9,158,"edge")
	art.rect(374,187,9,158,"edge")
	art.rect(272,205,84,60,"stone")
	art.rect(280,212,68,53,"ink")
	if open:
		art.rect(281,234,66,31,"L",0.18)
		for i in range(6):
			art.rect(285+i*10,242+floor(sin(clock*9+i)*4),7,20,"L")
			art.rect(287+i*10,250,3,12,"gold")
	else: art.rect(280,259,67,5,"dim")
	art.rect(279,291,58,8,"dim")
	art.rect(290,299,34,9,"edge")
	art.rect(299,307,15,17,"dim")
	art.rect(288,324,37,7,"edge")
	art.rect(326,282,5,12,Color(0.49,0.31,0.21))
	art.rect(319,279,18,7,"dim")
	if not open:
		art.rect(259,227,115,8,Color(0.33,0.25,0.20))
		art.rect(266,243,102,8,Color(0.33,0.25,0.20))
		art.rect(310,232,15,18,"gold")
		art.rect(313,225,9,10,"edge")
		art.rect(316,238,3,7,"ink")
	art.text("BLACKSMITH",258,163,10,"gold" if open else "dim",116,HORIZONTAL_ALIGNMENT_CENTER)
	art.rect(407,198,54,145,"ink")
	art.rect(402,193,64,7,"edge")
	for i in range(6): art.rect(412,325-i*16,44,8,Color(0.20+i*0.009,0.23+i*0.007,0.28+i*0.005))
	art.text("TO KEEP",401,178,9,"gold",68,HORIZONTAL_ALIGNMENT_CENTER)
	art.torch(205,225)
	art.torch(464,237)
	art.rect(18,351,464,45,Color(0.19,0.19,0.23))
	art.rect(18,351,464,4,"edge")
	for i in range(12): art.rect(26+i*39,378,minf(27,482-(26+i*39)),2,Color(0.27,0.26,0.29))
	art.hero(208,326)
	art.text("REST. REBUILD. DESCEND AGAIN.",29,381,9,"dim",440,HORIZONTAL_ALIGNMENT_CENTER)
	art.panel(16,412,468,101)
	art.text("YOUR STASH",29,424,11,"gold")
	art.text("Kept after every run",270,425,10,"dim",200,HORIZONTAL_ALIGNMENT_RIGHT)
	var colors = ["T","S","L","O","I"]
	for i in range(5):
		var x = 23+i*94
		var name = Session.RESOURCE_NAMES[i]
		if i > 0: art.rect(x-4,450,1,49,"edge")
		art.text(name.to_upper(),x,452,9,colors[i],92,HORIZONTAL_ALIGNMENT_CENTER)
		art.text(session.resources[name],x,475,16,"text",92,HORIZONTAL_ALIGNMENT_CENTER)
	art.panel(16,528,468,139)
	art.text("BLACKSMITH",30,542,16)
	art.text("UNLOCKED" if open else "LOCKED",328,546,11,"green" if open else "dim",140,HORIZONTAL_ALIGNMENT_RIGHT)
	if open:
		art.text("The forge is lit. Your workshop is ready.",30,574,12,"dim")
		art.text("Weapon and armor refining will come later.",30,595,12,"dim")
		art.text("TAP TO INSPECT" if touch_mode else "RESTORED",30,634,12,"green")
	else:
		art.text("Restore the forge with materials from your runs.",30,573,11,"dim")
		art.text("IRON  %s / 500" % session.resources.Iron,30,601,12,"green" if session.resources.Iron>=500 else "dim")
		art.text("COPPER  %s / 500" % session.resources.Copper,254,601,12,"green" if session.resources.Copper>=500 else "dim")
		art.text(("TAP TO UNLOCK" if touch_mode else "[ B ] UNLOCK BLACKSMITH") if session.can_unlock_blacksmith() else ("TAP WORKSHOP: 500 IRON + 500 COPPER" if touch_mode else "[ B ] UNLOCK: 500 IRON + 500 COPPER"),30,638,11,"gold" if session.can_unlock_blacksmith() else "dim")
	draw_button(CELL_LEAVE,"CHOOSE A DUNGEON" if touch_mode else "[ ENTER ] CHOOSE A DUNGEON","gold",16)
	var message = cell_message
	var summary = session.summary
	if message == "" and not summary.is_empty():
		var result = "You awaken in your cell." if summary.status == "lost" else "You returned to your cell."
		message = result+" %s resources gathered." % summary.loot
		art.text("%s / %s slain / %ds" % [summary.get("dungeon","Dungeon"),summary.kills,int(summary.get("elapsed",0))],20,762,11,"dim",460,HORIZONTAL_ALIGNMENT_CENTER)
	art.text(message if message != "" else "Clear lines to gather materials. Return here to rebuild.",20,745,11,"gold" if cell_message != "" else "dim",460,HORIZONTAL_ALIGNMENT_CENTER)
	art.text("Settings: sound and reset progress" if touch_mode else "ENTER DESCEND   B BLACKSMITH   R RESET   M SOUND",16,785,9,"dim",468,HORIZONTAL_ALIGNMENT_CENTER)

func draw_dungeon():
	art.panel(16,53,468,143)
	art.dungeon_background(game.dungeon().id,clock*(25 if game.travel>0 else 3))
	art.hero(42+game.position*285,133,game.travel>0)
	art.monster(game.enemy().kind,400+minf(48,game.travel*25),133)
	art.text("RETREAT",24,178,9,"red")
	art.text("ADVANCE",413,178,9,"dim")
	art.rect(91,181,294,4,"ink")
	art.rect(91,181,294*game.position,4,"red" if game.position<0.25 else "gold")
	if hit_flash>0: art.rect(18,55,464,139,"red",hit_flash*0.5)

func draw_board():
	art.panel(107,249,260,510)
	for y in range(20):
		for x in range(10):
			var px = 112+x*25
			var py = 254+y*25
			art.rect(px,py,24,24,Color(0.085,0.105,0.14) if (x+y)%2==0 else Color(0.09,0.11,0.15))
			art.rect(px+11,py+11,2,2,Color(0.15,0.18,0.22))
			if game.board[y][x] != "": art.block(px,py,game.board[y][x])
	if game.status == "playing":
		var dy = game.ghost_y()-game.piece.y
		for c in game.cells({},0,dy):
			if c.y >= 0: art.block(112+c.x*25,254+c.y*25,game.piece.kind,true)
		for c in game.cells():
			if c.y >= 0: art.block(112+c.x*25,254+c.y*25,game.piece.kind)
	if clear_flash>0: art.rect(112,254,250,500,"gold",clear_flash*0.6)

func draw_sidebar():
	art.panel(16,249,82,87)
	art.text("HOLD",16,260,11,"dim",82,HORIZONTAL_ALIGNMENT_CENTER)
	art.preview(game.held,22,287)
	art.text(("USED" if game.hold_used else "TAP TO HOLD") if touch_mode else "C / SHIFT",16,317,9,"dim" if game.hold_used else "gold",82,HORIZONTAL_ALIGNMENT_CENTER)
	art.panel(377,249,107,251)
	art.text("NEXT",377,261,11,"dim",107,HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(4): art.preview(game.queue[i],397,283+i*52)
	draw_button(RUN_PAUSE,"PAUSE","gold",16)
	draw_button(RUN_REVERSE,"ROTATE <","text",16)
	draw_button(RUN_SOFT,"SOFT DROP","text",16)
	if pointer_input.soft_drop_active(): art.rect(RUN_SOFT.position.x+3,RUN_SOFT.position.y+3,RUN_SOFT.size.x-6,3,"gold")
	art.panel(16,349,82,303)
	art.text("RESOURCES",16,358,10,"gold",82,HORIZONTAL_ALIGNMENT_CENTER)
	art.text("+10 / BLOCK",19,373,9,"dim",76,HORIZONTAL_ALIGNMENT_CENTER)
	var kinds = ["T","S","L","O","I"]
	var types = ["T","S / Z","L / J","O","I"]
	for i in range(5):
		var name = Session.RESOURCE_NAMES[i]
		var y = 393+i*52
		art.text(name.to_upper(),19,y,9,kinds[i],76,HORIZONTAL_ALIGNMENT_CENTER)
		art.text(game.resources[name],19,y+12,16,"text",76,HORIZONTAL_ALIGNMENT_CENTER)
		art.text(types[i],19,y+32,9,"dim",76,HORIZONTAL_ALIGNMENT_CENTER)
	art.text("SCORE",16,668,10,"dim",82,HORIZONTAL_ALIGNMENT_CENTER)
	art.text("%05d" % game.score,16,685,16,"text",82,HORIZONTAL_ALIGNMENT_CENTER)
	art.text("LINES",16,717,10,"dim",82,HORIZONTAL_ALIGNMENT_CENTER)
	art.text(game.lines,16,733,16,"text",82,HORIZONTAL_ALIGNMENT_CENTER)
	art.text("SLAIN "+str(game.kills),377,746,12,"gold",107,HORIZONTAL_ALIGNMENT_CENTER)

func draw_run():
	if shake>0 and not paused: draw_set_transform(Vector2(randf_range(-shake,shake),randf_range(-shake,shake)))
	header()
	art.text("%02d:%02d   RETREAT x%.1f" % [int(game.elapsed)/60,int(game.elapsed)%60,game.retreat_rate()/0.0015],260,36,9,"dim",224,HORIZONTAL_ALIGNMENT_RIGHT)
	draw_dungeon()
	art.text("FOE %03d  %s" % [game.enemy_index+1,game.enemy().name],18,207,12)
	art.text("LINES 1/2/3/4 = DAMAGE 1/3/5/9",18,238,9,"dim")
	var hp = maxi(0,game.enemy_hp)
	art.text("%s / %s HP" % [hp,game.enemy().hp],366,207,11,"dim",115,HORIZONTAL_ALIGNMENT_RIGHT)
	art.rect(18,227,318,6,"stone")
	art.rect(18,227,318*float(hp)/game.enemy().hp,6,"red")
	art.rect(352,227,130,6,"stone")
	art.rect(352,227,130*game.attack/game.attack_interval(),6,"gold")
	art.text("APPROACHING" if game.travel>0 else "NEXT ATTACK",352,237,9,"dim",130,HORIZONTAL_ALIGNMENT_RIGHT)
	draw_board()
	draw_sidebar()
	for p in particles: art.rect(p.p.x,p.p.y,3,3,p.c,minf(1,p.life*2))
	if not notices.is_empty():
		var n = notices.back()
		art.panel(118,348,238,36)
		art.text(n.label,118,359,12,n.c,238,HORIZONTAL_ALIGNMENT_CENTER)
	art.text("SWIPE LEFT/RIGHT: MOVE   UP: ROTATE   DOWN: DROP" if touch_mode else "A D / ARROWS MOVE   UP / X ROTATE   Z REVERSE",16,770,10,"dim",468,HORIZONTAL_ALIGNMENT_CENTER)
	art.text("TAP HOLD   HOLD SOFT DROP   SOUND IN PAUSE" if touch_mode else "SPACE DROP   C HOLD   P PAUSE   M SOUND",16,786,9,"dim",468,HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)
	if paused:
		art.rect(0,0,500,800,"bg",0.85)
		art.panel(51,250,398,380)
		art.text("PAUSED",65,286,26,"text",370,HORIZONTAL_ALIGNMENT_CENTER)
		art.text("Take a breath. The dungeon can wait.",73,336,12,"dim",354,HORIZONTAL_ALIGNMENT_CENTER)
		art.text("%s LINES / %s SLAIN / %s POINTS" % [game.lines,game.kills,game.score],65,376,12,"text",370,HORIZONTAL_ALIGNMENT_CENTER)
		draw_button(PAUSE_CONTINUE,"CONTINUE" if touch_mode else "[ P / ESC ] CONTINUE","gold",14)
		draw_button(PAUSE_ABANDON,"ABANDON RUN" if touch_mode else "[ R ] ABANDON RUN","red",14)
		draw_button(PAUSE_SOUND,"SOUND: "+("OFF" if muted else "ON"),"dim" if muted else "green",14)
		art.text("Return to your cell. Keep gathered resources.",65,613,11,"dim",370,HORIZONTAL_ALIGNMENT_CENTER)

func _draw():
	if art == null: return
	art.rect(0,0,500,800,"bg")
	if dungeon_selection: draw_dungeon_selection()
	elif session.scene == "cell": draw_cell()
	else: draw_run()
	if session.save_error != "": art.text(session.save_error,16,780,10,"red",468,HORIZONTAL_ALIGNMENT_CENTER)
	if settings_open: draw_settings()
	if reset_confirmation: draw_reset_confirmation()

func confirm_reset():
	pointer_input.clear()
	settings_open = false
	reset_confirmation = false
	if not session.reset_progress():
		cell_message = "Reset failed. Your progress has been kept."
		return
	game = null
	dungeon_selection = false
	selected_dungeon = 0
	paused = false
	repeat_direction = 0
	particles.clear()
	notices.clear()
	shake = 0.0
	hit_flash = 0.0
	clear_flash = 0.0
	cell_message = "Progress reset. A fresh start awaits."
	play("hold")

func draw_reset_confirmation():
	art.rect(0,0,500,800,"bg",0.9)
	art.panel(48,278,404,250)
	art.text("RESET ALL PROGRESS?",60,300,22,"red",380,HORIZONTAL_ALIGNMENT_CENTER)
	art.text("Are you sure you want to start over?",60,348,14,"text",380,HORIZONTAL_ALIGNMENT_CENTER)
	art.text("All resources and workshop unlocks will be lost.",60,378,12,"dim",380,HORIZONTAL_ALIGNMENT_CENTER)
	art.text("This cannot be undone.",60,403,12,"dim",380,HORIZONTAL_ALIGNMENT_CENTER)
	draw_button(RESET_CANCEL,"CANCEL" if touch_mode else "[ N / ESC ] CANCEL","gold",12)
	draw_button(RESET_CONFIRM,"RESET ALL" if touch_mode else "[ Y ] RESET ALL","red",12)

func _exit_tree():
	for player in players.values():
		player.stop()
		player.stream = null
	players.clear()

func draw_dungeon_selection():
	header()
	art.text("CHOOSE YOUR DUNGEON",16,60,22,"text")
	art.text("All paths are open. How far can you survive?",16,93,12,"dim")
	for i in range(6):
		var dungeon = Dungeons.DATA[i]
		var y = 126+i*88
		art.panel(16,y,468,78)
		if i == selected_dungeon:
			art.rect(18,y+2,464,74,dungeon.accent,0.08)
			art.rect(16,y,3,78,dungeon.accent)
		art.destination_icon(dungeon.id,28,y+12)
		art.text(str(i+1)+"  "+dungeon.name,96,y+9,16,dungeon.accent)
		art.text(dungeon.tag,96,y+35,10,"dim")
		art.text("OPEN",96,y+55,9,"green")
		art.text("DIFFICULTY",332,y+56,9,"dim")
		for rank in range(6): art.rect(401+rank*11,y+58,7,7,dungeon.accent if rank<=i else "stone")
	art.text("Endless enemies. Retreat pressure rises with time.",16,649,11,"dim",468,HORIZONTAL_ALIGNMENT_CENTER)
	draw_button(SELECT_BEGIN,"BEGIN RUN" if touch_mode else "[ ENTER ] BEGIN RUN",Dungeons.DATA[selected_dungeon].accent,16)
	draw_button(SELECT_BACK,"BACK TO CELL" if touch_mode else "[ ESC ] BACK TO CELL","gold",12)

func draw_button(bounds: Rect2,label: String,tint = "text",size: int = 14):
	art.panel(bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y)
	art.text(label,bounds.position.x,bounds.position.y+(bounds.size.y-size)/2-2,size,tint,bounds.size.x,HORIZONTAL_ALIGNMENT_CENTER)

func draw_settings():
	art.rect(0,0,500,800,"bg",0.9)
	art.panel(51,238,398,340)
	art.text("CELL SETTINGS",65,262,24,"text",370,HORIZONTAL_ALIGNMENT_CENTER)
	art.text("Sound and saved progression",65,301,12,"dim",370,HORIZONTAL_ALIGNMENT_CENTER)
	draw_button(SETTINGS_SOUND,"SOUND: "+("OFF" if muted else "ON"),"dim" if muted else "green")
	draw_button(SETTINGS_RESET,"RESET ALL PROGRESS","red")
	draw_button(SETTINGS_BACK,"BACK TO CELL","gold")
