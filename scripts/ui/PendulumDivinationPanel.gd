extends PanelContainer

@onready var pivot: Node2D = $MarginContainer/VBoxContainer/PendulumArea/Pivot
@onready var cord: Line2D = $MarginContainer/VBoxContainer/PendulumArea/Pivot/Cord
@onready var bob: Polygon2D = $MarginContainer/VBoxContainer/PendulumArea/Pivot/Bob
@onready var confidence_label: Label = $MarginContainer/VBoxContainer/ConfidenceLabel
@onready var result_label: Label = $MarginContainer/VBoxContainer/ResultLabel
@onready var note_label: Label = $MarginContainer/VBoxContainer/NoteLabel
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton

var display_generation := 0


func _ready() -> void:
	visible = false
	close_button.pressed.connect(func(): visible = false)


func show_divination(data: Dictionary) -> void:
	display_generation += 1
	var generation := display_generation
	visible = true
	modulate = Color.WHITE
	confidence_label.text = "可信度：判读中..."
	result_label.text = "灵摆正在摆动。"
	note_label.text = ""
	close_button.visible = false
	pivot.rotation_degrees = -26.0
	_apply_confidence_style(str(data.get("clarity", "clear")), false)
	_play_swing(str(data.get("clarity", "clear")), generation, data)


func _play_swing(clarity: String, generation: int, data: Dictionary) -> void:
	var swing := create_tween()
	swing.set_trans(Tween.TRANS_SINE)
	swing.set_ease(Tween.EASE_IN_OUT)
	match clarity:
		"distorted":
			swing.tween_property(pivot, "rotation_degrees", 28.0, 0.12)
			swing.tween_property(pivot, "rotation_degrees", -30.0, 0.10)
			swing.tween_property(pivot, "rotation_degrees", 19.0, 0.11)
			swing.tween_property(pivot, "rotation_degrees", -24.0, 0.10)
			swing.tween_property(pivot, "rotation_degrees", 11.0, 0.16)
		"vague":
			swing.tween_property(pivot, "rotation_degrees", 22.0, 0.24)
			swing.tween_property(pivot, "rotation_degrees", -18.0, 0.24)
			swing.tween_property(pivot, "rotation_degrees", 11.0, 0.26)
			swing.tween_property(pivot, "rotation_degrees", -6.0, 0.28)
			swing.tween_property(pivot, "rotation_degrees", 3.0, 0.26)
		_:
			swing.tween_property(pivot, "rotation_degrees", 24.0, 0.22)
			swing.tween_property(pivot, "rotation_degrees", -20.0, 0.22)
			swing.tween_property(pivot, "rotation_degrees", 14.0, 0.22)
			swing.tween_property(pivot, "rotation_degrees", -8.0, 0.22)
			swing.tween_property(pivot, "rotation_degrees", 0.0, 0.24)
	swing.tween_callback(func():
		if generation == display_generation:
			_show_result(data)
	)


func _show_result(data: Dictionary) -> void:
	confidence_label.text = "可信度：%s" % data.get("confidence_label", "稳定")
	result_label.text = str(data.get("result_text", "象征没有回应。"))
	note_label.text = str(data.get("detail_text", ""))
	close_button.visible = true
	_apply_confidence_style(str(data.get("clarity", "clear")), true)


func _apply_confidence_style(clarity: String, final_result: bool) -> void:
	var stable_color := Color(0.72, 0.94, 1.0, 1.0)
	var vague_color := Color(0.58, 0.68, 0.86, 1.0)
	var danger_color := Color(0.88, 0.36, 0.36, 1.0)
	var color := stable_color
	match clarity:
		"distorted":
			color = danger_color
		"vague":
			color = vague_color
	cord.default_color = Color(color.r, color.g, color.b, 0.88)
	bob.color = Color(color.r, color.g, color.b, 0.95)
	confidence_label.modulate = color if final_result else Color(0.80, 0.88, 0.92, 1.0)
