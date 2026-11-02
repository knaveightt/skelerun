extends RefCounted
## Shared touch/mouse gesture recognition in the game's logical canvas coordinates.
## UI actions commit on release; swipes never turn into menu taps.
const BOARD = Rect2(107,249,260,510)
const MOVE_STEP = 25.0
const AXIS_THRESHOLD = 18.0
const VERTICAL_THRESHOLD = 36.0
const TAP_SLOP = 14.0
var pointers = {}

func begin(id: int, point: Vector2, context: String, action: String, board_enabled: bool, serial: int):
	var mode = "tap"
	if action == "soft_drop" and context == "run": mode = "soft"
	elif board_enabled and BOARD.has_point(point):
		mode = "board"
		for pointer in pointers.values():
			if pointer.mode == "board": mode = "ignored"
	pointers[id] = {"start":point,"last":point,"distance":0.0,"mode":mode,"axis":"", "anchor":point.x,"context":context,"action":action,"serial":serial}

func motion(id: int, point: Vector2, context: String, serial: int) -> Array:
	var actions = []
	if not pointers.has(id): return actions
	var p = pointers[id]
	p.last = point
	p.distance = maxf(p.distance,p.start.distance_to(point))
	if p.context != context:
		p.mode = "ignored"
		return actions
	if p.mode == "soft":
		# Sliding off the held button releases soft drop until the next press.
		if p.start.distance_to(point)>40: p.mode = "ignored"
		return actions
	if p.mode != "board": return actions
	if p.serial != serial:
		p.mode = "ignored"
		return actions
	var delta = point-p.start
	if p.axis == "":
		if absf(delta.y)>=VERTICAL_THRESHOLD and absf(delta.y)>absf(delta.x)*1.25:
			p.axis = "vertical"
			actions.append({"action":"drop" if delta.y>0 else "rotate","direction":1})
		elif absf(delta.x)>=AXIS_THRESHOLD and absf(delta.x)>absf(delta.y)*1.25:
			p.axis = "horizontal"
	if p.axis == "horizontal":
		var distance = point.x-p.anchor
		var steps = int((absf(distance)+0.001)/MOVE_STEP)
		var direction = 1 if distance>0 else -1
		for step in range(steps): actions.append({"action":"move","direction":direction})
		p.anchor += steps*MOVE_STEP*direction
	return actions

func finish(id: int, point: Vector2, context: String, action: String, serial: int) -> Array:
	var actions = motion(id,point,context,serial)
	if not pointers.has(id): return actions
	var p = pointers[id]
	pointers.erase(id)
	if p.mode == "tap" and p.context == context and p.distance<=TAP_SLOP and p.action!="" and p.action==action:
		actions.append({"action":action})
	return actions

func cancel(id: int):
	pointers.erase(id)

func clear():
	pointers.clear()

func soft_drop_active() -> bool:
	for p in pointers.values():
		if p.mode == "soft" and p.context == "run": return true
	return false
