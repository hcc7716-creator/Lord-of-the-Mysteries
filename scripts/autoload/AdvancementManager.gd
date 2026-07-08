extends Node

signal advancement_success(sequence_id: String)
signal advancement_failed(reason: String)


func can_advance_to(sequence_id: String) -> bool:
	if sequence_id != "fool_09_seer":
		return false
	if PathwayManager.current_sequence_id != "":
		return false
	return true


func requires_ritual(sequence_id: String) -> bool:
	var sequence := DataManager.get_sequence(sequence_id)
	return sequence.get("advancement_ritual", null) != null


func advance_to_sequence(sequence_id: String) -> bool:
	if not can_advance_to(sequence_id):
		var reason := "当前阶段只支持普通人晋升为占卜家。"
		advancement_failed.emit(reason)
		GameManager.show_status_message(reason)
		return false

	PathwayManager.set_current_sequence(sequence_id)
	var sequence := DataManager.get_sequence(sequence_id)
	SkillManager.unlock_skills(sequence.get("abilities", []))
	QuestManager.mark_objective("quest_tingen_become_seer", "advance_seer")
	QuestManager.complete_quest("quest_tingen_become_seer")
	CorruptionManager.apply_sequence_spirituality(sequence_id, true)
	ClueManager.add_divination_hint("quest_tingen_become_seer", "advancement", "晋升成功", "你饮下魔药，灵性视野稳定展开，愚者途径序列 9 占卜家已解锁。")
	advancement_success.emit(sequence_id)
	GameManager.show_status_message("晋升成功：序列 9 占卜家 / Seer")
	return true
