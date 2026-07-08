extends Node

signal potion_brewed(sequence_id: String)
signal potion_brew_failed(reason: String)

var target_sequence_id := "fool_09_seer"


func get_target_sequence() -> Dictionary:
	return DataManager.get_sequence(target_sequence_id)


func get_main_material_ids() -> Array:
	var sequence := get_target_sequence()
	return sequence.get("main_materials", [])


func get_auxiliary_material_ids() -> Array:
	var sequence := get_target_sequence()
	return sequence.get("auxiliary_materials", [])


func get_required_material_ids() -> Array:
	var result: Array = []
	result.append_array(get_main_material_ids())
	result.append_array(get_auxiliary_material_ids())
	return result


func has_required_materials() -> bool:
	return get_missing_materials().is_empty()


func get_missing_materials() -> Array:
	var missing: Array = []
	for material_id in get_required_material_ids():
		if InventoryManager.get_material_count(str(material_id)) <= 0:
			missing.append(str(material_id))
	return missing


func brew_target_potion() -> bool:
	if not has_required_materials():
		var reason := "材料不足：%s" % ", ".join(get_missing_material_names())
		potion_brew_failed.emit(reason)
		GameManager.show_status_message(reason)
		return false

	for material_id in get_required_material_ids():
		InventoryManager.remove_material(str(material_id), 1)

	potion_brewed.emit(target_sequence_id)
	QuestManager.mark_objective("quest_tingen_become_seer", "brew_potion")
	GameManager.show_status_message("占卜家魔药调配完成，开始晋升。")
	AdvancementManager.advance_to_sequence(target_sequence_id)
	return true


func get_missing_material_names() -> Array[String]:
	var names: Array[String] = []
	for material_id in get_missing_materials():
		var material := DataManager.get_material(material_id)
		names.append(str(material.get("name_cn", material_id)))
	return names


func estimate_corruption_risk() -> String:
	var base := CorruptionManager.corruption
	if base >= 70:
		return "高：当前污染过高，晋升可能引发严重异常"
	if base >= 40:
		return "中：污染会干扰魔药稳定性"
	return "低：当前状态适合调配低序列魔药"
