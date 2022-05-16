extends "res://Charecters/Charecter.gd"

export(float) var move_speed = 200
export(float) var jump_impulse = 600
export(float) var enemy_bounce_impulse = 600
export(int) var max_jumps = 2
export(float) var wall_slide_friction = 0.1
export(float) var jump_damage = 1
export(float) var knockback_collision_speed = 100


enum STATE {IDLE, RUN, JUMP, DOUBLE_JUMP, HIT, WALL_SLIDE}

onready var animated_sprite = $AnimatedSprite
onready var animation_tree = $AnimationTree
onready var jump_hitbox = $JumpHitbox
onready var invincible_timer = $InvincibleTimer
onready var wall_jump_timer = $WallJumpTimer
onready var drop_timer = $DropTimer

signal changed_state(new_state_string, new_state_id)

var velocity: Vector2

var current_state = STATE.IDLE setget set_current_state
var jumps = 0
var has_double_jump_occured = false
var is_bordering_wall : bool
var wall_jump_direction : Vector2

func _physics_process(delta):
	var input = get_player_input()
	
	if(Input.is_action_just_pressed("down")):
		if(drop_timer.is_stopped()):
			drop_timer.start()
		else:
			drop()
	
	velocity = move_and_slide(velocity, Vector2.UP)
	
	is_bordering_wall = get_is_on_wall_raycast_test()
	set_anim_parameters()
	
	match (current_state):
		STATE.IDLE, STATE.JUMP, STATE.RUN, STATE.DOUBLE_JUMP:
			if (wall_jump_timer.is_stopped()):	
				velocity = normal_move(input)
			else:
				velocity = wall_jumping_movement()
			pick_next_state()
		STATE.HIT:
			velocity = hit_move()
		STATE.WALL_SLIDE:
			velocity = wall_slide_move()
			pick_next_state()
	

func normal_move(input):
	adjust_flip_direction(input)
	return Vector2(
		input.x * move_speed,
		min(velocity.y + GameSettings.gravity, GameSettings.terminal_velocity)
	)

# knockback after hit	
func hit_move():
	var knockback_direction : Vector2
	
	# facing left
	if (animated_sprite.flip_h):
		knockback_direction = Vector2.RIGHT
	else:
		knockback_direction = Vector2.LEFT
	
	knockback_direction = knockback_direction.normalized()
	
	return knockback_collision_speed * knockback_direction

func wall_slide_move():
	return Vector2(
		velocity.x,
		min(velocity.y + (GameSettings.gravity * wall_slide_friction), GameSettings.terminal_velocity)
	)

func wall_jumping_movement():
	return Vector2(
		move_speed * wall_jump_direction.x,
		min(velocity.y + GameSettings.gravity, GameSettings.terminal_velocity)
	)

func adjust_flip_direction(input : Vector2):
	if (sign(input.x) == 1):
		animated_sprite.flip_h = false
	elif (sign(input.x) == -1):
		animated_sprite.flip_h = true
	
	
func set_anim_parameters():
	animation_tree.set("parameters/x_sign/blend_position", sign(velocity.x))
	animation_tree.set("parameters/y_sign/blend_amount", sign(velocity.y))

	var is_on_wall_int: int
	
	if (is_bordering_wall):
		is_on_wall_int = 1
	else:
		is_on_wall_int = 0
		
	animation_tree.set("parameters/is_on_wall/blend_amount", is_on_wall_int)
	
func pick_next_state():
	if (is_on_floor()):
		jumps = 0
		has_double_jump_occured = false
		
		#if jump is pressed when charecter is on the ground
		if (Input.is_action_just_pressed("jump")):
			self.current_state = STATE.JUMP
		elif (abs(velocity.x) > 0):
			self.current_state = STATE.RUN
		else:
			self.current_state = STATE.IDLE
	
	# to do double jump
	elif (Input.is_action_just_pressed("jump") && jumps < max_jumps && has_double_jump_occured == false):
		if (is_bordering_wall):
			self.current_state = STATE.JUMP
		else:
			self.current_state = STATE.DOUBLE_JUMP
	
	# is bordering wall
	elif (is_bordering_wall):
		self.current_state = STATE.WALL_SLIDE
		
	elif (self.current_state == STATE.WALL_SLIDE && !is_bordering_wall):
		self.current_state = STATE.JUMP
		
		
# uses input to determine which directions the player is pressing down on for use in movement
func get_player_input():
	var input: Vector2
	
	input.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	return input

# returns direction the charecter is facing  based on the flip direction of animated sprite
func get_facing_direction():
	if (animated_sprite.flip_h == false):
		return Vector2.RIGHT
	else:
		return Vector2.LEFT
	
# checks for walls in the direction the charecter is facing using raycast
# returns true if it fines a wall, null otherwise
# only collision mask is checked
func get_is_on_wall_raycast_test():
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(global_position, global_position + 10 * get_facing_direction(), [self], self.collision_mask)	
	
	if (result.size() > 0):
		return true
	else:
		return false
	
func jump():
	velocity.y = -jump_impulse
	jumps += 1
	
func wall_jump():
	velocity.y = -jump_impulse
	jumps = 1
	wall_jump_direction = -get_facing_direction()
	wall_jump_timer.start()

func drop():
	position.y += 1
	
func _on_JumpHitbox_area_shape_entered(area_rid, area, area_shape_index, local_shape_index):
	var enemy = area.owner
	
	if (enemy is Enemy && enemy.can_be_hit):
		# check if we are hitting enemy in right position and from right velocity
		if (velocity.y > 0):
			#jump attack
			velocity.y = -enemy_bounce_impulse
			enemy.get_hit (jump_damage)

func die():
	emit_signal("player_died", self)
	queue_free()

func get_hit(damage: float):
	if (invincible_timer.is_stopped()):
		self.health -= damage
		self.current_state = STATE.HIT
		invincible_timer.start()
	

func on_hit_finished():
	self.current_state  = STATE.IDLE

# setters
func set_current_state(new_state):
	match(new_state):
		STATE.JUMP:
			# multiple ways to enter jump state from wall slide state check pick_next_state
			if (current_state == STATE.WALL_SLIDE):
				if (Input.is_action_just_pressed("jump")):
					wall_jump()
			else:
				jump()
		STATE.DOUBLE_JUMP:
			jump()
			animation_tree.set("parameters/double_jump/active", true)
			has_double_jump_occured = true
		STATE.HIT:
			animation_tree.set("parameters/hit/active", true)
		STATE.WALL_SLIDE:
			jumps = 0
			# animation_tree.set("parameters/is_on_wall/blend_amount", 1)
			# above code is set in set_anim_parameters function as it needs to be refreshed every frame. 
			# Will be called in physics function to update animation tree every frame
		
	current_state = new_state
	emit_signal("changed_state",STATE.keys()[new_state] ,new_state)




