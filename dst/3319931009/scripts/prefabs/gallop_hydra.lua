local assets =
{
    Asset("ANIM", "anim/gallop_hydra.zip"),
}

local BASE_DMG = 24

local function RemoveBonus(inst)
    if inst.components.combat then
        inst.components.combat.externaldamagemultipliers:RemoveModifier(inst, "gallop_setbonus_hydra")
    end
    if inst.components.planardamage then
        inst.components.planardamage:RemoveMultiplier(inst, "gallop_setbonus_hydra")
    end
end

local function OnRefreshEquip(inst)
    inst:DoTaskInTime(0, function()
        if inst.components.inventory == nil then
            return
        end
        local hat = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if hat and hat.prefab == "gallophat2" and weapon and weapon.prefab == "gallop_hydra" then
            local item = hat.components.container and hat.components.container.slots[1]
            if item and item.prefab == "redgem" then
                if inst.components.combat then
                    inst.components.combat.externaldamagemultipliers:SetModifier(inst, 1.1, "gallop_setbonus_hydra")
                end
                if inst.components.planardamage then
                    inst.components.planardamage:AddMultiplier(inst, 1.1, "gallop_setbonus_hydra")
                end
            else
                RemoveBonus(inst)
            end
        else
            RemoveBonus(inst)
        end
    end)
end

local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_gallop_hydra", inst.GUID, "swap_gallop_hydra")
    else
        owner.AnimState:OverrideSymbol("swap_object", "gallop_hydra", "swap_gallop_hydra")
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    --inst.refresh_fn = function() OnRefreshEquip(owner) end
    --inst:ListenForEvent("refreshequip", inst.refresh_fn, owner)
    inst:ListenForEvent("gallophat2_link", OnRefreshEquip, owner)
    inst:ListenForEvent("gallophat2_unlink", OnRefreshEquip, owner)
    inst.onattackother = function(attacker, data)
        local max_health = attacker.components.health and attacker.components.health.maxhealth
        inst.components.weapon:SetDamage(BASE_DMG + max_health*.1)
    end
    inst:ListenForEvent("onattackother", inst.onattackother, owner)

    OnRefreshEquip(owner)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
    --[[if inst.refresh_fn then
        inst:RemoveEventCallback("refreshequip", inst.refresh_fn, owner)
        inst.refresh_fn = nil
    end]]
    inst:RemoveEventCallback("gallophat2_link", OnRefreshEquip, owner)
    inst:RemoveEventCallback("gallophat2_unlink", OnRefreshEquip, owner)
    if inst.onattackother then
        inst.components.weapon:SetDamage(BASE_DMG)
        inst:RemoveEventCallback("onattackother", inst.onattackother, owner)
        inst.onattackother = nil
    end

    OnRefreshEquip(owner)
end

local function hitfx(pos)
    local fx = SpawnPrefab("fire_fail_fx")
    fx.Transform:SetPosition(pos:Get())
end

local function onattack(inst, attacker, target)
    --[[local max_health = attacker.components.health and attacker.components.health.maxhealth
    if max_health and target.components.health and not target.components.health:IsDead() and target.components.combat and not inst.DoDMG then
        inst.DoDMG = true
        local dmg_old = inst.components.weapon.damage
        inst.components.weapon:SetDamage(max_health*.1)
        attacker.components.combat:DoAttack(target, nil, nil, nil, nil, 10)
        inst.components.weapon:SetDamage(dmg_old)
        --target.components.combat:GetAttacked(attacker, max_health*.1)
        inst.DoDMG = nil
    end]]
    if not inst:HasTag("gallop_triple_atk") and not attacker:HasTag("gallop_nocahrge") then
        inst.hit_num = inst.hit_num + 1
        if inst.hit_num >= 3 then
            inst:AddTag("gallop_triple_atk")
            inst.hit_num = 0
        end
    end
    hitfx(target:GetPosition())
end

local function OnRefreshDMG(inst)
    if inst.onattackother then
        inst.onattackother(inst.components.inventoryitem:GetGrandOwner())
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("gallop_hydra")
    inst.AnimState:SetBuild("gallop_hydra")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("weapon")
    inst:AddTag("nopunch")
    inst:AddTag("jab")
    inst:AddTag("gallop_hydra")
    inst:AddTag("gallop_chop")

    MakeInventoryFloatable(inst, "small", nil, .75)

    inst.gallop_chop_cd = .5

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.hit_num = 0
    inst.hit_fx = hitfx

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(BASE_DMG)
    inst.components.weapon:SetRange(2)
    inst.components.weapon:SetOnAttack(onattack)

    inst:AddComponent("gallop_chop")

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnChargedFn(function() inst:RemoveTag("gallop_chop_discharge") end)
    inst.components.rechargeable:SetOnDischargedFn(function() inst:AddTag("gallop_chop_discharge") end)

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:ListenForEvent("gallop_refreshdmg", OnRefreshDMG)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("gallop_hydra", fn, assets)