class_name DemoManager
extends Manager

@export var player_box: RigidBody3D
@export var spawn_point_player: Node3D

func _ready() -> void:
	spawn_point_player.visible = false

func _physics_process(delta: float) -> void:
	var forward_dir = -player_box.global_transform.basis.z
	var input_dir = Input.get_axis("action_backward", "action_forward")
	var rotation_dir = Input.get_axis("action_turn_right", "action_turn_left")
	
	if input_dir != 0:
		player_box.linear_velocity = forward_dir * input_dir * game_data.linear_speed
	
	if rotation_dir != 0:
		player_box.rotate_y(rotation_dir * delta * game_data.rotation_speed)

func respawn_player():
	print("respawn")
	player_box.global_position = spawn_point_player.global_position
