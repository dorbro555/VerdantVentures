extends CharacterBody3D

var tile_size = 0.5
var inputs = {"right": Vector3.RIGHT,
			"left": Vector3.LEFT,
			"up": Vector3.UP,
			"down": Vector3.DOWN}
var XZ_VECTOR = Vector3(1, 0, 1)
# How fast the player moves in meters per second.
@export var speed = 5
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75
var target_velocity = Vector3.ZERO
@onready var destination = global_position
@onready var ray = $RayCast3D
# Values for animation
var animation_speed = 3
var moving = false

# Called when the node enters the scene tree for the first time.
#func _ready():
#	global_transform.origin = position.snapped(Vector3(XZ_VECTOR) * tile_size) * ( Vector3(XZ_VECTOR) * tile_size/2)
##	position += Vector3(XZ_VECTOR) * tile_size/2
#	print("present: ", global_position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# if we have a destination, we check for when we arrive to disable moving and accept input again
	if destination != null:
		if not compare_floats(global_position.x, destination.x) || not compare_floats(global_position.z, destination.z):
#			print('moving ', global_position, destination)
			pass
	#		moving = true
		else:
			print('we got it!')
			moving = false
			destination = null
	
# reset direction vector, then set direction of movement if standing still
	var direction = Vector3.ZERO
	if moving == false:
		if Input.is_action_pressed("right"):
			direction.x += 1
			moving = true
		elif Input.is_action_pressed("left"):
			direction.x -= 1
			moving = true
		elif Input.is_action_pressed("down"):
			direction.z += 1
			moving = true
		elif Input.is_action_pressed("up"):
			direction.z -= 1
			moving = true

# If we have movement, the below code takes over
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		# If we have a direction, then we will use the raycast to check if such a move is allowed
		ray.target_position = direction * tile_size
		# The below is to force physics engine to update, so we may correctly check for collision
		ray.force_raycast_update()
		if ray.is_colliding():
			# illegal move, so reset direction and moving to accept input again
			direction = Vector3.ZERO
			moving = false
			print('collide', ray.target_position, global_position, direction * tile_size)
		else:
			# our move is legal, set destination so we can start moving towards it 
			destination = global_position + ray.target_position
			# Confine possible coordinates to the center of tiles
			destination = destination.snapped(Vector3(XZ_VECTOR) * tile_size/2)
			print('from',global_position, 'to', destination)

	# Ground Velocity
	# If we have a destination, then we are moving to it, otherwise we should be staying still
	if destination != null:
		target_velocity.x = global_position.direction_to(destination).x * speed
		target_velocity.z = global_position.direction_to(destination).z * speed
	else:
		target_velocity.x = 0
		target_velocity.z = 0

	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

	# Moving the Character
	velocity = target_velocity
	move_and_slide()

#func _unhandled_input(event):
#	for dir in inputs.keys():
#		if event.is_action_pressed(dir):
#			move(dir)
#
#func move(dir):
#	position += inputs[dir] * tile_size

# Lets create a function to compare float values
const FLOAT_EPSILON = 0.00001
static func compare_floats(a, b, epsilon=FLOAT_EPSILON):
	return abs(a - b) <= epsilon
