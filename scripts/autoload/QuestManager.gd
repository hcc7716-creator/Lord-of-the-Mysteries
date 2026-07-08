extends Node

signal quest_updated(quest_id: String)
signal quest_objective_updated(quest_id: String, objective_id: String)

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
	"quest_tingen_become_seer": {
		"title": "成为占卜家",
		"description": "在老尼尔的指导下调查异常死亡案件，收集占卜家魔药材料，并完成第一次晋升。",
		"objectives": [
			{"id": "talk_old_neil", "text": "与老尼尔交谈，接取案件"},
			{"id": "investigate_death_scene", "text": "调查异常死亡现场"},
			{"id": "find_hidden_pollution", "text": "使用灵视发现隐藏的灵性污染点"},
			{"id": "pendulum_divination", "text": "使用灵摆占卜得到“教堂方向”"},
			{"id": "investigate_church_clue", "text": "调查教堂附近线索"},
			{"id": "collect_potion_materials", "text": "获得占卜家魔药材料"},
			{"id": "return_old_neil", "text": "回到老尼尔处确认调配方式"},
			{"id": "brew_potion", "text": "调配并服食占卜家魔药"},
			{"id": "advance_seer", "text": "成为序列 9 占卜家并解锁技能"},
		],
		"reward_materials": {},
	},
}

var quest_status: Dictionary = {}
var quest_progress: Dictionary = {}
var active_quest_id := ""


func accept_quest(quest_id: String) -> void:
	if not QUESTS.has(quest_id):
		push_warning("QuestManager: unknown quest %s" % quest_id)
		return
	if get_quest_status(quest_id) == QuestStatus.COMPLETED:
		return
	quest_status[quest_id] = QuestStatus.ACTIVE
	active_quest_id = quest_id
	if not quest_progress.has(quest_id):
		quest_progress[quest_id] = {}
	mark_objective(quest_id, "talk_old_neil")
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


func mark_objective(quest_id: String, objective_id: String) -> void:
	if quest_id == "" or objective_id == "":
		return
	if not QUESTS.has(quest_id):
		return
	if not quest_progress.has(quest_id):
		quest_progress[quest_id] = {}
	var progress: Dictionary = quest_progress[quest_id]
	if bool(progress.get(objective_id, false)):
		return
	progress[objective_id] = true
	quest_progress[quest_id] = progress
	quest_objective_updated.emit(quest_id, objective_id)
	quest_updated.emit(quest_id)


func is_objective_done(quest_id: String, objective_id: String) -> bool:
	var progress: Dictionary = quest_progress.get(quest_id, {})
	return bool(progress.get(objective_id, false))


func get_quest_status(quest_id: String) -> int:
	return int(quest_status.get(quest_id, QuestStatus.NOT_STARTED))


func get_quest(quest_id: String) -> Dictionary:
	return QUESTS.get(quest_id, {})


func get_active_quest() -> Dictionary:
	if active_quest_id == "":
		return {}
	return get_quest(active_quest_id)


func get_active_quest_title() -> String:
	var quest: Dictionary = get_active_quest()
	if quest.is_empty():
		return "当前任务：无"
	return "当前任务：%s" % quest.get("title", active_quest_id)


func get_hud_quest_title() -> String:
	var quest_id := _get_hud_quest_id()
	if quest_id == "":
		return "当前任务：无"
	var quest: Dictionary = get_quest(quest_id)
	var suffix := ""
	if get_quest_status(quest_id) == QuestStatus.COMPLETED:
		suffix = "（已完成）"
	return "当前任务：%s%s" % [quest.get("title", quest_id), suffix]


func get_next_objective_text() -> String:
	var quest_id := _get_hud_quest_id()
	if quest_id == "":
		return "下一步：与老尼尔交谈，接取案件"
	var quest: Dictionary = get_quest(quest_id)
	for objective in quest.get("objectives", []):
		if typeof(objective) != TYPE_DICTIONARY:
			continue
		var objective_id := str(objective.get("id", ""))
		if objective_id != "" and not is_objective_done(quest_id, objective_id):
			return "下一步：%s" % str(objective.get("text", objective_id))
	if get_quest_status(quest_id) == QuestStatus.COMPLETED:
		return "下一步：已完成第一次晋升，尝试使用已解锁技能"
	return "下一步：整理线索，等待新的任务目标"


func get_objective_lines(quest_id: String) -> Array[String]:
	var quest: Dictionary = get_quest(quest_id)
	var lines: Array[String] = []
	for objective in quest.get("objectives", []):
		var objective_id := ""
		var objective_text := ""
		if typeof(objective) == TYPE_DICTIONARY:
			objective_id = str(objective.get("id", ""))
			objective_text = str(objective.get("text", objective_id))
		else:
			objective_text = str(objective)
		var marker := "[ ]"
		if objective_id != "" and is_objective_done(quest_id, objective_id):
			marker = "[x]"
		lines.append("%s %s" % [marker, objective_text])
	return lines


func get_all_quests() -> Dictionary:
	return QUESTS


func _get_hud_quest_id() -> String:
	if active_quest_id != "":
		return active_quest_id
	if get_quest_status("quest_tingen_become_seer") != QuestStatus.NOT_STARTED:
		return "quest_tingen_become_seer"
	return ""
