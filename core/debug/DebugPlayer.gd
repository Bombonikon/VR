extends CharacterBody3D
class_name DebugPlayer

@export_group("Settings")
@export var move_speed: float = 10.0
@export var mouse_sensitivity: float = 0.003
@export var fly_mode: bool = false # Latanie (bez grawitacji)

# Pobieramy grawitację z ustawień projektu (bezpieczna metoda)
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var _camera: Camera3D
var _rotation_x: float = 0.0

func _ready():
	# Szukamy kamery wewnątrz gracza
	_camera = get_node_or_null("Camera3D")
	if not _camera:
		# Fallback: szukamy głębiej lub tworzymy
		_camera = find_child("Camera3D", true, false)
		if not _camera:
			_camera = Camera3D.new()
			_camera.position.y = 1.7
			add_child(_camera)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Obrót postaci (Y) i kamery (X)
		rotate_y(-event.relative.x * mouse_sensitivity)
		_rotation_x -= event.relative.y * mouse_sensitivity
		_rotation_x = clamp(_rotation_x, deg_to_rad(-90), deg_to_rad(90))
		_camera.rotation.x = _rotation_x

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseButton and event.pressed and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# 1. Ręczna obsługa WASD (niezależna od Input Map)
	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S): input_dir.y += 1
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D): input_dir.x += 1
	
	# Normalizacja, żeby ruch na ukos nie był szybszy
	input_dir = input_dir.normalized()
	
	# Przeliczenie na kierunek w świecie gry (zgodnie z obrotem gracza)
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
	
	# 2. Grawitacja i Skok (lub Latanie)
	if fly_mode:
		# Tryb latania (Q/E)
		if Input.is_key_pressed(KEY_E): velocity.y = move_speed
		elif Input.is_key_pressed(KEY_Q): velocity.y = -move_speed
		else: velocity.y = move_toward(velocity.y, 0, move_speed)
	else:
		# Tryb chodzenia
		if not is_on_floor():
			velocity.y -= gravity * delta # Standardowa grawitacja
		
		# Skok (Spacja)
		if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
			velocity.y = 5.0

	move_and_slide()

func set_physics_enabled(enabled: bool) -> void:
	# Włączamy/Wyłączamy wbudowaną fizykę Godota
	set_physics_process(enabled)
	velocity = Vector3.ZERO
	
func teleport_to(target_pos: Vector3, look_pos: Vector3) -> void:
	global_position = target_pos
	look_at(look_pos, Vector3.UP)
	velocity = Vector3.ZERO
