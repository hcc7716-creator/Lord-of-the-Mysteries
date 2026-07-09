extends Node

signal money_changed(balance_pence: int)
signal transaction_failed(reason: String)

var balance_pence := 0


func set_balance(amount_pence: int) -> void:
	balance_pence = max(0, amount_pence)
	money_changed.emit(balance_pence)


func add_money(amount_pence: int) -> void:
	if amount_pence <= 0:
		return
	balance_pence += amount_pence
	money_changed.emit(balance_pence)


func spend_money(amount_pence: int) -> bool:
	if amount_pence <= 0:
		return true
	if balance_pence < amount_pence:
		transaction_failed.emit("not_enough_money")
		return false
	balance_pence -= amount_pence
	money_changed.emit(balance_pence)
	return true


func can_afford(amount_pence: int) -> bool:
	return balance_pence >= amount_pence


func get_balance() -> int:
	return balance_pence


func format_pence(amount_pence: int) -> String:
	var remaining: int = max(0, amount_pence)
	var pound_value: int = int(DataManager.get_currency_unit("pound").get("value_in_pence", 240))
	var soli_value: int = int(DataManager.get_currency_unit("soli").get("value_in_pence", 12))
	var pounds: int = remaining / pound_value
	remaining %= pound_value
	var soli: int = remaining / soli_value
	remaining %= soli_value
	return "%d金镑 %d苏勒 %d便士" % [pounds, soli, remaining]
