extends CanvasLayer

@onready var quest_label: Label = $TopLeft/MarginContainer/VBoxContainer/QuestLabel
@onready var spirituality_label: Label = $TopLeft/MarginContainer/VBoxContainer/SpiritualityLabel
@onready var corruption_label: Label = $TopLeft/MarginContainer/VBoxContainer/CorruptionLabel
@onready var hint_label: Label = $TopLeft/MarginContainer/VBoxContainer/HintLabel
@onready var status_label: Label = $TopLeft/MarginContainer/VBoxContainer/StatusLabel
@onready var dialogue_box: PanelContainer = $DialogueBox
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var quest_panel: PanelContainer = $QuestPanel
@onready var pathway_panel: PanelContainer = $PathwayPanel
@onready var potion_panel: PanelContainer = $PotionPanel
@onready var case_notebook_panel: PanelContainer = $CaseNotebookPanel
@onready var skill_bar: PanelContainer = $SkillBar


func _ready() -> void:
	GameManager.register_hud(self)
	QuestManager.quest_updated.connect(_on_quest_updated)
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	PathwayManager.pathway_changed.connect(_on_pathway_changed)
	CorruptionManager.stats_changed.connect(_on_stats_changed)
	CorruptionManager.corruption_warning.connect(show_status_message)
	ClueManager.notebook_updated.connect(_on_notebook_updated)
	PotionManager.potion_brewed.connect(func(_sequence_id: String): refresh_all())
	refresh_all()


func refresh_all() -> void:
	quest_label.text = QuestManager.get_active_quest_title()
	_refresh_stats()
	hint_label.text = ""
	status_label.text = "快捷键：1 灵视 / 2 灵摆占卜 / 3 纸笔占卜 / O 魔药 / N 笔记"
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
	hint_label.text = text


func clear_interaction_hint() -> void:
	hint_label.text = ""


func show_dialogue(npc_name: String, lines, options: Array = []) -> void:
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


func _toggle_panel(panel: PanelContainer) -> void:
	var next_visibility := not panel.visible
	inventory_panel.visible = false
	quest_panel.visible = false
	pathway_panel.visible = false
	potion_panel.visible = false
	case_notebook_panel.visible = false
	panel.visible = next_visibility
	if next_visibility and panel.has_method("refresh"):
		panel.refresh()


func show_status_message(text: String) -> void:
	status_label.text = text
	var timer := get_tree().create_timer(4.0)
	timer.timeout.connect(func():
		if status_label.text == text:
			status_label.text = "快捷键：1 灵视 / 2 灵摆占卜 / 3 纸笔占卜 / O 魔药 / N 笔记"
	)


func _refresh_stats() -> void:
	spirituality_label.text = "灵性：%d / %d" % [CorruptionManager.spirituality, CorruptionManager.max_spirituality]
	corruption_label.text = "污染：%d | 稳定：%d | 风险：%s" % [
		CorruptionManager.corruption,
		CorruptionManager.stability,
		CorruptionManager.get_risk_label(),
	]


func _on_quest_updated(_quest_id: String) -> void:
	quest_label.text = QuestManager.get_active_quest_title()
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
