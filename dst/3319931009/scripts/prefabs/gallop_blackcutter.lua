local assets =
{
    Asset("ANIM", "anim/gallop_blackcutter.zip"),
}

local function Repaire(inst, percent)
    local finiteuses = inst.components.finiteuses
    if finiteuses ~= nil then
        finiteuses:SetUses(math.max(0, math.min(finiteuses.total, finiteuses:GetUses()+finiteuses.total*percent)))
    end
end

local function DoRegen(inst, owner)
    if owner.components.sanity ~= nil and owner.components.sanity:IsInsanityMode() then
        Repaire(inst, .004)
    end
end

local function StartRegen(inst, owner)
    if inst.regentask == nil then
        inst.regentask = inst:DoPeriodicTask(8, DoRegen, nil, owner)
    end
end

local function StopRegen(inst)
    if inst.regentask ~= nil then
        inst.regentask:Cancel()
        inst.regentask = nil
    end
end

local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "gallop_blackcutter", inst.GUID, "swap_gallop_blackcutter")
    else
        owner.AnimState:OverrideSymbol("swap_object", "gallop_blackcutter", "swap_gallop_blackcutter")
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if owner.components.combat then
        inst.atk_speed_old = owner.components.combat.min_attack_period
        owner.components.combat:SetAttackPeriod(inst.atk_speed_old*1.95)
    end

    StartRegen(inst, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    if owner.components.combat and owner.components.combat.min_attack_period == inst.atk_speed_old*1.95 then
        owner.components.combat:SetAttackPeriod(inst.atk_speed_old)
    end

    StopRegen(inst)
end

local function ShouldAcceptItem(inst, item, giver)
    return item.prefab == "nightmarefuel" or item.prefab == "horrorfuel"
end

local function OnGetItemFromPlayer(inst, giver, item)
    if item.prefab == "nightmarefuel" then
        Repaire(inst, .2)
    elseif item.prefab == "horrorfuel" then
        Repaire(inst, 1)
    end
end

local function hitfx(pos)
    local fx = SpawnPrefab("shadowstrike_slash2_fx")
    fx.Transform:SetPosition(pos:Get())
end

local function onattack(inst, attacker, target)
    --local atk_speed = attacker.components.combat.min_attack_period
    --attacker.components.combat:OverrideCooldown(atk_speed*1.2)

    target.gallop_blackcutter_stack = math.min((target.gallop_blackcutter_stack or 0)+1, 5)

    if target.gallop_blackcutter_task == nil then
        target.gallop_blackcutter_task = target:DoPeriodicTask(1, function()
            if target:IsValid() and target.components.health and not target.components.health:IsDead() then
                local tar_maxhp = target.components.health.maxhealth
                local tar_cur_percent = target.components.health:GetPercent()
                local tar_cur_hp = tar_cur_percent * tar_maxhp
                local tar_should_hp = tar_cur_hp - 5*target.gallop_blackcutter_stack
                local tar_should_percent = math.clamp(tar_should_hp/tar_maxhp,0,1)

                -- TheNet:Announce(tar_should_percent)
                target.components.health:SetPercent(tar_should_percent,nil,attacker)
                -- target.components.health:DoDelta(-5*target.gallop_blackcutter_stack)

                local fx = SpawnPrefab("ink_puddle_land")
                fx.Transform:SetPosition(target:GetPosition():Get())
            end
        end, .25)

        target.gallop_blackcutter_task.onfinish = function()
            target.gallop_blackcutter_task = nil
            target.gallop_blackcutter_stack = nil
        end
    end
    target.gallop_blackcutter_task.limit = 5
    
    hitfx(target:GetPosition())
end

local function CalcDapperness(inst, owner)
    local insanity = owner.components.sanity ~= nil and owner.components.sanity:IsInsanityMode()
    return insanity and inst.components.finiteuses:GetPercent() < 1 and TUNING.CRAZINESS_MED or 0
end

local function AddWeapon(inst)
    if inst.components.weapon == nil then
        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(68)
        inst.components.weapon:SetRange(1.2)
        inst.components.weapon:SetOnAttack(onattack)
    end
end

local function AddEquippable(inst)
    if inst.components.equippable == nil then
        inst:AddComponent("equippable")
        inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)
        inst.components.equippable.walkspeedmult = .9
        inst.components.equippable.dapperfn = CalcDapperness
        inst.components.equippable.is_magic_dapperness = true
    end
end

local function ReturnItem(inst)
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

local function OnUseDelta(inst, data)
    if not data then
        return
    end
    local percent = data.percent
    if percent > 0 then
        AddWeapon(inst)
        AddEquippable(inst)
        inst:RemoveTag("outofuse")
    else
        ReturnItem(inst)
        if inst.components.weapon ~= nil then
            inst:RemoveComponent("weapon")
        end
        if inst.components.equippable ~= nil then
            inst:RemoveComponent("equippable")
        end
        inst:AddTag("outofuse")
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("gallop_blackcutter")
    inst.AnimState:SetBuild("gallop_blackcutter")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("weapon")
    inst:AddTag("tool")
    inst:AddTag("nopunch")
    inst:AddTag("gallop_blackcutter")

    MakeInventoryFloatable(inst, "small", nil, 1)

    inst.gallop_blackcutter_cd = 20

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.hit_fx = hitfx

    AddWeapon(inst)

    inst:AddComponent("gallop_blackcutter")

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnChargedFn(function() inst:RemoveTag("gallop_blackcutter_discharge") end)
    inst.components.rechargeable:SetOnDischargedFn(function() inst:AddTag("gallop_blackcutter_discharge") end)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.CHOP, 3)
    -------
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(250)
    inst.components.finiteuses:SetUses(250)
    inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, 1)

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("damagetypebonus")
    inst.components.damagetypebonus:AddBonus("lunar_aligned", inst, TUNING.WEAPONS_NIGHTMARE_VS_LUNAR_BONUS)

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(2)

    AddEquippable(inst)

    inst:ListenForEvent("percentusedchange", OnUseDelta)

    MakeHauntableLaunch(inst)

    return inst
end

local DETECT_ONE_OF_TAGS = { "monster", "character", "animal", "smallcreature" }

local TARGET_RADIUS = 6
local TARGET_MUST_TAGS = nil
local TARGET_NO_TAGS = { "epic", "notraptrigger", "ghost", "player", "INLIMBO", "flight", "invisible", "notarget" }
local TARGET_ONE_OF_TAGS = DETECT_ONE_OF_TAGS

local function CanPanic(target)
    if target.components.hauntable ~= nil and target.components.hauntable.panicable or target.has_nightmare_state then
        return true
    end
end

local function EndSpeedMult(target)
    target._shadow_trap_task = nil
    target._shadow_trap_fx:KillFX()
    target._shadow_trap_fx = nil
    if target.components.locomotor ~= nil then
        target.components.locomotor:RemoveExternalSpeedMultiplier(target, "gallop_blackcutter")
    end
end

local function TryTrapTarget(inst, targets)
    local buff_time = 4
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, TARGET_RADIUS, TARGET_MUST_TAGS, TARGET_NO_TAGS, TARGET_ONE_OF_TAGS)) do
        if not targets[v] and
            CanPanic(v) and
            not (v.components.health ~= nil and v.components.health:IsDead()) and
            v.entity:IsVisible()
            then
            targets[v] = true
            local x1, y1, z1 = v.Transform:GetWorldPosition()
            local fx = SpawnPrefab("shadow_despawn")
            local platform = v:GetCurrentPlatform()
            if platform ~= nil then
                fx.entity:SetParent(platform.entity)
                fx.Transform:SetPosition(platform.entity:WorldToLocalSpace(x1, y1, z1))
                fx:ListenForEvent("onremove", function()
                    fx.Transform:SetPosition(fx.Transform:GetWorldPosition())
                    fx.entity:SetParent(nil)
                end, platform)
            else
                fx.Transform:SetPosition(x1, y1, z1)
            end
            if v.has_nightmare_state then
                v:PushEvent("ms_forcenightmarestate", { duration = TUNING.SHADOW_TRAP_NIGHTMARE_TIME + math.random() })
            end
            if not (v.sg ~= nil and v.sg:HasStateTag("noattack")) then
                v:PushEvent("attacked", { attacker = nil, damage = 0 })
            end
            if not v.has_nightmare_state and v.components.hauntable ~= nil and v.components.hauntable.panicable then
                v.components.hauntable:Panic(buff_time)
                if v.components.locomotor ~= nil then
                    if v._shadow_trap_task ~= nil then
                        v._shadow_trap_task:Cancel()
                    else
                        v._shadow_trap_fx = SpawnPrefab("shadow_trap_debuff_fx")
                        v._shadow_trap_fx.entity:SetParent(v.entity)
                        v._shadow_trap_fx:OnSetTarget(v)
                    end
                    v._shadow_trap_task = v:DoTaskInTime(buff_time, EndSpeedMult)
                    v.components.locomotor:SetExternalSpeedMultiplier(v, "gallop_blackcutter", TUNING.SHADOW_TRAP_SPEED_MULT)
                end
            end
        end
    end
end

local function trap()
    local inst = CreateEntity()
    inst.entity:SetCanSleep(false)
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.AnimState:SetBank("mushroombomb_base")
    inst.AnimState:SetBuild("mushroombomb_base")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetFinalOffset(3)
    inst.AnimState:SetScale(1.9, 1.9)
    inst.AnimState:SetMultColour(0, 0, 0, .5)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:ListenForEvent("animover", inst.Remove)
    inst.TryTrapTarget = TryTrapTarget

    return inst
end

return Prefab("gallop_blackcutter", fn, assets),
       Prefab("gallop_blackcutter_trap", trap, assets)