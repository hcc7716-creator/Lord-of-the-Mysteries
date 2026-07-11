extends Node

signal opportunity_discovered(opportunity_id: String)

var discovered_opportunities: Dictionary = {}
var opportunity_sources: Dictionary = {}


func discover_opportunity(opportunity_id: String, source_name: String = "") -> bool:
	var opportunity := DataManager.get_opportunity(opportunity_id)
	if opportunity.is_empty():
		push_warning("OpportunityManager: unknown opportunity %s" % opportunity_id)
		return false

	var is_new := not discovered_opportunities.has(opportunity_id)
	discovered_opportunities[opportunity_id] = true
	if source_name != "":
		var sources: Array = opportunity_sources.get(opportunity_id, [])
		if not sources.has(source_name):
			sources.append(source_name)
			opportunity_sources[opportunity_id] = sources

	var linked_lead_id := str(opportunity.get("linked_lead_id", ""))
	if linked_lead_id != "":
		QuestManager.discover_lead(linked_lead_id, source_name)

	if is_new:
		opportunity_discovered.emit(opportunity_id)
		GameManager.show_status_message("发现机会：%s" % str(opportunity.get("title", opportunity_id)))
	return is_new


func is_discovered(opportunity_id: String) -> bool:
	return bool(discovered_opportunities.get(opportunity_id, false))


func get_opportunity(opportunity_id: String) -> Dictionary:
	return DataManager.get_opportunity(opportunity_id)


func get_discovered_opportunities() -> Array:
	var result: Array = []
	for opportunity_id in discovered_opportunities.keys():
		var opportunity := get_opportunity(str(opportunity_id)).duplicate(true)
		if opportunity.is_empty():
			continue
		opportunity["opportunity_id"] = str(opportunity_id)
		opportunity["sources"] = opportunity_sources.get(str(opportunity_id), [])
		result.append(opportunity)
	result.sort_custom(func(a, b): return str(a.get("title", "")) < str(b.get("title", "")))
	return result


func get_source_type_label(source_type: String) -> String:
	match source_type:
		"newspaper":
			return "报纸"
		"bulletin_board":
			return "公告栏"
		"npc_dialogue":
			return "NPC 对话"
		"location_discovery":
			return "地点发现"
		_:
			return "未知来源"


func get_next_hint() -> String:
	var opportunities := get_discovered_opportunities()
	if opportunities.is_empty():
		return "探索雾城：阅读报纸、查看公告栏，或向居民打听消息"
	var opportunity: Dictionary = opportunities[0]
	return str(opportunity.get("follow_up_hint", "整理已发现的机会"))
