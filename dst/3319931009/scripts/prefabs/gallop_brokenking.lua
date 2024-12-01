local SpDamageUtil = require("components/spdamageutil")

local assets =
{
    Asset("ANIM", "anim/gallop_brokenking.zip"),
}

local TRAIL_FLAGS = { "shadowtrail" }
local function do_trail(inst)
    if not inst.entity:IsVisible() then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    if inst.sg ~= nil and inst.sg:HasStateTag("moving") then
        local theta = -inst.Transform:GetRotation() * DEGREES
        local speed = inst.components.locomotor:GetRunSpeed() * .1
        x = x + speed * math.cos(theta)
        z = z + speed * math.sin(theta)
    end
    local mounted = inst.components.rider ~= nil and inst.components.rider:IsRiding()
    local map = TheWorld.Map
    local offset = FindValidPositionByFan(
        math.random() * 2 * PI,
        (mounted and 1 or .5) + math.random() * .5,
        4,
        function(offset)
            local pt = Vector3(x + offset.x, 0, z + offset.z)
            return map:IsPassableAtPoint(pt:Get())
                and not map:IsPointNearHole(pt)
                and #TheSim:FindEntities(pt.x, 0, pt.z, .7, TRAIL_FLAGS) <= 0
        end
    )

    if offset ~= nil then
        SpawnPrefab("cane_ancient_fx").Transform:SetPosition(x + offset.x, 0, z + offset.z)
    end
end

local function RemoveBonus(inst, weapon)
    if inst.components.combat then
        inst.components.combat.externaldamagemultipliers:RemoveModifier(inst, "gallop_brokenking")
    end
    if inst.components.planardamage then
        inst.components.planardamage:RemoveMultiplier(inst, "gallop_brokenking")
    end
    if weapon and weapon.prefab == "gallop_brokenking" then
        weapon.link_active = nil
    end
end

local function AddBonus(inst, weapon)
    if inst.components.combat then
        inst.components.combat.externaldamagemultipliers:SetModifier(inst, 2, "gallop_brokenking")
    end
    if inst.components.planardamage then
        inst.components.planardamage:AddMultiplier(inst, 2, "gallop_brokenking")
    end
    if inst.components.talker then
        inst.components.talker:Say(STRINGS.GALLOP_BROKENKING.LINK_ACTIVE, 2, true)
    end
    local fx = SpawnPrefab("moonpulse_fx")
    fx.entity:SetParent(inst.entity)

    weapon.link_active = true
end

local function OnRefreshEquip(inst, data)
    inst:DoTaskInTime(0, function()
        if inst == nil or inst.components.inventory == nil then
            return
        end
        local hat = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if weapon and weapon.prefab == "gallop_brokenking" and hat then
            if hat.prefab == "alterguardianhat" then 
                AddBonus(inst, weapon)
            elseif hat.prefab == "gallophat2" then
                local item = hat.components.container and hat.components.container.slots[1]
                if item and item.prefab == "alterguardianhat" then
                    AddBonus(inst, weapon)
                else
                    RemoveBonus(inst, weapon)
                end
            end
        else
            RemoveBonus(inst, weapon)
        end
    end)
end

local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "gallop_brokenking", inst.GUID, "swap_gallop_brokenking")
    else
        owner.AnimState:OverrideSymbol("swap_object", "gallop_brokenking", "swap_gallop_brokenking")
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    inst:ListenForEvent("equip", OnRefreshEquip, owner)
    inst:ListenForEvent("unequip", OnRefreshEquip, owner)
    inst:ListenForEvent("gallophat2_link", OnRefreshEquip, owner)
    inst:ListenForEvent("gallophat2_unlink", OnRefreshEquip, owner)
    OnRefreshEquip(owner)

    if owner.gallop_brokenking_fx == nil then
        owner.gallop_brokenking_fx = owner:DoPeriodicTask(6 * FRAMES, do_trail, 2 * FRAMES)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    inst:RemoveEventCallback("equip", OnRefreshEquip, owner)
    inst:RemoveEventCallback("unequip", OnRefreshEquip, owner)
    inst:RemoveEventCallback("gallophat2_link", OnRefreshEquip, owner)
    inst:RemoveEventCallback("gallophat2_unlink", OnRefreshEquip, owner)
    inst.link_active = nil
    OnRefreshEquip(owner)

    if owner.gallop_brokenking_fx ~= nil then
        owner.gallop_brokenking_fx:Cancel()
        owner.gallop_brokenking_fx = nil
    end
end

local function hitfx(pos)
    local fx = SpawnPrefab("shadowstrike_slash_fx")
    fx.Transform:SetPosition(pos:Get())
end

local function IsLifeDrainable(target)
    return not target:HasAnyTag(NON_LIFEFORM_TARGET_TAGS) or target:HasTag("lifedrainable")
end

local function onattack(inst, attacker, target)
    if attacker.gallop_brokenking_jumping then
        return
    end
    if attacker.components.health and attacker.components.health:IsHurt() and IsLifeDrainable(target) then
        attacker.components.health:DoDelta(5, false, inst.prefab)
    end

    if inst.components.finiteuses:GetPercent() >= 1 then
        inst.components.finiteuses:SetUses(0)
        if target.components.health and not target.components.health:IsDead() then
            target.components.combat:GetAttacked(attacker, target.components.health.maxhealth*.02)
        end
        if attacker.components.health and attacker.components.health:IsHurt() then
            attacker.components.health:DoDelta(10, false, inst.prefab)
        end

        local fx = SpawnPrefab("fx_dock_pop")
        fx.Transform:SetPosition(target:GetPosition():Get())
    end

    hitfx(target:GetPosition())
end

local function ReticuleTargetFn()
    return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("gallop_brokenking")
    inst.AnimState:SetBuild("gallop_brokenking")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("weapon")
    inst:AddTag("nopunch")
    inst:AddTag("aoeweapon_leap")
    inst:AddTag("superjump")
    inst:AddTag("gallop_brokenking")

    MakeInventoryFloatable(inst, "small", nil, .55)

    inst.entity:SetPristine()

    inst:AddComponent("aoetargeting")
    --inst.components.aoetargeting:SetAlwaysValid(true) 
    inst.components.aoetargeting:SetAllowRiding(false)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticule_gallop_brokenking"  
    inst.components.aoetargeting.reticule.pingprefab = "reticuleping_gallop_brokenking" 
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }  
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 } 
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true
    inst.components.aoetargeting:SetRange(25) 

    if not TheWorld.ismastersim then
        return inst
    end

    inst.hit_fx = hitfx

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(51)
    inst.components.weapon:SetRange(1.5)
    inst.components.weapon:SetOnAttack(onattack)

    inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(function(inst, caster, pt) 
        caster:PushEvent("combat_superjump", {
            targetpos = pt,
            weapon = inst,
        })

        --[[local light = SpawnPrefab("gallop_ad_d_light")
        light.Transform:SetPosition(caster:GetPosition():Get())
        light.Light:SetIntensity(0.8)
        light.Light:SetRadius(5)
        light:DoTaskInTime(.8, light.Remove)]]
    end)

    inst:AddComponent("aoeweapon_leap")
    inst.components.aoeweapon_leap:SetDamage(0)
    inst.components.aoeweapon_leap.aoeradius = 5
    inst.components.aoeweapon_leap.physicspadding = 0
    inst.components.aoeweapon_leap:SetOnHitFn(function(inst, doer, target) 
        if target.components.combat then
            local spdmg = 100 * (inst.link_active and 2 or 1)
            target.components.combat:GetAttacked(doer, 0, nil, nil, {planar=spdmg})
        end
    end)
    inst.components.aoeweapon_leap:SetOnPreLeapFn(function(inst, doer, startingpos, targetpos) 
        doer.gallop_brokenking_jumping = true
    end)
    inst.components.aoeweapon_leap:SetOnLeaptFn(function(inst, doer, startingpos, targetpos) 
        doer.gallop_brokenking_jumping = nil
        inst.components.finiteuses:SetPercent(1)
        inst.components.rechargeable:Discharge(inst.link_active and 5 or 20)
        
        if doer.components.sanity then
            doer.components.sanity:DoDelta(-10)
        end

        if doer.components.talker then
            doer.components.talker:Say(STRINGS.GALLOP_BROKENKING.JIMPING, 2, true)
        end

        local fx = SpawnPrefab("moonpulse_fx")
        fx.Transform:SetPosition(targetpos:Get())

        fx = SpawnPrefab("moonstorm_glass_ground_fx")
        fx.Transform:SetPosition(targetpos:Get())

        fx = SpawnPrefab("lightning")
        fx.Transform:SetPosition(targetpos:Get())
    end)
    inst.components.aoeweapon_leap.OnHit = function(self, doer, target)
        if self.onprehitfn ~= nil then
            self.onprehitfn(self.inst, doer, target)
        end
        local did_hit = false
        if doer.components.combat:CanTarget(target) and not doer.components.combat:IsAlly(target) then
            doer.components.combat:DoAttack(target, nil, nil, self.stimuli)

            did_hit = true
        end

        if did_hit then
            if self.onhitfn then
                self.onhitfn(self.inst, doer, target)
            end
        else
            if self.onmissfn then
                self.onmissfn(self.inst, doer, target)
            end
        end
    end

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnChargedFn(function() inst.components.aoetargeting:SetEnabled(true) end)
    inst.components.rechargeable:SetOnDischargedFn(function() inst.components.aoetargeting:SetEnabled(false) end)
    -------
    inst:AddComponent("finiteuses")
    local finiteuses = inst.components.finiteuses
    finiteuses:SetMaxUses(20)
    finiteuses:SetUses(20)
    finiteuses:SetIgnoreCombatDurabilityLoss(true)

    inst:DoPeriodicTask(1, function() 
        if finiteuses:GetPercent() < 1 then
            finiteuses:SetUses(math.max(0, math.min(finiteuses.total, finiteuses:GetUses()+(inst.link_active and 4 or 1))))
        end
    end)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("damagetypebonus")
    inst.components.damagetypebonus:AddBonus("shadow_aligned", inst, TUNING.WEAPONS_NIGHTMARE_VS_LUNAR_BONUS)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = 1.1

    MakeHauntableLaunch(inst)

    return inst
end

local function gallop_brokenking_r()
    local inst = SpawnPrefab("reticuleaoe")
    local s = 1.9
    inst.AnimState:SetScale(s, s)

    return inst
end

local function gallop_brokenking_r_ping()
    local inst = SpawnPrefab("reticuleaoeping")
    local s = 1.9
    inst.AnimState:SetScale(s, s)

    return inst
end

return Prefab("gallop_brokenking", fn, assets),
       Prefab("reticule_gallop_brokenking", gallop_brokenking_r),
       Prefab("reticuleping_gallop_brokenking", gallop_brokenking_r_ping)