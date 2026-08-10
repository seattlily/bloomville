extends Node2D

const COLS: int = 8
const ROWS: int = 6
const TILE_SIZE: int = 64
const TILE_GAP: int = 4

const COLOR_DRY   := Color(0.60, 0.45, 0.28)
const COLOR_MOIST := Color(0.40, 0.28, 0.14)
const COLOR_WET   := Color(0.25, 0.16, 0.08)
const COLOR_GRID  := Color(0.0, 0.0, 0.0, 0.15)

var _tiles: Array[SoilTile] = []
var _biome_data: BiomeData = null

const BIOME_PATHS := {
	GameState.Biome.FOREST:   "res://resources/biomes/forest.tres",
	GameState.Biome.DESERT:   "res://resources/biomes/desert.tres",
	GameState.Biome.BEACH:    "res://resources/biomes/beach.tres",
	GameState.Biome.MOUNTAIN: "res://resources/biomes/mountain.tres",
}


func _ready() -> void:
	_biome_data = load(BIOME_PATHS[GameState.biome]) as BiomeData
	for i in COLS * ROWS:
		_tiles.append(SoilTile.new())
	GameClock.hour_passed.connect(_on_hour_passed)
	_center_grid()


func _center_grid() -> void:
	var grid_w: float = COLS * (TILE_SIZE + TILE_GAP) - TILE_GAP
	var grid_h: float = ROWS * (TILE_SIZE + TILE_GAP) - TILE_GAP
	var vp := get_viewport_rect().size
	position = Vector2((vp.x - grid_w) / 2.0, (vp.y - grid_h) / 2.0)


func _draw() -> void:
	for row in ROWS:
		for col in COLS:
			var tile := _tiles[row * COLS + col]
			var rect := _tile_rect(col, row)
			var color := _moisture_color(tile.moisture)
			draw_rect(rect, color)
			draw_rect(rect, COLOR_GRID, false, 1.0)


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var local := to_local(get_viewport().get_mouse_position())
	var cell := _world_to_cell(local)
	if cell.x >= 0:
		var idx := int(cell.y) * COLS + int(cell.x)
		_tiles[idx].moisture = clampf(_tiles[idx].moisture + 0.35, 0.0, 1.0)
		queue_redraw()


func _on_hour_passed() -> void:
	if not _biome_data:
		return
	for tile in _tiles:
		tile.moisture = maxf(0.0, tile.moisture - _biome_data.moisture_decay_per_hour)
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
	var rect := _tile_rect(col, row)
	if not rect.has_point(local):
		return Vector2(-1, -1)
	return Vector2(col, row)


func _moisture_color(m: float) -> Color:
	if m < 0.33:
		return COLOR_DRY.lerp(COLOR_MOIST, m / 0.33)
	elif m < 0.66:
		return COLOR_MOIST.lerp(COLOR_WET, (m - 0.33) / 0.33)
	else:
		return COLOR_WET
