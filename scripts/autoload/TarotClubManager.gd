extends Node

signal tarot_club_unlocked
signal tarot_request_completed(request_id: String)
signal tarot_club_available

var is_unlocked := false
var trust_level := 0
var completed_request_ids: Array[String] = []


func _ready() -> void:
	QuestManager.quest_updated.connect(_on_quest_updated)
	CalendarManager.sunday_started.connect(_on_sunday_started)
	FactionManager.faction_relation_changed.connect(_on_faction_relation_changed)
	OpportunityManager.opportunity_discovered.connect(_on_opportunity_discovered)


func reset() -> void:
	is_unlocked = false
	trust_level = 0
	completed_request_ids.clear()


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


func can_enter() -> bool:
	return is_unlocked and CalendarManager.is_sunday()


func complete_request(request_id: String) -> bool:
	if not can_enter():
		return false
	if DataManager.get_tarot_request(request_id).is_empty():
		return false
	if not _is_request_available(request_id):
		return false
	if completed_request_ids.has(request_id):
		return false
	completed_request_ids.append(request_id)
	tarot_request_completed.emit(request_id)
	return true


func submit_exchange_request(request_id: String) -> Dictionary:
	if not is_unlocked:
		return {"success": false, "reason": "tarot_club_locked"}
	if not CalendarManager.is_sunday():
		return {"success": false, "reason": "not_sunday"}
	if not complete_request(request_id):
		return {"success": false, "reason": "request_unavailable"}
	var request := DataManager.get_tarot_request(request_id)
	for item_id in request.get("requested_items", []):
		if str(item_id).begins_with("formula_"):
			FormulaManager.acquire_formula(str(item_id), "塔罗会等价交换")
	for material_id in request.get("granted_materials", {}).keys():
		InventoryManager.add_material(str(material_id), int(request["granted_materials"][material_id]))
	for information in request.get("requested_info", []):
		ClueManager.add_divination_hint("tarot_club", "exchange", "塔罗会情报", str(information))
		if str(information) == "market_tingen_black_market_password":
			MarketManager.add_unlock_flag("know_market_password")
			MarketManager.add_unlock_flag("underground_market_reputation_1")
	return {"success": true, "request": request}


func _is_request_available(request_id: String) -> bool:
	for request in get_available_requests():
		if str(request.get("request_id", "")) == request_id:
			return true
	return false


func _on_quest_updated(quest_id: String) -> void:
	if quest_id == "quest_tingen_become_seer" and QuestManager.get_quest_status(quest_id) == QuestManager.QuestStatus.COMPLETED:
		unlock_tarot_club()


func _on_sunday_started(_week: int) -> void:
	if is_unlocked:
		tarot_club_available.emit()


func _on_faction_relation_changed(faction_id: String) -> void:
	if faction_id == "divination_club":
		_try_unlock_from_divination_contact()


func _on_opportunity_discovered(opportunity_id: String) -> void:
	if opportunity_id == "opp_npc_divination_rumor":
		_try_unlock_from_divination_contact()


func _try_unlock_from_divination_contact() -> void:
	if is_unlocked:
		return
	var relation := FactionManager.get_relation("divination_club")
	if int(relation.get("trust", 0)) >= 2 and OpportunityManager.is_discovered("opp_npc_divination_rumor"):
		unlock_tarot_club()
