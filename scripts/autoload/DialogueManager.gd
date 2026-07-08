extends Node

signal dialogue_started(npc_name, lines, options)
signal dialogue_finished

var is_dialogue_open := false


func start_dialogue(npc_name: String, lines, options: Array = []) -> void:
	var normalized_lines: Array = []
	if typeof(lines) == TYPE_STRING:
		normalized_lines.append(str(lines))
	elif typeof(lines) == TYPE_ARRAY or typeof(lines) == TYPE_PACKED_STRING_ARRAY:
		for line in lines:
			normalized_lines.append(str(line))
	else:
		normalized_lines.append("")

	is_dialogue_open = true
	dialogue_started.emit(npc_name, normalized_lines, options)
	GameManager.show_dialogue(npc_name, normalized_lines, options)


func finish_dialogue() -> void:
	is_dialogue_open = false
	dialogue_finished.emit()
