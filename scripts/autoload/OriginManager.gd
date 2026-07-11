extends Node

signal origin_selected(origin_id: String)
signal early_event_triggered(event_id: String)

var selected_origin_id := ""
var selected_region_id := ""
var starting_region_id := ""
var available_job_ids: Array[String] = []
var early_event_pool: Array[String] = []
var starting_items: Array[String] = []


func has_selected_origin() -> bool:
	return selected_origin_id != ""


func get_available_origins(region_id: String = "") -> Array:
	if region_id == "":
		return DataManager.origins.values()
	return DataManager.get_origins_for_region(region_id)


func get_available_starting_regions() -> Array:
	return DataManager.get_starting_regions()


func select_origin(origin_id: String) -> bool:
	var origin := DataManager.get_origin(origin_id)
	if origin.is_empty():
		push_warning("OriginManager: unknown origin %s" % origin_id)
		return false

	selected_origin_id = origin_id
	selected_region_id = str(origin.get("region_id", ""))
	starting_region_id = str(origin.get("starting_region_id", selected_region_id))
	available_job_ids.assign(origin.get("available_jobs", []))
	early_event_pool.assign(origin.get("early_event_pool", []))
	starting_items.assign(origin.get("starting_items", []))

	EconomyManager.set_balance(int(origin.get("starting_currency_pence", 0)))
	_reset_player_pathway()
	origin_selected.emit(origin_id)
	return true


func select_first_origin_for_region(region_id: String) -> bool:
	var origins := get_available_origins(region_id)
	if origins.is_empty():
		return false
	return select_origin(str(origins[0].get("origin_id", "")))


func get_selected_origin() -> Dictionary:
	if selected_origin_id == "":
		return {}
	return DataManager.get_origin(selected_origin_id)


func get_available_jobs() -> Array:
	var result: Array = []
	for job_id in available_job_ids:
		var job := DataManager.get_job(job_id)
		if not job.is_empty():
			result.append(job)
	return result


func get_early_event_pool() -> Array[String]:
	return early_event_pool.duplicate()


func has_early_event(event_id: String) -> bool:
	return early_event_pool.has(event_id)


func trigger_early_event(event_id: String) -> bool:
	if not has_early_event(event_id):
		return false
	if event_id == "event_tingen_mystery_case":
		QuestManager.discover_lead("lead_tingen_mysterious_death", "工作传闻")
	early_event_triggered.emit(event_id)
	return true


func _reset_player_pathway() -> void:
	if PathwayManager.has_method("clear_pathway"):
		PathwayManager.clear_pathway()
	else:
		PathwayManager.current_pathway_id = ""
		PathwayManager.current_sequence_id = ""
