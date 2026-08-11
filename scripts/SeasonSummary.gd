extends CanvasLayer

signal dismissed

const SEASON_NAMES := ["Spring", "Summer", "Fall", "Winter"]

var _bg: ColorRect
var _title: Label
var _harvests_label: Label
var _gold_label: Label
var _next_label: Label


func _ready() -> void:
	layer = 3
	_build_ui()
	_bg.visible = false


func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.68)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(380, 0)
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(_title)

	vbox.add_child(HSeparator.new())

	_harvests_label = Label.new()
	_harvests_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_harvests_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_harvests_label)

	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_gold_label)

	vbox.add_child(HSeparator.new())

	_next_label = Label.new()
	_next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_next_label.modulate = Color(0.75, 0.75, 0.75)
	vbox.add_child(_next_label)

	var btn := Button.new()
	btn.text = "Continue"
	btn.pressed.connect(_on_continue)
	vbox.add_child(btn)


func show_for_season(ended_season: GameClock.Season, new_season: GameClock.Season) -> void:
	_title.text = "%s is over" % SEASON_NAMES[ended_season]
	_harvests_label.text = "Harvests: %d" % GameState.season_harvests
	_gold_label.text = "Gold earned: %d" % GameState.season_gold
	_next_label.text = "%s begins..." % SEASON_NAMES[new_season]
	_bg.visible = true
	GameState.overlay_open = true


func _on_continue() -> void:
	_bg.visible = false
	GameState.overlay_open = false
	GameState.reset_season_stats()
	dismissed.emit()
