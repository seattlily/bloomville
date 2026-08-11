class_name PlantData
extends Resource

@export var display_name: String = ""
@export var season: GameClock.Season = GameClock.Season.SPRING
@export var growth_stages: int = 3
@export var days_per_stage: int = 2
@export var water_need_per_day: float = 0.3
@export var harvest_gold: int = 15
@export var seed_cost: int = 20
@export var color: Color = Color.WHITE
