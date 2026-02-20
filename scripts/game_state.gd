extends Node

const SAVE_PATH: String = "user://save_data.json"
const DEFAULT_CHARACTER_PATH: String = "res://addons/duelyst_animated_sprites/assets/spriteframes/units/f3_general.tres"
const UNIT_FRAMES_DIR: String = "res://addons/duelyst_animated_sprites/assets/spriteframes/units"
const FLIGHT_CHARACTER_COUNT: int = 3
const SHOP_RANDOM_SEED: int = 884221

var coins: int = 0
var total_coins_earned: int = 0
var highest_score: int = 1
var equipped_character_path: String = DEFAULT_CHARACTER_PATH
var owned_characters: Dictionary = {}
var shop_character_entries: Array[Dictionary] = []
var character_cost_by_path: Dictionary = {}
var flight_character_paths: Dictionary = {}


func _ready() -> void:
	_rebuild_character_catalog()
	load_state()


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	total_coins_earned += amount
	save_state()


func spend_coins(amount: int) -> bool:
	if amount <= 0:
		return true
	if coins < amount:
		return false
	coins -= amount
	save_state()
	return true


func own_character(character_path: String) -> void:
	if character_path.is_empty():
		return
	owned_characters[character_path] = true
	save_state()


func is_character_owned(character_path: String) -> bool:
	return bool(owned_characters.get(character_path, false))


func equip_character(character_path: String) -> void:
	if character_path.is_empty():
		return
	if not is_character_owned(character_path):
		return
	equipped_character_path = character_path
	save_state()


func get_equipped_character_path() -> String:
	if equipped_character_path.is_empty():
		return DEFAULT_CHARACTER_PATH
	return equipped_character_path


func get_shop_characters() -> Array[Dictionary]:
	return shop_character_entries


func get_character_cost(character_path: String) -> int:
	return int(character_cost_by_path.get(character_path, 0))


func equipped_character_has_double_jump() -> bool:
	var path: String = get_equipped_character_path()
	return is_character_owned(path) and get_character_cost(path) == 500


func equipped_character_has_flight() -> bool:
	var path: String = get_equipped_character_path()
	return is_character_owned(path) and get_character_cost(path) == 1000


func equipped_character_has_q_ability() -> bool:
	return equipped_character_has_double_jump() or equipped_character_has_flight()


func get_character_display_name(character_path: String) -> String:
	for entry: Dictionary in shop_character_entries:
		if String(entry.get("path", "")) == character_path:
			return String(entry.get("name", "Unknown"))
	return "Unknown"


func set_highest_score(score: int) -> void:
	if score <= highest_score:
		return
	highest_score = score
	save_state()


func save_state() -> void:
	var data: Dictionary = {
		"coins": coins,
		"total_coins_earned": total_coins_earned,
		"highest_score": highest_score,
		"equipped_character_path": equipped_character_path,
		"owned_characters": owned_characters
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))


func load_state() -> void:
	_rebuild_character_catalog()
	coins = 0
	total_coins_earned = 0
	highest_score = 1
	equipped_character_path = DEFAULT_CHARACTER_PATH
	owned_characters.clear()
	owned_characters[DEFAULT_CHARACTER_PATH] = true

	if not FileAccess.file_exists(SAVE_PATH):
		save_state()
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		save_state()
		return

	var raw: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		save_state()
		return

	var data: Dictionary = parsed
	coins = int(data.get("coins", 0))
	total_coins_earned = int(data.get("total_coins_earned", coins))
	highest_score = maxi(1, int(data.get("highest_score", 1)))
	equipped_character_path = String(data.get("equipped_character_path", DEFAULT_CHARACTER_PATH))
	var saved_owned: Variant = data.get("owned_characters", {})
	if saved_owned is Dictionary:
		for key: Variant in saved_owned.keys():
			owned_characters[String(key)] = bool(saved_owned[key])

	owned_characters[DEFAULT_CHARACTER_PATH] = true
	if not is_character_owned(equipped_character_path):
		equipped_character_path = DEFAULT_CHARACTER_PATH


func _rebuild_character_catalog() -> void:
	shop_character_entries.clear()
	character_cost_by_path.clear()
	flight_character_paths.clear()

	var files: PackedStringArray = []
	var dir: DirAccess = DirAccess.open(UNIT_FRAMES_DIR)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var file_name: String = dir.get_next()
		if file_name.is_empty():
			break
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			files.append(file_name)
	dir.list_dir_end()

	files.sort()
	flight_character_paths = _pick_flight_character_paths(files)

	for i: int in range(files.size()):
		var file_name: String = files[i]
		var path: String = "%s/%s" % [UNIT_FRAMES_DIR, file_name]
		var cost: int = 1000 if bool(flight_character_paths.get(path, false)) else 100 + ((i % 5) * 100)
		var entry: Dictionary = {
			"name": _display_name_from_file(file_name),
			"path": path,
			"cost": cost
		}
		shop_character_entries.append(entry)
		character_cost_by_path[path] = cost


func _display_name_from_file(file_name: String) -> String:
	var base: String = file_name.trim_suffix(".tres")
	var parts: PackedStringArray = base.split("_")
	for i: int in range(parts.size()):
		parts[i] = parts[i].capitalize()
	return " ".join(parts)


func _pick_flight_character_paths(files: PackedStringArray) -> Dictionary:
	var picked: Dictionary = {}
	if files.is_empty():
		return picked

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SHOP_RANDOM_SEED

	var candidates: PackedInt32Array = PackedInt32Array()
	for i: int in range(files.size()):
		var path: String = "%s/%s" % [UNIT_FRAMES_DIR, files[i]]
		if path != DEFAULT_CHARACTER_PATH:
			candidates.append(i)

	var picks_needed: int = mini(FLIGHT_CHARACTER_COUNT, candidates.size())
	for _n: int in range(picks_needed):
		var chosen: int = rng.randi_range(0, candidates.size() - 1)
		var file_idx: int = candidates[chosen]
		candidates.remove_at(chosen)
		var flight_path: String = "%s/%s" % [UNIT_FRAMES_DIR, files[file_idx]]
		picked[flight_path] = true

	return picked
