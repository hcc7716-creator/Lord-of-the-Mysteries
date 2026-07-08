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
	text += "当前案件名称：%s\n\n" % _get_case_title(quest_id)

	var key_count := ClueManager.get_key_clue_count(quest_id)
	var key_total := ClueManager.get_total_key_clue_count(quest_id)
	text += "关键线索数量：%d / %d\n\n" % [key_count, key_total]

	text += "已获得线索列表：\n"
	var clues := ClueManager.get_clues_for_quest(quest_id)
	if clues.is_empty():
		text += " - 暂无线索\n"
	else:
		for clue in clues:
			text += " - %s：%s\n" % [
				clue.get("title", "未命名线索"),
				clue.get("description", ""),
			]

	text += "\n占卜提示记录：\n"
	var hints := ClueManager.get_divination_hints_for_quest(quest_id)
	if hints.is_empty():
		text += " - 暂无占卜提示\n"
	else:
		for hint in hints:
			text += " - %s：%s\n" % [
				hint.get("title", "占卜"),
				hint.get("text", ""),
			]

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
