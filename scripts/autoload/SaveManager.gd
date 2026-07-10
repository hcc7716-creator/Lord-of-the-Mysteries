extends Node

const SAVE_PATH := "user://stage3_save.json"


func build_save_data() -> Dictionary:
	return {
		"current_pathway_id": PathwayManager.current_pathway_id,
		"current_sequence_id": PathwayManager.current_sequence_id,
		"selected_origin_id": OriginManager.selected_origin_id,
		"selected_region_id": OriginManager.selected_region_id,
		"starting_region_id": OriginManager.starting_region_id,
		"money_pence": EconomyManager.get_balance(),
		"calendar_week": CalendarManager.current_week,
		"calendar_day_index": CalendarManager.day_index,
		"calendar_hour": CalendarManager.hour,
		"tarot_club_unlocked": TarotClubManager.is_unlocked,
		"tarot_trust_level": TarotClubManager.trust_level,
		"completed_tarot_request_ids": TarotClubManager.completed_request_ids,
		"market_unlock_flags": MarketManager.unlocked_flags,
		"purchased_market_item_ids": MarketManager.purchased_item_ids,
		"known_formula_ids": MarketManager.known_formula_ids,
		"completed_job_counts": JobManager.completed_job_counts,
		"materials": InventoryManager.get_all_materials(),
		"quest_status": QuestManager.quest_status,
		"quest_progress": QuestManager.quest_progress,
		"active_quest_id": QuestManager.active_quest_id,
		"acquired_clues": ClueManager.acquired_clues,
		"divination_hints": ClueManager.divination_hints,
		"unlocked_skill_ids": SkillManager.permanent_unlocked_skill_ids,
		"spirituality": CorruptionManager.spirituality,
		"max_spirituality": CorruptionManager.max_spirituality,
		"corruption": CorruptionManager.corruption,
		"stability": CorruptionManager.stability,
	}


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write save file")
		return
	file.store_string(JSON.stringify(build_save_data(), "\t"))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: cannot read save file")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	PathwayManager.current_pathway_id = str(parsed.get("current_pathway_id", ""))
	PathwayManager.current_sequence_id = str(parsed.get("current_sequence_id", ""))
	PathwayManager.refresh_unlocked_abilities()
	OriginManager.selected_origin_id = str(parsed.get("selected_origin_id", ""))
	OriginManager.selected_region_id = str(parsed.get("selected_region_id", ""))
	OriginManager.starting_region_id = str(parsed.get("starting_region_id", ""))
	var origin := OriginManager.get_selected_origin()
	if not origin.is_empty():
		OriginManager.available_job_ids.assign(origin.get("available_jobs", []))
		OriginManager.early_event_pool.assign(origin.get("early_event_pool", []))
		OriginManager.starting_items.assign(origin.get("starting_items", []))
	EconomyManager.set_balance(int(parsed.get("money_pence", 0)))
	CalendarManager.current_week = int(parsed.get("calendar_week", CalendarManager.current_week))
	CalendarManager.day_index = int(parsed.get("calendar_day_index", CalendarManager.day_index))
	CalendarManager.hour = int(parsed.get("calendar_hour", CalendarManager.hour))
	TarotClubManager.is_unlocked = bool(parsed.get("tarot_club_unlocked", false))
	TarotClubManager.trust_level = int(parsed.get("tarot_trust_level", 0))
	TarotClubManager.completed_request_ids.assign(parsed.get("completed_tarot_request_ids", []))
	MarketManager.unlocked_flags = parsed.get("market_unlock_flags", {})
	MarketManager.purchased_item_ids.assign(parsed.get("purchased_market_item_ids", []))
	MarketManager.known_formula_ids.assign(parsed.get("known_formula_ids", []))
	JobManager.completed_job_counts = parsed.get("completed_job_counts", {})
	if TarotClubManager.is_unlocked:
		MarketManager.add_unlock_flag("unlock_tarot_club")
	InventoryManager.materials = parsed.get("materials", {})
	QuestManager.quest_status = parsed.get("quest_status", {})
	QuestManager.quest_progress = parsed.get("quest_progress", {})
	QuestManager.active_quest_id = str(parsed.get("active_quest_id", ""))
	ClueManager.acquired_clues = parsed.get("acquired_clues", {})
	ClueManager.divination_hints = parsed.get("divination_hints", [])
	SkillManager.permanent_unlocked_skill_ids.assign(parsed.get("unlocked_skill_ids", []))
	CorruptionManager.spirituality = int(parsed.get("spirituality", CorruptionManager.spirituality))
	CorruptionManager.max_spirituality = int(parsed.get("max_spirituality", CorruptionManager.max_spirituality))
	CorruptionManager.corruption = int(parsed.get("corruption", CorruptionManager.corruption))
	CorruptionManager.stability = int(parsed.get("stability", CorruptionManager.stability))
	CorruptionManager.normalize_spirituality_for_sequence(PathwayManager.current_sequence_id)
