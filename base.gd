extends Node2D

# Preload Fighters
@onready var pirate_viper = preload("res://cards_ships/pirate_viper_1.tscn")
@onready var pirate_thunderhead = preload("res://cards_ships/pirate_thunderhead_2.tscn")

@onready var ship_position_1 = Vector2(1280, 1030)
@onready var ship_position_2 = Vector2(1280, 410)
@onready var ship_position_3 = Vector2(850, 1100)
@onready var ship_position_4 = Vector2(850, 340)
@onready var ship_position_5 = Vector2(1710, 1100)
@onready var ship_position_6 = Vector2(1710, 340)
@onready var player_draw_position_1 = Vector2(350, 1030)
@onready var player_draw_position_2 = Vector2(350, 410)
@onready var draw_pile_position = Vector2(2210, 720)
@onready var canvas_layer = $"menu_layer"
@onready var map = $"map"
@onready var music = $"music"
const cards_draw_path = "res://cards_draw"
const cards_ships_path = "res://cards_ships"
@onready var card_back = preload("res://card_back.tscn")
@onready var menu = preload("res://menu.tscn")
@onready var settings = preload("res://settings.tscn")
@onready var draw_deck = []
@onready var draw_deck_reshuffle = []
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
var player_attack_chosen = false
var player_end_turn_signal = false
var order_of_attack_determined = false
@onready var fighters_in_position_3 = 0
@onready var fighters_in_position_4 = 0
@onready var fighters_in_position_5 = 0
@onready var fighters_in_position_6 = 0
var attack_info_name
var attack_info_primary_ship
var player_which_enemy_initialized = false
var player_wins = 0
var end_message_printed = false

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
	if settings_instance.get_node("music").text == "Music ON":
		settings_instance.get_node("music").text = "Music OFF"
	elif settings_instance.get_node("music").text == "Music OFF":
		settings_instance.get_node("music").text = "Music ON"
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
	if battleloop_started == true and player_wins == 0:
		send_active_ship()
		determine_order_of_attack()
		attacks_generator()
		if player_attack_chosen == true and player_which_enemy_initialized == false:
			player_which_enemy()
		if player_end_turn_signal == true:
			player_end_turn()
	else:
		if battleloop_started == true and end_message_printed == false:
			final_win_label()
			print("YAAAYAYAYA!!!! Player ", player_wins, " WINSSSS!!!!")
			end_message_printed = true

func final_win_label():
	var label = Label.new()
	label.text = "Player " + str(player_wins) + " Wins!"
	label.custom_minimum_size = Vector2(350, 120)
	label.add_theme_font_size_override("font_size", 100)
	label.add_theme_color_override("font_color", return_font_color_by_race(attack_info_primary_ship))
	var final_instance = menu.instantiate()
	final_instance.position -= Vector2(25, 300)
	final_instance.add_child(label)
	canvas_layer.add_child(final_instance)

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
		if ships_attacking_this_phase.size() == 0:
			player_end_turn_signal = true
		ships_attacking_this_phase.sort_custom(func(a, b): return a.pursuit > b.pursuit)
		order_of_attack_determined = true

func attack_chosen(attack_button, active_ship):
	for x in active_ship.attacks:
		if x.button_name == attack_button.text:
			player_attack_chosen = true
			attack_info_name = attack_button.text
			attack_info_primary_ship = active_ship

func player_which_enemy():
	if check_for_fighter_launch():
		attack(return_enemy_single_ship_name())
	elif enemy_has_multiple_ships():
		if menu_attacks:
			for x in menu_attacks.get_children():
				x.queue_free()
		var unique_enemies_to_attack = return_unique_enemies()
		for i in range(unique_enemies_to_attack.size()):
			var attack_button_instance = Button.new()
			attack_button_instance.connect("pressed", Callable(self, "attack").bind(unique_enemies_to_attack[i]))
			attack_button_instance.custom_minimum_size = Vector2(250, 80)
			attack_button_instance.add_theme_font_size_override("font_size", 50)
			attack_button_instance.add_theme_color_override("font_color", return_font_color_by_race(attack_info_primary_ship))
			attack_button_instance.text = unique_enemies_to_attack[i]
			menu_attacks.add_child(attack_button_instance)
		player_which_enemy_initialized = true
	else:
		attack(return_enemy_single_ship_name())
		
func check_for_fighter_launch():
	for x in attack_info_primary_ship.attacks:
		if x.button_name == attack_info_name:
			if x.armor == null:
				return true
	return false

func return_unique_enemies():
	var unique_enemies = []
	if attack_info_primary_ship.ship_position == 1 or attack_info_primary_ship.ship_position == 3 or attack_info_primary_ship.ship_position == 5:
		for x in player_two_active_ships:
			var name_match = false
			for y in unique_enemies:
				if x.ship_button_name == y:
					name_match = true
			if name_match == false:
				unique_enemies.push_back(x.ship_button_name)
	else:
		for x in player_one_active_ships:
			var name_match = false
			for y in unique_enemies:
				if x.ship_button_name == y:
					name_match = true
			if name_match == false:
				unique_enemies.push_back(x.ship_button_name)
	return unique_enemies

func return_enemy_single_ship_name():
	if attack_info_primary_ship.ship_position == 1 or attack_info_primary_ship.ship_position == 3 or attack_info_primary_ship.ship_position == 5:
		return player_two_active_ships[0].ship_button_name
	else:
		return player_one_active_ships[0].ship_button_name
			
func enemy_has_multiple_ships():
	var first_ship_name
	if attack_info_primary_ship.ship_position == 1 or attack_info_primary_ship.ship_position == 3 or attack_info_primary_ship.ship_position == 5:
		if player_two_active_ships.size() > 1:
			first_ship_name = player_two_active_ships[0].ship_name
			for x in player_two_active_ships:
				if x.ship_name != first_ship_name:
					return true
	else:
		if player_one_active_ships.size() > 1:
			first_ship_name = player_one_active_ships[0].ship_name
			for x in player_one_active_ships:
				if x.ship_name != first_ship_name:
					return true
	return false

func attack(enemy_ship_name):
	var enemy_ship = return_first_instance_of_enemy_ship_name(enemy_ship_name)
	for x in attack_info_primary_ship.attacks:
		if x.button_name == attack_info_name:
			# Identifies Fighters
			if x.armor == null:
				launch_fighters(x, attack_info_primary_ship.ship_position)
			# Identifies Missiles
			elif x.pursuit != null:
				if x.pursuit + draw_a_card() >= enemy_ship.escape + draw_a_card():
					attack_hit(x, enemy_ship)
				x.ammo -= 1
			else:
				attack_hit(x, enemy_ship)
	player_end_turn_signal = true

func attack_hit(attack_details, enemy_ship):
	# Identifies Armor ONLY Attacks
	if attack_details.shield != null:
		# Identifies all other Attacks
		if enemy_ship.shield > 0:
			if attack_details.shield + draw_a_card() >= enemy_ship.shield + draw_a_card():
				shield_down(enemy_ship)
		else:
			if attack_details.armor + draw_a_card() >= enemy_ship.armor + draw_a_card():
				armor_down(enemy_ship)
	else:
		if attack_details.armor + draw_a_card() >= enemy_ship.armor + draw_a_card():
			armor_down(enemy_ship)
			
func shield_down(enemy_ship):
	enemy_ship.shield = 0
	blink_manager(enemy_ship, true)

func armor_down(enemy_ship):
	if enemy_ship.ship_position == 2 or enemy_ship.ship_position == 4 or enemy_ship.ship_position == 6:
		for x in player_two_active_ships:
			if x.ship_name == enemy_ship.ship_name:
				var index = player_two_active_ships.find(x)
				player_two_active_ships.pop_at(index)
				var index_attacking = ships_attacking_this_phase.find(x)
				ships_attacking_this_phase.pop_at(index_attacking)
				break
	else:
		for x in player_one_active_ships:
			if x.ship_name == enemy_ship.ship_name:
				var index = player_one_active_ships.find(x)
				player_one_active_ships.pop_at(index)
				var index_attacking = ships_attacking_this_phase.find(x)
				ships_attacking_this_phase.pop_at(index_attacking)
				break
	blink_manager(enemy_ship, false)
	remove_child(enemy_ship)

func blink_manager(enemy_ship, toggle):
	if enemy_ship.ship_position == 3 or enemy_ship.ship_position == 5:
		for x in player_one_active_ships:
			if enemy_ship.ship_button_name == x.ship_button_name:
				x.blink(toggle)
	elif enemy_ship.ship_position == 4 or enemy_ship.ship_position == 6:
		for x in player_two_active_ships:
			if enemy_ship.ship_button_name == x.ship_button_name:
				x.blink(toggle)
	else:
		enemy_ship.blink(toggle)
				
func draw_a_card():
	if draw_deck.size() == 0:
		for x in draw_deck_reshuffle:
			remove_child(x)
		draw_deck.append_array(draw_deck_reshuffle)
		draw_deck_reshuffle.clear()
	var index = randi() % draw_deck.size()
	var element = draw_deck.pop_at(index)
	element.position = draw_pile_position
	add_child(element)
	draw_deck_reshuffle.push_back(element)
	return element.value

func return_first_instance_of_enemy_ship_name(enemy_ship_name):
	if attack_info_primary_ship.ship_position == 1 or attack_info_primary_ship.ship_position == 3 or attack_info_primary_ship.ship_position == 5:
		for x in player_two_active_ships:
			if x.ship_button_name == enemy_ship_name:
				return x
	else:
		for x in player_one_active_ships:
			if x.ship_button_name == enemy_ship_name:
				return x

func player_end_turn():
	if menu_attacks != null:
		for x in menu_attacks.get_children():
			x.queue_free()
	if ships_attacking_this_phase.size() > 0:
		ships_attacking_this_phase.pop_front()
		if ships_attacking_this_phase.size() == 0:
			phase_switch()
	else:
		phase_switch()
	attacks_generated = false
	player_attack_chosen = false
	player_which_enemy_initialized = false
	player_end_turn_signal = false

func launch_fighters(attack_selected, active_ship_position):
	var ship_group_to_join
	var position_to_spawn
	var ship_position = 0
	if active_ship_position == 1:
		ship_group_to_join = player_one_active_ships
		if ship_group_to_join.size() == 1:
			ship_position = 3
			position_to_spawn = ship_position_3
		else:
			ship_position = 5
			position_to_spawn = ship_position_5
	else:
		ship_group_to_join = player_two_active_ships
		if ship_group_to_join.size() == 1:
			ship_position = 4
			position_to_spawn = ship_position_4
		else:
			ship_position = 6
			position_to_spawn = ship_position_6
	for x in attack_selected.ammo:
		var fighter_instance = fighter_return_instance(attack_selected.button_name)
		fighter_instance.ship_position = ship_position
		ship_group_to_join.push_back(fighter_instance)
		fighter_instance.position = position_to_spawn
		add_child(fighter_instance)
		fighter_adjust_counters(ship_position)
	attack_selected.ammo = 0

func fighter_adjust_counters(ship_position):
	var menu_to_show
	if ship_position == 3:
		fighters_in_position_3 += 1
		menu_to_show = $"menu_layer/player_three_counter"
		menu_to_show.text = "x" + str(fighters_in_position_3)
	elif ship_position == 4:
		fighters_in_position_4 += 1
		menu_to_show = $"menu_layer/player_four_counter"
		menu_to_show.text = "x" + str(fighters_in_position_4)
	elif ship_position == 5:
		fighters_in_position_5 += 1
		menu_to_show = $"menu_layer/player_five_counter"
		menu_to_show.text = "x" + str(fighters_in_position_5)
	elif ship_position == 6:
		fighters_in_position_6 += 1
		menu_to_show = $"menu_layer/player_six_counter"
		menu_to_show.text = "x" + str(fighters_in_position_6)
	menu_to_show.visible = true

func fighter_return_instance(fighter):
	if fighter == "Pirate Vipers":
		return pirate_viper.instantiate()
	elif fighter == "Pirate Thunderheads":
		return pirate_thunderhead.instantiate()

func attacks_generator():
	if attacks_generated == false and ships_attacking_this_phase.size() > 0:
		attacks_generated = true
		var active_ship = ships_attacking_this_phase[0]
		var ship_map_position = active_ship.ship_position
		determine_menu(ship_map_position)
		for x in active_ship.attacks:
			if x.phase == current_phase:
				# Perfect gate for determining proper items for attack menu
				if x.ammo != 0:
					var attack_button_instance = Button.new()
					attack_button_instance.connect("pressed", Callable(self, "attack_chosen").bind(attack_button_instance, active_ship))
					attack_button_instance.custom_minimum_size = Vector2(250, 80)
					attack_button_instance.add_theme_font_size_override("font_size", 50)
					attack_button_instance.add_theme_color_override("font_color", return_font_color_by_race(active_ship))
					attack_button_instance.text = x.button_name
					menu_attacks.add_child(attack_button_instance)
		if menu_attacks.get_child_count() == 0:
			player_end_turn_signal = true
		
func return_font_color_by_race(active_ship):
	if active_ship.type == "alien": return "#FFD700"
	elif active_ship.type == "auroran": return "#8B4513"
	elif active_ship.type == "federation": return "#4682B4"
	elif active_ship.type == "pirate": return "#D88B5E"
	elif active_ship.type == "polaris": return "#D8BFD8"
	elif active_ship.type == "rebel": return "#228B22"
	elif active_ship.type == "trader": return "#A9A9A9"
		
func determine_menu(ship_map_position):
	if ship_map_position == 1:
		menu_attacks = $"menu_layer/player_one_attacks_menu"
	elif ship_map_position == 2:
		menu_attacks = $"menu_layer/player_two_attacks_menu"
	elif ship_map_position == 3:
		menu_attacks = $"menu_layer/player_three_attacks_menu"
	elif ship_map_position == 4:
		menu_attacks = $"menu_layer/player_four_attacks_menu"
	elif ship_map_position == 5:
		menu_attacks = $"menu_layer/player_five_attacks_menu"
	elif ship_map_position == 6:
		menu_attacks = $"menu_layer/player_six_attacks_menu"

func phase_switch():
	if current_phase < 5:
		current_phase += 1
	else:
		current_phase = 1
	ships_attacking_this_phase.clear()
	order_of_attack_determined = false

func offset_attacks_menus():	
	var menu_1 = $"menu_layer/player_one_attacks_menu"
	var menu_2 = $"menu_layer/player_two_attacks_menu"
	var menu_3 = $"menu_layer/player_three_attacks_menu"
	var menu_4 = $"menu_layer/player_four_attacks_menu"
	var menu_5 = $"menu_layer/player_five_attacks_menu"
	var menu_6 = $"menu_layer/player_six_attacks_menu"
	var menus_to_offset = [menu_1, menu_2, menu_3, menu_4, menu_5, menu_6]
	for menu_to_offset in menus_to_offset:
		if menu_to_offset.get_child_count() == 2:
			menu_to_offset.get_node("Button").queue_free()
			menu_to_offset.get_node("Button2").queue_free()
			menu_to_offset.position.y += 330
		
func send_active_ship():
	if player_one_active_ships.size() == 0:
		if player_1_deck.size() > 0:
			var index = randi() % player_1_deck.size()
			player_one_active_ships.push_back(player_1_deck.pop_at(index))
			var player_one_main_ship = player_one_active_ships[0]
			player_one_main_ship.ship_position = 1
			player_one_main_ship.position = ship_position_1
			add_child(player_one_main_ship)
			if player_1_deck.size() == 0:
				player_one_draw_pile.queue_free()
			if player_one_active_ships.size() > 0 and player_two_active_ships.size() > 0:
				reset_phase()
		else:
			player_wins = 2
	if player_two_active_ships.size() == 0:
		if player_2_deck.size() > 0:
			var index = randi() % player_2_deck.size()
			player_two_active_ships.push_back(player_2_deck.pop_at(index))
			var player_two_main_ship = player_two_active_ships[0]
			player_two_main_ship.ship_position = 2
			player_two_main_ship.position = ship_position_2
			add_child(player_two_main_ship)
			if player_2_deck.size() == 0:
				player_two_draw_pile.queue_free()
			if player_one_active_ships.size() > 0 and player_two_active_ships.size() > 0:
				reset_phase()
		else:
			player_wins = 1
	# This accounts allows the game to continue if neither ship has any attacks
	if player_one_active_ships[0].attacks.size() == 0 and player_two_active_ships[0].attacks.size() == 0:
		print("Neither ship has any attacks! They crashed and were both destroyed...")
		
func reset_phase():
	current_phase = 1
	
func setup_battlefield():
	if battlefield_setup == false and players_done_choosing == true:
		player_one_draw_pile = card_back.instantiate()
		player_one_draw_pile.position += player_draw_position_1
		add_child(player_one_draw_pile)
		player_two_draw_pile = card_back.instantiate()
		player_two_draw_pile.position += player_draw_position_2
		add_child(player_two_draw_pile)
		draw_pile = card_back.instantiate()
		draw_pile.position += draw_pile_position
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
