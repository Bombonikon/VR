extends Node

var xr_interface : XRInterface

func _ready():
	# Szukamy interfejsu OpenXR
	xr_interface = XRServer.find_interface("OpenXR")
	
	if xr_interface and xr_interface.is_initialized():
		print("VR Zainicjalizowane pomyślnie")
		
		# Przełączamy główny viewport na tryb XR (wyjście na gogle)
		get_viewport().use_xr = true
		
		# Wyłączamy V-Sync dla lepszej wydajności i mniejszego opóźnienia
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	else:
		print("OpenXR nie znaleziony. Upewnij się, że gogle są podłączone.")
