extends Node

# --- KONFIGURACJA ---
var use_vr: bool = false 

@export_group("Scenes")
@export var menu_scene: PackedScene
@export var dungeon_scene: PackedScene
@export var player_debug_scene: PackedScene
@export var player_vr_scene: PackedScene

var current_scene: Node
var player_instance: Node3D

func _ready() -> void:
	if get_node_or_null("/root/Global"):
		use_vr = Global.use_vr_mode
	load_menu()

func load_menu() -> void:
	_cleanup()
	if menu_scene:
		current_scene = menu_scene.instantiate()
		_add_to_root(current_scene)
		if current_scene.has_signal("start_game_requested"):
			current_scene.start_game_requested.connect(start_game)

func start_game() -> void:
	print("GM: Startowanie gry... (VR: ", use_vr, ")")
	_cleanup()
	
	# 1. Spawnujemy gracza OD RAZU (ale zamrożonego)
	var scene_to_spawn = player_vr_scene if use_vr else player_debug_scene
	if not scene_to_spawn:
		push_error("GM: Brak sceny gracza!")
		return

	player_instance = scene_to_spawn.instantiate()
	_add_to_root(player_instance)
	
	# Czekamy klatkę na inicjalizację skryptów wewnątrz gracza
	await get_tree().process_frame
	
	# ZAMRAŻAMY GRACZA (Kluczowe dla naprawy błędu spadania)
	if player_instance.has_method("set_physics_enabled"):
		player_instance.set_physics_enabled(false)
		print("GM: Fizyka gracza wyłączona na czas ładowania.")
	
	# 2. Ładujemy i generujemy loch
	if dungeon_scene:
		current_scene = dungeon_scene.instantiate()
		_add_to_root(current_scene)
		
		var dungeon_gen = current_scene.get_node_or_null("DungeonGenerator")
		if dungeon_gen:
			dungeon_gen.generate_dungeon()
			
			# Czekamy aż loch fizycznie powstanie
			await get_tree().physics_frame
			await get_tree().physics_frame
			
			var spawn_pos = dungeon_gen.get_spawn_position()
			var spawn_dir = dungeon_gen.get_spawn_forward()
			
			# Lekkie podniesienie
			spawn_pos.y += 0.5
			var look_target = spawn_pos + spawn_dir
			
			print("GM: Teleportacja do: ", spawn_pos)
			
			# 3. Teleportujemy i Odmrażamy
			if player_instance.has_method("teleport_to"):
				player_instance.teleport_to(spawn_pos, look_target)
			else:
				# Fallback dla starego kodu (na wszelki wypadek)
				player_instance.global_position = spawn_pos
				player_instance.look_at(look_target, Vector3.UP)
			
			# Czekamy mikrosekundę, żeby teleport "siadł"
			await get_tree().process_frame
			
			if player_instance.has_method("set_physics_enabled"):
				player_instance.set_physics_enabled(true)
				print("GM: Fizyka gracza włączona. Gra startuje.")
				
		else:
			push_error("GM: Brak DungeonGenerator!")

func _cleanup() -> void:
	if current_scene: current_scene.queue_free()
	if player_instance: player_instance.queue_free()

func _add_to_root(node: Node) -> void:
	var root = get_tree().root.get_node_or_null("Main/SceneRoot")
	if not root: get_tree().root.add_child(node)
	else: root.add_child(node)
