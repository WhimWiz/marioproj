extends "res://entities/enemies/enemy.gd"

var STATE_WALK = 0
var STATE_SHELL_IDLE = 1
var STATE_SHELL_MOVING = 2

var SHELL_SPEED = 3.2
var SHELL_EXIT_TIME = 8 * 60
var SHELL_SHAKE_RATE = 7

var shell_cooldown = 24
var shell_exitTime = 0
var shell_shakeDirec = 1
var shell_bonk_sfx = preload("res://entities/player/sfx/bump.wav")

func _ready():
	state_stats = {
		STATE_WALK: {"initialAnim": "walk", "walking": true},
		STATE_SHELL_IDLE: {"initialAnim": "shell", "walking": false},
		STATE_SHELL_MOVING: {"initialAnim": "shell", "walking": false}
	}
	anim_nextAnimPool = {
		"turn": "walk",
		"stomped": "kill"
	}
	super._ready()
	
func _process(delta):
	super._process(delta)
	if state == STATE_SHELL_IDLE:
		if shell_exitTime > 0:
			shell_exitTime -= delta * 60
			if shell_exitTime < 0:
				exitShellState()
			elif shell_exitTime < 120:
				if abs(rotation_degrees) > 5 and abs(rotation_degrees) < 355:
					shell_shakeDirec *= -1
				rotate((SHELL_SHAKE_RATE * shell_shakeDirec) * delta)
					
				
	
func _physics_process(delta):
	super._physics_process(delta)
	match state:
		STATE_SHELL_IDLE:
			if interactionCooldown > 0:
				return
			var result = checkHitboxColl(players[0].position, Vector2(players[0].boxScaleX, players[0].boxScaleY))
			if result: shellToMotion(players[0])
			
		STATE_SHELL_MOVING:
			if direction > 0 and touchingRwall: 
				faceDirection(true)
				AudioManager.play_sound(shell_bonk_sfx)
			elif direction < 0 and touchingLwall: 
				faceDirection(false)
				AudioManager.play_sound(shell_bonk_sfx)
				
			for i in range(0, floor(abs(vel.x))):
				GameManager.createVfx("shelltrail_green", position.x + -i * sign(vel.x), position.y, true)
			
			vel.x = SHELL_SPEED * direction
			
			var subjects = GameManager.enemies
			for i in range(0, len(subjects)):
				if subjects[i] != self and subjects[i].collision_enabled and checkHitboxColl(subjects[i].position, Vector2(subjects[i].boxScaleX, subjects[i].boxScaleY)):
					subjects[i].startDeath(true, position.x)
				
	
func onStomp(player:Node2D):
	AudioManager.play_sound(sound_pool["bounce"])
	super.onStomp(player)
	if state == STATE_WALK:
		GameManager.spawnScore(position.x, position.y)
		toShellState()
	elif state == STATE_SHELL_MOVING:
		GameManager.spawnScore(position.x, position.y)
		toShellState()
	
func toShellState():
	shell_exitTime = SHELL_EXIT_TIME
	toState(STATE_SHELL_IDLE, state_stats[STATE_SHELL_IDLE]["initialAnim"])
	sprite.pause()
	vel.x = 0
	interactionCooldown = shell_cooldown
	dangerous = false
	stompable = false
	
func exitShellState():
	rotation = 0
	toState(STATE_WALK, state_stats[STATE_WALK]["initialAnim"])
	dangerous = true
	stompable = true
	
func shellToMotion(player):
	if player.position.x < position.x: faceDirection(false)
	else: faceDirection(true)
	GameManager.createVfx("clash", position.x, position.y)
	
	rotation = 0
	shell_exitTime = SHELL_EXIT_TIME
	dangerous = true
	stompable = true
	interactionCooldown = shell_cooldown
	toState(STATE_SHELL_MOVING, state_stats[STATE_SHELL_IDLE]["initialAnim"])
	AudioManager.play_sound(sound_pool["bounce"])
	
