extends Node2D

var _effects: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func add_splash(pos: Vector2) -> void:
	var particles: Array[Dictionary] = []
	for i in 8:
		particles.append({
			"angle": _rng.randf_range(0.0, TAU),
			"speed": _rng.randf_range(28.0, 60.0),
			"size":  _rng.randf_range(3.0, 6.0),
		})
	_effects.append({ "type": "splash", "pos": pos, "t": 0.0, "dur": 0.45, "p": particles })


func add_harvest(pos: Vector2, gold: int) -> void:
	var particles: Array[Dictionary] = []
	for i in 10:
		particles.append({
			"angle": float(i) / 10.0 * TAU + _rng.randf_range(-0.2, 0.2),
			"speed": _rng.randf_range(40.0, 75.0),
			"size":  _rng.randf_range(4.0, 8.0),
		})
	_effects.append({ "type": "harvest", "pos": pos, "t": 0.0, "dur": 0.65, "p": particles, "gold": gold })


func add_grow(pos: Vector2) -> void:
	_effects.append({ "type": "grow", "pos": pos, "t": 0.0, "dur": 0.45 })


func _process(delta: float) -> void:
	if _effects.is_empty():
		return
	var any_alive := false
	for eff in _effects:
		eff["t"] = minf(eff["t"] + delta / eff["dur"], 1.1)
		if eff["t"] <= 1.0:
			any_alive = true
	_effects = _effects.filter(func(e: Dictionary) -> bool: return e["t"] < 1.1)
	if any_alive:
		queue_redraw()


func _draw() -> void:
	for eff: Dictionary in _effects:
		var t: float = eff["t"]
		if t > 1.0:
			continue
		match eff["type"]:
			"splash":  _draw_splash(eff["pos"], t, eff["p"])
			"harvest": _draw_harvest(eff["pos"], t, eff["p"], eff.get("gold", 0))
			"grow":    _draw_grow(eff["pos"], t)


func _draw_splash(pos: Vector2, t: float, particles: Array) -> void:
	var ease := 1.0 - pow(1.0 - t, 2.0)  # ease out
	for p: Dictionary in particles:
		var d: float = p["speed"] * ease
		var pt := pos + Vector2(cos(p["angle"]) * d, sin(p["angle"]) * d - d * 0.25)
		var alpha := pow(1.0 - t, 1.5)
		var r: float = p["size"] * (1.0 - t * 0.4)
		draw_circle(pt, maxf(r, 0.5), Color(0.35, 0.65, 0.95, alpha))


func _draw_harvest(pos: Vector2, t: float, particles: Array, gold: int) -> void:
	for p: Dictionary in particles:
		var d: float = p["speed"] * t
		var pt := pos + Vector2(cos(p["angle"]) * d, sin(p["angle"]) * d - d * 0.55)
		var alpha := pow(1.0 - t, 1.5)
		var r: float = p["size"] * (1.0 - t * 0.3)
		draw_circle(pt, maxf(r, 0.5), Color(1.0, 0.85, 0.10, alpha))
		draw_circle(pt, maxf(r * 0.45, 0.3), Color(1.0, 0.65, 0.05, alpha))

	# Gold amount popup floating upward
	if gold > 0:
		var alpha := pow(1.0 - t, 1.2)
		var popup_pos := pos + Vector2(-16.0, -55.0 * t)
		var font := ThemeDB.fallback_font
		draw_string(font, popup_pos, "+%dg" % gold,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
				Color(1.0, 0.92, 0.20, alpha))


func _draw_grow(pos: Vector2, t: float) -> void:
	var ring_r := 18.0 + t * 38.0
	var alpha   := pow(1.0 - t, 1.8) * 0.85
	var width   := 3.5 - t * 2.5
	draw_arc(pos, ring_r, 0.0, TAU, 40, Color(0.35, 0.92, 0.35, alpha), maxf(width, 0.5))
	# Inner soft fill ring
	draw_arc(pos, ring_r * 0.55, 0.0, TAU, 28, Color(0.55, 1.0, 0.55, alpha * 0.5), maxf(width * 0.6, 0.3))
