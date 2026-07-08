extends PanelContainer

@onready var content: RichTextLabel = $MarginContainer/VBoxContainer/ScrollContainer/Content
@onready var brew_button: Button = $MarginContainer/VBoxContainer/BrewButton


func _ready() -> void:
	visible = false
	brew_button.pressed.connect(_on_brew_pressed)
	InventoryManager.inventory_changed.connect(refresh)
	PotionManager.potion_brewed.connect(_on_potion_brewed)
	PotionManager.potion_brew_failed.connect(_on_potion_brew_failed)
	refresh()


func refresh() -> void:
	var sequence: Dictionary = PotionManager.get_target_sequence()
	var text := ""
	text += "目标序列：序列 %s %s / %s\n\n" % [
		str(sequence.get("sequence_number", "?")),
		sequence.get("sequence_name_cn", "未知序列"),
		sequence.get("sequence_name_en", "Unknown"),
	]

	text += "主材料：\n"
	text += _format_materials(PotionManager.get_main_material_ids())
	text += "\n辅助材料：\n"
	text += _format_materials(PotionManager.get_auxiliary_material_ids())

	var missing := PotionManager.get_missing_material_names()
	text += "\n缺失材料：\n"
	if missing.is_empty():
		text += " - 无，材料已满足\n"
	else:
		for name in missing:
			text += " - %s\n" % name

	text += "\n预计失控风险：%s\n" % PotionManager.estimate_corruption_risk()
	content.text = text

	var can_brew := PotionManager.has_required_materials() and PathwayManager.current_sequence_id == ""
	brew_button.disabled = not can_brew
	if PathwayManager.current_sequence_id != "":
		brew_button.text = "已完成晋升"
	elif can_brew:
		brew_button.text = "调配魔药"
	else:
		brew_button.text = "材料不足"


func _format_materials(material_ids: Array) -> String:
	if material_ids.is_empty():
		return " - 无\n"
	var text := ""
	for material_id in material_ids:
		var material: Dictionary = DataManager.get_material(str(material_id))
		var owned := InventoryManager.get_material_count(str(material_id))
		text += " - %s / %s：%d / 1\n" % [
			material.get("name_cn", str(material_id)),
			material.get("name_en", ""),
			owned,
		]
	return text


func _on_brew_pressed() -> void:
	PotionManager.brew_target_potion()
	refresh()


func _on_potion_brewed(_sequence_id: String) -> void:
	refresh()


func _on_potion_brew_failed(_reason: String) -> void:
	refresh()
