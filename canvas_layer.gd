extends CanvasLayer

@onready var fade_rect = $DeathFade


func fade_to_scene(scene_path):

	fade_rect.visible = true
	
	$TransitionSound.play(3.0)


	for i in range(40):
		fade_rect.modulate.a = i / 40.0
		await get_tree().create_timer(0.02).timeout

	get_tree().change_scene_to_file(scene_path)

	for i in range(40):
		fade_rect.modulate.a = 1.0 - (i / 40.0)
		await get_tree().create_timer(0.02).timeout

	fade_rect.visible = false
