extends Node

signal visual_state_changed(palette_name: String, weather_state: String)

const DAY_COLOR := Color(0.82, 0.79, 0.68, 1.0)
const EVENING_COLOR := Color(0.65, 0.68, 0.7, 1.0)
const NIGHT_COLOR := Color(0.56, 0.65, 0.78, 1.0)
const RAIN_DAY_COLOR := Color(0.58, 0.61, 0.6, 1.0)
const RAIN_NIGHT_COLOR := Color(0.34, 0.43, 0.56, 1.0)

@export_enum("clear", "rain") var weather_state := "clear"

@onready var canvas_modulate := get_node("../CanvasModulate") as CanvasModulate
@onready var distant_fog := get_node("../Background/DistantFog") as Node2D
@onready var near_fog := get_node("../ForegroundEffects/NearFog") as Node2D
@onready var local_lights := get_node("../LocalLights") as Node2D

var _elapsed := 0.0
var _base_light_energy: Dictionary = {}
var _palette_tween: Tween


func _ready() -> void:
	for child in local_lights.get_children():
		if child is PointLight2D:
			_base_light_energy[child.name] = child.energy
	if not CalendarManager.time_period_changed.is_connected(_on_time_period_changed):
		CalendarManager.time_period_changed.connect(_on_time_period_changed)
	refresh_visual_state(false)


func _process(delta: float) -> void:
	_elapsed += delta
	# Separate, low-amplitude drift keeps the fog layered without moving gameplay nodes.
	distant_fog.position = Vector2(sin(_elapsed * 0.035) * 12.0, cos(_elapsed * 0.025) * 4.0)
	near_fog.position = Vector2(sin(_elapsed * 0.075) * 20.0, cos(_elapsed * 0.05) * 7.0)


func set_weather_state(next_state: String) -> void:
	weather_state = "rain" if next_state == "rain" else "clear"
	refresh_visual_state(true)


func refresh_visual_state(animate: bool = true) -> void:
	var period := CalendarManager.get_time_period()
	var target_color := _get_palette_color(period)
	if _palette_tween != null and _palette_tween.is_valid():
		_palette_tween.kill()
	if animate and is_inside_tree():
		_palette_tween = create_tween()
		_palette_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_palette_tween.tween_property(canvas_modulate, "color", target_color, 1.2)
	else:
		canvas_modulate.color = target_color
	_update_light_energy(period)
	visual_state_changed.emit(get_palette_name(), weather_state)


func get_palette_name() -> String:
	var period := CalendarManager.get_time_period()
	if weather_state == "rain" and period in ["evening", "night"]:
		return "rain_night"
	if period in ["morning", "day"]:
		return "day"
	if period == "evening":
		return "evening"
	return "night"


func _get_palette_color(period: String) -> Color:
	if weather_state == "rain":
		if period in ["evening", "night"]:
			return RAIN_NIGHT_COLOR
		return RAIN_DAY_COLOR
	match period:
		"morning", "day":
			return DAY_COLOR
		"evening":
			return EVENING_COLOR
		_:
			return NIGHT_COLOR


func _update_light_energy(period: String) -> void:
	var multiplier := 1.0
	match period:
		"morning":
			multiplier = 0.5
		"day":
			multiplier = 0.34
		"evening":
			multiplier = 0.86
	if weather_state == "rain":
		multiplier *= 1.08
	for child in local_lights.get_children():
		if not child is PointLight2D:
			continue
		var base_energy := float(_base_light_energy.get(child.name, child.energy))
		if child.name == "RitualGlow":
			child.energy = base_energy * maxf(multiplier, 0.78)
		else:
			child.energy = base_energy * multiplier


func _on_time_period_changed(_period: String) -> void:
	refresh_visual_state(true)
