extends PanelContainer

@onready var paper: ColorRect = $MarginContainer/VBoxContainer/PaperArea/Paper
@onready var ink_label: Label = $MarginContainer/VBoxContainer/PaperArea/Paper/InkLabel
@onready var keyword_list: VBoxContainer = $MarginContainer/VBoxContainer/PaperArea/Paper/KeywordList
@onready var result_label: Label = $MarginContainer/VBoxContainer/ResultLabel
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
	paper.modulate = Color(1.0, 1.0, 1.0, 0.72)
	ink_label.text = "墨迹正在纸面上游走..."
	result_label.text = "关键词显现后会同步到案件笔记。"
	close_button.visible = false
	for child in keyword_list.get_children():
		child.queue_free()

	var intro := create_tween()
	intro.tween_property(paper, "modulate:a", 1.0, 0.18)
	intro.tween_callback(func():
		if generation == display_generation:
			_reveal_keywords(data, generation)
	)


func _reveal_keywords(data: Dictionary, generation: int) -> void:
	var keywords: Array = data.get("keywords", [])
	if keywords.is_empty():
		var fallback := str(data.get("detail_text", data.get("result_text", "")))
		keywords = [fallback]

	var reveal := create_tween()
	for keyword in keywords:
		reveal.tween_callback(_add_keyword_if_current.bind(str(keyword), generation))
		reveal.tween_interval(0.42)
	reveal.tween_callback(func():
		if generation == display_generation:
			_show_result(data)
	)


func _add_keyword(keyword: String) -> void:
	var label := Label.new()
	label.text = "关键词：%s" % keyword
	label.modulate = Color(0.42, 0.30, 0.18, 0.0)
	label.position.y += 4.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	keyword_list.add_child(label)
	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property(label, "modulate:a", 1.0, 0.20)
	fade.tween_property(label, "position:y", label.position.y - 4.0, 0.20)


func _add_keyword_if_current(keyword: String, generation: int) -> void:
	if generation == display_generation:
		_add_keyword(keyword)


func _show_result(data: Dictionary) -> void:
	ink_label.text = "纸面稳定下来。"
	result_label.text = "%s\n已写入案件笔记。" % str(data.get("combined_text", data.get("result_text", "")))
	close_button.visible = true
