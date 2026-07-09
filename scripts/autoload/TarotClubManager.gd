extends Node

signal tarot_club_unlocked
signal tarot_request_completed(request_id: String)

var is_unlocked := false
var trust_level := 0
var completed_request_ids: Array[String] = []


func unlock_tarot_club() -> void:
	if is_unlocked:
		return
	is_unlocked = true
	MarketManager.add_unlock_flag("unlock_tarot_club")
	tarot_club_unlocked.emit()


func set_trust_level(value: int) -> void:
	trust_level = max(0, value)


func get_available_requests() -> Array:
	if not is_unlocked or not CalendarManager.is_sunday():
		return []
	var requests := DataManager.get_available_tarot_requests(CalendarManager.current_week, trust_level)
	var result: Array = []
	for request in requests:
		var request_id := str(request.get("request_id", ""))
		if not completed_request_ids.has(request_id):
			result.append(request)
	return result


func complete_request(request_id: String) -> bool:
	if DataManager.get_tarot_request(request_id).is_empty():
		return false
	if completed_request_ids.has(request_id):
		return false
	completed_request_ids.append(request_id)
	tarot_request_completed.emit(request_id)
	return true
