extends Control

@onready var result_label = $ResultLabel
@onready var victory_sprite = $VictorySprite
@onready var replay_button = $ReplayButton

func _ready():
	if GameState.match_result == "":
		result_label.text = "Draw"
	else:
		result_label.text = GameState.match_result
	
	replay_button.grab_focus()
	
	print(GameState.match_result)

	if GameState.match_result == "Player 1 Wins!":
		victory_sprite.play("p1_victory")
	elif GameState.match_result == "Player 2 Wins!":
		victory_sprite.play("p2_victory")

func _on_replay_button_pressed() -> void:
	Transition.fade_to_scene("res://Arena.tscn")

func _on_title_button_pressed() -> void:
	Transition.fade_to_scene("res://TitleScreen.tscn")
