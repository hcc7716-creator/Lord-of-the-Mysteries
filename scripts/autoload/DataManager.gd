extends Node

const DATASETS := {
	"pathways": {"path": "res://data/pathways.json", "id_key": "pathway_id"},
	"sequences": {"path": "res://data/sequences.json", "id_key": "sequence_id"},
	"materials": {"path": "res://data/materials.json", "id_key": "material_id"},
	"abilities": {"path": "res://data/abilities.json", "id_key": "ability_id"},
	"rituals": {"path": "res://data/rituals.json", "id_key": "ritual_id"},
	"characteristics": {"path": "res://data/characteristics.json", "id_key": "characteristic_id"},
	"artifacts": {"path": "res://data/sealed_artifacts.json", "id_key": "artifact_id"},
	"regions": {"path": "res://data/regions.json", "id_key": "region_id"},
	"origins": {"path": "res://data/origins.json", "id_key": "origin_id"},
	"currencies": {"path": "res://data/currencies.json", "id_key": "currency_id"},
	"jobs": {"path": "res://data/jobs.json", "id_key": "job_id"},
	"markets": {"path": "res://data/markets.json", "id_key": "market_id"},
	"potion_formulas": {"path": "res://data/potion_formulas.json", "id_key": "formula_id"},
	"tarot_exchange_requests": {"path": "res://data/tarot_exchange_requests.json", "id_key": "request_id"},
}

var pathways: Dictionary = {}
var sequences: Dictionary = {}
var materials: Dictionary = {}
var abilities: Dictionary = {}
var rituals: Dictionary = {}
var characteristics: Dictionary = {}
var artifacts: Dictionary = {}
var regions: Dictionary = {}
var origins: Dictionary = {}
var currencies: Dictionary = {}
var jobs: Dictionary = {}
var markets: Dictionary = {}
var potion_formulas: Dictionary = {}
var tarot_exchange_requests: Dictionary = {}
var is_loaded := false


func _ready() -> void:
	load_all_data()


func load_all_data() -> void:
	_load_dataset(pathways, DATASETS["pathways"]["path"], DATASETS["pathways"]["id_key"])
	_load_dataset(sequences, DATASETS["sequences"]["path"], DATASETS["sequences"]["id_key"])
	_load_dataset(materials, DATASETS["materials"]["path"], DATASETS["materials"]["id_key"])
	_load_dataset(abilities, DATASETS["abilities"]["path"], DATASETS["abilities"]["id_key"])
	_load_dataset(rituals, DATASETS["rituals"]["path"], DATASETS["rituals"]["id_key"])
	_load_dataset(characteristics, DATASETS["characteristics"]["path"], DATASETS["characteristics"]["id_key"])
	_load_dataset(artifacts, DATASETS["artifacts"]["path"], DATASETS["artifacts"]["id_key"])
	_load_dataset(regions, DATASETS["regions"]["path"], DATASETS["regions"]["id_key"])
	_load_dataset(origins, DATASETS["origins"]["path"], DATASETS["origins"]["id_key"])
	_load_dataset(currencies, DATASETS["currencies"]["path"], DATASETS["currencies"]["id_key"])
	_load_dataset(jobs, DATASETS["jobs"]["path"], DATASETS["jobs"]["id_key"])
	_load_dataset(markets, DATASETS["markets"]["path"], DATASETS["markets"]["id_key"])
	_load_dataset(potion_formulas, DATASETS["potion_formulas"]["path"], DATASETS["potion_formulas"]["id_key"])
	_load_dataset(tarot_exchange_requests, DATASETS["tarot_exchange_requests"]["path"], DATASETS["tarot_exchange_requests"]["id_key"])
	is_loaded = true
	print("DataManager loaded: %d pathways, %d sequences, %d materials, %d abilities, %d rituals, %d characteristics, %d artifacts, %d regions, %d origins, %d currencies, %d jobs, %d markets, %d formulas, %d tarot requests" % [
		pathways.size(),
		sequences.size(),
		materials.size(),
		abilities.size(),
		rituals.size(),
		characteristics.size(),
		artifacts.size(),
		regions.size(),
		origins.size(),
		currencies.size(),
		jobs.size(),
		markets.size(),
		potion_formulas.size(),
		tarot_exchange_requests.size(),
	])


func _load_dataset(target: Dictionary, file_path: String, id_key: String) -> void:
	target.clear()

	if not FileAccess.file_exists(file_path):
		push_error("DataManager: missing data file %s" % file_path)
		return

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("DataManager: cannot open data file %s" % file_path)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("DataManager: invalid JSON in %s" % file_path)
		return

	_index_records(parsed, target, id_key)


func _index_records(records, target: Dictionary, id_key: String) -> void:
	match typeof(records):
		TYPE_ARRAY:
			for item in records:
				_index_record(item, target, id_key)
		TYPE_DICTIONARY:
			if records.has("data") and typeof(records["data"]) == TYPE_ARRAY:
				for item in records["data"]:
					_index_record(item, target, id_key)
			else:
				for key in records.keys():
					var item = records[key]
					if typeof(item) == TYPE_DICTIONARY:
						if not item.has(id_key):
							item[id_key] = str(key)
						_index_record(item, target, id_key)
		_:
			push_warning("DataManager: unsupported JSON root type for %s" % id_key)


func _index_record(item, target: Dictionary, id_key: String) -> void:
	if typeof(item) != TYPE_DICTIONARY:
		return
	if not item.has(id_key):
		push_warning("DataManager: skipped record without id key %s" % id_key)
		return
	target[str(item[id_key])] = item


func _ensure_loaded() -> void:
	if not is_loaded:
		load_all_data()


func get_pathway(id: String) -> Dictionary:
	_ensure_loaded()
	return pathways.get(id, {})


func get_sequence(id: String) -> Dictionary:
	_ensure_loaded()
	return sequences.get(id, {})


func get_material(id: String) -> Dictionary:
	_ensure_loaded()
	return materials.get(id, {})


func get_ability(id: String) -> Dictionary:
	_ensure_loaded()
	return abilities.get(id, {})


func get_ritual(id: String) -> Dictionary:
	_ensure_loaded()
	return rituals.get(id, {})


func get_characteristic(id: String) -> Dictionary:
	_ensure_loaded()
	return characteristics.get(id, {})


func get_artifact(id: String) -> Dictionary:
	_ensure_loaded()
	return artifacts.get(id, {})


func get_region(id: String) -> Dictionary:
	_ensure_loaded()
	return regions.get(id, {})


func get_origin(id: String) -> Dictionary:
	_ensure_loaded()
	return origins.get(id, {})


func get_currency(id: String) -> Dictionary:
	_ensure_loaded()
	return currencies.get(id, {})


func get_job(id: String) -> Dictionary:
	_ensure_loaded()
	return jobs.get(id, {})


func get_market(id: String) -> Dictionary:
	_ensure_loaded()
	return markets.get(id, {})


func get_potion_formula(id: String) -> Dictionary:
	_ensure_loaded()
	return potion_formulas.get(id, {})


func get_formula(id: String) -> Dictionary:
	return get_potion_formula(id)


func get_tarot_exchange_request(id: String) -> Dictionary:
	_ensure_loaded()
	return tarot_exchange_requests.get(id, {})


func get_tarot_request(id: String) -> Dictionary:
	return get_tarot_exchange_request(id)


func get_sequences_for_pathway(pathway_id: String) -> Array:
	_ensure_loaded()
	var result: Array = []
	for sequence in sequences.values():
		if str(sequence.get("pathway_id", "")) == pathway_id:
			result.append(sequence)
	result.sort_custom(func(a, b): return int(a.get("sequence_number", 0)) > int(b.get("sequence_number", 0)))
	return result


func get_starting_regions() -> Array:
	_ensure_loaded()
	var result: Array = []
	for region in regions.values():
		if bool(region.get("is_starting_region", false)):
			result.append(region)
	return result


func get_origins_for_region(region_id: String) -> Array:
	_ensure_loaded()
	var result: Array = []
	for origin in origins.values():
		if str(origin.get("region_id", "")) == region_id or str(origin.get("starting_region_id", "")) == region_id:
			result.append(origin)
	return result


func get_jobs_for_region(region_id: String) -> Array:
	_ensure_loaded()
	var result: Array = []
	for job in jobs.values():
		if str(job.get("region_id", "")) == region_id:
			result.append(job)
	return result


func get_markets_for_region(region_id: String) -> Array:
	_ensure_loaded()
	var result: Array = []
	for market in markets.values():
		if str(market.get("region_id", "")) == region_id:
			result.append(market)
	return result


func get_formulas_for_sequence(sequence_id: String) -> Array:
	_ensure_loaded()
	var result: Array = []
	for formula in potion_formulas.values():
		if str(formula.get("sequence_id", "")) == sequence_id:
			result.append(formula)
	return result


func get_tarot_requests_for_weekday(weekday: String) -> Array:
	_ensure_loaded()
	var result: Array = []
	for request in tarot_exchange_requests.values():
		var schedule: Dictionary = request.get("schedule", {})
		if str(schedule.get("weekday", "")) == weekday:
			result.append(request)
	return result
