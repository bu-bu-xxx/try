

local function Injectatlas(ingredients,amount)
	local atlas = "images/inventoryimages/"..ingredients..".xml"
	return Ingredient(ingredients,amount,atlas)
end
local function Injectproductimg(product)
	local atlas = "images/inventoryimages/"..product..".xml"
	return atlas
end
local function isShownFn(...)
	for k,v in pairs({...}) do
		if v == "yes" then
			return true
		end
	end
	return false
end

--给MOD物品添加一个分类
-- AddRecipeFilter({
--     name = "EXAMPLE_TAB",
--     atlas = "images/exampletab.xml",
--     image = "exampletab.tex"
-- })
-- STRINGS.UI.CRAFTING_FILTERS.EXAMPLE_TAB = "样本制作分类"

local recipe_all = {
	
------------------------------------------------------------------
--TOOLS-----------------------------------------------------------
------------------------------------------------------------------


------------------------------------------------------------------
--WEAPONS----------------------------------------------------------
------------------------------------------------------------------
	{
		recipe_name = "lol_heartsteel",
		ingredients = {
			Ingredient("amulet",1),
			Ingredient("armormarble",1),
			Ingredient("goldnugget",60),
			Ingredient("thulecite",10),
			Ingredient("redgem",10),
		},
		tech = TECH.LOST,
        filters = {"MAGIC",'TAB_LOL_WP','MODS'}
	},
------------------------------------------------------------------
--ARMOUR-----------------------------------------------------------
------------------------------------------------------------------

--------
--others
--------

}

for k,_r in pairs(recipe_all) do
	if _r.isOriginalItem == nil then
		if _r.config == nil then
			_r.config = {}
		end
		if _r.config.atlas == nil then
			if _r.config.product ~= nil then
				_r.config.atlas = Injectproductimg(_r.config.product)
				_r.config.image = _r.config.product..".tex"
			else
				_r.config.atlas = Injectproductimg(_r.recipe_name)
				_r.config.image = _r.recipe_name..".tex"
			end
		end
	end
	if _r.filters == nil then
		_r.filters = {"EXAMPLE_TAB"}
	end
	if _r.config == nil then
		_r.config = {}
	end
	if _r.isShown == nil or _r.isShown == true then
		AddRecipe2(_r.recipe_name, _r.ingredients, _r.tech, _r.config, _r.filters)
	end
end






