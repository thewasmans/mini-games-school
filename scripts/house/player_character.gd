class_name PlayerCharacter
extends CharacterBody3D

@export var body: Node3D
@export var camera_pivot: Node3D
@export var spring_arm: SpringArm3D

@export_group("Réglages")
## Vitesse de marche de l'enfant, en mètres par seconde.
@export var walk_speed := 3.2
## Vitesse à laquelle l'enfant se tourne vers sa direction de marche.
@export var turn_speed := 10.0
## Rotation de la caméra par pixel glissé, en radians.
@export var camera_drag_speed := 0.006
## Inclinaison de la caméra la plus basse, en degrés.
@export var min_pitch := -60.0
## Inclinaison de la caméra la plus haute, en degrés.
@export var max_pitch := -15.0
## Distance entre la caméra et l'enfant, en mètres.
@export var camera_distance := 5.5
## Distance devant l'enfant où il interagit, en mètres.
@export var reach := 1.1

var move_input := Vector2.ZERO

var _gravity := 18.0
var _walk_time := 0.0


func _ready() -> void:
	body.add_child(HouseModels.kid())
	spring_arm.spring_length = camera_distance
	spring_arm.add_excluded_object(get_rid())


func _physics_process(delta: float) -> void:
	var input := move_input + _keyboard_input()
	input = input.limit_length(1.0)
	var yaw := camera_pivot.global_rotation.y
	var forward := Vector3(-sin(yaw), 0, -cos(yaw))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var direction := right * input.x - forward * input.y
	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - _gravity * delta
	move_and_slide()
	if direction.length() > 0.05:
		body.rotation.y = lerp_angle(body.rotation.y, atan2(-direction.x, -direction.z), minf(turn_speed * delta, 1.0))
		_walk_time += delta * 9.0
		body.position.y = absf(sin(_walk_time)) * 0.06
	else:
		body.position.y = lerpf(body.position.y, 0.0, minf(delta * 10.0, 1.0))


func rotate_camera(drag: Vector2) -> void:
	camera_pivot.rotation.y -= drag.x * camera_drag_speed
	spring_arm.rotation.x = clampf(spring_arm.rotation.x - drag.y * camera_drag_speed, deg_to_rad(min_pitch), deg_to_rad(max_pitch))


func facing() -> Vector3:
	return Vector3(-sin(body.rotation.y), 0, -cos(body.rotation.y))


func target_point() -> Vector3:
	return global_position + facing() * reach


func _keyboard_input() -> Vector2:
	var input := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		input.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		input.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		input.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		input.x += 1.0
	return input
