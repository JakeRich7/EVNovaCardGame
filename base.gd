extends Node2D

# Preload Fighters
@onready var thunderhead = preload("res://cards_ships/E-03 Event Auroran Incursion-Thunderhead Heavy Fighter.tscn")
@onready var pirate_viper = preload("res://cards_ships/M-R-23 Capture Commander Krane-Pirate Viper.tscn")
@onready var pirate_thunderhead = preload("res://cards_ships/M-SS-3 Sigma Shipyards 02a-Pirate Thunderhead.tscn")
@onready var firebird = preload("res://cards_ships/M-A-11 Start Dechtakars Service-Auroran Firebird Thamgir.tscn")
@onready var phoenix = preload("res://cards_ships/P-A-15 Eguit-Aur Phoenix Va Thamgiir.tscn")
@onready var viper = preload("res://cards_ships/M-F-18 Scout Moash Space-Federation Viper.tscn")
@onready var anaconda = preload("res://cards_ships/M-F-08 Bring in Dissident-Federation Anaconda.tscn")
@onready var rebel_viper = preload("res://cards_ships/M-R-05 Rescue Rebel Operative-Rebel Viper.tscn")
@onready var manta = preload("res://cards_ships/M-P-09 Take Muhari to Port Kane-Polaris Manta.tscn")

# Constants
@onready var player_one_deck_counter = $"menu_layer/player_one_deck_counter"
@onready var player_two_deck_counter = $"menu_layer/player_two_deck_counter"
@onready var menu_1 = $"menu_layer/player_one_attacks_menu"
@onready var menu_2 = $"menu_layer/player_two_attacks_menu"
@onready var menu_3 = $"menu_layer/player_three_attacks_menu"
@onready var menu_4 = $"menu_layer/player_four_attacks_menu"
@onready var menu_5 = $"menu_layer/player_five_attacks_menu"
@onready var menu_6 = $"menu_layer/player_six_attacks_menu"
@onready var menu_counter_three = $"menu_layer/player_three_counter"
@onready var menu_counter_four = $"menu_layer/player_four_counter"
@onready var menu_counter_five = $"menu_layer/player_five_counter"
@onready var menu_counter_six = $"menu_layer/player_six_counter"
@onready var canvas_layer = $"menu_layer"
@onready var map = $"map"
@onready var music = get_parent().get_node("music")
@onready var ship_position_1 = Vector2(1280, 1030)
@onready var ship_position_2 = Vector2(1280, 410)
@onready var ship_position_3 = Vector2(850, 1100)
@onready var ship_position_4 = Vector2(850, 340)
@onready var ship_position_5 = Vector2(1710, 1100)
@onready var ship_position_6 = Vector2(1710, 340)
@onready var player_draw_position_1 = Vector2(350, 1030)
@onready var player_draw_position_2 = Vector2(350, 410)
@onready var draw_pile_position = Vector2(2210, 720)
const cards_draw_path = "res://cards_draw"
const cards_ships_path = "res://cards_ships"

# Dynamics
@onready var player_one_deck_count = 0
@onready var player_two_deck_count = 0
@onready var card_back = preload("res://card_back.tscn")
@onready var menu = preload("res://menu.tscn")
@onready var settings = preload("res://settings.tscn")
@onready var deck_races = ["Alien", "Auroran", "Federation", "Pirate", "Polaris", "Rebel", "Trader"]
@onready var draw_deck = []
@onready var draw_deck_reshuffle = []
@onready var ships_all = []
@onready var player_1_deck = []
@onready var player_2_deck = []
@onready var player_one_choose = false
@onready var player_one_setup = false
@onready var player_two_choose = false
@onready var player_two_setup = false
@onready var battlefield_setup = false
@onready var players_done_choosing = false
@onready var battleloop_started = false
@onready var player_one_active_ships = []
@onready var player_two_active_ships = []
@onready var ships_attacking_this_phase = []
@onready var attacks_generated = false
@onready var fighters_in_position_3 = 0
@onready var fighters_in_position_4 = 0
@onready var fighters_in_position_5 = 0
@onready var fighters_in_position_6 = 0
var current_phase = 1
var player_attack_chosen = false
var player_end_turn_signal = false
var order_of_attack_determined = false
var player_which_enemy_initialized = false
var player_wins = 0
var end_message_printed = false
var button_held = false
var repeat_timer = 0.0
var secondary_cards_to_remove_1 = []
var secondary_cards_to_remove_2 = []
var menu_instance
var settings_instance
var player_one_draw_pile
var player_two_draw_pile
var draw_pile_1
var draw_pile_2
var menu_attacks
var attack_info_name
var attack_info_primary_ship
var game_type = null

func _ready():
	# Position attack menus
	offset_attacks_menus()
	# Centers map
	map.position.x += 1278
	map.position.y += 720
	# Creates initial menu
	menu_instance = menu.instantiate()
	menu_instance.position.x -= 25
	menu_instance.position.y -= 5
	canvas_layer.add_child(menu_instance)
	# Creates settings menu
	settings_instance = settings.instantiate()
	settings_instance.hide()
	canvas_layer.add_child(settings_instance)
	# Creates settings menu listeners
	settings_instance.get_node("music").pressed.connect(_on_music_pressed)
	settings_instance.get_node("audio").pressed.connect(_on_audio_pressed)
	settings_instance.get_node("display").pressed.connect(_on_display_pressed)
	settings_instance.get_node("speed").pressed.connect(_on_speed_pressed)
	settings_instance.get_node("restart").pressed.connect(_on_restart_pressed)
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
			instance.scale = Vector2(.78, .78)
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
			instance.scale = Vector2(.78, .78)
			ships_all.push_back(instance)
		file_name = dir.get_next()
	# Anonymous lambda function to sort all ships alphabetically
	ships_all.sort_custom(func(a, b): return a.ship_button_name < b.ship_button_name)
	# Play base loaded sound
	SfxManager.play_sound("menu_loaded", SfxManager.menu_loaded_volume)
	# Setup menu for gametype selection
	setup_gametype_selection()
	# Set all setting states on initial startup and restart
	if music.playing:
		settings_instance.get_node("music").text = "Music ON"
	else:
		settings_instance.get_node("music").text = "Music OFF"
	if SfxManager.audio_playing:
		settings_instance.get_node("audio").text = "Audio ON"
	else:
		settings_instance.get_node("audio").text = "Audio OFF"
	if get_parent().game_speed == 0.3:
		settings_instance.get_node("speed").text = "Normal"
	elif get_parent().game_speed == 0.1:
		settings_instance.get_node("speed").text = "Fast"
	elif get_parent().game_speed == 0:
		settings_instance.get_node("speed").text = "Fastest"
	if get_parent().display_mode == "Borderless":
		settings_instance.get_node("display").text = "Borderless"
	elif get_parent().display_mode == "Windowed":
		settings_instance.get_node("display").text = "Windowed"
	
func _physics_process(delta):
	map_movement_manager()
	player_setup_manager()
	setup_battlefield()
	battleloop()
	handle_held_inputs(delta)

func _input(event):
	if event.is_action_pressed("escape"):
		# Allows menu to be pulled up after selection has taken place
		if battleloop_started:
			play_click_sounds()
			if settings_instance.visible:
				settings_instance.hide()
				show_attack_menus()
			else:
				hide_attack_menus()
				settings_instance.show()
	if event.is_action_pressed("return") or event.is_action_pressed("right_click") or event.is_action_pressed("space"):
		simulate_mouse_click()

func setup_gametype_selection():
	for x in 3:
		var game_type_name
		if x == 0:
			game_type_name = "Battle"
		elif x == 1:
			game_type_name = "Skirmish"
		elif x == 2:
			game_type_name = "Custom"
		var game_type_button = Button.new()
		game_type_button.connect("pressed", Callable(self, "_game_type_pressed").bind(game_type_name))
		game_type_button.custom_minimum_size = Vector2(400, 120)
		game_type_button.add_theme_font_size_override("font_size", 75)
		game_type_button.text = game_type_name
		menu_instance.add_child(game_type_button)

func simulate_mouse_click():
	var click = InputEventMouseButton.new()
	click.set_button_index(MOUSE_BUTTON_LEFT)
	click.position = get_viewport().get_mouse_position() * .75
	click.set_pressed(true)
	Input.parse_input_event(click)
		
	var release_click = InputEventMouseButton.new()
	release_click.set_button_index(MOUSE_BUTTON_LEFT)
	release_click.position = click.position
	release_click.set_pressed(false)
	Input.parse_input_event(release_click)

func handle_held_inputs(delta):
	if Input.is_action_pressed("return") or Input.is_action_pressed("right_click") or Input.is_action_pressed("space"):
		repeat_timer += delta
		if not button_held and repeat_timer >= 0.5:
			button_held = true
		if button_held and repeat_timer >= 0.6:
			simulate_mouse_click()
			repeat_timer = 0.5
	else:
		if button_held:
			button_held = false
			repeat_timer = 0.0
	
func _game_type_pressed(game_type_name):
	play_click_sounds()
	if game_type_name == "Battle":
		game_type = "Battle"
	elif game_type_name == "Skirmish":
		game_type = "Skirmish"
	elif game_type_name == "Custom":
			game_type = "Custom"
	remove_all_buttons_from_main_menu()
	player_one_choose = true
	
func _on_skip_button_pressed():
	play_click_sounds()
	player_end_turn_signal = true

func _on_select_race_button_pressed(button):
	play_click_sounds()
	# Adds ships to players deck
	var type_to_search
	if button.text == "Alien": type_to_search = "alien"
	elif button.text == "Auroran": type_to_search = "auroran"
	elif button.text == "Federation": type_to_search = "federation"
	elif button.text == "Pirate": type_to_search = "pirate"
	elif button.text == "Polaris": type_to_search = "polaris"
	elif button.text == "Rebel": type_to_search = "rebel"
	elif button.text == "Trader": type_to_search = "trader"
	if game_type == "Battle":
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
			player_one_choose = false
			player_two_choose = true
		remove_all_buttons_from_main_menu()
	elif game_type == "Skirmish":
		if player_two_choose == true:
			add_ships_to_player_deck_skirmish(2, type_to_search)
			player_two_choose = false
			players_done_choosing = true
		else:
			add_ships_to_player_deck_skirmish(1, type_to_search)
			player_one_choose = false
			player_two_choose = true
		remove_all_buttons_from_main_menu()
	elif game_type == "Custom":
		if player_two_choose == true:
			remove_all_buttons_from_main_menu()
			# Creates 10 buttons to choose from
			for x in 10:
				var game_type_button = Button.new()
				game_type_button.connect("pressed", Callable(self, "custom_amount_pressed").bind(type_to_search, x + 1))
				game_type_button.custom_minimum_size = Vector2(250, 80)
				game_type_button.add_theme_font_size_override("font_size", 75)
				game_type_button.text = str(x + 1)
				menu_instance.add_child(game_type_button)
		else:
			remove_all_buttons_from_main_menu()
			# Creates 10 buttons to choose from
			for x in 10:
				var game_type_button = Button.new()
				game_type_button.connect("pressed", Callable(self, "custom_amount_pressed").bind(type_to_search, x + 1))
				game_type_button.custom_minimum_size = Vector2(250, 80)
				game_type_button.add_theme_font_size_override("font_size", 75)
				game_type_button.text = str(x + 1)
				menu_instance.add_child(game_type_button)
	# Removes option from deck races button list
	for x in range(deck_races.size() - 1, -1, -1):  # Iterate backwards
		if deck_races[x] == button.text:
			deck_races.remove_at(x)

func remove_all_buttons_from_main_menu():
	for x in menu_instance.get_children():
		x.queue_free()

func custom_amount_pressed(type_to_search, number_of_custom_ships):
	play_click_sounds()
	remove_all_buttons_from_main_menu()
	if number_of_custom_ships > 0:
		var scroll_container = ScrollContainer.new()
		scroll_container.custom_minimum_size = Vector2(600, 800)
		var vbox = VBoxContainer.new()
		scroll_container.add_child(vbox)
		for x in ships_all:
			if x.type == type_to_search:
				var game_type_button = Button.new()
				game_type_button.connect("pressed", Callable(self, "add_ships_to_player_deck_custom").bind(type_to_search, number_of_custom_ships, x))
				game_type_button.add_theme_font_size_override("font_size", 30)
				game_type_button.custom_minimum_size = Vector2(600, 80)
				game_type_button.text = str(x.ship_button_name)
				vbox.add_child(game_type_button)
		menu_instance.add_child(scroll_container)
	else:
		if player_two_choose:
			player_two_choose = false
			players_done_choosing = true
		else:
			player_one_choose = false
			player_two_choose = true

func add_ships_to_player_deck_custom(type_to_search, number_of_custom_ships, ship_instance):
	var num_ships = number_of_custom_ships - 1
	if player_two_choose:
		player_2_deck.push_back(ship_instance)
	else:
		player_1_deck.push_back(ship_instance)
	for i in range(ships_all.size()):
		if ships_all[i].ship_name == ship_instance.ship_name:
			ships_all.remove_at(i)
			break
	custom_amount_pressed(type_to_search, num_ships)

func add_ships_to_player_deck_skirmish(player_number, type_to_search):
	if player_number == 2:
		var available_ships = []
		for x in ships_all:
			if x.type == type_to_search:
				available_ships.append(x)
		var total_cost = 0
		var failed_attempts = 0
		while available_ships.size() > 0 and failed_attempts < 10:
			var index = randi() % available_ships.size()
			var ship = available_ships[index]
			if total_cost + ship.cost <= 100 and ship not in player_2_deck:
				player_2_deck.append(ship)
				total_cost += ship.cost
				available_ships.remove_at(index)
				failed_attempts = 0
			else:
				failed_attempts += 1
	else:
		var available_ships = []
		for x in ships_all:
			if x.type == type_to_search:
				available_ships.append(x)
		var total_cost = 0
		var failed_attempts = 0
		while available_ships.size() > 0 and failed_attempts < 10:
			var index = randi() % available_ships.size()
			var ship = available_ships[index]
			if total_cost + ship.cost <= 100 and ship not in player_1_deck:
				player_1_deck.append(ship)
				total_cost += ship.cost
				available_ships.remove_at(index)
				failed_attempts = 0
			else:
				failed_attempts += 1

func _on_music_pressed():
	play_click_sounds()
	if settings_instance.get_node("music").text == "Music ON":
		settings_instance.get_node("music").text = "Music OFF"
	elif settings_instance.get_node("music").text == "Music OFF":
		settings_instance.get_node("music").text = "Music ON"
	music.playing = !music.playing
	
func _on_audio_pressed():
	SfxManager.audio_playing = !SfxManager.audio_playing
	play_click_sounds()
	if settings_instance.get_node("audio").text == "Audio ON":
		settings_instance.get_node("audio").text = "Audio OFF"
	elif settings_instance.get_node("audio").text == "Audio OFF":
		settings_instance.get_node("audio").text = "Audio ON"
	
func _on_display_pressed():
	if get_parent().display_mode == "Borderless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		settings_instance.get_node("display").text = "Windowed"
		get_parent().display_mode = "Windowed"
		DisplayServer.window_set_size(DisplayServer.screen_get_size() * .8)
	elif get_parent().display_mode == "Windowed":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		settings_instance.get_node("display").text = "Borderless"
		get_parent().display_mode = "Borderless"
		
func _on_speed_pressed():
	play_click_sounds()
	var normal = "Normal"
	var fast = "Fast"
	var fastest = "Fastest"
	if settings_instance.get_node("speed").text == fastest:
		settings_instance.get_node("speed").text = normal
		get_parent().game_speed = 0.3
	elif settings_instance.get_node("speed").text == normal:
		settings_instance.get_node("speed").text = fast
		get_parent().game_speed = 0.1
	elif settings_instance.get_node("speed").text == fast:
		settings_instance.get_node("speed").text = fastest
		get_parent().game_speed = 0
	
func _on_restart_pressed():
	# Accesses the 'loading_scene' root and resets it
	get_parent().base_loaded = false
	queue_free()
	
func _on_quit_pressed():
	play_click_sounds()
	get_tree().quit()
	
func play_click_sounds():
	SfxManager.play_sound("click_on", SfxManager.click_on_volume)
	SfxManager.delayed_play_sound("click_off", SfxManager.click_off_volume)

func create_race_selection_options():
	for x in deck_races:
		var button = Button.new()
		button.text = x
		button.custom_minimum_size = Vector2(400, 120)
		button.add_theme_font_size_override("font_size", 75)
		button.add_theme_color_override("font_color", font_color_by_race(x.to_lower()))
		button.connect("pressed", Callable(self, "_on_select_race_button_pressed").bind(button))
		menu_instance.add_child(button)

func player_setup_manager():
	if player_one_choose == true and player_one_setup == false:
		create_race_selection_options()
		player_one_setup = true
	if player_two_choose == true and player_two_setup == false:
		# Creates menu options to select from for player 2
		create_race_selection_options()
		player_two_setup = true
		
func setup_battlefield():
	if battlefield_setup == false and players_done_choosing == true:
		player_one_draw_pile = card_back.instantiate()
		player_one_draw_pile.position += player_draw_position_1
		add_child(player_one_draw_pile)
		player_two_draw_pile = card_back.instantiate()
		player_two_draw_pile.position += player_draw_position_2
		add_child(player_two_draw_pile)
		draw_pile_1 = card_back.instantiate()
		draw_pile_1.position += draw_pile_position
		draw_pile_1.position.y += 310
		add_child(draw_pile_1)
		draw_pile_2 = card_back.instantiate()
		draw_pile_2.position += draw_pile_position
		draw_pile_2.position.y -= 310
		add_child(draw_pile_2)
		# Populates deck counters
		player_one_deck_counter.text = "x " + str(player_1_deck.size())
		player_one_deck_count = player_1_deck.size()
		player_one_deck_counter.visible = true
		player_two_deck_counter.text = "x " + str(player_2_deck.size())
		player_two_deck_count = player_2_deck.size()
		player_two_deck_counter.visible = true
		# Adds skip option to buttons
		var skip_button = Button.new()
		skip_button.text = "Skip"
		skip_button.custom_minimum_size = Vector2(250, 30)
		skip_button.add_theme_font_size_override("font_size", 30)
		skip_button.connect("pressed", Callable(self, "_on_skip_button_pressed"))
		menu_instance.add_child(skip_button)
		# Toggles next step
		battlefield_setup = true
		battleloop_started = true

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
			end_message_printed = true

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
			if player_1_deck.size() < 2:
				player_one_deck_counter.visible = false
			else:
				player_one_deck_count -= 1 
				player_one_deck_counter.text = "x " + str(player_1_deck.size())
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
			if player_2_deck.size() < 2:
				player_two_deck_counter.visible = false
			else:
				player_two_deck_count -= 1 
				player_two_deck_counter.text = "x " + str(player_2_deck.size())
		else:
			player_wins = 1

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
					attack_button_instance.add_theme_color_override("font_color", font_color_by_race(active_ship.type))
					attack_button_instance.text = x.button_name
					menu_attacks.add_child(attack_button_instance)
		if menu_attacks.get_child_count() == 0:
			player_end_turn_signal = true
	
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
	
func attack_chosen(attack_button, active_ship):
	for x in active_ship.attacks:
		if x.button_name == attack_button.text:
			player_attack_chosen = true
			attack_info_name = attack_button.text
			attack_info_primary_ship = active_ship

func player_which_enemy():
	if check_for_fighter_launch():
		attack(enemy_single_ship_name())
	elif enemy_has_multiple_ships():
		# Covers all cases when click sounds need to be played for a non-attack attack menu
		play_click_sounds()
		shuffle_deck()
		if menu_attacks:
			for x in menu_attacks.get_children():
				x.queue_free()
		var unique_enemies_to_attack = unique_enemies_attackable()
		for i in range(unique_enemies_to_attack.size()):
			var attack_button_instance = Button.new()
			attack_button_instance.connect("pressed", Callable(self, "attack").bind(unique_enemies_to_attack[i]))
			attack_button_instance.custom_minimum_size = Vector2(250, 80)
			attack_button_instance.add_theme_font_size_override("font_size", 50)
			attack_button_instance.add_theme_color_override("font_color", font_color_by_race(attack_info_primary_ship.type))
			attack_button_instance.text = unique_enemies_to_attack[i]
			menu_attacks.add_child(attack_button_instance)
		player_which_enemy_initialized = true
	else:
		shuffle_deck()
		attack(enemy_single_ship_name())
		
func check_for_fighter_launch():
	for x in attack_info_primary_ship.attacks:
		if x.button_name == attack_info_name:
			if x.armor == null:
				return true
	return false

func unique_enemies_attackable():
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

func enemy_single_ship_name():
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
	# Plays click sounds when attack is chosen
	play_click_sounds()
	var enemy_ship = first_instance_of_enemy_ship(enemy_ship_name)
	for x in attack_info_primary_ship.attacks:
		if x.button_name == attack_info_name:
			# Identifies Fighters
			if x.armor == null:
				launch_fighters(x, attack_info_primary_ship.ship_position)
			# Identifies Missiles
			elif x.pursuit != null:
				if x.pursuit + draw_a_card_missile(attack_info_primary_ship.ship_position) >= enemy_ship.escape + draw_a_card_missile(enemy_ship.ship_position):
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
			# Identifies Shield
			if attack_details.shield + draw_a_card(attack_info_primary_ship.ship_position) >= enemy_ship.shield + draw_a_card(enemy_ship.ship_position):
				shield_down(enemy_ship)
		else:
			# Identifies Armor
			if attack_details.armor + draw_a_card(attack_info_primary_ship.ship_position) >= enemy_ship.armor + draw_a_card(enemy_ship.ship_position):
				armor_down(enemy_ship)
	else:
		# Identifies Pass-Through-Shield attacks (Nanites, etc...)
		if attack_details.armor + draw_a_card(attack_info_primary_ship.ship_position) >= enemy_ship.armor + draw_a_card(enemy_ship.ship_position):
			armor_down(enemy_ship)
			
func shield_down(enemy_ship):
	enemy_ship.shield = 0
	blink_manager(enemy_ship, true)

func armor_down(enemy_ship):
	# Removes ship from player 2 active ships
	if enemy_ship.ship_position == 2 or enemy_ship.ship_position == 4 or enemy_ship.ship_position == 6:
		for x in player_two_active_ships:
			if x.ship_name == enemy_ship.ship_name:
				var index = player_two_active_ships.find(x)
				player_two_active_ships.pop_at(index)
				break
	# Removes ship from player 1 active ships
	else:
		for x in player_one_active_ships:
			if x.ship_name == enemy_ship.ship_name:
				var index = player_one_active_ships.find(x)
				player_one_active_ships.pop_at(index)
				break
	# Removes ship from this phase attacking queue
	for x in ships_attacking_this_phase:
		if x.ship_name == enemy_ship.ship_name:
			var index = ships_attacking_this_phase.find(x)
			ships_attacking_this_phase.pop_at(index)
			break
	if enemy_ship.ship_position > 2:
		fighter_subtract_from_counters(enemy_ship.ship_position)
	blink_manager(enemy_ship, false)
	remove_child(enemy_ship)

func draw_a_card(primary_ship_position):
	var index = randi() % draw_deck.size()
	var element = draw_deck.pop_at(index)
	if primary_ship_position == 1 or primary_ship_position == 3 or primary_ship_position == 5:
		element.position = draw_pile_position
		element.position.y += 310
	else:
		element.position = draw_pile_position
		element.position.y -= 310
	element.scale = Vector2(.78, .78)
	if get_parent().game_speed != 0:
		flip_a_card(primary_ship_position, element)
	else:
		if element.get_parent() == null: add_child(element)
	draw_deck_reshuffle.push_back(element)
	return element.value
	
func draw_a_card_missile(primary_ship_position):
	var index = randi() % draw_deck.size()
	var element = draw_deck.pop_at(index)
	if primary_ship_position == 1 or primary_ship_position == 3 or primary_ship_position == 5:
		element.position = draw_pile_position
		element.position.y += 355
	else:
		element.position = draw_pile_position
		element.position.y -= 265
	element.scale = Vector2(.78, .78)
	element.position.x += 45
	secondary_cards_to_remove_1.push_back(element)
	secondary_cards_to_remove_2.push_back(element)
	if get_parent().game_speed != 0:
		flip_a_card(primary_ship_position, element)
	else:
		if element.get_parent() == null: add_child(element)
	draw_deck_reshuffle.push_back(element)
	return element.value

func flip_a_card(primary_ship_position, front_card):
	# Card back cover is used to cover previously flipped cards
	var card_back_cover = card_back.instantiate()
	# Card back temp is the card back that is flipped
	var card_back_temp = card_back.instantiate()
	# Determines which draw pile to use (Front card has already been positioned)
	if primary_ship_position == 1 or primary_ship_position == 3 or primary_ship_position == 5:
		card_back_cover.position = draw_pile_position
		card_back_cover.position.y += 310
		card_back_temp.position = draw_pile_position
		card_back_temp.position.y += 310
	else:
		card_back_cover.position = draw_pile_position
		card_back_cover.position.y -= 310
		card_back_temp.position = draw_pile_position
		card_back_temp.position.y -= 310
	add_child(card_back_cover)
	add_child(card_back_temp)
	# Back card flip
	var tween_back = create_tween()
	tween_back.tween_property(card_back_temp, "scale", Vector2(0, 1), get_parent().game_speed)
	await get_tree().create_timer(get_parent().game_speed).timeout
	card_back_temp.queue_free()
	# Front card flip
	front_card.scale = Vector2(0, .78)
	if front_card.get_parent() == null: add_child(front_card)
	var tween_front = create_tween()
	tween_front.tween_property(front_card, "scale", Vector2(.78, .78), get_parent().game_speed)
	await get_tree().create_timer(get_parent().game_speed).timeout
	# Cleanup of card back cover
	card_back_cover.queue_free()
	
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

func shuffle_deck():
	for x in secondary_cards_to_remove_1:
		if x.get_parent(): remove_child(x)
	for x in secondary_cards_to_remove_2:
		if x.get_parent(): remove_child(x)
	secondary_cards_to_remove_1.clear()
	secondary_cards_to_remove_2.clear()
	for x in draw_deck:
		if x.get_parent(): remove_child(x)
	draw_deck.append_array(draw_deck_reshuffle)
	draw_deck_reshuffle.clear()
	
func first_instance_of_enemy_ship(enemy_ship_name):
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
		var fighter_instance = fighter_instance_by_name(attack_selected.button_name)
		fighter_instance.ship_position = ship_position
		ship_group_to_join.push_back(fighter_instance)
		fighter_instance.position = position_to_spawn
		fighter_instance.scale = Vector2(.78, .78)
		add_child(fighter_instance)
		fighter_add_to_counters(ship_position)
	attack_selected.ammo = 0

func fighter_subtract_from_counters(ship_position):
	var menu_to_subtract
	var fighters_left
	if ship_position == 3:
		fighters_in_position_3 -= 1
		fighters_left = fighters_in_position_3
		menu_to_subtract = menu_counter_three
		menu_to_subtract.text = "x" + str(fighters_in_position_3)
	elif ship_position == 4:
		fighters_in_position_4 -= 1
		menu_to_subtract = menu_counter_four
		fighters_left = fighters_in_position_4
		menu_to_subtract.text = "x" + str(fighters_in_position_4)
	elif ship_position == 5:
		fighters_in_position_5 -= 1
		fighters_left = fighters_in_position_5
		menu_to_subtract = menu_counter_five
		menu_to_subtract.text = "x" + str(fighters_in_position_5)
	elif ship_position == 6:
		fighters_in_position_6 -= 1
		fighters_left = fighters_in_position_6
		menu_to_subtract = menu_counter_six
		menu_to_subtract.text = "x" + str(fighters_in_position_6)
	if fighters_left > 1:
		menu_to_subtract.visible = true
	else:
		menu_to_subtract.visible = false

func fighter_add_to_counters(ship_position):
	var menu_to_show
	if ship_position == 3:
		fighters_in_position_3 += 1
		menu_to_show = menu_counter_three
		menu_to_show.text = "x" + str(fighters_in_position_3)
	elif ship_position == 4:
		fighters_in_position_4 += 1
		menu_to_show = menu_counter_four
		menu_to_show.text = "x" + str(fighters_in_position_4)
	elif ship_position == 5:
		fighters_in_position_5 += 1
		menu_to_show = menu_counter_five
		menu_to_show.text = "x" + str(fighters_in_position_5)
	elif ship_position == 6:
		fighters_in_position_6 += 1
		menu_to_show = menu_counter_six
		menu_to_show.text = "x" + str(fighters_in_position_6)
	menu_to_show.visible = true

func fighter_instance_by_name(fighter):
	if fighter == "Thunderhead Bay":
		return thunderhead.instantiate()
	elif fighter == "Pirate Viper Bay":
		return pirate_viper.instantiate()
	elif fighter == "Pirate Thunderhead Bay":
		return pirate_thunderhead.instantiate()
	elif fighter == "Phoenix Bay":
		return phoenix.instantiate()
	elif fighter == "Firebird Bay":
		return firebird.instantiate()
	elif fighter == "Viper Bay":
		return viper.instantiate()
	elif fighter == "Anaconda Bay":
		return anaconda.instantiate()
	elif fighter == "Rebel Viper Bay":
		return rebel_viper.instantiate()
	elif fighter == "Manta Bay":
		return manta.instantiate()

func font_color_by_race(active_ship_type):
	if active_ship_type == "alien": return "#FFE766"
	elif active_ship_type == "auroran": return "#E68568"
	elif active_ship_type == "federation": return "#6BAFDE"
	elif active_ship_type == "pirate": return "#D89262"
	elif active_ship_type == "polaris": return "#D8BFD8"
	elif active_ship_type == "rebel": return "#5AC46E"
	elif active_ship_type == "trader": return "#C0C0C0"
		
func phase_switch():
	if current_phase < 5:
		current_phase += 1
	else:
		current_phase = 1
	ships_attacking_this_phase.clear()
	order_of_attack_determined = false

func reset_phase():
	current_phase = 1
	ships_attacking_this_phase.clear()
	order_of_attack_determined = false
	
func offset_attacks_menus():	
	var menus_to_offset = [menu_1, menu_2, menu_3, menu_4, menu_5, menu_6]
	for menu_to_offset in menus_to_offset:
		if menu_to_offset.get_child_count() == 2:
			menu_to_offset.get_node("Button").queue_free()
			menu_to_offset.get_node("Button2").queue_free()
			menu_to_offset.position.y += 330
		
func hide_attack_menus():
	menu_1.visible = false
	menu_2.visible = false
	menu_3.visible = false
	menu_4.visible = false
	menu_5.visible = false
	menu_6.visible = false
	menu_instance.visible = false

func show_attack_menus():
	menu_1.visible = true
	menu_2.visible = true
	menu_3.visible = true
	menu_4.visible = true
	menu_5.visible = true
	menu_6.visible = true
	menu_instance.visible = true
		
func final_win_label():
	hide_attack_menus()
	var label = Label.new()
	label.text = "Player " + str(player_wins) + " Wins!"
	label.custom_minimum_size = Vector2(350, 120)
	label.add_theme_font_size_override("font_size", 100)
	label.add_theme_color_override("font_color", font_color_by_race(attack_info_primary_ship.type))
	var final_instance = menu.instantiate()
	final_instance.position.x -= 25
	final_instance.position.y -= 5
	if player_wins == 1:
		final_instance.position -= Vector2(0, 400)
	else:
		final_instance.position += Vector2(0, 300)
	final_instance.add_child(label)
	canvas_layer.add_child(final_instance)
	
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
