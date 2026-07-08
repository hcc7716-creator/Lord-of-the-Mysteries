extends PanelContainer

@onready var list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/List


func _ready() -> void:
	visible = false
	refresh()


func refresh() -> void:
	for child in list.get_children():
		child.queue_free()

	for quest_id in QuestManager.get_all_quests().keys():
		var quest: Dictionary = QuestManager.get_quest(str(quest_id))
		var status: int = QuestManager.get_quest_status(str(quest_id))
		var status_text := _status_to_text(status)
		_add_line("%s [%s]" % [quest.get("title", quest_id), status_text])
		_add_line(str(quest.get("description", "")))
		for objective_line in QuestManager.get_objective_lines(str(quest_id)):
			_add_line(" %s" % objective_line)
		_add_line("")


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
