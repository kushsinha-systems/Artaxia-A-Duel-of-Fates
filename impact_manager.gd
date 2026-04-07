extends CanvasLayer

@onready var flash_rect = $ColorRect

func impact_flash():

	flash_rect.modulate.a = 1.0

	await get_tree().create_timer(0.04, true, false, true).timeout

	flash_rect.modulate.a = 0.0
