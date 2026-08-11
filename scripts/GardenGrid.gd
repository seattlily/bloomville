extends Node2D

const COLS: int = 8
const ROWS: int = 6
const TILE_SIZE: int = 80
const TILE_GAP: int = 4

const COLOR_DRY          := Color(0.60, 0.45, 0.28)
const COLOR_MOIST        := Color(0.40, 0.28, 0.14)
const COLOR_WET          := Color(0.25, 0.16, 0.08)
const COLOR_GRID         := Color(0.0, 0.0, 0.0, 0.18)
const COLOR_STEM         := Color(0.22, 0.55, 0.18)
const COLOR_LEAF         := Color(0.20, 0.58, 0.15)
const COLOR_MATURE_RING  := Color(1.0, 0.85, 0.1)
const COLOR_MOISTURE_BG  := Color(0.0, 0.0, 0.0, 0.35)
const COLOR_MOISTURE_LOW := Color(0.82, 0.44, 0.12)
const COLOR_MOISTURE_MID := Color(0.22, 0.62, 0.88)
const COLOR_MOISTURE_HI  := Color(0.18, 0.38, 0.90)
const COLOR_ROTTED       := Color(0.35, 0.22, 0.10, 0.80)

# Root rot triggers after this many consecutive hours above the over-water threshold
const OVERWATER_THRESHOLD: float = 0.85
const OVERWATER_HOURS_LIMIT: int = 8

const BIOME_PATHS := {
	GameState.Biome.FOREST:   "res://resources/biomes/forest.tres",
	GameState.Biome.DESERT:   "res://resources/biomes/desert.tres",
	GameState.Biome.BEACH:    "res://resources/biomes/beach.tres",
	GameState.Biome.MOUNTAIN: "res://resources/biomes/mountain.tres",
}

const EffectLayerScript := preload("res://scripts/EffectLayer.gd")

var _tiles: Array[SoilTile] = []
var _tile_variations: Array[float] = []
var _biome_data: BiomeData = null
var _fx: Node = null


func _ready() -> void:
	_biome_data = load(BIOME_PATHS[GameState.biome]) as BiomeData
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in COLS * ROWS:
		_tiles.append(SoilTile.new())
		_tile_variations.append(rng.randf_range(-0.05, 0.05))
	GameClock.hour_passed.connect(_on_hour_passed)
	GameClock.day_started.connect(_on_day_started)
	_fx = EffectLayerScript.new()
	add_child(_fx)
	_center_grid()


func _center_grid() -> void:
	var grid_w: float = COLS * (TILE_SIZE + TILE_GAP) - TILE_GAP
	var grid_h: float = ROWS * (TILE_SIZE + TILE_GAP) - TILE_GAP
	var vp := get_viewport_rect().size
	position = Vector2((vp.x - grid_w) / 2.0, (vp.y - grid_h) / 2.0 - 20.0)


func _draw() -> void:
	for row in ROWS:
		for col in COLS:
			var idx := row * COLS + col
			var tile := _tiles[idx]
			var rect := _tile_rect(col, row)
			var base := _moisture_color(tile.moisture)
			var v := _tile_variations[idx]
			draw_rect(rect, Color(clampf(base.r + v, 0, 1), clampf(base.g + v * 0.8, 0, 1), clampf(base.b + v * 0.6, 0, 1)))
			draw_rect(rect, COLOR_GRID, false, 1.0)
			if tile.plant:
				_draw_plant(tile.plant, rect)
			_draw_moisture_bar(tile.moisture, rect)


func _draw_moisture_bar(moisture: float, rect: Rect2) -> void:
	const BAR_H: float = 5.0
	const BAR_PAD: float = 4.0
	var bar_y := rect.end.y - BAR_H - 2.0
	var bar_x := rect.position.x + BAR_PAD
	var bar_w := rect.size.x - BAR_PAD * 2.0
	draw_rect(Rect2(bar_x, bar_y, bar_w, BAR_H), COLOR_MOISTURE_BG)
	var fill_w := bar_w * clampf(moisture, 0.0, 1.0)
	if fill_w > 0:
		var bar_color: Color
		if moisture < 0.4:
			bar_color = COLOR_MOISTURE_LOW
		elif moisture < 0.75:
			bar_color = COLOR_MOISTURE_MID
		else:
			bar_color = COLOR_MOISTURE_HI
		draw_rect(Rect2(bar_x, bar_y, fill_w, BAR_H), bar_color)


func _draw_plant(plant: PlantInstance, rect: Rect2) -> void:
	var in_season := GameClock.current_season == plant.data.season
	var alpha := 1.0 if in_season else 0.38
	var plant_color := Color(plant.data.color.r, plant.data.color.g, plant.data.color.b, alpha)
	var stem_color := Color(COLOR_STEM.r, COLOR_STEM.g, COLOR_STEM.b, alpha)
	var leaf_color := Color(COLOR_LEAF.r, COLOR_LEAF.g, COLOR_LEAF.b, alpha)

	var cx := rect.get_center().x
	var base_y := rect.end.y - 14.0
	var stem_heights := [12.0, 22.0, 36.0, 50.0]
	var stem_h: float = stem_heights[mini(plant.stage, stem_heights.size() - 1)]
	var tip := Vector2(cx, base_y - stem_h)

	draw_line(Vector2(cx, base_y), tip, stem_color, 2.5)

	if stem_h >= 22.0:
		var leaf_y := base_y - stem_h * 0.48
		var ls := stem_h * 0.28
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx, leaf_y),
			Vector2(cx - ls * 1.6, leaf_y - ls * 0.9),
			Vector2(cx - ls * 0.2, leaf_y - ls * 0.5)]), leaf_color)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx, leaf_y),
			Vector2(cx + ls * 1.6, leaf_y - ls * 0.9),
			Vector2(cx + ls * 0.2, leaf_y - ls * 0.5)]), leaf_color)

	if plant.is_mature():
		_draw_mature_flower(plant.data, tip, alpha, plant_color)
		draw_arc(tip, _flower_orbit(plant.data) + _flower_petal_r(plant.data) + 5.0,
				0, TAU, 36, Color(COLOR_MATURE_RING.r, COLOR_MATURE_RING.g, COLOR_MATURE_RING.b, alpha), 1.5)
	else:
		var bud_radii := [5.5, 9.0, 13.0]
		var bud_r: float = bud_radii[mini(plant.stage, bud_radii.size() - 1)]
		draw_circle(tip, bud_r, plant_color)
		if plant.stage >= 1:
			draw_circle(tip, bud_r * 0.38, plant.data.color.lightened(0.45) * Color(1, 1, 1, alpha))
			var sl := bud_r * 0.75
			draw_colored_polygon(PackedVector2Array([Vector2(cx, tip.y + bud_r * 0.3), Vector2(cx - sl, tip.y + bud_r + sl * 0.6), Vector2(cx + sl * 0.1, tip.y + bud_r)]), leaf_color)
			draw_colored_polygon(PackedVector2Array([Vector2(cx, tip.y + bud_r * 0.3), Vector2(cx + sl, tip.y + bud_r + sl * 0.6), Vector2(cx - sl * 0.1, tip.y + bud_r)]), leaf_color)


func _draw_mature_flower(data: PlantData, tip: Vector2, alpha: float, plant_color: Color) -> void:
	var pcount := _petal_count(data)
	var orbit  := _flower_orbit(data)
	var pr     := _flower_petal_r(data)
	var name   := data.display_name

	match name:
		"Sunflower", "Zinnias":
			# Dense ray petals around a large dark center
			for i in pcount:
				var angle := float(i) / float(pcount) * TAU - PI * 0.5
				var p := tip + Vector2(cos(angle), sin(angle)) * orbit
				draw_circle(p, pr, plant_color)
			if name == "Sunflower":
				draw_circle(tip, 11.0, Color(0.30, 0.18, 0.04, alpha))
				draw_circle(tip,  6.0, Color(0.50, 0.28, 0.06, alpha))
				draw_circle(tip,  3.0, Color(0.20, 0.10, 0.02, alpha))
			else:
				draw_circle(tip, 9.0, Color(0.18, 0.52, 0.18, alpha))
				draw_circle(tip, 5.0, Color(0.12, 0.38, 0.12, alpha))

		"Dahlias", "Chrysanthemums":
			# Dense double-layer petals (pompom effect)
			for i in pcount:
				var angle := float(i) / float(pcount) * TAU - PI * 0.5
				var p1 := tip + Vector2(cos(angle), sin(angle)) * orbit
				var p2 := tip + Vector2(cos(angle), sin(angle)) * orbit * 0.55
				draw_circle(p1, pr, plant_color)
				draw_circle(p2, pr * 0.75, plant_color.lightened(0.15) * Color(1, 1, 1, alpha))
			draw_circle(tip, 5.0, plant_color.lightened(0.35) * Color(1, 1, 1, alpha))

		"Asters", "Marigolds":
			# Narrow ray petals, yellow-orange disk center
			for i in pcount:
				var angle := float(i) / float(pcount) * TAU - PI * 0.5
				var p := tip + Vector2(cos(angle), sin(angle)) * orbit
				draw_circle(p, pr, plant_color)
				draw_circle(p + Vector2(cos(angle), sin(angle)) * (pr * 0.3),
						pr * 0.35, plant_color.lightened(0.3) * Color(1, 1, 1, alpha))
			draw_circle(tip, 7.0, Color(1.0, 0.82, 0.10, alpha))
			draw_circle(tip, 4.0, Color(1.0, 0.62, 0.05, alpha))

		"Snapdragons":
			# Tall tubular blooms stacked along stem (draw 3 petal-clusters vertically)
			for k in 3:
				var ky := tip.y + k * 6.0
				var kc := Color(plant_color.r, plant_color.g, plant_color.b, alpha * (1.0 - k * 0.2))
				draw_circle(Vector2(tip.x, ky), 8.0 - k * 1.5, kc)
				draw_circle(Vector2(tip.x, ky), (8.0 - k * 1.5) * 0.5, kc.lightened(0.3) * Color(1, 1, 1, alpha))
			draw_arc(tip, 8.0, 0, TAU, 24, Color(COLOR_MATURE_RING.r, COLOR_MATURE_RING.g, COLOR_MATURE_RING.b, alpha * 0.5), 1.0)

		"Ranunculus", "Peonies":
			# Many concentric rings of petals
			for ring in 3:
				var ring_orbit := orbit * (1.0 - ring * 0.28)
				var ring_pr    := pr * (1.0 - ring * 0.18)
				var ring_pc    := 6 + ring * 2
				var ring_color := plant_color.lightened(ring * 0.12) * Color(1, 1, 1, alpha)
				for i in ring_pc:
					var angle := float(i) / float(ring_pc) * TAU - PI * 0.5
					var p := tip + Vector2(cos(angle), sin(angle)) * ring_orbit
					draw_circle(p, ring_pr, ring_color)
			draw_circle(tip, 5.0, Color(1.0, 0.92, 0.30, alpha))

		"Anemones", "Japanese Anemones", "Jpn Anemones":
			# 5–6 wide petals, dark center
			for i in pcount:
				var angle := float(i) / float(pcount) * TAU - PI * 0.5
				var p := tip + Vector2(cos(angle), sin(angle)) * orbit
				draw_colored_polygon(PackedVector2Array([
					tip,
					p + Vector2(-cos(angle + PI * 0.5), -sin(angle + PI * 0.5)) * pr * 0.85,
					p + Vector2(cos(angle), sin(angle)) * pr,
					p + Vector2(cos(angle + PI * 0.5), sin(angle + PI * 0.5)) * pr * 0.85,
				]), plant_color)
			draw_circle(tip, 7.0, Color(0.12, 0.08, 0.28, alpha))
			draw_circle(tip, 4.0, Color(1.0, 0.95, 0.30, alpha))

		"Sweet Peas":
			# Butterfly-wing shaped pair
			var wing_c := plant_color
			for side in [-1, 1]:
				var pts := PackedVector2Array([
					tip,
					Vector2(tip.x + side * orbit, tip.y - pr * 0.3),
					Vector2(tip.x + side * orbit * 0.7, tip.y + pr * 0.9),
				])
				draw_colored_polygon(pts, wing_c)
				draw_colored_polygon(PackedVector2Array([
					tip,
					Vector2(tip.x + side * orbit * 0.4, tip.y - pr * 0.8),
					Vector2(tip.x + side * orbit * 0.9, tip.y - pr * 0.5),
				]), wing_c.lightened(0.2) * Color(1, 1, 1, alpha))
			draw_circle(tip, 4.5, Color(1.0, 0.94, 0.55, alpha))

		"Hellebores":
			# 5 cupped petals, nodding downward
			for i in pcount:
				var angle := float(i) / float(pcount) * TAU + PI * 0.1
				var p := tip + Vector2(cos(angle), sin(angle) * 0.7 + 0.35) * orbit
				draw_circle(p, pr, plant_color)
				draw_circle(p, pr * 0.45, plant_color.lightened(0.25) * Color(1, 1, 1, alpha))
			draw_circle(Vector2(tip.x, tip.y + orbit * 0.35), 5.5, Color(0.94, 0.94, 0.50, alpha))
			draw_circle(Vector2(tip.x, tip.y + orbit * 0.35), 3.0, Color(0.55, 0.72, 0.30, alpha))

		"Paperwhites":
			# Cluster of small white star flowers
			for i in 5:
				var angle := float(i) / 5.0 * TAU
				var off := Vector2(cos(angle), sin(angle)) * orbit * 0.45
				for j in 6:
					var pa := float(j) / 6.0 * TAU
					var pp := tip + off + Vector2(cos(pa), sin(pa)) * pr * 0.7
					draw_circle(pp, pr * 0.45, Color(0.97, 0.97, 0.95, alpha))
				draw_circle(tip + off, 3.5, Color(0.95, 0.88, 0.20, alpha))

		"Winter Aconite":
			# 5–6 cupped yellow petals, green ruff
			var ruff_r := orbit + pr + 3.0
			for i in 8:
				var angle := float(i) / 8.0 * TAU
				var p := tip + Vector2(cos(angle), sin(angle)) * ruff_r
				draw_colored_polygon(PackedVector2Array([
					tip + Vector2(cos(angle), sin(angle)) * (orbit - 2.0),
					p + Vector2(-sin(angle), cos(angle)) * 4.0,
					p + Vector2(sin(angle), -cos(angle)) * 4.0,
				]), Color(0.22, 0.62, 0.18, alpha))
			for i in pcount:
				var angle := float(i) / float(pcount) * TAU - PI * 0.5
				var p := tip + Vector2(cos(angle), sin(angle)) * orbit
				draw_circle(p, pr, plant_color)
			draw_circle(tip, 5.5, Color(1.0, 0.92, 0.22, alpha))

		"Camellias":
			# Rose-like spiral of petals
			for ring in 3:
				var ring_orbit := orbit * (1.0 - ring * 0.25)
				var ring_pr    := pr * (1.0 - ring * 0.15)
				var ring_off   := float(ring) * 0.35
				var ring_pc    := 8 - ring
				for i in ring_pc:
					var angle := float(i) / float(ring_pc) * TAU + ring_off - PI * 0.5
					var p := tip + Vector2(cos(angle), sin(angle)) * ring_orbit
					draw_circle(p, ring_pr, plant_color.lightened(ring * 0.08) * Color(1, 1, 1, alpha))
			draw_circle(tip, 4.0, Color(1.0, 0.90, 0.55, alpha))

		_:
			# Generic: 6 petals + yellow center
			for i in pcount:
				var angle := float(i) / float(pcount) * TAU - PI * 0.5
				var p := tip + Vector2(cos(angle), sin(angle)) * orbit
				draw_circle(p, pr, plant_color)
				draw_circle(p + Vector2(cos(angle), sin(angle)) * (pr * 0.3),
						pr * 0.35, plant_color.lightened(0.3) * Color(1, 1, 1, alpha))
			draw_circle(tip, 8.0, Color(1.0, 0.92, 0.20, alpha))
			draw_circle(tip, 4.0, Color(1.0, 0.72, 0.10, alpha))


func _petal_count(data: PlantData) -> int:
	match data.display_name:
		"Sunflower":                       return 16
		"Zinnias":                         return 14
		"Dahlias", "Chrysanthemums":       return 12
		"Asters", "Marigolds":             return 20
		"Anemones", "Japanese Anemones", "Jpn Anemones": return 6
		"Ranunculus", "Peonies":           return 8
		"Hellebores":                      return 5
		"Winter Aconite":                  return 6
		"Snapdragons":                     return 4
		"Camellias":                       return 8
		_:                                 return 6


func _flower_orbit(data: PlantData) -> float:
	match data.display_name:
		"Sunflower":                       return 18.0
		"Zinnias":                         return 14.0
		"Dahlias", "Chrysanthemums":       return 14.0
		"Asters", "Marigolds":             return 13.0
		"Ranunculus", "Peonies":           return 14.0
		"Anemones", "Japanese Anemones", "Jpn Anemones": return 12.0
		"Sweet Peas":                      return 13.0
		"Snapdragons":                     return 10.0
		"Hellebores":                      return 11.0
		"Paperwhites":                     return 11.0
		"Winter Aconite":                  return 10.0
		"Camellias":                       return 13.0
		_:                                 return 12.0


func _flower_petal_r(data: PlantData) -> float:
	match data.display_name:
		"Sunflower":                       return 8.0
		"Zinnias":                         return 6.0
		"Dahlias":                         return 7.0
		"Chrysanthemums":                  return 5.5
		"Asters", "Marigolds":             return 4.5
		"Ranunculus", "Peonies":           return 7.0
		"Anemones", "Japanese Anemones", "Jpn Anemones": return 8.0
		"Sweet Peas":                      return 9.0
		"Hellebores":                      return 8.0
		"Snapdragons":                     return 7.0
		"Paperwhites":                     return 5.0
		"Winter Aconite":                  return 7.0
		"Camellias":                       return 7.5
		_:                                 return 7.0


func _input(event: InputEvent) -> void:
	if GameState.shop_open or GameState.overlay_open:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var local := to_local(get_viewport().get_mouse_position())
	var cell := _world_to_cell(local)
	if cell.x < 0:
		return
	var idx := int(cell.y) * COLS + int(cell.x)
	var tile := _tiles[idx]

	var center := _tile_rect(int(cell.x), int(cell.y)).get_center()
	if tile.plant and tile.plant.is_mature():
		_harvest(tile, center)
	elif tile.plant == null and GameState.selected_plant != null:
		_plant_seed(tile)
	else:
		tile.moisture = clampf(tile.moisture + 0.35, 0.0, 1.0)
		_fx.add_splash(center)

	queue_redraw()


func _harvest(tile: SoilTile, center: Vector2) -> void:
	var flower_name := tile.plant.data.display_name
	var gold := tile.plant.data.harvest_gold
	GameState.record_harvest(gold, flower_name)
	_fx.add_harvest(center, gold)
	tile.plant = null
	tile.overwater_hours = 0


func _plant_seed(tile: SoilTile) -> void:
	var plant_name := GameState.get_plant_name(GameState.selected_plant)
	if not GameState.use_seed(plant_name):
		return
	tile.plant = PlantInstance.new(GameState.selected_plant)
	tile.overwater_hours = 0


func _on_hour_passed(_hour: int) -> void:
	if not _biome_data:
		return
	for tile in _tiles:
		tile.moisture = maxf(0.0, tile.moisture - _biome_data.moisture_decay_per_hour)
		if tile.plant:
			if tile.moisture > OVERWATER_THRESHOLD:
				tile.overwater_hours += 1
				if tile.overwater_hours >= OVERWATER_HOURS_LIMIT:
					# Root rot — plant dies
					tile.plant = null
					tile.moisture = clampf(tile.moisture - 0.20, 0.0, 1.0)
					tile.overwater_hours = 0
			else:
				tile.overwater_hours = 0
	queue_redraw()


func _on_day_started(_day: int, season: GameClock.Season, _year: int) -> void:
	for i in _tiles.size():
		var tile := _tiles[i]
		if tile.plant and tile.plant.data.season == season:
			var old_stage := tile.plant.stage
			tile.plant.try_grow(tile.moisture)
			if tile.plant.stage > old_stage:
				var col := i % COLS
				var row := i / COLS
				_fx.add_grow(_tile_rect(col, row).get_center())
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
