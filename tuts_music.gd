extends Node

var music_player: AudioStreamPlayer

func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	music_player.bus = "Master" 
	music_player.autoplay = false
	music_player.volume_db = 0




func play_music(stream: AudioStream):
	if music_player.stream == stream:
		if not music_player.playing:
			music_player.play(8.0)
		return

	music_player.stream = stream
	music_player.play(8.0)


func stop_music():
	music_player.stop()


func set_volume(db: float):
	music_player.volume_db = db
