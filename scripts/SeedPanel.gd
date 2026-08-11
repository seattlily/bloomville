extends CanvasLayer

signal open_shop_requested

const PREVIEW_H: float = 90.0
const BUTTON_H: float  = 60.0

const FlowerPreviewCell := preload("res://scripts/FlowerPreviewCell.gd")

var _buttons: Dictionary = {}
var _group: ButtonGroup


func _ready() -> void:
	_group = ButtonGroup.new()
	_build_ui()
	GameState.seeds_changed.connect(_refresh_buttons)


func _build_ui() -> void:
	var total_h := PREVIEW_H + BUTTON_H
	var anchor := Control.new()
	anchor.anchor_left   = 0.0
	anchor.anchor_right  = 1.0
	anchor.anchor_top    = 1.0
	anchor.anchor_bottom = 1.0
	anchor.offset_top    = -total_h
	anchor.offset_bottom = 0.0
	add_child(anchor)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	# ── Flower preview strip ──────────────────────────────────────
	var preview_row := HBoxContainer.new()
	preview_row.custom_minimum_size = Vector2(0, PREVIEW_H)
	preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_row.add_theme_constant_override("separation", 12)
	vbox.add_child(preview_row)

	var preview_label := Label.new()
	preview_label.text = "Full bloom:"
	preview_label.add_theme_font_size_override("font_size", 11)
	preview_label.modulate = Color(0.75, 0.75, 0.75)
	preview_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview_row.add_child(preview_label)

	for plant_name in GameState.all_plants:
		var data := GameState.all_plants[plant_name] as PlantData
		preview_row.add_child(_make_preview_cell(data))

	vbox.add_child(HSeparator.new())

	# ── Seed buttons row ──────────────────────────────────────────
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.custom_minimum_size = Vector2(0, BUTTON_H)
	vbox.add_child(hbox)

	var mode_label := Label.new()
	mode_label.text = "Plant: "
	hbox.add_child(mode_label)

	for plant_name in GameState.all_plants:
		var data := GameState.all_plants[plant_name] as PlantData
		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_group = _group
		btn.custom_minimum_size = Vector2(110, 0)
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
	water_btn.text = "🪣 Water"
	water_btn.toggle_mode = true
	water_btn.button_group = _group
	water_btn.button_pressed = true
	water_btn.custom_minimum_size = Vector2(90, 0)
	water_btn.toggled.connect(func(pressed: bool):
		if pressed:
			GameState.selected_plant = null
	)
	hbox.add_child(water_btn)

	var shop_btn := Button.new()
	shop_btn.text = "Shop  [Tab]"
	shop_btn.custom_minimum_size = Vector2(100, 0)
	shop_btn.pressed.connect(func(): open_shop_requested.emit())
	hbox.add_child(shop_btn)


func _make_preview_cell(data: PlantData) -> Control:
	var cell := Control.new()
	cell.custom_minimum_size = Vector2(80, PREVIEW_H - 8)

	var lbl := Label.new()
	lbl.text = data.display_name
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.anchor_left   = 0.0
	lbl.anchor_right  = 1.0
	lbl.anchor_top    = 1.0
	lbl.anchor_bottom = 1.0
	lbl.offset_top    = -16
	lbl.offset_bottom = 0.0
	cell.add_child(lbl)

	var canvas := FlowerPreviewCell.new()
	canvas.plant_data = data
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.offset_bottom = -16
	cell.add_child(canvas)

	return cell


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
