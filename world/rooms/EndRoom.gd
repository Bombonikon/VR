extends Node3D

@onready var trigger := $EndTrigger

# Zmieniamy podejście na Tablice (Array) - dzięki temu możesz
# przypisać wiele świateł i wiele pól energii w Inspektorze.
@export var energy_fields: Array[Node3D]
@export var lights: Array[Light3D]

var is_locked := true

# Kolory
var color_locked := Color(1.0, 0.0, 0.0) # Czerwony
var color_unlocked := Color(0.0, 1.0, 1.0) # Błękitny (Cyan)

func _ready():
	_update_visuals()
	
	if trigger:
		trigger.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Sprawdzamy, czy to gracz (zwykły lub VR)
	if body.name.contains("Player"):
		if is_locked:
			_try_unlock(body)
		else:
			_enter_portal()

func _try_unlock(player):
	# Tutaj logika klucza (na razie uproszczona)
	var has_key = false
	
	if player.has_method("has_key"):
		has_key = player.has_key()
	
	# --- TYMCZASOWY DEBUG (Odkomentuj, żeby testować bez klucza): ---
	# has_key = true 
	# -------------------------------------------------------------

	if has_key:
		print("END ROOM: Key used! Portal opening...")
		is_locked = false
		_update_visuals()
		if player.has_method("remove_key"):
			player.remove_key()
	else:
		print("END ROOM: Portal is locked. Find the key!")

func _enter_portal():
	print("END ROOM: Teleporting...")
	GameManager.start_game() 

func _update_visuals():
	var target_color = color_locked if is_locked else color_unlocked
	
	# 1. Zmień kolor wszystkich przypisanych świateł
	for light in lights:
		if light:
			light.light_color = target_color
	
	# 2. Zmień kolor wszystkich pól energii
	for field in energy_fields:
		if field and field.material:
			# Tworzymy unikalną kopię materiału, żeby nie psuć innych obiektów
			# (Robimy to tylko raz, ale tutaj dla uproszczenia przy każdej zmianie)
			var mat = field.material
			if not mat.resource_local_to_scene:
				mat = mat.duplicate()
				field.material = mat
			
			mat.albedo_color = target_color
			mat.albedo_color.a = 0.6 # Półprzezroczystość
			mat.emission = target_color
