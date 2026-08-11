extends Node2D

const COLS: int = 8
const ROWS: int = 6
const TILE_SIZE: int = 64
const TILE_GAP: int = 4

const COLOR_DRY   := Color(0.60, 0.45, 0.28)
const COLOR_MOIST := Color(0.40, 0.28, 0.14)
const COLOR_WET   := Color(0.25, 0.16, 0.08)
const COLOR_GRID  := Color(0.0, 0.0, 0.0, 0.15)
const COLOR_MATURE_RING := Color(1.0, 0.85, 0.1)

const PLANT_RADII := [6.0, 13.0, 20.0, 27.0]

const BIOME_PATHS := {
	GameState.Biome.FOREST:   "res://resources/biomes/forest.tres",
	GameState.Biome.DESERT:   "res://resources/biomes/desert.tres",
	GameState.Biome.BEACH:    "res://resources/biomes/beach.tres",
	GameState.Biome.MOUNTAIN: "res://resources/biomes/mountain.tres",
}

var _tiles: Array[SoilTile] = []
var _biome_data: BiomeData = null


func _ready() -> void:
	_biome_data = load(BIOME_PATHS[GameState.biome]) as BiomeData
	for i in COLS * ROWS:
		_tiles.append(SoilTile.new())
	GameClock.hour_passed.connect(_on_hour_passed)
	GameClock.day_started.connect(_on_day_started)
	_center_grid()


func _center_grid() -> void:
	var grid_w: float = COLS * (TILE_SIZE + TILE_GAP) - TILE_GAP
	var grid_h: float = ROWS * (TILE_SIZE + TILE_GAP) - TILE_GAP
	var vp := get_viewport_rect().size
	position = Vector2((vp.x - grid_w) / 2.0, (vp.y - grid_h) / 2.0 - 20.0)


func _draw() -> void:
	for row in ROWS:
		for col in COLS:
			var tile := _tiles[row * COLS + col]
			var rect := _tile_rect(col, row)
			draw_rect(rect, _moisture_color(tile.moisture))
			draw_rect(rect, COLOR_GRID, false, 1.0)
			if tile.plant:
				_draw_plant(tile.plant, rect)


func _draw_plant(plant: PlantInstance, rect: Rect2) -> void:
	var center := rect.get_center()
	var radius: float = PLANT_RADII[mini(plant.stage, PLANT_RADII.size() - 1)]
	draw_circle(center, radius, plant.data.color)
	if plant.is_mature():
		draw_arc(center, radius + 3.0, 0, TAU, 24, COLOR_MATURE_RING, 2.0)


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var local := to_local(get_viewport().get_mouse_position())
	var cell := _world_to_cell(local)
	if cell.x < 0:
		return
	var idx := int(cell.y) * COLS + int(cell.x)
	var tile := _tiles[idx]

	if tile.plant and tile.plant.is_mature():
		_harvest(tile)
	elif tile.plant == null and GameState.selected_plant != null:
		_plant_seed(tile)
	else:
		tile.moisture = clampf(tile.moisture + 0.35, 0.0, 1.0)

	queue_redraw()


func _harvest(tile: SoilTile) -> void:
	GameState.add_gold(tile.plant.data.harvest_gold)
	tile.plant = null


func _plant_seed(tile: SoilTile) -> void:
	var plant_name := GameState.get_plant_name(GameState.selected_plant)
	if not GameState.use_seed(plant_name):
		return
	tile.plant = PlantInstance.new(GameState.selected_plant)


func _on_hour_passed() -> void:
	if not _biome_data:
		return
	for tile in _tiles:
		tile.moisture = maxf(0.0, tile.moisture - _biome_data.moisture_decay_per_hour)
	queue_redraw()


func _on_day_started(_day: int, _season: GameClock.Season, _year: int) -> void:
	for tile in _tiles:
		if tile.plant:
			tile.plant.try_grow(tile.moisture)
	queue_redraw()


func _tile_rect(col: int, row: int) -> Rect2:
	var step := TILE_SIZE + TILE_GAP
	return Rect2(col * step, row * step, TILE_SIZE, TILE_SIZE)


func _world_to_cell(local: Vector2) -> Vector2:
	var step := TILE_SIZE + TILE_GAP
	var col := int(local.x / step)
	var row := int(local.y / step)
	if col < 0 or col >= COLS or row < 0 or row >= ROWS:
		return Vector2(-1, -1)
	if not _tile_rect(col, row).has_point(local):
		return Vector2(-1, -1)
	return Vector2(col, row)


func _moisture_color(m: float) -> Color:
	if m < 0.33:
		return COLOR_DRY.lerp(COLOR_MOIST, m / 0.33)
	elif m < 0.66:
		return COLOR_MOIST.lerp(COLOR_WET, (m - 0.33) / 0.33)
	else:
		return COLOR_WET
