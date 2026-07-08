extends Area2D

@export var point_name := "调查点"
@export_multiline var description := "这里残留着异常的灵性痕迹。"
@export var material_id := "mat_star_crystal"
@export var material_quantity := 1
@export var complete_quest_id := ""
@export var one_shot := true
@export var interaction_prompt := "按 E 调查"

var has_been_used := false

@onready var label: Label = $Label


func _ready() -> void:
	label.text = point_name


func interact(_actor: Node = null) -> void:
	if one_shot and has_been_used:
		DialogueManager.start_dialogue(point_name, ["这里已经调查过了，没有新的发现。"], [{"text": "离开", "action": "close"}])
		return

	has_been_used = true
	var lines: Array = [description]

	if material_id != "":
		InventoryManager.add_material(material_id, material_quantity)
		var material: Dictionary = DataManager.get_material(material_id)
		var material_name := str(material.get("name_cn", material_id))
		lines.append("获得材料：%s x%d" % [material_name, material_quantity])

	if complete_quest_id != "":
		QuestManager.complete_quest(complete_quest_id)
		lines.append("任务状态已更新。")

	DialogueManager.start_dialogue(point_name, lines, [{"text": "记录到调查笔记", "action": "close"}])
