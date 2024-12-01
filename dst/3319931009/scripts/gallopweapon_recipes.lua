local AddRecipe2 = AddRecipe2
local tag = "gallop" -- builder_tag
local function AddRec(name, def)
  if def.disabled then return end
  if def.delay then
    -- #note that delay will actually change the position！
    def.delay = false
    AddSimPostInit(function() AddRec(name, def) end)
  end
  -- settings={builder_tag = def.tag, placer = def.placer, no_deconstruct = def.nodeconstrct,nounlock,image,atlas,product}
  -- filters={FAVORITES  CRAFTING_STATION  SPECIAL_EVENT
  --          MODS CHARACTER  TOOLS LIGHT  PROTOTYPERS REFINE
  --          WEAPONS  ARMOUR    CLOTHING  RESTORATION  MAGIC
  --          DECOR STRUCTURES CONTAINERS  COOKING  GARDENING
  --          FISHING  SEAFARING   RIDING  WINTER SUMMER RAIN}
  -- tag is specified above
  if def.tag == true then
    if not def.settings then def.settings = {} end
    if not def.settings.builder_tag then def.settings.builder_tag = tag end
  end
  -- character filter
  if def.character == true then
    if not def.filters then def.filters = {} end
    if not table.contains(def.filters, "CHARACTER") then
      table.insert(def.filters, "CHARACTER")
    end
  end
  local tech = def.tech
  if type(tech) == "string" then tech = TECH[tech] end
  tech = TECH[tech] or tech
  if not tech then
    print("[AddRec] Error: TECH[" .. tostring(def.tech or "") .. "] or " ..
            tostring(def.tech or "") .. " is nil")
    return
  end
  local ingredient_table = {}
  if def.ingredients then
    for i, data in ipairs(def.ingredients) do
      local ing = Ingredient(unpack(data))
      table.insert(ingredient_table, ing)
    end
  end
  if def.actual_product then
    if not def.settings then def.settings = {} end
    def.settings.image = def.settings.image or def.actual_product .. ".tex"
    def.settings.product = def.settings.product or def.actual_product
    if not def.ingredients then
      ingredient_table = AllRecipes[def.actual_product] and
                           AllRecipes[def.actual_product].ingredients
    end
  end
  if not STRINGS.NAMES[name:upper()] then
    if STRINGS.NAMES[def.settings and def.settings.product and
      def.settings.product:upper()] then
      STRINGS.NAMES[name:upper()] = STRINGS.NAMES[def.settings.product:upper()]
    end
  end
  if def.settings and def.settings.product and
    not STRINGS.RECIPE_DESC[def.settings.product:upper()] then
    if STRINGS.RECIPE_DESC[name:upper()] then
      STRINGS.RECIPE_DESC[def.settings.product:upper()] =
        STRINGS.RECIPE_DESC[name:upper()]
    end
  end
  if def.actual_describe then
    def.settings.description = type(def.actual_describe) == "string" and
                                 def.actual_describe or name
  end
  return AddRecipe2(name, ingredient_table, tech, def.settings, def.filters)
end

local defs = {
  -- {
  --   gallop_whip = {
  --     ingredients = {
  --       {"pickaxe", 1},
  --       {"marble", 2},
  --       {"goldnugget", 4},
  --       {"flint", 6}
  --     },
  --     tech = "SCIENCE_TWO",
  --     filters = {"WEAPONS",'TAB_LOL_WP'}
  --   }
  -- },
  -- {
  --   gallop_bloodaxe = {
  --     ingredients = {
  --       {"gallop_whip", 1},
  --       {"shadow_battleaxe", 1},
  --       {"dreadstone", 8},
  --       {"horrorfuel", 4},
  --       {"voidcloth", 2}
  --     },
  --     tech = "SHADOWFORGING_TWO",
  --     settings = {nounlock = true, station_tag = "shadow_forge"},
  --     filters = {"WEAPONS", "MODS",'TAB_LOL_WP'}
  --   }
  -- },
  -- {
  --   gallop_breaker = {
  --     ingredients = {
  --       {"multitool_axe_pickaxe", 1},
  --       {"gnarwail_horn", 2},
  --       {"minotaurhorn", 1},
  --       {"cookiecuttershell", 8},
  --       {"thulecite", 6}
  --     },
  --     tech = "ANCIENT_THREE",
  --     settings = {station_tag = "altar", nounlock = true},
  --     filters = {"CRAFTING_STATION", "WEAPONS", "MODS",'TAB_LOL_WP'}
  --   }
  -- },
}
for i, v in ipairs(defs) do for name, def in pairs(v) do AddRec(name, def) end end
