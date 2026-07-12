extends Node

signal faction_relation_changed(faction_id: String)
signal faction_information_learned(faction_id: String, information: String)

const JOB_RELATION_EFFECTS := {
	"job_church_helper": {"church": [2, 1, 0], "black_market": [0, 0, 1]},
	"job_detective_assistant": {"police": [2, 1, 0], "black_market": [0, 0, 1]},
	"job_police_informant": {"police": [2, 2, 0], "black_market": [-1, 0, 2]},
	"job_black_market_runner": {"black_market": [2, 1, 0], "police": [0, -1, 2], "church": [0, 0, 1]},
	"job_dock_worker": {"black_market": [1, 0, 0]},
	"job_newspaper_copyist": {"divination_club": [1, 1, 0]},
}

var relations: Dictionary = {}
var known_information: Dictionary = {}


func _ready() -> void:
	_initialize_relations()
	JobManager.job_completed.connect(_on_job_completed)
	MarketManager.purchase_completed.connect(_on_market_purchase)


func _initialize_relations() -> void:
	for faction in DataManager.factions.values():
		var faction_id := str(faction.get("faction_id", ""))
		if faction_id == "":
			continue
		if not relations.has(faction_id):
			relations[faction_id] = {
				"reputation": int(faction.get("default_reputation", 0)),
				"trust": int(faction.get("default_trust", 0)),
				"hostility": int(faction.get("default_hostility", 0)),
			}
		if not known_information.has(faction_id):
			known_information[faction_id] = faction.get("known_information", []).duplicate()


func get_all_factions() -> Array:
	var result: Array = []
	for faction in DataManager.factions.values():
		result.append(faction)
	result.sort_custom(func(a, b): return str(a.get("faction_id", "")) < str(b.get("faction_id", "")))
	return result


func get_relation(faction_id: String) -> Dictionary:
	_initialize_relations()
	return relations.get(faction_id, {"reputation": 0, "trust": 0, "hostility": 0})


func adjust_relation(faction_id: String, reputation_delta := 0, trust_delta := 0, hostility_delta := 0) -> void:
	if DataManager.get_faction(faction_id).is_empty():
		return
	var relation := get_relation(faction_id).duplicate()
	relation["reputation"] = clampi(int(relation.get("reputation", 0)) + reputation_delta, -10, 10)
	relation["trust"] = clampi(int(relation.get("trust", 0)) + trust_delta, -10, 10)
	relation["hostility"] = clampi(int(relation.get("hostility", 0)) + hostility_delta, 0, 10)
	relations[faction_id] = relation
	faction_relation_changed.emit(faction_id)


func learn_information(faction_id: String, information: String) -> void:
	if information == "":
		return
	var entries: Array = known_information.get(faction_id, [])
	if entries.has(information):
		return
	entries.append(information)
	known_information[faction_id] = entries
	faction_information_learned.emit(faction_id, information)


func get_known_information(faction_id: String) -> Array:
	_initialize_relations()
	return known_information.get(faction_id, [])


func can_access_market(market_id: String) -> bool:
	var market := DataManager.get_market(market_id)
	var faction_id := str(market.get("faction_id", ""))
	if faction_id == "":
		return true
	var requirement: Dictionary = market.get("faction_requirements", {})
	var relation := get_relation(faction_id)
	return int(relation.get("reputation", 0)) >= int(requirement.get("reputation", -10)) and int(relation.get("trust", 0)) >= int(requirement.get("trust", -10)) and int(relation.get("hostility", 0)) <= int(requirement.get("max_hostility", 10))


func get_market_access_reason(market_id: String) -> String:
	if can_access_market(market_id):
		return ""
	var market := DataManager.get_market(market_id)
	var faction := DataManager.get_faction(str(market.get("faction_id", "")))
	var requirement: Dictionary = market.get("faction_requirements", {})
	return "需要 %s：声望 %d、信任 %d，且敌意不高于 %d" % [
		str(faction.get("name_cn", "相关势力")),
		int(requirement.get("reputation", 0)),
		int(requirement.get("trust", 0)),
		int(requirement.get("max_hostility", 10)),
	]


func get_effective_price(market_id: String, base_price: int) -> int:
	var market := DataManager.get_market(market_id)
	var faction_id := str(market.get("faction_id", ""))
	if faction_id == "":
		return base_price
	var faction := DataManager.get_faction(faction_id)
	var rule: Dictionary = faction.get("market_price_modifier", {})
	var relation := get_relation(faction_id)
	var multiplier := 1.0
	multiplier -= float(relation.get("reputation", 0)) * float(rule.get("reputation_discount_per_point", 0.0))
	multiplier -= float(relation.get("trust", 0)) * float(rule.get("trust_discount_per_point", 0.0))
	multiplier += float(relation.get("hostility", 0)) * float(rule.get("hostility_markup_per_point", 0.0))
	multiplier = clampf(multiplier, float(rule.get("min_multiplier", 0.5)), float(rule.get("max_multiplier", 2.0)))
	return maxi(1, int(round(float(base_price) * multiplier)))


func get_faction_jobs(faction_id: String) -> Array:
	var faction := DataManager.get_faction(faction_id)
	var result: Array = []
	for job_id in faction.get("available_jobs", []):
		var job := DataManager.get_job(str(job_id))
		if not job.is_empty():
			result.append(job)
	return result


func _on_job_completed(job_id: String, _reward_pence: int) -> void:
	var effects: Dictionary = JOB_RELATION_EFFECTS.get(job_id, {})
	for faction_id in effects.keys():
		var values: Array = effects[faction_id]
		adjust_relation(str(faction_id), int(values[0]), int(values[1]), int(values[2]))


func _on_market_purchase(market_id: String, _entry_id: String, _price: int) -> void:
	var market := DataManager.get_market(market_id)
	var faction_id := str(market.get("faction_id", ""))
	if faction_id == "":
		return
	adjust_relation(faction_id, 1, 0, 0)
	if faction_id == "black_market":
		adjust_relation("police", 0, -1, 1)
		CorruptionManager.add_corruption(1, "黑市交易留下了难以解释的痕迹")
