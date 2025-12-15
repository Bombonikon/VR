extends Node3D

# Definiujemy sygnał, który GameManager usłyszy
signal start_game_requested

@onready var start_button := $MenuUI/StartButton

func _ready():
	if start_button != null:
		start_button.pressed.connect(_on_start_pressed)
		print("MenuRoom: Button connected")
	else:
		push_error("MenuRoom: StartButton NOT FOUND in MenuUI")

	print("MenuRoom: Press ENTER to start game (DEBUG)")

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ENTER:
			print("MenuRoom: ENTER pressed")
			_request_start()

func _on_start_pressed():
	print("MenuRoom: Button pressed")
	_request_start()

func _request_start():
	# Emitujemy sygnał w górę do GameManagera
	start_game_requested.emit()
