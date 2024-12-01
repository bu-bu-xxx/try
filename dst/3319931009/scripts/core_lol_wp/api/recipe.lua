---@diagnostic disable: lowercase-global, undefined-global, trailing-space

---@class api_recipe # 配方API
local dst_lan = {}

-- Ingredient = Class(function(self, ingredienttype, amount, atlas, deconstruct, imageoverride)

---给MOD物品添加一个分类(过滤器),注意本函数必须放在main函数之前调用,否则无法将新物品添加到此过滤器中
---@param id string 全大写的filers名称
---@param atlas_path string XML路径
---@param image_path string TEX名字
---@param description string 描述,注意中英文译名
function dst_lan:addRecipeFilter(id,atlas_path,image_path,description)
    AddRecipeFilter({name = string.upper(id),atlas = atlas_path,image = image_path})
    STRINGS.UI.CRAFTING_FILTERS[string.upper(id)] = description
end

-- @lan: filters:
--[[ 	
ARMOUR -- Armor | 盔甲
CHARACTER -- Survivor Items | 冒险家物品
CLOTHING -- Clothing | 服装
CONTAINERS -- Storage Solutions | 储物方案
COOKING -- Cooking | 烹饪
CRAFTING_STATION -- All Crafting Stations | 所有制作站
DECOR -- Decorations | 装饰
EVERYTHING -- Everything | 所有
FAVORITES -- Favorites | 收藏夹
FISHING -- Fishing | 钓鱼
GARDENING -- Food & Gardening | 食物和耕种
LIGHT -- Light Sources | 光源
MAGIC -- Magic | 魔法
MODS -- Modded Items | 模组物品
PROTOTYPERS -- Prototypers & Stations | 原型工具和制作站
RAIN -- Rain Gear | 雨具
REFINE -- Refined Materials | 精炼材料
RESTORATION -- Healing | 治疗
RIDING -- Beefalo Riding | 骑乘皮弗娄牛
SEAFARING -- Seafaring | 航行
SPECIAL_EVENT -- Special Event | 特别活动
STRUCTURES -- Structures | 建筑
SUMMER -- Summer Items | 夏季物品
TOOLS -- Tools | 工具
WEAPONS -- Weapons | 武器
WINTER -- Winter Items | 冬季物品
]]

-- local recipe_all = {
	
	-- {
	-- 	recipe_name = 'choleknife_recipe_1', --食谱ID
	-- 	ingredients = { --配方
	-- 		Injectatlas('pack_gold',1), 
	-- 		Ingredient('rope',2), 
	-- 		Ingredient('log',2),
	-- 	},
	-- 	tech = TECH.SCIENCE_ONE, --所需科技 ,TECH.LOST 表示需要蓝图才能解锁
	-- 	isOriginalItem = true, --是官方物品(官方物品严禁写atlas和image路径,因为是自动获取的),不写则为自定义物品
	-- 	config ={ --其他的一些配置,可不写
	-- 		--制作出来的物品,不写则默认制作出来的预制物为食谱ID
	-- 		product = 'choleknife', 
	-- 		--xml路径,不写则默认路径为,'images/inventoryimages/'..product..'.xml' 或 'images/inventoryimages/'..recipe_name..'.xml'
	-- 		atlas = 'images/choleknife.xml',
	-- 		--图片名称,不写则默认名称为 product..'.tex' 或 recipe_name..'.tex'
	-- 		image = 'choleknife.tex',
	-- 		--制作出的物品数量,不写则为1
	-- 		numtogive = 40,
	--		--不需要解锁
	--		nounlock = false,
	-- 	},
	--	filters = {'CHARACTER'} --将物品添加到这些分类中
	-- },


	
------------------------------------------------------------------
--TOOLS-----------------------------------------------------------
------------------------------------------------------------------


------------------------------------------------------------------
--WEAPONS----------------------------------------------------------
------------------------------------------------------------------

------------------------------------------------------------------
--ARMOUR-----------------------------------------------------------
------------------------------------------------------------------

----------
--original
----------

	-- {
	-- 	recipe_name = 'plenty_sewing_tape', 
	-- 	isOriginalItem = true,
	-- 	ingredients = {
	-- 		Ingredient('silk',40),
	-- 		Ingredient('rope',40),
	-- 	},
	-- 	tech = TECH.NONE,
	-- 	config = {
	-- 		product = 'sewing_tape',
	-- 		numtogive = 40,
	-- 	},
	-- 	filters = {'CLOTHING'}
	-- },

-- }

---将a配方参照b配方位置重排
---@param a string 被排配方名
---@param b string 参照配方名
---@param filter_name string 配方分类名
---@param offset number 偏移量
function dst_lan:sortRecipe(a, b, filter_name, offset)
	local filter = CRAFTING_FILTERS[filter_name]
	if filter and filter.recipes then
		for sortvalue, product in ipairs(filter.recipes) do
			if product == a then
				table.remove(filter.recipes, sortvalue)
				break
			end
		end

		local target_position = #filter.recipes + 1
		for sortvalue, product in ipairs(filter.recipes) do
			if product == b then
				target_position = sortvalue + offset
				break
			end
		end
		table.insert(filter.recipes, target_position, a)
	end
end

---将a配方放到b配方之后
---@param a string 被排配方名
---@param b string 参照配方名
---@param filter_name string 配方分类名
function dst_lan:sortAfter(a, b, filter_name)
	self:sortRecipe(a, b, filter_name, 1)
end

---按表内配方顺序重排
---@param tbl string[] 配方表
---@param filter_name string 过滤器
function dst_lan:sortRecipeArray(tbl,filter_name)
	for i = 1, #tbl-1 do
		self:sortAfter(tbl[i+1],tbl[i],filter_name)
	end
end

---总是显示配方
---@param tbl string[] 配方表
function dst_lan:alwaysShowRecipes(tbl)
	local alwaysShowRecipe = {}
	for i,v in ipairs(tbl) do
		alwaysShowRecipe[v] = true
	end
	AddClassPostConstruct("widgets/redux/craftingmenu_hud", function(self)
		local old_RebuildRecipes = self.RebuildRecipes
		function self:RebuildRecipes(...)
			local res = {old_RebuildRecipes(self,...)}
			if self.owner ~= nil and self.owner.replica.builder ~= nil then
				for _, v in pairs(AllRecipes) do
					if IsRecipeValid(v.name) then
						if alwaysShowRecipe[v.name] and self.valid_recipes[v.name] then
							local meta = self.valid_recipes[v.name].meta
							if meta.build_state == "hide" then
								meta.build_state = "hint"
							end
						end
					end
				end
			end
			return unpack(res)
		end
	end)
end

function dst_lan:main(tbl_recipe_all)
	local alwaysshow = {}

    for _,r in ipairs(tbl_recipe_all) do 
        if not r.isHidden then
			-- 保证有config
			if r.config == nil then 
				r.config = {}
			end
			-- 如果是原版物品
			if r.isOriginalItem then
			else -- 非原版物品
				-- 没有product,则用配方名,确保有product
				if r.config.product == nil then
					r.config.product = r.recipe_name
				end
				-- 没有图集路径,则用product路径
				if r.config.atlas == nil then
					r.config.atlas = 'images/inventoryimages/'..r.config.product..'.xml'
				end
				if r.config.image == nil then
					r.config.image = r.config.product..'.tex'
				end
				-- 数量
				if r.config.numtogive == nil then
					r.config.numtogive = 1
				end
			end
			-- 如果需要常显
			if r.isAlwaysShown then
				table.insert(alwaysshow, r.recipe_name)
			end

			AddRecipe2(r.recipe_name, r.ingredients, r.tech, r.config, r.filters)
		end
    end

	self:alwaysShowRecipes(alwaysshow)
end

return dst_lan










