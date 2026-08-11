extends CanvasLayer

var _day_label: Label
var _time_label: Label
var _time_bar: ProgressBar
var _gold_label: Label
var _save_label: Label
var _save_timer: float = 0.0
const SAVE_FLASH_DURATION: float = 2.5


func _ready() -> void:
	_build_ui()
	GameClock.day_started.connect(_on_day_started)
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.autosave_fired.connect(_on_autosave_fired)
	_refresh_day(GameClock.current_day, GameClock.current_season, GameClock.current_year)
	_on_gold_changed(GameState.gold)


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(10, 10)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	_day_label = Label.new()
	_day_label.custom_minimum_size = Vector2(300, 0)
	vbox.add_child(_day_label)

	_time_bar = ProgressBar.new()
	_time_bar.custom_minimum_size = Vector2(300, 10)
	_time_bar.max_value = 1.0
	_time_bar.show_percentage = false
	vbox.add_child(_time_bar)

	_time_label = Label.new()
	_time_label.add_theme_font_size_override("font_size", 11)
	_time_label.modulate = Color(0.75, 0.75, 0.75)
	vbox.add_child(_time_label)

	_gold_label = Label.new()
	vbox.add_child(_gold_label)

	_save_label = Label.new()
	_save_label.add_theme_font_size_override("font_size", 11)
	_save_label.modulate = Color(0.55, 0.95, 0.55)
	_save_label.visible = false
	vbox.add_child(_save_label)


func _process(delta: float) -> void:
	_time_bar.value = GameClock.time_of_day
	_time_label.text = GameClock.get_time_string()
	if _save_timer > 0.0:
		_save_timer -= delta
		if _save_timer <= 0.0:
			_save_label.visible = false


func _on_day_started(day: int, season: GameClock.Season, year: int) -> void:
	_refresh_day(day, season, year)


func _refresh_day(day: int, _season: GameClock.Season, year: int) -> void:
	_day_label.text = "Day %d  |  %s  |  Year %d" % [day, GameClock.get_season_name(), year]


func _on_gold_changed(amount: int) -> void:
	_gold_label.text = "Gold: %d" % amount


func _on_autosave_fired() -> void:
	_save_label.text = "AUTOSAVED"
	_save_label.visible = true
	_save_timer = SAVE_FLASH_DURATION


func flash_saved() -> void:
	_save_label.text = "SAVED"
	_save_label.visible = true
	_save_timer = SAVE_FLASH_DURATION
