extends Sprite2D

var type = "pirate"
var shields = 13
var armor = 14
var escape = 4
var cost = 20
var attacks = [
	{
		"name": "4 Pirate Viper Bays", "button_name": "Pirate Vipers",
		"phase": 1, "shield": null, "armor": null, "pursuit": null, "ammo": 16
	},
	{
		"name": "4 150mm Railguns", "button_name": "150mm Railguns",
		"phase": 1, "shield": 18, "armor": 22, "pursuit": null, "ammo": null
	},
{
		"name": "EMP Torpedo Tube", "button_name": "EMP Torpedos",
		"phase": 3, "shield": 34, "armor": 10, "pursuit": 8, "ammo": 4
	},
	{
		"name": "2 PD Quad Lt. Blaster Turrets", "button_name": "Quad Light Blaster Turrets",
		"phase": 4, "shield": 16, "armor": 11, "pursuit": null, "ammo": null
	}
]
