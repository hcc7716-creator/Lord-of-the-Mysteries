extends Area2D

@export var npc_name := "老尼尔"
@export_multiline var dialogue_text := "这些死亡痕迹不像普通案件。\n你愿意帮我调查雾城最近的神秘死亡事件吗？"
@export var quest_to_offer := "quest_tingen_become_seer"
@export var schedule_id := ""
@export var interaction_prompt := "按 E 与老尼尔交谈"

@onready var name_label: Label = $NameLabel


func _ready() -> void:
	name_label.text = npc_name
	name_label.visible = false
	if schedule_id != "":
		ScheduleManager.register_npc(self)


func _process(_delta: float) -> void:
	var player := GameManager.player as Node2D
	name_label.visible = player != null and global_position.distance_to(player.global_position) <= 120.0


func _exit_tree() -> void:
	if schedule_id != "":
		ScheduleManager.unregister_npc(self)


func apply_schedule_state(state: String) -> void:
	name_label.text = npc_name if state == "" else "%s\n%s" % [npc_name, state]


func interact(_actor: Node = null) -> void:
	if quest_to_offer == "quest_tingen_become_seer":
		_interact_become_seer()
		return

	var lines := dialogue_text.split("\n", false)
	var options: Array = []
	if quest_to_offer != "" and QuestManager.get_quest_status(quest_to_offer) == QuestManager.QuestStatus.NOT_STARTED:
		var quest: Dictionary = QuestManager.get_quest(quest_to_offer)
		options.append({
			"text": "接受任务：%s" % quest.get("title", quest_to_offer),
			"action": "accept_quest",
			"quest_id": quest_to_offer,
		})
	options.append({"text": "结束对话", "action": "close"})
	DialogueManager.start_dialogue(npc_name, lines, options)


func _interact_become_seer() -> void:
	var quest_id := "quest_tingen_become_seer"
	var status := QuestManager.get_quest_status(quest_id)
	var lines: Array = []
	var options: Array = []

	if status == QuestManager.QuestStatus.NOT_STARTED:
		lines = dialogue_text.split("\n", false)
		var quest: Dictionary = QuestManager.get_quest(quest_id)
		options.append({
			"text": "接受任务：%s" % quest.get("title", quest_id),
			"action": "accept_quest",
			"quest_id": quest_id,
		})
	elif status == QuestManager.QuestStatus.COMPLETED:
		lines = [
			"你的灵性已经稳定下来。",
			"从现在开始，你就是序列 9 占卜家。记住，占卜是提示，不是答案。",
		]
	else:
		if QuestManager.is_objective_done(quest_id, "collect_potion_materials") and not QuestManager.is_objective_done(quest_id, "return_old_neil"):
			QuestManager.mark_objective(quest_id, "return_old_neil")
			lines = [
				"你把教堂后街找到的材料带回来了。",
				"星晶、拉沃斯鱿鱼血、纯水和几种辅助材料都齐了。",
				"现在打开魔药面板，调配并服食占卜家魔药。不要犹豫太久，材料的灵性会慢慢散掉。",
			]
		elif not QuestManager.is_objective_done(quest_id, "investigate_death_scene"):
			lines = ["先去调查异常死亡现场，那里会告诉你这不是普通谋杀。"]
		elif not QuestManager.is_objective_done(quest_id, "find_hidden_pollution"):
			lines = ["现在使用灵视。污染残留被遮蔽了，肉眼看不到。"]
		elif not QuestManager.is_objective_done(quest_id, "pendulum_divination"):
			lines = ["污染点已经确认。接下来使用灵摆占卜，问方向，不要问真凶。"]
		elif not QuestManager.is_objective_done(quest_id, "investigate_church_clue"):
			lines = ["灵摆已经给出方向。去教堂附近，尤其留意后街和旧箱。"]
		elif not QuestManager.is_objective_done(quest_id, "return_old_neil"):
			lines = ["如果你已经在教堂附近找到材料，就带回来给我确认。"]
		elif not QuestManager.is_objective_done(quest_id, "brew_potion"):
			lines = ["材料确认无误。按 O 打开魔药面板，调配并服食占卜家魔药。"]
		else:
			lines = ["闭上眼，稳定呼吸。晋升完成后，你会真正看见世界的另一面。"]

	options.append({"text": "结束对话", "action": "close"})
	DialogueManager.start_dialogue(npc_name, lines, options)
