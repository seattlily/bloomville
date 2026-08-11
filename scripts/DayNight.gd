extends CanvasLayer

var _overlay: ColorRect
var _season_overlay: ColorRect

const SEASON_TINTS := {
	GameClock.Season.SPRING: Color(0.30, 0.75, 0.20, 0.10),
	GameClock.Season.SUMMER: Color(0.88, 0.68, 0.12, 0.09),
	GameClock.Season.FALL:   Color(0.80, 0.38, 0.06, 0.13),
	GameClock.Season.WINTER: Color(0.50, 0.62, 0.90, 0.14),
}

const SKY_GRADIENT: Array = [
	[0.00, Color(0.04, 0.04, 0.15)],
	[0.18, Color(0.12, 0.08, 0.24)],
	[0.25, Color(0.80, 0.38, 0.18)],
	[0.33, Color(0.55, 0.72, 0.92)],
	[0.50, Color(0.38, 0.62, 0.95)],
	[0.67, Color(0.55, 0.72, 0.92)],
	[0.75, Color(0.82, 0.38, 0.18)],
	[0.85, Color(0.28, 0.08, 0.26)],
	[1.00, Color(0.04, 0.04, 0.15)],
]


func _ready() -> void:
	layer = 0
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = Color.TRANSPARENT
	add_child(_overlay)

	_season_overlay = ColorRect.new()
	_season_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_season_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_season_overlay.color = Color.TRANSPARENT
	add_child(_season_overlay)


func _process(_delta: float) -> void:
	var t := GameClock.time_of_day
	RenderingServer.set_default_clear_color(_sky_color(t))
	var night_alpha := 0.48 * (1.0 - sin(t * PI))
	_overlay.color = Color(0.0, 0.02, 0.12, night_alpha)
	_season_overlay.color = SEASON_TINTS[GameClock.current_season]


func _sky_color(t: float) -> Color:
	for i in range(SKY_GRADIENT.size() - 1):
		var t0: float = SKY_GRADIENT[i][0]
		var t1: float = SKY_GRADIENT[i + 1][0]
		if t <= t1:
			var frac := (t - t0) / (t1 - t0)
			return (SKY_GRADIENT[i][1] as Color).lerp(SKY_GRADIENT[i + 1][1], frac)
	return SKY_GRADIENT[-1][1] as Color
