extends Node

const SAVE_PATH := "user://stage3_save.json"


func build_save_data() -> Dictionary:
	return {
		"current_pathway_id": PathwayManager.current_pathway_id,
		"current_sequence_id": PathwayManager.current_sequence_id,
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
	PathwayManager.current_pathway_id = str(parsed.get("current_pathway_id", "fool"))
	PathwayManager.current_sequence_id = str(parsed.get("current_sequence_id", "fool_09_seer"))
	PathwayManager.refresh_unlocked_abilities()
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
