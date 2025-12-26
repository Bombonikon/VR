extends Control

@export var main_game_scene: PackedScene

func _ready():
	# Ustawiamy focus na przyciski, by można było klikać
	$VBoxContainer/ButtonVR.pressed.connect(_on_vr_pressed)
	$VBoxContainer/ButtonDebug.pressed.connect(_on_debug_pressed)

func _on_vr_pressed():
	print("BOOT: Wybrano tryb VR")
	Global.use_vr_mode = true
	_initialize_xr()
	_load_game()

func _on_debug_pressed():
	print("BOOT: Wybrano tryb Debug")
	Global.use_vr_mode = false
	_load_game()

func _initialize_xr():
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("BOOT: OpenXR was already initialized")
		# FIX: Force Viewport to use XR even if interface was auto-started
		get_viewport().use_xr = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		
	elif xr_interface:
		print("BOOT: Initializing OpenXR...")
		if xr_interface.initialize():
			get_viewport().use_xr = true
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			print("BOOT: OpenXR initialized successfully")
		else:
			push_error("BOOT: Failed to initialize OpenXR!")
	else:
		push_error("BOOT: OpenXR interface not found!")

func _load_game():
	if main_game_scene:
		get_tree().change_scene_to_packed(main_game_scene)
	else:
		push_error("BOOT: Nie przypisano sceny głównej (main.tscn)!")
