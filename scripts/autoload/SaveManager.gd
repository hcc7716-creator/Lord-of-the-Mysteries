extends Node

const SAVE_PATH := "user://stage3_save.json"


func build_save_data() -> Dictionary:
	return {
		"current_pathway_id": PathwayManager.current_pathway_id,
		"current_sequence_id": PathwayManager.current_sequence_id,
		"materials": InventoryManager.get_all_materials(),
		"quest_status": QuestManager.quest_status,
		"active_quest_id": QuestManager.active_quest_id,
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
	QuestManager.active_quest_id = str(parsed.get("active_quest_id", ""))
