class_name InteractionSensor
extends Area2D

const DEFAULT_RANGE := 72.0

var player: CoopPlayer
var candidates: Array[Interactable] = []

func _ready() -> void:
	monitoring = true
	monitorable = false
	var collision_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = DEFAULT_RANGE
	collision_shape.shape = circle
	add_child(collision_shape)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func get_closest_interactable() -> Interactable:
	var closest: Interactable
	var closest_distance := INF
	for candidate in candidates:
		if not is_instance_valid(candidate) or not candidate.can_interact(player):
			continue
		var distance := global_position.distance_squared_to(candidate.get_interaction_position())
		if distance < closest_distance or (is_equal_approx(distance, closest_distance) and _comes_before(candidate, closest)):
			closest = candidate
			closest_distance = distance
	return closest

func _on_area_entered(area: Area2D) -> void:
	_register_candidate(area)

func _on_area_exited(area: Area2D) -> void:
	_unregister_candidate(area)

func _on_body_entered(body: Node2D) -> void:
	_register_candidate(body)

func _on_body_exited(body: Node2D) -> void:
	_unregister_candidate(body)

func _register_candidate(node: Node) -> void:
	var candidate := _find_interactable(node)
	if candidate == null:
		return
	var count := int(candidate.get_meta("interaction_sensor_count", 0))
	candidate.set_meta("interaction_sensor_count", count + 1)
	if not candidates.has(candidate):
		candidates.append(candidate)

func _unregister_candidate(node: Node) -> void:
	var candidate := _find_interactable(node)
	if candidate != null:
		var count := int(candidate.get_meta("interaction_sensor_count", 1)) - 1
		if count <= 0:
			candidate.remove_meta("interaction_sensor_count")
			candidates.erase(candidate)
		else:
			candidate.set_meta("interaction_sensor_count", count)

func _find_interactable(node: Node) -> Interactable:
	var current := node
	while current != null:
		if current is Interactable:
			return current as Interactable
		current = current.get_parent()
	return null

func _comes_before(candidate: Interactable, current: Interactable) -> bool:
	if current == null:
		return true
	return str(candidate.get_path()) < str(current.get_path())
