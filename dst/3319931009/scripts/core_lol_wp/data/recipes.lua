---@diagnostic disable: lowercase-global, undefined-global, trailing-space


---@type data_recipe[]
local data = {
	-- 
	{
		recipe_name = 'gallop_whip',
		ingredients = {
			Ingredient("pickaxe",1),
			Ingredient("marble",2),
			Ingredient("goldnugget",4),
			Ingredient("flint",6),
		},
		tech = TECH.SCIENCE_TWO,
		config = {
		},
      	filters = {"WEAPONS",'TAB_LOL_WP','MODS'}
	},
	{
		recipe_name = 'gallop_bloodaxe',
		ingredients = {
			Ingredient("gallop_whip",1,'images/inventoryimages/gallop_whip.xml'),
			Ingredient("shadow_battleaxe",1),
			Ingredient("dreadstone",8),
			Ingredient("horrorfuel",4),
			Ingredient("voidcloth",2),
		},
		tech = TECH.SHADOWFORGING_TWO,
		config = {
			nounlock = true, station_tag = "shadow_forge"
		},
      	filters = {"WEAPONS", "MODS",'TAB_LOL_WP'}
	},
	{
		recipe_name = 'gallop_breaker',
		ingredients = {
			Ingredient("multitool_axe_pickaxe",1),
			Ingredient("gnarwail_horn",2),
			Ingredient("minotaurhorn",1),
			Ingredient("cookiecuttershell",8),
			Ingredient("thulecite",6),
		},
		tech = TECH.ANCIENT_THREE,
		config = {
			station_tag = "altar", nounlock = true
		},
      	filters = {"CRAFTING_STATION", "WEAPONS", "MODS",'TAB_LOL_WP'}
	},

	-- 1玻璃刀, 4月岩，6玻璃碎片，2蓝宝石
	{
		recipe_name = 'lol_wp_sheen',
		ingredients = {
			Ingredient("glasscutter",1),
			Ingredient("moonrocknugget",4),
			Ingredient("moonglass",6),
			Ingredient("bluegem",2),
		},
		tech = TECH.CELESTIAL_THREE,
		config = {
			station_tag="moon_altar",
			nounlock = true,
		},
		filters = {'WEAPONS','TAB_LOL_WP','MODS'},
	},
	-- 1多用斧镐，1耀光，12铥矿，2海象牙，4黄宝石
	-- 1多用斧镐，1耀光，8铥矿，40金块，4绿宝石
	{
		recipe_name = 'lol_wp_divine',
		ingredients = {
			Ingredient("multitool_axe_pickaxe",1),
			Ingredient("lol_wp_sheen",1,'images/inventoryimages/lol_wp_sheen.xml'),
			Ingredient("goldnugget",40),
			Ingredient("thulecite",12),
			Ingredient("greengem",4),
		},
		tech = TECH.ANCIENT_TWO,
		config = {
			station_tag = "altar",
			nounlock = true,
		},
		filters = {'CRAFTING_STATION','WEAPONS','TAB_LOL_WP','MODS'},
	},
	-- 1 铥矿棒，1 暗夜剑，1 耀光, 6 铥矿，3 彩虹宝石
	-- 1 铥矿棒，1 暗夜剑，1 耀光, 33 金矿，3 彩虹宝石
	{
		recipe_name = 'lol_wp_trinity',
		ingredients = {
			Ingredient("ruins_bat",1),
			Ingredient("nightsword",1),
			Ingredient("lol_wp_sheen",1,'images/inventoryimages/lol_wp_sheen.xml'),
			Ingredient("goldnugget",33),
			Ingredient("opalpreciousgem",3),
		},
		tech = TECH.ANCIENT_TWO,
		config = {
			station_tag = "altar",
			nounlock = true,
		},
		filters = {'CRAFTING_STATION','WEAPONS','TAB_LOL_WP','MODS'},
	},
	-- 霸王血铠 1骨头盔甲，1绝望石盔甲，5红宝石，10铥矿，6纯粹恐惧
	{
		recipe_name = 'lol_wp_overlordbloodarmor',
		ingredients = {
			Ingredient("armorskeleton",1),
			Ingredient("armordreadstone",1),
			Ingredient("redgem",5),
			Ingredient("thulecite",10),
			Ingredient("horrorfuel",6),
		},
		tech = TECH.LOST,
		config = {
			-- nounlock = true,
		},
		filters = {'ARMOUR','TAB_LOL_WP','MODS'},
	},
	-- -- 恶魔之拥 1骨头头盔，1绝望石头盔，5紫宝石，10铥矿，6纯粹恐惧
	{
		recipe_name = 'lol_wp_demonicembracehat',
		ingredients = {
			Ingredient("skeletonhat",1),
			Ingredient("dreadstonehat",1),
			Ingredient("purplegem",5),
			Ingredient("thulecite",10),
			Ingredient("horrorfuel",6),
		},
		tech = TECH.LOST,
		config = {},
		filters = {'ARMOUR','TAB_LOL_WP','MODS'},
	},
	-- -- 狂徒铠甲 1木甲，1荆棘外壳，8蘑菇皮，16活木，4绿宝石
	{
		recipe_name = 'lol_wp_warmogarmor',
		ingredients = {
			Ingredient("armorwood",1),
			Ingredient("armor_bramble",1),
			Ingredient("shroom_skin",8),
			Ingredient("livinglog",16),
			Ingredient("greengem",4),
		},
		tech = TECH.LOST,
		config = {},
		filters = {'ARMOUR','TAB_LOL_WP','MODS'},
	},
	-- S7
	-- 萃取（武器栏）制作配方：1长矛，20金块，5燧石
	{
		recipe_name = 'lol_wp_s7_cull',
		ingredients = {
			Ingredient("spear",1),
			Ingredient("goldnugget",20),
			Ingredient("flint",5),
		},
		tech = TECH.SCIENCE_TWO,
		config = {},
		filters = {'WEAPONS','TAB_LOL_WP','MODS'},
	}, 
	-- 多兰之刃（武器栏 1长矛，4金块，2燧石
	{
		recipe_name = 'lol_wp_s7_doranblade',
		ingredients = {
			Ingredient("spear",1),
			Ingredient("goldnugget",4),
			Ingredient("flint",2),
		},
		tech = TECH.SCIENCE_ONE,
		config = {},
		filters = {'WEAPONS','TAB_LOL_WP','MODS'},
	},
	-- 多兰之盾（护甲栏
	{
		recipe_name = 'lol_wp_s7_doranshield',
		ingredients = {
			Ingredient("boards",2),
			Ingredient("goldnugget",4),
			Ingredient("flint",2),
		},
		tech = TECH.SCIENCE_ONE,
		config = {},
		filters = {'ARMOUR','TAB_LOL_WP','MODS'},
	},
	-- 多兰之戒（魔法栏
	{
		recipe_name = 'lol_wp_s7_doranring',
		ingredients = {
			Ingredient("bluegem",1),
			Ingredient("goldnugget",4),
			Ingredient("nightmarefuel",2),
		},
		tech = TECH.MAGIC_TWO,
		config = {},
		filters = {'MAGIC','TAB_LOL_WP','MODS'},
	},
	-- 女神之泪（月岛科技栏
	{
		recipe_name = 'lol_wp_s7_tearsofgoddess',
		ingredients = {
			Ingredient("bluegem",5),
			Ingredient("moonglass",10),
			Ingredient("nightmarefuel",5),
		},
		tech = TECH.CELESTIAL_THREE,
		config = {
			station_tag="moon_altar",
			nounlock = true,
		},
		filters = {'TAB_LOL_WP','MODS'},
	},
	-- 黑曜石锋刃（武器栏 5月岩，8蜂刺，5燧石
	{
		recipe_name = 'lol_wp_s7_obsidianblade',
		ingredients = {
			Ingredient("moonrocknugget",4),
			Ingredient("stinger",8),
			Ingredient("flint",5),
		},
		tech = TECH.SCIENCE_TWO,
		config = {},
		filters = {'WEAPONS','TAB_LOL_WP','MODS'},
	},
}


return data