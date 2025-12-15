extends Node

@export var maze_width: int = 30
@export var maze_height: int = 30
@export var cell_size: float = 3.0

@export var start_corridor_length: int = 8
@export var spawn_offset_from_end: int = 2
@export var spawn_height: float = 2.0   # <<< 2 METRY W POWIETRZU

const WALL := 0
const FLOOR := 1

var _start_spawn_position: Vector3
var _start_spawn_forward: Vector3


func generate_level() -> void:
	var dungeon_root := get_parent().get_node("DungeonRoot")

	for c in dungeon_root.get_children():
		c.queue_free()

	var generator = preload("res://world/generation/MazeGenerator.gd").new()
	var builder   = preload("res://world/generation/MazeBuilder.gd").new()

	var data = generator.generate(maze_width, maze_height)

	# --- znajdź wejście do lochu ---
	var entry_cell := _find_border_floor_cell(data)

	# --- kierunek NA ZEWNĄTRZ lochu ---
	var out_dir := _get_outward_direction(entry_cell, data)

	# --- wydrąż korytarz startowy ---
	var corridor_end := _carve_start_corridor(data, entry_cell, out_dir)

	# --- spawn 2 bloki przed końcem ---
	var spawn_cell := corridor_end - out_dir * spawn_offset_from_end

	_start_spawn_position = Vector3(
		spawn_cell.x * cell_size,
		spawn_height,
		spawn_cell.y * cell_size
	)

	# >>> GRACZ MA PATRZEĆ DO LOCHU
	# czyli w PRZECIWNYM kierunku niż korytarz
	_start_spawn_forward = Vector3(-out_dir.x, 0, -out_dir.y).normalized()

	builder.build(data, dungeon_root, cell_size)


func get_start_spawn_position() -> Vector3:
	return _start_spawn_position


func get_start_spawn_forward() -> Vector3:
	return _start_spawn_forward


# ======================================================
# LOGIKA
# ======================================================

func _find_border_floor_cell(data) -> Vector2i:
	for y in range(1, data.height - 1):
		for x in range(1, data.width - 1):
			if data.get_cell(x, y) != FLOOR:
				continue

			if data.get_cell(x + 1, y) == WALL \
			or data.get_cell(x - 1, y) == WALL \
			or data.get_cell(x, y + 1) == WALL \
			or data.get_cell(x, y - 1) == WALL:
				return Vector2i(x, y)

	return Vector2i(data.width / 2, data.height / 2)


func _get_outward_direction(cell: Vector2i, data) -> Vector2i:
	if data.get_cell(cell.x + 1, cell.y) == WALL:
		return Vector2i(1, 0)
	if data.get_cell(cell.x - 1, cell.y) == WALL:
		return Vector2i(-1, 0)
	if data.get_cell(cell.x, cell.y + 1) == WALL:
		return Vector2i(0, 1)
	if data.get_cell(cell.x, cell.y - 1) == WALL:
		return Vector2i(0, -1)

	return Vector2i(0, -1)


func _carve_start_corridor(data, start: Vector2i, dir: Vector2i) -> Vector2i:
	var pos := start
	for i in range(start_corridor_length):
		pos += dir
		if pos.x < 1 or pos.y < 1 or pos.x >= data.width - 1 or pos.y >= data.height - 1:
			break
		data.set_cell(pos.x, pos.y, FLOOR)
	return pos
