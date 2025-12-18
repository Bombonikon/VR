extends Node3D

# Sygnał wysyłany do generatora, gdy poziom zostaje ukończony
signal level_completed

func _ready() -> void:
	# Szukamy węzła Area3D o nazwie "KeyDetector", który dodałeś w edytorze
	var detector = $KeyDetector
	
	if detector:
		# Jeśli jeszcze nie połączono sygnału w edytorze, robimy to kodem
		if not detector.body_entered.is_connected(_on_key_entered):
			detector.body_entered.connect(_on_key_entered)
	else:
		printerr("BŁĄD: W scenie EndRoom brakuje węzła Area3D o nazwie 'KeyDetector'!")

func _on_key_entered(body: Node3D) -> void:
	# Sprawdzamy, czy obiekt to klucz (musi być w grupie "key")
	if body.is_in_group("key"):
		print("END ROOM: Klucz dostarczony! Poziom ukończony.")
		
		# Usuwamy klucz, żeby nie aktywował portalu wielokrotnie
		body.queue_free()
		
		# Emitujemy sygnał, który odbierze DungeonGenerator
		level_completed.emit()
