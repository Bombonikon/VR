extends Node3D
class_name DungeonGenerator

# --- KONFIGURACJA ---
@export_group("Settings")
@export var maze_width: int = 40
@export var maze_height: int = 40
@export var cell_size: float = 3.0 
@export var wall_height: float = 5.0
@export var room_count: int = 20

@export_group("Spawning")
@export var start_corridor_length: int = 6
@export var enemy_spawn_chance: float = 0.5
@export var coin_spawn_chance: float = 0.1
@export var key_min_distance: int = 15

# --- ZASOBY ---
@export_group("Assets")
@export var floor_scene: PackedScene
@export var wall_scene: PackedScene
@export var ceiling_scene: PackedScene 
@export var end_room_scene: PackedScene
@export var enemy_scene: PackedScene
@export var portal_scene: PackedScene
@export var pillar_scene: PackedScene
@export var coin_scene: PackedScene
@export var key_scene: PackedScene

# --- STAŁE ---
const WALL := 0
const FLOOR := 1
const START := 2
const END := 3
const ENEMY := 4
const PORTAL := 5
const COIN := 6
const KEY_ITEM := 7

# Zmienne pomocnicze
var _player_spawn_pos: Vector3 = Vector3.ZERO
var _player_look_dir: Vector3 = Vector3.FORWARD
var _start_corridor_dir: Vector2i
var _placed_pillars := {} 

# ==========================================================
# GŁÓWNA PĘTLA GENEROWANIA
# ==========================================================
func generate_dungeon() -> void:
	print("DUNGEN: Rozpoczynam generowanie lochu...")
	_clear_old_dungeon()
	
	var data := MazeData.new(maze_width, maze_height)
	randomize()

	# 1. Generowanie układu
	var rooms := _generate_rooms(data)
	_connect_rooms_logic(data, rooms)
	
	# 2. Wyznaczanie Startu
	var entry_info = _create_start_corridor(data)
	_calculate_spawn_point(entry_info.end_cell, entry_info.direction)
	
	# 3. Wyznaczanie Końca i obiektów
	_place_end_room_logic(data, entry_info.end_cell, rooms)
	_place_enemies_logic(data, rooms)
	_place_coins_logic(data, rooms)
	_place_key_logic(data, entry_info.end_cell)
	
	# 4. Budowanie świata 3D
	_build_3d_world(data)
	
	# 5. Przeniesienie gracza (jeśli gra już trwa)
	_teleport_player_to_start()
	
	print("DUNGEN: Generowanie zakończone.")

# --- GETTERY DLA GAMEMANAGERA (NAPRAWA BŁĘDU) ---
func get_spawn_position() -> Vector3:
	return _player_spawn_pos

func get_spawn_forward() -> Vector3:
	return _player_look_dir

# --- OBSŁUGA UKOŃCZENIA POZIOMU ---
func _on_level_completed() -> void:
	print("DUNGEN: Odebrano sygnał ukończenia poziomu! Resetowanie za 1 sekundę...")
	await get_tree().create_timer(1.0).timeout
	generate_dungeon()

# --- BUDOWANIE ŚWIATA 3D ---
func _build_3d_world(data: MazeData) -> void:
	_placed_pillars.clear()
	
	for y in range(data.height):
		for x in range(data.width):
			var cell = data.get_cell(x, y)
			var pos = Vector3(x * cell_size, 0, y * cell_size)
			
			if cell == END:
				if end_room_scene:
					var end_room = _spawn_obj(end_room_scene, pos)
					if ceiling_scene: _spawn_ceiling(pos)
					if end_room.has_signal("level_completed"):
						if not end_room.level_completed.is_connected(_on_level_completed):
							end_room.level_completed.connect(_on_level_completed)
			
			elif cell == PORTAL:
				if floor_scene: _spawn_obj(floor_scene, pos)
				if ceiling_scene: _spawn_ceiling(pos)
				_check_walls(data, x, y, pos)
				if portal_scene:
					var p = _spawn_obj(portal_scene, pos)
					if abs(_start_corridor_dir.x) > 0: p.rotation.y = PI / 2

			elif cell == FLOOR or cell == START or cell == ENEMY or cell == COIN or cell == KEY_ITEM:
				if floor_scene: _spawn_obj(floor_scene, pos)
				if ceiling_scene: _spawn_ceiling(pos) 
				_check_walls(data, x, y, pos)
				
				if cell == ENEMY and enemy_scene:
					_spawn_obj(enemy_scene, pos + Vector3(0, 1, 0))
				
				if cell == COIN and coin_scene:
					_spawn_obj(coin_scene, pos)
				
				if cell == KEY_ITEM and key_scene:
					_spawn_obj(key_scene, pos + Vector3(0, 1.0, 0))

# ==========================================================
# LOGIKA LOGICZNA (Siatka 2D)
# ==========================================================

func _place_key_logic(data: MazeData, start_point: Vector2i) -> void:
	var candidates = []
	for y in range(1, maze_height - 1):
		for x in range(1, maze_width - 1):
			var cell = data.get_cell(x, y)
			if cell == FLOOR or cell == COIN:
				var dist = abs(x - start_point.x) + abs(y - start_point.y)
				if dist > key_min_distance:
					candidates.append(Vector2i(x, y))
	
	if candidates.is_empty():
		for y in range(1, maze_height - 1):
			for x in range(1, maze_width - 1):
				if data.get_cell(x, y) == FLOOR: candidates.append(Vector2i(x, y))
	
	if not candidates.is_empty():
		var chosen = candidates.pick_random()
		data.set_cell(chosen.x, chosen.y, KEY_ITEM)
		print("Klucz ustawiony na: ", chosen)

func _generate_rooms(data: MazeData) -> Array[Rect2i]:
	var rooms: Array[Rect2i] = []
	var attempts := 0
	var margin = start_corridor_length + 2
	if maze_width < margin * 2 or maze_height < margin * 2: margin = 2
		
	while rooms.size() < room_count and attempts < (room_count * 10):
		attempts += 1
		var size = Vector2i(randi_range(5, 9), randi_range(5, 9))
		var pos = Vector2i(randi_range(margin, maze_width - size.x - margin - 1), randi_range(margin, maze_height - size.y - margin - 1))
		var new_room = Rect2i(pos, size)
		var overlaps = false
		for r in rooms: 
			if new_room.grow(1).intersects(r): 
				overlaps = true
				break
		if not overlaps: 
			rooms.append(new_room)
			_carve_rect(data, new_room, FLOOR)
	return rooms

func _connect_rooms_logic(data: MazeData, rooms: Array[Rect2i]) -> void:
	for i in range(rooms.size() - 1): 
		_tunnel_between(data, rooms[i], rooms[i+1])
	for i in range(rooms.size()): 
		if randf() < 0.4: 
			var other = rooms.pick_random()
			if other != rooms[i]: 
				_tunnel_between(data, rooms[i], other)

func _tunnel_between(data: MazeData, r1: Rect2i, r2: Rect2i) -> void:
	var c1 = r1.get_center()
	var c2 = r2.get_center()
	if randf() < 0.5: 
		_carve_h_tunnel(data, c1.x, c2.x, c1.y)
		_carve_v_tunnel(data, c1.y, c2.y, c2.x)
	else: 
		_carve_v_tunnel(data, c1.y, c2.y, c1.x)
		_carve_h_tunnel(data, c1.x, c2.x, c2.y)

func _create_start_corridor(data: MazeData) -> Dictionary:
	var best_cell := Vector2i(maze_width/2, maze_height/2)
	var min_dist_to_edge := 99999
	var chosen_direction := Vector2i(0, 0)
	
	for y in range(1, maze_height - 1):
		for x in range(1, maze_width - 1):
			if data.get_cell(x, y) == FLOOR:
				var d_left = x
				var d_right = maze_width - 1 - x
				var d_top = y
				var d_bottom = maze_height - 1 - y
				var local_min = min(d_left, min(d_right, min(d_top, d_bottom)))
				
				if local_min < min_dist_to_edge:
					min_dist_to_edge = local_min
					best_cell = Vector2i(x, y)
					if local_min == d_left: chosen_direction = Vector2i(-1, 0)
					elif local_min == d_right: chosen_direction = Vector2i(1, 0)
					elif local_min == d_top: chosen_direction = Vector2i(0, -1)
					elif local_min == d_bottom: chosen_direction = Vector2i(0, 1)
					
	_start_corridor_dir = chosen_direction
	var current = best_cell
	var last_valid = best_cell
	
	for i in range(start_corridor_length):
		var next_step = current + chosen_direction
		if next_step.x < 1 or next_step.y < 1 or next_step.x >= maze_width - 1 or next_step.y >= maze_height - 1: 
			break 
		current = next_step
		data.set_cell(current.x, current.y, START)
		last_valid = current
		
	data.set_cell(last_valid.x, last_valid.y, PORTAL)
	return {"end_cell": last_valid, "direction": chosen_direction}

func _place_end_room_logic(data: MazeData, start_node: Vector2i, rooms: Array[Rect2i]) -> void:
	var dists = {}
	var queue: Array[Vector2i] = [start_node]
	dists[start_node] = 0
	
	while not queue.is_empty():
		var curr = queue.pop_front()
		for d in [Vector2i(0,1), Vector2i(0,-1), Vector2i(1,0), Vector2i(-1,0)]:
			var next = curr + d
			if data.get_cell(next.x, next.y) != WALL and not dists.has(next): 
				dists[next] = dists[curr] + 1
				queue.append(next)
				
	var furthest_center = start_node
	var max_d = -1
	for r in rooms: 
		var c = r.get_center()
		if dists.has(c) and dists[c] > max_d: 
			max_d = dists[c]
			furthest_center = c
			
	data.set_cell(furthest_center.x, furthest_center.y, END)

func _place_enemies_logic(data: MazeData, rooms: Array[Rect2i]) -> void:
	for r in rooms:
		var c = r.get_center()
		if data.get_cell(c.x, c.y) == END: continue 
		if randf() < enemy_spawn_chance:
			var ex = randi_range(r.position.x+1, r.end.x-2)
			var ey = randi_range(r.position.y+1, r.end.y-2)
			if data.get_cell(ex, ey) == FLOOR: 
				data.set_cell(ex, ey, ENEMY)

func _place_coins_logic(data: MazeData, rooms: Array[Rect2i]) -> void:
	for y in range(1, maze_height - 1):
		for x in range(1, maze_width - 1):
			if data.get_cell(x, y) == FLOOR:
				if randf() < coin_spawn_chance:
					data.set_cell(x, y, COIN)

# ==========================================================
# POMOCNICZE FUNKCJE BUDOWANIA
# ==========================================================
func _spawn_ceiling(pos: Vector3) -> void:
	if not ceiling_scene: return
	var c = ceiling_scene.instantiate()
	add_child(c)
	c.position = pos + Vector3(0, wall_height, 0)

func _check_walls(data: MazeData, x: int, y: int, pos: Vector3) -> void:
	if not wall_scene: return
	var half = cell_size / 2.0
	if data.get_cell(x, y-1) == WALL: 
		_spawn_wall(pos, Vector3(0,0,-1))
		_try_spawn_pillar(pos + Vector3(-half, 0, -half)); _try_spawn_pillar(pos + Vector3(half, 0, -half))
	if data.get_cell(x, y+1) == WALL: 
		_spawn_wall(pos, Vector3(0,0,1))
		_try_spawn_pillar(pos + Vector3(-half, 0, half)); _try_spawn_pillar(pos + Vector3(half, 0, half))
	if data.get_cell(x-1, y) == WALL: 
		_spawn_wall(pos, Vector3(-1,0,0))
		_try_spawn_pillar(pos + Vector3(-half, 0, -half)); _try_spawn_pillar(pos + Vector3(-half, 0, half))
	if data.get_cell(x+1, y) == WALL: 
		_spawn_wall(pos, Vector3(1,0,0))
		_try_spawn_pillar(pos + Vector3(half, 0, -half)); _try_spawn_pillar(pos + Vector3(half, 0, half))

func _try_spawn_pillar(at_pos: Vector3) -> void:
	if not pillar_scene: return
	var key = Vector3(snapped(at_pos.x, 0.1), 0, snapped(at_pos.z, 0.1))
	if _placed_pillars.has(key): return
	var p = pillar_scene.instantiate()
	p.position = at_pos
	p.position.y = wall_height / 2.0 
	add_child(p)
	_placed_pillars[key] = true

func _spawn_wall(base_pos: Vector3, dir: Vector3) -> void:
	var w = wall_scene.instantiate()
	w.position = base_pos + (dir * (cell_size / 2.0))
	w.position.y = wall_height / 2.0 
	if abs(dir.x) > 0.1: w.rotation.y = PI / 2
	add_child(w)

func _spawn_obj(scene: PackedScene, pos: Vector3) -> Node3D:
	var obj = scene.instantiate()
	add_child(obj)
	obj.position = pos
	return obj

func _clear_old_dungeon() -> void: 
	for child in get_children(): 
		child.queue_free()

func _calculate_spawn_point(portal_cell: Vector2i, dir_outwards: Vector2i) -> void:
	var dir_inwards = -dir_outwards
	var spawn_cell = portal_cell + (dir_inwards * 2)
	_player_spawn_pos = Vector3(spawn_cell.x * cell_size, 2.0, spawn_cell.y * cell_size)
	_player_look_dir = Vector3(dir_inwards.x, 0, dir_inwards.y)

func _teleport_player_to_start() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = _player_spawn_pos
		player.rotation.y = atan2(_player_look_dir.x, _player_look_dir.z)
		if player.has_method("set_velocity"): player.velocity = Vector3.ZERO

func _carve_rect(data: MazeData, r: Rect2i, val: int) -> void:
	for y in range(r.position.y, r.end.y): 
		for x in range(r.position.x, r.end.x): 
			data.set_cell(x, y, val)

func _carve_h_tunnel(data: MazeData, x1, x2, y) -> void:
	for x in range(min(x1, x2), max(x1, x2) + 1): 
		data.set_cell(x, y, FLOOR)

func _carve_v_tunnel(data: MazeData, y1, y2, x) -> void:
	for y in range(min(y1, y2), max(y1, y2) + 1): 
		data.set_cell(x, y, FLOOR)
