extends Node

signal divination_performed(skill_id: String, result_text: String)

const QUEST_DIVINATION := {
	"quest_tingen_become_seer": {
		"skill_seer_pendulum_divination": {
			"title": "灵摆占卜结果",
			"clear": "灵摆稳定地指向教堂方向。老尼尔提过，教堂后街有一处被封存的旧箱。",
			"vague": "灵摆先是指向教堂方向，随后开始轻微颤动，像被雾干扰。",
			"distorted": "灵摆转得很慢，方向像被灰雾折断，只剩下“钟声”和“背面”的印象。",
			"corruption": 3,
		},
		"skill_seer_paper_divination": {
			"title": "纸笔占卜结果",
			"clear": "纸面浮现出“红烟囱”“镜子”“午夜”三个词。",
			"vague": "纸面只留下“烟囱”“镜面”和一个模糊的时间符号。",
			"distorted": "纸面被墨迹污染，只能辨认出破碎的“红”“镜”“夜”。",
			"corruption": 2,
			"clue_id": "clue_paper_divination_keywords",
		},
	},
}


func perform_divination(skill_id: String) -> String:
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
	var result_text := str(result_data.get(clarity, result_data.get("clear", "")))
	var title := str(result_data.get("title", "占卜结果"))
	ClueManager.add_divination_hint(quest_id, skill_id, title, result_text)

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
	divination_performed.emit(skill_id, result_text)
	return result_text
