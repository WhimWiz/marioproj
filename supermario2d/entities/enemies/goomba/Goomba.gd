extends "res://entities/enemies/enemy.gd"

var STATE_WALK = 0
var STATE_STOMPED = 1

func _ready():
	state_stats = {
		STATE_WALK: {"initialAnim": "walk", "walking": true},
		STATE_STOMPED: {"initialAnim": "stomped", "walking": false}
	}
	anim_nextAnimPool = {
		"turn": "walk",
		"stomped": "kill"
	}
	super._ready()
	
func onStomp(player:Node2D):
	GameManager.createVfx("smoke2", position.x, position.y)
	GameManager.spawnScore(position.x, position.y)
	AudioManager.play_sound(sound_pool["bounce"])
	super.onStomp(player)
	toState(STATE_STOMPED, "stomped")
	gravity_enabled = false
	startDeath(false)
	
