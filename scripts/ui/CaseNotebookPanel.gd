extends PanelContainer

@onready var content: RichTextLabel = $MarginContainer/VBoxContainer/ScrollContainer/Content


func _ready() -> void:
	visible = false
	content.custom_minimum_size = Vector2(760, 500)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.fit_content = false
	content.scroll_active = true
	ClueManager.notebook_updated.connect(refresh)
	QuestManager.quest_updated.connect(func(_quest_id: String): refresh())
	refresh()


func refresh() -> void:
	var quest_id := _get_display_quest_id()

	var text := ""
	text += "[b]当前案件名称：%s[/b]\n\n" % _get_case_title(quest_id)

	var key_count := ClueManager.get_key_clue_count(quest_id)
	var key_total := ClueManager.get_total_key_clue_count(quest_id)
	text += "关键线索数量：%d / %d\n\n" % [key_count, key_total]

	text += "[b]现场线索[/b]\n"
	text += "----------------\n"
	var scene_clues := _get_scene_clues(quest_id)
	if scene_clues.is_empty():
		text += " - 暂无现场线索\n"
	else:
		for clue in scene_clues:
			text += " - %s\n" % clue.get("title", "未命名线索")

	text += "\n[b]占卜提示[/b]\n"
	text += "----------------\n"
	var hints := ClueManager.get_divination_hints_for_quest(quest_id)
	if hints.is_empty():
		text += " - 暂无占卜提示\n"
	else:
		for hint in hints:
			text += " - %s\n" % _format_divination_hint(hint)

	text += "\n[b]下一步推断[/b]\n"
	text += "----------------\n"
	for inference in _get_next_inferences(quest_id):
		text += " - %s\n" % inference

	content.text = text


func _get_display_quest_id() -> String:
	if QuestManager.active_quest_id != "":
		return QuestManager.active_quest_id
	if not ClueManager.get_clues_for_quest("quest_tingen_become_seer").is_empty():
		return "quest_tingen_become_seer"
	if not ClueManager.get_divination_hints_for_quest("quest_tingen_become_seer").is_empty():
		return "quest_tingen_become_seer"
	return "quest_tingen_become_seer"


func _get_case_title(quest_id: String) -> String:
	var quest: Dictionary = QuestManager.get_quest(quest_id)
	if quest.is_empty():
		return "未接取案件"
	return str(quest.get("title", quest_id))


func _get_scene_clues(quest_id: String) -> Array:
	var result: Array = []
	for clue in ClueManager.get_clue_entries_for_quest(quest_id):
		if str(clue.get("clue_id", "")) == "clue_paper_divination_keywords":
			continue
		result.append(clue)
	return result


func _format_divination_hint(hint: Dictionary) -> String:
	var skill_id := str(hint.get("skill_id", ""))
	var text := str(hint.get("text", ""))
	if skill_id == "skill_seer_pendulum_divination":
		if text.find("教堂方向") != -1:
			return "灵摆指向教堂方向"
		return "灵摆占卜：%s" % text
	if skill_id == "skill_seer_paper_divination":
		var keywords := _format_keywords(hint.get("keywords", []))
		if keywords == "":
			keywords = _extract_keywords(text)
		if keywords != "":
			return "关键词：%s" % keywords
		return "纸笔占卜：%s" % text
	return "%s：%s" % [hint.get("title", "占卜"), text]


func _extract_keywords(text: String) -> String:
	var marker := "关键词："
	var start := text.find(marker)
	if start == -1:
		return ""
	var keyword_text := text.substr(start + marker.length()).strip_edges()
	if keyword_text.ends_with("。"):
		keyword_text = keyword_text.substr(0, keyword_text.length() - 1)
	return keyword_text


func _format_keywords(keywords) -> String:
	if typeof(keywords) != TYPE_ARRAY or keywords.is_empty():
		return ""
	var parts: Array[String] = []
	for keyword in keywords:
		parts.append(str(keyword))
	return "、".join(parts)


func _get_next_inferences(quest_id: String) -> Array[String]:
	if not ClueManager.has_clue("clue_abnormal_death_scene"):
		return ["调查异常死亡现场，确认死亡是否与仪式有关"]
	if not ClueManager.has_clue("clue_hidden_pollution"):
		return ["开启灵视，寻找肉眼无法发现的污染残留"]
	if not QuestManager.is_objective_done(quest_id, "paper_divination"):
		return ["使用纸笔占卜记录关键词，补充案件笔记"]
	if not QuestManager.is_objective_done(quest_id, "pendulum_divination"):
		return ["使用灵摆占卜，确认污染残留指向哪里"]
	if not ClueManager.has_clue("clue_church_direction"):
		return ["前往教堂后街调查旧箱子"]
	if not QuestManager.is_objective_done(quest_id, "return_old_neil"):
		return ["带着材料回到老尼尔处确认调配方式"]
	if PathwayManager.current_sequence_id == "":
		return ["打开魔药面板，调配并服食占卜家魔药"]
	return ["第一次晋升已完成，记录占卜家技能表现并准备下一阶段"]
