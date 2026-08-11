extends CanvasLayer

const SEASON_NAMES := ["Spring", "Summer", "Fall", "Winter"]
const SEASON_COLORS := [
	Color(0.40, 0.78, 0.42),  # Spring green
	Color(0.98, 0.82, 0.20),  # Summer yellow
	Color(0.88, 0.48, 0.18),  # Fall orange
	Color(0.62, 0.80, 0.95),  # Winter blue
]

var _overlay: Control
var _wallet_vbox: VBoxContainer
var _seed_grid: GridContainer


func _ready() -> void:
	layer = 10
	_build_ui()
	_overlay.visible = false


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.70)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 14)
	outer_vbox.custom_minimum_size = Vector2(720, 0)
	panel.add_child(outer_vbox)

	# ── Header ──────────────────────────────────────────────────
	var header_hbox := HBoxContainer.new()
	outer_vbox.add_child(header_hbox)

	var title := Label.new()
	title.text = "Garden: %s" % GameState.gardener_name
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	header_hbox.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "Resume  [ESC]"
	close_btn.pressed.connect(hide_menu)
	header_hbox.add_child(close_btn)

	outer_vbox.add_child(HSeparator.new())

	# ── Two-column layout ────────────────────────────────────────
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	outer_vbox.add_child(columns)

	# Left: Seed Pouch
	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 8)
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left_vbox)

	var seed_title := Label.new()
	seed_title.text = "Seed Pouch"
	seed_title.add_theme_font_size_override("font_size", 16)
	left_vbox.add_child(seed_title)

	_seed_grid = GridContainer.new()
	_seed_grid.columns = 2
	_seed_grid.add_theme_constant_override("h_separation", 8)
	_seed_grid.add_theme_constant_override("v_separation", 4)
	left_vbox.add_child(_seed_grid)

	# Right: Wallet
	var right_vbox := VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 8)
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right_vbox)

	var wallet_title := Label.new()
	wallet_title.text = "Wallet"
	wallet_title.add_theme_font_size_override("font_size", 16)
	right_vbox.add_child(wallet_title)

	var gold_lbl := Label.new()
	gold_lbl.text = "Gold: %d" % GameState.gold
	gold_lbl.add_theme_font_size_override("font_size", 18)
	right_vbox.add_child(gold_lbl)
	GameState.gold_changed.connect(func(g): gold_lbl.text = "Gold: %d" % g)

	var log_header := Label.new()
	log_header.text = "Recent transactions:"
	log_header.modulate = Color(0.75, 0.75, 0.75)
	right_vbox.add_child(log_header)

	_wallet_vbox = VBoxContainer.new()
	_wallet_vbox.add_theme_constant_override("separation", 3)
	right_vbox.add_child(_wallet_vbox)

	outer_vbox.add_child(HSeparator.new())

	# ── Buttons row ──────────────────────────────────────────────
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	outer_vbox.add_child(btn_row)

	var save_btn := Button.new()
	save_btn.text = "Save Game"
	save_btn.pressed.connect(func():
		GameState.save_game()
		save_btn.text = "Saved!"
		get_tree().create_timer(1.5).timeout.connect(func(): save_btn.text = "Save Game")
	)
	btn_row.add_child(save_btn)

	var exit_btn := Button.new()
	exit_btn.text = "Exit to Desktop"
	exit_btn.pressed.connect(func():
		GameState.save_game()
		get_tree().quit()
	)
	btn_row.add_child(exit_btn)


func show_menu() -> void:
	_overlay.visible = true
	GameState.overlay_open = true
	_refresh_seeds()
	_refresh_log()


func hide_menu() -> void:
	_overlay.visible = false
	GameState.overlay_open = false


func toggle() -> void:
	if _overlay.visible:
		hide_menu()
	else:
		show_menu()


func _refresh_seeds() -> void:
	for child in _seed_grid.get_children():
		child.queue_free()

	for season_idx in 4:
		var season := season_idx as GameClock.Season
		var season_plants := GameState.plants_for_season(season)

		var season_lbl := Label.new()
		season_lbl.text = SEASON_NAMES[season_idx]
		season_lbl.modulate = SEASON_COLORS[season_idx]
		season_lbl.add_theme_font_size_override("font_size", 12)
		_seed_grid.add_child(season_lbl)

		var plants_hbox := HBoxContainer.new()
		plants_hbox.add_theme_constant_override("separation", 6)
		_seed_grid.add_child(plants_hbox)

		for plant_name in season_plants:
			var data := GameState.all_plants[plant_name] as PlantData
			var count := GameState.seeds.get(plant_name, 0)
			var entry := Label.new()
			entry.text = "%s x%d" % [data.display_name, count]
			if count == 0:
				entry.modulate = Color(0.55, 0.55, 0.55)
			plants_hbox.add_child(entry)


func _refresh_log() -> void:
	for child in _wallet_vbox.get_children():
		child.queue_free()

	var shown := mini(GameState.transaction_log.size(), 12)
	for i in shown:
		var entry: Dictionary = GameState.transaction_log[i]
		var type: String = entry.get("type", "")
		var detail: String = entry.get("detail", "")
		var amount: int = entry.get("amount", 0)
		var day: int = entry.get("day", 0)
		var season_idx: int = entry.get("season", 0)
		var season_short := SEASON_NAMES[season_idx].substr(0, 3)

		var sign_str := "+" if amount >= 0 else ""
		var row_color := Color(0.45, 0.85, 0.45) if amount >= 0 else Color(0.95, 0.55, 0.40)

		var lbl := Label.new()
		lbl.text = "[%s D%d] %s %s — %s%dg" % [season_short, day, type.capitalize(), detail, sign_str, amount]
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.modulate = row_color
		_wallet_vbox.add_child(lbl)
