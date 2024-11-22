extends Node

var players:Array[Node2D] = []
var enemies:Array[Node2D] = []

const Z_LAYER_UI = 10
const Z_LAYER_VFX_FRONT = 7
const Z_LAYER_TILE_FRONT = 6
const Z_LAYER_PLAYER = 5
const Z_LAYER_ENEMY = 4
const Z_LAYER_BLOCK = 3
const Z_LAYER_VFX_BACK = 2
const Z_LAYER_TILE_BACK = 1

var score_tier = 0
var vfx_score:PackedScene = load("res://effects/Vfx.tscn")
var gameObjectsPaused:bool = false
var deathPlaneY = 32

# Called when the node enters the scene tree for the first time.
func _ready():
	AudioStreamPlayer2D.new()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func addEnemyToPool(subject:Node2D):
	enemies.append(subject)
	
func deleteEnemyFromPool(subject:Node2D):
	if subject in enemies:
		enemies.erase(subject)
		
func createVfx(anim:String, x:float, y:float, layerBack: bool = false, frame:int = -1, speed:float = 1):
	var temp = vfx_score.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	get_tree().root.add_child(temp)
	temp.position.x = x
	temp.position.y = y
	temp.setVFXdata(anim, frame, layerBack, speed)
		
func spawnScore(x:float, y:float):
	createVfx("score", x, y, false, score_tier, 0)
	score_tier += 1
		
func pauseGameObjects(pause:bool, excludePlayers:bool = false):
	gameObjectsPaused = pause
	for i in range(0, len(enemies)):
		if pause:enemies[i].process_mode = Node.PROCESS_MODE_DISABLED
		else: enemies[i].process_mode = Node.PROCESS_MODE_INHERIT
		
	if not excludePlayers:
		for i in range(0, len(players)):
			if pause:players[i].process_mode = Node.PROCESS_MODE_DISABLED
			else: players[i].process_mode = Node.PROCESS_MODE_INHERIT
