extends "res://entities/Entity.gd"

var moveSpd = 0.7
var jumpSpd = 0
var deathPlaneY = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	deathPlaneY = GameManager.deathPlaneY


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _physics_process(delta):
	if position.y >= deathPlaneY:
		kill()
		return	
		
	vel.x += moveSpd * direction
	
func checkTurnCondi():
	if collision_enabled:
		if direction > 0 and touchingRwall:
			faceDirection(true)
		elif direction < 0 and touchingLwall:
			faceDirection(false)
