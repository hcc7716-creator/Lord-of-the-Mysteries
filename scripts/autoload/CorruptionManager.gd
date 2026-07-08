extends Node

signal stats_changed
signal corruption_warning(message: String)

var max_spirituality := 60
var spirituality := 60
var corruption := 0
var stability := 100


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
