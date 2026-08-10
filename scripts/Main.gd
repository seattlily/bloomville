extends Node2D

func _ready() -> void:
	GameClock.day_started.connect(_on_day_started)
	GameClock.season_changed.connect(_on_season_changed)


func _on_day_started(day: int, _season: GameClock.Season, _year: int) -> void:
	print("[Clock] Day %d of %s, Year %d" % [day, GameClock.get_season_name(), GameClock.current_year])


func _on_season_changed(_season: GameClock.Season, year: int) -> void:
	print("[Clock] Season changed to %s, Year %d" % [GameClock.get_season_name(), year])


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match event.keycode:
		KEY_F5:
			GameState.save_game()
			print("[Save] Game saved.")
		KEY_F9:
			if GameState.load_game():
				print("[Save] Game loaded.")
