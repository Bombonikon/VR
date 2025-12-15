extends Node

@export var delay := 1.0

func _ready():
	await get_tree().create_timer(delay).timeout
	get_node("/root/Main/GameManager").start_game()
