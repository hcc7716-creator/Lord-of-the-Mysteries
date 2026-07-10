extends PanelContainer

@onready var balance_label: Label = $MarginContainer/VBoxContainer/BalanceLabel
@onready var detail_label: Label = $MarginContainer/VBoxContainer/DetailLabel
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton


func _ready() -> void:
	visible = false
	close_button.pressed.connect(func(): visible = false)
	EconomyManager.money_changed.connect(func(_balance: int): refresh())
	refresh()


func refresh() -> void:
	var balance := EconomyManager.get_balance()
	balance_label.text = "持有货币：%s" % EconomyManager.get_balance_text()
	detail_label.text = "内部记账单位：%d 便士\n换算：1 金镑 = 240 便士｜1 苏勒 = 12 便士" % balance
