extends Control


func _on_title_button_pressed() -> void:
	MusicManager.stop_music()
	Transition.fade_to_scene("res://TitleScreen.tscn")
