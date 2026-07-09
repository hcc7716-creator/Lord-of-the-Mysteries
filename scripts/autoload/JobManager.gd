extends Node

signal job_completed(job_id: String, reward_pence: int)
signal job_event_triggered(job_id: String, event_id: String)

var completed_job_counts: Dictionary = {}


func get_available_jobs() -> Array:
	if OriginManager.has_selected_origin():
		return OriginManager.get_available_jobs()
	var starting_region_id := "tingen_prototype"
	return DataManager.get_jobs_for_region(starting_region_id)


func can_work(job_id: String) -> bool:
	return not DataManager.get_job(job_id).is_empty()


func perform_job(job_id: String) -> Dictionary:
	var job := DataManager.get_job(job_id)
	if job.is_empty():
		return {"success": false, "reason": "unknown_job"}

	var reward := int(job.get("reward_pence", 0))
	EconomyManager.add_money(reward)
	CalendarManager.advance_hours(int(job.get("time_cost_hours", 0)))
	completed_job_counts[job_id] = int(completed_job_counts.get(job_id, 0)) + 1

	var triggered_events: Array[String] = []
	for event in job.get("possible_events", []):
		if typeof(event) != TYPE_DICTIONARY:
			continue
		if randf() <= float(event.get("chance", 0.0)):
			var event_id := str(event.get("event_id", ""))
			if event_id != "":
				triggered_events.append(event_id)
				job_event_triggered.emit(job_id, event_id)

	job_completed.emit(job_id, reward)
	return {
		"success": true,
		"reward_pence": reward,
		"triggered_events": triggered_events,
	}
