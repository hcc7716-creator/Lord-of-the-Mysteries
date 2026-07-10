extends Node

signal date_changed(week: int, day: String, hour: int)
signal sunday_started(week: int)

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
		if is_sunday():
			sunday_started.emit(current_week)
	date_changed.emit(current_week, get_weekday(), hour)


func advance_time(hours: int) -> void:
	advance_hours(hours)


func get_current_day() -> int:
	return day_index + 1


func get_current_weekday() -> String:
	return get_weekday()


func get_weekday_name_cn() -> String:
	var names := ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
	return names[day_index]


func get_display_text() -> String:
	return "第 %d 周 %s %02d:00" % [current_week, get_weekday_name_cn(), hour]


func get_weekday() -> String:
	return WEEKDAYS[day_index]


func is_sunday() -> bool:
	return get_weekday() == "sunday"
