extends Object
class_name MazeGenerator   # <<< KLUCZOWE

const WALL := 0
const FLOOR := 1

@export var room_count := 20
@export var room_min_size := 5
@export var room_max_size := 9
@export var extra_connection_chance := 0.4
@export var subroom_chance := 0.45

func generate(width: int, height: int):
	var data := preload("res://world/generation/MazeData.gd").new(width, height)
	randomize()

	var rooms: Array[Rect2i] = []
	var max_attempts := room_count * 10
	var attempts := 0

	# -----------------------------
	# GŁÓWNE POKOJE
	# -----------------------------
	while rooms.size() < room_count and attempts < max_attempts:
		attempts += 1

		var rw := randi_range(room_min_size, room_max_size)
		var rh := randi_range(room_min_size, room_max_size)
		var rx := randi_range(2, width - rw - 3)
		var ry := randi_range(2, height - rh - 3)

		var new_room := Rect2i(rx, ry, rw, rh)
		var overlaps := false

		for r in rooms:
			if new_room.grow(1).intersects(r):
				overlaps = true
				break

		if overlaps:
			continue

		_carve_room(data, new_room)
		rooms.append(new_room)

	# -----------------------------
	# POŁĄCZENIA
	# -----------------------------
	for i in range(rooms.size() - 1):
		_connect_rooms(data, rooms[i], rooms[i + 1])

	for i in range(rooms.size()):
		if randf() < extra_connection_chance:
			var other: Rect2i = rooms.pick_random()
			if other != rooms[i]:
				_connect_rooms(data, rooms[i], other)

	# -----------------------------
	# START + END
	# -----------------------------
	var start_room := rooms[0]
	var start_cell := Vector2i(
		start_room.position.x + start_room.size.x / 2,
		start_room.position.y + start_room.size.y / 2
	)

	data.set_cell(start_cell.x, start_cell.y, MazeData.START)

	var end_cell := _place_end_point(data, start_cell)
	print("END placed at:", end_cell)

	return data

func _carve_room(data: MazeData, room: Rect2i) -> void:
	for y in range(room.position.y, room.position.y + room.size.y):
		for x in range(room.position.x, room.position.x + room.size.x):
			data.set_cell(x, y, FLOOR)

func _connect_rooms(data: MazeData, a: Rect2i, b: Rect2i) -> void:
	var ax := a.position.x + a.size.x / 2
	var ay := a.position.y + a.size.y / 2
	var bx := b.position.x + b.size.x / 2
	var by := b.position.y + b.size.y / 2

	if randf() < 0.5:
		_carve_h(data, ax, bx, ay)
		_carve_v(data, ay, by, bx)
	else:
		_carve_v(data, ay, by, ax)
		_carve_h(data, ax, bx, by)

func _carve_h(data: MazeData, x1: int, x2: int, y: int) -> void:
	for x in range(min(x1, x2), max(x1, x2) + 1):
		data.set_cell(x, y, FLOOR)

func _carve_v(data: MazeData, y1: int, y2: int, x: int) -> void:
	for y in range(min(y1, y2), max(y1, y2) + 1):
		data.set_cell(x, y, FLOOR)

func _place_end_point(data: MazeData, start: Vector2i) -> Vector2i:
	var best_cell := start
	var best_distance := -1

	for y in range(data.height):
		for x in range(data.width):
			if data.get_cell(x, y) == FLOOR:
				var dist: int = abs(x - start.x) + abs(y - start.y)
				if dist > best_distance:
					best_distance = dist
					best_cell = Vector2i(x, y)

	data.set_cell(best_cell.x, best_cell.y, MazeData.END)
	return best_cell
