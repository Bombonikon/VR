extends Object

# ===============================
# PRELOADY (Tylko sceny, nie skrypty z class_name!)
# ===============================

const FloorScene = preload("res://world/tiles/Floor.tscn")
const WallScene = preload("res://world/tiles/Wall.tscn")
const EndRoomScene = preload("res://world/rooms/EndRoom.tscn")

const WALL_THICKNESS := 0.3
const WALL_OFFSET := WALL_THICKNESS / 2.0

# ===============================
# PUBLICZNE API
# ===============================

func build(data: MazeData, parent: Node3D, cell_size: float) -> void:
	print("BUILDER: Starting build process...")
	for y in range(data.height):
		for x in range(data.width):
			var cell := data.get_cell(x, y)

			# --- END ROOM ---
			if cell == MazeData.END:
				_spawn_end_room(parent, x, y, cell_size)
				continue

			# --- NORMALNE TILE (FLOOR ORAZ START) ---
			if cell == MazeData.FLOOR or cell == MazeData.START:
				_spawn_floor(parent, x, y, cell_size)
				_spawn_walls_around(parent, data, x, y, cell_size)
	
	print("BUILDER: Build complete.")

# ===============================
# FLOOR
# ===============================

func _spawn_floor(parent: Node3D, x: int, y: int, size: float) -> void:
	var floor_inst := FloorScene.instantiate()
	floor_inst.position = Vector3(
		x * size,
		0,
		y * size
	)
	parent.add_child(floor_inst)

# ===============================
# WALLS
# ===============================

func _spawn_walls_around(parent: Node3D, data: MazeData, x: int, y: int, size: float) -> void:
	# północ
	if _is_wall(data, x, y - 1):
		_spawn_wall(parent, x, y, Vector3(0, 0, -1), size)

	# południe
	if _is_wall(data, x, y + 1):
		_spawn_wall(parent, x, y, Vector3(0, 0, 1), size)

	# zachód
	if _is_wall(data, x - 1, y):
		_spawn_wall(parent, x, y, Vector3(-1, 0, 0), size)

	# wschód
	if _is_wall(data, x + 1, y):
		_spawn_wall(parent, x, y, Vector3(1, 0, 0), size)

func _spawn_wall(parent: Node3D, x: int, y: int, dir: Vector3, size: float) -> void:
	var wall := WallScene.instantiate()

	var base_pos := Vector3(x * size, 0, y * size)
	var offset := dir * (size / 2.0)

	wall.position = base_pos + offset
	wall.position.y = 1.5

	# obrót ściany
	if abs(dir.x) > 0:
		wall.rotation.y = PI / 2

	parent.add_child(wall)

# ===============================
# END ROOM
# ===============================

func _spawn_end_room(parent: Node3D, x: int, y: int, size: float) -> void:
	var room := EndRoomScene.instantiate()
	room.position = Vector3(
		x * size,
		0,
		y * size
	)
	parent.add_child(room)

# ===============================
# UTILS
# ===============================

func _is_wall(data: MazeData, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= data.width or y >= data.height:
		return true
	# Traktujemy wszystko co nie jest podłogą, startem lub końcem jako ścianę
	var cell = data.get_cell(x, y)
	return cell == MazeData.WALL
