extends Control

@onready var start_button = $TextureButton
@onready var music = $TitleMusic

func _ready():
	start_button.grab_focus()
	music.play()

func _on_texture_button_pressed() -> void:
	Transition.fade_to_scene("res://Arena.tscn")


func _on_texture_button_2_pressed() -> void:
	Transition.fade_to_scene("res://Credits.tscn")


func _on_button_pressed() -> void:
	Transition.fade_to_scene("res://Tutorial.tscn") # Replace with function body.
