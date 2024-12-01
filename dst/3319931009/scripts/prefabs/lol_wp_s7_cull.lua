

local LANS = require('core_lol_wp/utils/sugar')

local prefab_id = "lol_wp_s7_cull"
local tmp_assets_id = 'lol_wp_s7_cull'

local assets =
{
    Asset( "ANIM", "anim/"..tmp_assets_id..".zip"),
    Asset( "ANIM", "anim/swap_"..tmp_assets_id..".zip"),
    Asset( "ATLAS", "images/inventoryimages/"..tmp_assets_id..".xml" ),
}

local prefabs =
{
    prefab_id,
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_"..tmp_assets_id, "swap_"..tmp_assets_id)
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

-- local function onfinished(inst)
--     inst:Remove()
-- end

local function onattack(inst,attacker,target)
    if LANS:checkAlive(attacker) then
        attacker.components.health:DoDelta(TUNING.MOD_LOL_WP.CULL.ATK_REGEN)
    end
    if target.components.health and target.components.health:IsDead() then
        if inst.components.lol_wp_s7_cull_counter then
            inst.components.lol_wp_s7_cull_counter:Add()
            LANS:flingItem(SpawnPrefab("goldnugget"),target:GetPosition())

            inst.components.lol_wp_s7_cull_counter:CheckMax(attacker)
        end
    end
end

local function IsEntityInFront(inst, entity, doer_rotation, doer_pos)
    local facing = Vector3(math.cos(-doer_rotation / RADIANS), 0 , math.sin(-doer_rotation / RADIANS))

    return IsWithinAngle(doer_pos, facing, TUNING.VOIDCLOTH_SCYTHE_HARVEST_ANGLE_WIDTH, entity:GetPosition())
end

local function HarvestPickable(inst, ent, doer)
    if ent.components.pickable.picksound ~= nil then
        doer.SoundEmitter:PlaySound(ent.components.pickable.picksound)
    end

    local success, loot = ent.components.pickable:Pick(TheWorld)

    if loot ~= nil then
        for i, item in ipairs(loot) do
            Launch(item, doer, 1.5)
        end
    end
end

local HARVEST_MUSTTAGS  = {"pickable"}
local HARVEST_CANTTAGS  = {"INLIMBO", "FX"}
local HARVEST_ONEOFTAGS = {"plant", "lichen", "oceanvine", "kelp"}

local function DoScythe(inst, target, doer)
    -- inst:SayRandomLine(STRINGS.VOIDCLOTH_SCYTHE_TALK.onharvest, doer)
    if not inst:HasTag('lol_wp_s7_cull_iscd') then
        inst:AddTag('lol_wp_s7_cull_iscd')
    end

    if inst.components.rechargeable then
        inst.components.rechargeable:Discharge(TUNING.MOD_LOL_WP.CULL.SKILL_SWEEP.CD)
    end
    if target.components.pickable ~= nil then
        local doer_pos = doer:GetPosition()
        local x, y, z = doer_pos:Get()

        local doer_rotation = doer.Transform:GetRotation()

        local ents = TheSim:FindEntities(x, y, z, TUNING.VOIDCLOTH_SCYTHE_HARVEST_RADIUS, HARVEST_MUSTTAGS, HARVEST_CANTTAGS, HARVEST_ONEOFTAGS)
        for _, ent in pairs(ents) do
            if ent:IsValid() and ent.components.pickable ~= nil then
                if inst:IsEntityInFront(ent, doer_rotation, doer_pos) then
                    inst:HarvestPickable(ent, doer)
                end
            end
        end
    end
end

local function DoScytheAsWp(inst, target, doer)
    if not inst:HasTag('lol_wp_s7_cull_iscd') then
        inst:AddTag('lol_wp_s7_cull_iscd')
    end

    if inst.components.rechargeable then
        inst.components.rechargeable:Discharge(TUNING.MOD_LOL_WP.CULL.SKILL_SWEEP.CD)
    end

    local doer_pos = doer:GetPosition()
    local x, y, z = doer_pos:Get()

    local doer_rotation = doer.Transform:GetRotation()
    local ents = TheSim:FindEntities(x, y, z, TUNING.VOIDCLOTH_SCYTHE_HARVEST_RADIUS, nil,{'player','wall',"companion","INLIMBO","structure"})
    for _, ent in pairs(ents) do
        if LANS:checkAlive(ent) and ent.components.combat then
            if inst:IsEntityInFront(ent, doer_rotation, doer_pos) then
                ent.components.combat:GetAttacked(doer,TUNING.MOD_LOL_WP.CULL.DMG,inst)
                if inst.components.weapon then
                    inst.components.weapon:OnAttack(doer, ent)
                end
            end
        end
    end

end



local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    -- inst.entity:AddLight()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(tmp_assets_id)
    inst.AnimState:SetBuild(tmp_assets_id)
    inst.AnimState:PlayAnimation("idle",true)

    MakeInventoryFloatable(inst, "med", nil, 0.75)

    -- inst.Light:SetFalloff(0.5)
    -- inst.Light:SetIntensity(.8)
    -- inst.Light:SetRadius(1.3)
    -- inst.Light:SetColour(128/255, 20/255, 128/255)
    -- inst.Light:Enable(true)

    inst.entity:SetPristine()

    inst:AddTag("nosteal")

    -- inst.MiniMapEntity:SetIcon(prefab_id..".tex")

    if not TheWorld.ismastersim then
        return inst
    end

    -- inst:AddComponent("talker")
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = tmp_assets_id
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..tmp_assets_id..".xml"
    -- inst.components.inventoryitem:SetOnDroppedFn(function()
    -- end)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    -- inst.components.equippable.walkspeedmult = 1.2
    -- inst.components.equippable.dapperness = 2

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.MOD_LOL_WP.CULL.DMG)
    inst.components.weapon:SetOnAttack(onattack)

    inst:AddComponent("tool")
	inst.components.tool:SetAction(ACTIONS.SCYTHE)

    inst.DoScythe = DoScythe
    inst.IsEntityInFront = IsEntityInFront
    inst.HarvestPickable = HarvestPickable

    inst.DoScytheAsWp = DoScytheAsWp

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetChargeTime(TUNING.MOD_LOL_WP.CULL.SKILL_SWEEP.CD)
    -- inst.components.rechargeable:SetOnDischargedFn(function(inst)  end)
    inst.components.rechargeable:SetOnChargedFn(function(inst)
        if inst:HasTag('lol_wp_s7_cull_iscd') then
            inst:RemoveTag('lol_wp_s7_cull_iscd')
        end
    end)

    inst:AddComponent('lol_wp_s7_cull_counter')
    -- inst:AddComponent("finiteuses")
    -- inst.components.finiteuses:SetMaxUses(500)
    -- inst.components.finiteuses:SetUses(500)
    -- inst.components.finiteuses:SetOnFinished(onfinished)

    -- local planardamage = inst:AddComponent("planardamage")
    -- planardamage:SetBaseDamage(data_prefab.planardamage)

    -- inst.OnSave = onsave
    -- inst.OnPreLoad = onpreload

    return inst
end

return Prefab("common/inventory/"..prefab_id, fn, assets, prefabs)


