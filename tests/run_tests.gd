extends SceneTree
const Run = preload("res://scripts/run.gd")
const Dungeons = preload("res://scripts/dungeons.gd")
const Session = preload("res://scripts/session.gd")
var checks = 0
var failures = 0
func check(value, message):
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func fresh(): return Run.new({},123)
func prepare_clear(g, count):
	for y in range(20-count,20):
		for x in range(10):
			if x != 4: g.board[y][x] = "J"
	g.piece = {"kind":"I","x":2,"y":16,"rotation":1}
func _initialize():
	var g = fresh()
	check(g.queue.size()==5,"five queued pieces")
	var seen = {g.piece.kind:true}
	for i in range(6):
		g.spawn()
		seen[g.piece.kind] = true
	check(seen.size()==7,"seven bag")
	g = fresh()
	var first = g.piece.kind
	g.hold()
	check(g.held==first and g.hold_used,"hold stores active piece")
	var next = g.piece.kind
	g.hold()
	check(g.piece.kind==next,"hold once per piece")
	g.drop()
	check(not g.hold_used,"placement restores hold")
	g.hold()
	check(g.piece.kind==first,"hold swaps back")
	g = fresh()
	for i in range(20): g.move(-1,0)
	check(g.valid(),"wall collision")
	for i in range(4):
		g.rotate(1)
		check(g.valid(),"wall kick valid")
	g = fresh()
	var ghost = g.ghost_y()
	g.drop()
	var occupied = 0
	for row in g.board:
		for kind in row:
			if kind != "": occupied += 1
	check(occupied==4 and ghost>0,"hard drop places four blocks")
	for n in g.resources.values(): check(n==0,"no rewards without cleared rows")
	for count in range(1,5):
		g = fresh()
		g.enemy_hp = 100
		var pos = g.position
		prepare_clear(g,count)
		g.lock_piece()
		check(g.lines==count,"clears %s rows" % count)
		check(g.enemy_hp==100-[1,3,5,9][count-1],"line damage")
		check(g.position>pos,"ground regained")
		check(g.resources.Copper==90*count and g.resources.Platinum==10*count,"block rewards across rows")
		var event = g.events[0]
		check(event.kind=="clear" and event.data.rows.size()==count,"individual row records")
		for row in event.data.rows: check(row.J==9 and row.I==1,"row composition")
	g = fresh()
	var mixed = ["T","S","Z","L","J","O","I","T","O","I"]
	g.board[19] = mixed.duplicate()
	g.board[18][0] = "J"
	var rows = g.clear_rows()
	check(rows.size()==1 and rows[0].T==2 and rows[0].S==1 and rows[0].Z==1 and rows[0].L==1 and rows[0].J==1 and rows[0].O==2 and rows[0].I==2,"all seven piece types counted")
	for name in Session.RESOURCE_NAMES: check(g.resources[name]==20,"mapping "+name)
	check(g.board[19][0]=="J","uncleared block retained")
	check(g.clear_rows().is_empty(),"partial rows not cleared")
	for name in Session.RESOURCE_NAMES: check(g.resources[name]==20,"partial row gives no resources")
	g = fresh()
	g.travel = 0.0
	g.attack = g.enemy().rate-0.01
	var pos = g.position
	g.update(0.02)
	check(g.position<pos,"monster knockback")
	g.position = 0.01
	g.attack = g.enemy().rate-0.01
	g.update(0.02)
	check(g.status=="lost","left edge loss")
	g = fresh()
	g.board[0].fill("Z")
	g.spawn("O")
	check(g.status=="lost","blocked spawn")
	g = fresh()
	g.piece = {"kind":"O","x":3,"y":18,"rotation":0}
	g.update(0.1)
	check(g.lock_time>0 and g.board[19][4]=="","lock delay gives movement time")
	for i in range(5): g.update(0.1)
	check(g.board[19][4]=="O","lock delay eventually places piece")
	for index in range(5):
		g = fresh()
		g.enemy_index = index
		g.enemy_hp = 1
		prepare_clear(g,1)
		g.lock_piece()
		check(g.kills==1,"enemy defeated")
		check(g.status=="playing" and g.enemy_index==index+1 and g.travel==2,"endless enemy progression")
	var s = Session.new("",false)
	check(s.scene=="cell" and not s.blacksmith_unlocked,"starts in locked cell")
	for n in s.resources.values(): check(n==0,"empty initial stash")
	s.unlock_blacksmith()
	check(not s.blacksmith_unlocked,"insufficient funds")
	s.resources.Iron = 500
	s.resources.Copper = 499
	s.unlock_blacksmith()
	check(not s.blacksmith_unlocked and s.resources.Iron==500 and s.resources.Copper==499,"both costs required")
	s.resources.Iron = 499
	s.resources.Copper = 500
	s.unlock_blacksmith()
	check(not s.blacksmith_unlocked,"iron required too")
	g = s.start_run(123)
	check(s.start_run()==null,"cannot overwrite active run")
	s.unlock_blacksmith()
	check(not s.blacksmith_unlocked,"no unlocking during run")
	prepare_clear(g,1)
	g.lock_piece()
	check(s.resources.Copper==590 and s.resources.Platinum==10,"shared stash")
	check(g.loot.Copper==90 and g.loot.Platinum==10,"run loot separate from stash")
	g.lose("test")
	s.return_to_cell()
	check(s.scene=="cell" and s.summary.status=="lost" and s.summary.loot==100,"death returns with loot")
	s.resources.Iron = 550
	s.unlock_blacksmith()
	check(s.blacksmith_unlocked and s.resources.Iron==50 and s.resources.Copper==90,"exact unlock costs")
	s.unlock_blacksmith()
	check(s.resources.Iron==50 and s.resources.Copper==90,"no duplicate spending")
	check(not s.return_to_cell(),"return idempotent")
	g = s.start_run(123)
	check(g.lines==0 and g.loot.Copper==0 and g.resources.Copper==90,"new run retains stash only")
	g.lose("test")
	s.return_to_cell()
	check(s.scene=="cell" and s.summary.status=="lost","loss returns")
	s.start_run()
	s.return_to_cell()
	check(s.scene=="cell" and s.resources.Copper==90,"early return keeps inventory")
	var path = "user://test_progress.json"
	var disk = Session.new(path,false)
	disk.resources.Iron = 505
	disk.resources.Copper = 600
	disk.resources.Tin = 70
	disk.unlock_blacksmith()
	check(disk.save_error=="","save works")
	var restored = Session.new(path)
	check(restored.scene=="cell" and restored.blacksmith_unlocked,"reload unlock")
	check(restored.resources.Iron==5 and restored.resources.Copper==100 and restored.resources.Tin==70,"reload inventory")
	var bad = Session.new("",false)
	bad.restore({"version":1,"resources":{"Iron":-1,"Copper":"999","Tin":INF,"Orichalcum":NAN,"Platinum":1.5}})
	check(bad.resources.Iron==0 and bad.resources.Copper==0 and bad.resources.Tin==0 and bad.resources.Orichalcum==0 and bad.resources.Platinum==1,"invalid data sanitized")
	check(bad.import_legacy("SKELERUN_SAVE_1\nBlacksmith=1\nIron=80\nCopper=90\nTin=20\n"),"legacy save imported")
	check(bad.blacksmith_unlocked and bad.resources.Iron==80 and bad.resources.Copper==90 and bad.resources.Tin==20,"legacy save values")
	check(not bad.import_legacy("invalid save"),"invalid legacy ignored")
	check(disk.reset_progress(),"cell progress reset succeeds")
	check(not disk.blacksmith_unlocked and disk.run==null and disk.summary.is_empty(),"reset removes unlock and run history")
	for name in Session.RESOURCE_NAMES: check(disk.resources[name]==0,"reset clears "+name)
	restored = Session.new(path)
	check(not restored.blacksmith_unlocked and restored.resources==disk.resources,"reset persists after reload")
	g = restored.start_run(123)
	check(g.lines==0 and g.kills==0 and g.position==0.56,"reset begins a fresh run")
	check(not restored.reset_progress() and restored.scene=="run","reset forbidden during run")
	var failed = Session.new("user://missing-reset-directory/progress.json",false)
	failed.resources.Iron = 700
	failed.blacksmith_unlocked = true
	check(not failed.reset_progress() and failed.resources.Iron==700 and failed.blacksmith_unlocked,"failed save preserves progress")
	check(Dungeons.DATA.size()==6,"six destinations")
	var earlier_kinds = []
	var previous_hp = 0
	var previous_rate = 99.0
	var previous_retreat = 0.0
	for destination in range(6):
		var data = Dungeons.DATA[destination]
		check(data.enemies.size()>=3 and data.enemies.size()<=5,"3-5 native enemies per destination")
		var local_kinds = []
		for foe in data.enemies:
			check(not earlier_kinds.has(foe.kind) and not local_kinds.has(foe.kind),"unique native enemy "+foe.kind)
			local_kinds.append(foe.kind)
		g = Run.new({},123,destination)
		check(g.dungeon().id==data.id and g.status=="playing","destination selected")
		check(g.enemy().hp>previous_hp and g.attack_interval()<previous_rate and g.retreat_rate()>previous_retreat,"ascending starting difficulty")
		previous_hp = g.enemy().hp
		previous_rate = g.attack_interval()
		previous_retreat = g.retreat_rate()
		for number in range(data.enemies.size()):
			check(Dungeons.encounter(destination,number,g.rng).kind==data.enemies[number].kind,"opening showcases native roster")
		var allowed = earlier_kinds+local_kinds
		var saw_visitor = false
		for number in range(80):
			var kind = Dungeons.encounter(destination,number,g.rng).kind
			check(allowed.has(kind),"only native or easier enemies")
			if earlier_kinds.has(kind): saw_visitor = true
		check(saw_visitor if destination>0 else not saw_visitor,"visitors come from easier dungeons only")
		var initial_retreat = g.retreat_rate()
		var initial_interval = g.attack_interval()
		var initial_push = g.hit_push()
		var initial_hp = g.enemy().hp
		g.elapsed = 240
		g.new_enemy()
		check(g.retreat_rate()>initial_retreat and g.attack_interval()<initial_interval and g.hit_push()>initial_push and g.enemy().hp>initial_hp,"time increases all pressure")
		for number in range(25):
			g.board.clear()
			for y in range(20): g.board.append(g.empty_row())
			g.enemy_hp = 1
			prepare_clear(g,1)
			g.lock_piece()
			check(g.status=="playing" and g.kills==number+1,"no victory cap after repeated defeats")
		check(g.enemy_index==25,"unbounded encounter counter")
		g = Run.new({},123,destination)
		g.travel = 100.0
		g.position = 0.00001
		g.update(0.1)
		check(g.status=="lost" and g.position==0,"continuous retreat can end a run during travel")
		var picked = Session.new("",false)
		check(picked.start_run(123,destination).dungeon_index==destination,"session starts selected dungeon")
		picked.return_to_cell()
		check(picked.summary.dungeon==data.name and picked.summary.elapsed==0,"summary records destination and duration")
		earlier_kinds.append_array(local_kinds)
	g = fresh()
	var early_rate = g.retreat_rate()
	g.elapsed = 1800
	check(g.retreat_rate()>early_rate*20,"continuous retreat accelerates without a fixed cap")
	var seed_a = Run.new({},123,5)
	var seed_b = Run.new({},123,5)
	seed_a.enemy_index = 9
	seed_b.enemy_index = 9
	seed_a.new_enemy()
	seed_b.new_enemy()
	check(seed_a.enemy()==seed_b.enemy() and seed_a.queue==seed_b.queue,"seeded encounters and piece bag reproducible")
	DirAccess.remove_absolute(path)
	print("%s Godot checks passed; %s failures" % [checks-failures,failures])
	quit(0 if failures==0 else 1)
