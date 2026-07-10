extends Node

var player: Node = null
var hud: CanvasLayer = null


func register_player(node: Node) -> void:
	player = node


func register_hud(node: CanvasLayer) -> void:
	hud = node
	_refresh_hud()


func toggle_inventory() -> void:
	if hud and hud.has_method("toggle_inventory"):
		hud.toggle_inventory()


func toggle_quest_panel() -> void:
	if hud and hud.has_method("toggle_quest_panel"):
		hud.toggle_quest_panel()


func toggle_pathway_panel() -> void:
	if hud and hud.has_method("toggle_pathway_panel"):
		hud.toggle_pathway_panel()


func toggle_potion_panel() -> void:
	if hud and hud.has_method("toggle_potion_panel"):
		hud.toggle_potion_panel()


func toggle_case_notebook() -> void:
	if hud and hud.has_method("toggle_case_notebook"):
		hud.toggle_case_notebook()


func toggle_help_panel() -> void:
	if hud and hud.has_method("toggle_help_panel"):
		hud.toggle_help_panel()


func toggle_economy_panel() -> void:
	if hud and hud.has_method("toggle_economy_panel"):
		hud.toggle_economy_panel()


func toggle_job_panel() -> void:
	if hud and hud.has_method("toggle_job_panel"):
		hud.toggle_job_panel()


func toggle_market_panel() -> void:
	if hud and hud.has_method("toggle_market_panel"):
		hud.toggle_market_panel()


func toggle_tarot_club_panel() -> void:
	if hud and hud.has_method("toggle_tarot_club_panel"):
		hud.toggle_tarot_club_panel()


func is_ui_modal_active() -> bool:
	return hud != null and hud.has_method("is_modal_panel_open") and hud.is_modal_panel_open()


func close_active_modal() -> void:
	if hud and hud.has_method("close_active_modal"):
		hud.close_active_modal()


func show_pendulum_divination(data: Dictionary) -> void:
	if hud and hud.has_method("show_pendulum_divination"):
		hud.show_pendulum_divination(data)


func show_paper_divination(data: Dictionary) -> void:
	if hud and hud.has_method("show_paper_divination"):
		hud.show_paper_divination(data)


func show_dialogue(npc_name: String, lines, options: Array = []) -> void:
	if hud and hud.has_method("show_dialogue"):
		hud.show_dialogue(npc_name, lines, options)


func show_interaction_hint(text: String) -> void:
	if hud and hud.has_method("show_interaction_hint"):
		hud.show_interaction_hint(text)


func clear_interaction_hint() -> void:
	if hud and hud.has_method("clear_interaction_hint"):
		hud.clear_interaction_hint()


func show_status_message(text: String) -> void:
	if hud and hud.has_method("show_status_message"):
		hud.show_status_message(text)
	else:
		print(text)


func _refresh_hud() -> void:
	if hud and hud.has_method("refresh_all"):
		hud.refresh_all()
