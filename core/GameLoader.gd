extends Node

@export var gameplay_scene : PackedScene

func start_game():
	GameManager.set_state(GameManager.State.GENERATING)
	get_tree().change_scene_to_packed(gameplay_scene)
