local assets =
{
    Asset("ANIM", "anim/gallop_tiamat.zip"),
}

local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "gallop_tiamat", inst.GUID, "swap_gallop_tiamat")
    else
        owner.AnimState:OverrideSymbol("swap_object", "gallop_tiamat", "swap_gallop_tiamat")
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
end

local function ShouldAcceptItem(inst, item, giver)
    if item.prefab == "goldnugget" then
        return true
    end
    return false
end

local function OnGetItemFromPlayer(inst, giver, item)
    if item.prefab == "goldnugget" then
        local finiteuses = inst.components.finiteuses
        finiteuses:SetUses(math.max(0, math.min(finiteuses.total, finiteuses:GetUses() + finiteuses.total*.2)))
    end
end

local function hitfx(pos)
    local fx = SpawnPrefab("shadowstrike_slash_fx")
    fx.Transform:SetPosition(pos:Get())
end

local function onattack(inst, attacker, target)
    hitfx(target:GetPosition())
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("gallop_tiamat")
    inst.AnimState:SetBuild("gallop_tiamat")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("weapon")
    inst:AddTag("tool")
    inst:AddTag("nopunch")
    inst:AddTag("gallop_tiamat")
    inst:AddTag("gallop_chop")

    MakeInventoryFloatable(inst, "small", nil, .75)

    inst._laglength = .1
    inst.gallop_chop_cd = 2

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.hit_fx = hitfx

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(45)
    inst.components.weapon:SetOnAttack(onattack)

    inst:AddComponent("gallop_chop")

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnChargedFn(function() inst:RemoveTag("gallop_chop_discharge") end)
    inst.components.rechargeable:SetOnDischargedFn(function() inst:AddTag("gallop_chop_discharge") end)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.CHOP, TUNING.MULTITOOL_AXE_PICKAXE_EFFICIENCY)
    inst.components.tool:SetAction(ACTIONS.MINE, TUNING.MULTITOOL_AXE_PICKAXE_EFFICIENCY)
    inst.components.tool:EnableToughWork(true)
    -------
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(800)
    inst.components.finiteuses:SetUses(800)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, 1)
    inst.components.finiteuses:SetConsumption(ACTIONS.MINE, 3)

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("gallop_tiamat", fn, assets)