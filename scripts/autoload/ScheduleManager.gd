extends Node

signal npc_schedule_updated(npc: Node, schedule_entry: Dictionary)

var schedules: Dictionary = {}
var tracked_npcs: Array[Node] = []


func _ready() -> void:
	_load_schedules()
	CalendarManager.date_changed.connect(_on_date_changed)


func _load_schedules() -> void:
	schedules.clear()
	var path := "res://data/npc_schedules.json"
	if not FileAccess.file_exists(path):
		push_error("ScheduleManager: missing npc schedules")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("ScheduleManager: invalid npc schedules")
		return
	for schedule in parsed:
		if typeof(schedule) == TYPE_DICTIONARY and str(schedule.get("schedule_id", "")) != "":
			schedules[str(schedule["schedule_id"])] = schedule


func register_npc(npc: Node) -> void:
	if npc == null or tracked_npcs.has(npc):
		return
	tracked_npcs.append(npc)
	_apply_schedule(npc)


func unregister_npc(npc: Node) -> void:
	tracked_npcs.erase(npc)


func get_schedule_entry(schedule_id: String) -> Dictionary:
	var schedule: Dictionary = schedules.get(schedule_id, {})
	if schedule.is_empty():
		return {}
	var weekday_key := "sunday" if CalendarManager.is_sunday() else "regular"
	var entries: Dictionary = schedule.get(weekday_key, schedule.get("regular", {}))
	return entries.get(CalendarManager.get_time_period(), {})


func get_npc_state(schedule_id: String) -> String:
	return str(get_schedule_entry(schedule_id).get("state_cn", ""))


func _on_date_changed(_week: int, _weekday: String, _hour: int) -> void:
	for npc in tracked_npcs.duplicate():
		if not is_instance_valid(npc):
			tracked_npcs.erase(npc)
			continue
		_apply_schedule(npc)


func _apply_schedule(npc: Node) -> void:
	var schedule_id := str(npc.get("schedule_id"))
	if schedule_id == "":
		return
	var entry := get_schedule_entry(schedule_id)
	if entry.is_empty():
		return
	var position_data: Array = entry.get("position", [])
	if position_data.size() == 2:
		npc.global_position = Vector2(float(position_data[0]), float(position_data[1]))
	if npc.has_method("apply_schedule_state"):
		npc.apply_schedule_state(str(entry.get("state_cn", "")))
	npc_schedule_updated.emit(npc, entry)
