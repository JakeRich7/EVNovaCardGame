extends Node

@onready var audio_playing = true
@onready var menu_loaded = preload("res://sounds/nova_loading.wav")
@onready var click_on = preload("res://sounds/nova_click_on.wav")
@onready var click_off = preload("res://sounds/nova_click_off.wav")

@onready var menu_loaded_volume = 0.5
@onready var click_on_volume = 0.7
@onready var click_off_volume = 0.7

@onready var pool_size = 10
@onready var pool = []
@onready var sfx_volume = 0.4

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(pool_size):
		var player = AudioStreamPlayer.new()
		player.volume_db = linear_to_db(sfx_volume)
		player.bus = "SFX"
		player.connect("finished", Callable(self, "_recycle").bind(player))
		add_child(player)
		pool.append(player)

func play_sound(stream, volume):
	if audio_playing:
		var player = _get_available_player()
		player.volume_db = linear_to_db(volume)
		player.stream = get_sfx_resource(stream)
		player.play()
		
func delayed_play_sound(stream, volume):
	if audio_playing:
		await get_tree().create_timer(0.1).timeout
		var player = _get_available_player()
		player.volume_db = linear_to_db(volume)
		player.stream = get_sfx_resource(stream)
		player.play()

func get_sfx_resource(stream):
	if stream == "menu_loaded": return menu_loaded
	elif stream == "click_on": return click_on
	elif stream == "click_off": return click_off

func _get_available_player():
	for player in pool:
		if !player.playing:
			return player
	# If all are in use, create a new one dynamically (optional)
	var new_player = AudioStreamPlayer.new()
	new_player.volume_db = linear_to_db(sfx_volume)
	new_player.bus = "SFX"
	new_player.connect("finished", Callable(self, "_recycle").bind(new_player))
	add_child(new_player)
	pool.append(new_player)
	return new_player

func _recycle(player):
	player.stop()
