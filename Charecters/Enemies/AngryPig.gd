extends KinematicBody2D

export(float) var move_speed = 100
export(float) var run_speed = 200
export(float) var waypoint_arrived_distance = 10
export(bool) var faces_right = true

export (Array, NodePath) var waypoints
export(int) var starting_waypoint = 0

var waypoint_position
var waypoint_index setget set_waypoint_index
var velocity = Vector2.ZERO

onready var animated_sprite = $AnimatedSprite

# Called when the node enters the scene tree for the first time.
func _ready():
	self.waypoint_index = starting_waypoint


func _physics_process(delta):
	var direction = self.position.direction_to(waypoint_position)
	var distance_x = Vector2(self.position.x, 0).distance_to(Vector2(waypoint_position.x, 0))
	
	if(distance_x >= waypoint_arrived_distance):
		#move towards waypoint
		var direction_x_sign = sign(direction.x)
		
		velocity = Vector2(
			move_speed * sign (direction.x),
			min(velocity.y + GameSettings.gravity, GameSettings.terminal_velocity)
		)
		# flip direction
		if (direction_x_sign == -1):
			animated_sprite.flip_h = faces_right
		elif(direction_x_sign == 1):
			animated_sprite.flip_h = !faces_right
		
		move_and_slide(velocity, Vector2.UP)
		
	else:
		var num_waypoints = waypoints.size()
		
		if (waypoint_index < num_waypoints - 1):
			self.waypoint_index += 1
		else:
			self.waypoint_index = 0
		#switch waypoints
		
func set_waypoint_index(value):
	waypoint_index = value
	waypoint_position = get_node(waypoints[waypoint_index]).position
