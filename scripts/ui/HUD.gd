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
@onready var paper_divination_panel: PanelContainer = $PaperDivinationPanel
@onready var advancement_darken: ColorRect = $AdvancementDarken
@onready var advancement_vfx: Control = $AdvancementVFX
@onready var advancement_pulse: ColorRect = $AdvancementVFX/Pulse
@onready var advancement_spark: Label = $AdvancementVFX/Spark
@onready var advancement_popup: PanelContainer = $AdvancementPopup
@onready var advancement_title: Label = $AdvancementPopup/MarginContainer/VBoxContainer/Title
@onready var advancement_subtitle: Label = $AdvancementPopup/MarginContainer/VBoxContainer/Subtitle
@onready var advancement_spirituality_label: Label = $AdvancementPopup/MarginContainer/VBoxContainer/SpiritualityLabel
@onready var advancement_skill_list: RichTextLabel = $AdvancementPopup/MarginContainer/VBoxContainer/SkillList
@onready var advancement_continue_button: Button = $AdvancementPopup/MarginContainer/VBoxContainer/ContinueButton

var help_panel_pinned := false
var interaction_hint := ""
var transient_message := ""
var feedback_generation := 0
var spiritual_vision_tween: Tween = null
var advancement_tween: Tween = null


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
	AdvancementManager.advancement_success.connect(_on_advancement_success)
	advancement_continue_button.pressed.connect(_hide_advancement_feedback)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	_on_spiritual_vision_changed(SkillManager.spiritual_vision_active)
	refresh_all()


func _process(_delta: float) -> void:
	help_panel.visible = help_panel_pinned or Input.is_key_pressed(KEY_TAB)


func _unhandled_input(event: InputEvent) -> void:
	if not advancement_popup.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_ESCAPE:
			_hide_advancement_feedback()
			get_viewport().set_input_as_handled()


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


func show_paper_divination(data: Dictionary) -> void:
	_close_overlay_panels()
	if paper_divination_panel.has_method("show_divination"):
		paper_divination_panel.show_divination(data)


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
	paper_divination_panel.visible = false


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
	if potion_panel.has_method("refresh"):
		potion_panel.refresh()
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


func _on_advancement_success(sequence_id: String) -> void:
	refresh_all()
	_close_overlay_panels()
	skill_bar.visible = false
	_show_advancement_feedback(sequence_id)


func _show_advancement_feedback(sequence_id: String) -> void:
	if advancement_tween:
		advancement_tween.kill()

	var sequence := DataManager.get_sequence(sequence_id)
	advancement_title.text = "晋升成功"
	advancement_subtitle.text = "序列 %s %s / %s" % [
		str(sequence.get("sequence_number", "?")),
		sequence.get("sequence_name_cn", "未知序列"),
		sequence.get("sequence_name_en", "Unknown"),
	]
	advancement_spirituality_label.text = "灵性上限：%d / %d" % [
		CorruptionManager.spirituality,
		CorruptionManager.max_spirituality,
	]
	advancement_skill_list.text = _format_unlocked_skill_list(sequence.get("abilities", []))

	advancement_darken.visible = true
	advancement_vfx.visible = true
	advancement_popup.visible = true
	advancement_darken.modulate.a = 0.0
	advancement_vfx.modulate.a = 0.0
	advancement_popup.modulate.a = 0.0
	advancement_pulse.scale = Vector2(0.35, 0.35)
	advancement_pulse.modulate.a = 0.85
	advancement_spark.modulate.a = 0.0

	advancement_tween = create_tween()
	advancement_tween.tween_property(advancement_darken, "modulate:a", 1.0, 0.25)
	advancement_tween.parallel().tween_property(advancement_vfx, "modulate:a", 1.0, 0.25)
	advancement_tween.parallel().tween_property(advancement_spark, "modulate:a", 1.0, 0.25)
	advancement_tween.tween_property(advancement_pulse, "scale", Vector2(7.0, 7.0), 0.55)
	advancement_tween.parallel().tween_property(advancement_pulse, "modulate:a", 0.0, 0.55)
	advancement_tween.parallel().tween_property(advancement_spark, "modulate:a", 0.0, 0.55)
	advancement_tween.tween_property(advancement_popup, "modulate:a", 1.0, 0.25)


func _hide_advancement_feedback() -> void:
	if advancement_tween:
		advancement_tween.kill()
	advancement_tween = create_tween()
	advancement_tween.tween_property(advancement_popup, "modulate:a", 0.0, 0.15)
	advancement_tween.parallel().tween_property(advancement_darken, "modulate:a", 0.0, 0.2)
	advancement_tween.parallel().tween_property(advancement_vfx, "modulate:a", 0.0, 0.2)
	advancement_tween.tween_callback(func():
		advancement_popup.visible = false
		advancement_darken.visible = false
		advancement_vfx.visible = false
		skill_bar.visible = true
		if skill_bar.has_method("refresh"):
			skill_bar.refresh()
	)


func _format_unlocked_skill_list(skill_ids: Array) -> String:
	var text := ""
	for skill_id in skill_ids:
		var skill := DataManager.get_ability(str(skill_id))
		if skill.is_empty():
			continue
		text += "✓ %s / %s\n" % [
			skill.get("ability_name_cn", str(skill_id)),
			skill.get("ability_name_en", ""),
		]
	return text.strip_edges()
