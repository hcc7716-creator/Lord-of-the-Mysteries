extends PanelContainer

const SKILL_SLOTS := [
	{"key": "1", "skill_id": "skill_seer_spiritual_vision"},
	{"key": "2", "skill_id": "skill_seer_pendulum_divination"},
	{"key": "3", "skill_id": "skill_seer_paper_divination"},
]

@onready var slots: HBoxContainer = $MarginContainer/Slots


func _ready() -> void:
	SkillManager.skill_cooldowns_updated.connect(refresh)
	SkillManager.skill_used.connect(func(_skill_id: String): refresh())
	QuestManager.quest_updated.connect(func(_quest_id: String): refresh())
	PathwayManager.pathway_changed.connect(refresh)
	CorruptionManager.stats_changed.connect(refresh)
	refresh()


func refresh() -> void:
	for child in slots.get_children():
		child.queue_free()

	for slot in SKILL_SLOTS:
		var skill_id := str(slot.get("skill_id", ""))
		var button := Button.new()
		button.custom_minimum_size = Vector2(210, 54)
		button.text = "[%s] %s" % [slot.get("key", "?"), SkillManager.get_skill_ui_hint(skill_id)]
		button.disabled = not SkillManager.can_execute_skill(skill_id)
		button.pressed.connect(SkillManager.execute_skill.bind(skill_id))
		slots.add_child(button)
