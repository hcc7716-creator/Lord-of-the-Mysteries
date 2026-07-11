extends Area2D

@export var source_name := "线索来源"
@export var source_type := "location_discovery"
@export_multiline var source_description := "这里似乎藏着一些值得留意的消息。"
@export var opportunity_ids: Array[String] = []
@export var interaction_prompt := "按 E 查看线索"
@export var available_periods: Array[String] = []
@export var available_weekdays: Array[String] = []

@onready var label: Label = $Label
@onready var marker: Polygon2D = $Marker


func _ready() -> void:
	label.text = source_name
	marker.color = _get_source_color()
	CalendarManager.date_changed.connect(_on_date_changed)
	_update_availability()


func interact(_actor: Node = null) -> void:
	if not _is_available():
		DialogueManager.start_dialogue(source_name, ["现在还不是适合留意这条消息的时候。"], [{"text": "离开", "action": "close"}])
		return
	var lines: Array = [source_description]
	var new_count := 0
	for opportunity_id in opportunity_ids:
		if OpportunityManager.discover_opportunity(opportunity_id, source_name):
			new_count += 1
		var opportunity := OpportunityManager.get_opportunity(opportunity_id)
		if not opportunity.is_empty():
			lines.append("记录机会：%s" % str(opportunity.get("title", opportunity_id)))
	if new_count == 0 and not opportunity_ids.is_empty():
		lines.append("你已经记下了这里能提供的消息。")
	DialogueManager.start_dialogue(source_name, lines, [{"text": "记录到线索与委托", "action": "close"}])


func _get_source_color() -> Color:
	match source_type:
		"newspaper":
			return Color(0.88, 0.78, 0.50, 0.92)
		"bulletin_board":
			return Color(0.68, 0.48, 0.24, 0.92)
		"npc_dialogue":
			return Color(0.62, 0.77, 0.95, 0.92)
		_:
			return Color(0.57, 0.83, 0.73, 0.92)


func _on_date_changed(_week: int, _weekday: String, _hour: int) -> void:
	_update_availability()


func _is_available() -> bool:
	if not available_periods.is_empty() and not available_periods.has(CalendarManager.get_time_period()):
		return false
	if not available_weekdays.is_empty() and not available_weekdays.has(CalendarManager.get_weekday()):
		return false
	return true


func _update_availability() -> void:
	var is_available := _is_available()
	visible = is_available
	monitoring = is_available
	monitorable = is_available
