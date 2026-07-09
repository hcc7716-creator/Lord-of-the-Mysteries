extends PanelContainer

@onready var content: RichTextLabel = $MarginContainer/VBoxContainer/Content
@onready var close_button: Button = $MarginContainer/VBoxContainer/Header/CloseButton


func _ready() -> void:
	visible = false
	close_button.pressed.connect(func(): visible = false)
	refresh()


func refresh() -> void:
	if not _has_pathway_context():
		content.text = _build_locked_text()
		return

	var pathway: Dictionary = PathwayManager.get_current_pathway()
	var sequence: Dictionary = PathwayManager.get_current_sequence()
	var characteristic: Dictionary = PathwayManager.get_current_characteristic()

	var text := ""
	text += "当前途径：%s / %s\n" % [
		pathway.get("pathway_name_cn", "未知途径"),
		pathway.get("pathway_name_en", "Unknown Pathway"),
	]
	if sequence.is_empty():
		text += "当前序列：普通人 / Unawakened\n"
		text += "目标序列：序列 9 占卜家 / Seer\n\n"
	else:
		text += "当前序列：序列 %s %s / %s\n\n" % [
			str(sequence.get("sequence_number", "?")),
			sequence.get("sequence_name_cn", "未知序列"),
			sequence.get("sequence_name_en", "Unknown"),
		]

	text += "已解锁技能：\n"
	var abilities := PathwayManager.get_unlocked_abilities()
	if abilities.is_empty():
		text += " - 暂未永久解锁。接取老尼尔任务后可临时使用见习灵视与占卜。\n"
	else:
		for ability in abilities:
			text += " - %s / %s：%s\n" % [
				ability.get("ability_name_cn", ability.get("ability_id", "")),
				ability.get("ability_name_en", ""),
				ability.get("effect_description", ""),
			]

	if sequence.is_empty():
		var target_formula := PotionManager.get_target_formula()
		var target_sequence := PotionManager.get_target_sequence()
		var main_materials = target_formula.get("main_materials", target_sequence.get("main_materials", []))
		var auxiliary_materials = target_formula.get("auxiliary_materials", target_sequence.get("auxiliary_materials", []))
		text += "\n晋升所需主材料：\n"
		text += _format_material_list(main_materials)

		text += "\n晋升所需辅助材料：\n"
		text += _format_material_list(auxiliary_materials)
	else:
		text += "\n晋升状态：已完成当前序列晋升。下一序列晋升材料暂未开放。\n"

	text += "\n非凡特性说明：\n"
	if characteristic.is_empty():
		var target_characteristic: Dictionary = DataManager.get_characteristic("char_fool_09_seer")
		if target_characteristic.is_empty():
			text += " - 暂无非凡特性数据\n"
		else:
			text += " - 外观：%s / %s\n" % [
				target_characteristic.get("appearance_cn", "未记录"),
				target_characteristic.get("appearance_en", "Unrecorded"),
			]
			text += " - 风险等级：%s\n" % target_characteristic.get("risk_level", "unknown")
			text += " - 游戏效果：%s\n" % target_characteristic.get("gameplay_effect", "未记录")
	else:
		text += " - 外观：%s / %s\n" % [
			characteristic.get("appearance_cn", "未记录"),
			characteristic.get("appearance_en", "Unrecorded"),
		]
		text += " - 风险等级：%s\n" % characteristic.get("risk_level", "unknown")
		text += " - 游戏效果：%s\n" % characteristic.get("gameplay_effect", "未记录")

	content.text = text


func _has_pathway_context() -> bool:
	return QuestManager.get_quest_status("quest_tingen_become_seer") != QuestManager.QuestStatus.NOT_STARTED or PathwayManager.current_sequence_id != ""


func _build_locked_text() -> String:
	var text := ""
	text += "当前状态：普通人 / Unawakened\n\n"
	text += "你还没有接触任何非凡途径。\n"
	text += "与老尼尔交谈并接取案件后，才会记录可疑途径、目标序列、临时能力和魔药线索。\n\n"
	text += "已解锁技能：\n"
	text += " - 无\n\n"
	text += "提示：先靠近老尼尔，按 E 与他交谈。\n"
	return text


func _format_material_list(material_ids) -> String:
	if material_ids.is_empty():
		return " - 无\n"
	var text := ""
	for material_id in material_ids:
		var material: Dictionary = DataManager.get_material(str(material_id))
		text += " - %s / %s\n" % [
			material.get("name_cn", str(material_id)),
			material.get("name_en", ""),
		]
	return text
