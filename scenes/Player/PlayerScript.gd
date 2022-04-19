extends KinematicBody2D

export var mine_cliche:PackedScene

var can_mine:bool = true

var checkpoint:Vector2
var current_checkpoint = null
var prev_checkpoint = null

var local_state = Commons.STATES.GAMEPLAY
onready var father = get_tree().get_current_scene()
var action_area

var velocity:Vector2

var acceleration:float = 750
var maxvelocity:float = 115
var fricction:float = 25
var jumpforce:float = 75
var jump_push:float = 0.5
var gravity:float = 15

var just_grounded:bool=false
var hor_inp:float = 0

func _ready():
	
	father.connect("game_state_signal",self,"_new_game_state")
	pass


func _new_game_state(state):
	local_state = state
	if local_state == Commons.STATES.DIALOGE:
		hor_inp = 0
		can_mine = false
		pass
	elif local_state == Commons.STATES.GAMEPLAY:
		$CrunchTimer.start()
	elif local_state == Commons.STATES.GAMEOVER:
		get_parent().visible = false
		set_physics_process(false)
		set_process(false)
		Engine.set_time_scale(1)
		pass
	pass


func _physics_process(delta):
	if Input.is_action_pressed("ui_down"):
		father._next_level()
	velocity.y = max(velocity.y, -600)
	velocity = move_and_slide(velocity,Vector2.UP)
	if !is_on_floor():
		just_grounded = false
		$WalkingParticles.emitting = false
		$AnimatedSprite.play("jump")
	
	if local_state == Commons.STATES.GAMEPLAY:
		hor_inp = Input.get_action_raw_strength("ui_right") - Input.get_action_raw_strength("ui_left")
		if hor_inp != 0 && is_on_floor():
			$WalkingParticles.emitting = true
			$AnimatedSprite.play("run")
			$AnimatedSprite.flip_h = true if hor_inp < 0 else false
		elif is_on_floor():
			$WalkingParticles.emitting = false
			$AnimatedSprite.play("iddle")
		pass
	else:
		$WalkingParticles.emitting = false
		$AnimatedSprite.play("iddle")
	
	#Movimiento horizontal
	if hor_inp != 0:
		if hor_inp > 0:
			velocity.x = min(velocity.x + acceleration*hor_inp*delta, maxvelocity*hor_inp)
		else:
			velocity.x = max(velocity.x + acceleration*hor_inp*delta, maxvelocity*hor_inp)
			pass
	else:
		if velocity.x > 0:
			velocity.x = max(velocity.x - fricction, 0)
		elif velocity.x == 0:
			pass
		else:
			velocity.x = min(velocity.x + fricction, 0)
	
	#Movimiento vertical
	if velocity.y <= 300:
		velocity.y += gravity
		pass
	
	if just_grounded == false:
		if is_on_floor():
			just_grounded = true
			$FallParticles.restart()
			$FallParticles.emitting = true
		pass
	
	pass





func _process(delta):
	
	if Input.is_action_just_pressed("ui_up"):
		_on_damage()
	
	if Input.is_action_just_pressed("ui_jump"):
		if action_area != null && local_state == Commons.STATES.GAMEPLAY:
			if action_area.has_method("_transmit_dialoge"):
				father._add_dialoge(action_area._transmit_dialoge())
			elif action_area.has_method("_transmit_item"):
				action_area.transmit_item()
				pass
			_on_InteractDetector_area_exited(action_area)
			pass
		
		elif father.get_mines() > 0 && local_state == Commons.STATES.GAMEPLAY && can_mine:
			$CrunchTimer.start()
			can_mine = false
			var new_mine = mine_cliche.instance()
			get_parent().add_child(new_mine)
			new_mine.apply_central_impulse(Vector2.UP * 75)
			new_mine.global_position = $MineSpawner.global_position
			father.set_mines(1,true)
			pass
		
		pass
	pass

func _add_more(mines:bool,life:bool,mine_more:int,life_more:int):
	if mines:
		father.set_mines(mine_more,true)
	if life && father.get_lifes()+life_more != 5:
		father.set_lifes(life_more,true)
	
	pass

func _on_damage():
	father.flash()
	global_position = checkpoint
	$CrunchTimer.wait_time = 0.05
	$CrunchTimer.start()
	Engine.set_time_scale(0.25)
	father.set_lifes(1,true)
	pass

func _on_mine_exploded():
	$CrunchTimer.wait_time = 0.05
	$CrunchTimer.start()
	Engine.set_time_scale(0.25)
	father.set_lifes(1,true)
	pass

func _set_vertical_velocity(VerVel:float):
	velocity.y = -VerVel
	pass

func _apply_vertical_velocity(VerVel:float):
	velocity.y -= VerVel
	pass


func _on_InteractDetector_area_entered(area):
	action_area = area
	$ActionIndicator._start_dialoge_anim()
	pass # Replace with function body.


func _on_InteractDetector_area_exited(area):
	$ActionIndicator._stop_dialoge_anim()
	action_area = null
	pass # Replace with function body.


func _on_CrunchTimer_timeout():
	can_mine = true
	Engine.set_time_scale(1)
	pass # Replace with function body.


func _on_Damager_area_entered(area):
	_on_damage()
	pass # Replace with function body.


func _on_CheckpointCollider_area_entered(area):
	if current_checkpoint != area:
		father.flash()
		prev_checkpoint = current_checkpoint
		current_checkpoint = area
		checkpoint = current_checkpoint.global_position
		
		if prev_checkpoint != null:
			prev_checkpoint.set_active(false)
		current_checkpoint.set_active(true)
	
	pass # Replace with function body.


func _on_Damager_body_entered(body):
	_on_damage()
	pass # Replace with function body.
