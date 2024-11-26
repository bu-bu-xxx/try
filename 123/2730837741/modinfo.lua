name = "Motorbike"
description = [[
Motorbike: Your STEAM powered two wheeled vehicle!

How to drive:
Craft it on the ground;
Place a watering can inside it to provide enough water for the STEAM engine;
Fill it with charcoal to heat it up! Hotter means FASTER!
And done! Just it, get to the driver seat and start driving.

Give your friends a ride!
If you are on the driver seat and your motorbike is parked, your friends can interact with your character to get a ride in a small motorbike cart attached;
Note: Friends, please don't forget to give your driver a five star ;)

Recipe:

On your "Alchemy Engine"[, in "Science" tab:

1 Saddle
2 Gears
3 Boards


[h2]Controls:[/h2]
Move Up: Accelerate
Move Down: Brake/Rear
Move Left: Turn Left
Move Right: Turn Right
Action Button (Space): Brake & Drop Off (after holding it)


Notes:

If you hit something with your motorbike at high speed, you will crash, but no damage is taken;
The motorbike heat dissipation depends on world temperature. On hotter days, it last longer;
Water consumption depends on motorbike temperature. Higher temperatures consume more water;
The maximum amount of water depends on the amount of water the watering can can hold; Premium watering can last 4 times longer;
In your hud you can see the mana and health bar, which are, respectively, water and heat;
The maximum speed is 6 tiles per second, which is achieved at maximum heat.


This mod was live coded by Gleenus, and the art was made by ButterflyHolix
]]

author = "Gleenus and ButterflyHolix"
version = "1.02"
forumthread = ""
api_version = 10
dst_compatible = true

all_clients_require_mod = true
client_only_mod = false

server_filter_tags = {"ghmods", "motorbike", "gleenus", "holix"}

icon_atlas = "images/modicon.xml"
icon = "modicon.tex"

----------------------------
-- Configuration settings --
----------------------------


configuration_options = 
{
	{
		name = "MOTOBIKE_FUEL_RATE",
		label = "Water consumption rate",
		hover = "Modify the water consumption multiplier.",
		options =	
		{
		    {description = "0", data =  0},
		    {description = "0.2", data =  0.2},
		    {description = "0.4", data =  0.4},
		    {description = "0.6", data =  0.6},
            {description = "0.8", data =  0.8},
			{description = "1", data = 1},
			{description = "1.2", data = 1.2},
			{description = "1.4", data = 1.4},
			{description = "1.6", data = 1.6},
			{description = "1.8", data = 1.8},
			{description = "2", data = 2},
			{description = "3", data = 3},
			{description = "4", data = 4},
			{description = "5", data = 5},
		},
		default = 1,
	},
	{
		name = "MOTOBIKE_HEAT_RATE",
		label = "Heat dissipation rate",
		hover = "Modify the heat dissipation multiplier.",
		options =	
		{
		    {description = "0", data =  0},
		    {description = "0.2", data =  0.2},
		    {description = "0.4", data =  0.4},
		    {description = "0.6", data =  0.6},
            {description = "0.8", data =  0.8},
			{description = "1", data = 1},
			{description = "1.2", data = 1.2},
			{description = "1.4", data = 1.4},
			{description = "1.6", data = 1.6},
			{description = "1.8", data = 1.8},
			{description = "2", data = 2},
			{description = "3", data = 3},
			{description = "4", data = 4},
			{description = "5", data = 5},
		},
		default = 1,
	},
	{
		name = "MOTOBIKE_CHARCOAL_RATE",
		label = "Charcoal heat rate",
		hover = "Modify the amount of heat generated by each charcoal.",
		options =	
		{
		    {description = "0", data =  0},
		    {description = "0.2", data =  0.2},
		    {description = "0.4", data =  0.4},
		    {description = "0.6", data =  0.6},
            {description = "0.8", data =  0.8},
			{description = "1", data = 1},
			{description = "1.2", data = 1.2},
			{description = "1.4", data = 1.4},
			{description = "1.6", data = 1.6},
			{description = "1.8", data = 1.8},
			{description = "2", data = 2},
			{description = "3", data = 3},
			{description = "4", data = 4},
			{description = "5", data = 5},
		},
		default = 1,
	},
	{
		name = "MOTOBIKE_DROP_CAN_ON_EXIT",
		label = "Drop watering can on exit",
		hover = "Enabling this will make watering can drop on exit to avoid wasting water.",
		options =	
		{
		    {description = "No", data =  false},
		    {description = "Yes", data =  true},

		},
		default = false,
	},
}

