extends Node

signal market_unlocked(market_id: String)
signal purchase_completed(market_id: String, entry_id: String, price_pence: int)
signal purchase_failed(market_id: String, entry_id: String, reason: String)
signal market_risk_triggered(market_id: String, event_id: String)
signal formula_acquired(formula_id: String)

var unlocked_flags: Dictionary = {}
var purchased_item_ids: Array[String] = []
var known_formula_ids: Array[String] = []


func add_unlock_flag(flag: String) -> void:
	if flag == "":
		return
	unlocked_flags[flag] = true
	for market in get_markets_for_current_region():
		var market_id := str(market.get("market_id", ""))
		if market_id != "" and is_market_available(market_id):
			market_unlocked.emit(market_id)


func has_unlock_flag(flag: String) -> bool:
	return bool(unlocked_flags.get(flag, false))


func get_markets_for_current_region() -> Array:
	var region_id := OriginManager.starting_region_id
	if region_id == "":
		region_id = "tingen_prototype"
	return DataManager.get_markets_for_region(region_id)


func get_market_entries(market_id: String) -> Array:
	var market := DataManager.get_market(market_id)
	if market.is_empty():
		return []
	var entries: Array = []
	for item in market.get("available_items", []):
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = item.duplicate(true)
		entry["entry_type"] = "item"
		entry["base_price_pence"] = int(entry.get("price_pence", 0))
		entry["price_pence"] = FactionManager.get_effective_price(market_id, int(entry.get("price_pence", 0)))
		entries.append(entry)
	for formula_id in market.get("available_formulas", []):
		var formula := DataManager.get_formula(str(formula_id))
		if formula.is_empty():
			continue
		var base_price := int(formula.get("base_price_pence", 0))
		entries.append({
			"entry_type": "formula",
			"formula_id": str(formula_id),
			"name_cn": str(formula.get("name_cn", formula_id)),
			"base_price_pence": base_price,
			"price_pence": FactionManager.get_effective_price(market_id, base_price),
		})
	return entries


func is_market_available(market_id: String) -> bool:
	return is_market_unlocked(market_id)


func is_market_unlocked(market_id: String) -> bool:
	var market := DataManager.get_market(market_id)
	if market.is_empty():
		return false
	for condition in market.get("unlock_conditions", []):
		var condition_id := str(condition)
		if condition_id == "" or condition_id == "future_region_unlock":
			continue
		if not has_unlock_flag(condition_id):
			return false
	return FactionManager.can_access_market(market_id)


func is_market_open(market_id: String) -> bool:
	var market := DataManager.get_market(market_id)
	if market.is_empty():
		return false
	for window in market.get("open_days", []):
		if CalendarManager.matches_open_window(str(window)):
			return true
	return false


func can_trade(market_id: String) -> bool:
	return is_market_unlocked(market_id) and is_market_open(market_id)


func get_market_time_status(market_id: String) -> String:
	if not is_market_unlocked(market_id):
		return "尚未开放"
	if is_market_open(market_id):
		return "营业中"
	return "当前休市"


func get_available_formulas(market_id: String) -> Array:
	if not is_market_available(market_id):
		return []
	var market := DataManager.get_market(market_id)
	var result: Array = []
	for formula_id in market.get("available_formulas", []):
		var formula := DataManager.get_formula(str(formula_id))
		if not formula.is_empty():
			result.append(formula)
	return result


func buy_item(market_id: String, item_id: String) -> Dictionary:
	var market := DataManager.get_market(market_id)
	if market.is_empty() or not is_market_available(market_id):
		return _fail_purchase(market_id, item_id, "market_locked")
	for item in market.get("available_items", []):
		if typeof(item) != TYPE_DICTIONARY or str(item.get("item_id", "")) != item_id:
			continue
		var price := FactionManager.get_effective_price(market_id, int(item.get("price_pence", 0)))
		if not EconomyManager.spend_money(price):
			return _fail_purchase(market_id, item_id, "not_enough_money")
		if not purchased_item_ids.has(item_id):
			purchased_item_ids.append(item_id)
		if not DataManager.get_material(item_id).is_empty():
			InventoryManager.add_material(item_id, 1)
		_trigger_market_risk(market_id, market)
		purchase_completed.emit(market_id, item_id, price)
		return {"success": true, "entry_id": item_id, "price_pence": price}
	return _fail_purchase(market_id, item_id, "item_not_sold")


func buy_formula(market_id: String, formula_id: String) -> Dictionary:
	var market := DataManager.get_market(market_id)
	if market.is_empty() or not is_market_available(market_id):
		return _fail_purchase(market_id, formula_id, "market_locked")
	if not market.get("available_formulas", []).has(formula_id):
		return _fail_purchase(market_id, formula_id, "formula_not_sold")
	var formula := DataManager.get_formula(formula_id)
	var price := FactionManager.get_effective_price(market_id, int(formula.get("base_price_pence", 0)))
	if not EconomyManager.spend_money(price):
		return _fail_purchase(market_id, formula_id, "not_enough_money")
	if not known_formula_ids.has(formula_id):
		known_formula_ids.append(formula_id)
	formula_acquired.emit(formula_id)
	_trigger_market_risk(market_id, market)
	purchase_completed.emit(market_id, formula_id, price)
	return {"success": true, "entry_id": formula_id, "price_pence": price}


func is_formula_known(formula_id: String) -> bool:
	return known_formula_ids.has(formula_id)


func _fail_purchase(market_id: String, entry_id: String, reason: String) -> Dictionary:
	purchase_failed.emit(market_id, entry_id, reason)
	return {"success": false, "reason": reason}


func _trigger_market_risk(market_id: String, market: Dictionary) -> void:
	if str(market.get("market_type", "")) != "black_market":
		return
	for risk_event in market.get("risk_events", []):
		if typeof(risk_event) != TYPE_DICTIONARY:
			continue
		if randf() <= float(risk_event.get("chance", 0.0)):
			var event_id := str(risk_event.get("event_id", ""))
			if event_id != "":
				market_risk_triggered.emit(market_id, event_id)
				CorruptionManager.add_corruption(2, "黑市交易带来了额外风险")
