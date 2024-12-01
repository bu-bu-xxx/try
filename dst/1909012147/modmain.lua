local Recipe = GLOBAL.Recipe
local Ingredient = GLOBAL.Ingredient
local TECH = GLOBAL.TECH
local RECIPETABS = GLOBAL.RECIPETABS
local STRINGS = GLOBAL.STRINGS


PrefabFiles = {	
	"thumper",
}


Assets = {			
	Asset("ATLAS", "images/inventoryimages/thumper.xml"),
	Asset("IMAGE", "images/inventoryimages/thumper.tex"),  
	Asset( "SOUNDPACKAGE","sound/hamletcharactersound.fev" ),
	Asset( "SOUND", "sound/hamletcharactersound.fsb" ),
}

local mod_language = GetModConfigData("Language")
if mod_language == "chinese" then
	STRINGS.NAMES.THUMPER = "重击者"
	STRINGS.RECIPE_DESC.THUMPER = "革命性的收割机"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.THUMPER = "苦活累活它来做"
	else
	STRINGS.NAMES.THUMPER = "Thumper"
	STRINGS.RECIPE_DESC.THUMPER = "A revolutionary harvester"
	STRINGS.CHARACTERS.GENERIC.DESCRIBE.THUMPER = "Does all the hard work for me."
end

AddRecipe2("thumper", 
{Ingredient("gears", 2), Ingredient("flint", 6), Ingredient("hammer", 2)},
	TECH.SCIENCE_TWO,
	{placer= "thumper_placer", min_spacing= 1.5,
		atlas="images/inventoryimages/thumper.xml", image= "thumper.tex"}, 
	{"PROTOTYPERS"})


RemapSoundEvent("dontstarve/characters/wagstaff/thumper/hit", "hamletcharactersound/characters/wagstaff/thumper/hit" )
RemapSoundEvent("dontstarve/characters/wagstaff/thumper/place", "hamletcharactersound/characters/wagstaff/thumper/place" )
RemapSoundEvent("dontstarve/characters/wagstaff/thumper/reset", "hamletcharactersound/characters/wagstaff/thumper/reset" )
RemapSoundEvent("dontstarve/characters/wagstaff/thumper/steam", "hamletcharactersound/characters/wagstaff/thumper/steam" )
RemapSoundEvent("dontstarve/characters/wagstaff/thumper/thump", "hamletcharactersound/characters/wagstaff/thumper/thump" )

AddMinimapAtlas("images/inventoryimages/thumper.xml")


