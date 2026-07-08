extends PanelContainer

@onready var list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/List


func _ready() -> void:
	visible = false
	refresh()


func refresh() -> void:
	for child in list.get_children():
		child.queue_free()

	var items: Dictionary = InventoryManager.get_all_materials()
	if items.is_empty():
		_add_line("背包为空")
		return

	for material_id in items.keys():
		var material: Dictionary = DataManager.get_material(str(material_id))
		var material_name := str(material.get("name_cn", str(material_id)))
		_add_line("%s x%d" % [material_name, int(items[material_id])])


func _add_line(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.add_child(label)
