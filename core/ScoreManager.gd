extends Node

# Sygnał emitowany, gdy zmieni się liczba punktów (przydatne do aktualizacji UI)
signal score_updated(new_score: int)

# Zmienna przechowująca aktualne punkty w danej sesji
var current_score: int = 0

func _ready() -> void:
	# Resetujemy wynik na starcie gry
	reset_score()

# Funkcja dodająca punkty
func add_points(amount: int) -> void:
	current_score += amount
	print("SCORE: Dodano ", amount, " pkt. Razem: ", current_score)
	score_updated.emit(current_score)

# Funkcja pobierająca aktualny wynik
func get_score() -> int:
	return current_score

# Funkcja resetująca wynik (np. przy śmierci gracza lub nowej grze)
func reset_score() -> void:
	current_score = 0
	score_updated.emit(current_score)
