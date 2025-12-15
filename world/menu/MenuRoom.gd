extends Node3D

@onready var start_button := $MenuUI/StartButton

func _ready():
	if start_button != null:
		start_button.pressed.connect(_on_start_pressed)
		print("MenuRoom READY – StartButton connected")
	else:
		push_error("StartButton NOT FOUND")

	print("Press ENTER to start game (DEBUG)")

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ENTER:
			print("ENTER pressed (DEBUG)")
			_start_game()

func _on_start_pressed():
	print("Start button PRESSED")
	_start_game()

func _start_game():
	var game_manager := get_tree().get_root().get_node_or_null("Main/GameManager")
	if game_manager == null:
		push_error("GameManager NOT FOUND")
		return

	game_manager.start_game()
