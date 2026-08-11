extends Node2D

# Mirror GardenGrid constants to compute grid bounds
const COLS := 8
const ROWS := 6
const TILE_SIZE := 80
const TILE_GAP := 4


func _grid_rect() -> Rect2:
	var gw := float(COLS * (TILE_SIZE + TILE_GAP) - TILE_GAP)
	var gh := float(ROWS * (TILE_SIZE + TILE_GAP) - TILE_GAP)
	var vp := get_viewport_rect().size
	return Rect2((vp.x - gw) * 0.5, (vp.y - gh) * 0.5 - 20.0, gw, gh)


func _draw() -> void:
	var vp := get_viewport_rect().size
	var gr := _grid_rect()
	match GameState.biome:
		GameState.Biome.FOREST:   _draw_forest(vp, gr)
		GameState.Biome.DESERT:   _draw_desert(vp, gr)
		GameState.Biome.BEACH:    _draw_beach(vp, gr)
		GameState.Biome.MOUNTAIN: _draw_mountain(vp, gr)


# ──────────────── FOREST ────────────────

func _draw_forest(vp: Vector2, gr: Rect2) -> void:
	# Ground fill
	draw_rect(Rect2(0, gr.end.y - 30, vp.x, vp.y - gr.end.y + 30), Color(0.18, 0.35, 0.12))
	# Distant canopy layer
	for i in 12:
		var tx := (float(i) / 11.0) * vp.x
		var th := randf_from_seed(i * 17) * 60 + 120
		_draw_tree(tx, gr.position.y + 20, th, Color(0.14, 0.32, 0.10, 0.6), Color(0.28, 0.18, 0.09, 0.6))
	# Foreground trees on left and right of grid
	var tree_positions_l := [40.0, 100.0, 170.0, 220.0]
	var tree_positions_r := [vp.x - 40, vp.x - 110, vp.x - 175, vp.x - 230]
	for tx in tree_positions_l:
		var th := randf_from_seed(int(tx) * 7) * 50 + 160
		_draw_tree(tx, gr.end.y, th, Color(0.18, 0.45, 0.14), Color(0.38, 0.24, 0.10))
	for tx in tree_positions_r:
		var th := randf_from_seed(int(tx) * 13) * 50 + 160
		_draw_tree(tx, gr.end.y, th, Color(0.18, 0.45, 0.14), Color(0.38, 0.24, 0.10))
	# Ground mushrooms
	for i in 6:
		var mx := randf_from_seed(i * 31 + 5) * vp.x
		if mx > gr.position.x - 10 and mx < gr.end.x + 10:
			continue
		_draw_mushroom(Vector2(mx, gr.end.y + 10))


func _draw_tree(cx: float, base_y: float, height: float, leaf_color: Color, trunk_color: Color) -> void:
	var trunk_w := height * 0.10
	var trunk_h := height * 0.35
	# Trunk
	draw_rect(Rect2(cx - trunk_w * 0.5, base_y - trunk_h, trunk_w, trunk_h), trunk_color)
	# Three stacked canopy tiers
	for tier in 3:
		var ty := base_y - trunk_h - tier * (height * 0.22)
		var tw := (height * 0.55) * (1.0 - tier * 0.22)
		var th := height * 0.30
		var pts := PackedVector2Array([
			Vector2(cx, ty - th),
			Vector2(cx - tw, ty),
			Vector2(cx + tw, ty)
		])
		var c := leaf_color.darkened(tier * 0.12)
		draw_colored_polygon(pts, c)


func _draw_mushroom(pos: Vector2) -> void:
	# Stem
	draw_rect(Rect2(pos.x - 3, pos.y - 12, 6, 12), Color(0.85, 0.80, 0.72))
	# Cap
	var cap_pts := PackedVector2Array([
		Vector2(pos.x, pos.y - 18),
		Vector2(pos.x - 9, pos.y - 9),
		Vector2(pos.x + 9, pos.y - 9)
	])
	var cap_c := Color(0.82, 0.22, 0.18)
	draw_colored_polygon(cap_pts, cap_c)
	draw_circle(Vector2(pos.x - 3, pos.y - 14), 1.5, Color(1, 1, 1, 0.7))
	draw_circle(Vector2(pos.x + 2, pos.y - 12), 1.2, Color(1, 1, 1, 0.7))


# ──────────────── DESERT ────────────────

func _draw_desert(vp: Vector2, gr: Rect2) -> void:
	# Sandy ground
	draw_rect(Rect2(0, gr.end.y - 20, vp.x, vp.y - gr.end.y + 20), Color(0.80, 0.62, 0.30))
	# Sand dunes in background (behind grid)
	for i in 5:
		var dx := float(i) / 4.0 * vp.x + 80
		_draw_dune(dx, gr.position.y + 40, 180 + i * 30)
	# Cacti on sides
	var cactus_xs := [50.0, 140.0, 200.0, vp.x - 55, vp.x - 145, vp.x - 205]
	for i in cactus_xs.size():
		var cx := cactus_xs[i]
		var ch := 80.0 + randf_from_seed(i * 23 + 1) * 60.0
		_draw_cactus(Vector2(cx, gr.end.y + 5), ch)
	# Rocks
	for i in 8:
		var rx := randf_from_seed(i * 11 + 3) * vp.x
		if rx > gr.position.x - 5 and rx < gr.end.x + 5:
			continue
		var ry := gr.end.y + 5 + randf_from_seed(i * 19) * 30
		_draw_rock(Vector2(rx, ry), 8 + randf_from_seed(i * 7) * 14)


func _draw_dune(cx: float, y: float, width: float) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := float(i) / 15.0 * PI
		pts.append(Vector2(cx + cos(a) * width, y + sin(a) * 35))
	pts.append(Vector2(cx + width, y + 60))
	pts.append(Vector2(cx - width, y + 60))
	var c := Color(0.88, 0.72, 0.42, 0.5)
	draw_colored_polygon(pts, c)


func _draw_cactus(base: Vector2, height: float) -> void:
	var cw := height * 0.18
	# Main trunk
	draw_rect(Rect2(base.x - cw * 0.5, base.y - height, cw, height), Color(0.22, 0.52, 0.20))
	# Left arm
	var arm_y := base.y - height * 0.60
	var arm_len := height * 0.35
	draw_rect(Rect2(base.x - cw * 0.5 - arm_len, arm_y - cw * 0.5, arm_len, cw), Color(0.22, 0.52, 0.20))
	draw_rect(Rect2(base.x - cw * 0.5 - arm_len - cw * 0.5, arm_y - arm_len * 0.5, cw, arm_len * 0.5), Color(0.22, 0.52, 0.20))
	# Right arm
	draw_rect(Rect2(base.x + cw * 0.5, arm_y - cw * 0.5 + height * 0.08, arm_len, cw), Color(0.22, 0.52, 0.20))
	draw_rect(Rect2(base.x + cw * 0.5 + arm_len - cw * 0.5, arm_y - arm_len * 0.4 + height * 0.08, cw, arm_len * 0.4), Color(0.22, 0.52, 0.20))
	# Spines
	var spine_c := Color(0.80, 0.78, 0.58, 0.6)
	for i in 5:
		var sy := base.y - height * 0.15 * (i + 1)
		draw_line(Vector2(base.x - cw, sy), Vector2(base.x - cw - 5, sy - 3), spine_c, 1.0)
		draw_line(Vector2(base.x + cw, sy), Vector2(base.x + cw + 5, sy - 3), spine_c, 1.0)


func _draw_rock(pos: Vector2, size: float) -> void:
	var c := Color(0.58, 0.50, 0.38)
	draw_circle(pos, size, c)
	draw_circle(pos + Vector2(size * 0.3, -size * 0.2), size * 0.65, c.lightened(0.08))


# ──────────────── BEACH ────────────────

func _draw_beach(vp: Vector2, gr: Rect2) -> void:
	# Ocean on the right side
	var ocean_x := vp.x * 0.70
	draw_rect(Rect2(ocean_x, 0, vp.x - ocean_x, vp.y), Color(0.14, 0.38, 0.68, 0.85))
	# Wave lines
	for i in 5:
		var wy := 80.0 + float(i) * (vp.y - 80) / 5.0
		_draw_wave(ocean_x + 10, wy, (vp.x - ocean_x) - 20)
	# Sandy ground
	draw_rect(Rect2(0, gr.end.y - 20, vp.x, vp.y - gr.end.y + 20), Color(0.87, 0.78, 0.55))
	# Water horizon fade at top of ocean
	draw_rect(Rect2(ocean_x, 0, vp.x - ocean_x, 60), Color(0.55, 0.72, 0.92, 0.4))
	# Palm tree on left
	_draw_palm(Vector2(120, gr.end.y + 5), 130)
	_draw_palm(Vector2(vp.x * 0.55, gr.end.y + 5), 100)
	# Seashells
	for i in 6:
		var sx := 30.0 + randf_from_seed(i * 13) * (gr.position.x - 40)
		_draw_shell(Vector2(sx, gr.end.y + 15 + randf_from_seed(i * 7) * 20))


func _draw_wave(x: float, y: float, width: float) -> void:
	var pts := PackedVector2Array()
	var segments := 20
	for i in segments + 1:
		var t := float(i) / float(segments)
		pts.append(Vector2(x + t * width, y + sin(t * TAU * 2) * 4))
	draw_polyline(pts, Color(1.0, 1.0, 1.0, 0.30), 1.5)


func _draw_palm(base: Vector2, height: float) -> void:
	# Curved trunk (approximate with segments)
	var trunk_pts := PackedVector2Array()
	for i in 8:
		var t := float(i) / 7.0
		trunk_pts.append(Vector2(base.x + sin(t * 0.8) * 18, base.y - t * height))
	draw_polyline(trunk_pts, Color(0.55, 0.38, 0.18), 7.0)
	# Fronds
	var tip := trunk_pts[-1]
	var frond_c := Color(0.22, 0.55, 0.18)
	for i in 7:
		var a := float(i) / 7.0 * TAU
		var fl := 40.0 + sin(float(i)) * 10
		var end_pt := tip + Vector2(cos(a) * fl, sin(a) * fl * 0.4 + 5)
		draw_line(tip, end_pt, frond_c, 3.0)
		# Leaflets along frond
		var mid := tip.lerp(end_pt, 0.6)
		var perp := (end_pt - tip).normalized().rotated(PI * 0.5)
		draw_line(mid - perp * 8, mid + perp * 8, frond_c, 1.5)


func _draw_shell(pos: Vector2) -> void:
	draw_circle(pos, 5.0, Color(0.95, 0.85, 0.72))
	draw_arc(pos, 4.0, 0, PI, 12, Color(0.75, 0.60, 0.45), 1.0)


# ──────────────── MOUNTAIN ────────────────

func _draw_mountain(vp: Vector2, gr: Rect2) -> void:
	# Rocky ground
	draw_rect(Rect2(0, gr.end.y - 20, vp.x, vp.y - gr.end.y + 20), Color(0.48, 0.44, 0.40))
	# Distant mountain silhouettes
	var peaks := [
		[vp.x * 0.08, vp.y * 0.55, 160.0],
		[vp.x * 0.22, vp.y * 0.50, 200.0],
		[vp.x * 0.80, vp.y * 0.52, 180.0],
		[vp.x * 0.92, vp.y * 0.48, 220.0],
	]
	for p in peaks:
		_draw_mountain_peak(p[0], p[1], p[2], Color(0.42, 0.40, 0.45), 0.38)
	# Closer peaks on sides
	var near_peaks := [
		[vp.x * 0.02, gr.end.y + 10, 260.0],
		[vp.x * 0.17, gr.end.y + 10, 300.0],
		[vp.x * 0.83, gr.end.y + 10, 280.0],
		[vp.x * 0.98, gr.end.y + 10, 260.0],
	]
	for p in near_peaks:
		_draw_mountain_peak(p[0], p[1], p[2], Color(0.52, 0.50, 0.54), 0.50)
	# Pine trees at base
	var pine_xs := [60.0, 130.0, 200.0, vp.x - 60, vp.x - 130, vp.x - 200]
	for i in pine_xs.size():
		_draw_pine(Vector2(pine_xs[i], gr.end.y + 8), 70 + randf_from_seed(i * 29) * 30)
	# Snow patches on ground
	for i in 5:
		var sx := randf_from_seed(i * 41 + 2) * vp.x
		if sx > gr.position.x - 5 and sx < gr.end.x + 5:
			continue
		draw_circle(Vector2(sx, gr.end.y + 5 + randf_from_seed(i * 17) * 20),
				12 + randf_from_seed(i * 23) * 10, Color(0.90, 0.93, 1.0, 0.70))


func _draw_mountain_peak(cx: float, base_y: float, height: float, color: Color, snow_frac: float) -> void:
	var width := height * 0.70
	var pts := PackedVector2Array([
		Vector2(cx, base_y - height),
		Vector2(cx - width, base_y),
		Vector2(cx + width, base_y)
	])
	draw_colored_polygon(pts, color)
	# Snow cap
	var snow_h := height * snow_frac
	var sw := width * snow_frac * 0.85
	var snow_pts := PackedVector2Array([
		Vector2(cx, base_y - height),
		Vector2(cx - sw, base_y - height + snow_h),
		Vector2(cx + sw, base_y - height + snow_h)
	])
	draw_colored_polygon(snow_pts, Color(0.92, 0.94, 1.0))


func _draw_pine(base: Vector2, height: float) -> void:
	var tw := height * 0.10
	draw_rect(Rect2(base.x - tw * 0.5, base.y - height * 0.30, tw, height * 0.30), Color(0.35, 0.22, 0.10))
	for tier in 4:
		var ty := base.y - height * 0.25 * (tier + 1)
		var tw2 := (height * 0.45) * (1.0 - tier * 0.18)
		var th := height * 0.22
		var pts := PackedVector2Array([
			Vector2(base.x, ty - th),
			Vector2(base.x - tw2, ty),
			Vector2(base.x + tw2, ty)
		])
		var c := Color(0.14, 0.32, 0.16).darkened(tier * 0.08)
		draw_colored_polygon(pts, c)


# ──────────────── HELPERS ────────────────

func randf_from_seed(s: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	return rng.randf()
