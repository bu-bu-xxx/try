---@diagnostic disable: undefined-global, trailing-space
local prefab_id = 'lol_wp_overlordbloodarmor'

local assets =
{
    Asset("ANIM", "anim/"..prefab_id..".zip"),
    Asset("ATLAS", "images/inventoryimages/"..prefab_id..".xml"),
}

local RESISTANCES =
{
    "_combat",
    "explosive",
    "quakedebris",
    "lunarhaildebris",
    "caveindebris",
    "trapdamage",
}

local function OnShieldOver(inst, OnResistDamage)
    inst.task = nil
    for i, v in ipairs(RESISTANCES) do
        inst.components.resistance:RemoveResistance(v)
    end
    inst.components.resistance:SetOnResistDamageFn(OnResistDamage)
end


local SHIELD_DURATION = 10 * FRAMES

local function OnBlocked(owner)
    owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", prefab_id, "swap_body")
    inst:ListenForEvent("blocked", OnBlocked, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    inst:RemoveEventCallback("blocked", OnBlocked, owner)
end

local function ShouldResistFn(inst)
    if not inst.components.equippable:IsEquipped() then
        return false
    end
    local owner = inst.components.inventoryitem.owner

    return owner ~= nil
        and not (owner.components.inventory ~= nil and
                owner.components.inventory:EquipHasTag("forcefield"))
end

local function OnResistDamage(inst)--, damage)
    local owner = inst.components.inventoryitem:GetGrandOwner() or inst
    local fx = SpawnPrefab("shadow_shield"..math.random(1,6))
    fx.entity:SetParent(owner.entity)

    if inst.task ~= nil then
        inst.task:Cancel()
    end
    inst.task = inst:DoTaskInTime(SHIELD_DURATION, OnShieldOver, OnResistDamage)
    inst.components.resistance:SetOnResistDamageFn(nil)

    inst.components.rechargeable:Discharge(TUNING.MOD_LOL_WP.OVERLORDBLOOD.CD)
end


local function OnChargedFn(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
        inst.components.resistance:SetOnResistDamageFn(OnResistDamage)
    end
    for i, v in ipairs(RESISTANCES) do
        inst.components.resistance:AddResistance(v)
    end
end

local function onpercentusedchange(inst,data)
    local cur_percent = data and data.percent
    -- when armor durability < .8, start auto repair task
    if cur_percent and cur_percent <= TUNING.MOD_LOL_WP.OVERLORDBLOOD.AUTO_REPAIR.START then
        local owner = inst.components.equippable and inst.components.equippable:IsEquipped() and inst.components.inventoryitem and inst.components.inventoryitem.owner
        if owner then
            if inst.taskperiod_lol_wp_overlordbloodarmor_autorepair == nil then
                local time_passed = 0
                inst.taskperiod_lol_wp_overlordbloodarmor_autorepair = inst:DoPeriodicTask(TUNING.MOD_LOL_WP.OVERLORDBLOOD.AUTO_REPAIR.INTERVAL_REPAIR,function()
                    local cur_percent = inst and inst.components.armor and inst.components.armor:GetPercent()
                    -- 判断耐久是否到达预设值,以停止
                    if cur_percent and cur_percent >= TUNING.MOD_LOL_WP.OVERLORDBLOOD.AUTO_REPAIR.END then
                        if inst.taskperiod_lol_wp_overlordbloodarmor_autorepair then
                            inst.taskperiod_lol_wp_overlordbloodarmor_autorepair:Cancel()
                            inst.taskperiod_lol_wp_overlordbloodarmor_autorepair = nil
                        end
                        return
                    end

                    -- 获取装备者
                    local owner = inst.components.equippable and inst.components.equippable:IsEquipped() and inst.components.inventoryitem and inst.components.inventoryitem.owner
                    if owner then
                        local player_maxhp = owner.components.health and not owner.components.health:IsDead() and owner.components.health.maxhealth
                        if player_maxhp then
                            -- 获取玩家血量够不够
                            local player_cur_hp = owner.components.health:GetPercent() * player_maxhp
                            if player_cur_hp > TUNING.MOD_LOL_WP.OVERLORDBLOOD.AUTO_REPAIR.DRAIN then
                                -- 判断是否到时间去扣玩家血
                                time_passed = time_passed%TUNING.MOD_LOL_WP.OVERLORDBLOOD.AUTO_REPAIR.INTERVAL + TUNING.MOD_LOL_WP.OVERLORDBLOOD.AUTO_REPAIR.INTERVAL_REPAIR
                                if time_passed >= TUNING.MOD_LOL_WP.OVERLORDBLOOD.AUTO_REPAIR.INTERVAL then
                                    owner.components.health:DoDelta(-TUNING.MOD_LOL_WP.OVERLORDBLOOD.AUTO_REPAIR.DRAIN)
                                end
                                -- 每次回复耐久
                                local armor_maxcondition = inst.components.armor.maxcondition
                                local armor_cur_condition = armor_maxcondition * cur_percent
                                local armor_new_percent = math.min(1,(armor_cur_condition + TUNING.MOD_LOL_WP.OVERLORDBLOOD.AUTO_REPAIR.REPAIR)/armor_maxcondition)
                                inst.components.armor:SetPercent(armor_new_percent)
                            end
                        end
                    end
                end)
            end
        end
    end
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
    inst:AddTag(prefab_id..'_nofiniteuses')
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

    inst:AddTag("shadow_item")

	--shadowlevel (from shadowlevel component) added to pristine state for optimization
	inst:AddTag("shadowlevel")

    inst:AddTag('lol_wp_overlordbloodarmor')

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
    inst.components.armor:InitCondition(TUNING.MOD_LOL_WP.OVERLORDBLOOD.DURABILITY, TUNING.MOD_LOL_WP.OVERLORDBLOOD.ABSORB)
    inst.components.armor:SetKeepOnFinished(true) -- 耐久用完保留
    inst.components.armor:SetOnFinished(onfinished)

    inst:AddComponent("planardefense")
    inst.components.planardefense:SetBaseDefense(TUNING.MOD_LOL_WP.OVERLORDBLOOD.DEFEND_PLANAR)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.is_magic_dapperness = true
    inst.components.equippable.dapperness = TUNING.MOD_LOL_WP.OVERLORDBLOOD.DARPPERNESS/54

    inst:AddComponent("shadowlevel")
	inst.components.shadowlevel:SetDefaultLevel(TUNING.MOD_LOL_WP.OVERLORDBLOOD.SHADOW_LEVEL)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetChargeTime(TUNING.MOD_LOL_WP.OVERLORDBLOOD.CD)
    -- inst.components.rechargeable:SetOnDischargedFn(function(inst) end)
    inst.components.rechargeable:SetOnChargedFn(OnChargedFn)

    inst:AddComponent("resistance")
    inst.components.resistance:SetShouldResistFn(ShouldResistFn)
    inst.components.resistance:SetOnResistDamageFn(OnResistDamage)
    for i, v in ipairs(RESISTANCES) do
        inst.components.resistance:AddResistance(v)
    end



    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.MOD_LOL_WP.OVERLORDBLOOD.WATERPROOF)

    inst:ListenForEvent('percentusedchange',onpercentusedchange)

    --MakeHauntableLaunch(inst)
    -- MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    return inst
end

return Prefab(prefab_id, fn, assets)
