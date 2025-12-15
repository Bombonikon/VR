extends Node3D
class_name DebugController

@export var move_speed := 10.0
@export var mouse_sensitivity := 0.003 # Zmniejszyłem wartość, bo używamy radianów (lepsza precyzja)

var _camera: Camera3D

func _ready():
	# Szukamy kamery wewnątrz gracza (musi być dzieckiem węzła gracza)
	_camera = get_node_or_null("Camera3D")
	if _camera == null:
		# Fallback: szukamy jakiejkolwiek kamery głębiej
		_camera = find_child("Camera3D", true, false)
	
	if _camera == null:
		push_error("DebugController: Brak Camera3D wewnątrz gracza!")
	
	# Przechwytujemy myszkę
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	# Obsługa myszki (rozdzielona na ciało i kamerę)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# 1. Obracamy CAŁYM GRACZEM lewo/prawo (oś Y)
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# 2. Obracamy TYLKO KAMERĄ góra/dół (oś X), jeśli istnieje
		if _camera:
			_camera.rotate_x(-event.relative.y * mouse_sensitivity)
			# Ograniczamy patrzenie góra/dół do 90 stopni (żeby nie zrobić fikołka)
			_camera.rotation.x = clamp(_camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

	# Wyjście z trybu przechwytywania (ESC)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Powrót do gry po kliknięciu myszką
	if event is InputEventMouseButton and event.pressed:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	# Ruch oparty na lokalnym układzie współrzędnych
	var input_dir := Vector3.ZERO

	if Input.is_key_pressed(KEY_W): input_dir -= transform.basis.z
	if Input.is_key_pressed(KEY_S): input_dir += transform.basis.z
	if Input.is_key_pressed(KEY_A): input_dir -= transform.basis.x
	if Input.is_key_pressed(KEY_D): input_dir += transform.basis.x
	
	# Latanie góra/dół (Q/E) - w przestrzeni globalnej (żeby nie latać na ukos jak się patrzy w dół)
	var vertical_dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_E): vertical_dir += Vector3.UP
	if Input.is_key_pressed(KEY_Q): vertical_dir -= Vector3.UP

	if input_dir != Vector3.ZERO:
		# Normalizujemy wektor ruchu, żeby ruch na ukos nie był szybszy
		# Używamy global_transform.basis.y do niwelowania pochylenia przy chodzeniu
		var move_vec = input_dir.normalized()
		global_position += move_vec * move_speed * delta
	
	if vertical_dir != Vector3.ZERO:
		global_position += vertical_dir * move_speed * delta
