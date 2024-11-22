extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func play_sound(audio_stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0):
	# Create an AudioStreamPlayer node
	var audio_player:AudioStreamPlayer = AudioStreamPlayer.new()
	audio_player.stream = audio_stream
	audio_player.volume_db = volume_db
	audio_player.pitch_scale = pitch_scale

	# Add the AudioStreamPlayer to the scene tree (to play the sound)
	get_tree().root.add_child(audio_player)
	
	# Connect the finished signal to automatically remove the player when done
	audio_player.connect("finished", audio_player.queue_free)
	
	# Play the sound
	audio_player.play()
