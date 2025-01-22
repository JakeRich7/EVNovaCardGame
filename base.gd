extends Node2D

@onready var map = $"map"
@onready var music = $"music"

func _ready():
	music.playing = true
	map.position.x += 1278
	map.position.y += 720
	$"alien_arrow".position.x += 1280
	$"alien_arrow".position.y += 1030
	$"pirate_carrier_5".position.x += 1280
	$"pirate_carrier_5".position.y += 410

func _input(event):
	if event.is_action_pressed("escape"):
		get_tree().quit()

func _physics_process(_delta):
	map_movement_manager()

func map_movement_manager():
	var mouse_position = get_viewport().get_mouse_position()
	if mouse_position.x < 10 and mouse_position.y < 10:
		if map.position.x < 1587.5: map.position.x += 5
		if map.position.y < 1587.5: map.position.y += 5
	elif mouse_position.x < 10 and mouse_position.y > 1430:
		if map.position.x < 1587.5: map.position.x += 5
		if map.position.y > -147.5: map.position.y -= 5
	elif mouse_position.x > 2545 and mouse_position.y > 1430:
		if map.position.x > 972.5: map.position.x -= 5
		if map.position.y > -147.5: map.position.y -= 5
	elif mouse_position.x > 2545 and mouse_position.y < 10:
		if map.position.x > 972.5: map.position.x -= 5
		if map.position.y < 1587.5: map.position.y += 5
	elif mouse_position.x < 10:
		if map.position.x < 1587.5: map.position.x += 5
	elif mouse_position.y > 1430:
		if map.position.y > -147.5: map.position.y -= 5
	elif mouse_position.x > 2545:
		if map.position.x > 972.5: map.position.x -= 5
	elif mouse_position.y < 10:
		if map.position.y < 1587.5: map.position.y += 5
