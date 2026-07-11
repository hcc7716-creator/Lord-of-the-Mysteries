extends Node

signal quest_updated(quest_id: String)
signal quest_objective_updated(quest_id: String, objective_id: String)
signal lead_updated(lead_id: String)

enum QuestStatus {
	NOT_STARTED,
	ACTIVE,
	COMPLETED,
}

enum LeadStatus {
	UNDISCOVERED,
	DISCOVERED,
	PURSUING,
	RESOLVED,
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
			{"id": "paper_divination", "text": "使用纸笔占卜记录关键词"},
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

const LEADS := {
	"lead_tingen_mysterious_death": {
		"title": "异常死亡案件",
		"description": "雾城最近出现了一起被悄悄压下的异常死亡。有人说尸体附近留有仪式痕迹，老尼尔或许知道更多。",
		"lead_type": "rumor",
		"linked_quest_id": "quest_tingen_become_seer",
	},
}

var quest_status: Dictionary = {}
var quest_progress: Dictionary = {}
var active_quest_id := ""
var lead_status: Dictionary = {}
var lead_sources: Dictionary = {}


func accept_quest(quest_id: String) -> void:
	if not QUESTS.has(quest_id):
		push_warning("QuestManager: unknown quest %s" % quest_id)
		return
	if get_quest_status(quest_id) == QuestStatus.COMPLETED:
		return
	quest_status[quest_id] = QuestStatus.ACTIVE
	active_quest_id = quest_id
	_set_linked_leads_status(quest_id, LeadStatus.PURSUING)
	if quest_id == "quest_tingen_become_seer" and PathwayManager.has_method("set_suspected_pathway"):
		PathwayManager.set_suspected_pathway("fool")
	if not quest_progress.has(quest_id):
		quest_progress[quest_id] = {}
	mark_objective(quest_id, "talk_old_neil")
	_sync_discovered_clues_to_quest(quest_id)
	quest_updated.emit(quest_id)


func complete_quest(quest_id: String) -> void:
	if not QUESTS.has(quest_id):
		push_warning("QuestManager: unknown quest %s" % quest_id)
		return
	quest_status[quest_id] = QuestStatus.COMPLETED
	_set_linked_leads_status(quest_id, LeadStatus.RESOLVED)
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


func discover_lead(lead_id: String, source: String = "") -> bool:
	if not LEADS.has(lead_id):
		push_warning("QuestManager: unknown lead %s" % lead_id)
		return false
	var was_known := get_lead_status(lead_id) != LeadStatus.UNDISCOVERED
	if not was_known:
		lead_status[lead_id] = LeadStatus.DISCOVERED
	if source != "":
		var sources: Array = lead_sources.get(lead_id, [])
		if not sources.has(source):
			sources.append(source)
			lead_sources[lead_id] = sources
	if not was_known or source != "":
		lead_updated.emit(lead_id)
	return true


func get_lead(lead_id: String) -> Dictionary:
	return LEADS.get(lead_id, {})


func get_lead_status(lead_id: String) -> int:
	return int(lead_status.get(lead_id, LeadStatus.UNDISCOVERED))


func get_discovered_leads() -> Array:
	var result: Array = []
	for lead_id in LEADS.keys():
		if get_lead_status(str(lead_id)) == LeadStatus.UNDISCOVERED:
			continue
		var lead: Dictionary = get_lead(str(lead_id)).duplicate(true)
		lead["lead_id"] = str(lead_id)
		lead["status"] = get_lead_status(str(lead_id))
		lead["sources"] = lead_sources.get(str(lead_id), [])
		result.append(lead)
	return result


func get_lead_status_text(lead_id: String) -> String:
	match get_lead_status(lead_id):
		LeadStatus.DISCOVERED:
			return "待追查"
		LeadStatus.PURSUING:
			return "调查中"
		LeadStatus.RESOLVED:
			return "已解决"
		_:
			return "未发现"


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
		var leads := get_discovered_leads()
		if not leads.is_empty():
			var lead: Dictionary = leads[0]
			return "下一步：追查线索“%s”，或向老尼尔求证" % str(lead.get("title", "未知线索"))
		if OpportunityManager.get_discovered_opportunities().size() > 0:
			return "下一步：%s" % OpportunityManager.get_next_hint()
		return "下一步：探索雾城、工作，或向居民打听消息"
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


func _set_linked_leads_status(quest_id: String, status: int) -> void:
	for lead_id in LEADS.keys():
		var lead: Dictionary = LEADS[lead_id]
		if str(lead.get("linked_quest_id", "")) != quest_id:
			continue
		lead_status[str(lead_id)] = status
		lead_updated.emit(str(lead_id))


func _sync_discovered_clues_to_quest(quest_id: String) -> void:
	if quest_id != "quest_tingen_become_seer":
		return
	if ClueManager.has_clue("clue_abnormal_death_scene"):
		mark_objective(quest_id, "investigate_death_scene")
	if ClueManager.has_clue("clue_hidden_pollution"):
		mark_objective(quest_id, "find_hidden_pollution")
	if ClueManager.has_clue("clue_church_direction"):
		mark_objective(quest_id, "investigate_church_clue")
		mark_objective(quest_id, "collect_potion_materials")


func _get_hud_quest_id() -> String:
	if active_quest_id != "":
		return active_quest_id
	if get_quest_status("quest_tingen_become_seer") != QuestStatus.NOT_STARTED:
		return "quest_tingen_become_seer"
	return ""
