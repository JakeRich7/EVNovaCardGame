extends Node2D

@onready var menu_layer = $"menu_layer"
@onready var map = $"map"
@onready var music = $"music"
const cards_draw_path = "res://cards_draw"
const cards_ships_path = "res://cards_ships"
@onready var menu_empty = preload("res://menu.tscn")
@onready var ships_all = []
@onready var player_1_deck = []
@onready var player_2_deck = []
@onready var deck_races = ["Pirate", "Alien"]
@onready var player_two_choose = false
@onready var player_two_setup = false
var menu_empty_instance

func _ready():
	# Starts music
	music.playing = true
	# Centers map
	map.position.x += 1278
	map.position.y += 720
	# Creates initial menu
	menu_empty_instance = menu_empty.instantiate()
	menu_layer.add_child(menu_empty_instance)
	# Initializes and places all ships in an array
	var dir = DirAccess.open(cards_ships_path)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tscn") or file_name.ends_with(".scn"):
			var scene_path = cards_ships_path + "/" + file_name
			var packed_scene = load(scene_path)
			var instance = packed_scene.instantiate()
			ships_all.push_back(instance)
		file_name = dir.get_next()
	# Creates menu options to select from for player 1
	create_menu_options()
	
	$"alien_arrow".position.x += 1280
	$"alien_arrow".position.y += 1030
	$"pirate_carrier_5".position.x += 1280
	$"pirate_carrier_5".position.y += 410

func _on_button_pressed(button):
	# Adds all ships to players deck
	var type_to_search
	if button.text == "Pirate": type_to_search = "pirate"
	elif button.text == "Alien": type_to_search = "alien"
	if player_two_choose == true:
		for x in ships_all:
			if x.type == type_to_search:
				player_2_deck.push_back(x)
		player_two_choose = false
	else:
		for x in ships_all:
			if x.type == type_to_search:
				player_1_deck.push_back(x)
		player_two_choose = true
	# Removes option from deck races button list
	for x in range(deck_races.size() - 1, -1, -1):  # Iterate backwards
		if deck_races[x] == button.text:
			deck_races.remove_at(x)
	# Removes all buttons
	for x in menu_empty_instance.get_children():
		x.queue_free()

func _input(event):
	if event.is_action_pressed("escape"):
		get_tree().quit()

func _physics_process(_delta):
	if player_two_choose == true and player_two_setup == false:
		create_menu_options()
		player_two_setup = true
	map_movement_manager()

func create_menu_options():
	for x in deck_races:
		var button = Button.new()
		button.text = x
		button.connect("pressed", Callable(self, "_on_button_pressed").bind(button))
		menu_empty_instance.add_child(button)

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
