extends Node

signal clue_added(clue_id: String)
signal notebook_updated

const CLUES := {
	"clue_abnormal_death_scene": {
		"title": "异常死亡现场",
		"description": "尸体附近没有明显搏斗痕迹，但地面残留着近似仪式粉末的痕迹。",
		"quest_id": "quest_tingen_become_seer",
		"is_key": true,
	},
	"clue_ritual_residue": {
		"title": "仪式残留痕迹",
		"description": "残留物中混有星晶碎屑与药草气味，像是某种低序列魔药准备仪式。",
		"quest_id": "quest_tingen_become_seer",
		"is_key": true,
	},
	"clue_hidden_pollution": {
		"title": "隐藏的灵性污染点",
		"description": "灵视下能看到墙缝里渗出的灰蓝色灵性污染，说明现场曾被刻意遮蔽。",
		"quest_id": "quest_tingen_become_seer",
		"is_key": true,
	},
	"clue_paper_divination_keywords": {
		"title": "纸笔占卜关键词",
		"description": "纸面浮现出“红烟囱”“镜子”“午夜”三个词。",
		"quest_id": "quest_tingen_become_seer",
		"is_key": false,
	},
}

var acquired_clues: Dictionary = {}
var divination_hints: Array[Dictionary] = []


func add_clue(clue_id: String) -> void:
	if clue_id == "":
		return
	if acquired_clues.has(clue_id):
		return
	var clue: Dictionary = get_clue(clue_id)
	if clue.is_empty():
		push_warning("ClueManager: unknown clue %s" % clue_id)
		return
	acquired_clues[clue_id] = true
	clue_added.emit(clue_id)
	notebook_updated.emit()


func get_clue(clue_id: String) -> Dictionary:
	return CLUES.get(clue_id, {})


func has_clue(clue_id: String) -> bool:
	return acquired_clues.has(clue_id)


func get_clues_for_quest(quest_id: String) -> Array:
	var result: Array = []
	for clue_id in acquired_clues.keys():
		var clue: Dictionary = get_clue(str(clue_id))
		if str(clue.get("quest_id", "")) == quest_id:
			result.append(clue)
	return result


func add_divination_hint(quest_id: String, skill_id: String, title: String, text: String) -> void:
	divination_hints.append({
		"quest_id": quest_id,
		"skill_id": skill_id,
		"title": title,
		"text": text,
	})
	notebook_updated.emit()


func get_divination_hints_for_quest(quest_id: String) -> Array:
	var result: Array = []
	for hint in divination_hints:
		if str(hint.get("quest_id", "")) == quest_id:
			result.append(hint)
	return result


func get_key_clue_count(quest_id: String) -> int:
	var count := 0
	for clue_id in acquired_clues.keys():
		var clue: Dictionary = get_clue(str(clue_id))
		if str(clue.get("quest_id", "")) == quest_id and bool(clue.get("is_key", false)):
			count += 1
	return count


func get_total_key_clue_count(quest_id: String) -> int:
	var count := 0
	for clue in CLUES.values():
		if str(clue.get("quest_id", "")) == quest_id and bool(clue.get("is_key", false)):
			count += 1
	return count


func get_current_case_title() -> String:
	var quest_id := QuestManager.active_quest_id
	if quest_id == "":
		return "未接取案件"
	var quest: Dictionary = QuestManager.get_quest(quest_id)
	return str(quest.get("title", quest_id))
