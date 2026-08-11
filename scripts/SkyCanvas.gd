extends Node2D

var _stars: Array[Vector2] = []
var _star_sizes: Array[float] = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	for i in 80:
		_stars.append(Vector2(rng.randf_range(0, 1152), rng.randf_range(0, 420)))
		_star_sizes.append(rng.randf_range(0.8, 2.0))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := GameClock.time_of_day
	var vp := get_viewport_rect().size

	_draw_stars(t, vp)
	_draw_sun(t, vp)
	_draw_moon(t, vp)


func _draw_stars(t: float, vp: Vector2) -> void:
	# Stars visible when away from midday; peak alpha at midnight (t=0 or t=1)
	var star_alpha := clampf((absf(t - 0.5) - 0.18) * 4.5, 0.0, 1.0)
	if star_alpha <= 0.0:
		return
	var star_color := Color(1.0, 0.98, 0.92, star_alpha)
	for i in _stars.size():
		var sx := _stars[i].x / 1152.0 * vp.x
		var sy := _stars[i].y / 420.0 * vp.y * 0.65
		draw_circle(Vector2(sx, sy), _star_sizes[i], star_color)
		# Twinkle: small cross
		if _star_sizes[i] > 1.4:
			draw_line(Vector2(sx - 2, sy), Vector2(sx + 2, sy), Color(1, 1, 1, star_alpha * 0.5), 1.0)
			draw_line(Vector2(sx, sy - 2), Vector2(sx, sy + 2), Color(1, 1, 1, star_alpha * 0.5), 1.0)


func _draw_sun(t: float, vp: Vector2) -> void:
	# Sun arcs from horizon-left (t=0.20) to horizon-right (t=0.80)
	if t < 0.18 or t > 0.82:
		return
	var sun_t := clampf((t - 0.20) / 0.60, 0.0, 1.0)
	var fade := clampf(minf(sun_t * 6.0, (1.0 - sun_t) * 6.0), 0.0, 1.0)
	var sx := sun_t * vp.x
	var sy := vp.y * 0.68 - sin(sun_t * PI) * vp.y * 0.62
	# Glow halo
	draw_circle(Vector2(sx, sy), 28.0, Color(1.0, 0.90, 0.30, 0.18 * fade))
	draw_circle(Vector2(sx, sy), 20.0, Color(1.0, 0.92, 0.40, 0.28 * fade))
	# Sun disc
	draw_circle(Vector2(sx, sy), 14.0, Color(1.0, 0.95, 0.55, fade))
	draw_circle(Vector2(sx, sy),  9.0, Color(1.0, 1.00, 0.80, fade))
	# Horizon glow streak near sunrise/sunset
	if sun_t < 0.15 or sun_t > 0.85:
		var glow_alpha := (1.0 - absf(sun_t - 0.5) * 2.0 + 0.7) * fade * 0.35
		draw_line(Vector2(0, sy + 5), Vector2(vp.x, sy + 5),
				Color(1.0, 0.55, 0.12, clampf(glow_alpha, 0, 0.35)), 18.0)


func _draw_moon(t: float, vp: Vector2) -> void:
	# Moon arcs during nighttime: from t=0.78 to t=1.0/0.0 to t=0.22
	var moon_t: float
	if t >= 0.78:
		moon_t = (t - 0.78) / 0.44
	elif t <= 0.22:
		moon_t = (t + 0.22) / 0.44
	else:
		return
	moon_t = clampf(moon_t, 0.0, 1.0)
	var fade := clampf(minf(moon_t * 5.0, (1.0 - moon_t) * 5.0), 0.0, 1.0)
	var mx := moon_t * vp.x
	var my := vp.y * 0.65 - sin(moon_t * PI) * vp.y * 0.52
	# Soft glow
	draw_circle(Vector2(mx, my), 20.0, Color(0.80, 0.85, 1.0, 0.12 * fade))
	# Moon disc
	draw_circle(Vector2(mx, my), 11.0, Color(0.90, 0.92, 1.00, 0.92 * fade))
	# Shadow bite for crescent effect
	draw_circle(Vector2(mx + 5, my - 2), 9.0, Color(0.0, 0.0, 0.0, 0.0))  # handled by sky color; just the disc is enough
