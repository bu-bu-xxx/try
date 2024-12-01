local HYPNOSIS_TIMERNAME = "HYPNOSIS_TIMERNAME"

local assets =
{
    Asset("ANIM", "anim/gallop_ad_destroyer.zip"),
}

local prefabs = {}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "gallop_ad_destroyer", "swap_object")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if owner.gallop_ad_d_light == nil then
        owner.gallop_ad_d_light = SpawnPrefab("gallop_ad_d_light")
        owner.gallop_ad_d_light.entity:SetParent(owner.entity)
    end

    if inst._vfx_fx == nil then
        inst._vfx_fx = SpawnPrefab("cane_victorian_fx")
        inst._vfx_fx.entity:AddFollower()
    end
    inst._vfx_fx.entity:SetParent(owner.entity)
    inst._vfx_fx.Follower:FollowSymbol(owner.GUID, "swap_object", 0, 0, 0)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    if owner.gallop_ad_d_light then
        owner.gallop_ad_d_light:Remove()
        owner.gallop_ad_d_light = nil
    end

    if inst._vfx_fx ~= nil then
        inst._vfx_fx:Remove()
        inst._vfx_fx = nil
    end
end

local function onequiptomodel(inst, owner, from_ground)
    if owner.gallop_ad_d_light then
        owner.gallop_ad_d_light:Remove()
        owner.gallop_ad_d_light = nil
    end
end

local function Repaire(inst, percent)
    local finiteuses = inst.components.finiteuses
    if finiteuses ~= nil then
        finiteuses:SetUses(math.max(0, math.min(finiteuses.total, finiteuses:GetUses()+finiteuses.total*percent)))
    end
end

local function ShouldAcceptItem(inst, item, giver)
    return item.prefab == "purebrilliance"
end

local function OnGetItemFromPlayer(inst, giver, item)
    if item.prefab == "purebrilliance" then
        Repaire(inst, .2)
    end
end

local function hitfx(pos)
    local fx = SpawnPrefab("fx_dock_pop")
    fx.Transform:SetPosition(pos:Get())
end

local function onattack(inst, attacker, target)
    hitfx(target:GetPosition())

    if inst.Gallop_DoAoeDMG then
        return
    end
    inst.Gallop_DoAoeDMG = true
    local attacker_combat = attacker.components.combat
    attacker_combat:EnableAreaDamage(false)
    inst.components.weapon.attackwear = 0

    local pt = target:GetPosition()
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 3, nil, {'FX', 'NOCLICK', 'DECOR', 'INLIMBO', "wall"})
    for k, v in pairs(ents) do
        if v ~= attacker and v ~= target and v.components.combat ~= nil and attacker.components.combat ~= nil and
                attacker.components.combat:CanTarget(v) and v.components.combat:CanBeAttacked(attacker) and
                    not attacker.components.combat:IsAlly(v) then
            attacker.components.combat:DoAttack(v, nil, nil, nil, 1, 10)
        end
    end
    inst.Gallop_DoAoeDMG = nil
    attacker_combat:EnableAreaDamage(true)
    inst.components.weapon.attackwear = 1

    if math.random() < .1 and not inst.components.timer:TimerExists(HYPNOSIS_TIMERNAME) then
        inst.components.timer:StartTimer(HYPNOSIS_TIMERNAME, 10)

        --pt = attacker:GetPosition()
        local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 4, nil, {'FX', 'NOCLICK', 'DECOR', 'INLIMBO'})
        for k, v in pairs(ents) do
            if v ~= attacker and attacker.components.combat ~= nil and not attacker.components.combat:IsAlly(v) 
                and v.components.sleeper ~= nil then
                v.components.sleeper:GoToSleep(12)
            end
        end

        local fx = SpawnPrefab("alterguardian_summon_fx")
        fx.Transform:SetPosition(pt:Get())
        fx:DoTaskInTime(1+math.random(), function()
            fx:PushEvent("endloop")
        end)
    end
end

local function AddWeapon(inst)
    if inst.components.weapon == nil then
        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(45)
        inst.components.weapon:SetRange(2)
        inst.components.weapon:SetOnAttack(onattack)
    end
end

local function AddEquippable(inst)
    if inst.components.equippable == nil then
        inst:AddComponent("equippable")
        inst.components.equippable:SetOnEquip(onequip)
        inst.components.equippable:SetOnUnequip(onunequip)
        inst.components.equippable:SetOnEquipToModel(onequiptomodel)
        inst.components.equippable.walkspeedmult = 1.2
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
        if inst.components.rechargeable:IsCharged() then
            inst.components.aoetargeting:SetEnabled(true)
        end
    else
        ReturnItem(inst)
        if inst.components.weapon ~= nil then
            inst:RemoveComponent("weapon")
        end
        if inst.components.equippable ~= nil then
            inst:RemoveComponent("equippable")
        end
        inst.components.aoetargeting:SetEnabled(false)
    end
end

local function ReticuleTargetFn()
    return Vector3(ThePlayer.entity:LocalToWorldSpace(0, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
    if not mousepos then
        return
    end
    return Vector3(ThePlayer.entity:LocalToWorldSpace(0, 0, 0))
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    reticule.Transform:SetPosition(x, 0, z)
    local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
    if ease and dt ~= nil then
        local rot0 = reticule.Transform:GetRotation()
        local drot = rot - rot0
        rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end

local function onCastSpell(inst, caster, pt)
    if not inst.components.rechargeable:IsCharged() then
        return false
    end
    inst.components.rechargeable:Discharge(5)
    inst.components.finiteuses:Use(5)

    inst.Gallop_DoAoeDMG = true
    local caster_combat = caster.components.combat
    caster_combat:EnableAreaDamage(false)
    inst.components.weapon.attackwear = 0

    local num = 0
    local pt = caster:GetPosition()
    local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 5, nil, {'FX', 'NOCLICK', 'DECOR', 'INLIMBO', "wall"})
    for k, v in pairs(ents) do
        if v ~= caster and v.components.combat ~= nil and caster.components.combat ~= nil and
                caster.components.combat:CanTarget(v) and v.components.combat:CanBeAttacked(caster) and
                    not caster.components.combat:IsAlly(v) then
            caster.components.combat:DoAttack(v, nil, nil, nil, 1, 10)

            if v.components.locomotor then
                v.components.locomotor:Stop()
                if v.Physics ~= nil and v.Transform ~= nil then
                    v:ForceFacePoint(caster.Transform:GetWorldPosition())
                    local rot = v.Transform:GetRotation()
                    v.gallop_ad_d_push = v:DoPeriodicTask(FRAMES, function()
                        v.Transform:SetRotation(rot+180)
                        v.Physics:SetMotorVel(25, 0, 0)
                    end)
                    v:DoTaskInTime(.2, function() 
                        v.gallop_ad_d_push:Cancel()
                        v.gallop_ad_d_push = nil
                        v.Physics:Stop() 
                        v.Transform:SetRotation(rot-180)
                    end)
                end

                if v.gallop_ad_d_speeddown ~= nil then
                    v.gallop_ad_d_speeddown:Cancel()
                end
                v.components.locomotor:SetExternalSpeedMultiplier(v, inst.prefab, .5)
                v.gallop_ad_d_speeddown = v:DoTaskInTime(5, function() 
                    v.components.locomotor:RemoveExternalSpeedMultiplier(v, inst.prefab)
                    v.gallop_ad_d_speeddown = nil
                end)
            end
            num = num + 1
        end
    end

    if caster.components.locomotor then
        if caster.gallop_ad_d_speedup ~= nil then
            caster.gallop_ad_d_speedup:Cancel()
        end
        caster.components.locomotor:SetExternalSpeedMultiplier(caster, inst.prefab, 1+math.min(num, 7)*.05)
        caster.gallop_ad_d_speedup = caster:DoTaskInTime(5, function() 
            caster.components.locomotor:RemoveExternalSpeedMultiplier(caster, inst.prefab)
            caster.gallop_ad_d_speedup = nil
        end)
    end

    inst.Gallop_DoAoeDMG = nil
    caster_combat:EnableAreaDamage(true)
    inst.components.weapon.attackwear = 1

    local fx = SpawnPrefab("moonstorm_glass_ground_fx")
    fx.Transform:SetPosition(caster:GetPosition():Get())
    local s = 1.41
    fx.Transform:SetScale(s, s, s)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

	inst:AddTag("pocketwatch")
    inst:AddTag("gallop_ad_destroyer")

    inst.AnimState:SetBank("gallop_ad_destroyer")
    inst.AnimState:SetBuild("gallop_ad_destroyer")
    inst.AnimState:PlayAnimation("idle", true)

    MakeInventoryFloatable(inst, "small", 0.05, {1.2, 0.75, 1.2})

    inst.entity:SetPristine()

    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetAlwaysValid(true)
    inst.components.aoetargeting:SetAllowRiding(false)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticule_gallop_ad_d"
    inst.components.aoetargeting.reticule.pingprefab = "reticuleping_gallop_ad_d"
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
    --inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true

    if not TheWorld.ismastersim then
        return inst
    end

    --inst:DoPeriodicTask(.5, function() 
    --print(inst.components.aoetargeting:IsEnabled())
    --end)

    inst.hit_fx = hitfx

    inst:AddComponent("inventoryitem")
    inst:AddComponent("lootdropper")
	
    inst:AddComponent("inspectable")

    AddWeapon(inst)

    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(30)

    inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(onCastSpell)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnChargedFn(function() inst.components.aoetargeting:SetEnabled(true) end)
    inst.components.rechargeable:SetOnDischargedFn(function() inst.components.aoetargeting:SetEnabled(false) end)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(400)
    inst.components.finiteuses:SetUses(400)

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer

    inst:AddComponent("timer")
    
    AddEquippable(inst)

    inst:ListenForEvent("percentusedchange", OnUseDelta)

    MakeHauntableLaunch(inst)

    return inst
end

local function lightfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    
    inst.Light:SetIntensity(0.8)
    inst.Light:SetRadius(3)
    inst.Light:SetFalloff(.5)
    inst.Light:SetColour(115 / 255, 115 / 255, 220 / 255)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

local function gallop_ad_d()
    local inst = SpawnPrefab("reticuleaoe")
    local s = 1.9
    inst.AnimState:SetScale(s, s)

    return inst
end

local function gallop_ad_d_ping()
    local inst = SpawnPrefab("reticuleaoeping")
    local s = 1.9
    inst.AnimState:SetScale(s, s)

    return inst
end

return Prefab("gallop_ad_destroyer", fn, assets, prefabs),
       Prefab("common/fx/gallop_ad_d_light", lightfn, assets),
       Prefab("reticule_gallop_ad_d", gallop_ad_d),
       Prefab("reticuleping_gallop_ad_d", gallop_ad_d_ping)
