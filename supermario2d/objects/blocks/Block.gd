extends StaticBody2D

@onready var sprite:AnimatedSprite2D = get_node("Sprite")
@onready var collisionBox:CollisionShape2D = get_node("CollisionShape")

const STATE_IDLE = 0
const STATE_TRIGGERED = 1
const STATE_DESTROYED = 2

var state = 0
var bump_rate = 15
var bump_wave = 0
var hitDirecMulti = 1
const BUMP_MULTI = 6
const BUMP_GROWTH = 0.25

@export var triggerLimit = -1
@export var isContainer:bool = true
@export var containedItem:PackedScene = null
@export var destroyOnTrigger:bool = false
@export var destroyVFX:String = ""
var dispenseSound = preload("res://entities/player/sfx/hurt.wav")

func _ready():
	sprite.z_index = GameManager.Z_LAYER_BLOCK

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if state == STATE_TRIGGERED:
		bump_wave += bump_rate * delta
		sprite.position.y = (-sin(bump_wave) * BUMP_MULTI) * hitDirecMulti
		sprite.scale.x = 1 + abs(sprite.position.y / BUMP_MULTI) * BUMP_GROWTH
		sprite.scale.y = sprite.scale.x
		if bump_wave >= PI:
			if triggerLimit > 0:
				triggerLimit -= 1
				if triggerLimit == 0:
					sprite.play("empty")
			sprite.position.y = 0
			sprite.scale.x = 1
			sprite.scale.y = 1
			bump_wave = 0
			if containedItem != null:
				dispenseItem()
			sprite.z_index = GameManager.Z_LAYER_BLOCK
			state = STATE_IDLE
		
func block_trigger(hitFromTop:bool = false):
	if destroyOnTrigger:
		block_destroy()
		return
		
	if state == STATE_TRIGGERED or triggerLimit == 0:
		return
		
	if hitFromTop: hitDirecMulti = -1
	else: hitDirecMulti = 1
		
	if isContainer and containedItem == null:
		GameManager.createVfx("block_coin", position.x, position.y, -1, 1, true)
		AudioManager.play_sound(load("res://objects/coins/coin.wav"))
		
	var enemies = GameManager.enemies
	for i in range(0, len(enemies)):
		if enemies[i].checkHitboxColl(position + Vector2.UP * 8, Vector2(1, 0.0625)):
			enemies[i].startDeath(true, position.x)
	
	sprite.z_index = GameManager.Z_LAYER_TILE_FRONT
	state = STATE_TRIGGERED
	
func dispenseItem():
	AudioManager.play_sound(dispenseSound)
	var temp = containedItem.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	get_tree().root.add_child(temp)
	temp.position.x = position.x
	temp.position.y = position.y
	temp.setSpawn(Vector2(position.x, position.y - (16 - 8 * (temp.boxScaleY - 1)) * hitDirecMulti), false)
	temp.onSpawnDirect()
	
func block_destroy(vfx:String = destroyVFX):
	if vfx != "":
		GameManager.createVfx(vfx, position.x, position.y)
	sprite.visible = false
	collisionBox.disabled = true
	state = STATE_DESTROYED
	
