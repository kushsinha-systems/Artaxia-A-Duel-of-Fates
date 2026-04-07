extends Node

@onready var player1 = $"../Player1"
@onready var player2 = $"../Player2"

var match_started = false

var match_over = false
var resolving = false
var dead_players = []

var match_manager

func _ready():
	match_started = false
	
	await get_tree().create_timer(5.6).timeout
	
	match_started = true
	
	match_manager = get_node("../MatchManager")

func player_died(player):

	if match_over:
		return

	if player not in dead_players:
		dead_players.append(player)

	# Start resolution only once
	if not resolving:
		resolving = true
		resolve_match()
	
	print("Death reported by ", player.name)


func resolve_match():

	await get_tree().process_frame

	match_over = true

	if dead_players.size() >= 2:
		end_match("DRAW!")

	elif dead_players[0] == player1:
		freeze_player(player2)
		end_match("Player 2 Wins!")

	else:
		freeze_player(player1)
		end_match("Player 1 Wins!")


func end_match(result):

	print(result)

	GameState.match_result = result

	await get_tree().create_timer(1.5).timeout

	Transition.fade_to_scene("res://GameOver.tscn")

func freeze_player(player):
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
