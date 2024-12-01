---@diagnostic disable: undefined-global

local prefab_id = "lol_wp_sheen"

local assets =
{
    Asset( "ANIM", "anim/"..prefab_id..".zip"),
    Asset("ANIM","anim/swap_"..prefab_id..".zip"),
    Asset( "ATLAS", "images/inventoryimages/"..prefab_id..".xml" ),
}

local prefabs = 
{
    prefab_id,
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_"..prefab_id, "swap_"..prefab_id)
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    inst.Light:Enable(true)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    inst.Light:Enable(false)
end

local function onfinished(inst)
    inst:Remove()
end

local function onattack(inst,attacker,target)
    local fx = SpawnPrefab("crab_king_shine")
    fx.Transform:SetScale(.7,.7,.7)
    fx.Transform:SetPosition(inst:GetPosition():Get())
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(prefab_id)
    inst.AnimState:SetBuild(prefab_id)
    inst.AnimState:PlayAnimation("idle",true)

    MakeInventoryFloatable(inst, "med", nil, 0.75)

    inst.Light:SetFalloff(TUNING.MOD_LOL_WP.SHEEN.LIGHT_FALLOFF)
    inst.Light:SetIntensity(TUNING.MOD_LOL_WP.SHEEN.LIGHT_INTENSITY)
    inst.Light:SetRadius(TUNING.MOD_LOL_WP.SHEEN.LIGHT_RADIUS)
    inst.Light:SetColour(unpack(TUNING.MOD_LOL_WP.SHEEN.LIGHT_COLOR))
    inst.Light:Enable(false)

    inst.entity:SetPristine()

    inst:AddTag("nosteal")

    -- inst.MiniMapEntity:SetIcon(prefab_id..".tex")

    if not TheWorld.ismastersim then 
        return inst 
    end

    -- inst:AddComponent("talker")
    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = prefab_id
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..prefab_id..".xml"
    -- inst.components.inventoryitem:SetOnDroppedFn(function()
    -- end)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = TUNING.MOD_LOL_WP.SHEEN.WALKSPEEDMULT
    -- inst.components.equippable.dapperness = 2

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.MOD_LOL_WP.SHEEN.DMG)
    -- inst.components.weapon:SetOnAttack(onattack)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.MOD_LOL_WP.SHEEN.FINITEUSES)
    inst.components.finiteuses:SetUses(TUNING.MOD_LOL_WP.SHEEN.FINITEUSES)
    inst.components.finiteuses:SetOnFinished(onfinished)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetChargeTime(TUNING.MOD_LOL_WP.SHEEN.CD)
    inst.components.rechargeable:SetOnDischargedFn(function(inst) end)
    inst.components.rechargeable:SetOnChargedFn(function(inst) end)

    -- local planardamage = inst:AddComponent("planardamage")
    -- planardamage:SetBaseDamage(data_prefab.planardamage)

    -- inst.OnSave = onsave
    -- inst.OnPreLoad = onpreload

    return inst
end

return Prefab("common/inventory/"..prefab_id, fn, assets, prefabs)


