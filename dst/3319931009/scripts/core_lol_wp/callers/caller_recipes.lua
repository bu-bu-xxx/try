---@diagnostic disable: lowercase-global, undefined-global, trailing-space

local modid = 'lol_wp'

local data = _require('core_'..modid..'/data/recipes')

API.RECIPE:addRecipeFilter('TAB_LOL_WP','images/tab_lol_wp.xml','tab_lol_wp.tex',STRINGS.MOD_LOL_WP.FILTERS.TAB_LOL_WP)

API.RECIPE:main(data)

