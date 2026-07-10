extends PanelContainer

@onready var date_label: Label = $MarginContainer/DateLabel


func _ready() -> void:
	CalendarManager.date_changed.connect(_on_date_changed)
	refresh()


func refresh() -> void:
	date_label.text = CalendarManager.get_display_text()


func _on_date_changed(_week: int, _day: String, _hour: int) -> void:
	refresh()
