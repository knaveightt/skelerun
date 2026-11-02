extends RefCounted
## Ordered easiest to hardest. All destinations are currently available.
const DATA = [
	{"id":"halls","name":"Dungeon Halls","tag":"Torchlit stone corridors","accent":Color(1,0.74,0.32),"enemies":[
		{"name":"CRYPT RAT","hp":4,"rate":10.0,"push":0.09,"kind":"rat"},
		{"name":"BONE GUARD","hp":7,"rate":9.0,"push":0.105,"kind":"skeleton"},
		{"name":"MIRE SLIME","hp":8,"rate":8.5,"push":0.11,"kind":"slime"},
		{"name":"KEEP WRAITH","hp":10,"rate":8.0,"push":0.12,"kind":"wraith"},
		{"name":"THE IRON WARDEN","hp":14,"rate":7.5,"push":0.13,"kind":"warden"}]},
	{"id":"crypts","name":"Dungeon Crypts","tag":"Restless graves beneath the earth","accent":Color(0.68,0.55,0.91),"enemies":[
		{"name":"GRAVE GHOUL","hp":5,"rate":9.8,"push":0.095,"kind":"ghoul"},
		{"name":"SHAMBLING CORPSE","hp":7,"rate":9.0,"push":0.105,"kind":"zombie"},
		{"name":"BONEWING BAT","hp":8,"rate":8.4,"push":0.11,"kind":"bonebat"},
		{"name":"TOMB KEEPER","hp":12,"rate":8.0,"push":0.12,"kind":"gravekeeper"}]},
	{"id":"lava","name":"Dungeon Lava Pits","tag":"Molten rivers and living flame","accent":Color(1,0.43,0.24),"enemies":[
		{"name":"EMBER IMP","hp":6,"rate":9.5,"push":0.10,"kind":"emberimp"},
		{"name":"CINDER HOUND","hp":8,"rate":8.8,"push":0.11,"kind":"cinderhound"},
		{"name":"MAGMA OOZE","hp":10,"rate":8.2,"push":0.12,"kind":"magmaslime"},
		{"name":"FURNACE GOLEM","hp":14,"rate":8.0,"push":0.13,"kind":"furnacegolem"}]},
	{"id":"sewers","name":"Dungeon Sewers","tag":"Corroded tunnels and acid runoff","accent":Color(0.62,0.9,0.28),"enemies":[
		{"name":"ACID CRAWLER","hp":7,"rate":9.5,"push":0.10,"kind":"acidcrawler"},
		{"name":"CAUSTIC LEECH","hp":9,"rate":8.8,"push":0.11,"kind":"sewerleech"},
		{"name":"BILE TOAD","hp":11,"rate":8.2,"push":0.12,"kind":"bogtoad"},
		{"name":"SLUDGE BRUTE","hp":15,"rate":8.0,"push":0.13,"kind":"oozebrute"}]},
	{"id":"courtyard","name":"Dungeon Courtyard","tag":"Snowbound ruins under a cold moon","accent":Color(0.55,0.83,1),"enemies":[
		{"name":"FROST MOTH","hp":8,"rate":9.5,"push":0.10,"kind":"frostmoth"},
		{"name":"RIME WOLF","hp":10,"rate":8.8,"push":0.11,"kind":"icewolf"},
		{"name":"SNOW REVENANT","hp":12,"rate":8.2,"push":0.12,"kind":"snowrevenant"},
		{"name":"GLACIER GIANT","hp":16,"rate":8.0,"push":0.13,"kind":"frostgiant"}]},
	{"id":"throne","name":"Dungeon Throne Room","tag":"Gilded halls of a fallen monarchy","accent":Color(0.96,0.68,0.83),"enemies":[
		{"name":"GILDED SENTINEL","hp":9,"rate":9.5,"push":0.10,"kind":"royalguard"},
		{"name":"COURT HEXER","hp":11,"rate":8.8,"push":0.11,"kind":"courtmage"},
		{"name":"CROWN MIMIC","hp":13,"rate":8.2,"push":0.12,"kind":"crownmimic"},
		{"name":"THE FALLEN REGENT","hp":18,"rate":8.0,"push":0.14,"kind":"fallenregent"}]}
]

static func get_dungeon(index: int) -> Dictionary:
	return DATA[clampi(index,0,DATA.size()-1)]

static func encounter(dungeon_index: int, number: int, rng: RandomNumberGenerator) -> Dictionary:
	var dungeon = get_dungeon(dungeon_index)
	# Each opening rotation showcases every native enemy. Every fifth encounter
	# thereafter can revisit an earlier dungeon; harder creatures never leak down.
	var roster = dungeon.enemies
	if dungeon_index>0 and number>=roster.size() and number%5==4:
		var earlier = rng.randi_range(0,dungeon_index-1)
		var visitors = DATA[earlier].enemies
		return visitors[rng.randi_range(0,visitors.size()-1)].duplicate()
	return roster[number%roster.size()].duplicate()
