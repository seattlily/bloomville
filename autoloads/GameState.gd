extends Node

enum Biome { FOREST = 0, DESERT = 1, BEACH = 2, MOUNTAIN = 3 }

var biome: Biome = Biome.FOREST
var starting_season: GameClock.Season = GameClock.Season.SPRING
var gardener_name: String = "Gardener"
var gold: int = 100
var seeds: Dictionary = {}
var selected_plant: PlantData = null
var shop_open: bool = false
var overlay_open: bool = false

var season_harvests: int = 0
var season_gold: int = 0

var all_plants: Dictionary = {}

# Transaction log entries: {type, detail, amount, day, season}
var transaction_log: Array = []
const MAX_LOG_ENTRIES: int = 30

const SAVE_PATH: String = "user://bloomville.save"
const AUTOSAVE_INTERVAL: float = 120.0  # 2 real minutes

var _autosave_timer: float = 0.0
var _game_started: bool = false

signal gold_changed(new_amount: int)
signal seeds_changed
signal autosave_fired


func _ready() -> void:
	all_plants = {
		"ranunculus":        load("res://resources/plants/ranunculus.tres"),
		"peonies":           load("res://resources/plants/peonies.tres"),
		"anemones":          load("res://resources/plants/anemones.tres"),
		"sweet_peas":        load("res://resources/plants/sweet_peas.tres"),
		"zinnias":           load("res://resources/plants/zinnias.tres"),
		"snapdragons":       load("res://resources/plants/snapdragons.tres"),
		"dahlias":           load("res://resources/plants/dahlias.tres"),
		"sunflowers":        load("res://resources/plants/sunflowers.tres"),
		"chrysanthemums":    load("res://resources/plants/chrysanthemums.tres"),
		"asters":            load("res://resources/plants/asters.tres"),
		"marigolds":         load("res://resources/plants/marigolds.tres"),
		"japanese_anemones": load("res://resources/plants/japanese_anemones.tres"),
		"hellebores":        load("res://resources/plants/hellebores.tres"),
		"paperwhites":       load("res://resources/plants/paperwhites.tres"),
		"winter_aconite":    load("res://resources/plants/winter_aconite.tres"),
		"camellias":         load("res://resources/plants/camellias.tres"),
	}
	seeds = { "ranunculus": 2, "peonies": 2, "anemones": 2, "sweet_peas": 2 }


func _process(delta: float) -> void:
	if not _game_started:
		return
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		save_game()
		autosave_fired.emit()


func get_biome_name() -> String:
	return ["Forest", "Desert", "Beach", "Mountain"][biome]


func get_plant_name(plant: PlantData) -> String:
	for key in all_plants:
		if all_plants[key] == plant:
			return key
	return ""


func plants_for_season(season: GameClock.Season) -> Array:
	var result: Array = []
	for key in all_plants:
		var data := all_plants[key] as PlantData
		if data.season == season:
			result.append(key)
	return result


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


func record_harvest(harvest_gold: int, flower_name: String = "") -> void:
	season_harvests += 1
	season_gold += harvest_gold
	add_gold(harvest_gold)
	_push_log("harvest", flower_name, harvest_gold)


func log_purchase(plant_name: String, cost: int) -> void:
	_push_log("purchase", plant_name, -cost)


func reset_season_stats() -> void:
	season_harvests = 0
	season_gold = 0


func _push_log(type: String, detail: String, amount: int) -> void:
	transaction_log.push_front({
		"type":   type,
		"detail": detail,
		"amount": amount,
		"day":    GameClock.current_day,
		"season": int(GameClock.current_season),
	})
	if transaction_log.size() > MAX_LOG_ENTRIES:
		transaction_log.pop_back()


func use_seed(plant_name: String) -> bool:
	if seeds.get(plant_name, 0) <= 0:
		return false
	seeds[plant_name] -= 1
	seeds_changed.emit()
	return true


func add_seed(plant_name: String, count: int) -> void:
	seeds[plant_name] = seeds.get(plant_name, 0) + count
	seeds_changed.emit()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var data := {
		"biome":            int(biome),
		"starting_season":  int(starting_season),
		"gardener_name":    gardener_name,
		"gold":             gold,
		"day":              GameClock.current_day,
		"season":           int(GameClock.current_season),
		"year":             GameClock.current_year,
		"seeds":            seeds,
		"transaction_log":  transaction_log.slice(0, 20),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return false
	file.close()
	var data: Dictionary = json.get_data()
	biome            = (data.get("biome", 0) as int) as Biome
	starting_season  = (data.get("starting_season", 0) as int) as GameClock.Season
	gardener_name    = data.get("gardener_name", "Gardener")
	gold             = data.get("gold", 100)
	GameClock.current_day    = data.get("day", 1)
	GameClock.current_season = (data.get("season", 0) as int) as GameClock.Season
	GameClock.current_year   = data.get("year", 1)
	if data.has("seeds"):
		seeds = data["seeds"]
		seeds_changed.emit()
	if data.has("transaction_log"):
		transaction_log = data["transaction_log"]
	gold_changed.emit(gold)
	_game_started = true
	return true


func start_new_game() -> void:
	_game_started = true
	_autosave_timer = 0.0
