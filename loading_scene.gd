extends Node2D

# Constants
@onready var base_string = "res://base.tscn"
@onready var base_loaded = false
@onready var base_resource

# Dynamics
@onready var game_speed = 0.1
@onready var display_mode = "Borderless"
	
func _physics_process(_delta):
	if base_loaded == false:
		ResourceLoader.load_threaded_request(base_string)
		if ResourceLoader.load_threaded_get_status(base_string) == 3:
			base_loaded = true
			base_resource = ResourceLoader.load_threaded_get(base_string)
			var base = base_resource.instantiate()
			add_child(base)
