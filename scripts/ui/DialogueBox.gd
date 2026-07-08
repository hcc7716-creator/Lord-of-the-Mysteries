extends PanelContainer

var npc_name := ""
var lines: Array[String] = []
var options: Array = []
var line_index := 0

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var dialogue_text: RichTextLabel = $MarginContainer/VBoxContainer/DialogueText
@onready var options_container: VBoxContainer = $MarginContainer/VBoxContainer/Options


func _ready() -> void:
	visible = false


func show_dialogue(next_npc_name: String, next_lines, next_options: Array = []) -> void:
	npc_name = next_npc_name
	lines.clear()
	if typeof(next_lines) == TYPE_ARRAY or typeof(next_lines) == TYPE_PACKED_STRING_ARRAY:
		for line in next_lines:
			lines.append(str(line))
	else:
		lines.append(str(next_lines))
	options = next_options
	line_index = 0
	visible = true
	_render_current_line()


func _render_current_line() -> void:
	name_label.text = npc_name
	dialogue_text.text = lines[line_index] if line_index < lines.size() else ""
	_clear_options()

	if line_index < lines.size() - 1:
		_add_button("继续", func(): _next_line())
	else:
		if options.is_empty():
			_add_button("结束", func(): _close())
		else:
			for option in options:
				var text := str(option.get("text", "继续"))
				_add_option_button(text, option)


func _next_line() -> void:
	line_index += 1
	_render_current_line()


func _select_option(option: Dictionary) -> void:
	var action := str(option.get("action", "close"))
	match action:
		"accept_quest":
			QuestManager.accept_quest(str(option.get("quest_id", "")))
		"complete_quest":
			QuestManager.complete_quest(str(option.get("quest_id", "")))
		"add_material":
			InventoryManager.add_material(str(option.get("material_id", "")), int(option.get("quantity", 1)))
		_:
			pass
	_close()


func _close() -> void:
	visible = false
	DialogueManager.finish_dialogue()


func _clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()


func _add_button(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	options_container.add_child(button)


func _add_option_button(text: String, option: Dictionary) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(_select_option.bind(option))
	options_container.add_child(button)
