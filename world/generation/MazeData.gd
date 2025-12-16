extends Resource
class_name MazeData

const WALL := 0
const FLOOR := 1
const START := 2
const END := 3
const ENEMY := 4
const PORTAL := 5 # <--- NOWOŚĆ

var width: int
var height: int
var cells: Array = []

func _init(w: int, h: int):
	width = w
	height = h
	cells.resize(w * h)
	cells.fill(WALL)

func _index(x: int, y: int) -> int:
	return y * width + x

func set_cell(x: int, y: int, value: int) -> void:
	if x < 0 or y < 0 or x >= width or y >= height:
		return
	cells[_index(x, y)] = value

func get_cell(x: int, y: int) -> int:
	return cells[_index(x, y)]

func is_floor(x: int, y: int) -> bool:
	return get_cell(x, y) == FLOOR

func is_end(x: int, y: int) -> bool:
	return get_cell(x, y) == END
