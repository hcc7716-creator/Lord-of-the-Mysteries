extends Node

signal stats_changed
signal corruption_warning(message: String)

const BASE_MAX_SPIRITUALITY := 60
const SEQUENCE_MAX_SPIRITUALITY := {
	"fool_09_seer": 90,
}

var max_spirituality := 60
var spirituality := 60
var corruption := 0
var stability := 100


func get_max_spirituality_for_sequence(sequence_id: String) -> int:
	if sequence_id == "":
		return BASE_MAX_SPIRITUALITY
	return int(SEQUENCE_MAX_SPIRITUALITY.get(sequence_id, BASE_MAX_SPIRITUALITY))


func apply_sequence_spirituality(sequence_id: String, refill_to_full := true) -> void:
	max_spirituality = get_max_spirituality_for_sequence(sequence_id)
	if refill_to_full:
		spirituality = max_spirituality
	else:
		spirituality = mini(spirituality, max_spirituality)
	stats_changed.emit()


func normalize_spirituality_for_sequence(sequence_id: String) -> void:
	var previous_max := max_spirituality
	var expected_max := get_max_spirituality_for_sequence(sequence_id)
	var was_full := spirituality >= previous_max
	max_spirituality = expected_max
	if was_full:
		spirituality = expected_max
	else:
		spirituality = mini(spirituality, expected_max)
	stats_changed.emit()


func consume_spirituality(amount: int) -> bool:
	if amount <= 0:
		return true
	if spirituality < amount:
		return false
	spirituality = max(0, spirituality - amount)
	stats_changed.emit()
	return true


func restore_spirituality(amount: int) -> void:
	if amount <= 0:
		return
	spirituality = min(max_spirituality, spirituality + amount)
	stats_changed.emit()


func add_corruption(amount: int, reason: String = "") -> void:
	if amount <= 0:
		return
	corruption = clampi(corruption + amount, 0, 100)
	stability = clampi(stability - max(1, amount / 2), 0, 100)
	stats_changed.emit()
	var suffix := ""
	if reason != "":
		suffix = "（%s）" % reason
	corruption_warning.emit("污染值 +%d%s" % [amount, suffix])


func reduce_corruption(amount: int) -> void:
	if amount <= 0:
		return
	corruption = max(0, corruption - amount)
	stability = min(100, stability + max(1, amount / 2))
	stats_changed.emit()


func get_divination_clarity() -> String:
	if corruption >= 70:
		return "distorted"
	if corruption >= 40:
		return "vague"
	return "clear"


func get_risk_label() -> String:
	if corruption >= 70:
		return "高"
	if corruption >= 40:
		return "中"
	return "低"
