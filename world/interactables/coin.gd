extends Area3D

@export_group("Settings")
@export var points_value: int = 10
@export var rotation_speed: float = 2.0
@export var bob_speed: float = 3.0
@export var bob_height: float = 0.2

# Zmienne pomocnicze do animacji
var _start_y: float
var _time_passed: float = 0.0

func _ready() -> void:
	# Zapamiętujemy pozycję startową Y, aby wiedzieć wokół czego lewitować
	_start_y = position.y
	
	# Losowy offset czasu, żeby wszystkie monety nie ruszały się identycznie
	_time_passed = randf_range(0.0, 10.0)

func _process(delta: float) -> void:
	_time_passed += delta
	
	# 1. Obrót wokół własnej osi Y
	rotate_y(rotation_speed * delta)
	
	# 2. Lewitacja (sinusoida) góra-dół
	var new_y = _start_y + (sin(_time_passed * bob_speed) * bob_height)
	position.y = new_y

# Ta funkcja musi być podłączona do sygnału body_entered w Area3D!
func _on_body_entered(body: Node3D) -> void:
	# Sprawdzamy czy to gracz. 
	# W VR Tools gracz to często CharacterBody3D o nazwie "PlayerBody" lub ma specyficzną grupę.
	# Najbezpieczniej sprawdzić czy ma metody ruchu lub jest w grupie "player".
	if body.is_in_group("player") or body.name == "PlayerBody" or body is CharacterBody3D:
		_collect_coin()

func _collect_coin() -> void:
	# Dodaj punkty przez Singleton
	if ScoreManager:
		ScoreManager.add_points(points_value)
	
	# Tutaj można dodać dźwięk (np. AudioStreamPlayer3D)
	# await $AudioStreamPlayer3D.finished # jeśli masz dźwięk
	
	# Usuń monetę ze świata
	queue_free()
