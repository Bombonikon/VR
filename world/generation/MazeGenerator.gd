extends Object
class_name MazeGenerator

const WALL := 0
const FLOOR := 1

@export var room_count := 20
@export var room_min_size := 5
@export var room_max_size := 9
@export var extra_connection_chance := 0.4
@export var subroom_chance := 0.45

func generate(width: int, height: int) -> MazeData:
	var data := MazeData.new(width, height)
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
	if rooms.size() > 0:
		var start_room := rooms[0]
		var start_cell := Vector2i(
			start_room.position.x + start_room.size.x / 2,
			start_room.position.y + start_room.size.y / 2
		)
		data.set_cell(start_cell.x, start_cell.y, MazeData.START)
		
		# ZMIANA: Przekazujemy tablicę 'rooms', aby znaleźć najdalszy pokój
		var end_cell := _place_end_point(data, start_cell, rooms)
		print("GENERATOR: Start at ", start_cell, " | End at ", end_cell)
	else:
		push_error("GENERATOR ERROR: Could not place rooms!")

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

# ZMIANA: Nowa logika z użyciem Flood Fill (BFS) do szukania najdłuższej ścieżki
func _place_end_point(data: MazeData, start: Vector2i, rooms: Array[Rect2i]) -> Vector2i:
	# Mapa odległości: Vector2i -> int (liczba kroków)
	var distances := {} 
	var queue: Array[Vector2i] = [start]
	distances[start] = 0
	
	var directions = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
	
	# Algorytm BFS - rozlewamy się po korytarzach
	while not queue.is_empty():
		var current = queue.pop_front()
		var current_dist = distances[current]
		
		for dir in directions:
			var next = current + dir
			
			# Sprawdzenie granic mapy
			if next.x < 0 or next.y < 0 or next.x >= data.width or next.y >= data.height:
				continue

			# Jeśli to nie ściana i jeszcze tam nie byliśmy
			if data.get_cell(next.x, next.y) != WALL: 
				if not distances.has(next):
					distances[next] = current_dist + 1
					queue.append(next)

	# Wybieramy ten pokój z listy, do którego jest najdalej (najwięcej kroków)
	var best_cell := start
	var max_distance := -1

	for room in rooms:
		var center = Vector2i(
			room.position.x + room.size.x / 2,
			room.position.y + room.size.y / 2
		)
		
		# Sprawdzamy, czy algorytm dotarł do środka tego pokoju
		if distances.has(center):
			var dist = distances[center]
			if dist > max_distance:
				max_distance = dist
				best_cell = center

	# Zabezpieczenie na wypadek błędu
	if max_distance == -1:
		push_warning("Nie znaleziono ścieżki do żadnego pokoju! Ustawiam End w punkcie startu.")
		
	data.set_cell(best_cell.x, best_cell.y, MazeData.END)
	return best_cell
