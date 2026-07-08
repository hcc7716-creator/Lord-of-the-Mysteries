extends Node

const DATASETS := {
	"pathways": {"path": "res://data/pathways.json", "id_key": "pathway_id"},
	"sequences": {"path": "res://data/sequences.json", "id_key": "sequence_id"},
	"materials": {"path": "res://data/materials.json", "id_key": "material_id"},
	"abilities": {"path": "res://data/abilities.json", "id_key": "ability_id"},
	"rituals": {"path": "res://data/rituals.json", "id_key": "ritual_id"},
	"characteristics": {"path": "res://data/characteristics.json", "id_key": "characteristic_id"},
	"artifacts": {"path": "res://data/sealed_artifacts.json", "id_key": "artifact_id"},
}

var pathways: Dictionary = {}
var sequences: Dictionary = {}
var materials: Dictionary = {}
var abilities: Dictionary = {}
var rituals: Dictionary = {}
var characteristics: Dictionary = {}
var artifacts: Dictionary = {}
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
	is_loaded = true
	print("DataManager loaded: %d pathways, %d sequences, %d materials, %d abilities, %d rituals, %d characteristics, %d artifacts" % [
		pathways.size(),
		sequences.size(),
		materials.size(),
		abilities.size(),
		rituals.size(),
		characteristics.size(),
		artifacts.size(),
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


func get_sequences_for_pathway(pathway_id: String) -> Array:
	_ensure_loaded()
	var result: Array = []
	for sequence in sequences.values():
		if str(sequence.get("pathway_id", "")) == pathway_id:
			result.append(sequence)
	result.sort_custom(func(a, b): return int(a.get("sequence_number", 0)) > int(b.get("sequence_number", 0)))
	return result
