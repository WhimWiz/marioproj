extends "res://entities/Entity.gd"
# STATE MACHINE --------------------------
const STATE_IDLE = 0
const STATE_WALK = 1
const STATE_JUMP = 2
const STATE_FALL = 3
const STATE_CROUCH = 4
const STATE_SPIN = 5
const STATE_HURT = 6
const STATE_WALLSLIDE = 7
const STATE_GROUNDPOUND = 8

# WALK --------------------------
const WALK_RATE = 0.0546875
const WALK_CAP = 1.5
# RUN --------------------------
const RUN_RATE = 0.0546875
const RUN_CAP = 3.5
const SKID_RANGE = 1.5
# FRICTION --------------------------
const FRICTION_RATE = 0.0546875
var skidTime = 0
# JUMP --------------------------
const JUMP_RATE_FAST = -3.6
const JUMP_RATE_SLOW = -3.15
var jump_rate = -3.4375
var jump_time_curr = 0
var jump_button:String = "Jump"
const JUMP_TIME = 0.3
const JUMP_TIME_MIN = 0.06
# WALLJUMPING -----------------------
const WALLSLIDE_GRAV_CAP = 1.1
const WALLJUMP_JUMP_X = 2.8

const sound_pool = {
	"jump": preload("res://entities/player/sfx/jump.wav"),
	"spin": preload("res://entities/player/sfx/spin.wav"),
	"walljump": preload("res://entities/enemies/sfx/kick.wav"),
	"impact": preload("res://entities/player/sfx/bump.wav"),
	"level_down": preload("res://entities/player/sfx/hurt.wav")
}

# POWERUP TIERS --------------------------
var powerupID = 1
var powerup_prefix = [
	"sma_",
	"sup_"
]
var powerup_scales = [
	Vector2(1, 1),
	Vector2(1, 2)
]

var isSpinning = false
var canMoveGrounded = true
var canMoveAerial = true
var canJump = true

var hurtEndSignal = null


func _ready():
	state_stats = {
		STATE_IDLE: {"initialAnim": "stand", "allowGroundMovement": true, "allowAerialMovement": true, "allowJump": true, "allowFlip": true, "canCrouch": true},
		STATE_WALK: {"initialAnim": "walk", "allowGroundMovement": true, "allowAerialMovement": true, "allowJump": true, "allowFlip": true, "canCrouch": true},
		STATE_JUMP: {"initialAnim": "jump", "allowGroundMovement": true, "allowAerialMovement": true, "allowJump": true, "allowFlip": true, "canCrouch": true},
		STATE_FALL: {"initialAnim": "fall", "allowGroundMovement": true, "allowAerialMovement": true, "allowJump": true, "allowFlip": true, "canCrouch": true},
		STATE_CROUCH: {"initialAnim": "crouch", "allowGroundMovement": false, "allowAerialMovement": true, "allowJump": true, "allowFlip": true, "canCrouch": true},
		STATE_SPIN: {"initialAnim": "spin", "allowGroundMovement": true, "allowAerialMovement": true, "allowJump": true, "allowFlip": true, "canCrouch": true},
		STATE_HURT: {"initialAnim": "hurt", "allowGroundMovement": false, "allowAerialMovement": false, "allowJump": false, "allowFlip": false, "canCrouch": false},
		STATE_WALLSLIDE: {"initialAnim": "fall", "allowGroundMovement": false, "allowAerialMovement": false, "allowJump": true, "allowFlip": false, "canCrouch": false},
		STATE_GROUNDPOUND: {"initialAnim": "groupound_roll", "allowGroundMovement": false, "allowAerialMovement": false, "allowJump": false, "allowFlip": false, "canCrouch": false}
	}
	
	anim_nextAnimPool = {
		"land": "stand",
		"turn": "walk",
		"uncrouch": "initial",
		"groupound_roll": "groupound_fall"
	}
	
	entity_timers = {
		"invuln": 0
	}
	sprite.z_index = GameManager.Z_LAYER_PLAYER
	GameManager.players.push_back(self)
	
	sprite.play(powerup_prefix[powerupID] + "stand")
	updatePlayerScale(powerup_scales[powerupID])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if entity_timers["invuln"] > 0:
		entity_timers["invuln"] -= delta
		if int(ceil(entity_timers["invuln"] * 10)) % 2 == 0:
			sprite.self_modulate.a = 1
		else:
			sprite.self_modulate.a = 0.5
			
	if jump_time_curr > 0:
		vel.y = jump_rate
		jump_time_curr -= delta
		if jump_time_curr <= 0 or jump_time_curr < JUMP_TIME - JUMP_TIME_MIN and not Input.is_action_pressed(jump_button):
			endJump()
				
	match state:
		STATE_IDLE:
			if vel.x != 0:
				toState(STATE_WALK, powerup_prefix[powerupID], true)
				
		STATE_WALK:
			if sprite.animation == powerup_prefix[powerupID] + "walk":
				sprite.speed_scale = abs(vel.x / RUN_CAP)
			elif sprite.animation == powerup_prefix[powerupID] + "skid":
				skidTime += 0.1
				if skidTime >= 1: 
					skidTime -= 1
					GameManager.createVfx("smoke1", position.x, position.y + (powerup_scales[powerupID].y / 2) * TILESCALE)
				if sign(vel.x) == sign(direction): sprite.animation = powerup_prefix[powerupID] + "walk"
				
			if vel.x == 0:
				toState(STATE_IDLE, powerup_prefix[powerupID], true)
			elif not grounded:
				toState(STATE_FALL, powerup_prefix[powerupID], true)
		STATE_JUMP:
			# ACTS AS A FAILSAFE FOR ENDJUMP, NOT THE PRIMARY WAY THIS SHOULD BE TRANSITIONING
			if jump_time_curr <= 0:
				toState(STATE_FALL)
		STATE_FALL:
			if sprite.animation == powerup_prefix[powerupID] + "jump" and vel.y > 0:
				sprite.play(powerup_prefix[powerupID] + state_stats[STATE_FALL]["initialAnim"])
				
			if touchingLwall and Input.is_action_pressed("Left") or touchingRwall and Input.is_action_pressed("Right"):
				startWallSlide()
				return
				
			if Input.is_action_pressed("Down"):
				startGroundPound()
				return
				
			if grounded:
				GameManager.createVfx("smoke1", position.x, position.y + (powerup_scales[powerupID].y / 2) * TILESCALE)
				land()
		
		STATE_WALLSLIDE:
			if not touchingLwall and not touchingRwall:
				toState(STATE_FALL, powerup_prefix[powerupID], true)
				return
				
			if touchingLwall and Input.is_action_just_pressed("Right") or touchingRwall and Input.is_action_just_pressed("Left"):
				toState(STATE_FALL, powerup_prefix[powerupID], true)
				return
			
			if vel.y > WALLSLIDE_GRAV_CAP:
				vel.y = WALLSLIDE_GRAV_CAP
			
			if Input.is_action_just_pressed("Jump"):
				if touchingLwall: vel.x += WALLJUMP_JUMP_X
				else: vel.x -= WALLJUMP_JUMP_X
				
				AudioManager.play_sound(sound_pool["walljump"])
				jump_button = "Jump"
				startJump()
				toState(STATE_JUMP, powerup_prefix[powerupID], true)
				canMoveAerial = false
				return
				
			if grounded:
				GameManager.createVfx("smoke1", position.x, position.y + (powerup_scales[powerupID].y / 2) * TILESCALE)
				land()
		STATE_GROUNDPOUND:
			if sprite.animation == powerup_prefix[powerupID] + "groupound_fall":
				vel.y = 7.5
				if grounded:
					sprite.play(powerup_prefix[powerupID] + "groupound_land")
					
			if sprite.animation == powerup_prefix[powerupID] + "groupound_land" and sprite.frame_progress >= 1:
				gravity_enabled = true
				gravity_capped = true
				toState(STATE_IDLE, powerup_prefix[powerupID], true)
				
		STATE_CROUCH:
			if not Input.is_action_pressed("Down") and grounded:
				if powerup_scales[powerupID].y > 1 and checkHeadSpace():
					return
				if vel.x != 0:
					toState(STATE_WALK, powerup_prefix[powerupID], true)
				else:
					toState(STATE_IDLE, powerup_prefix[powerupID], true)
				updatePlayerScale(powerup_scales[powerupID])
				sprite.play(powerup_prefix[powerupID] + "uncrouch")
				
		STATE_SPIN:
			if grounded:
				isSpinning = false
				if vel.x != 0:
					toState(STATE_WALK, powerup_prefix[powerupID], true)
				else:
					toState(STATE_IDLE, powerup_prefix[powerupID], true)
				
	
func _physics_process(delta):
	
	updateMovement()
			
	if Input.is_action_just_pressed("Jump") and grounded and state_stats[state]["allowJump"]:
		AudioManager.play_sound(sound_pool["jump"])
		jump_button = "Jump"
		startJump()
		if state != STATE_CROUCH:
			toState(STATE_JUMP, powerup_prefix[powerupID], true)
			
	if Input.is_action_just_pressed("Action2") and grounded and state_stats[state]["allowJump"]:
		AudioManager.play_sound(sound_pool["spin"])
		jump_button = "Action2"
		startJump()
		isSpinning = true
		toState(STATE_SPIN, powerup_prefix[powerupID], true)
		
	elif Input.is_action_pressed("Down") and state != STATE_CROUCH and grounded and state_stats[state]["canCrouch"]:
		updatePlayerScale(Vector2(powerup_scales[powerupID].x, 1))
		toState(STATE_CROUCH, powerup_prefix[powerupID], true)
			
	super._physics_process(delta)
	
func updateMovement():
	var rate = WALK_RATE
	var cap = WALK_CAP
	var canMove = canMoveGrounded
	var hasMoved = false
	if not grounded:
		canMove = canMoveAerial
	if Input.is_action_pressed("Action"):
		rate = RUN_RATE
		cap = RUN_CAP
		
	if Input.is_action_pressed("Left"):
		if direction > 0 and state_stats[state]["allowFlip"]:
			if state == STATE_WALK:
				sprite.speed_scale = 1
				if abs(vel.x) > SKID_RANGE: sprite.play(powerup_prefix[powerupID] + "skid")
				else: sprite.play(powerup_prefix[powerupID] + "turn")
			faceDirection(true)
		if canMove:
			hasMoved = true
			vel.x -= rate
			if vel.x < -cap:
				vel.x = -cap
			elif vel.x > 0:
				vel.x -= FRICTION_RATE
	elif Input.is_action_pressed("Right"):
		if direction < 0 and state_stats[state]["allowFlip"]:
			if state == STATE_WALK:
				sprite.speed_scale = 1
				if abs(vel.x) > SKID_RANGE: sprite.play(powerup_prefix[powerupID] + "skid")
				else: sprite.play(powerup_prefix[powerupID] + "turn")
			faceDirection(false)
		if canMove:
			hasMoved = true
			vel.x += rate
			if vel.x > cap:
				vel.x = cap
			elif vel.x < 0:
				vel.x += FRICTION_RATE
	if grounded and not hasMoved:
		vel.x -= FRICTION_RATE * sign(vel.x)
		if abs(vel.x) < FRICTION_RATE:
			vel.x = 0
			
func startJump():
	gravity_enabled = false
	jump_time_curr = JUMP_TIME
	if grounded:
		position.y -= abs(groundData.normal.x)
		grounded = false
		
	if abs(vel.x) > 1.2:
		jump_rate = JUMP_RATE_FAST
	else:
		jump_rate = JUMP_RATE_SLOW
	vel.y = jump_rate
	
func endJump():
	gravity_enabled = true
	jump_time_curr = 0
	if state == STATE_JUMP:
		toState(STATE_FALL)
		
func land():
	GameManager.score_tier = 0
	if vel.x != 0:
		toState(STATE_WALK, powerup_prefix[powerupID], true)
	else:
		toState(STATE_IDLE, powerup_prefix[powerupID], true)
		
func triggerBounce():
	if state == STATE_SPIN:
		vel.y = 0
	else:
		toState(STATE_JUMP, powerup_prefix[powerupID], true)
		startJump()
		
func startWallSlide():
	vel.x = 0
	if touchingRwall: faceDirection(true)
	else: faceDirection(false)
	toState(STATE_WALLSLIDE, powerup_prefix[powerupID], true)
	
func startGroundPound():
	gravity_enabled = false
	gravity_capped = false
	vel.y = 0
	vel.x = 0
	toState(STATE_GROUNDPOUND, powerup_prefix[powerupID], true)
	
func onFloorCollision(collidedObj:Node2D):
	if state == STATE_GROUNDPOUND:
		if collidedObj.is_in_group("block"):
			collidedObj.block_trigger(true)
	
func onCeilingCollision(collidedObj:Node2D):
	endJump()
	AudioManager.play_sound(sound_pool["impact"])
	if collidedObj.is_in_group("block"):
		collidedObj.block_trigger(false)
	
# NOTE --- only works with 1x1 at the moment, compatibility for other scales may be considered for the future
func checkHeadSpace():
	var query = PhysicsRayQueryParameters2D.create(position, Vector2(position.x, position.y - 23))
	var result = get_world_2d().direct_space_state.intersect_ray(query)
	if result:
		return true
	else:
		return false
	
func updatePlayerScale(newScale:Vector2):
	position.y -= (newScale.y - boxScaleY) * 8
	sprite.position.y += (newScale.y - boxScaleY) * 8
	boxScaleX = newScale.x
	boxScaleY = newScale.y
	
func hurt_player():
	if entity_timers["invuln"] > 0:
		return
	vel.x = 0
	vel.y = 0
	gravity_enabled = false
	collision_enabled = false
	entity_timers["invuln"] = 5
	GameManager.pauseGameObjects(true, true)
	AudioManager.play_sound(sound_pool["level_down"])
	toState(STATE_HURT, powerup_prefix[powerupID] + "hurt")
	sprite.animation_finished.connect(end_hurt)
	
func end_hurt():
	sprite.animation_finished.disconnect(end_hurt)
	gravity_enabled = true
	collision_enabled = true
	powerupID -= 1
	GameManager.pauseGameObjects(false, true)
	updatePlayerScale(powerup_scales[powerupID])
	toState(STATE_FALL, powerup_prefix[powerupID] + "fall")
	
func toState(newState:int, anim:String = "", useAsPrefix:bool = false):
	super.toState(newState, anim, useAsPrefix)
	canMoveGrounded = state_stats[state]["allowGroundMovement"]
	canMoveAerial = state_stats[state]["allowAerialMovement"]
	canJump = state_stats[state]["allowJump"]
	
func anim_onEnd():
	if anim_nextAnimPool.has(sprite.animation.replace(powerup_prefix[powerupID], "")):
		var nextAnim = anim_nextAnimPool[sprite.animation.replace(powerup_prefix[powerupID], "")]
		sprite.speed_scale = 1
		if nextAnim == "initial":
			sprite.play(powerup_prefix[powerupID] + state_stats[state]["initialAnim"])
		else:
			sprite.play(powerup_prefix[powerupID] + nextAnim)
