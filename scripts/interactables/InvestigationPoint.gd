extends Area2D

@export var investigation_id := "investigation_point"
@export var point_name := "调查点"
@export var title := ""
@export_multiline var description := "这里残留着异常的灵性痕迹。"
@export var requires_spiritual_vision := false
@export var requires_objective_done := ""
@export var clue_id := ""
@export var reward_items: Dictionary = {}
@export var quest_id := "quest_tingen_become_seer"
@export var quest_update := ""
@export var quest_updates: Array = []
@export var material_id := "mat_star_crystal"
@export var material_quantity := 1
@export var complete_quest_id := ""
@export var one_shot := true
@export var interaction_prompt := "按 E 调查"

var already_investigated := false

@onready var label: Label = $Label
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	if title == "":
		title = point_name
	label.text = title
	SkillManager.spiritual_vision_changed.connect(_on_spiritual_vision_changed)
	QuestManager.quest_objective_updated.connect(_on_quest_objective_updated)
	_update_visibility()


func interact(_actor: Node = null) -> void:
	if requires_spiritual_vision and not SkillManager.spiritual_vision_active and not already_investigated:
		DialogueManager.start_dialogue(title, ["肉眼看不到这里的真实痕迹。也许需要先开启灵视。"], [{"text": "离开", "action": "close"}])
		return
	if requires_objective_done != "" and not QuestManager.is_objective_done(quest_id, requires_objective_done) and not already_investigated:
		DialogueManager.start_dialogue(title, ["你还没有获得足够明确的方向。也许需要先做一次占卜。"], [{"text": "离开", "action": "close"}])
		return

	if one_shot and already_investigated:
		DialogueManager.start_dialogue(title, ["这里已经调查过了，没有新的发现。"], [{"text": "离开", "action": "close"}])
		return

	already_investigated = true
	var lines: Array = [description]

	if clue_id != "":
		ClueManager.add_clue(clue_id)
		var clue: Dictionary = ClueManager.get_clue(clue_id)
		lines.append("记录线索：%s" % clue.get("title", clue_id))

	var rewards := _get_reward_items()
	for reward_id in rewards.keys():
		var quantity := int(rewards[reward_id])
		InventoryManager.add_material(str(reward_id), quantity)
		var material: Dictionary = DataManager.get_material(str(reward_id))
		var material_name := str(material.get("name_cn", str(reward_id)))
		lines.append("获得材料：%s x%d" % [material_name, quantity])

	if quest_update != "":
		QuestManager.mark_objective(quest_id, quest_update)
	for objective_id in quest_updates:
		QuestManager.mark_objective(quest_id, str(objective_id))

	if complete_quest_id != "":
		QuestManager.complete_quest(complete_quest_id)
		lines.append("任务状态已更新。")

	_update_visibility()
	DialogueManager.start_dialogue(title, lines, [{"text": "记录到调查笔记", "action": "close"}])


func _get_reward_items() -> Dictionary:
	if not reward_items.is_empty():
		return reward_items
	if material_id != "":
		return {material_id: material_quantity}
	return {}


func _on_spiritual_vision_changed(_active: bool) -> void:
	_update_visibility()


func _on_quest_objective_updated(_quest_id: String, _objective_id: String) -> void:
	_update_visibility()


func _update_visibility() -> void:
	var active := true
	if requires_spiritual_vision and not SkillManager.spiritual_vision_active and not already_investigated:
		active = false
	if requires_objective_done != "" and not QuestManager.is_objective_done(quest_id, requires_objective_done) and not already_investigated:
		active = false
	visible = active
	monitoring = active
	monitorable = active
	if collision_shape:
		collision_shape.disabled = not active
