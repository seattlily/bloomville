extends Node

enum Biome { FOREST = 0, DESERT = 1, BEACH = 2, MOUNTAIN = 3 }

var biome: Biome = Biome.FOREST
var starting_season: GameClock.Season = GameClock.Season.SPRING
var gold: int = 100
var seeds: Dictionary = {}
var selected_plant: PlantData = null
var shop_open: bool = false

var all_plants: Dictionary = {}

const SAVE_PATH: String = "user://bloomville.save"

signal gold_changed(new_amount: int)
signal seeds_changed


func _ready() -> void:
	all_plants = {
		"crocus":    load("res://resources/plants/crocus.tres"),
		"sunflower": load("res://resources/plants/sunflower.tres"),
		"aster":     load("res://resources/plants/aster.tres"),
		"snowdrop":  load("res://resources/plants/snowdrop.tres"),
	}
	seeds = { "crocus": 3, "sunflower": 3, "aster": 3, "snowdrop": 3 }


func get_biome_name() -> String:
	return ["Forest", "Desert", "Beach", "Mountain"][biome]


func get_plant_name(plant: PlantData) -> String:
	for key in all_plants:
		if all_plants[key] == plant:
			return key
	return ""


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


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
		"gold":             gold,
		"day":              GameClock.current_day,
		"season":           int(GameClock.current_season),
		"year":             GameClock.current_year,
		"seeds":            seeds,
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
	gold             = data.get("gold", 100)
	GameClock.current_day    = data.get("day", 1)
	GameClock.current_season = (data.get("season", 0) as int) as GameClock.Season
	GameClock.current_year   = data.get("year", 1)
	if data.has("seeds"):
		seeds = data["seeds"]
		seeds_changed.emit()
	gold_changed.emit(gold)
	return true
