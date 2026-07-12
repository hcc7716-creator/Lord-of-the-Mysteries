extends Node

signal date_changed(week: int, day: String, hour: int)
signal sunday_started(week: int)
signal time_period_changed(period: String)

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
	time_period_changed.emit(get_time_period())


func advance_hours(hours: int) -> void:
	if hours <= 0:
		return
	var previous_period := get_time_period()
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
	if previous_period != get_time_period():
		time_period_changed.emit(get_time_period())


func advance_time(hours: int) -> void:
	advance_hours(hours)


func rest(hours: int = 8) -> void:
	var restore_amount := maxi(1, int(ceil(float(CorruptionManager.max_spirituality) * 0.6)))
	advance_hours(maxi(1, hours))
	CorruptionManager.restore_spirituality(restore_amount)
	CorruptionManager.reduce_corruption(2)
	GameManager.show_status_message("休息结束：恢复 %d 点灵性，时间推进至 %s" % [restore_amount, get_display_text()])


func get_current_day() -> int:
	return day_index + 1


func get_current_weekday() -> String:
	return get_weekday()


func get_weekday_name_cn() -> String:
	var names := ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
	return names[day_index]


func get_display_text() -> String:
	return "第 %d 周 %s %02d:00｜%s" % [current_week, get_weekday_name_cn(), hour, get_time_period_label()]


func get_weekday() -> String:
	return WEEKDAYS[day_index]


func is_sunday() -> bool:
	return get_weekday() == "sunday"


func get_time_period() -> String:
	if hour >= 6 and hour < 10:
		return "morning"
	if hour >= 10 and hour < 18:
		return "day"
	if hour >= 18 and hour < 22:
		return "evening"
	return "night"


func get_time_period_label() -> String:
	match get_time_period():
		"morning":
			return "早晨"
		"day":
			return "白天"
		"evening":
			return "傍晚"
		_:
			return "夜晚"


func matches_open_window(window: String) -> bool:
	if window == "daily":
		return true
	if window == "conditional_safe_window":
		return false
	var parts := window.split("_")
	if parts.is_empty():
		return false
	if parts[0] == "daily" and parts.size() > 1:
		return parts[1] == get_time_period()
	if parts[0] != get_weekday():
		return false
	if parts.size() == 1:
		return true
	if window == "sunday_gray_fog_meeting":
		return is_sunday()
	return parts[1] == get_time_period()
