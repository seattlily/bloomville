extends Node2D

const WorldCreationScene   := preload("res://scenes/WorldCreation.tscn")
const GardenGridScene      := preload("res://scenes/GardenGrid.tscn")
const SeedPanelScene       := preload("res://scenes/SeedPanel.tscn")
const SeedShopScene        := preload("res://scenes/SeedShop.tscn")
const DayNightScene        := preload("res://scenes/DayNight.tscn")
const SeasonSummaryScene   := preload("res://scenes/SeasonSummary.tscn")
const BiomeBackgroundScene := preload("res://scenes/BiomeBackground.tscn")

var _world_creation: Node = null
var _garden_grid: Node = null
var _seed_panel: Node = null
var _seed_shop: Node = null
var _season_summary: Node = null


func _ready() -> void:
	var day_night := DayNightScene.instantiate()
	add_child(day_night)
	move_child(day_night, 0)  # behind HUD (same layer, earlier in tree = drawn first)

	_season_summary = SeasonSummaryScene.instantiate()
	add_child(_season_summary)

	GameClock.day_started.connect(_on_day_started)
	GameClock.season_changed.connect(_on_season_changed)

	if GameState.has_save():
		GameState.load_game()
		_spawn_garden()
	else:
		_show_world_creation()


func _show_world_creation() -> void:
	_world_creation = WorldCreationScene.instantiate()
	_world_creation.world_created.connect(_on_world_created)
	add_child(_world_creation)


func _on_world_created() -> void:
	_world_creation.queue_free()
	_world_creation = null
	_spawn_garden()


func _spawn_garden() -> void:
	var biome_bg := BiomeBackgroundScene.instantiate()
	add_child(biome_bg)
	move_child(biome_bg, 1)  # after DayNight CanvasLayer, before HUD

	_garden_grid = GardenGridScene.instantiate()
	add_child(_garden_grid)

	_seed_panel = SeedPanelScene.instantiate()
	_seed_panel.open_shop_requested.connect(_toggle_shop)
	add_child(_seed_panel)

	_seed_shop = SeedShopScene.instantiate()
	add_child(_seed_shop)


func _toggle_shop() -> void:
	_seed_shop.toggle()


func _on_day_started(day: int, _season: GameClock.Season, _year: int) -> void:
	print("[Clock] Day %d of %s, Year %d" % [day, GameClock.get_season_name(), GameClock.current_year])


func _on_season_changed(new_season: GameClock.Season, year: int) -> void:
	print("[Clock] Season changed to %s, Year %d" % [GameClock.get_season_name(), year])
	var ended_season := ((new_season - 1 + 4) % 4) as GameClock.Season
	_season_summary.show_for_season(ended_season, new_season)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match event.keycode:
		KEY_TAB:
			if _seed_shop:
				_toggle_shop()
		KEY_F5:
			GameState.save_game()
			print("[Save] Game saved.")
		KEY_F9:
			if GameState.load_game():
				print("[Save] Game loaded.")
