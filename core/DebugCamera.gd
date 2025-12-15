extends Node3D

@export var move_speed := 10.0
@export var mouse_sensitivity := 0.2

var yaw := 0.0
var pitch := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -80, 80)
		rotation_degrees = Vector3(pitch, yaw, 0)

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta):
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): dir -= transform.basis.z
	if Input.is_key_pressed(KEY_S): dir += transform.basis.z
	if Input.is_key_pressed(KEY_A): dir -= transform.basis.x
	if Input.is_key_pressed(KEY_D): dir += transform.basis.x
	if Input.is_key_pressed(KEY_E): dir += transform.basis.y
	if Input.is_key_pressed(KEY_Q): dir -= transform.basis.y
	if dir != Vector3.ZERO:
		global_position += dir.normalized() * move_speed * delta
