extends Node

signal formula_acquired(formula_id: String, source: String)
signal formula_fragment_added(formula_id: String, fragment_id: String)

const REQUIRED_FRAGMENT_COUNT := 3

var known_formula_ids: Array[String] = []
var formula_sources: Dictionary = {}
var formula_fragments: Dictionary = {}


func acquire_formula(formula_id: String, source: String) -> bool:
	if DataManager.get_formula(formula_id).is_empty():
		return false
	var is_new := not known_formula_ids.has(formula_id)
	if is_new:
		known_formula_ids.append(formula_id)
	var sources: Array = formula_sources.get(formula_id, [])
	if source != "" and not sources.has(source):
		sources.append(source)
		formula_sources[formula_id] = sources
	if is_new:
		formula_acquired.emit(formula_id, source)
		GameManager.show_status_message("获得配方：%s" % str(DataManager.get_formula(formula_id).get("name_cn", formula_id)))
	return is_new


func add_fragment(formula_id: String, fragment_id: String, source: String) -> bool:
	if DataManager.get_formula(formula_id).is_empty() or fragment_id == "":
		return false
	var fragments: Array = formula_fragments.get(formula_id, [])
	if fragments.has(fragment_id):
		return false
	fragments.append(fragment_id)
	formula_fragments[formula_id] = fragments
	formula_fragment_added.emit(formula_id, fragment_id)
	GameManager.show_status_message("获得配方残页：%d / %d" % [fragments.size(), REQUIRED_FRAGMENT_COUNT])
	if fragments.size() >= REQUIRED_FRAGMENT_COUNT:
		acquire_formula(formula_id, "%s拼凑" % source)
	return true


func has_formula(formula_id: String) -> bool:
	return known_formula_ids.has(formula_id)


func get_formula_sources(formula_id: String) -> Array:
	return formula_sources.get(formula_id, [])


func get_fragment_count(formula_id: String) -> int:
	return formula_fragments.get(formula_id, []).size()


func get_fragment_progress_text(formula_id: String) -> String:
	return "%d / %d" % [get_fragment_count(formula_id), REQUIRED_FRAGMENT_COUNT]
