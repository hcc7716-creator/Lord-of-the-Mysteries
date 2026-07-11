extends PanelContainer

@onready var list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/List


func _ready() -> void:
	visible = false
	QuestManager.quest_updated.connect(func(_quest_id: String): refresh())
	QuestManager.lead_updated.connect(func(_lead_id: String): refresh())
	refresh()


func refresh() -> void:
	for child in list.get_children():
		child.queue_free()

	for quest_id in QuestManager.get_all_quests().keys():
		var quest: Dictionary = QuestManager.get_quest(str(quest_id))
		var status: int = QuestManager.get_quest_status(str(quest_id))
		if status == QuestManager.QuestStatus.NOT_STARTED:
			continue
		var status_text := _status_to_text(status)
		_add_line("%s [%s]" % [quest.get("title", quest_id), status_text])
		_add_line(str(quest.get("description", "")))
		for objective_line in QuestManager.get_objective_lines(str(quest_id)):
			_add_line(" %s" % objective_line)
		_add_line("")

	var leads := QuestManager.get_discovered_leads()
	if not leads.is_empty():
		_add_line("线索")
		for lead in leads:
			var lead_id := str(lead.get("lead_id", ""))
			_add_line("%s [%s]" % [lead.get("title", lead_id), QuestManager.get_lead_status_text(lead_id)])
			_add_line(str(lead.get("description", "")))
			var sources: Array = lead.get("sources", [])
			if not sources.is_empty():
				_add_line("来源：%s" % "、".join(sources))
			_add_line("")

	if list.get_child_count() == 0:
		_add_line("暂无正式委托或已知线索。")
		_add_line("可以探索雾城、打工，或向居民打听消息。")


func _status_to_text(status: int) -> String:
	match status:
		QuestManager.QuestStatus.ACTIVE:
			return "进行中"
		QuestManager.QuestStatus.COMPLETED:
			return "已完成"
		_:
			return "未接取"


func _add_line(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.add_child(label)
