extends Node

@export var menu_room_scene: PackedScene
@export var dungeon_scene: PackedScene
@export var player_scene: PackedScene

var current_scene: Node3D
var player_instance: Node3D


func _ready() -> void:
	load_menu()


func load_menu() -> void:
	_clear_scene()

	if menu_room_scene == null:
		push_error("MenuRoom scene not assigned")
		return

	current_scene = menu_room_scene.instantiate()
	get_parent().get_node("SceneRoot").add_child(current_scene)


func start_game() -> void:
	_clear_scene()

	if dungeon_scene == null:
		push_error("DungeonScene scene not assigned")
		return

	current_scene = dungeon_scene.instantiate()
	get_parent().get_node("SceneRoot").add_child(current_scene)

	var level_manager := current_scene.get_node_or_null("LevelManager")
	if level_manager == null:
		push_error("LevelManager not found in DungeonScene")
		return

	level_manager.generate_level()

	var spawn_position: Vector3 = level_manager.get_start_spawn_position()
	var spawn_forward: Vector3  = level_manager.get_start_spawn_forward()

	_spawn_player(spawn_position, spawn_forward)


func _spawn_player(position: Vector3, forward: Vector3) -> void:
	if player_scene == null:
		push_error("Player scene not assigned")
		return

	if player_instance == null:
		player_instance = player_scene.instantiate()
		get_parent().get_node("SceneRoot").add_child(player_instance)

	player_instance.global_position = position
	player_instance.look_at(position + forward, Vector3.UP)


func _clear_scene() -> void:
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
