extends Node2D

# Preload Fighter
@onready var pirate_viper = preload("res://cards_ships/pirate_viper_1.tscn")
@onready var pirate_thunderhead = preload("res://cards_ships/pirate_thunderhead_2.tscn")

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
@onready var attacks_generated = false
var current_phase = 1
var menu_attacks
var player_end_turn_signal = false
var order_of_attack_determined = false

func _ready():
	# Position attack menus
	offset_attacks_menus()
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
		print("Phase", " ", current_phase)
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
		if ships_attacking_this_phase.size() == 0:
			player_end_turn_signal = true
		ships_attacking_this_phase.sort_custom(func(a, b): return a.pursuit > b.pursuit)
		order_of_attack_determined = true

func attack_chosen(attack_button, active_ship, active_ship_position):
	for x in active_ship.attacks:
		if x.button_name == attack_button.text:
			player_end_turn_signal = true
			if x.armor == null:
				launch_fighters(x, active_ship_position)

func launch_fighters(attack, active_ship_position):
	var ship_group_to_join
	var position_to_spawn
	if active_ship_position == 1:
		ship_group_to_join = player_one_active_ships
		if ship_group_to_join.size() == 1: position_to_spawn = Vector2(328, 1203)
		else: position_to_spawn = Vector2(1828, 1203)
	else:
		ship_group_to_join = player_two_active_ships
		if ship_group_to_join.size() == 1: position_to_spawn = Vector2(328, 303)
		else: position_to_spawn = Vector2(1828, 303)
	for x in attack.ammo:
		var fighter_instance = fighter_return_instance(attack.button_name)
		ship_group_to_join.push_back(fighter_instance)
		fighter_instance.position = position_to_spawn
		add_child(fighter_instance)
		print(attack.button_name, " ", "Launched!")
	attack.ammo = 0

func fighter_return_instance(fighter):
	if fighter == "Pirate Vipers":
		return pirate_viper.instantiate()
	elif fighter == "Pirate Thunderheads":
		return pirate_thunderhead.instantiate()

func attacks_generator():
	if attacks_generated == false and ships_attacking_this_phase.size() > 0:
		attacks_generated = true
		var active_ship = ships_attacking_this_phase[0]
		var ship_map_position = determine_ship_position(active_ship)
		determine_menu(ship_map_position)
		for x in active_ship.attacks:
			if x.phase == current_phase:
				# Perfect gate for determining proper items for attack menu
				if x.ammo != 0:
					var attack_button_instance = Button.new()
					attack_button_instance.connect("pressed", Callable(self, "attack_chosen").bind(attack_button_instance, active_ship, ship_map_position))
					attack_button_instance.custom_minimum_size = Vector2(250, 80)
					attack_button_instance.add_theme_font_size_override("font_size", 50)
					attack_button_instance.text = x.button_name
					menu_attacks.add_child(attack_button_instance)
		if menu_attacks.get_child_count() == 0:
			player_end_turn_signal = true
		
func determine_ship_position(active_ship):
	for x in player_one_active_ships:
		if active_ship == x:
			return 1
	for x in player_two_active_ships:
		if active_ship == x:
			return 2
		
func determine_menu(ship_map_position):
	if ship_map_position == 1:
		menu_attacks = $"menu_layer/player_one_attacks_menu"
	if ship_map_position == 2:
		menu_attacks = $"menu_layer/player_two_attacks_menu"
		
func player_end_turn():
	if menu_attacks:
		for x in menu_attacks.get_children():
			x.queue_free()
	if ships_attacking_this_phase.size() > 0:
		ships_attacking_this_phase.pop_front()
		if ships_attacking_this_phase.size() == 0:
			phase_switch()
	else:
		phase_switch()
	attacks_generated = false
	player_end_turn_signal = false

func phase_switch():
	if current_phase < 5:
		current_phase += 1
	else:
		current_phase = 1
	order_of_attack_determined = false

func offset_attacks_menus():	
	var menu_1 = $"menu_layer/player_one_attacks_menu"
	var menu_2 = $"menu_layer/player_two_attacks_menu"
	var menus_to_offset = [menu_1, menu_2]
	for menu_to_offset in menus_to_offset:
		if menu_to_offset.get_child_count() == 2:
			menu_to_offset.get_node("Button").queue_free()
			menu_to_offset.get_node("Button2").queue_free()
			menu_to_offset.position.y += 330
		
func send_active_ship():
	if player_one_active_ships.size() == 0:
		if player_1_deck.size() > 0:
			#var index = randi() % player_1_deck.size()
			var index = 0
			player_one_active_ships.push_back(player_1_deck.pop_at(index))
			var player_one_main_ship = player_one_active_ships[0]
			player_one_main_ship.position = Vector2(1280, 1030)
			add_child(player_one_main_ship)
			if player_1_deck.size() == 0:
				player_one_draw_pile.queue_free()
			if player_one_active_ships.size() > 0 and player_two_active_ships.size() > 0:
				reset_phase()
		else:
			print("Player 2 Wins!!")
	if player_two_active_ships.size() == 0:
		if player_2_deck.size() > 0:
			#var index = randi() % player_2_deck.size()
			var index = 0
			player_two_active_ships.push_back(player_2_deck.pop_at(index))
			var player_two_main_ship = player_two_active_ships[0]
			player_two_main_ship.position = Vector2(1280, 410)
			add_child(player_two_main_ship)
			if player_2_deck.size() == 0:
				player_two_draw_pile.queue_free()
			if player_one_active_ships.size() > 0 and player_two_active_ships.size() > 0:
				reset_phase()
		else:
			print("Player 1 Wins!!")
	
func reset_phase():
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
