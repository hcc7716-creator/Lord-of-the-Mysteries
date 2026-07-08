extends Node

signal inventory_changed

var materials: Dictionary = {}


func add_material(material_id: String, quantity: int = 1) -> void:
	if material_id == "" or quantity <= 0:
		return
	materials[material_id] = get_material_count(material_id) + quantity
	inventory_changed.emit()


func remove_material(material_id: String, quantity: int = 1) -> bool:
	if material_id == "" or quantity <= 0:
		return false
	var current := get_material_count(material_id)
	if current < quantity:
		return false
	var next := current - quantity
	if next <= 0:
		materials.erase(material_id)
	else:
		materials[material_id] = next
	inventory_changed.emit()
	return true


func get_material_count(material_id: String) -> int:
	return int(materials.get(material_id, 0))


func get_all_materials() -> Dictionary:
	return materials.duplicate()


func toggle_inventory() -> void:
	GameManager.toggle_inventory()
