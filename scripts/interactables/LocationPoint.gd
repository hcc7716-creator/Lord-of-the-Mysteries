extends Area2D

@export var location_id := "tingen_location"
@export var location_name := "地点"
@export_multiline var location_description := "这里暂时没有新的发现。"
@export var interaction_prompt := "按 E 进入地点"

@onready var label: Label = $Label


func _ready() -> void:
	label.text = location_name


func interact(_actor: Node = null) -> void:
	DialogueManager.start_dialogue(location_name, [location_description], [{"text": "离开", "action": "close"}])
