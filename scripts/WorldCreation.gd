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

const BIOME_LABELS := ["Forest", "Desert", "Beach", "Mountain"]
const SEASON_LABELS := ["Spring", "Summer", "Fall", "Winter"]

var _selected_biome: GameState.Biome = GameState.Biome.FOREST
var _selected_season: GameClock.Season = GameClock.Season.SPRING
var _name_input: LineEdit
var _pending_slot: int = 0

var _slot_screen: Control
var _new_game_screen: Control


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Slot selection screen
	_slot_screen = _build_slot_screen()
	root.add_child(_slot_screen)

	# New game setup screen (hidden until a slot is chosen for a new game)
	_new_game_screen = _build_new_game_screen()
	_new_game_screen.visible = false
	root.add_child(_new_game_screen)


func _build_slot_screen() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.08, 0.10, 0.08, 0.92)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.custom_minimum_size = Vector2(540, 0)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "Bloomville"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Choose a save slot"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.modulate = Color(0.70, 0.80, 0.70)
	vbox.add_child(sub)

	for slot in GameState.SAVE_SLOTS:
		vbox.add_child(_build_slot_card(slot))

	return overlay


func _build_slot_card(slot: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 90)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	card.add_child(hbox)

	var slot_lbl := Label.new()
	slot_lbl.text = "Slot %d" % (slot + 1)
	slot_lbl.custom_minimum_size = Vector2(52, 0)
	slot_lbl.add_theme_font_size_override("font_size", 13)
	slot_lbl.modulate = Color(0.65, 0.65, 0.65)
	slot_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(slot_lbl)

	var meta := GameState.get_slot_metadata(slot)
	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 3)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(info_vbox)

	if meta.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Empty"
		empty_lbl.modulate = Color(0.55, 0.55, 0.55)
		info_vbox.add_child(empty_lbl)
	else:
		var name_lbl := Label.new()
		name_lbl.text = meta.get("gardener_name", "Gardener")
		name_lbl.add_theme_font_size_override("font_size", 15)
		info_vbox.add_child(name_lbl)

		var season_idx: int = meta.get("season", 0)
		var biome_idx: int  = meta.get("biome", 0)
		var detail := Label.new()
		detail.text = "%s  •  Day %d, Year %d  •  %s  •  %dg" % [
			SEASON_LABELS[season_idx],
			meta.get("day", 1),
			meta.get("year", 1),
			BIOME_LABELS[biome_idx],
			meta.get("gold", 100),
		]
		detail.add_theme_font_size_override("font_size", 11)
		detail.modulate = Color(0.72, 0.78, 0.72)
		info_vbox.add_child(detail)

	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 4)
	btn_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(btn_vbox)

	if not meta.is_empty():
		var continue_btn := Button.new()
		continue_btn.text = "Continue"
		continue_btn.custom_minimum_size = Vector2(90, 0)
		var captured_slot: int = slot
		continue_btn.pressed.connect(func(): _load_slot(captured_slot))
		btn_vbox.add_child(continue_btn)

	var new_btn := Button.new()
	new_btn.text = "New Game" if not meta.is_empty() else "New Garden"
	new_btn.custom_minimum_size = Vector2(90, 0)
	var captured_slot: int = slot
	new_btn.pressed.connect(func(): _start_new_in_slot(captured_slot))
	btn_vbox.add_child(new_btn)

	return card


func _build_new_game_screen() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.08, 0.10, 0.08, 0.92)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

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

	vbox.add_child(_section_label("Gardener Name"))
	_name_input = LineEdit.new()
	_name_input.text = "Gardener"
	_name_input.placeholder_text = "Enter your name..."
	_name_input.max_length = 24
	_name_input.custom_minimum_size = Vector2(0, 36)
	vbox.add_child(_name_input)

	vbox.add_child(_section_label("Choose Your Biome"))
	vbox.add_child(_button_row(BIOMES, func(id): _selected_biome = id, _selected_biome))

	vbox.add_child(_section_label("Starting Season"))
	vbox.add_child(_button_row(SEASONS, func(id): _selected_season = id, _selected_season))

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.pressed.connect(func():
		_slot_screen.visible = true
		_new_game_screen.visible = false
	)
	btn_row.add_child(back_btn)

	var start_btn := Button.new()
	start_btn.text = "Start"
	start_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_btn.pressed.connect(_on_start_pressed)
	btn_row.add_child(start_btn)

	return overlay


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


func _load_slot(slot: int) -> void:
	GameState.save_slot = slot
	GameState.load_game()
	world_created.emit()


func _start_new_in_slot(slot: int) -> void:
	_pending_slot = slot
	_slot_screen.visible = false
	_new_game_screen.visible = true


func _on_start_pressed() -> void:
	var name_text := _name_input.text.strip_edges()
	GameState.gardener_name    = name_text if name_text.length() > 0 else "Gardener"
	GameState.biome            = _selected_biome
	GameState.save_slot        = _pending_slot
	GameState.starting_season  = _selected_season
	GameClock.set_starting_season(_selected_season)
	GameState.start_new_game()
	world_created.emit()
