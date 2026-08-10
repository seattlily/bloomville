extends Node

enum Biome { FOREST = 0, DESERT = 1, BEACH = 2, MOUNTAIN = 3 }

var biome: Biome = Biome.FOREST
var starting_season: GameClock.Season = GameClock.Season.SPRING
var gold: int = 100

const SAVE_PATH: String = "user://bloomville.save"

signal gold_changed(new_amount: int)


func get_biome_name() -> String:
	return ["Forest", "Desert", "Beach", "Mountain"][biome]


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


func save_game() -> void:
	var data := {
		"biome": int(biome),
		"starting_season": int(starting_season),
		"gold": gold,
		"day": GameClock.current_day,
		"season": int(GameClock.current_season),
		"year": GameClock.current_year,
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
	biome = (data.get("biome", 0) as int) as Biome
	starting_season = (data.get("starting_season", 0) as int) as GameClock.Season
	gold = data.get("gold", 100)
	GameClock.current_day = data.get("day", 1)
	GameClock.current_season = (data.get("season", 0) as int) as GameClock.Season
	GameClock.current_year = data.get("year", 1)
	gold_changed.emit(gold)
	return true
