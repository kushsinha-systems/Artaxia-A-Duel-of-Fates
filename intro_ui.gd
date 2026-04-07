extends Node

@onready var anim = $CanvasLayer/AnimationPlayer

func _ready():
	anim.play("intro_sequence")
