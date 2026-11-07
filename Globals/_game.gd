extends Node

var post_ready_fired := false #To execute code after all other nodes finished loading
var player_light_ref : CoopPlayer #Set by the players
var player_dark_ref : CoopPlayer

func _process(delta):
	if(!post_ready_fired):
		post_ready()
		post_ready_fired = true

func post_ready():
	player_dark_ref.configure(self)
	player_light_ref.configure(self)
