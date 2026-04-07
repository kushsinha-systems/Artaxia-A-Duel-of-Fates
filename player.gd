extends CharacterBody2D

@export var input_prefix := ""

var gravity = 2800

enum state {
	Idle,
	Air,
	JumpAttack,
	JumpAttackRecovery,
	Death,
	Attack, 
	Block,
	Parry,
	AttackRecovery,
	ParryRecovery,
	HitStun,
	PostureBroken,
	Dash,
	DashRecovery,
}

var posture_recovery_delay := 0.0
const POSTURE_RECOVERY_WAIT := 1.2

var current_state = state.Idle
var previous_state = state.Idle

var state_timer : float = 0.0

var parry_elapsed : float = 0.0
var perfect_parry_window = 0.05

var jump_counter : int = 0

var dash_direction
var dash_speed

var hp : int = 100
var posture : int = 0

var facing := 1

var hit_direction: int = 0

var dash_cooldown: float = 0.0
var dash_flag:= true

var is_dead := false
var match_manager = null

var death_floor_buffer = 1.8

var dash_attack := false

@onready var anim = $AnimatedSprite2D

func can_control():
	if match_manager == null:
		return true
	return match_manager.match_started and not is_dead

var attack_buffered := false
var attack_buffer_expire_time := 0
const ATTACK_BUFFER_TIME := 0.25

var combo_step := 0
var combo_timer := 0.0
const COMBO_WINDOW := 1.0

var can_be_comboed := false

var sword_sounds = [
	preload("res://Assets/Sound/Effects/Sworddef/sword-breaking-sound-effect-393840.mp3"),
	preload("res://Assets/Sound/Effects/Sworddef/sword-deflection-the-ballad-of-the-blades-255962.mp3"),
	preload("res://Assets/Sound/Effects/Sworddef/swordclash-96506.mp3")
	]
	
var sword_hit = [
	preload("res://Assets/Sound/Effects/Swordhit/violent-sword-slice-2-393841.mp3"),
	preload("res://Assets/Sound/Effects/Swordhit/violent-sword-slice-393839.mp3")
	]

func play_random_sword_deflect_sound():
	play_sound_from_array(sword_sounds)

func play_random_sword_hit_sound():
	play_sound_from_array(sword_hit)

enum AttackType {
	NONE,
	NORMAL,
	FOLLOWUP,
	DASH,
	JUMP
}

var last_attack_type : AttackType = AttackType.NONE

var arena_music
var end_sound

func fade_out_music(player: AudioStreamPlayer, duration: float):
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -40, duration)
	tween.tween_callback(player.stop)

var sfx_players = []

func play_sound_from_array(array):
	for player in sfx_players:
		if not player.playing:
			player.stream = array.pick_random()
			player.pitch_scale = randf_range(0.9, 1.1)
			player.play()
			return

func _ready() -> void:
	
	arena_music = get_parent().get_node("ArenaMusic")
	end_sound = get_parent().get_node("EndSound")
	
	
	sfx_players = [$SFXPlayer1, $SFXPlayer2]
	
	$Hitbox.owner_character = self
	anim.animation_finished.connect(_on_animation_finished)
	
	match_manager = get_parent().get_node("MatchManager")
	
	if input_prefix == "p2_":
		anim.sprite_frames = preload("res://Red_Warrior.tres")
	else:
		anim.sprite_frames = preload("res://Blue_Warrior.tres")
	
	if input_prefix == "p2_":
		facing = 1
		set_direction(-1)
	else:
		facing = 1
		set_direction(1)

func _physics_process(delta: float) -> void:	
	
	apply_gravity(delta)
	
	if is_dead:
		death_floor_buffer -= delta
		if is_on_floor():
			death_floor_buffer -= delta
			if death_floor_buffer <= 0:
				velocity.x = move_toward(velocity.x, 0, 1200 * delta)
	else:
		
		if attack_buffered and Time.get_ticks_msec() > attack_buffer_expire_time:
			attack_buffered = false
		
		
		if Input.is_action_just_pressed(input_prefix + "attack") and current_state in [state.Attack, state.AttackRecovery]:
			attack_buffered = true
			attack_buffer_expire_time = Time.get_ticks_msec() + int(ATTACK_BUFFER_TIME * 1000)
				
		if combo_timer > 0:
				combo_timer -= delta
		
		if current_state not in [state.Attack, state.AttackRecovery]:
			combo_step = 0
			last_attack_type = AttackType.NONE
		
		next_dash(delta)
		
		match current_state:
			state.Idle:
				idle_state()
			state.Air:
				air_state(delta)
			state.JumpAttack:
				jump_attack_state()
			state.JumpAttackRecovery:
				jump_attack_recovery_state()
			state.Death:
				death_state()
			state.Attack:
				attack_state()
			state.Parry:
				parry_state(delta)
			state.Block:
				block_state()
			state.AttackRecovery:
				attack_recovery_state()
			state.ParryRecovery:
				parry_recovery_state()
			state.HitStun:
				hit_stun(delta)
			state.PostureBroken:
				posture_broken(delta)
			state.Dash:
				dash_state(delta)
			state.DashRecovery:
				dash_recovery_state(delta)

		
		previous_state = current_state
	
	recover_posture(delta)
	
	move_and_slide()

func trigger_death(direction):
	is_dead = true
	velocity = Vector2(-direction * 600, -850)
	
	$Hitbox/CollisionShape2D.disabled = true
	$Hurtbox/CollisionShape2D.disabled = true
	
	anim.play("Death")

	if match_manager != null:
		match_manager.player_died(self)
	
	current_state = state.Death

func death_state():
	pass

func hitstop(duration: float):
	Engine.time_scale = 0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1

func enter_hit_stun(direction: int, knockback: float = 250.0, stun_time: float = 0.33, allow_combo := false):
	state_timer = stun_time
	current_state = state.HitStun
	hit_direction = direction
	velocity.x = direction * knockback
	
	can_be_comboed = allow_combo
	
	set_direction(hit_direction)
	anim.play("Hurt")

func hit_stun(delta):
	state_timer -= delta
	velocity.x = move_toward(velocity.x, 0, 80 * delta)
	
	if state_timer <= 0:
		current_state = state.Idle
		velocity.x = 0
		can_be_comboed = false
	
func enter_posture_broken(time: float, attacker_facing: int):
	state_timer = time
	current_state = state.PostureBroken
	
	anim.play("Posture_Broken")
	
	$Hitbox/CollisionShape2D.disabled = true
	
	velocity.x = -attacker_facing * 700

func posture_broken(delta):
	state_timer -= delta
	
	velocity.x = move_toward(velocity.x, 0, 1200 * delta)

	if state_timer <= 0:
		posture = 0
		current_state = state.Idle

func apply_gravity(delta):
	if !is_on_floor():
		velocity.y += gravity * delta

func handle_movement():
	if not can_control():
		return
	var dir := 0
	if Input.is_action_pressed(input_prefix + "move_left"):
		dir -= 1
	if Input.is_action_pressed(input_prefix + "move_right"):
		dir += 1
	if is_on_floor():
		velocity.x = dir * 700
		if dir != 0:
			set_direction(dir)

func set_direction(dir):
	if dir > 0:
		if facing != 1:
			facing = 1
			scale.x = -1
	elif dir < 0:
		if facing != -1:
			facing = -1
			scale.x = -1

func slow_move():
	if not can_control():
		return
	var dir := 0
	if Input.is_action_pressed(input_prefix + "move_left"):
		dir -= 1
	if Input.is_action_pressed(input_prefix + "move_right"):
		dir += 1
	velocity.x = dir * 50

func idle_state():
	handle_movement()
	
	if anim.animation == "Landing" and anim.is_playing():
		return
	
	if abs(velocity.x) > 0:
		if anim.animation != "Run":
			anim.play("Run")
	else:
		if anim.animation != "Idle":
			anim.play("Idle")
		
	if not can_control():
		return
	
	if Input.is_action_just_pressed(input_prefix + "jump"):
		if is_on_floor():
			jump()

	if Input.is_action_just_pressed(input_prefix + "jump"):
		if is_on_floor() == false:
			double_jump()

	if Input.is_action_just_pressed(input_prefix + "attack"):
		enter_attack()

	if Input.is_action_just_pressed(input_prefix + "dash"):
		enter_dash()

	if Input.is_action_just_pressed(input_prefix + "block"):
		enter_parry()
		return
		
func jump():
	var dir := 0
	if Input.is_action_pressed(input_prefix + "move_left"):
		dir -= 1
	if Input.is_action_pressed(input_prefix + "move_right"):
		dir += 1
	velocity.x = dir * 500
	velocity.y = -1600
	jump_counter = 1
	current_state = state.Air
	anim.play("Single_Jump")
	set_direction(dir)

func double_jump():
	if jump_counter == 1:
		var dir := 0
		if Input.is_action_pressed(input_prefix + "move_left"):
			dir -= 1
		if Input.is_action_pressed(input_prefix + "move_right"):
			dir += 1
			
		velocity.x = dir * 450
		velocity.y = -1250
		jump_counter = 2
		anim.play("Double_Jump")
		
		if dir != 0:
			set_direction(dir)

func air_state(_delta):

	handle_movement()

	if Input.is_action_just_pressed(input_prefix + "jump"):
		double_jump()
	
	if Input.is_action_just_pressed(input_prefix + "dash"):
		enter_dash()
	
	if Input.is_action_just_pressed(input_prefix + "attack"):
		enter_jump_attack()

	if current_state == state.Air and velocity.y > 0:
		if anim.animation != "Falling":
			anim.play("Falling")

	if is_on_floor():
		enter_landing()

func enter_jump_attack():
	current_state = state.JumpAttack
	
	velocity.x = 0
	velocity.y = 2000
	
	anim.play("Jump_Attack_prep")

func start_active_jump_attack():
	anim.play("Jump_Attack")
	$AnimationPlayer.play("Attack")
	$Hitbox.has_hit = false

func jump_attack_state():
	velocity.x = 0
	if is_on_floor():
		enter_Jump_attack_recovery()

func enter_Jump_attack_recovery():
	current_state = state.JumpAttackRecovery
	anim.play("Jump_Attack_recovery")

func jump_attack_recovery_state():
	if not anim.is_playing():
		current_state = state.Idle


func enter_landing():
	anim.play("Landing")
	jump_counter = 0
	current_state = state.Idle

func enter_dash():
	if dash_flag == true:
		current_state = state.Dash
		
		if not can_control():
			return
		
		var dir := 0
		if Input.is_action_pressed(input_prefix + "move_left"):
			dir -= 1
		if Input.is_action_pressed(input_prefix + "move_right"):
			dir += 1
	
		if dir > 0:
			dash_direction = 1
			dash_speed = dash_direction * 1200
		elif dir < 0:
			dash_direction = -1
			dash_speed = dash_direction * 1200
		else:
			dash_direction = 1 * facing
			dash_speed = dash_direction * 800
			
		set_direction(dash_direction)
		velocity.x = dash_speed
		anim.play("Dash_start")

func dash_state(delta):

	velocity.x = dash_speed

	if not can_control():
		return
	if Input.is_action_just_pressed(input_prefix + "attack"):
		dash_attack = true
		enter_attack()
		return

	if Input.is_action_just_pressed(input_prefix + "jump"):
		if is_on_floor() == false:
			double_jump()

	state_timer -= delta

	if state_timer <= 0:
		anim.play("Dash_end")

func enter_dash_recovery(time: float):
	state_timer = time
	dash_cooldown = 0.1
	current_state = state.DashRecovery

func next_dash(delta):
	dash_cooldown -= delta
	if dash_cooldown <= 0:
		dash_flag = true
	else:
		dash_flag = false

func dash_recovery_state(delta):
	state_timer -= delta
	if state_timer <= 0:
		current_state = state.Idle

var queued_attack_step := 0
var active_attack_step := 0

func enter_attack():
	print("ENTER ATTACK STEP:", combo_step, "SPRITE:", anim.animation)
		
	if combo_step == 0:
		combo_step = 1
	elif combo_step == 1:
		combo_step = 2
	elif combo_step == 2:
		combo_step = 3
	else:
		combo_step = 1
	
	combo_timer = COMBO_WINDOW
	queued_attack_step = combo_step
	current_state = state.Attack
	
	if combo_step == 1:
		$AnimationPlayer.speed_scale = 1.0
		
		if dash_attack:
			anim.play("Dash_attack")
			last_attack_type = AttackType.DASH
		
		elif previous_state == state.JumpAttack:
			anim.play("Jump_Attack")
			last_attack_type = AttackType.JUMP
		
		else:
			anim.play("Attack")
			last_attack_type = AttackType.NORMAL
	
	elif combo_step == 2:
		anim.play("Attack")
		$AnimationPlayer.speed_scale = 1.0
	
	elif combo_step == 3:
		anim.play("Follow_up")
		$AnimationPlayer.speed_scale = 1.06


	$AnimationPlayer.play("Attack")
	$Hitbox.has_hit = false



func attack_state():
	if current_state == state.PostureBroken:
		return
	if not can_control():
		return
	if Input.is_action_just_pressed(input_prefix + "attack"):
		attack_buffered = true
		attack_buffer_expire_time = Time.get_ticks_msec() + int(ATTACK_BUFFER_TIME * 1000)

func enter_attack_recovery():
	current_state = state.AttackRecovery
	anim.play("Attack_recovery")

func attack_recovery_state():
	slow_move()

	if not anim.is_playing():
		current_state = state.Idle


func dash():
	pass

func enter_block():
	current_state = state.Block
	anim.play("Block_loop")

func block_state():
	if current_state == state.PostureBroken:
		return
	if not can_control():
		return
	slow_move()
	if not Input.is_action_pressed(input_prefix + "block"):
		enter_parry_recovery()

func enter_parry():
	current_state = state.Parry
	parry_elapsed = 0.0
	anim.play("Parry")

func parry_state(delta):
	parry_elapsed += delta

func enter_parry_recovery():
	if current_state == state.ParryRecovery:
		return
	current_state = state.ParryRecovery
	anim.play("Shield_down")

func parry_recovery_state():
	slow_move()

func _on_animation_finished():
	match current_state:
		state.Attack:			
			if anim.animation == "Attack":
				dash_attack = false
				if attack_buffered and Time.get_ticks_msec() <= attack_buffer_expire_time:
					attack_buffered = false
					enter_attack()
				else:
					enter_attack_recovery()
			
			elif anim.animation == "Follow_up":

				enter_attack_recovery()

				combo_step = 0
				active_attack_step = 0
				attack_buffered = false
			
			elif anim.animation == "Dash_attack":
				dash_attack = false
				enter_attack_recovery()
				
		state.Parry:
			if anim.animation == "Parry":
				if not can_control():
					return
				if Input.is_action_pressed(input_prefix + "block"):
					enter_block()
				else:
					enter_parry_recovery()
		state.ParryRecovery:
			if anim.animation == "Shield_down":
				current_state = state.Idle
		state.Dash:
			if anim.animation == "Dash_start":
				state_timer = 0.15
				anim.play("Dash_loop")

			elif anim.animation == "Dash_end":
				dash_flag = false
				enter_dash_recovery(0.15)
		state.JumpAttack:
			if anim.animation == "Jump_Attack_prep":
				start_active_jump_attack()

			elif anim.animation == "Jump_Attack":
				enter_Jump_attack_recovery()

const POSTURE_DECAY_INTERVAL := 0.5
var posture_decay_timer := 0.0
const BASE_DECAY_INTERVAL := 0.4
const MAX_DECAY_INTERVAL := 1.2
const POSTURE_DECAY_AMOUNT := 1.5

func recover_posture(delta):
	
	if current_state == state.PostureBroken:
		return
	
	if posture_recovery_delay > 0:
		posture_recovery_delay -= delta
		return
	
	var hp_ratio = hp / 100.0
	
	var decay_interval = lerp(MAX_DECAY_INTERVAL, BASE_DECAY_INTERVAL, hp_ratio)
	
	posture_decay_timer += delta
	
	if posture_decay_timer < decay_interval:
		return
	
	posture_decay_timer = 0.0
	
	if current_state in [state.Attack, state.HitStun]:
		return
	
	elif current_state in [state.Idle, state.Block, state.ParryRecovery]:
		posture -= POSTURE_DECAY_AMOUNT
	
	else:
		posture -= POSTURE_DECAY_AMOUNT * 0.5
	
	posture = clamp(posture, 0, 100)
	

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if not is_instance_valid(area):
		return
	var attacker = area.get("owner_character")
	if not is_instance_valid(attacker):
		return
	
	var defender = self
	
	if defender.is_dead:
		return
	
	if attacker == defender:
		return
	
	if area.has_hit:
		return

	if defender.current_state == state.HitStun and not defender.can_be_comboed:
		return
	
	else:
		print("HIT STEP:", attacker.combo_step, "ACTIVE STEP:", attacker.active_attack_step)
		area.has_hit = true
		
		if current_state == state.Parry && parry_elapsed <= perfect_parry_window:
			play_random_sword_deflect_sound()
			ImpactManager.impact_flash()
			hitstop(0.3)
			attacker.posture += 50
			defender.posture -= 20
			if attacker.posture >= 100:
				attacker.enter_posture_broken(4.0, defender.facing)
			else:
				attacker.enter_hit_stun(-defender.facing,-100.0,1.0,true)

		elif current_state == state.Parry:
			play_random_sword_deflect_sound()
			defender.posture -= 15
			attacker.posture += 30

			if attacker.posture >= 100:
				attacker.enter_posture_broken(3.0, defender.facing)
			else:
				attacker.enter_hit_stun(-defender.facing)

		elif current_state == state.Block:
			play_random_sword_deflect_sound()
			defender.posture += 20
			defender.posture_recovery_delay = POSTURE_RECOVERY_WAIT
			attacker.posture -= 5
			if defender.posture >= 100:
				defender.enter_posture_broken(3.0, attacker.facing)

		else:
			print(defender.hp)
			play_random_sword_hit_sound()

			var damage := 12
			var post := 18

			match attacker.combo_step:
				1:
					damage = 12
					post = 18
				2:
					damage = 6
					post = 12
				3:
					damage = 3
					post = 10
	
			if defender.current_state == state.PostureBroken:
				damage = defender.hp
	
			defender.hp -= damage
			defender.posture += post
			defender.posture_recovery_delay = POSTURE_RECOVERY_WAIT
	
			if attacker.combo_step >= 3:
				defender.enter_hit_stun(-attacker.facing, -900, 0.20, true)
	
				attacker.attack_buffered = false
				attacker.enter_attack_recovery()
	
				attacker.combo_step = 0
				attacker.last_attack_type = AttackType.NONE
	
			else:
				defender.enter_hit_stun(-attacker.facing, -250, 0.20, true)
	
			if defender.hp <= 0:
				defender.trigger_death(-attacker.facing)
				if defender == self:
					fade_out_music(arena_music, 1.0)
					end_sound.play()
				set_direction(-attacker.facing)
				return
	
			if defender.posture >= 100:
				defender.enter_posture_broken(2.2, -attacker.facing)
