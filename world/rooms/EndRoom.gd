extends Node3D

@onready var trigger := $EndTrigger

func _ready():
	if trigger:
		trigger.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	print("END ROOM ENTERED by:", body.name)
