extends CanvasLayer

var _buttons: Dictionary = {}
var _group: ButtonGroup


func _ready() -> void:
	_group = ButtonGroup.new()
	_build_ui()
	GameState.seeds_changed.connect(_refresh_buttons)


func _build_ui() -> void:
	var anchor := Control.new()
	anchor.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	anchor.custom_minimum_size = Vector2(0, 56)
	add_child(anchor)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	var mode_label := Label.new()
	mode_label.text = "Plant: "
	hbox.add_child(mode_label)

	for plant_name in GameState.all_plants:
		var data := GameState.all_plants[plant_name] as PlantData
		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_group = _group
		btn.custom_minimum_size = Vector2(100, 0)
		_set_button_text(btn, data, GameState.seeds.get(plant_name, 0))
		btn.disabled = GameState.seeds.get(plant_name, 0) == 0
		var captured_name: String = plant_name
		var captured_data: PlantData = data
		btn.toggled.connect(func(pressed: bool):
			GameState.selected_plant = captured_data if pressed else null
		)
		_buttons[plant_name] = btn
		hbox.add_child(btn)

	var water_btn := Button.new()
	water_btn.text = "Water"
	water_btn.toggle_mode = true
	water_btn.button_group = _group
	water_btn.button_pressed = true
	water_btn.custom_minimum_size = Vector2(80, 0)
	water_btn.toggled.connect(func(pressed: bool):
		if pressed:
			GameState.selected_plant = null
	)
	hbox.add_child(water_btn)


func _refresh_buttons() -> void:
	for plant_name in _buttons:
		var data := GameState.all_plants[plant_name] as PlantData
		var count: int = GameState.seeds.get(plant_name, 0)
		var btn: Button = _buttons[plant_name]
		_set_button_text(btn, data, count)
		btn.disabled = count == 0
		if btn.disabled and btn.button_pressed:
			btn.button_pressed = false
			GameState.selected_plant = null


func _set_button_text(btn: Button, data: PlantData, count: int) -> void:
	btn.text = "%s (%d)" % [data.display_name, count]
