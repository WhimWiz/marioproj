extends Node2D

@onready var sprite:AnimatedSprite2D = get_node("Sprite")

var vel = Vector2(0, 0)
var friction = 0
var lifeTime:float = 1
var alphaFade = 0

var vfx_pool = {
	"score": {"vel": Vector2(0, -0.7), "lifeTime": 0.5, "friction": 0.015},
	"smoke1": {"vel": Vector2(0, 0), "lifeTime": 1, "friction": 0},
	"smoke2": {"vel": Vector2(0, 0), "lifeTime": 1, "friction": 0},
	"clash": {"vel": Vector2(0, 0), "lifeTime": 1, "friction": 0},
	"block_coin": {"vel": Vector2(0, -3.4), "lifeTime": 0.45, "friction": 0.14},
	"shelltrail_green": {"lifeTime": 0.2, "alphaFade": true}
}

func _ready():
	pass

func _process(delta):
	lifeTime -= delta
	if alphaFade != 0: sprite.modulate.a = lifeTime / alphaFade
	if lifeTime <= 0:
		queue_free()
	
func _physics_process(delta):
	position += vel
	vel.x -= friction * sign(vel.x)
	if abs(vel.x) < friction:
		vel.x = 0
		
	vel.y -= friction * sign(vel.y)
	if abs(vel.y) < friction:
		vel.y = 0
	
	
func setVFXdata(vfxAnim:String, frame:int = -1, layerBack:bool = false, speed:float = 1):
	sprite.play(vfxAnim, speed)
	sprite.z_index = GameManager.Z_LAYER_VFX_FRONT
	if layerBack:
		sprite.z_index = GameManager.Z_LAYER_VFX_BACK
	if vfx_pool[vfxAnim].has("vel"): vel = vfx_pool[vfxAnim]["vel"]
	if vfx_pool[vfxAnim].has("lifeTime"): lifeTime = vfx_pool[vfxAnim]["lifeTime"]
	if vfx_pool[vfxAnim].has("friction"): friction = vfx_pool[vfxAnim]["friction"]
	if vfx_pool[vfxAnim].has("alphaFade") and vfx_pool[vfxAnim]["alphaFade"]: alphaFade = vfx_pool[vfxAnim]["lifeTime"]
	
	if frame >= 0:
		sprite.frame = frame
		
func endVfx():
	queue_free()
