@tool
extends XROrigin3D

# --- KONFIGURACJA ŚCIEŻEK ---
const PATH_MOV_DIRECT  = "res://addons/godot-xr-tools/functions/movement_direct.tscn"
const PATH_MOV_TURN    = "res://addons/godot-xr-tools/functions/movement_turn.tscn"
const PATH_PLAYER_BODY = "res://addons/godot-xr-tools/player/player_body.tscn"
const PATH_HAND_L      = "res://addons/godot-xr-tools/hands/scenes/lowpoly/left_physics_hand_low.tscn"
const PATH_HAND_R      = "res://addons/godot-xr-tools/hands/scenes/lowpoly/right_physics_hand_low.tscn"
const PATH_POINTER     = "res://addons/godot-xr-tools/functions/function_pointer.tscn"

func _ready() -> void:
	if not get_node_or_null("XRCamera3D"):
		_build_player()

func _build_player() -> void:
	# ... (Tutaj bez zmian, budowanie struktury) ...
	var cam = XRCamera3D.new()
	cam.name = "XRCamera3D"
	cam.current = true
	cam.far = 500.0 
	add_child(cam)

	var left_ctrl = _create_controller("LeftHand", "left_hand")
	var right_ctrl = _create_controller("RightHand", "right_hand")

	_add_tool(PATH_HAND_L, left_ctrl)
	_add_tool(PATH_HAND_R, right_ctrl)
	
	# Wskaźniki
	_add_tool(PATH_POINTER, left_ctrl, func(n): n.y_offset = 0.05)
	_add_tool(PATH_POINTER, right_ctrl, func(n): n.y_offset = 0.05)

	# Ruch
	_add_tool(PATH_MOV_DIRECT, left_ctrl, func(n): 
		n.strafe = true
		n.max_speed = 3.0
	)
	_add_tool(PATH_MOV_TURN, right_ctrl)

	# Fizyka
	_add_tool(PATH_PLAYER_BODY, self)

# --- API DLA GAMEMANAGERA (NOWOŚĆ) ---

# Funkcja do zamrażania gracza przed teleportacją
func set_physics_enabled(enabled: bool) -> void:
	var body = find_child("PlayerBody", true, false)
	if body:
		# Wyłączamy/Włączamy przetwarzanie fizyki w PlayerBody
		body.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
		# Zerujemy prędkość przy wyłączaniu i włączaniu
		if "velocity" in body:
			body.velocity = Vector3.ZERO

# Funkcja do bezpiecznej teleportacji
func teleport_to(target_pos: Vector3, look_pos: Vector3) -> void:
	# 1. Przesuwamy Origin (Gracza)
	global_position = target_pos
	
	# 2. Obracamy
	var target_look = look_pos
	target_look.y = target_pos.y
	look_at(target_look, Vector3.UP)
	
	# 3. Synchronizujemy PlayerBody (żeby nie zostało w tyle)
	var body = find_child("PlayerBody", true, false)
	if body:
		body.global_position = target_pos
		body.velocity = Vector3.ZERO

# --- Funkcje pomocnicze budowania (bez zmian) ---
func _create_controller(name_str: String, tracker_str: String) -> XRController3D:
	var ctrl = XRController3D.new()
	ctrl.name = name_str
	ctrl.tracker = tracker_str
	ctrl.pose = "aim"
	add_child(ctrl)
	return ctrl

func _add_tool(path: String, parent: Node, config_func: Callable = Callable()) -> void:
	var scene = load(path)
	if scene:
		var instance = scene.instantiate()
		parent.add_child(instance)
		if config_func.is_valid():
			config_func.call(instance)
