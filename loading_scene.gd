extends Node2D

@onready var base_string = "res://base.tscn"
@onready var base_loaded = false
@onready var base_resource

func _ready():
	ResourceLoader.load_threaded_request(base_string)
	
func _physics_process(_delta):
	if base_loaded == false:
		if ResourceLoader.load_threaded_get_status(base_string) == 3:
			base_loaded = true
			base_resource = ResourceLoader.load_threaded_get(base_string)
			var base = base_resource.instantiate()
			add_child(base)
