local assets =
{
    Asset("ANIM", "anim/nashor_tooth.zip"),
    Asset("ANIM", "anim/swap_nashor_tooth.zip"),
}

local exclude_tags = {'laser', 'DECOR', 'INLIMBO', 'companion', 'wall', 'abigail', 'shadowminion', 'player', 'erd_doll'}

local function weapon_onhitother(owner, data)
    SpawnPrefab("nightsword_sharp_fx").Transform:SetPosition(data.target.Transform:GetWorldPosition())
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_nashor_tooth", "swap_nashor_tooth")

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    owner:ListenForEvent("onhitother", weapon_onhitother)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    owner:RemoveEventCallback("onhitother", weapon_onhitother)
end

local function CLIENT_PlayFuelSound(inst)
	local parent = inst.entity:GetParent()
	local container = parent ~= nil and (parent.replica.inventory or parent.replica.container) or nil
	if container ~= nil and container:IsOpenedBy(ThePlayer) then
		TheFocalPoint.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
	end
end

local function SERVER_PlayFuelSound(inst)
	local owner = inst.components.inventoryitem.owner
	if owner == nil then
		inst.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
	elseif inst.components.equippable:IsEquipped() and owner.SoundEmitter ~= nil then
		owner.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
	else
		inst.playfuelsound:push()
		--Dedicated server does not need to trigger sfx
		if not TheNet:IsDedicated() then
			CLIENT_PlayFuelSound(inst)
		end
	end
end

------------------------------------------------------------------------------------------------------------------------
--代码是aria的，我相信罗夏爱我（不是
local function ReticuleTargetFn()
    --Cast range is 8, leave room for error (6.5 lunge)
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

local function DoDamage(inst, rad, attacker, targetpos)
    local x, y, z = targetpos:Get()
    local hasattacked = false
    local weapon = attacker.components.combat:GetWeapon()
    if weapon then
        weapon.components.finiteuses.ignorecombatdurabilityloss = true
    end
    local ents = TheSim:FindEntities(x, 0, z, rad, {'_combat'}, exclude_tags)
    for i, v in ipairs(ents) do
        if v and v:IsValid() and v ~= attacker then
            if v.components.combat and not (v.components.health and v.components.health:IsDead()) then
                if attacker ~= nil and attacker.components.combat ~= nil then
                    if attacker.components.combat.ignorehitrange then
                        hasattacked = true
                        --attacker.components.combat:DoAttack(v, weapon, inst)
                    else
                        attacker.components.combat.ignorehitrange = true
                        --attacker.components.combat:DoAttack(v, weapon, inst)
                        hasattacked = true
                        attacker.components.combat.ignorehitrange = false
                    end
                end
            end
        end
    end
    if weapon then
        weapon.components.finiteuses.ignorecombatdurabilityloss = false
    end
    if hasattacked then 
        weapon.components.finiteuses:Use(1)
    end
end

local function SpellFn(inst, doer, pos)
    DoDamage(inst, 5, doer, pos)
    --local p = SpawnPrefab("nashor_tooth")
    inst.components.planardamage:SetBaseDamage(70)
    doer:PushEvent('combat_lunge', {targetpos = pos, weapon = inst})
    inst:DoTaskInTime(0.2,function()
        inst.components.planardamage:SetBaseDamage(51)
        --inst.components.weapon:SetDamage(51)
    end)
    inst.components.rechargeable:Discharge(5)
end



local function OnLunged(inst, doer, startingpos, targetpos)
    local fx = SpawnPrefab('spear_wathgrithr_lightning_lunge_fx')
    fx.Transform:SetPosition(targetpos:Get())
    fx.Transform:SetRotation(doer:GetRotation())
--[[
    local ring = SpawnPrefab('aria_laser_ring')
    ring.Transform:SetScale(1, 1, 1)
    ring.Transform:SetPosition(targetpos:Get())]]
    --[[inst:DoTaskInTime(
        0.3,
        function()
            DoDamage(inst, 5, doer, targetpos)
        end
    )]]
end

local function OnLungedHit(inst, doer, target)
end

------------------------------------------------------------------------------------------------------------------------
local function OnCharged(inst)
    inst:AddComponent('aoespell')
    inst.components.aoespell:SetSpellFn(SpellFn)
end

local function OnDischarged(inst)
    inst:RemoveComponent("aoespell")
end
------------------------------------------------------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("nashor_tooth")
    inst.AnimState:SetBuild("nashor_tooth")
    inst.AnimState:PlayAnimation("idle")

    inst.spelltype = "NASHOR_TOOTH"

    inst:AddTag("sharp")
    inst:AddTag("pointy")
    inst:AddTag("weapon")
    inst:AddTag("shadowlevel")
    inst:AddTag("lol_weapon")
    inst:AddTag("shadow_item")
    inst:AddTag("shadow")

    inst:AddComponent('aoetargeting')
    inst.components.aoetargeting:SetAllowRiding(false)
    inst.components.aoetargeting.reticule.reticuleprefab = 'reticuleline'
    inst.components.aoetargeting.reticule.pingprefab = 'reticulelineping'
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
    inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
    inst.components.aoetargeting.reticule.validcolour = {1, .75, 0, 1}
    inst.components.aoetargeting.reticule.invalidcolour = {.5, 0, 0, 1}
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true

    inst.playfuelsound = net_event(inst.GUID, "nashor_tooth.playfuelsound")

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:DoTaskInTime(0, inst.ListenForEvent, "nashor_tooth.playfuelsound", CLIENT_PlayFuelSound)
        return inst
    end

    inst.currentplanarbonus = 0
    inst.maxplanarbonus = 20

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", function(inst, data)
        if data and data.name and data.name == "planarbonus" then
            inst.currentplanarbonus = 0
            for i = 1, inst.maxplanarbonus do
                inst.components.planardamage:RemoveBonus(inst, i)
            end
        end
    end)

    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(51)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(5)
    inst.components.weapon:SetOnAttack(function(inst, attacker, target)
        if inst.currentplanarbonus < inst.maxplanarbonus then
            inst.currentplanarbonus = inst.currentplanarbonus + 1
            inst.components.planardamage:AddBonus(inst, 1, inst.currentplanarbonus)
        end
        if not inst.components.timer:TimerExists("planarbonus") then
            inst.components.timer:StartTimer("planarbonus", 10)
        else
            inst.components.timer:SetTimeLeft("planarbonus", 10)
        end

        local fx = SpawnPrefab(math.random() < .5 and "shadowstrike_slash_fx" or "shadowstrike_slash2_fx")
        local x, y, z = target.Transform:GetWorldPosition()
        fx.Transform:SetPosition(x, y + 1.5, z)
        fx.Transform:SetRotation(inst.Transform:GetRotation())
    end)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(200)
    inst.components.finiteuses:SetUses(200)
    inst.components.finiteuses:SetOnFinished(function()
        if inst.components.equippable ~= nil then
            if inst.components.equippable:IsEquipped() then
                local owner = inst.components.inventoryitem.owner
                if owner ~= nil and owner.components.inventory ~= nil then
                    local item = owner.components.inventory:Unequip(inst.components.equippable.equipslot)
                    if item ~= nil then
                        owner.components.inventory:GiveItem(item, nil, owner:GetPosition())
                    end
                end
            end

            inst:RemoveComponent("equippable")
            inst:AddTag("broken")
        end
    end)

    inst:AddComponent("repairable")
    inst.components.repairable.repairmaterial = MATERIALS.NIGHTMARE
    inst.components.repairable.noannounce = true
    inst.components.repairable.checkmaterialfn = function(inst, repair_item)
        if repair_item.prefab == "nightmarefuel" or repair_item.prefab == "horrorfuel" then
            return true
        end
        return false
    end
	inst.components.repairable.onrepaired = function(inst, doer, repair_item)
        local repairnum = 0
        if repair_item.prefab == "nightmarefuel" then 
            repairnum = 40
        elseif repair_item.prefab == "horrorfuel" then 
            repairnum = 200
        end
        inst.components.finiteuses:Repair(repairnum)
        if inst.components.equippable == nil then
            inst:AddComponent("equippable")
            inst.components.equippable:SetOnEquip(onequip)
            inst.components.equippable:SetOnUnequip(onunequip)
            inst:RemoveTag("broken")
        end
        SERVER_PlayFuelSound(inst)
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable.walkspeedmult = 1.1
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.dapperness = -10/60

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(2)
    
    inst:AddComponent('aoeweapon_lunge')
    inst.components.aoeweapon_lunge:SetDamage(0)
    inst.components.aoeweapon_lunge:SetSound('meta3/wigfrid/spear_lighting_lunge')
    inst.components.aoeweapon_lunge:SetSideRange(2)
    inst.components.aoeweapon_lunge:SetOnLungedFn(OnLunged)
    inst.components.aoeweapon_lunge:SetOnHitFn(OnLungedHit)
    inst.components.aoeweapon_lunge:SetWorkActions()
    inst.components.aoeweapon_lunge:SetTags('_combat')

    inst:AddComponent('aoespell')
    inst.components.aoespell:SetSpellFn(SpellFn)

    inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
	inst.components.rechargeable:SetOnChargedFn(OnCharged)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("nashor_tooth", fn, assets)