extends RefCounted
## Engine-independent board and combat rules. Coordinates are zero-based.
const SHAPES = {
	"I": [[0,1],[1,1],[2,1],[3,1]], "O": [[1,0],[2,0],[1,1],[2,1]],
	"T": [[1,0],[0,1],[1,1],[2,1]], "S": [[1,0],[2,0],[0,1],[1,1]],
	"Z": [[0,0],[1,0],[1,1],[2,1]], "J": [[0,0],[0,1],[1,1],[2,1]],
	"L": [[2,0],[0,1],[1,1],[2,1]]}
const MATERIALS = {"T":"Tin", "S":"Iron", "Z":"Iron", "L":"Copper", "J":"Copper", "O":"Orichalcum", "I":"Platinum"}
const Dungeons = preload("res://scripts/dungeons.gd")
var board = []
var bag = []
var queue = []
var piece = {}
var held = ""
var hold_used = false
var status = "playing"
var reason = ""
var position = 0.56
var enemy_index = 0
var enemy_hp = 4
var dungeon_index = 0
var elapsed = 0.0
var current_enemy = {}
var attack = 0.0
var travel = 1.5
var lines = 0
var score = 0
var kills = 0
var combo = -1
var gravity = 0.0
var lock_time = 0.0
var lock_resets = 0
var resources: Dictionary
var loot = {"Tin":0,"Iron":0,"Copper":0,"Orichalcum":0,"Platinum":0}
var events = []
var rng = RandomNumberGenerator.new()

func _init(inventory: Dictionary = {}, seed_value: int = -1, destination: int = 0):
	resources = inventory if not inventory.is_empty() else loot.duplicate()
	if seed_value >= 0: rng.seed = seed_value
	else: rng.randomize()
	dungeon_index = clampi(destination,0,Dungeons.DATA.size()-1)
	new_enemy()
	for y in range(20): board.append(empty_row())
	fill_queue()
	spawn()

func empty_row() -> Array:
	var row = []
	row.resize(10)
	row.fill("")
	return row

func enemy() -> Dictionary:
	return current_enemy

func dungeon() -> Dictionary:
	return Dungeons.get_dungeon(dungeon_index)

func difficulty_scale() -> float:
	return 1.0+0.20*dungeon_index

func retreat_rate() -> float:
	# Ground lost per second: continuous and unbounded, including travel breaks.
	return (0.0015+elapsed*0.000025)*(1.0+dungeon_index*0.22)

func attack_interval() -> float:
	return maxf(2.2,enemy().rate/(1.0+elapsed/240.0))

func hit_push() -> float:
	return minf(0.35,enemy().push+elapsed*0.00015)

func new_enemy():
	current_enemy = Dungeons.encounter(dungeon_index,enemy_index,rng)
	current_enemy.hp = int(ceil(current_enemy.hp*difficulty_scale()*(1.0+elapsed/180.0+enemy_index/80.0)))
	current_enemy.rate /= 1.0+dungeon_index*0.08
	current_enemy.push += dungeon_index*0.012
	enemy_hp = current_enemy.hp

func emit(kind: String, data: Dictionary = {}):
	events.append({"kind":kind,"data":data})

func fill_queue():
	while queue.size() < 5:
		if bag.is_empty():
			bag = ["I","O","T","S","Z","J","L"]
			for i in range(6,0,-1):
				var j = rng.randi_range(0,i)
				var swap = bag[i]
				bag[i] = bag[j]
				bag[j] = swap
		queue.append(bag.pop_back())

func cells(p: Dictionary = {}, dx: int = 0, dy: int = 0, rotation: int = -1) -> Array:
	if p.is_empty(): p = piece
	var result = []
	var r = p.rotation if rotation < 0 else rotation
	for cell in SHAPES[p.kind]:
		var x = cell[0]
		var y = cell[1]
		for i in range(r):
			var old_x = x
			x = (3 if p.kind == "I" else 2) - y
			y = old_x
		result.append(Vector2i(x + p.x + dx, y + p.y + dy))
	return result

func valid(p: Dictionary = {}, dx: int = 0, dy: int = 0, rotation: int = -1) -> bool:
	for c in cells(p,dx,dy,rotation):
		if c.x < 0 or c.x >= 10 or c.y >= 20: return false
		if c.y >= 0 and board[c.y][c.x] != "": return false
	return true

func spawn(kind: String = ""):
	piece = {"kind":queue.pop_front() if kind == "" else kind,"x":3,"y":-1,"rotation":0}
	fill_queue()
	gravity = 0.0
	lock_time = 0.0
	lock_resets = 0
	if not valid(): lose("The room filled with rubble.")

func lose(message: String):
	status = "lost"
	reason = message
	emit("lost")

func move(dx: int, dy: int) -> bool:
	if status != "playing" or not valid({},dx,dy): return false
	piece.x += dx
	piece.y += dy
	if dx != 0 and lock_resets < 15:
		lock_time = 0.0
		lock_resets += 1
	return true

func rotate(direction: int):
	if status != "playing" or piece.kind == "O": return
	var r = posmod(piece.rotation + direction,4)
	for kick in [Vector2i(0,0),Vector2i(-1,0),Vector2i(1,0),Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-1),Vector2i(-1,-1),Vector2i(1,-1),Vector2i(0,-2)]:
		if valid({},kick.x,kick.y,r):
			piece.x += kick.x
			piece.y += kick.y
			piece.rotation = r
			if lock_resets < 15:
				lock_time = 0.0
				lock_resets += 1
			emit("rotate")
			return

func hold():
	if status != "playing" or hold_used: return
	var old = held
	held = piece.kind
	spawn(old)
	hold_used = true
	emit("hold")

func ghost_y() -> int:
	var distance = 0
	while valid({},0,distance+1): distance += 1
	return piece.y + distance

func drop():
	if status != "playing": return
	var y = ghost_y()
	score += (y-piece.y)*2
	piece.y = y
	lock_piece()

func clear_rows() -> Array:
	var cleared = []
	var y = 19
	while y >= 0:
		if not board[y].has(""):
			var blocks = {"I":0,"O":0,"T":0,"S":0,"Z":0,"J":0,"L":0}
			for kind in board[y]:
				blocks[kind] += 1
				var material = MATERIALS[kind]
				resources[material] += 10
				loot[material] += 10
			cleared.append(blocks)
			board.remove_at(y)
			board.push_front(empty_row())
		else: y -= 1
	return cleared

func lock_piece():
	var overflow = false
	for c in cells():
		if c.y < 0: overflow = true
		else: board[c.y][c.x] = piece.kind
	if overflow:
		lose("The room filled with rubble.")
		return
	var rows = clear_rows()
	var count = rows.size()
	if count > 0:
		combo += 1
		lines += count
		var damage = [1,3,5,9][count-1]
		score += [100,300,500,1000][count-1] + maxi(0,combo)*50
		position = minf(0.92,position+0.035*count)
		enemy_hp -= damage
		emit("clear",{"lines":count,"damage":damage,"rows":rows})
		if enemy_hp <= 0:
			kills += 1
			emit("kill")
			enemy_index += 1
			new_enemy()
			attack = 0.0
			travel = 2.0
	else:
		combo = -1
		emit("lock")
	hold_used = false
	spawn()

func update(dt: float, soft: bool = false):
	if status != "playing": return
	dt = minf(dt,0.1)
	elapsed += dt
	position -= retreat_rate()*dt
	if position <= 0:
		position = 0.0
		lose("The dungeon's pressure overwhelmed you.")
		return
	if travel > 0: travel = maxf(0.0,travel-dt)
	else:
		attack += dt
		if attack >= attack_interval():
			attack -= attack_interval()
			position -= hit_push()
			emit("hit")
			if position <= 0:
				position = 0.0
				lose("You were driven out of the dungeon.")
				return
	var interval = 0.045 if soft else maxf(0.38,0.8-lines*0.008)
	gravity += dt
	while gravity >= interval:
		gravity -= interval
		if move(0,1) and soft: score += 1
	if not valid({},0,1):
		lock_time += dt
		if lock_time >= 0.45: lock_piece()
	else: lock_time = 0.0
