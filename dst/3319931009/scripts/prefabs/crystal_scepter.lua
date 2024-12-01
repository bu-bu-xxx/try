local assets =
{
    Asset("ANIM", "anim/crystal_scepter.zip"),
    Asset("ANIM", "anim/swap_crystal_scepter.zip"),
}

local prefabs =
{
    "ice_projectile",
    "crystal_scepter_ice_circle",
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_crystal_scepter", "swap_crystal_scepter")

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    --[[if inst.components.rechargeable:GetTimeToCharge() < 2 then
        inst.components.rechargeable:Discharge(2)
    end--]]
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function OnDischarged(inst)
    inst._can_cast:set(false)
    --inst.components.aoetargeting:SetEnabled(false)
end

local function OnCharged(inst)
    inst._can_cast:set(true)
    --inst.components.aoetargeting:SetEnabled(true)
end

local function fn()
    local inst = CreateEntity()

    inst.projectiledelay = FRAMES
    inst.spelltype = "CRYSTAL_SCEPTER"

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("crystal_scepter")
    inst.AnimState:SetBuild("crystal_scepter")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("icestaff")
    inst:AddTag("weapon")
    inst:AddTag("rangedweapon")
    inst:AddTag("rechargeable")
    inst:AddTag("extinguisher")
    inst:AddTag("lol_weapon")

    MakeInventoryFloatable(inst)

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = function()
        return Vector3(ThePlayer.entity:LocalToWorldSpace(5, 0.001, 0))
    end
    inst.components.reticule.ease = true
    inst.components.reticule.ispassableatallpoints = true--]]

    inst._can_cast = net_bool(inst.GUID, "_can_cast","_can_cast_dirty")
    inst._can_cast:set(true)

    --[[inst:AddComponent("aoetargeting") -- 范围显示
	inst.components.aoetargeting:SetAllowWater(true)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoe"
	inst.components.aoetargeting.reticule.targetfn = function()
        return Vector3(ThePlayer.entity:LocalToWorldSpace(5, 0.001, 0))
    end
	inst.components.aoetargeting.reticule.validcolour = { 185/255, 205/255, 246/255, 1 }
	inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
	inst.components.aoetargeting.reticule.ease = true
	inst.components.aoetargeting.reticule.mouseenabled = true--]]

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(function(staff, target, pos,doer)
        local spell = SpawnPrefab("crystal_scepter_ice_circle")
        if spell then
            spell.Transform:SetPosition(pos.x, 0, pos.z)
            spell:DoTaskInTime(6, spell.KillFX)
            spell:TriggerFX()
            staff.components.rechargeable:Discharge(20)
            if doer.components.sanity then
                doer.components.sanity:DoDelta(-20)
            end
        end
        return spell
    end)
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canuseonpoint_water = true

    --[[inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(function(inst, doer, pos)
        local spell = SpawnPrefab("deer_ice_circle")
        if spell then
            spell.Transform:SetPosition(pos.x, 0, pos.z)
            spell:DoTaskInTime(6, spell.KillFX)
            inst.components.rechargeable:Discharge(20)
        end
        return spell
    end)--]]

    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(40)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)
    inst.components.weapon:SetRange(8, 10)
    inst.components.weapon:SetOnAttack(function(inst, attacker, target)
        if not target:IsValid() then
            --target killed or removed in combat damage phase
            return
        end

        if target.components.sleeper ~= nil and target.components.sleeper:IsAsleep() then
            target.components.sleeper:WakeUp()
        end

        if target.components.burnable ~= nil then
            if target.components.burnable:IsBurning() then
                target.components.burnable:Extinguish()
            elseif target.components.burnable:IsSmoldering() then
                target.components.burnable:SmotherSmolder()
            end
        end

        if target.components.combat ~= nil then
            target.components.combat:SuggestTarget(attacker)
        end

        if target.sg ~= nil and not target.sg:HasStateTag("frozen") then
            target:PushEvent("attacked", { attacker = attacker, weapon = inst })
        end

        if target.components.freezable ~= nil then
            target.components.freezable:AddColdness(.5)
            target.components.freezable:SpawnShatterFX()
        end

        target:AddDebuff("lol_weapon_slow", "lol_weapon_slow_buff")
    end)
    inst.components.weapon:SetProjectile("ice_projectile")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable.walkspeedmult = 1.2
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("crystal_scepter", fn, assets, prefabs)