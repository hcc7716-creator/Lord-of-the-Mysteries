extends CanvasLayer

@onready var quest_label: Label = $TopLeft/MarginContainer/VBoxContainer/QuestLabel
@onready var hint_label: Label = $TopLeft/MarginContainer/VBoxContainer/HintLabel
@onready var dialogue_box: PanelContainer = $DialogueBox
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var quest_panel: PanelContainer = $QuestPanel
@onready var pathway_panel: PanelContainer = $PathwayPanel


func _ready() -> void:
	GameManager.register_hud(self)
	QuestManager.quest_updated.connect(_on_quest_updated)
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	PathwayManager.pathway_changed.connect(_on_pathway_changed)
	refresh_all()


func refresh_all() -> void:
	quest_label.text = QuestManager.get_active_quest_title()
	hint_label.text = ""
	if inventory_panel.has_method("refresh"):
		inventory_panel.refresh()
	if quest_panel.has_method("refresh"):
		quest_panel.refresh()
	if pathway_panel.has_method("refresh"):
		pathway_panel.refresh()


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


func _toggle_panel(panel: PanelContainer) -> void:
	var next_visibility := not panel.visible
	inventory_panel.visible = false
	quest_panel.visible = false
	pathway_panel.visible = false
	panel.visible = next_visibility
	if next_visibility and panel.has_method("refresh"):
		panel.refresh()


func _on_quest_updated(_quest_id: String) -> void:
	quest_label.text = QuestManager.get_active_quest_title()
	if quest_panel.has_method("refresh"):
		quest_panel.refresh()


func _on_inventory_changed() -> void:
	if inventory_panel.has_method("refresh"):
		inventory_panel.refresh()


func _on_pathway_changed() -> void:
	if pathway_panel.has_method("refresh"):
		pathway_panel.refresh()
