---@diagnostic disable: undefined-global
---@type string
local modid = 'lol_wp' -- 定义唯一modid

local new_PrefabFiles = {
	-- 'lol_wp_module_dishes',
	-- 'lol_wp_module_particle',
	'lol_wp_sheen',
	'lol_wp_divine',
	'lol_wp_trinity',
	'fx_lol_wp_trinity',
	'lol_wp_terraprisma',
	-- S6
    'lol_wp_overlordbloodarmor',
	'lol_wp_warmogarmor',
	'lol_wp_demonicembracehat',
	-- S7
	'lol_wp_s7_cull',
	'lol_wp_s7_doranblade',
	'lol_wp_s7_doranshield',
	'lol_wp_s7_doranring',
	'lol_wp_s7_tearsofgoddess',
	'lol_wp_s7_obsidianblade',

}

local new_Assets = {
    Asset("ATLAS","images/tab_lol_wp.xml"),

	Asset("SOUNDPACKAGE","sound/soundfx_lol_wp_divine.fev"),
	Asset("SOUND","sound/soundfx_lol_wp_divine.fsb"),

	-- 其他码师的物品的invimg
	Asset("ATLAS","images/inventoryimages/gallop_bloodaxe.xml"),
	Asset("ATLAS","images/inventoryimages/gallop_breaker.xml"),
	Asset("ATLAS","images/inventoryimages/gallop_whip.xml"),
}

for _, v in pairs(new_Assets) do table.insert(Assets, v) end
for _, v in pairs(new_PrefabFiles) do table.insert(PrefabFiles, v) end

-- 导入常量表
modimport('scripts/core_'..modid..'/data/tuning.lua')

-- 导入工具
modimport('scripts/core_'..modid..'/utils/_register.lua')

-- 导入功能API
modimport('scripts/core_'..modid..'/api/_register.lua')

-- 导入mod配置
TUNING['CONFIG_'..string.upper(modid)..'_LANG'] = currentlang == 'zh' and 'cn' or 'en'

-- 导入语言文件
modimport('scripts/core_'..modid..'/languages/'..TUNING['CONFIG_'..string.upper(modid)..'_LANG']..'.lua')

-- 导入调用器
-- modimport('scripts/core_'..modid..'/callers/caller_badge.lua.lua')
modimport('scripts/core_'..modid..'/callers/caller_ca.lua')
-- modimport('scripts/core_'..modid..'/callers/caller_container.lua.lua')
-- modimport('scripts/core_'..modid..'/callers/caller_dish.lua.lua')
-- modimport('scripts/core_'..modid..'/callers/caller_keyhandler.lua.lua')
modimport('scripts/core_'..modid..'/callers/caller_recipes.lua')
-- modimport('scripts/core_'..modid..'/callers/caller_stack.lua.lua')


-- 导入UI

-- 注册客机组件
AddReplicableComponent('lol_wp_s7_cull_counter')
AddReplicableComponent('lol_wp_s7_tearsofgoddess')

-- 导入钩子
modimport('scripts/core_'..modid..'/hooks/sup.lua')
modimport('scripts/core_'..modid..'/hooks/lol_wp_sheen.lua')
modimport('scripts/core_'..modid..'/hooks/lol_wp_divine.lua')
modimport('scripts/core_'..modid..'/hooks/lol_wp_trinity.lua')
modimport('scripts/core_'..modid..'/hooks/lol_wp_overlordbloodarmor.lua')
modimport('scripts/core_'..modid..'/hooks/lol_wp_warmogarmor.lua')
modimport('scripts/core_'..modid..'/hooks/lol_wp_demonicembracehat.lua')
modimport('scripts/core_'..modid..'/hooks/lol_wp_s7_cull.lua')
modimport('scripts/core_'..modid..'/hooks/lol_wp_s7_doranring.lua')
modimport('scripts/core_'..modid..'/hooks/lol_wp_s7_tearsofgoddess.lua')
modimport('scripts/core_'..modid..'/hooks/lol_wp_s7_obsidianblade.lua')
modimport('scripts/core_'..modid..'/hooks/lol_wp_s7_doranshield.lua')

-- 导入sg
modimport('scripts/core_'..modid..'/sg/leap_atk.lua')


