class_name PlantInstance
extends RefCounted

var data: PlantData
var stage: int = 0
var days_in_stage: int = 0


func _init(plant_data: PlantData) -> void:
	data = plant_data


func is_mature() -> bool:
	return stage >= data.growth_stages


func try_grow(tile_moisture: float) -> void:
	if is_mature():
		return
	if tile_moisture >= data.water_need_per_day:
		days_in_stage += 1
		if days_in_stage >= data.days_per_stage:
			stage += 1
			days_in_stage = 0
