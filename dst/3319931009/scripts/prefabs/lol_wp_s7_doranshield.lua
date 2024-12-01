local LANS = require('core_lol_wp/utils/sugar')

local prefab_id = 'lol_wp_s7_doranshield'

local assets =
{
    Asset("ANIM", "anim/wathgrithr_shield.zip"),
    Asset("ANIM", "anim/swap_wathgrithr_shield.zip"),

    Asset("ANIM", "anim/"..prefab_id..".zip"),
    Asset("ANIM", "anim/swap_"..prefab_id..".zip"),
    Asset("ATLAS", "images/inventoryimages/"..prefab_id..".xml"),
}

local prefabs =
{
    "reticulearc",
    "reticulearcping",
}

------------------------------------------------------------------------------------------------------------------------

local function ReticuleTargetFn()
    return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
    if mousepos ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local dx = mousepos.x - x
        local dz = mousepos.z - z
        local l = dx * dx + dz * dz
        if l <= 0 then
            return inst.components.reticule.targetpos
        end
        l = 6.5 / math.sqrt(l)
        return Vector3(x + dx * l, 0, z + dz * l)
    end
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

------------------------------------------------------------------------------------------------------------------------
local function equipRegen(enable,inst,owner)
    if enable then
        if inst.taskperiod_lol_wp_s7_doranshield_equipregen == nil then
            inst.taskperiod_lol_wp_s7_doranshield_equipregen = inst:DoPeriodicTask(TUNING.MOD_LOL_WP.DORANSHIELD.SKILL_RESTORE.INTERVAL,function()
                if LANS:checkAlive(owner) then
                    owner.components.health:DoDelta(TUNING.MOD_LOL_WP.DORANSHIELD.SKILL_RESTORE.REGEN)
                end
            end)
        end
    else
        if inst.taskperiod_lol_wp_s7_doranshield_equipregen ~= nil then
            inst.taskperiod_lol_wp_s7_doranshield_equipregen:Cancel()
            inst.taskperiod_lol_wp_s7_doranshield_equipregen = nil
        end
    end
end


local function OnEquip(inst, owner)
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Show("lantern_overlay")
    owner.AnimState:Hide("ARM_normal")
    owner.AnimState:HideSymbol("swap_object")

    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("lantern_overlay", skin_build, "swap_shield", inst.GUID, "swap_wathgrithr_shield")
        owner.AnimState:OverrideItemSkinSymbol("swap_shield",     skin_build, "swap_shield", inst.GUID, "swap_wathgrithr_shield")
    else
        owner.AnimState:OverrideSymbol("lantern_overlay", "swap_"..prefab_id, "swap_shield")
        owner.AnimState:OverrideSymbol("swap_shield",     "swap_"..prefab_id, "swap_shield")
    end


    if inst.components.rechargeable:GetTimeToCharge() < TUNING.WATHGRITHR_SHIELD_COOLDOWN_ONEQUIP then
        inst.components.rechargeable:Discharge(TUNING.WATHGRITHR_SHIELD_COOLDOWN_ONEQUIP)
    end

    equipRegen(true,inst,owner)
end

local function OnUnequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("lantern_overlay")
    owner.AnimState:ClearOverrideSymbol("swap_shield")

    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Hide("lantern_overlay")
    owner.AnimState:Show("ARM_normal")
    owner.AnimState:ShowSymbol("swap_object")

    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    equipRegen(false,inst,owner)
end

------------------------------------------------------------------------------------------------------------------------

local function SpellFn(inst, doer, pos)
    local duration_mult =
        doer.components.skilltreeupdater ~= nil and
        doer.components.skilltreeupdater:IsActivated("wathgrithr_arsenal_shield_2") and
        TUNING.SKILLS.WATHGRITHR.SHIELD_PARRY_DURATION_MULT or
        1

    inst.components.parryweapon:EnterParryState(doer, doer:GetAngleToPoint(pos), TUNING.WATHGRITHR_SHIELD_PARRY_DURATION * duration_mult)
    inst.components.rechargeable:Discharge(TUNING.WATHGRITHR_SHIELD_COOLDOWN)
end

local function OnParry(inst, doer, attacker, damage)
    doer:ShakeCamera(CAMERASHAKE.SIDE, 0.1, 0.03, 0.3)

    if inst.components.rechargeable:GetPercent() < TUNING.WATHGRITHR_SHIELD_COOLDOWN_ONPARRY_REDUCTION then
        inst.components.rechargeable:SetPercent(TUNING.WATHGRITHR_SHIELD_COOLDOWN_ONPARRY_REDUCTION)
    end

    if doer.components.skilltreeupdater ~= nil and doer.components.skilltreeupdater:IsActivated("wathgrithr_arsenal_shield_3") then
        inst._lastparrytime = GetTime()

        local tuning = TUNING.SKILLS.WATHGRITHR.SHIELD_PARRY_BONUS_DAMAGE
        local scale =  TUNING.SKILLS.WATHGRITHR.SHIELD_PARRY_BONUS_DAMAGE_SCALE

        inst._bonusdamage = math.clamp(damage * scale, tuning.min, tuning.max)
    end

    if LANS:checkAlive(doer) then
        doer.components.health:DoDelta(TUNING.MOD_LOL_WP.DORANSHIELD.SKILL_BLOCK.REGEN_WHEN_SUCCESS)
    end
end

local function DamageFn(inst)
    if inst._lastparrytime ~= nil and (inst._lastparrytime + TUNING.SKILLS.WATHGRITHR.SHIELD_PARRY_BONUS_DAMAGE_DURATION) >= GetTime() then
        return TUNING.MOD_LOL_WP.DORANSHIELD.DMG + (inst._bonusdamage or 0)
    end

    return TUNING.MOD_LOL_WP.DORANSHIELD.DMG
end

local function OnAttackFn(inst, attacker, target)
    inst._lastparrytime = nil
    inst._bonusdamage = nil

    inst.components.armor:TakeDamage(TUNING.WATHGRITHR_SHIELD_USEDAMAGE)
end

local function OnDischarged(inst)
    inst.components.aoetargeting:SetEnabled(false)
end

local function OnCharged(inst)
    inst.components.aoetargeting:SetEnabled(true)
end

------------------------------------------------------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(prefab_id)
    inst.AnimState:SetBuild(prefab_id)
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("toolpunch")
    inst:AddTag("battleshield")
    inst:AddTag("shield")

    --parryweapon (from parryweapon component) added to pristine state for optimization
    inst:AddTag("parryweapon")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    --rechargeable (from rechargeable component) added to pristine state for optimization
    inst:AddTag("rechargeable")

    MakeInventoryFloatable(inst, nil, 0.2, {1.1, 0.6, 1.1})

    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetAlwaysValid(true)
    inst.components.aoetargeting:SetAllowRiding(false)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticulearc"
    inst.components.aoetargeting.reticule.pingprefab = "reticulearcping"
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
    inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.scrapbook_weapondamage = TUNING.MOD_LOL_WP.DORANSHIELD.DMG
    
    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = prefab_id
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..prefab_id..".xml"

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DamageFn)
    inst.components.weapon:SetOnAttack(OnAttackFn)

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.MOD_LOL_WP.DORANSHIELD.FINITEUSE, TUNING.MOD_LOL_WP.DORANSHIELD.ABSORB)

    inst:AddComponent("equippable")
    -- inst.components.equippable.restrictedtag = "wathgrithrshieldmaker"
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(SpellFn)

    inst:AddComponent("parryweapon")
    inst.components.parryweapon:SetParryArc(TUNING.WATHGRITHR_SHIELD_PARRY_ARC)
    --inst.components.parryweapon:SetOnPreParryFn(OnPreParry)
    inst.components.parryweapon:SetOnParryFn(OnParry)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab(prefab_id, fn, assets, prefabs)