extends CanvasLayer

var player1
var player2

@export var p1_hp_bar : TextureProgressBar
@export var p1_posture_bar : TextureProgressBar
@export var p2_hp_bar : TextureProgressBar
@export var p2_posture_bar : TextureProgressBar

@export var anim1 : AnimatedSprite2D
@export var anim2 : AnimatedSprite2D

func _ready() -> void:	
	print("UI ready")
	print(anim1, anim2)
	print(player1, player2)
	
	player1 = get_node_or_null("../Player1")
	player2 = get_node_or_null("../Player2")
	
	anim1.play("Idle_2")
	anim2.play("Idle_1")
	

func _process(_delta):
	if player1 != null:
		p1_hp_bar.value = player1.hp
		p1_posture_bar.value = player1.posture
	
	if player2 != null:
		p2_hp_bar.value = player2.hp
		p2_posture_bar.value = player2.posture
