---@diagnostic disable: lowercase-global, undefined-global, trailing-space

local function removeItem(obj)
    if obj.components.stackable then
        obj.components.stackable:Get():Remove()
    else
        obj:Remove()
    end
end

local function upequipItem(inst)
    if inst.components.equippable ~= nil and inst.components.equippable:IsEquipped() then
        local owner = inst.components.inventoryitem.owner
        if owner ~= nil and owner.components.inventory ~= nil then
            local item = owner.components.inventory:Unequip(inst.components.equippable.equipslot)
            if item ~= nil then
                owner.components.inventory:GiveItem(item, nil, owner:GetPosition())
            end
        end
    end
end

local function TouchFn(item)
	if item.components and item.components.lol_heartsteel_num then
		item.components.lol_heartsteel_num:TouchSound()
	end
end

---@type data_componentaction[]
local data = {
    -- 心之钢
    {
		id = "ACTION_LOL_HEARTSTEEL_TOUCH_ININV",
		str = STRINGS.MOD_LOL_WP.ACTIONS.ACTION_LOL_HEARTSTEEL_TOUCH,
		fn = function(act)
			if act.doer ~= nil and act.invobject ~= nil then
                TouchFn(act.invobject)
                return true
            else
				return false
			end
		end,
		state = "give",
		actiondata = {
			priority = 99,
			mount_valid = true,
		},
        type = "INVENTORY",
		component = "inventoryitem",
		testfn = function(inst,doer,actions,right)
            return doer:HasTag("player") and inst.prefab == 'lol_heartsteel' and inst.replica.equippable:IsEquipped()
        end,
	},
    {
		id = "ACTION_LOL_HEARTSTEEL_TOUCH_ONGROUND",
		str = STRINGS.MOD_LOL_WP.ACTIONS.ACTION_LOL_HEARTSTEEL_TOUCH,
		fn = function(act)
			if act.doer ~= nil and act.target ~= nil then
                TouchFn(act.target)
                return true
            else
				return false
			end
		end,
		state = "give",
		actiondata = {
			priority = 99,
			mount_valid = true,
		},
        type = "SCENE",
		component = "inventoryitem",
		testfn = function(inst,doer,actions,right)
            return right and doer:HasTag("player") and inst.prefab == 'lol_heartsteel'
        end,
	},
    -- 修理 finiteuse
    {
        id = 'ACTION_LOL_WP_REPAIR',
        str = STRINGS.MOD_LOL_WP.ACTIONS.ACTION_LOL_WP_REPAIR,
        fn = function (act)
            if act.doer ~= nil and act.invobject ~= nil and act.target ~= nil then
                return (function (obj,tar)
                    if tar.prefab and obj.prefab and tar.components.finiteuses then
                        local delta = TUNING.MOD_LOL_WP.REPAIR[string.upper(tar.prefab)] and TUNING.MOD_LOL_WP.REPAIR[string.upper(tar.prefab)][string.upper(obj.prefab)]
                        if delta then
                            local cur = tar.components.finiteuses:GetPercent()
                            local new = math.min(1,cur + delta)
                            tar.components.finiteuses:SetPercent(new)
                            removeItem(obj)
                            -- lol_wp_divine_nofiniteuses
                            if tar:HasTag(tar.prefab..'_nofiniteuses') then
                                tar:RemoveTag(tar.prefab..'_nofiniteuses')
                            end
                            return true
                        end
                    end
                    return false
                end)(act.invobject,act.target)
            end
            return false
        end,
        state = 'give',
        actiondata = {
            mount_valid = true,
            priority = 100,
        },
        type = "USEITEM",
        component = 'inventoryitem',
        testfn = function (inst, doer, target, actions, right)
            if right and doer:HasTag("player") and target.prefab and TUNING.MOD_LOL_WP.REPAIR[string.upper(target.prefab)] then
                local canrepair = inst and inst.prefab and TUNING.MOD_LOL_WP.REPAIR[string.upper(target.prefab)][string.upper(inst.prefab)]
                if canrepair then
                    return true
                end
            end
            return false
        end,
    },
    -- 神圣分离者 跳劈
    {
        id = 'ACTION_LOL_WP_DIVINE_BLOW',
        str = STRINGS.MOD_LOL_WP.ACTIONS.ACTION_LOL_WP_DIVINE_BLOW,
        fn = function (act)
            if act.doer and act.doer:IsValid() and act.invobject and act.invobject:IsValid() and act.target and act.target:IsValid() and act.target.components.combat and act.target.components.health and not act.target.components.health:IsDead() then

                return (function (wp,victim,attacker)
                    -- 标记正在放技能
                    wp.lol_wp_divine_isuseingholyskill = true

                    -- sec kill shadow 
                    if victim:HasTag("shadow_aligned") and victim:HasTag("shadowcreature") then
                        victim.components.health:SetPercent(0,nil,attacker)
                    else
                        local victim_maxhealth = victim.components.health.maxhealth
                        local panel_dmg = TUNING.MOD_LOL_WP.DIVINE.DMG
                        local bonus_dmg = victim_maxhealth * TUNING.MOD_LOL_WP.DIVINE.HOLY_DMG
                        local total_dmg = panel_dmg + bonus_dmg

                        victim.components.combat:GetAttacked(attacker,total_dmg,wp)
                    end
                    local v_x,v_y,v_z = victim:GetPosition():Get()
                    local fx_3 = SpawnPrefab('hammer_mjolnir_cracklebase')
                    -- local fx_2 = SpawnPrefab('cracklehitfx')
                    local fx = SpawnPrefab('fx_dock_pop')
                    fx.Transform:SetPosition(v_x,v_y,v_z)
                    -- fx_2.Transform:SetPosition(v_x,v_y,v_z)
                    fx_3.Transform:SetPosition(v_x,v_y,v_z)

                    -- fx_2:DoTaskInTime(.6,function (inst)
                    --     inst:Remove()
                    -- end)
                    -- 神圣打击回血
                    if not victim:HasTag("structure") and not victim:HasTag("wall") and attacker.components.health and not attacker.components.health:IsDead() then
                        attacker.components.health:DoDelta(TUNING.MOD_LOL_WP.DIVINE.HOLY_HEAL,nil,nil,true)
                    end
                    

                    wp:AddTag('lol_wp_divine_holy_iscd')
                    -- if wp.taskintime_lol_wp_divine_holy_cd == nil then
                    --     wp.taskintime_lol_wp_divine_holy_cd = wp:DoTaskInTime(TUNING.MOD_LOL_WP.DIVINE.HOLY_CD,function()
                    --         wp:RemoveTag('lol_wp_divine_holy_iscd')
                    --         if wp.taskintime_lol_wp_divine_holy_cd then wp.taskintime_lol_wp_divine_holy_cd:Cancel() wp.taskintime_lol_wp_divine_holy_cd = nil end
                    --     end)
                    -- end
                    wp.components.rechargeable:Discharge(TUNING.MOD_LOL_WP.DIVINE.HOLY_CD)

                    -- 标记结束
                    wp.lol_wp_divine_isuseingholyskill = false
                    return true
                end)(act.invobject,act.target,act.doer)
            end
            return false
        end,
        state = 'wisprain_helmsplitter',
        actiondata = {
            mount_valid = false,
            priority = 100,
            distance = 7.5,
        },
        type = 'EQUIPPED',
        component = 'inventoryitem',
        testfn = function (inst, doer, target, actions, right)
            if right and doer:HasTag("player") and inst.prefab == 'lol_wp_divine' and not inst:HasTag('lol_wp_divine_holy_iscd') then
                if not target:HasTag("player") and not target:HasTag("wall") and target.replica.health and not target.replica.health:IsDead() then
                    return true
                end
            end
            return false
        end,
        -- noclient = true,
    },
    -- 三项 转换成护符
    {
        id = 'ACTION_LOL_WP_TRINITY_TF',
        str = STRINGS.MOD_LOL_WP.ACTIONS.ACTION_LOL_WP_TRINITY_TF,
        fn = function (act)
            if act.doer and act.invobject then
                return (function (obj)
                    if obj.lol_wp_trinity_type == 'weapon' then
                        if obj.components.equippable then
                            upequipItem(obj)
                            obj.components.equippable.equipslot = EQUIPSLOTS.NECK or EQUIPSLOTS.BODY
                            obj.lol_wp_trinity_type = 'amulet'
                            obj:AddTag('amulet')
                            obj.components.equippable.walkspeedmult = TUNING.MOD_LOL_WP.TRINITY.WALKSPEEDMULT
                            -- obj.components.equippable.dapperness = TUNING.MOD_LOL_WP.TRINITY.DARPPERNESS/54
                            return true
                        end
                    elseif obj.lol_wp_trinity_type == 'amulet' then
                        if obj.components.equippable then
                            upequipItem(obj)
                            obj.components.equippable.equipslot = EQUIPSLOTS.HANDS
                            obj.lol_wp_trinity_type = 'weapon'
                            obj:RemoveTag('amulet')
                            obj.components.equippable.walkspeedmult = 1
                            -- obj.components.equippable.dapperness = 0
                            return true
                        end
                    end
                    return false
                end)(act.invobject)
            end
            return false
        end,
        state = "give",
        actiondata = {
            mount_valid = true,
            priority = 999,
        },
        type = "INVENTORY",
        component = 'inventoryitem',
        testfn = function (inst, doer, actions, right)
            if doer:HasTag('player') and inst.prefab == 'lol_wp_trinity' and inst.replica.equippable and inst.replica.equippable:IsEquipped() then
                return true
            end
            
            return false
        end
    },
    -- armor组件 修复
    {
        id = 'ACTION_LOL_WP_REPAIR_ARMOR_COMPO',
        str = STRINGS.MOD_LOL_WP.ACTIONS.ACTION_LOL_WP_REPAIR_ARMOR_COMPO,
        fn = function (act)
            if act.doer and act.doer:IsValid() and act.invobject and act.invobject:IsValid() and act.target and act.target:IsValid() then
                return (function (obj,tar)
                    local cur_percent = tar.components.armor and tar.components.armor:GetPercent()
                    local repair_percent = obj and obj.prefab and TUNING.MOD_LOL_WP.REPAIR_ARMOR[string.upper(tar.prefab)][string.upper(obj.prefab)]
                    if cur_percent and repair_percent then
                        local new_percent = math.min(cur_percent + repair_percent,1)
                        tar.components.armor:SetPercent(new_percent)

                        removeItem(obj)

                        if tar:HasTag(tar.prefab..'_nofiniteuses') then
                            tar:RemoveTag(tar.prefab..'_nofiniteuses')
                        end
                        return true
                    end
                    return false
                end)(act.invobject,act.target)
            end
            return false
        end,
        state = 'give',
        actiondata = {
            mount_valid = true,
            priority = 10,
        },
        type = 'USEITEM',
        component = 'inventoryitem',
        testfn = function (inst, doer, target, actions, right)
            if doer:HasTag("player") and target.prefab and TUNING.MOD_LOL_WP.REPAIR_ARMOR[string.upper(target.prefab)] then
                local canrepair = inst and inst.prefab and TUNING.MOD_LOL_WP.REPAIR_ARMOR[string.upper(target.prefab)][string.upper(inst.prefab)]
                if canrepair then
                    return true
                end
            end
            return false
        end
    },
    -- 狂徒铠甲 主动：【真菌毒雾】
    {
        id = 'ACTION_LOL_WP_WARMOGARMOR_POISONFOG',
        str = STRINGS.MOD_LOL_WP.ACTIONS.ACTION_LOL_WP_WARMOGARMOR_POISONFOG,
        fn = function (act)
            if act.doer and act.doer:IsValid() and act.invobject and act.invobject:IsValid() then
                return (function (obj)
                    local x,_,z = obj:GetPosition():Get()
                    SpawnPrefab("sleepbomb_burst").Transform:SetPosition(x, 0, z)
                    SpawnPrefab("sleepcloud").Transform:SetPosition(x, 0, z)

                    obj:AddTag('lol_wp_warmogarmor_iscd')

                    obj.components.rechargeable:Discharge(TUNING.MOD_LOL_WP.WARMOGARMOR.SKILL_POISONFOG.CD)
                    return true
                end)(act.invobject)
            end
            return false
        end,
        state = "give",
        actiondata = {
            mount_valid = false,
            priority = 10,
        },
        type = "INVENTORY",
        component = 'inventoryitem',
        testfn = function (inst, doer, actions, right)
            return doer:HasTag("player") and inst.prefab == 'lol_wp_warmogarmor' and not inst:HasTag('lol_wp_warmogarmor_iscd') and inst.replica.equippable and inst.replica.equippable:IsEquipped()
        end
    },
    -- 恶魔之拥  佩戴时右键可以切换头盔和面具形态
    {
        id = 'ACTION_LOL_WP_DEMONICEMBRACEHAT_TF',
        str = STRINGS.MOD_LOL_WP.ACTIONS.ACTION_LOL_WP_DEMONICEMBRACEHAT_TF,
        fn = function (act)
            if act.doer and act.doer:IsValid() and act.invobject and act.invobject:IsValid() then
                return (function (obj)
                    obj.fn_lol_wp_demonicembracehat_tf(obj)

                    return true
                end)(act.invobject)
            end
            return false
        end,
        state = "give",
        actiondata = {
            mount_valid = true,
            priority = 10,
        },
        type = "INVENTORY",
        component = 'inventoryitem',
        testfn = function (inst, doer, actions, right)
            return doer:HasTag("player") and inst.prefab == 'lol_wp_demonicembracehat' and inst.replica.equippable and inst.replica.equippable:IsEquipped()
        end
    },
    -- 萃取  主动：【收割】
    {
        id = 'ACTION_LOL_WP_S7_CULL_SCRAPE',
        str = STRINGS.MOD_LOL_WP.ACTIONS.ACTION_LOL_WP_S7_CULL_SCRAPE,
        fn = function (act)
            if act.doer and act.doer:IsValid() and act.invobject and act.invobject:IsValid() and act.target and act.target:IsValid() then
                return (function(obj,tar,doer)
                    if obj.DoScytheAsWp ~= nil then
                        obj:DoScytheAsWp(tar,doer)
                        return true
                    end
                    return false
                end)(act.invobject,act.target,act.doer)
            end
            return false
        end,
        state = 'scythe',
        actiondata = {
            mount_valid = false,
            priority = 10,
            distance = 1.2,
        },
        type = "EQUIPPED",
        component = 'inventoryitem',
        testfn = function (inst, doer, target, actions, right)
            return right and doer:HasTag('player') and inst.prefab == 'lol_wp_s7_cull' and not inst:HasTag('lol_wp_s7_cull_iscd') and target.replica.health
        end
    }
}
return data

