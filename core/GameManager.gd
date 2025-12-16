extends Node

# --- KONFIGURACJA ---
@export var use_vr: bool = false # Przełącznik VR / DEBUG

@export_group("Scenes")
@export var menu_scene: PackedScene
@export var dungeon_scene: PackedScene
@export var player_debug_scene: PackedScene
@export var player_vr_scene: PackedScene # Tu podepniesz gracza VR

var current_scene: Node
var player_instance: Node3D

func _ready() -> void:
	load_menu()

func load_menu() -> void:
	_cleanup()
	if menu_scene:
		current_scene = menu_scene.instantiate()
		_add_to_root(current_scene)
		if current_scene.has_signal("start_game_requested"):
			current_scene.start_game_requested.connect(start_game)

func start_game() -> void:
	print("GM: Starting game...")
	_cleanup()
	
	# 1. Ładowanie sceny lochu
	if dungeon_scene:
		current_scene = dungeon_scene.instantiate()
		_add_to_root(current_scene)
		
		# 2. Generowanie
		var dungeon_gen = current_scene.get_node_or_null("DungeonGenerator") # Nazwa węzła w scenie
		if dungeon_gen:
			dungeon_gen.generate_dungeon()
			
			# 3. Spawnowanie odpowiedniego gracza
			var scene_to_spawn = player_vr_scene if use_vr else player_debug_scene
			_spawn_player(scene_to_spawn, dungeon_gen.get_spawn_position(), dungeon_gen.get_spawn_forward())
		else:
			push_error("GM: Brak DungeonGenerator w scenie lochu!")

func _spawn_player(scene: PackedScene, pos: Vector3, forward: Vector3) -> void:
	if not scene: 
		push_warning("GM: Brak sceny gracza!")
		return
		
	player_instance = scene.instantiate()
	_add_to_root(player_instance)
	
	player_instance.global_position = pos
	# Ustawienie rotacji (look_at w płaszczyźnie poziomej)
	var target = pos + forward
	target.y = pos.y 
	player_instance.look_at(target, Vector3.UP)
	
	print("GM: Player spawned (VR: ", use_vr, ")")

func _cleanup() -> void:
	if current_scene: current_scene.queue_free()
	if player_instance: player_instance.queue_free()

func _add_to_root(node: Node) -> void:
	get_parent().get_node("SceneRoot").add_child(node)
