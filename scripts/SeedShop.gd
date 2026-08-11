extends CanvasLayer

var _gold_label: Label
var _buy_buttons: Dictionary = {}
var _overlay: Control


func _ready() -> void:
	_build_ui()
	GameState.gold_changed.connect(_on_gold_changed)
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
	vbox.custom_minimum_size = Vector2(460, 0)
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

	var sep := HSeparator.new()
	vbox.add_child(sep)

	for plant_name in GameState.all_plants:
		var data := GameState.all_plants[plant_name] as PlantData
		vbox.add_child(_plant_row(plant_name, data))

	var close_btn := Button.new()
	close_btn.text = "Close  [Tab]"
	close_btn.pressed.connect(hide_shop)
	vbox.add_child(close_btn)


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
	name_lbl.custom_minimum_size = Vector2(90, 0)
	row.add_child(name_lbl)

	var season_lbl := Label.new()
	season_lbl.text = GameClock.Season.keys()[data.season].capitalize()
	season_lbl.custom_minimum_size = Vector2(70, 0)
	season_lbl.modulate = Color(0.75, 0.75, 0.75)
	row.add_child(season_lbl)

	var harvest_lbl := Label.new()
	harvest_lbl.text = "Sells for %dg" % data.harvest_gold
	harvest_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	harvest_lbl.modulate = Color(0.75, 0.75, 0.75)
	row.add_child(harvest_lbl)

	var buy_btn := Button.new()
	buy_btn.text = "Buy  %dg" % data.seed_cost
	buy_btn.disabled = GameState.gold < data.seed_cost
	var captured_name: String = plant_name
	var captured_cost: int = data.seed_cost
	buy_btn.pressed.connect(func():
		if GameState.spend_gold(captured_cost):
			GameState.add_seed(captured_name, 1)
	)
	_buy_buttons[plant_name] = buy_btn
	row.add_child(buy_btn)

	return row


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
