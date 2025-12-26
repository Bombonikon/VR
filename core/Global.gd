extends Node

# Domyślnie false (tryb PC), zmienimy to w Menu startowym
var use_vr_mode: bool = false

func _ready():
	# Upewnij się, że gra nie pauzuje się sama przy zmianie trybu
	process_mode = Node.PROCESS_MODE_ALWAYS
