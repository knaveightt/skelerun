extends RefCounted
## Persistent cell progression, kept separate from the disposable dungeon run.
const DungeonRun = preload("res://scripts/run.gd")
const RESOURCE_NAMES = ["Tin","Iron","Copper","Orichalcum","Platinum"]
var scene = "cell"
var resources = {"Tin":0,"Iron":0,"Copper":0,"Orichalcum":0,"Platinum":0}
var blacksmith_unlocked = false
var run
var summary = {}
var save_error = ""
var save_path: String

func _init(path: String = "user://progress.json", load_saved: bool = true):
	save_path = path
	if load_saved:
		if FileAccess.file_exists(save_path):
			restore(JSON.parse_string(FileAccess.get_file_as_string(save_path)))
		else:
			# One-time, read-only import of the original LÖVE prototype's inventory.
			for legacy in [OS.get_data_dir()+"/love/skelerun/progress.dat",OS.get_data_dir()+"/LOVE/skelerun/progress.dat"]:
				if FileAccess.file_exists(legacy):
					import_legacy(FileAccess.get_file_as_string(legacy))
					break

func restore(data):
	if not data is Dictionary or data.get("version",0) != 1: return
	var inventory = data.get("resources",{})
	if inventory is Dictionary:
		for name in RESOURCE_NAMES:
			var value = inventory.get(name,0)
			if (value is int or value is float) and is_finite(float(value)) and value >= 0 and value < 1e12:
				resources[name] = int(value)
	blacksmith_unlocked = data.get("blacksmith_unlocked",false) == true

func import_legacy(data: String) -> bool:
	if not data.begins_with("SKELERUN_SAVE_1\n"): return false
	var inventory = {}
	var unlocked = false
	for line in data.split("\n"):
		var parts = line.split("=")
		if parts.size() != 2: continue
		if parts[0] == "Blacksmith": unlocked = parts[1] == "1"
		elif parts[0] in RESOURCE_NAMES and parts[1].is_valid_int(): inventory[parts[0]] = int(parts[1])
	restore({"version":1,"resources":inventory,"blacksmith_unlocked":unlocked})
	save()
	return true

func save() -> bool:
	if save_path.is_empty(): return true
	var file = FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if file == null:
		save_error = "Could not save progress to disk."
		return false
	file.store_string(JSON.stringify({"version":1,"resources":resources,"blacksmith_unlocked":blacksmith_unlocked}))
	file.close()
	var result = DirAccess.rename_absolute(save_path+".tmp",save_path)
	save_error = "" if result == OK else "Could not save progress to disk."
	return result == OK

func start_run(seed_value: int = -1, destination: int = 0):
	if scene != "cell": return null
	run = DungeonRun.new(resources,seed_value,destination)
	scene = "run"
	summary = {}
	return run

func return_to_cell() -> bool:
	if scene != "run": return false
	var total = 0
	for value in run.loot.values(): total += value
	summary = {"status":run.status,"reason":run.reason,"lines":run.lines,"kills":run.kills,"loot":total,"dungeon":run.dungeon().name,"elapsed":run.elapsed}
	scene = "cell"
	save()
	return true

func can_unlock_blacksmith() -> bool:
	return not blacksmith_unlocked and resources.Iron >= 500 and resources.Copper >= 500

func reset_progress() -> bool:
	if scene != "cell": return false
	var previous_resources = resources
	var previous_unlock = blacksmith_unlocked
	resources = {"Tin":0,"Iron":0,"Copper":0,"Orichalcum":0,"Platinum":0}
	blacksmith_unlocked = false
	# Overwrite the save rather than deleting it, so legacy saves cannot reimport.
	if not save():
		resources = previous_resources
		blacksmith_unlocked = previous_unlock
		return false
	run = null
	summary = {}
	return true

func unlock_blacksmith() -> String:
	if scene != "cell": return "Return to your cell first."
	if blacksmith_unlocked: return "The Blacksmith is open. Refining will come later."
	if not can_unlock_blacksmith(): return "The Blacksmith needs 500 Iron AND 500 Copper."
	resources.Iron -= 500
	resources.Copper -= 500
	blacksmith_unlocked = true
	save()
	return "Blacksmith unlocked! Refining will come later."
