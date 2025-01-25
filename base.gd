extends Node2D

@onready var canvas_layer = $"menu_layer"
@onready var map = $"map"
@onready var music = $"music"
const cards_draw_path = "res://cards_draw"
const cards_ships_path = "res://cards_ships"
@onready var card_back = preload("res://card_back.tscn")
@onready var menu = preload("res://menu.tscn")
@onready var settings = preload("res://settings.tscn")
@onready var draw_deck = []
@onready var ships_all = []
@onready var player_1_deck = []
@onready var player_2_deck = []
@onready var deck_races = ["Pirate", "Alien"]
@onready var player_two_choose = false
@onready var player_two_setup = false
@onready var battlefield_setup = false
@onready var players_done_choosing = false
@onready var battleloop_started = false
var menu_instance
var settings_instance
var player_one_draw_pile
var player_two_draw_pile
var draw_pile
@onready var player_one_active_ships = []
@onready var player_two_active_ships = []
@onready var ships_attacking_this_phase = []
@onready var player_turn = 1
@onready var attacks_generated = false
var current_phase = 1
var menu_attacks_p1
var menu_attacks_p1_offset_to_fix = 0
var menu_attacks_p2
var menu_attacks_p2_offset_to_fix = 0
var player_end_turn_signal = false
var order_of_attack_determined = false

func _ready():
	# Starts music
	music.playing = true
	# Centers map
	map.position.x += 1278
	map.position.y += 720
	# Creates initial menu
	menu_instance = menu.instantiate()
	canvas_layer.add_child(menu_instance)
	# Creates settings menu
	settings_instance = settings.instantiate()
	settings_instance.hide()
	canvas_layer.add_child(settings_instance)
	# Creates settings menu listeners
	settings_instance.get_node("music").pressed.connect(_on_music_pressed)
	settings_instance.get_node("quit").pressed.connect(_on_quit_pressed)
	# Initializes and places all draw cards in deck
	var dir_deck = DirAccess.open(cards_draw_path)
	dir_deck.list_dir_begin()
	var file_name_deck = dir_deck.get_next()
	while file_name_deck != "":
		if file_name_deck.ends_with(".tscn") or file_name_deck.ends_with(".scn"):
			var scene_path = cards_draw_path + "/" + file_name_deck
			var packed_scene = load(scene_path)
			var instance = packed_scene.instantiate()
			draw_deck.push_back(instance)
		file_name_deck = dir_deck.get_next()
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
		players_done_choosing = true
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
	for x in menu_instance.get_children():
		x.queue_free()

func _on_music_pressed():
	music.playing = !music.playing
	
func _on_quit_pressed():
	get_tree().quit()

func _input(event):
	if event.is_action_pressed("escape"):
		if menu_instance.get_child_count() == 0:
			if settings_instance.visible:
				settings_instance.hide()
			else:
				settings_instance.show()

func _physics_process(_delta):
	map_movement_manager()
	player_setup_manager()
	setup_battlefield()
	battleloop()
	
func battleloop():
	if battleloop_started == true:
		send_active_ship()
		determine_order_of_attack()
		attacks_generator()
		if player_end_turn_signal == true:
			player_end_turn()

func determine_order_of_attack():
	if order_of_attack_determined == false:
		for x in player_one_active_ships:
				var ship_attacking = false
				for y in x.attacks:
					if ship_attacking == false:
						if y.phase == current_phase:
							ships_attacking_this_phase.push_back(x)
							ship_attacking = true
		for x in player_two_active_ships:
				var ship_attacking = false
				for y in x.attacks:
					if ship_attacking == false:
						if y.phase == current_phase:
							ships_attacking_this_phase.push_back(x)
							ship_attacking = true
		# Anonymous lambda function to sort by pursuit speed
		ships_attacking_this_phase.sort_custom(func(a, b): return a.pursuit < b.pursuit)
		order_of_attack_determined = true

func attack_chosen(attack_button, active_ship):
	for x in active_ship.attacks:
		if x.button_name == attack_button.text:
			player_end_turn_signal = true
			#print(x.button_name, " ", x.shield, " ", x.armor)

func attacks_generator():
	if attacks_generated == false:
		attacks_generated = true
		var active_ship = player_one_active_ships[0]
		menu_attacks_p1 = $"menu_layer/player_one_attacks_menu"
		for x in active_ship.attacks:
			if x.phase == current_phase:
				var attack_button_instance = Button.new()
				attack_button_instance.connect("pressed", Callable(self, "attack_chosen").bind(attack_button_instance, active_ship))
				attack_button_instance.custom_minimum_size = Vector2(250, 80)
				attack_button_instance.add_theme_font_size_override("font_size", 50)
				attack_button_instance.text = x.button_name
				menu_attacks_p1.add_child(attack_button_instance)
		offset_attacks_menu_by_number_of_attacks(menu_attacks_p1)
		if menu_attacks_p1.get_child_count() == 0:
			player_end_turn_signal = true
		
func player_end_turn():
	attacks_generated = false
	player_end_turn_signal = false
	order_of_attack_determined = false

func phase_switch():
	if current_phase < 5:
		current_phase += 1
	else:
		current_phase = 1

func offset_attacks_menu_by_number_of_attacks(menu_attacks):
	if player_turn == 1:
		if menu_attacks.get_child_count() > 0:
			menu_attacks.position.y += 297
			menu_attacks_p1_offset_to_fix = 297
	elif player_turn == 2:
		if menu_attacks.get_child_count() > 0:
			menu_attacks.position.y += 297
			menu_attacks_p2_offset_to_fix = 297
		
func send_active_ship():
	if player_one_active_ships.size() == 0:
		if player_1_deck.size() > 0:
			var index = randi() % player_1_deck.size()
			player_one_active_ships.push_back(player_1_deck.pop_at(index))
			var player_one_main_ship = player_one_active_ships[0]
			player_one_main_ship.position = Vector2(1280, 1030)
			add_child(player_one_main_ship)
			if player_1_deck.size() == 0:
				player_one_draw_pile.queue_free()
			if player_one_active_ships.size() > 0 and player_two_active_ships.size() > 0:
				determine_first_player_and_reset_phase()
		else:
			print("Player 2 Wins!!")
	if player_two_active_ships.size() == 0:
		if player_2_deck.size() > 0:
			var index = randi() % player_2_deck.size()
			player_two_active_ships.push_back(player_2_deck.pop_at(index))
			var player_two_main_ship = player_two_active_ships[0]
			player_two_main_ship.position = Vector2(1280, 410)
			add_child(player_two_main_ship)
			if player_2_deck.size() == 0:
				player_two_draw_pile.queue_free()
			if player_one_active_ships.size() > 0 and player_two_active_ships.size() > 0:
				determine_first_player_and_reset_phase()
		else:
			print("Player 1 Wins!!")
	
func determine_first_player_and_reset_phase():
	var player_one_main_ship = player_one_active_ships[0]
	var player_two_main_ship = player_two_active_ships[0]
	if player_one_main_ship.pursuit >= player_two_main_ship.pursuit:
		player_turn = 1
	else:
		player_turn = 2
	current_phase = 1
	
func setup_battlefield():
	if battlefield_setup == false and players_done_choosing == true:
		player_one_draw_pile = card_back.instantiate()
		player_one_draw_pile.position.x += 350
		player_one_draw_pile.position.y += 1030
		add_child(player_one_draw_pile)
		player_two_draw_pile = card_back.instantiate()
		player_two_draw_pile.position.x += 350
		player_two_draw_pile.position.y += 410
		add_child(player_two_draw_pile)
		draw_pile = card_back.instantiate()
		draw_pile.position.x += 1820
		draw_pile.position.y += 720
		add_child(draw_pile)
		battlefield_setup = true
		battleloop_started = true

func player_setup_manager():
	if player_two_choose == true and player_two_setup == false:
		# Creates menu options to select from for player 2
		create_menu_options()
		player_two_setup = true

func create_menu_options():
	for x in deck_races:
		var button = Button.new()
		button.text = x
		button.custom_minimum_size = Vector2(350, 120)
		button.add_theme_font_size_override("font_size", 75)
		button.connect("pressed", Callable(self, "_on_button_pressed").bind(button))
		menu_instance.add_child(button)

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
