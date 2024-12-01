---@diagnostic disable: lowercase-global, undefined-global, trailing-space

---@class api_dish
local dst_lan = {}


---让prefab可以进烹煮锅
---@param names string[] prefab
---@param tags table<string, number> tags
---@param cancook any
---@param candry any
function dst_lan:AddIngredientValues(names,tags,cancook,candry)
    -- (names)<>[] 
    -- (tags)<>[] 
    -- (cancook)<>[] 
    -- (candry)<>[] 
    -- AddIngredientValues({'gears'}, {gears=1})
    AddIngredientValues(names,tags,cancook,candry)
end

---将所有料理添加到对应锅中
---@param tbl table data table
function dst_lan:addToPot(tbl)
    for _, v in pairs(tbl) do
        if not v.isMasterfood then
            -- 将非大厨料理添加到烹饪锅
            AddCookerRecipe("cookpot", v)
            AddCookerRecipe("archive_cookpot", v)
        end
        --将所有料理添加到便携锅
        AddCookerRecipe("portablecookpot", v)
        if v.card_def then
            -- 如果有食谱卡定义则生成对应的食谱卡，大厨料理食谱卡无法被解读
            AddRecipeCard("cookpot", v)
        end
    end
end

---添加调味
---@param tbl table data table
function dst_lan:spiced(tbl)
    GenerateSpicedFoods(tbl)
   -- 生成的调味料理定义在官方的表中，但是由于模组加载晚于游戏因此需要自行添加到调味站配方
    local spicedfoods = require("spicedfoods")
    for _, v in pairs(spicedfoods) do
        if v.mod == true then
            -- 设定模组料理为非官方料理
            v.official = false
            -- 将调味料理配方添加到便携式调味站
            AddCookerRecipe("portablespicer", v)
        end
    end
end



---comment
---@param tbl data_dish
function dst_lan:main(tbl)
    self:addToPot(tbl)
    self:spiced(tbl)
end


return dst_lan