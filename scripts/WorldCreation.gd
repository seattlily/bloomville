extends CanvasLayer

signal world_created

const BIOMES := [
	{ "id": GameState.Biome.FOREST,   "label": "Forest" },
	{ "id": GameState.Biome.DESERT,   "label": "Desert" },
	{ "id": GameState.Biome.BEACH,    "label": "Beach" },
	{ "id": GameState.Biome.MOUNTAIN, "label": "Mountain" },
]

const SEASONS := [
	{ "id": GameClock.Season.SPRING, "label": "Spring" },
	{ "id": GameClock.Season.SUMMER, "label": "Summer" },
	{ "id": GameClock.Season.FALL,   "label": "Fall" },
	{ "id": GameClock.Season.WINTER, "label": "Winter" },
]

var _selected_biome: GameState.Biome = GameState.Biome.FOREST
var _selected_season: GameClock.Season = GameClock.Season.SPRING


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.custom_minimum_size = Vector2(420, 0)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "New Garden"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	vbox.add_child(_section_label("Choose Your Biome"))
	vbox.add_child(_button_row(BIOMES, func(id): _selected_biome = id, _selected_biome))

	vbox.add_child(_section_label("Starting Season"))
	vbox.add_child(_button_row(SEASONS, func(id): _selected_season = id, _selected_season))

	var start_btn := Button.new()
	start_btn.text = "Start"
	start_btn.pressed.connect(_on_start_pressed)
	vbox.add_child(start_btn)


func _section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	return lbl


func _button_row(items: Array, on_select: Callable, default_id) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	var group := ButtonGroup.new()
	for item in items:
		var btn := Button.new()
		btn.text = item["label"]
		btn.toggle_mode = true
		btn.button_group = group
		if item["id"] == default_id:
			btn.button_pressed = true
		var captured_id = item["id"]
		btn.toggled.connect(func(pressed): if pressed: on_select.call(captured_id))
		hbox.add_child(btn)
	return hbox


func _on_start_pressed() -> void:
	GameState.biome = _selected_biome
	GameClock.set_starting_season(_selected_season)
	world_created.emit()
