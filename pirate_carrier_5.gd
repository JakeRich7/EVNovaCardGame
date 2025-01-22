extends Sprite2D

@onready var type = "pirate"
@onready var shields = 13
@onready var armor = 14
@onready var escape = 4
@onready var cost = 20
@onready var attacks = [
	{
		"name": "4 Pirate Viper Bays", "phase": 1, "shield": null,
		"armor": null, "pursuit": null, "ammo": 16
	},
	{
		"name": "4 150mm Railguns", "phase": 1, "shield": 18,
		"armor": 22, "pursuit": null, "ammo": null
	},
{
		"name": "EMP Torpedo Tube", "phase": 3, "shield": 34,
		"armor": 10, "pursuit": 8, "ammo": 4
	},
	{
		"name": "2 PD Quad Lt. Blaster Turrets", "phase": 4, "shield": 16,
		"armor": 11, "pursuit": null, "ammo": null
	}
]
