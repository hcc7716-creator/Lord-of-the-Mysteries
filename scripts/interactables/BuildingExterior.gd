extends Node2D

@export var location_id := "tingen_building"
@export var location_name := "地点"
@export_multiline var location_description := "这里暂时没有新的发现。"
@export var interaction_prompt := "按 E 查看地点"
@export var opportunity_ids: Array[String] = []
@export var allows_rest := false
@export var rest_hours := 8
@export var open_windows: Array[String] = []
@export var interaction_enabled := true
@export var label_reveal_distance := 150.0

@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_shape: CollisionShape2D = $InteractionArea/CollisionShape2D
@onready var name_label: Label = $NameLabel


func _ready() -> void:
	name_label.text = location_name
	name_label.visible = false
	if not interaction_enabled:
		interaction_area.collision_layer = 0
		interaction_area.monitoring = false
		interaction_area.monitorable = false
		interaction_shape.disabled = true


func _process(_delta: float) -> void:
	var player := GameManager.player as Node2D
	name_label.visible = player != null and global_position.distance_to(player.global_position) <= label_reveal_distance


func interact(_actor: Node = null) -> void:
	if not interaction_enabled:
		return
	if not _is_open():
		DialogueManager.start_dialogue(
			location_name,
			["这里现在没有开放。可开放时段：%s" % _format_open_windows()],
			[{"text": "离开", "action": "close"}]
		)
		return

	var lines: Array = [location_description]
	for opportunity_id in opportunity_ids:
		if OpportunityManager.discover_opportunity(opportunity_id, location_name):
			var opportunity := OpportunityManager.get_opportunity(opportunity_id)
			lines.append("记录机会：%s" % str(opportunity.get("title", opportunity_id)))
	var options: Array = [{"text": "离开", "action": "close"}]
	if allows_rest:
		options.push_front({"text": "休息 %d 小时" % rest_hours, "action": "rest", "hours": rest_hours})
	DialogueManager.start_dialogue(location_name, lines, options)


func _is_open() -> bool:
	if open_windows.is_empty():
		return true
	for window in open_windows:
		if CalendarManager.matches_open_window(window):
			return true
	return false


func _format_open_windows() -> String:
	if open_windows.is_empty():
		return "全天"
	return " / ".join(open_windows)
