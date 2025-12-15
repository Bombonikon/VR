extends Node

@export var menu_room_scene: PackedScene
@export var dungeon_scene: PackedScene
@export var player_scene: PackedScene

var current_scene: Node
var player_instance: Node3D

func _ready() -> void:
	load_menu()

func load_menu() -> void:
	_clear_scene()
	_clear_player() # Czyścimy gracza, by nie został z poprzedniej sesji

	if menu_room_scene == null:
		push_error("MenuRoom scene not assigned")
		return

	current_scene = menu_room_scene.instantiate()
	get_parent().get_node("SceneRoot").add_child(current_scene)
	
	# --- POPRAWKA: Podłączamy sygnał z MenuRoom ---
	if current_scene.has_signal("start_game_requested"):
		current_scene.start_game_requested.connect(start_game)
	else:
		# Ostrzeżenie, jeśli zapomnisz o sygnale w MenuRoom.gd
		push_warning("MenuRoom does not have 'start_game_requested' signal!")


func start_game() -> void:
	print("GameManager: Starting game...")
	_clear_scene()
	# Nie usuwamy gracza tutaj, bo zaraz go stworzymy
	_clear_player()

	if dungeon_scene == null:
		push_error("DungeonScene scene not assigned")
		return

	# 1. Instancjujemy Loch
	current_scene = dungeon_scene.instantiate()
	get_parent().get_node("SceneRoot").add_child(current_scene)

	# 2. Generujemy poziom
	var level_manager := current_scene.get_node_or_null("LevelManager")
	if level_manager == null:
		push_error("LevelManager not found in DungeonScene")
		return

	level_manager.generate_level()

	# 3. Pobieramy dane spawnu
	var spawn_position: Vector3 = level_manager.get_start_spawn_position()
	var spawn_forward: Vector3  = level_manager.get_start_spawn_forward()

	# 4. Spawnujemy gracza
	_spawn_player(spawn_position, spawn_forward)


func _spawn_player(position: Vector3, forward: Vector3) -> void:
	if player_scene == null:
		push_error("Player scene not assigned")
		return

	player_instance = player_scene.instantiate()
	get_parent().get_node("SceneRoot").add_child(player_instance)

	player_instance.global_position = position
	player_instance.look_at(position + forward, Vector3.UP)


func _clear_scene() -> void:
	if current_scene:
		current_scene.queue_free()
		current_scene = null

func _clear_player() -> void:
	if player_instance:
		player_instance.queue_free()
		player_instance = null
