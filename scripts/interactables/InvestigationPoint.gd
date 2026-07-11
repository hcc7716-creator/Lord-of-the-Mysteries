extends Area2D

const STATE_NORMAL := "normal"
const STATE_UNDISCOVERED := "undiscovered"
const STATE_REVEALED := "revealed"
const STATE_DISCOVERED := "discovered"

@export var investigation_id := "investigation_point"
@export var point_name := "调查点"
@export var title := ""
@export_multiline var description := "这里残留着异常的灵性痕迹。"
@export var requires_spiritual_vision := false
@export var spiritual_vision_highlight := false
@export var requires_objective_done := ""
@export var clue_id := ""
@export var lead_id := ""
@export var lead_source := ""
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
var pulse_time := 0.0
var marker_base_color := Color(0.45, 0.76, 0.72, 1.0)
var label_base_modulate := Color.WHITE

@onready var vision_glow: Polygon2D = $VisionGlow
@onready var vision_outline: Line2D = $VisionOutline
@onready var marker: Polygon2D = $Marker
@onready var label: Label = $Label
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	if title == "":
		title = point_name
	marker_base_color = marker.color
	label_base_modulate = label.modulate
	label.text = title
	if requires_spiritual_vision:
		spiritual_vision_highlight = true
	_restore_investigation_state()
	SkillManager.spiritual_vision_changed.connect(_on_spiritual_vision_changed)
	QuestManager.quest_objective_updated.connect(_on_quest_objective_updated)
	_update_visibility()


func _process(delta: float) -> void:
	pulse_time += delta
	if _should_pulse():
		_apply_visual_state()


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

	if lead_id != "":
		QuestManager.discover_lead(lead_id, lead_source if lead_source != "" else title)
		var lead: Dictionary = QuestManager.get_lead(lead_id)
		lines.append("发现机会：%s" % lead.get("title", lead_id))

	var rewards := _get_reward_items()
	for reward_id in rewards.keys():
		var quantity := int(rewards[reward_id])
		InventoryManager.add_material(str(reward_id), quantity)
		var material: Dictionary = DataManager.get_material(str(reward_id))
		var material_name := str(material.get("name_cn", str(reward_id)))
		lines.append("获得材料：%s x%d" % [material_name, quantity])

	if quest_update != "" and QuestManager.get_quest_status(quest_id) == QuestManager.QuestStatus.ACTIVE:
		QuestManager.mark_objective(quest_id, quest_update)
	if QuestManager.get_quest_status(quest_id) == QuestManager.QuestStatus.ACTIVE:
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
	_restore_investigation_state()
	_update_visibility()


func get_visual_state() -> String:
	if not requires_spiritual_vision:
		return STATE_NORMAL
	if already_investigated:
		return STATE_DISCOVERED
	if SkillManager.spiritual_vision_active and _is_objective_available():
		return STATE_REVEALED
	return STATE_UNDISCOVERED


func _update_visibility() -> void:
	var active := _is_objective_available()
	if requires_spiritual_vision and get_visual_state() == STATE_UNDISCOVERED:
		active = false
	visible = active
	monitoring = active
	monitorable = active
	if collision_shape:
		collision_shape.disabled = not active
	_apply_visual_state()


func _restore_investigation_state() -> void:
	if already_investigated:
		return
	if clue_id != "" and ClueManager.has_clue(clue_id):
		already_investigated = true
		return
	if quest_update != "" and QuestManager.is_objective_done(quest_id, quest_update):
		already_investigated = true
		return
	for objective_id in quest_updates:
		if QuestManager.is_objective_done(quest_id, str(objective_id)):
			already_investigated = true
			return


func _is_objective_available() -> bool:
	if requires_objective_done == "" or already_investigated:
		return true
	return QuestManager.is_objective_done(quest_id, requires_objective_done)


func _should_pulse() -> bool:
	if not visible:
		return false
	if get_visual_state() == STATE_REVEALED:
		return true
	return SkillManager.spiritual_vision_active and spiritual_vision_highlight and not already_investigated


func _apply_visual_state() -> void:
	var state := get_visual_state()
	var pulse := (sin(pulse_time * 6.0) + 1.0) * 0.5
	marker.scale = Vector2.ONE
	vision_glow.visible = false
	vision_outline.visible = false
	label.modulate = label_base_modulate

	match state:
		STATE_UNDISCOVERED:
			marker.color = Color(marker_base_color.r, marker_base_color.g, marker_base_color.b, 0.0)
			label.modulate = Color(label_base_modulate.r, label_base_modulate.g, label_base_modulate.b, 0.0)
		STATE_REVEALED:
			marker.color = Color(0.58, 0.92, 1.0, 0.92)
			marker.scale = Vector2.ONE * (1.0 + pulse * 0.12)
			vision_glow.visible = true
			vision_outline.visible = true
			vision_glow.color = Color(0.30, 0.74, 1.0, 0.30 + pulse * 0.30)
			vision_glow.scale = Vector2.ONE * (1.0 + pulse * 0.10)
			vision_outline.default_color = Color(0.78, 0.95, 1.0, 0.62 + pulse * 0.32)
			vision_outline.scale = Vector2.ONE * (1.0 + pulse * 0.08)
			label.modulate = Color(0.78, 0.95, 1.0, 1.0)
		STATE_DISCOVERED:
			marker.color = Color(marker_base_color.r, marker_base_color.g, marker_base_color.b, 0.38)
			vision_outline.visible = true
			vision_outline.default_color = Color(0.56, 0.82, 0.90, 0.22)
			vision_outline.scale = Vector2.ONE
			label.modulate = Color(label_base_modulate.r, label_base_modulate.g, label_base_modulate.b, 0.48)
		_:
			if SkillManager.spiritual_vision_active and spiritual_vision_highlight:
				marker.color = Color(0.55, 0.86, 0.96, 0.90)
				vision_glow.visible = true
				vision_outline.visible = true
				vision_glow.color = Color(0.25, 0.60, 0.85, 0.12 + pulse * 0.16)
				vision_glow.scale = Vector2.ONE * (0.92 + pulse * 0.08)
				vision_outline.default_color = Color(0.60, 0.86, 0.95, 0.28 + pulse * 0.20)
				vision_outline.scale = Vector2.ONE * (0.96 + pulse * 0.04)
			else:
				marker.color = marker_base_color
