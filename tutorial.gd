extends Control

@export var player: Node

var blue_frames := preload("res://Blue_Warrior.tres")
var red_frames := preload("res://Red_Warrior.tres")

var current_player := "blue"

var tutorial_music := preload("res://Assets/Sound/Epic Electronic & Cinematic (Music For Videos) - Reloaded by Savfk - BreakingCopyright — Royalty Free Music (2).mp3")


func _ready() -> void:
	if player == null:
		return
	
	MusicManager.play_music(tutorial_music)
	_apply_player_side()


func _input(_event) -> void:
	if player == null:
		return

	# If the body is busy, do not let control swap mid-action.
	if _is_player_busy():
		return

	# Blue controls
	if Input.is_action_just_pressed("move_left") \
	or Input.is_action_just_pressed("move_right") \
	or Input.is_action_just_pressed("jump") \
	or Input.is_action_just_pressed("attack") \
	or Input.is_action_just_pressed("block") \
	or Input.is_action_just_pressed("dash"):
		current_player = "blue"
		_apply_player_side()

	# Red controls
	if Input.is_action_just_pressed("p2_move_left") \
	or Input.is_action_just_pressed("p2_move_right") \
	or Input.is_action_just_pressed("p2_jump") \
	or Input.is_action_just_pressed("p2_attack") \
	or Input.is_action_just_pressed("p2_block") \
	or Input.is_action_just_pressed("p2_dash"):
		current_player = "red"
		_apply_player_side()


func _is_player_busy() -> bool:
	if player == null:
		return false

	return player.current_state in [
		player.state.Attack,
		player.state.AttackRecovery,
		player.state.Block,
		player.state.Parry,
		player.state.ParryRecovery,
		player.state.Dash,
		player.state.DashRecovery,
		player.state.JumpAttack,
		player.state.JumpAttackRecovery,
		player.state.HitStun,
		player.state.PostureBroken
	]


func _apply_player_side() -> void:
	if player == null:
		return

	if current_player == "blue":
		player.input_prefix = ""
		player.anim.sprite_frames = blue_frames
	else:
		player.input_prefix = "p2_"
		player.anim.sprite_frames = red_frames


func _on_title_button_pressed() -> void:
	MusicManager.stop_music()
	Transition.fade_to_scene("res://TitleScreen.tscn")


func _on_texture_button_pressed() -> void:
	Transition.fade_to_scene("res://Tuts2.tscn")
