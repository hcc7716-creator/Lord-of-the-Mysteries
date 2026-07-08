extends CharacterBody2D

@export var speed := 180.0

var nearby_interactables: Array[Node] = []

@onready var interaction_area: Area2D = $InteractionArea


func _ready() -> void:
	GameManager.register_player(self)
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)


func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO

	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_action_pressed("move_up") or Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_action_pressed("move_down") or Input.is_key_pressed(KEY_S):
		direction.y += 1.0

	velocity = direction.normalized() * speed
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_E:
				_try_interact()
			KEY_I:
				InventoryManager.toggle_inventory()
			KEY_J:
				GameManager.toggle_quest_panel()
			KEY_P:
				GameManager.toggle_pathway_panel()


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
