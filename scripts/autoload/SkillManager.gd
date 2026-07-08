extends Node

signal skill_used(skill_id: String)
signal skill_failed(skill_id: String, reason: String)
signal skill_cooldowns_updated
signal spiritual_vision_changed(active: bool)

const DEMO_TRAINING_SKILLS: Array[String] = [
	"skill_seer_spiritual_vision",
	"skill_seer_pendulum_divination",
	"skill_seer_paper_divination",
]

var permanent_unlocked_skill_ids: Array[String] = []
var cooldowns: Dictionary = {}
var spiritual_vision_active := false


func _process(delta: float) -> void:
	var changed := false
	for skill_id in cooldowns.keys():
		var next_value: float = max(0.0, float(cooldowns[skill_id]) - delta)
		if next_value != float(cooldowns[skill_id]):
			cooldowns[skill_id] = next_value
			changed = true
	if changed:
		skill_cooldowns_updated.emit()


func get_skill(skill_id: String) -> Dictionary:
	return DataManager.get_ability(skill_id)


func unlock_skills(skill_ids: Array) -> void:
	for skill_id in skill_ids:
		var normalized: String = str(skill_id)
		if not permanent_unlocked_skill_ids.has(normalized):
			permanent_unlocked_skill_ids.append(normalized)
	skill_cooldowns_updated.emit()


func is_skill_unlocked(skill_id: String) -> bool:
	if permanent_unlocked_skill_ids.has(skill_id):
		return true
	if PathwayManager.unlocked_ability_ids.has(skill_id):
		return true
	if QuestManager.get_quest_status("quest_tingen_become_seer") == QuestManager.QuestStatus.ACTIVE and DEMO_TRAINING_SKILLS.has(skill_id):
		return true
	return false


func has_enough_spirituality(skill_id: String) -> bool:
	return CorruptionManager.spirituality >= get_skill_cost(skill_id)


func is_cooldown_ready(skill_id: String) -> bool:
	return float(cooldowns.get(skill_id, 0.0)) <= 0.0


func can_execute_skill(skill_id: String) -> bool:
	return is_skill_unlocked(skill_id) and has_enough_spirituality(skill_id) and is_cooldown_ready(skill_id)


func execute_skill(skill_id: String) -> bool:
	if not is_skill_unlocked(skill_id):
		_fail(skill_id, "技能尚未解锁")
		return false
	if not has_enough_spirituality(skill_id):
		_fail(skill_id, "灵性不足")
		return false
	if not is_cooldown_ready(skill_id):
		_fail(skill_id, "技能冷却中")
		return false

	var cost: int = get_skill_cost(skill_id)
	CorruptionManager.consume_spirituality(cost)
	cooldowns[skill_id] = get_skill_cooldown(skill_id)

	match skill_id:
		"skill_seer_spiritual_vision":
			_activate_spiritual_vision()
			GameManager.show_status_message("灵视开启：隐藏的灵性痕迹会短暂显现。")
		"skill_seer_pendulum_divination":
			var pendulum_result: String = DivinationManager.perform_divination(skill_id)
			GameManager.show_status_message(pendulum_result)
		"skill_seer_paper_divination":
			var paper_result: String = DivinationManager.perform_divination(skill_id)
			GameManager.show_status_message(paper_result)
		_:
			GameManager.show_status_message("使用技能：%s" % get_skill_name(skill_id))

	skill_used.emit(skill_id)
	skill_cooldowns_updated.emit()
	return true


func update_skill_cooldown(skill_id: String, remaining: float) -> void:
	cooldowns[skill_id] = max(0.0, remaining)
	skill_cooldowns_updated.emit()


func get_skill_ui_hint(skill_id: String) -> String:
	var skill: Dictionary = get_skill(skill_id)
	var name: String = get_skill_name(skill_id)
	var cost: int = get_skill_cost(skill_id)
	var cooldown: int = int(ceil(float(cooldowns.get(skill_id, 0.0))))
	var status := "可用"
	if not is_skill_unlocked(skill_id):
		status = "未解锁"
	elif not has_enough_spirituality(skill_id):
		status = "灵性不足"
	elif cooldown > 0:
		status = "冷却 %ds" % cooldown
	return "%s | 灵性 %d | %s\n%s" % [name, cost, status, skill.get("ui_hint", "")]


func get_skill_name(skill_id: String) -> String:
	var skill: Dictionary = get_skill(skill_id)
	return str(skill.get("ability_name_cn", skill_id))


func get_skill_cost(skill_id: String) -> int:
	var skill: Dictionary = get_skill(skill_id)
	var cost_data: Dictionary = skill.get("cost", {})
	return int(cost_data.get("spirituality", 0))


func get_skill_cooldown(skill_id: String) -> float:
	var skill: Dictionary = get_skill(skill_id)
	return float(skill.get("cooldown", 0))


func _activate_spiritual_vision() -> void:
	spiritual_vision_active = true
	spiritual_vision_changed.emit(true)
	var timer: SceneTreeTimer = get_tree().create_timer(8.0)
	timer.timeout.connect(func():
		spiritual_vision_active = false
		spiritual_vision_changed.emit(false)
		GameManager.show_status_message("灵视效果结束。")
	)


func _fail(skill_id: String, reason: String) -> void:
	skill_failed.emit(skill_id, reason)
	GameManager.show_status_message("%s：%s" % [get_skill_name(skill_id), reason])
