extends PanelContainer

const TYPE_LABELS := {
	"normal_market": "普通市场",
	"black_market": "地下黑市",
	"church_storehouse": "教会物资库",
	"tarot_exchange": "灰雾等价交换",
}

@onready var summary_label: Label = $MarginContainer/VBoxContainer/SummaryLabel
@onready var markets_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/Markets
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton


func _ready() -> void:
	visible = false
	close_button.pressed.connect(func(): visible = false)
	MarketManager.purchase_completed.connect(_on_purchase_completed)
	MarketManager.purchase_failed.connect(_on_purchase_failed)
	MarketManager.market_risk_triggered.connect(_on_market_risk_triggered)
	refresh()


func refresh() -> void:
	for child in markets_container.get_children():
		child.queue_free()
	summary_label.text = "持有：%s｜市场、黑市和教会渠道会随关系与线索开放。" % EconomyManager.get_balance_text()
	for market in MarketManager.get_markets_for_current_region():
		_add_market(market)


func _add_market(market: Dictionary) -> void:
	var market_id := str(market.get("market_id", ""))
	var available := MarketManager.is_market_available(market_id)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var title := Label.new()
	title.text = "%s｜%s｜%s" % [
		str(market.get("name_cn", market_id)),
		TYPE_LABELS.get(str(market.get("market_type", "")), "市场"),
		"可进入" if available else "尚未开放",
	]
	box.add_child(title)
	var description := Label.new()
	description.text = str(market.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(description)
	if not available:
		var requirements := Label.new()
		requirements.text = "开放条件：%s" % ", ".join(market.get("unlock_conditions", []))
		requirements.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(requirements)
	else:
		for entry in MarketManager.get_market_entries(market_id):
			_add_entry_button(box, market_id, entry)
	markets_container.add_child(box)


func _add_entry_button(parent: VBoxContainer, market_id: String, entry: Dictionary) -> void:
	var entry_type := str(entry.get("entry_type", "item"))
	var entry_id := str(entry.get("item_id", entry.get("formula_id", "")))
	var item_name := str(entry.get("name_cn", ""))
	if item_name == "" and entry_type == "item":
		item_name = str(DataManager.get_material(entry_id).get("name_cn", entry_id))
	var button := Button.new()
	button.text = "购买%s：%s（%s）" % [
		"配方" if entry_type == "formula" else "物品",
		item_name,
		EconomyManager.format_pence(int(entry.get("price_pence", 0))),
	]
	button.disabled = not EconomyManager.can_afford(int(entry.get("price_pence", 0)))
	if entry_type == "formula":
		button.pressed.connect(_buy_formula.bind(market_id, entry_id))
	else:
		button.pressed.connect(_buy_item.bind(market_id, entry_id))
	parent.add_child(button)


func _buy_item(market_id: String, item_id: String) -> void:
	var result := MarketManager.buy_item(market_id, item_id)
	_show_purchase_result(result)


func _buy_formula(market_id: String, formula_id: String) -> void:
	var result := MarketManager.buy_formula(market_id, formula_id)
	_show_purchase_result(result)


func _show_purchase_result(result: Dictionary) -> void:
	if bool(result.get("success", false)):
		GameManager.show_status_message("交易完成，已更新货币与持有物。")
	else:
		GameManager.show_status_message("交易未完成：%s" % str(result.get("reason", "unknown")))
	refresh()


func _on_purchase_completed(_market_id: String, _entry_id: String, _price: int) -> void:
	refresh()


func _on_purchase_failed(_market_id: String, _entry_id: String, _reason: String) -> void:
	refresh()


func _on_market_risk_triggered(_market_id: String, _event_id: String) -> void:
	GameManager.show_status_message("黑市交易引起了额外注意。")
