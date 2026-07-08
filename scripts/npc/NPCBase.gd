extends Area2D

@export var npc_name := "老尼尔"
@export_multiline var dialogue_text := "这些死亡痕迹不像普通案件。\n你愿意帮我调查雾城最近的神秘死亡事件吗？"
@export var quest_to_offer := "quest_mysterious_death"
@export var interaction_prompt := "按 E 与老尼尔交谈"

@onready var name_label: Label = $NameLabel


func _ready() -> void:
	name_label.text = npc_name


func interact(_actor: Node = null) -> void:
	var lines := dialogue_text.split("\n", false)
	var options: Array = []
	if quest_to_offer != "" and QuestManager.get_quest_status(quest_to_offer) == QuestManager.QuestStatus.NOT_STARTED:
		options.append({
			"text": "接受任务：神秘死亡案件",
			"action": "accept_quest",
			"quest_id": quest_to_offer,
		})
	options.append({"text": "结束对话", "action": "close"})
	DialogueManager.start_dialogue(npc_name, lines, options)
