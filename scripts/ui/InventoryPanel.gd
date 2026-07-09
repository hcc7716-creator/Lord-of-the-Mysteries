extends PanelContainer

@onready var currency_label: Label = $MarginContainer/VBoxContainer/CurrencyLabel
@onready var list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/List


func _ready() -> void:
	visible = false
	if not EconomyManager.money_changed.is_connected(_on_money_changed):
		EconomyManager.money_changed.connect(_on_money_changed)
	refresh()


func refresh() -> void:
	currency_label.text = "当前货币：%s" % EconomyManager.get_balance_text()
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


func _on_money_changed(_balance_pence: int) -> void:
	refresh()
