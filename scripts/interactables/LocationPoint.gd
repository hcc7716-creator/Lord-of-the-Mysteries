extends Area2D

@export var location_id := "tingen_location"
@export var location_name := "地点"
@export_multiline var location_description := "这里暂时没有新的发现。"
@export var interaction_prompt := "按 E 进入地点"
@export var opportunity_ids: Array[String] = []

@onready var label: Label = $Label


func _ready() -> void:
	label.text = location_name


func interact(_actor: Node = null) -> void:
	var lines: Array = [location_description]
	for opportunity_id in opportunity_ids:
		if OpportunityManager.discover_opportunity(opportunity_id, location_name):
			var opportunity := OpportunityManager.get_opportunity(opportunity_id)
			lines.append("记录机会：%s" % str(opportunity.get("title", opportunity_id)))
	DialogueManager.start_dialogue(location_name, lines, [{"text": "离开", "action": "close"}])
