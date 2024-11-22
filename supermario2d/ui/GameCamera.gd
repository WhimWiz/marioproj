extends Node2D

@export var focusSubject:Node2D

var followX = 0
var followY = 0
const PAN_RATE = 0.2
const Y_OFFSET = -32

const CAM_VIEW_SCALE = Vector2(192, 108)

var levelBorders = [
	Vector2(-80, 32),
	Vector2(500, -220)
]
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	followX = focusSubject.position.x
	if focusSubject.grounded:
		followY = focusSubject.position.y
	tweenToPos(followX, followY + Y_OFFSET)
	if position.y + CAM_VIEW_SCALE.y > levelBorders[0].y:
		position.y = levelBorders[0].y - CAM_VIEW_SCALE.y
	
func tweenToPos(x, y):
	if position.x != x:
		if position.x < x - 0.4:  position.x += PAN_RATE * abs(position.x - x)
		elif position.x > x + 0.4: position.x -= PAN_RATE * abs(position.x - x)
		else: position.x = x
		
	if position.y != y:
		if position.y < y - 0.4: position.y += PAN_RATE * abs(position.y - y)
		elif position.y > y + 0.4: position.y -= PAN_RATE * abs(position.y - y)
		else: position.y = y
