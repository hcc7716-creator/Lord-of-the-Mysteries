extends CanvasLayer

@onready var spiritual_vision_overlay: ColorRect = $SpiritualVisionOverlay
@onready var quest_label: Label = $TopLeft/MarginContainer/VBoxContainer/QuestLabel
@onready var next_step_label: Label = $TopLeft/MarginContainer/VBoxContainer/NextStepLabel
@onready var spirituality_label: Label = $TopLeft/MarginContainer/VBoxContainer/SpiritualityLabel
@onready var corruption_label: Label = $TopLeft/MarginContainer/VBoxContainer/CorruptionLabel
@onready var feedback_panel: PanelContainer = $FeedbackPanel
@onready var feedback_label: Label = $FeedbackPanel/MarginContainer/FeedbackLabel
@onready var help_panel: PanelContainer = $HelpPanel
@onready var dialogue_box: PanelContainer = $DialogueBox
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var quest_panel: PanelContainer = $QuestPanel
@onready var pathway_panel: PanelContainer = $PathwayPanel
@onready var potion_panel: PanelContainer = $PotionPanel
@onready var case_notebook_panel: PanelContainer = $CaseNotebookPanel
@onready var skill_bar: PanelContainer = $SkillBar
@onready var pendulum_divination_panel: PanelContainer = $PendulumDivinationPanel

var help_panel_pinned := false
var interaction_hint := ""
var transient_message := ""
var feedback_generation := 0
var spiritual_vision_tween: Tween = null


func _ready() -> void:
	GameManager.register_hud(self)
	QuestManager.quest_updated.connect(_on_quest_updated)
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	PathwayManager.pathway_changed.connect(_on_pathway_changed)
	CorruptionManager.stats_changed.connect(_on_stats_changed)
	CorruptionManager.corruption_warning.connect(show_status_message)
	ClueManager.notebook_updated.connect(_on_notebook_updated)
	SkillManager.spiritual_vision_changed.connect(_on_spiritual_vision_changed)
	PotionManager.potion_brewed.connect(func(_sequence_id: String): refresh_all())
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	_on_spiritual_vision_changed(SkillManager.spiritual_vision_active)
	refresh_all()


func _process(_delta: float) -> void:
	help_panel.visible = help_panel_pinned or Input.is_key_pressed(KEY_TAB)


func refresh_all() -> void:
	_refresh_task_text()
	_refresh_stats()
	interaction_hint = ""
	transient_message = ""
	_refresh_feedback()
	if inventory_panel.has_method("refresh"):
		inventory_panel.refresh()
	if quest_panel.has_method("refresh"):
		quest_panel.refresh()
	if pathway_panel.has_method("refresh"):
		pathway_panel.refresh()
	if potion_panel.has_method("refresh"):
		potion_panel.refresh()
	if case_notebook_panel.has_method("refresh"):
		case_notebook_panel.refresh()
	if skill_bar.has_method("refresh"):
		skill_bar.refresh()


func show_interaction_hint(text: String) -> void:
	interaction_hint = text
	_refresh_feedback()


func clear_interaction_hint() -> void:
	interaction_hint = ""
	_refresh_feedback()


func show_dialogue(npc_name: String, lines, options: Array = []) -> void:
	_close_overlay_panels()
	skill_bar.visible = false
	if dialogue_box.has_method("show_dialogue"):
		dialogue_box.show_dialogue(npc_name, lines, options)


func toggle_inventory() -> void:
	_toggle_panel(inventory_panel)


func toggle_quest_panel() -> void:
	_toggle_panel(quest_panel)


func toggle_pathway_panel() -> void:
	_toggle_panel(pathway_panel)


func toggle_potion_panel() -> void:
	_toggle_panel(potion_panel)


func toggle_case_notebook() -> void:
	_toggle_panel(case_notebook_panel)


func toggle_help_panel() -> void:
	help_panel_pinned = not help_panel_pinned
	help_panel.visible = help_panel_pinned


func show_pendulum_divination(data: Dictionary) -> void:
	_close_overlay_panels()
	if pendulum_divination_panel.has_method("show_divination"):
		pendulum_divination_panel.show_divination(data)


func _toggle_panel(panel: PanelContainer) -> void:
	var next_visibility := not panel.visible
	_close_overlay_panels()
	panel.visible = next_visibility
	if next_visibility and panel.has_method("refresh"):
		panel.refresh()


func _close_overlay_panels() -> void:
	inventory_panel.visible = false
	quest_panel.visible = false
	pathway_panel.visible = false
	potion_panel.visible = false
	case_notebook_panel.visible = false
	pendulum_divination_panel.visible = false


func show_status_message(text: String) -> void:
	transient_message = text
	feedback_generation += 1
	var generation := feedback_generation
	_refresh_feedback()
	var timer := get_tree().create_timer(4.0)
	timer.timeout.connect(func():
		if generation == feedback_generation and transient_message == text:
			transient_message = ""
			_refresh_feedback()
	)


func _refresh_feedback() -> void:
	if transient_message != "":
		feedback_label.text = transient_message
		feedback_panel.visible = true
	elif interaction_hint != "":
		feedback_label.text = interaction_hint
		feedback_panel.visible = true
	else:
		feedback_label.text = ""
		feedback_panel.visible = false


func _refresh_task_text() -> void:
	quest_label.text = QuestManager.get_hud_quest_title()
	next_step_label.text = QuestManager.get_next_objective_text()


func _refresh_stats() -> void:
	spirituality_label.text = "灵性：%d / %d" % [CorruptionManager.spirituality, CorruptionManager.max_spirituality]
	corruption_label.text = "污染：%d | 风险：%s" % [
		CorruptionManager.corruption,
		CorruptionManager.get_risk_label(),
	]


func _on_quest_updated(_quest_id: String) -> void:
	_refresh_task_text()
	if quest_panel.has_method("refresh"):
		quest_panel.refresh()
	if case_notebook_panel.has_method("refresh"):
		case_notebook_panel.refresh()
	if skill_bar.has_method("refresh"):
		skill_bar.refresh()


func _on_inventory_changed() -> void:
	if inventory_panel.has_method("refresh"):
		inventory_panel.refresh()


func _on_pathway_changed() -> void:
	_refresh_task_text()
	if pathway_panel.has_method("refresh"):
		pathway_panel.refresh()
	if skill_bar.has_method("refresh"):
		skill_bar.refresh()


func _on_stats_changed() -> void:
	_refresh_stats()
	if skill_bar.has_method("refresh"):
		skill_bar.refresh()
	if potion_panel.has_method("refresh"):
		potion_panel.refresh()


func _on_notebook_updated() -> void:
	if case_notebook_panel.has_method("refresh"):
		case_notebook_panel.refresh()


func _on_spiritual_vision_changed(active: bool) -> void:
	if spiritual_vision_tween:
		spiritual_vision_tween.kill()
	if active:
		spiritual_vision_overlay.visible = true
		spiritual_vision_overlay.modulate.a = 0.0
		spiritual_vision_tween = create_tween()
		spiritual_vision_tween.tween_property(spiritual_vision_overlay, "modulate:a", 1.0, 0.18)
	else:
		spiritual_vision_tween = create_tween()
		spiritual_vision_tween.tween_property(spiritual_vision_overlay, "modulate:a", 0.0, 0.24)
		spiritual_vision_tween.tween_callback(func():
			if not SkillManager.spiritual_vision_active:
				spiritual_vision_overlay.visible = false
		)


func _on_dialogue_started(_npc_name, _lines, _options) -> void:
	_close_overlay_panels()
	skill_bar.visible = false


func _on_dialogue_finished() -> void:
	skill_bar.visible = true
	if skill_bar.has_method("refresh"):
		skill_bar.refresh()
