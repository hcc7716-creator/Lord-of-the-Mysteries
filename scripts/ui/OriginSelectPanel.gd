extends Control

signal origin_confirmed(origin_id: String)

@onready var region_label: Label = $Dimmer/PanelContainer/MarginContainer/VBoxContainer/RegionLabel
@onready var description_label: Label = $Dimmer/PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel
@onready var origin_options: VBoxContainer = $Dimmer/PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/OriginOptions
@onready var selection_label: Label = $Dimmer/PanelContainer/MarginContainer/VBoxContainer/SelectionLabel
@onready var confirm_button: Button = $Dimmer/PanelContainer/MarginContainer/VBoxContainer/ConfirmButton

var selected_origin_id := ""


func _ready() -> void:
	visible = false
	confirm_button.pressed.connect(_confirm_selection)


func open() -> void:
	visible = true
	_refresh_options()


func _refresh_options() -> void:
	for child in origin_options.get_children():
		child.queue_free()
	var origins := DataManager.get_origins_for_region("tingen_prototype")
	if origins.is_empty():
		origins = DataManager.get_origins_for_region("loen")
	region_label.text = "可游玩地区：鲁恩王国 · 雾城 / 廷根原型"
	description_label.text = "先选择普通人的出身。途径不会在开局确定，之后将通过工作、案件、市场与组织接触获得线索。"
	selected_origin_id = ""
	for origin in origins:
		var origin_id := str(origin.get("origin_id", ""))
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 52)
		button.text = "%s\n%s" % [str(origin.get("name_cn", origin_id)), str(origin.get("description", ""))]
		button.tooltip_text = "初始资金：%s" % EconomyManager.format_pence(int(origin.get("starting_currency_pence", 0)))
		button.pressed.connect(_select_origin.bind(origin_id))
		origin_options.add_child(button)
		if selected_origin_id == "":
			selected_origin_id = origin_id
	_update_selection_text()
	confirm_button.grab_focus()


func _select_origin(origin_id: String) -> void:
	selected_origin_id = origin_id
	_update_selection_text()


func _update_selection_text() -> void:
	var origin := DataManager.get_origin(selected_origin_id)
	if origin.is_empty():
		selection_label.text = "尚未选择出身"
		confirm_button.disabled = true
		return
	selection_label.text = "当前选择：%s｜初始资金：%s" % [
		str(origin.get("name_cn", selected_origin_id)),
		EconomyManager.format_pence(int(origin.get("starting_currency_pence", 0))),
	]
	confirm_button.disabled = false


func _confirm_selection() -> void:
	if selected_origin_id == "" or not OriginManager.select_origin(selected_origin_id):
		return
	CalendarManager.reset_calendar()
	TarotClubManager.reset()
	visible = false
	origin_confirmed.emit(selected_origin_id)
