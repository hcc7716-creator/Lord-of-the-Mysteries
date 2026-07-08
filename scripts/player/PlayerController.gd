extends CharacterBody2D

@export var speed := 240.0

var nearby_interactables: Array[Node] = []

@onready var interaction_area: Area2D = $InteractionArea


func _ready() -> void:
	GameManager.register_player(self)
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0

	velocity = direction.normalized() * speed
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var pressed_key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		match pressed_key:
			KEY_E:
				_try_interact()
			KEY_I:
				InventoryManager.toggle_inventory()
			KEY_J:
				GameManager.toggle_quest_panel()
			KEY_P:
				GameManager.toggle_pathway_panel()
			KEY_O:
				GameManager.toggle_potion_panel()
			KEY_N:
				GameManager.toggle_case_notebook()
			KEY_H:
				GameManager.toggle_help_panel()
			KEY_1:
				SkillManager.execute_skill("skill_seer_spiritual_vision")
			KEY_2:
				SkillManager.execute_skill("skill_seer_pendulum_divination")
			KEY_3:
				SkillManager.execute_skill("skill_seer_paper_divination")


func _try_interact() -> void:
	var target := _get_best_interactable()
	if target and target.has_method("interact"):
		target.interact(self)


func _get_best_interactable() -> Node:
	var best: Node = null
	var best_distance := INF
	for item in nearby_interactables:
		if not is_instance_valid(item):
			continue
		var distance := global_position.distance_to(item.global_position)
		if distance < best_distance:
			best = item
			best_distance = distance
	return best


func _on_interaction_area_entered(area: Area2D) -> void:
	if area.has_method("interact"):
		nearby_interactables.append(area)
		_update_interaction_hint()


func _on_interaction_area_exited(area: Area2D) -> void:
	nearby_interactables.erase(area)
	_update_interaction_hint()


func _update_interaction_hint() -> void:
	var target := _get_best_interactable()
	if target == null:
		GameManager.clear_interaction_hint()
		return
	var prompt := "按 E 交互"
	var target_prompt = target.get("interaction_prompt")
	if target_prompt != null and str(target_prompt) != "":
		prompt = str(target_prompt)
	GameManager.show_interaction_hint(prompt)
