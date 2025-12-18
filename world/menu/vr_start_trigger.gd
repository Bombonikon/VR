extends Area3D

# Ten skrypt podpinamy pod Area3D, które dodaliśmy do przycisku.

func _ready():
	# Podłączamy sygnał wykrycia wejścia obiektu do strefy
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	print("Coś dotknęło przycisku: ", body.name)
	
	# Sprawdzamy, czy obiekt to ręka gracza VR (z XR Tools)
	# Fizyczne ręce w XR Tools nazywają się zazwyczaj "LeftPhysicsHand" lub "RightPhysicsHand"
	# Ewentualnie mogą być w grupie "player_hands"
	if "Hand" in body.name or body.is_in_group("player_hands"):
		print("Ręka wykryta! Uruchamiam grę.")
		trigger_game_start()

func trigger_game_start():
	# Szukamy GameManagera w głównej scenie
	var game_manager = get_tree().root.get_node_or_null("Main/GameManager")
	
	if game_manager:
		# Uruchamiamy funkcję startu, którą napisaliśmy wcześniej
		game_manager.on_vr_button_pressed()
		
		# Opcjonalnie: Dźwięk kliknięcia (jeśli masz AudioStreamPlayer3D w przycisku)
		# var audio = get_parent().get_node_or_null("ClickSound")
		# if audio: audio.play()
	else:
		print("Błąd: Nie znaleziono Main/GameManager! Sprawdź strukturę sceny.")
