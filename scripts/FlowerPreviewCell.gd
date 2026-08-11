extends Control

var plant_data: PlantData = null


func _draw() -> void:
	if not plant_data:
		return

	var cx := size.x * 0.5
	var cy := size.y * 0.5 + 6.0
	var sc := minf(size.x, size.y) / 80.0  # scale relative to 80px tile

	var stem_color := Color(0.22, 0.55, 0.18)
	var leaf_color := Color(0.20, 0.58, 0.15)
	var pc         := plant_data.color

	# Stem
	draw_line(Vector2(cx, cy + 18 * sc), Vector2(cx, cy - 18 * sc), stem_color, 2.0)

	# Leaves
	var lh := cy - 4.0 * sc
	var ls := 8.0 * sc
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, lh), Vector2(cx - ls * 1.4, lh - ls * 0.8), Vector2(cx - ls * 0.2, lh - ls * 0.4)]), leaf_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, lh), Vector2(cx + ls * 1.4, lh - ls * 0.8), Vector2(cx + ls * 0.2, lh - ls * 0.4)]), leaf_color)

	var tip    := Vector2(cx, cy - 20.0 * sc)
	var orbit  := _orbit() * sc
	var pr     := _petal_r() * sc
	var pcount := _petal_count()
	var name   := plant_data.display_name

	match name:
		"Dahlias", "Chrysanthemums":
			for ring in 3:
				var ro := orbit * (1.0 - ring * 0.28)
				var rpr := pr * (1.0 - ring * 0.18)
				var rpc := 6 + ring * 2
				for i in rpc:
					var angle := float(i) / float(rpc) * TAU - PI * 0.5
					draw_circle(tip + Vector2(cos(angle), sin(angle)) * ro, rpr, pc.lightened(ring * 0.1))
			draw_circle(tip, 4.0 * sc, pc.lightened(0.35))

		"Ranunculus", "Peonies":
			for ring in 3:
				var ro  := orbit * (1.0 - ring * 0.28)
				var rpr := pr * (1.0 - ring * 0.18)
				var rpc := 6 + ring * 2
				for i in rpc:
					var angle := float(i) / float(rpc) * TAU - PI * 0.5
					draw_circle(tip + Vector2(cos(angle), sin(angle)) * ro, rpr, pc.lightened(ring * 0.12))
			draw_circle(tip, 4.0 * sc, Color(1.0, 0.92, 0.30))

		"Anemones", "Japanese Anemones", "Jpn Anemones":
			for i in pcount:
				var angle := float(i) / float(pcount) * TAU - PI * 0.5
				var p := tip + Vector2(cos(angle), sin(angle)) * orbit
				draw_colored_polygon(PackedVector2Array([
					tip,
					p + Vector2(-cos(angle + PI * 0.5), -sin(angle + PI * 0.5)) * pr * 0.85,
					p + Vector2(cos(angle), sin(angle)) * pr,
					p + Vector2(cos(angle + PI * 0.5), sin(angle + PI * 0.5)) * pr * 0.85,
				]), pc)
			draw_circle(tip, 5.0 * sc, Color(0.12, 0.08, 0.28))
			draw_circle(tip, 3.0 * sc, Color(1.0, 0.95, 0.30))

		"Sweet Peas":
			for side in [-1, 1]:
				draw_colored_polygon(PackedVector2Array([
					tip,
					Vector2(tip.x + side * orbit, tip.y - pr * 0.3),
					Vector2(tip.x + side * orbit * 0.7, tip.y + pr * 0.9),
				]), pc)
			draw_circle(tip, 3.5 * sc, Color(1.0, 0.94, 0.55))

		"Snapdragons":
			for k in 3:
				var ky := tip.y + k * 5.0 * sc
				draw_circle(Vector2(tip.x, ky), (7.0 - k * 1.5) * sc, pc.lightened(k * 0.1))
				draw_circle(Vector2(tip.x, ky), (7.0 - k * 1.5) * 0.5 * sc, pc.lightened(0.3))

		"Hellebores":
			for i in pcount:
				var angle := float(i) / float(pcount) * TAU + PI * 0.1
				var p := tip + Vector2(cos(angle), sin(angle) * 0.7 + 0.35) * orbit
				draw_circle(p, pr, pc)
				draw_circle(p, pr * 0.45, pc.lightened(0.25))
			draw_circle(Vector2(tip.x, tip.y + orbit * 0.35), 4.0 * sc, Color(0.94, 0.94, 0.50))

		"Paperwhites":
			for i in 5:
				var angle := float(i) / 5.0 * TAU
				var off := Vector2(cos(angle), sin(angle)) * orbit * 0.45
				for j in 6:
					var pa := float(j) / 6.0 * TAU
					draw_circle(tip + off + Vector2(cos(pa), sin(pa)) * pr * 0.7, pr * 0.45, Color(0.97, 0.97, 0.95))
				draw_circle(tip + off, 2.5 * sc, Color(0.95, 0.88, 0.20))

		"Winter Aconite":
			var ruff_r := orbit + pr + 2.0 * sc
			for i in 8:
				var angle := float(i) / 8.0 * TAU
				var p := tip + Vector2(cos(angle), sin(angle)) * ruff_r
				draw_colored_polygon(PackedVector2Array([
					tip + Vector2(cos(angle), sin(angle)) * (orbit - 2.0 * sc),
					p + Vector2(-sin(angle), cos(angle)) * 3.0 * sc,
					p + Vector2(sin(angle), -cos(angle)) * 3.0 * sc,
				]), Color(0.22, 0.62, 0.18))
			for i in pcount:
				var angle := float(i) / float(pcount) * TAU - PI * 0.5
				draw_circle(tip + Vector2(cos(angle), sin(angle)) * orbit, pr, pc)
			draw_circle(tip, 4.0 * sc, Color(1.0, 0.92, 0.22))

		"Camellias":
			for ring in 3:
				var ro  := orbit * (1.0 - ring * 0.25)
				var rpr := pr * (1.0 - ring * 0.15)
				var rpc := 8 - ring
				var roff := float(ring) * 0.35
				for i in rpc:
					var angle := float(i) / float(rpc) * TAU + roff - PI * 0.5
					draw_circle(tip + Vector2(cos(angle), sin(angle)) * ro, rpr, pc.lightened(ring * 0.08))
			draw_circle(tip, 3.5 * sc, Color(1.0, 0.90, 0.55))

		_:
			# Sunflower, Zinnias, Asters, Marigolds, and generic
			for i in pcount:
				var angle := float(i) / float(pcount) * TAU - PI * 0.5
				draw_circle(tip + Vector2(cos(angle), sin(angle)) * orbit, pr, pc)
			if name == "Sunflower":
				draw_circle(tip, 8.0 * sc, Color(0.30, 0.18, 0.04))
				draw_circle(tip, 4.0 * sc, Color(0.50, 0.28, 0.06))
			elif name == "Zinnias":
				draw_circle(tip, 7.0 * sc, Color(0.18, 0.52, 0.18))
				draw_circle(tip, 4.0 * sc, Color(0.12, 0.38, 0.12))
			else:
				draw_circle(tip, 6.5 * sc, Color(1.0, 0.92, 0.20))
				draw_circle(tip, 3.0 * sc, Color(1.0, 0.72, 0.10))


func _petal_count() -> int:
	match plant_data.display_name:
		"Sunflower":                                     return 16
		"Zinnias":                                       return 14
		"Dahlias", "Chrysanthemums":                     return 12
		"Asters", "Marigolds":                           return 20
		"Anemones", "Japanese Anemones", "Jpn Anemones": return 6
		"Ranunculus", "Peonies":                         return 8
		"Hellebores":                                    return 5
		"Winter Aconite":                                return 6
		"Camellias":                                     return 8
		_:                                               return 6


func _orbit() -> float:
	match plant_data.display_name:
		"Sunflower":                                     return 18.0
		"Zinnias":                                       return 14.0
		"Dahlias", "Chrysanthemums":                     return 14.0
		"Asters", "Marigolds":                           return 13.0
		"Ranunculus", "Peonies":                         return 14.0
		"Anemones", "Japanese Anemones", "Jpn Anemones": return 12.0
		"Sweet Peas":                                    return 13.0
		"Hellebores":                                    return 11.0
		"Paperwhites":                                   return 11.0
		"Winter Aconite":                                return 10.0
		"Camellias":                                     return 13.0
		_:                                               return 12.0


func _petal_r() -> float:
	match plant_data.display_name:
		"Sunflower":                                     return 8.0
		"Zinnias":                                       return 6.0
		"Dahlias":                                       return 7.0
		"Chrysanthemums":                                return 5.5
		"Asters", "Marigolds":                           return 4.5
		"Ranunculus", "Peonies":                         return 7.0
		"Anemones", "Japanese Anemones", "Jpn Anemones": return 8.0
		"Sweet Peas":                                    return 9.0
		"Hellebores":                                    return 8.0
		"Paperwhites":                                   return 5.0
		"Winter Aconite":                                return 7.0
		"Camellias":                                     return 7.5
		_:                                               return 7.0
