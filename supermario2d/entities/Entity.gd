extends Node2D

const STATE_SPAWNING = 40
const SPAWNING_TRANS_RATE = 0.65
var spawn_position:Vector2 = Vector2(0, 0)
var spawn_dist:float = 0
var spawn_originalSize = Vector2(0, 0)
var spawn_originalState = 0
var spawn_originalLayer = 3

var gravity_multiplier = 1
var gravity_capped = true
const GRAVITY_RATE = 0.3125
const GRAVITY_CAP = 4.3125
const SENSOR_OVERSHOOT = 0.1
const TILESCALE = 16

const LAYER_BLOCK_BEHIND = 0

@onready var sprite:AnimatedSprite2D = get_node("Sprite")
#@onready var hitbox:CollisionShape2D = get_node("Area/Hitbox")

@export var direction = 1
var gravity_enabled:bool = true
var collision_enabled:bool = true
var grounded = false
var touchingCeil = false
var touchingLwall = false
var touchingRwall = false
var state = 0
var state_stats:Dictionary = {}
var anim_nextAnimPool = {}
var extendFeet = false
var groundData = null
var entity_timers:Dictionary = {}

@export var boxScaleX:int = 1
@export var boxScaleY:int = 1

var vel:Vector2 = Vector2.ZERO

func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _physics_process(delta):
	if state == STATE_SPAWNING:
		updateSpawn()
		return
	if gravity_enabled:
		vel.y += GRAVITY_RATE * gravity_multiplier
	if vel.y > GRAVITY_CAP and gravity_capped:
		vel.y = GRAVITY_CAP
	applyVelocity(vel * (delta * 60))
	
func faceDirection(faceLeft:bool):
	sprite.flip_h = faceLeft
	if faceLeft:
		direction = -1
	else:
		direction = 1

func collisionCheck():
	if collision_enabled:
		checkVerticalColl(position.x, position.y)
		checkHorizontalColl(position.x, position.y)
	
func applyVelocity(velocToAdd:Vector2):
	extendFeet = grounded
	grounded = false
	touchingCeil = false
	touchingLwall = false
	touchingRwall = false
	collisionCheck()
	var repeats = ceil(velocToAdd.length() / 4)
	for i in range(0, repeats):
		position.x += (velocToAdd.x / repeats)
		collisionCheck()
		position.y += (velocToAdd.y / repeats)
		collisionCheck()
		
func checkHorizontalColl(x, y):
	var ogX = 8 * (boxScaleX - 1)
	var ogY = 8 * (boxScaleY - 1)
	for a in range(0, boxScaleY):
		# LEFT DETECTION
		var query = PhysicsRayQueryParameters2D.create(Vector2((x - ogX), (y - ogY) + (a * TILESCALE)), Vector2((x - ogX) - 8 - SENSOR_OVERSHOOT, (y - ogY) + (a * TILESCALE)))
		var result = get_world_2d().direct_space_state.intersect_ray(query)
		if result and abs(result.normal.x) > 0.9:
			if abs(position.x - result.position.x) < 8:
				if vel.x <= 0: vel.x = 0
				position.x = result.position.x + (boxScaleX * 8)
			touchingLwall = true
			return true
		# RIGHT DETECTION
		query = PhysicsRayQueryParameters2D.create(Vector2((x + ogX), (y - ogY) + (a * TILESCALE)), Vector2((x + ogX) + 8 + SENSOR_OVERSHOOT, (y - ogY) + (a * TILESCALE)))
		result = get_world_2d().direct_space_state.intersect_ray(query)
		if result and abs(result.normal.x) > 0.9:
			if abs(position.x - result.position.x) < 8:
				if vel.x >= 0: vel.x = 0
				position.x = result.position.x - (boxScaleX * 8)
			touchingRwall = true
			return true
			
	return false
	
func checkVerticalColl(x, y):
	var ogX = 8 * (boxScaleX - 1)
	var ogY = 8 * (boxScaleY - 1)
	for a in range(0, boxScaleX):
		if vel.y < 0:
			# HEAD DETECTION
			var query = PhysicsRayQueryParameters2D.create(Vector2((x - ogX) + (a * TILESCALE), (y - ogY)), Vector2((x - ogX) + (a * TILESCALE), (y - ogY) - 8 - SENSOR_OVERSHOOT))
			var result = get_world_2d().direct_space_state.intersect_ray(query)
			if result:
				vel.y = 0
				position.y = result.position.y + (boxScaleY * 8)
				touchingCeil = true
				onCeilingCollision(result.collider)
				return true
		else:
			var range = 8
			if extendFeet:
				range = 16
			
			# FEET DETECTION
			var query = PhysicsRayQueryParameters2D.create(Vector2((x - ogX) + (a * TILESCALE), (y + ogY)), Vector2((x - ogX) + (a * TILESCALE), (y + ogY) + range + SENSOR_OVERSHOOT))
			var result = get_world_2d().direct_space_state.intersect_ray(query)
			if result:
				groundData = result
				vel.y = 0
				position.y = result.position.y - (boxScaleY * 8)
				if not extendFeet:
					onFloorCollision(result.collider)
				grounded = true
				return true
				
	return false
				
func checkHitboxColl(subject_pos:Vector2, subject_box:Vector2):
	var hitbox = Rect2(Vector2(position.x - (boxScaleX * TILESCALE) / 2, position.y - (boxScaleY * TILESCALE) / 2), Vector2(boxScaleX * TILESCALE, boxScaleY * TILESCALE))
	return hitbox.intersects(Rect2(Vector2(subject_pos.x - (subject_box.x * TILESCALE) / 2, subject_pos.y - (subject_box.y * TILESCALE) / 2), 
	Vector2(subject_box.x * TILESCALE, subject_box.y * TILESCALE)))
				
func onFloorCollision(collidedObj:Node2D):
	pass	
			
func onCeilingCollision(collidedObj:Node2D):
	pass
	
func toState(newState:int, anim:String = "", useAsPrefix:bool = false):
	if anim != "":
		sprite.speed_scale = 1
		if useAsPrefix:
			sprite.play(anim + state_stats[newState]["initialAnim"], 1)
		else:
			sprite.play(anim, 1)
		
	state = newState
	
func updateSpawn():
	var direction = (spawn_position - position).normalized()
	position += direction * SPAWNING_TRANS_RATE
	if spawn_originalSize != Vector2.ZERO:
		sprite.scale.x = spawn_originalSize.x - spawn_originalSize.x * (position.distance_to(spawn_position) / spawn_dist)
		sprite.scale.y = spawn_originalSize.y - spawn_originalSize.y * (position.distance_to(spawn_position) / spawn_dist)
	if position.distance_to(spawn_position) < SPAWNING_TRANS_RATE:
		endSpawn()
	
func setSpawn(toPosition:Vector2, grow:bool = true):
	gravity_enabled = false
	collision_enabled = false
	vel = Vector2.ZERO
	spawn_position = toPosition
	spawn_dist = position.distance_to(spawn_position)
	spawn_originalLayer = sprite.z_index
	sprite.z_index = LAYER_BLOCK_BEHIND
	if grow:
		spawn_originalSize = sprite.scale
		sprite.scale = Vector2.ZERO
	state = STATE_SPAWNING
	
func endSpawn():
	position = spawn_position
	sprite.z_index = spawn_originalLayer
	if spawn_originalSize != Vector2.ZERO:
		sprite.scale = spawn_originalSize
	gravity_enabled = true
	collision_enabled = true
	toState(spawn_originalState)
		
func anim_onEnd():
	if anim_nextAnimPool.has(sprite.animation):
		if anim_nextAnimPool[sprite.animation] == "kill":
			kill()
			return
		sprite.speed_scale = 1
		sprite.play(anim_nextAnimPool[sprite.animation])
		
func kill():
	self.queue_free()
