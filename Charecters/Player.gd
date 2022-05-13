extends KinematicBody2D

export(float) var move_speed = 200
export(float) var jump_impulse = 600
export(int) var max_jumps = 2

enum STATE {IDLE, RUN, JUMP, DOUBLE_JUMP}

onready var animated_sprite = $AnimatedSprite
onready var animation_tree = $AnimationTree

signal changed_state(new_state_string, new_state_id)

var velocity: Vector2

var current_state = STATE.IDLE setget set_current_state
var jumps = 0

func _physics_process(delta):
	var input = get_player_input()
	adjust_flip_direction(input)
	
	velocity = Vector2(
		input.x * move_speed,
		min(velocity.y + GameSettings.gravity, GameSettings.terminal_velocity)
	)
	
	velocity = move_and_slide(velocity, Vector2.UP)
	set_anim_parameters()
	pick_next_state()
	
func adjust_flip_direction(input : Vector2):
	if (sign(input.x) == 1):
		animated_sprite.flip_h = false
	elif (sign(input.x) == -1):
		animated_sprite.flip_h = true
	
	
func set_anim_parameters():
	animation_tree.set("parameters/x_sign/blend_position", sign(velocity.x))
	animation_tree.set("parameters/y_sign/blend_amount", sign(velocity.y))

	
func pick_next_state():
	if (is_on_floor()):
		jumps = 0
		
		#if jump is pressed when charecter is on the ground
		if (Input.is_action_just_pressed("jump")):
			self.current_state = STATE.JUMP
		elif (abs(velocity.x) > 0):
			self.current_state = STATE.RUN
		else:
			self.current_state = STATE.IDLE
	
	else:
		# to do double jump
		if (Input.is_action_just_pressed("jump") && jumps < max_jumps):
			self.current_state = STATE.DOUBLE_JUMP
		
# uses input to determine which directions the player is pressing down on for use in movement
func get_player_input():
	var input: Vector2
	
	input.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	return input
	
func jump():
	velocity.y = -jump_impulse
	jumps += 1
	
# setters
func set_current_state(new_state):
	match(new_state):
		STATE.JUMP, STATE.DOUBLE_JUMP:
			jump()
	
	current_state = new_state
	emit_signal("changed_state",STATE.keys()[new_state] ,new_state)

