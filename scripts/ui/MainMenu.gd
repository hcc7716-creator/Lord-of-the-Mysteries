extends Control

const GAME_SCENE := "res://scenes/main/Main.tscn"

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var origin_select_panel = $OriginSelectPanel


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	origin_select_panel.origin_confirmed.connect(_on_origin_confirmed)
	start_button.grab_focus()


func _on_start_button_pressed() -> void:
	start_button.disabled = true
	origin_select_panel.open()


func _on_origin_confirmed(_origin_id: String) -> void:
	get_tree().change_scene_to_file(GAME_SCENE)
