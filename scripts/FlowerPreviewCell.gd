extends Control

var plant_data: PlantData = null


func _draw() -> void:
	if not plant_data:
		return

	var cx := size.x * 0.5
	var cy := size.y * 0.5 + 4.0

	# Stem
	draw_line(Vector2(cx, cy + 16), Vector2(cx, cy - 16), Color(0.22, 0.55, 0.18), 2.0)

	# Leaves
	var lc := Color(0.20, 0.58, 0.15)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, cy), Vector2(cx - 10, cy - 6), Vector2(cx - 2, cy - 2)]), lc)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, cy), Vector2(cx + 10, cy - 6), Vector2(cx + 2, cy - 2)]), lc)

	var tip := Vector2(cx, cy - 22)
	var pcount := _petal_count()
	var orbit := _orbit()
	var pr := _petal_r()
	var pc := plant_data.color

	for i in pcount:
		var angle := float(i) / float(pcount) * TAU - PI * 0.5
		draw_circle(tip + Vector2(cos(angle), sin(angle)) * orbit, pr, pc)

	# Center
	match plant_data.display_name:
		"Sunflower":
			draw_circle(tip, 8.0, Color(0.30, 0.18, 0.04))
			draw_circle(tip, 4.0, Color(0.50, 0.28, 0.06))
		"Snowdrop":
			draw_circle(tip, 5.0, Color(1.0, 1.0, 1.0))
			draw_circle(tip, 2.5, Color(0.60, 0.90, 0.55))
		_:
			draw_circle(tip, 6.5, Color(1.0, 0.92, 0.20))
			draw_circle(tip, 3.0, Color(1.0, 0.72, 0.10))


func _petal_count() -> int:
	match plant_data.display_name:
		"Sunflower": return 14
		"Aster":     return 20
		"Snowdrop":  return 6
	return 6


func _orbit() -> float:
	match plant_data.display_name:
		"Sunflower": return 13.0
		"Aster":     return 10.0
	return 12.0


func _petal_r() -> float:
	match plant_data.display_name:
		"Sunflower": return 6.0
		"Aster":     return 3.5
	return 7.0
