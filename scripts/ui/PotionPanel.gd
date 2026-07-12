extends PanelContainer

const REQUIRED_QUANTITY := 1
const COLOR_OK := "#7ee787"
const COLOR_MISSING := "#ff8a8a"
const COLOR_DIM := "#a9a9a9"

@onready var content: RichTextLabel = $MarginContainer/VBoxContainer/ScrollContainer/Content
@onready var brew_button: Button = $MarginContainer/VBoxContainer/BrewButton
@onready var close_button: Button = $MarginContainer/VBoxContainer/Header/CloseButton


func _ready() -> void:
	visible = false
	brew_button.pressed.connect(_on_brew_pressed)
	close_button.pressed.connect(_close)
	QuestManager.quest_updated.connect(_on_quest_updated)
	InventoryManager.inventory_changed.connect(refresh)
	PotionManager.potion_brewed.connect(_on_potion_brewed)
	PotionManager.potion_brew_failed.connect(_on_potion_brew_failed)
	FormulaManager.formula_acquired.connect(func(_formula_id: String, _source: String): refresh())
	FormulaManager.formula_fragment_added.connect(func(_formula_id: String, _fragment_id: String): refresh())
	refresh()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_O:
			_close()
			get_viewport().set_input_as_handled()


func _close() -> void:
	visible = false


func refresh() -> void:
	if PathwayManager.current_sequence_id != "":
		content.text = "[b]魔药调配[/b]\n\n已完成序列 9 占卜家晋升。\n当前已不需要显示该配方材料。"
		brew_button.disabled = true
		brew_button.text = "已完成晋升"
		return

	if not PotionManager.has_recipe_unlocked():
		content.text = "[b]魔药调配[/b]\n\n尚未获得占卜家魔药配方。\n\n完成调查线索后，回到老尼尔处确认调配方式，配方和材料清单才会显示。"
		brew_button.disabled = true
		brew_button.text = "尚未获得配方"
		return

	var sequence: Dictionary = PotionManager.get_target_sequence()
	var text := ""
	text += "[b]目标序列[/b]：序列 %s %s / %s\n" % [
		str(sequence.get("sequence_number", "?")),
		sequence.get("sequence_name_cn", "未知序列"),
		sequence.get("sequence_name_en", "Unknown"),
	]
	text += "[color=%s]目标 ID：%s[/color]\n\n" % [COLOR_DIM, PotionManager.target_sequence_id]
	var formula_id := PotionManager.target_formula_id
	var formula_sources := FormulaManager.get_formula_sources(formula_id)
	if not formula_sources.is_empty():
		text += "[b]配方来源[/b]：%s\n\n" % "、".join(formula_sources)
	else:
		text += "[b]残页进度[/b]：%s\n\n" % FormulaManager.get_fragment_progress_text(formula_id)

	text += "[b]主材料[/b]\n"
	text += _format_material_checklist(PotionManager.get_main_material_ids())
	text += "\n[b]辅助材料[/b]\n"
	text += _format_material_checklist(PotionManager.get_auxiliary_material_ids())

	var missing := PotionManager.get_missing_material_names()
	text += "\n[b]缺失材料[/b]："
	if missing.is_empty():
		text += "[color=%s]无，材料已满足[/color]\n" % COLOR_OK
	else:
		text += "\n"
		for name in missing:
			text += " - [color=%s]%s[/color]\n" % [COLOR_MISSING, name]

	text += "\n[b]预计失控风险[/b]：%s\n" % PotionManager.estimate_corruption_risk()
	text += "[color=%s]配方风险：%s[/color]\n" % [
		COLOR_DIM,
		sequence.get("loss_control_risk", "暂无记录"),
	]

	var block_reason := PotionManager.get_brew_block_reason()
	if block_reason != "":
		text += "\n[b]调配条件[/b]：[color=%s]%s[/color]\n" % [COLOR_MISSING, block_reason]
	else:
		text += "\n[b]调配条件[/b]：[color=%s]可以调配并服食魔药[/color]\n" % COLOR_OK
	content.text = text

	var can_brew := PotionManager.can_brew_target_potion()
	brew_button.disabled = not can_brew
	if PathwayManager.current_sequence_id != "":
		brew_button.text = "已完成晋升"
	elif can_brew:
		brew_button.text = "调配并服食魔药"
	else:
		brew_button.text = "材料不足，暂不可调配" if not PotionManager.has_required_materials() else "暂不可调配"


func _format_material_checklist(material_ids: Array) -> String:
	if material_ids.is_empty():
		return " - 无\n"
	var text := ""
	for material_id in material_ids:
		var material: Dictionary = DataManager.get_material(str(material_id))
		var owned := InventoryManager.get_material_count(str(material_id))
		var is_satisfied := owned >= REQUIRED_QUANTITY
		var status := "[color=%s]✓ 已满足[/color]" % COLOR_OK
		if not is_satisfied:
			status = "[color=%s]缺失 %d[/color]" % [COLOR_MISSING, REQUIRED_QUANTITY - owned]
		text += " - %s %s：拥有 %d / %d（%s）\n" % [
			"[color=%s]✓[/color]" % COLOR_OK if is_satisfied else "[color=%s]□[/color]" % COLOR_MISSING,
			material.get("name_cn", str(material_id)),
			owned,
			REQUIRED_QUANTITY,
			status,
		]
	return text


func _on_brew_pressed() -> void:
	PotionManager.brew_target_potion()
	refresh()


func _on_potion_brewed(_sequence_id: String) -> void:
	refresh()


func _on_potion_brew_failed(_reason: String) -> void:
	refresh()


func _on_quest_updated(_quest_id: String) -> void:
	refresh()
