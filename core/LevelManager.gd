extends Node

@export var maze_width: int = 40
@export var maze_height: int = 40
@export var cell_size: float = 3.0

@export var start_corridor_length: int = 6
@export var spawn_offset_from_end: int = 2
@export var spawn_height: float = 2.0

const WALL := 0
const FLOOR := 1

var _start_spawn_position: Vector3
var _start_spawn_forward: Vector3

func generate_level() -> void:
	var dungeon_root := get_parent().get_node("DungeonRoot")

	# Czyścimy poprzedni poziom, jeśli istnieje
	for c in dungeon_root.get_children():
		c.queue_free()

	# Tworzymy instancje generatora i buildera
	var generator = MazeGenerator.new() # Teraz używamy class_name
	var builder   = preload("res://world/generation/MazeBuilder.gd").new()

	print("LevelManager: Generating data...")
	var data: MazeData = generator.generate(maze_width, maze_height)

	# --- 1. Znajdź wejście do lochu ---
	var entry_cell := _find_border_floor_cell(data)

	# --- 2. Określ kierunek NA ZEWNĄTRZ ---
	var out_dir := _get_outward_direction(entry_cell, data)

	# --- 3. Wydrąż korytarz startowy ---
	# Zwraca koniec korytarza (gwarantowana podłoga)
	var corridor_end := _carve_start_corridor(data, entry_cell, out_dir)

	# --- 4. Oblicz punkt spawnu ---
	# Cofamy się o kilka pól od końca korytarza, żeby nie stać przy ścianie
	var spawn_cell := corridor_end - (out_dir * spawn_offset_from_end)
	
	# Zabezpieczenie: jeśli korytarz był za krótki, ustaw spawn na jego końcu
	if !_is_valid_cell(spawn_cell, data):
		spawn_cell = corridor_end

	_start_spawn_position = Vector3(
		spawn_cell.x * cell_size,
		spawn_height,
		spawn_cell.y * cell_size
	)

	# Gracz ma patrzeć W STRONĘ lochu (przeciwnie do kierunku korytarza)
	_start_spawn_forward = Vector3(-out_dir.x, 0, -out_dir.y).normalized()

	print("LevelManager: Building 3D world...")
	builder.build(data, dungeon_root, cell_size)

func get_start_spawn_position() -> Vector3:
	return _start_spawn_position

func get_start_spawn_forward() -> Vector3:
	return _start_spawn_forward

# ======================================================
# LOGIKA POMOCNICZA
# ======================================================

func _find_border_floor_cell(data: MazeData) -> Vector2i:
	# Szukamy podłogi, która sąsiaduje ze ścianą "na zewnątrz"
	for y in range(1, data.height - 1):
		for x in range(1, data.width - 1):
			if data.get_cell(x, y) != MazeData.FLOOR:
				continue
			
			# Sprawdzamy czy to brzeg "wewnętrzny"
			if data.get_cell(x + 1, y) == MazeData.WALL \
			or data.get_cell(x - 1, y) == MazeData.WALL \
			or data.get_cell(x, y + 1) == MazeData.WALL \
			or data.get_cell(x, y - 1) == MazeData.WALL:
				return Vector2i(x, y)

	return Vector2i(data.width / 2, data.height / 2) # Fallback

func _get_outward_direction(cell: Vector2i, data: MazeData) -> Vector2i:
	# Sprawdzamy, w którą stronę jest ściana, żeby tam kopać korytarz
	if data.get_cell(cell.x + 1, cell.y) == MazeData.WALL: return Vector2i(1, 0)
	if data.get_cell(cell.x - 1, cell.y) == MazeData.WALL: return Vector2i(-1, 0)
	if data.get_cell(cell.x, cell.y + 1) == MazeData.WALL: return Vector2i(0, 1)
	if data.get_cell(cell.x, cell.y - 1) == MazeData.WALL: return Vector2i(0, -1)
	return Vector2i(0, -1)

func _carve_start_corridor(data: MazeData, start: Vector2i, dir: Vector2i) -> Vector2i:
	var current_pos := start
	var last_valid_pos := start

	for i in range(start_corridor_length):
		var next_pos = current_pos + dir
		
		# Sprawdzenie granic mapy (Void Bug fix)
		if next_pos.x < 1 or next_pos.y < 1 or next_pos.x >= data.width - 1 or next_pos.y >= data.height - 1:
			print("LevelManager: Start corridor hit world edge at ", next_pos)
			break
		
		current_pos = next_pos
		data.set_cell(current_pos.x, current_pos.y, MazeData.FLOOR)
		last_valid_pos = current_pos

	return last_valid_pos

func _is_valid_cell(pos: Vector2i, data: MazeData) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < data.width and pos.y < data.height
