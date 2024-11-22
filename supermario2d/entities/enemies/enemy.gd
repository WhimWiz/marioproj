extends "res://entities/Entity.gd"
# STATE MACHINE --------------------------
const STATE_GENERICDEATH = 30
const STATE_STACK = 31

var players:Array = []

const DEATH_ROTATION_RATE = 0.25
const DEATH_FALL_RATE = 0.2
const DEATH_JUMP = Vector2(1.5, -4)

const sound_pool = {
	"bounce": preload("res://entities/enemies/sfx/kick.wav")
}

var isWalking = true
var stompable = true
var dangerous = true
@export var smartWalk = false
var interactionCooldown = 0
@export var stackChild:Node2D = null
var stackParent:Node2D = null

var walkSpd = 0.46
var jumpSpd = 0
var deathPlaneY = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	players = GameManager.players
	onSpawnDirect()
	
	deathPlaneY = GameManager.deathPlaneY
	GameManager.addEnemyToPool(self)
	
	if stackChild != null:
		stackChild.toStackState(self)
		stackChild.updateStackPos(position + Vector2.UP * (((boxScaleY * TILESCALE) / 2) + ((stackChild.boxScaleY * TILESCALE) / 2)))
	
	sprite.z_index = GameManager.Z_LAYER_ENEMY

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if interactionCooldown > 0:
		interactionCooldown -= delta * 60
		if interactionCooldown < 0:
			interactionCooldown = 0
	
func _physics_process(delta):
	if position.y >= deathPlaneY:
		kill()
		return	
		
	if state == STATE_GENERICDEATH:
		rotation += DEATH_ROTATION_RATE
		vel.y += DEATH_FALL_RATE
		scale.x += 0.01
		scale.y += 0.01
		
	super._physics_process(delta)
	
	if state == STATE_STACK:
		return
		
	if stackChild != null:
		stackChild.updateStackPos(position + Vector2.UP * (((boxScaleY * TILESCALE) / 2) + ((stackChild.boxScaleY * TILESCALE) / 2)))
	
	if isWalking:
		checkTurnCondi()
		vel.x = walkSpd * direction
		
	if grounded and jumpSpd != 0:
		vel.y = jumpSpd
		
func collisionCheck():
	super.collisionCheck()
	if collision_enabled and interactionCooldown <= 0:
		checkPlayerColl()
				
func checkPlayerColl():
	var result = checkHitboxColl(players[0].position, Vector2(players[0].boxScaleX, players[0].boxScaleY))
	if result:
		if stompable and players[0].position.y + (players[0].boxScaleY * TILESCALE) / 2 <= position.y:
			onStomp(players[0])
		elif dangerous:
			players[0].hurt_player()
		return players[0]
	return null
			
func checkTurnCondi():
	if collision_enabled:
		if direction > 0 and touchingRwall:
			sprite.play("turn")
			faceDirection(true)
		elif direction < 0 and touchingLwall:
			sprite.play("turn")
			faceDirection(false)
		
		var subjects = GameManager.enemies
		for i in range(0, len(subjects)):
			if subjects[i] != self and checkHitboxColl(subjects[i].position, Vector2(subjects[i].boxScaleX, subjects[i].boxScaleY)):
				if position.x > subjects[i].position.x and direction < 0: 
					sprite.play("turn")
					faceDirection(false)
				elif position.x < subjects[i].position.x and direction > 0: 
					sprite.play("turn")
					faceDirection(true)
					
		if smartWalk and grounded:
			if not checkVerticalColl(position.x + (TILESCALE / 4) * direction, position.y):
				if direction > 0: faceDirection(true)
				elif direction < 0: faceDirection(false)
				sprite.play("turn")
				
func onSpawnDirect():
	if players.size() > 0:
		if players[0].position.x < position.x: faceDirection(true) 
		else: faceDirection(false)
					
func onStomp(player:Node2D):
	player.vel.y = 0
	player.position.y = position.y - (player.boxScaleY * TILESCALE) / 2
	player.triggerBounce()
	
func toState(newState:int, anim:String = "", useAsPrefix:bool = false):
	super.toState(newState, anim, useAsPrefix)
	if state_stats.has(state):
		if state_stats[state].has("walking"):
			isWalking = state_stats[state]["walking"]
		else: isWalking = false
		
func toStackState(parent):
	gravity_enabled = false
	toState(STATE_STACK)
	stackParent = parent
	
func exitStack():
	gravity_enabled = true
	vel.y -= 2
	stackParent = null
	toState(0)
	
func abandonStackChild():
	stackChild = null
	
func updateStackPos(newPos:Vector2):
	position = newPos
	if stackChild != null:
		stackChild.updateStackPos(position + Vector2.UP * (((boxScaleY * TILESCALE) / 2) + ((stackChild.boxScaleY * TILESCALE) / 2)))
	
func startDeath(genericDeath:bool = true, offenderXpos:float = 0):
	if stackParent != null:
		stackParent.abandonStackChild()
	if stackChild != null:
		stackChild.exitStack()
		abandonStackChild()
		
	gravity_enabled = false
	collision_enabled = false
	vel.x = 0
	vel.y = 0
	if genericDeath:
		AudioManager.play_sound(sound_pool["bounce"])
		GameManager.spawnScore(position.x, position.y)
		GameManager.createVfx("smoke2", position.x, position.y)
		
		if offenderXpos > position.x:
			faceDirection(true)
		else:
			faceDirection(false)
		vel.x = DEATH_JUMP.x * direction
		vel.y = DEATH_JUMP.y
		isWalking = false
		sprite.z_index = GameManager.Z_LAYER_VFX_FRONT
		toState(STATE_GENERICDEATH, "generic_death")
			
func kill():
	GameManager.deleteEnemyFromPool(self)
	self.queue_free()
	
func faceDirection(faceLeft:bool):
	super.faceDirection(faceLeft)
	if stackChild != null:
		stackChild.faceDirection(faceLeft)
	

	
