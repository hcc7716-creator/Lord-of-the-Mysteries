extends Node

signal pathway_changed

var current_pathway_id := "fool"
var current_sequence_id := "fool_09_seer"
var unlocked_ability_ids: Array[String] = []


func _ready() -> void:
	refresh_unlocked_abilities()


func set_current_sequence(sequence_id: String) -> void:
	current_sequence_id = sequence_id
	var sequence: Dictionary = DataManager.get_sequence(sequence_id)
	current_pathway_id = str(sequence.get("pathway_id", current_pathway_id))
	refresh_unlocked_abilities()
	pathway_changed.emit()


func refresh_unlocked_abilities() -> void:
	unlocked_ability_ids.clear()
	var sequence := get_current_sequence()
	for ability_id in sequence.get("abilities", []):
		unlocked_ability_ids.append(str(ability_id))


func get_current_pathway() -> Dictionary:
	return DataManager.get_pathway(current_pathway_id)


func get_current_sequence() -> Dictionary:
	return DataManager.get_sequence(current_sequence_id)


func get_unlocked_abilities() -> Array:
	var result: Array = []
	for ability_id in unlocked_ability_ids:
		var ability: Dictionary = DataManager.get_ability(ability_id)
		if not ability.is_empty():
			result.append(ability)
	return result


func get_current_characteristic() -> Dictionary:
	var sequence := get_current_sequence()
	var characteristic_id := str(sequence.get("characteristic_id", ""))
	if characteristic_id == "":
		characteristic_id = "char_%s_%02d_%s" % [
			current_pathway_id,
			int(sequence.get("sequence_number", 0)),
			str(sequence.get("sequence_name_en", "")).to_lower(),
		]
	return DataManager.get_characteristic(characteristic_id)
