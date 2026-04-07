extends Control

@onready var start_button = $TitleButton
@onready var music = $TitleMusic

func _ready():
	start_button.grab_focus()
	music.play()

func _on_title_button_pressed() -> void:
	Transition.fade_to_scene("res://TitleScreen.tscn")
