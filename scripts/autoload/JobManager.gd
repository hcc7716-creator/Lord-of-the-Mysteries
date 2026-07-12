extends Node

signal job_completed(job_id: String, reward_pence: int)
signal job_event_triggered(job_id: String, event_id: String)
signal job_failed(job_id: String, reason: String)

var completed_job_counts: Dictionary = {}


func get_available_jobs() -> Array:
	var result: Array = []
	var added_ids := {}
	for job in OriginManager.get_available_jobs():
		var job_id := str(job.get("job_id", ""))
		if job_id != "" and not added_ids.has(job_id):
			added_ids[job_id] = true
			result.append(job)

	var region_id := OriginManager.starting_region_id
	if region_id == "":
		region_id = "tingen_prototype"
	for job in DataManager.get_jobs_for_region(region_id):
		var job_id := str(job.get("job_id", ""))
		if job_id != "" and not added_ids.has(job_id):
			added_ids[job_id] = true
			result.append(job)
	return result


func can_work(job_id: String) -> bool:
	for job in get_available_jobs():
		if str(job.get("job_id", "")) == job_id:
			return true
	return false


func perform_job(job_id: String) -> Dictionary:
	var job := DataManager.get_job(job_id)
	if job.is_empty() or not can_work(job_id):
		job_failed.emit(job_id, "unknown_or_unavailable_job")
		return {"success": false, "reason": "unknown_or_unavailable_job"}

	var reward := int(job.get("reward_pence", 0))
	var started_at_night := CalendarManager.get_time_period() == "night"
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
				_handle_event(event_id)
				job_event_triggered.emit(job_id, event_id)

	var gained_materials := _grant_possible_rewards(job)

	var risk_level := str(job.get("risk_level", "low"))
	if risk_level == "high":
		CorruptionManager.add_corruption(2, "高风险工作接触了不稳定的人和物")

	if started_at_night:
		var night_corruption := 2 if risk_level == "high" else 1
		CorruptionManager.add_corruption(night_corruption, "夜间工作让城市里的异常更容易靠近你")
		if randf() <= 0.20:
			triggered_events.append("event_nighttime_complication")

	job_completed.emit(job_id, reward)
	return {
		"success": true,
		"reward_pence": reward,
		"triggered_events": triggered_events,
		"risk_level": risk_level,
		"night_risk": started_at_night,
		"gained_materials": gained_materials,
	}


func _handle_event(event_id: String) -> void:
	match event_id:
		"event_tingen_mystery_case":
			if QuestManager.get_lead_status("lead_tingen_mysterious_death") == QuestManager.LeadStatus.UNDISCOVERED:
				OriginManager.trigger_early_event(event_id)
		"event_black_market_password":
			MarketManager.add_unlock_flag("know_market_password")
			MarketManager.add_unlock_flag("underground_market_reputation_1")


func _grant_possible_rewards(job: Dictionary) -> Array[String]:
	var gained: Array[String] = []
	for reward in job.get("possible_rewards", []):
		if typeof(reward) != TYPE_DICTIONARY or randf() > float(reward.get("chance", 0.0)):
			continue
		var reward_type := str(reward.get("type", ""))
		var reward_id := str(reward.get("id", ""))
		match reward_type:
			"material":
				var quantity := int(reward.get("quantity", 1))
				InventoryManager.add_material(reward_id, quantity)
				gained.append("%s x%d" % [str(DataManager.get_material(reward_id).get("name_cn", reward_id)), quantity])
			"flag":
				MarketManager.add_unlock_flag(reward_id)
			"reputation":
				if reward_id == "police_contact":
					FactionManager.adjust_relation("police", int(reward.get("amount", 1)), 0, 0)
			"material_hint":
				ClueManager.add_divination_hint("work", "material_hint", "工作材料线索", reward_id)
	return gained
