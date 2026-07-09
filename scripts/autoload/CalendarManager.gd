extends Node

signal date_changed(week: int, day: String, hour: int)

const WEEKDAYS: Array[String] = [
	"monday",
	"tuesday",
	"wednesday",
	"thursday",
	"friday",
	"saturday",
	"sunday",
]

var current_week := 1
var day_index := 0
var hour := 8


func reset_calendar() -> void:
	current_week = 1
	day_index = 0
	hour = 8
	date_changed.emit(current_week, get_weekday(), hour)


func advance_hours(hours: int) -> void:
	if hours <= 0:
		return
	hour += hours
	while hour >= 24:
		hour -= 24
		day_index += 1
		if day_index >= WEEKDAYS.size():
			day_index = 0
			current_week += 1
	date_changed.emit(current_week, get_weekday(), hour)


func get_weekday() -> String:
	return WEEKDAYS[day_index]


func is_sunday() -> bool:
	return get_weekday() == "sunday"
