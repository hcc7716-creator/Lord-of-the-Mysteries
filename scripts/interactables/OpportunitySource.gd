extends Area2D

@export var source_name := "线索来源"
@export var source_type := "location_discovery"
@export_multiline var source_description := "这里似乎藏着一些值得留意的消息。"
@export var opportunity_ids: Array[String] = []
@export var interaction_prompt := "按 E 查看线索"

@onready var label: Label = $Label
@onready var marker: Polygon2D = $Marker


func _ready() -> void:
	label.text = source_name
	marker.color = _get_source_color()


func interact(_actor: Node = null) -> void:
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
