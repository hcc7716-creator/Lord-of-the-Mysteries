extends Node

signal quest_updated(quest_id: String)

enum QuestStatus {
	NOT_STARTED,
	ACTIVE,
	COMPLETED,
}

const QUESTS := {
	"quest_mysterious_death": {
		"title": "神秘死亡案件",
		"description": "调查雾城近期出现的离奇死亡事件，确认它是否与神秘仪式和失控者有关。",
		"objectives": [
			"与老尼尔交谈，了解案件背景",
			"调查死亡现场的异常痕迹",
			"收集占卜家魔药相关材料",
			"整理调查笔记，锁定下一步行动",
		],
		"reward_materials": {
			"mat_gold_mint_leaves": 1,
		},
	},
}

var quest_status: Dictionary = {}
var active_quest_id := ""


func accept_quest(quest_id: String) -> void:
	if not QUESTS.has(quest_id):
		push_warning("QuestManager: unknown quest %s" % quest_id)
		return
	if get_quest_status(quest_id) == QuestStatus.COMPLETED:
		return
	quest_status[quest_id] = QuestStatus.ACTIVE
	active_quest_id = quest_id
	quest_updated.emit(quest_id)


func complete_quest(quest_id: String) -> void:
	if not QUESTS.has(quest_id):
		push_warning("QuestManager: unknown quest %s" % quest_id)
		return
	quest_status[quest_id] = QuestStatus.COMPLETED
	if active_quest_id == quest_id:
		active_quest_id = ""
	var rewards: Dictionary = QUESTS[quest_id].get("reward_materials", {})
	for material_id in rewards.keys():
		InventoryManager.add_material(str(material_id), int(rewards[material_id]))
	quest_updated.emit(quest_id)


func get_quest_status(quest_id: String) -> int:
	return int(quest_status.get(quest_id, QuestStatus.NOT_STARTED))


func get_quest(quest_id: String) -> Dictionary:
	return QUESTS.get(quest_id, {})


func get_active_quest() -> Dictionary:
	if active_quest_id == "":
		return {}
	return get_quest(active_quest_id)


func get_active_quest_title() -> String:
	var quest := get_active_quest()
	if quest.is_empty():
		return "当前任务：无"
	return "当前任务：%s" % quest.get("title", active_quest_id)


func get_all_quests() -> Dictionary:
	return QUESTS
