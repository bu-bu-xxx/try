---@diagnostic disable: undefined-global, trailing-space

local LANS = require('core_lol_wp/utils/sugar')

local prefab_id = 'lol_wp_warmogarmor'

local assets =
{
    Asset("ANIM", "anim/"..prefab_id..".zip"),
    Asset("ATLAS", "images/inventoryimages/"..prefab_id..".xml"),
}

local function enableHungerRate(enable,inst,player)
    if player and player:IsValid() and player.components.health and not player.components.health:IsDead() and player.components.hunger then
        if enable then
            player.components.hunger.burnratemodifiers:SetModifier(inst,TUNING.MOD_LOL_WP.WARMOGARMOR.HUNGERRATE,'lol_wp_warmogarmor_hungerratebuff')
        else
            player.components.hunger.burnratemodifiers:RemoveModifier(inst, 'lol_wp_warmogarmor_hungerratebuff')
        end
    end
    
end

local function skillHeart(enable,owner,inst)
    if enable then
        owner.taskintime_lol_wp_warmogarmor_notakedmg = owner:DoTaskInTime(TUNING.MOD_LOL_WP.WARMOGARMOR.SKILL_HEART.NO_TAKE_DMG_IN,function()
            if owner and owner:IsValid() then
                local cur_percent = owner.components.health:GetPercent()
                if cur_percent < TUNING.MOD_LOL_WP.WARMOGARMOR.SKILL_HEART.HP_PERCENT_BELOW and owner.taskperiod_lol_wp_warmogarmor_regen == nil then
                    -- 并额外增加10%移速
                    if inst.components.equippable then
                        inst.components.equippable.walkspeedmult = TUNING.MOD_LOL_WP.WARMOGARMOR.WALKSPEEDMULT + TUNING.MOD_LOL_WP.WARMOGARMOR.SKILL_HEART.WALKSPEEDMULT
                    end
                    owner.taskperiod_lol_wp_warmogarmor_regen = owner:DoPeriodicTask(TUNING.MOD_LOL_WP.WARMOGARMOR.SKILL_HEART.INTERVAL, function()
                        if LANS:checkAlive(owner) then
                            local cur_percent = owner.components.health:GetPercent()
                            if cur_percent >= 1 then
                                skillHeart(false,owner,inst)
                                skillHeart(true,owner,inst)
                                return
                            end
                            
                            local new_percent = math.min(cur_percent + TUNING.MOD_LOL_WP.WARMOGARMOR.SKILL_HEART.REGEN_PERCENT,1)
                            local maxhp = owner.components.health.maxhealth
                            local delta = (new_percent - cur_percent) * maxhp
                            if delta > 0 then
                                -- 每秒恢复自身5%最大生命值的血量
                                owner.components.health:DoDelta(delta)
                                -- 在触发狂徒之心时每秒消耗1点耐久
                                if inst.components.armor then
                                    local cur_condition = inst.components.armor.condition
                                    local new_condition = math.max(0,cur_condition - TUNING.MOD_LOL_WP.WARMOGARMOR.SKILL_HEART.RESUME)
                                    inst.components.armor:SetCondition(new_condition)
                                end
                            end
                        end
                    end)
                end
            end
        end)
    else
        if inst.components.equippable then
            inst.components.equippable.walkspeedmult = TUNING.MOD_LOL_WP.WARMOGARMOR.WALKSPEEDMULT
        end
        if owner.taskintime_lol_wp_warmogarmor_notakedmg then
            owner.taskintime_lol_wp_warmogarmor_notakedmg:Cancel()
            owner.taskintime_lol_wp_warmogarmor_notakedmg = nil
        end
        if owner.taskperiod_lol_wp_warmogarmor_regen then
            owner.taskperiod_lol_wp_warmogarmor_regen:Cancel()
            owner.taskperiod_lol_wp_warmogarmor_regen = nil
        end
    end
end

local function playerHealthChangeWhenWearWarmogArmor(player,data)
    
    local itm = player.equip_lol_wp_warmogarmor_item
    local new_percent = data.newpercent
    local old_percent = data.oldpercent
    if itm and new_percent and old_percent and new_percent < old_percent then
        skillHeart(false,player,itm)
        skillHeart(true,player,itm)
    end

end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", prefab_id, "swap_body")
    -- inst:ListenForEvent("blocked", OnBlocked, owner)

    enableHungerRate(true,inst,owner)

    inst.components.periodicspawner:Start()

    owner.equip_lol_wp_warmogarmor_item = inst 

    skillHeart(true,owner,inst)

    owner:ListenForEvent('healthdelta',playerHealthChangeWhenWearWarmogArmor)
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    -- inst:RemoveEventCallback("blocked", OnBlocked, owner)

    enableHungerRate(false,inst,owner)

    owner.equip_lol_wp_warmogarmor_item = nil

    skillHeart(false,owner,inst)

    inst.components.periodicspawner:Stop()

    owner:RemoveEventCallback('healthdelta',playerHealthChangeWhenWearWarmogArmor)
end

local function unequipItem(inst)
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

local function onfinished(inst)
    unequipItem(inst)
    inst:AddTag('lol_wp_warmogarmor_nofiniteuses')
end

local function onsave(inst,data)
    
end
local function onpreload(inst,data)
    
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(prefab_id)
    inst.AnimState:SetBuild(prefab_id)
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("wood")

    inst.foleysound = "dontstarve/movement/foley/logarmour"

    MakeInventoryFloatable(inst, "small", 0.2, 0.80)

    inst.entity:SetPristine()

    -- inst:AddTag("shadow_item")

	--shadowlevel (from shadowlevel component) added to pristine state for optimization
	-- inst:AddTag("shadowlevel")

    inst:AddTag("waterproofer")

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..prefab_id..".xml"

    -- inst:AddComponent("fuel")
    -- inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.MOD_LOL_WP.WARMOGARMOR.DURABILITY, TUNING.MOD_LOL_WP.WARMOGARMOR.ABSORB)
    inst.components.armor:SetKeepOnFinished(true) -- 耐久用完保留
    inst.components.armor:SetOnFinished(onfinished)
    -- hook教学,注意事项: 1. 长参保证适应未来函数的修改 2. 保证返回值的数量
    local old_TakeDamage = inst.components.armor.TakeDamage
    function inst.components.armor:TakeDamage(...)
        self.inst.lol_wp_warmogarmor_takedmg = true
        local res = {old_TakeDamage(self,...)}
        self.inst.lol_wp_warmogarmor_takedmg = false
        return unpack(res)
    end
    local old_SetCondition = inst.components.armor.SetCondition
    function inst.components.armor:SetCondition(...)
        if self.inst.lol_wp_warmogarmor_takedmg then
            return
        end
        return old_SetCondition(self,...)
    end

    -- inst:AddComponent("planardefense")
    -- inst.components.planardefense:SetBaseDefense(TUNING.MOD_LOL_WP.OVERLORDBLOOD.DEFEND_PLANAR)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    -- inst.components.equippable.is_magic_dapperness = true
    inst.components.equippable.dapperness = TUNING.MOD_LOL_WP.WARMOGARMOR.DARPPERNESS/54
    inst.components.equippable.walkspeedmult = TUNING.MOD_LOL_WP.WARMOGARMOR.WALKSPEEDMULT

    -- inst:AddComponent("shadowlevel")
	-- inst.components.shadowlevel:SetDefaultLevel(TUNING.MOD_LOL_WP.OVERLORDBLOOD.SHADOW_LEVEL)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetChargeTime(TUNING.MOD_LOL_WP.WARMOGARMOR.SKILL_POISONFOG.CD)
    -- inst.components.rechargeable:SetOnDischargedFn(function(inst) end)
    inst.components.rechargeable:SetOnChargedFn(function (inst)
        if inst:HasTag('lol_wp_warmogarmor_iscd') then
            inst:RemoveTag('lol_wp_warmogarmor_iscd')
        end
    end)


    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.MOD_LOL_WP.WARMOGARMOR.WATERPROOF)

    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.MOD_LOL_WP.WARMOGARMOR.INSULATION)
    inst.components.insulator:SetSummer()

    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetPrefab('spore_small')
    inst.components.periodicspawner:SetIgnoreFlotsamGenerator(true) -- NOTES(JBK): These spores float and self expire do not flotsam them.
    inst.components.periodicspawner:SetRandomTimes(TUNING.MUSHROOMHAT_SPORE_TIME, 1, true)



    --MakeHauntableLaunch(inst)
    -- MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    inst.OnSave = onsave
    -- inst.OnLoad = onload
    inst.OnPreLoad = onpreload

    return inst
end

return Prefab(prefab_id, fn, assets)
