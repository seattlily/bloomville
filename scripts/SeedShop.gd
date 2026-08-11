extends CanvasLayer

var _gold_label: Label
var _buy_buttons: Dictionary = {}  # plant_name -> Button (current season only)
var _plant_list_vbox: VBoxContainer
var _overlay: Control


func _ready() -> void:
	_build_ui()
	GameState.gold_changed.connect(_on_gold_changed)
	GameClock.season_changed.connect(_on_season_changed)
	hide_shop()


func _build_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.55)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.custom_minimum_size = Vector2(480, 0)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var title := Label.new()
	title.text = "Seed Shop"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)

	_gold_label = Label.new()
	_gold_label.text = "Gold: %d" % GameState.gold
	header.add_child(_gold_label)

	vbox.add_child(HSeparator.new())

	_plant_list_vbox = VBoxContainer.new()
	_plant_list_vbox.add_theme_constant_override("separation", 8)
	vbox.add_child(_plant_list_vbox)

	_build_season_rows()

	var close_btn := Button.new()
	close_btn.text = "Close  [Tab]"
	close_btn.pressed.connect(hide_shop)
	vbox.add_child(close_btn)


func _build_season_rows() -> void:
	for child in _plant_list_vbox.get_children():
		child.queue_free()
	_buy_buttons.clear()

	var season_plants := GameState.plants_for_season(GameClock.current_season)

	var season_header := Label.new()
	season_header.text = "%s Seeds" % GameClock.get_season_name()
	season_header.add_theme_font_size_override("font_size", 14)
	season_header.modulate = Color(0.85, 0.85, 0.65)
	_plant_list_vbox.add_child(season_header)

	for plant_name in season_plants:
		var data := GameState.all_plants[plant_name] as PlantData
		_plant_list_vbox.add_child(_plant_row(plant_name, data))


func _plant_row(plant_name: String, data: PlantData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var dot := ColorRect.new()
	dot.color = data.color
	dot.custom_minimum_size = Vector2(16, 16)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(dot)

	var name_lbl := Label.new()
	name_lbl.text = data.display_name
	name_lbl.custom_minimum_size = Vector2(120, 0)
	row.add_child(name_lbl)

	var harvest_lbl := Label.new()
	harvest_lbl.text = "Sells for %dg" % data.harvest_gold
	harvest_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	harvest_lbl.modulate = Color(0.75, 0.75, 0.75)
	row.add_child(harvest_lbl)

	var owned_lbl := Label.new()
	owned_lbl.text = "x%d" % GameState.seeds.get(plant_name, 0)
	owned_lbl.custom_minimum_size = Vector2(32, 0)
	owned_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(owned_lbl)

	var buy_btn := Button.new()
	buy_btn.text = "Buy  %dg" % data.seed_cost
	buy_btn.disabled = GameState.gold < data.seed_cost
	var captured_name: String = plant_name
	var captured_cost: int = data.seed_cost
	buy_btn.pressed.connect(func():
		if GameState.spend_gold(captured_cost):
			GameState.add_seed(captured_name, 1)
			GameState.log_purchase(captured_name, captured_cost)
			owned_lbl.text = "x%d" % GameState.seeds.get(captured_name, 0)
	)
	_buy_buttons[plant_name] = buy_btn
	row.add_child(buy_btn)

	return row


func _on_season_changed(_new_season: GameClock.Season, _year: int) -> void:
	_build_season_rows()


func toggle() -> void:
	if GameState.shop_open:
		hide_shop()
	else:
		show_shop()


func show_shop() -> void:
	_overlay.visible = true
	GameState.shop_open = true
	_on_gold_changed(GameState.gold)


func hide_shop() -> void:
	_overlay.visible = false
	GameState.shop_open = false


func _on_gold_changed(amount: int) -> void:
	_gold_label.text = "Gold: %d" % amount
	for plant_name in _buy_buttons:
		var data := GameState.all_plants[plant_name] as PlantData
		_buy_buttons[plant_name].disabled = amount < data.seed_cost
