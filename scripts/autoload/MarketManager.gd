extends Node

signal market_unlocked(market_id: String)

var unlocked_flags: Dictionary = {}


func add_unlock_flag(flag: String) -> void:
	if flag == "":
		return
	unlocked_flags[flag] = true


func has_unlock_flag(flag: String) -> bool:
	return bool(unlocked_flags.get(flag, false))


func get_markets_for_current_region() -> Array:
	var region_id := OriginManager.starting_region_id
	if region_id == "":
		region_id = "tingen_prototype"
	return DataManager.get_markets_for_region(region_id)


func is_market_available(market_id: String) -> bool:
	var market := DataManager.get_market(market_id)
	if market.is_empty():
		return false
	for condition in market.get("unlock_conditions", []):
		var condition_id := str(condition)
		if condition_id == "" or condition_id == "future_region_unlock":
			continue
		if not has_unlock_flag(condition_id):
			return false
	return true


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
