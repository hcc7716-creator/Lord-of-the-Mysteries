extends Node

signal divination_performed(skill_id: String, result_text: String)

const QUEST_DIVINATION := {
	"quest_tingen_become_seer": {
		"skill_seer_pendulum_divination": {
			"title": "灵摆占卜结果",
			"clear": {
				"result": "灵摆稳定地指向教堂方向。",
				"detail": "老尼尔提醒过，教堂后街有一处被封存的旧箱。",
			},
			"vague": {
				"result": "灵摆先是指向教堂方向，随后开始轻微颤动。",
				"detail": "你只能确认线索与教堂附近有关，旧箱的位置被雾气干扰。",
			},
			"distorted": {
				"result": "灵摆转得很慢，方向像被灰雾折断。",
				"detail": "只剩下“钟声”“背面”和“封存物”的危险印象，不能完全信任。",
			},
			"corruption": 3,
		},
		"skill_seer_paper_divination": {
			"title": "纸笔占卜结果",
			"clear": {
				"result": "纸面浮现出三个稳定关键词。",
				"detail": "关键词：红烟囱、镜子、午夜。",
				"keywords": ["红烟囱", "镜子", "午夜"],
			},
			"vague": {
				"result": "墨迹迟疑地聚拢成几个模糊词。",
				"detail": "关键词：烟囱、镜面、模糊的时间符号。",
				"keywords": ["烟囱", "镜面", "时间符号"],
			},
			"distorted": {
				"result": "纸面被污染墨迹拖拽，只剩破碎字形。",
				"detail": "关键词：红、镜、夜。",
				"keywords": ["红", "镜", "夜"],
			},
			"corruption": 2,
			"clue_id": "clue_paper_divination_keywords",
		},
	},
}


func perform_divination(skill_id: String) -> String:
	var result := perform_divination_data(skill_id)
	return str(result.get("combined_text", result.get("result_text", "")))


func perform_divination_data(skill_id: String) -> Dictionary:
	var quest_id := QuestManager.active_quest_id
	if quest_id == "":
		quest_id = "quest_tingen_become_seer"

	var quest_data: Dictionary = QUEST_DIVINATION.get(quest_id, {})
	var result_data: Dictionary = quest_data.get(skill_id, {})
	if result_data.is_empty():
		result_data = {
			"title": "占卜结果",
			"clear": "象征没有回应，也许问题还不够明确。",
			"vague": "你只得到一阵模糊的冷意。",
			"distorted": "污染干扰了象征，结果无法信任。",
			"corruption": 1,
		}

	var clarity := CorruptionManager.get_divination_clarity()
	var raw_result = result_data.get(clarity, result_data.get("clear", ""))
	var result_text := ""
	var detail_text := ""
	var keywords: Array = []
	if typeof(raw_result) == TYPE_DICTIONARY:
		result_text = str(raw_result.get("result", ""))
		detail_text = str(raw_result.get("detail", ""))
		keywords = raw_result.get("keywords", [])
	else:
		result_text = str(raw_result)
	var title := str(result_data.get("title", "占卜结果"))
	var combined_text := result_text
	if detail_text != "":
		combined_text = "%s %s" % [result_text, detail_text]
	ClueManager.add_divination_hint(quest_id, skill_id, title, combined_text, keywords)

	var clue_id := str(result_data.get("clue_id", ""))
	if clue_id != "":
		ClueManager.add_clue(clue_id)

	if skill_id == "skill_seer_pendulum_divination":
		QuestManager.mark_objective(quest_id, "pendulum_divination")
	elif skill_id == "skill_seer_paper_divination":
		QuestManager.mark_objective(quest_id, "paper_divination")

	var corruption_gain := int(result_data.get("corruption", 1))
	if clarity == "distorted":
		corruption_gain += 2
	CorruptionManager.add_corruption(corruption_gain, title)
	divination_performed.emit(skill_id, combined_text)
	return {
		"skill_id": skill_id,
		"quest_id": quest_id,
		"title": title,
		"clarity": clarity,
		"confidence_label": _get_confidence_label(clarity),
		"result_text": result_text,
		"detail_text": detail_text,
		"keywords": keywords,
		"combined_text": combined_text,
	}


func _get_confidence_label(clarity: String) -> String:
	match clarity:
		"distorted":
			return "危险"
		"vague":
			return "模糊"
		_:
			return "稳定"
