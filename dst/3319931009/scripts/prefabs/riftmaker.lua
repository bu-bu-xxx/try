local weapon_assets =
{
    Asset("ANIM", "anim/weapon_riftmaker.zip"),
    Asset("ANIM", "anim/swap_weapon_riftmaker.zip"),
}

local weapon_prefabs =
{
    "riftmaker_charge",
    "riftmaker_light",
}

local amulet_assets =
{
    Asset("ANIM", "anim/amulet_riftmaker.zip"),
    Asset("ANIM", "anim/swap_amulet_riftmaker.zip"),
}

local fx_assets =
{
    Asset("ANIM", "anim/riftmaker_attack.zip"),
}

local function finish(inst)
    local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
    local form = inst.components.riftmaker.form
    inst:Remove()

    local sp = nil
    if form == "weapon" then
        sp = SpawnPrefab("riftmaker_weapon")
    else 
        sp = SpawnPrefab("riftmaker_amulet")
    end
    sp.components.finiteuses.current = 0
    sp.components.equippable.restrictedtag = "别看了我就是不让你装备的"
    if owner and sp and owner.components.inventory then 
        owner.components.inventory:GiveItem(sp)
    end
end

local function IsLifeDrainable(target)
	return not target:HasAnyTag(NON_LIFEFORM_TARGET_TAGS) or target:HasTag("lifedrainable")
end
--[[
local function ShouldAcceptItem(inst, item)
    if
        item.prefab == "nightmarefuel" or item.prefab == "horrorfuel"
     then
        return true
    end
    return false
end

local function OnGetItemFromPlayer(inst, giver, item)
    if inst.components.finiteuses.current <= 0 then 
        inst.components.equippable.restrictedtag = nil
    end
    if item.prefab == "nightmarefuel"  then
        inst.components.finiteuses:Repair(40)
    end
    if item.prefab == "horrorfuel"  then
        inst.components.finiteuses:Repair(200)
    end
end
]]


----
require "prefabs/telebase"

local function getrandomposition(caster, teleportee, target_in_ocean)
	if target_in_ocean then
		local pt = TheWorld.Map:FindRandomPointInOcean(20)
		if pt ~= nil then
			return pt
		end
		local from_pt = teleportee:GetPosition()
		local offset = FindSwimmableOffset(from_pt, math.random() * TWOPI, 90, 16)
						or FindSwimmableOffset(from_pt, math.random() * TWOPI, 60, 16)
						or FindSwimmableOffset(from_pt, math.random() * TWOPI, 30, 16)
						or FindSwimmableOffset(from_pt, math.random() * TWOPI, 15, 16)
		if offset ~= nil then
			return from_pt + offset
		end
		return teleportee:GetPosition()
	else
		local centers = {}
		for i, node in ipairs(TheWorld.topology.nodes) do
			if TheWorld.Map:IsPassableAtPoint(node.x, 0, node.y) and node.type ~= NODE_TYPE.SeparatedRoom then
				table.insert(centers, {x = node.x, z = node.y})
			end
		end
		if #centers > 0 then
			local pos = centers[math.random(#centers)]
			return Point(pos.x, 0, pos.z)
		else
			return caster:GetPosition()
		end
	end
end

local function teleport_end(teleportee, locpos, loctarget, staff)
    if loctarget ~= nil and loctarget:IsValid() and loctarget.onteleto ~= nil then
        loctarget:onteleto()
    end

    if teleportee.components.inventory ~= nil and teleportee.components.inventory:IsHeavyLifting() then
        teleportee.components.inventory:DropItem(
            teleportee.components.inventory:Unequip(EQUIPSLOTS.BODY),
            true,
            true
        )
    end

    --#v2c hacky way to prevent lightning from igniting us
    local preventburning = teleportee.components.burnable ~= nil and not teleportee.components.burnable.burning
    if preventburning then
        teleportee.components.burnable.burning = true
    end
    TheWorld:PushEvent("ms_sendlightningstrike", locpos)
    if preventburning then
        teleportee.components.burnable.burning = false
    end

    if teleportee:HasTag("player") then
        teleportee.sg.statemem.teleport_task = nil
        teleportee.sg:GoToState(teleportee:HasTag("playerghost") and "appear" or "wakeup")
        --teleportee.SoundEmitter:PlaySound(staff.skin_castsound or "dontstarve/common/staffteleport")
    else
        teleportee:Show()
        if teleportee.DynamicShadow ~= nil then
            teleportee.DynamicShadow:Enable(true)
        end
        if teleportee.components.health ~= nil then
            teleportee.components.health:SetInvincible(false)
        end
        teleportee:PushEvent("teleported")
    end
end

local function teleport_continue(teleportee, locpos, loctarget, staff)
    if teleportee.Physics ~= nil then
        teleportee.Physics:Teleport(locpos.x, 0, locpos.z)
    else
        teleportee.Transform:SetPosition(locpos.x, 0, locpos.z)
    end

    if teleportee:HasTag("player") then
        teleportee:SnapCamera()
        teleportee:ScreenFade(true, 1)
        teleportee.sg.statemem.teleport_task = teleportee:DoTaskInTime(1, teleport_end, locpos, loctarget, staff)
    else
        teleport_end(teleportee, locpos, loctarget, staff)
    end
end

local function teleport_start(teleportee, staff, caster, loctarget, target_in_ocean, no_teleport)
    local ground = TheWorld

    --V2C: Gotta do this RIGHT AWAY in case anything happens to loctarget or caster
	local locpos
	if not no_teleport then
		locpos = (teleportee.components.teleportedoverride ~= nil and teleportee.components.teleportedoverride:GetDestPosition())
			or (loctarget == nil and getrandomposition(caster, teleportee, target_in_ocean))
			or (loctarget.teletopos ~= nil and loctarget:teletopos())
			or loctarget:GetPosition()

		if teleportee.components.locomotor ~= nil then
			teleportee.components.locomotor:StopMoving()
		end
	end

    staff.components.finiteuses:Use(staff.components.finiteuses.total * 0.1)

    if ground:HasTag("cave") then
        -- There's a roof over your head, magic lightning can't strike!
        ground:PushEvent("ms_miniquake", { rad = 3, num = 5, duration = 1.5, target = teleportee })
        return
    end

	local is_teleporting_player
	if not no_teleport then
		if teleportee:HasTag("player") then
			is_teleporting_player = true
			teleportee.sg:GoToState("forcetele")
		else
			if teleportee.components.health ~= nil then
				teleportee.components.health:SetInvincible(true)
			end
			if teleportee.DynamicShadow ~= nil then
				teleportee.DynamicShadow:Enable(false)
			end
			teleportee:Hide()
		end
	end

    --#v2c hacky way to prevent lightning from igniting us
    local preventburning = teleportee.components.burnable ~= nil and not teleportee.components.burnable.burning
    if preventburning then
        teleportee.components.burnable.burning = true
    end
    ground:PushEvent("ms_sendlightningstrike", teleportee:GetPosition())
    if preventburning then
        teleportee.components.burnable.burning = false
    end

    if caster ~= nil then
        if caster.components.staffsanity then
            caster.components.staffsanity:DoCastingDelta(-TUNING.SANITY_HUGE)
        elseif caster.components.sanity ~= nil then
            caster.components.sanity:DoDelta(-TUNING.SANITY_HUGE)
        end
    end

    ground:PushEvent("ms_deltamoisture", TUNING.TELESTAFF_MOISTURE)

	if not no_teleport then
		if is_teleporting_player then
			teleportee.sg.statemem.teleport_task = teleportee:DoTaskInTime(3, teleport_continue, locpos, loctarget, staff)
		else
			teleport_continue(teleportee, locpos, loctarget, staff)
		end
	end
end

local function teleport_targets_sort_fn(a, b)
    return a.distance < b.distance
end

local TELEPORT_MUST_TAGS = { "locomotor" }
local TELEPORT_CANT_TAGS = { "playerghost", "INLIMBO", "noteleport" }
local function teleport_func(inst, target, pos, caster)
	target = target or caster

    local x, y, z = target.Transform:GetWorldPosition()
	local target_in_ocean = target.components.locomotor ~= nil and target.components.locomotor:IsAquatic()
	local no_teleport = target:HasTag("noteleport") --targetable by spell, but don't actually teleport
	local loctarget
	if not no_teleport then
		loctarget = (target.components.minigame_participator ~= nil and target.components.minigame_participator:GetMinigame())
				or (target.components.teleportedoverride ~= nil and target.components.teleportedoverride:GetDestTarget())
				or (target.components.hitchable ~= nil and target:HasTag("hitched") and target.components.hitchable.hitched)
				or nil

		if loctarget == nil and not target_in_ocean then
			loctarget = FindNearestActiveTelebase(x, y, z, nil, 1)
		end
	end
	teleport_start(target, inst, caster, loctarget, target_in_ocean, no_teleport)
end
----
local function common_fn(tags)
    local inst = CreateEntity()

    inst.projectiledelay = FRAMES

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    for k, v in pairs(tags) do
        inst:AddTag(v)
    end
    inst:AddTag("shadowlevel")
    inst:AddTag("lol_weapon")
    inst:AddTag("riftmaker")
    inst:AddTag("shadow_item")
    inst:AddTag("shadow")

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable.dapperness = -5/60

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(4)

    inst:AddComponent("riftmaker")

    inst:AddComponent("finiteuses") 
    inst.components.finiteuses:SetMaxUses(200)
    inst.components.finiteuses:SetUses(200)
    inst.components.finiteuses:SetOnFinished(finish)
    if inst.components.finiteuses.current <= 0 then 
        inst.components.equippable.restrictedtag = "别看了我就是不让你装备的"
    end
--[[
    inst:AddComponent('trader')
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
]]
    local setbonus = inst:AddComponent("setbonus")
	setbonus:SetSetName(EQUIPMENTSETNAMES.DREADSTONE)

    MakeHauntableLaunch(inst)

    return inst
end

local function DoRegen(inst, owner)
	if owner.components.sanity ~= nil and owner.components.sanity:IsInsanityMode() then
		local setbonus = inst.components.setbonus ~= nil and inst.components.setbonus:IsEnabled(EQUIPMENTSETNAMES.DREADSTONE) and TUNING.ARMOR_DREADSTONE_REGEN_SETBONUS or 1
		local rate = 1 / Lerp(1 / TUNING.ARMOR_DREADSTONE_REGEN_MAXRATE, 1 / TUNING.ARMOR_DREADSTONE_REGEN_MINRATE, owner.components.sanity:GetPercent())
		inst.components.finiteuses:Repair(inst.components.finiteuses.total * rate * setbonus)
	end
end

local function StartRegen(inst, owner)
	if inst.regentask == nil then
		inst.regentask = inst:DoPeriodicTask(TUNING.ARMOR_DREADSTONE_REGEN_PERIOD, DoRegen, nil, owner)
	end
end

local function StopRegen(inst)
	if inst.regentask ~= nil then
		inst.regentask:Cancel()
		inst.regentask = nil
	end
end

local function turnon(inst)
    local owner = inst.components.inventoryitem.owner
    if inst._fx ~= nil then 
        inst._fx:Remove()
    end
    inst._fx = SpawnPrefab("riftmaker_light")
    inst._fx.entity:SetParent((owner or inst).entity)
    inst._fx.Transform:SetPosition(0, 0, 0)
end

local function turnoff(inst)
    if inst._fx ~= nil then
        inst._fx:Remove()
    end
end

local function OnDropped(inst)
    if inst._fx ~= nil then 
        inst._fx:Remove()
    end
    turnon(inst)
end

local function OnPickup(inst)
    if inst._fx ~= nil then 
        inst._fx:Remove()
    end
end

local function weapon_onhitother(owner, data)
    if data and data.target then
        if data.target.components.health and data.damageresolved then
            data.target.components.health:DoDelta(-data.damageresolved * .25, nil, owner, nil, owner, true)
        end
        if data.target.AnimState then
            SpawnPrefab("electricchargedfx"):SetTarget(data.target)
        end
    end
end
--[[
local function telestaff(inst, target, pos, caster)
    local p = SpawnPrefab("telestaff")
    caster.components.talker:Say("?")
    p.components.spellcaster:CastSpell(inst, target, pos, caster)
    p:Remove()
end
]]
local function weapon_fn()
    local inst = common_fn({"weapon", "rangedweapon"})

    inst.spelltype = "RIFTMAKER"

    inst.AnimState:SetBank("weapon_riftmaker")
    inst.AnimState:SetBuild("weapon_riftmaker")
    inst.AnimState:PlayAnimation("idle")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(50)

    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(teleport_func)
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.canonlyuseonlocomotorspvp = true

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)
    inst.components.weapon:SetRange(5, 7)
    --inst.components.weapon:SetElectric()
    inst.components.weapon:SetOnAttack(function(inst, attacker, target)
        if not target:IsValid() then
            --target killed or removed in combat damage phase
            return
        end

        if attacker.components.sanity then 
            attacker.components.sanity:DoDelta(-2)
        end

        if target.components.sleeper ~= nil and target.components.sleeper:IsAsleep() then
            target.components.sleeper:WakeUp()
        end

        if target.components.combat ~= nil then
            target.components.combat:SuggestTarget(attacker)
        end

        if target.sg ~= nil and not target.sg:HasStateTag("frozen") then
            target:PushEvent("attacked", { attacker = attacker, weapon = inst })
        end

        if attacker.components.health and attacker.components.health:IsHurt() and IsLifeDrainable(target) then
            attacker.components.health:DoDelta(7,false)
        end

    end)
    inst.components.weapon:SetProjectile("riftmaker_charge")

    inst.components.equippable:SetOnEquip(function(inst, owner)
        owner.AnimState:OverrideSymbol("swap_object", "swap_weapon_riftmaker", "swap_weapon_riftmaker")

        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")

        if owner.components.sanity ~= nil then
            StartRegen(inst, owner)
        else
            StopRegen(inst)
        end

        turnon(inst)

        owner:ListenForEvent("onhitother", weapon_onhitother)
    end)
    inst.components.equippable:SetOnUnequip(function(inst, owner)
        owner.AnimState:Hide("ARM_carry")
        owner.AnimState:Show("ARM_normal")

        StopRegen(inst)

        turnoff(inst)

        owner:RemoveEventCallback("onhitother", weapon_onhitother)
    end)

    inst.components.riftmaker.form = "weapon"

    inst:ListenForEvent("onpickup", OnPickup)
    inst:ListenForEvent("ondropped", OnDropped)

    return inst
end

local function amulet_onhitother(owner, data)
    if data and data.target and data.target.components.health and owner.components.health then
        --data.target.components.health:DoDelta(-7, nil, owner, nil, owner, true)
        if owner.components.health and owner.components.health:IsHurt() and IsLifeDrainable(data.target) then
            owner.components.health:DoDelta(7,false)
        end
        if owner.components.sanity then 
            owner.components.sanity:DoDelta(-2)
        end
        for k in pairs(owner.components.inventory.equipslots) do 
            if owner.components.inventory.equipslots[k].prefab == "riftmaker_amulet" then 
                owner.components.inventory.equipslots[k].components.finiteuses:Use(1)
            end
        end

    end
end

local function amulet_fn()
    local inst = common_fn({"amulet"})

    inst.AnimState:SetBank("amulet_riftmaker")
    inst.AnimState:SetBuild("amulet_riftmaker")
    inst.AnimState:PlayAnimation("idle")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.equippable.equipslot = EQUIPSLOTS.NECK or EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(function(inst, owner)
        owner.AnimState:OverrideSymbol("swap_body", "swap_amulet_riftmaker", "purpleamulet")

        if owner.components.sanity ~= nil then
            StartRegen(inst, owner)
        else
            StopRegen(inst)
        end

        turnon(inst)

        owner:ListenForEvent("onhitother", amulet_onhitother)
    end)
    inst.components.equippable:SetOnUnequip(function(inst, owner)
        owner.AnimState:ClearOverrideSymbol("swap_body")

        StopRegen(inst)

        turnoff(inst)

        owner:RemoveEventCallback("onhitother", amulet_onhitother)
    end)

    inst:ListenForEvent("onpickup", OnPickup)
    inst:ListenForEvent("ondropped", OnDropped)

    inst.components.riftmaker.form = "amulet"

    return inst
end

local function OnHit(inst, owner, target)
    SpawnPrefab("bishop_charge_hit").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

local function OnAnimOver(inst)
    inst:DoTaskInTime(.3, inst.Remove)
end

local function OnThrown(inst)
    inst:ListenForEvent("animover", OnAnimOver)
end

local function fx_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("riftmaker_attack")
    inst.AnimState:SetBuild("riftmaker_attack")
    inst.AnimState:PlayAnimation("idle")

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(30)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetHitDist(2)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(inst.Remove)
    inst.components.projectile:SetOnThrownFn(OnThrown)

    return inst
end

local function PlayHitSound(proxy)
    local inst = CreateEntity()

    --[[Non-networked entity]]

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()

    inst.Transform:SetFromProxy(proxy.GUID)

    inst.SoundEmitter:PlaySound("dontstarve/creatures/bishop/shotexplo")

    inst:Remove()
end

local function fx_hit_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    --Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() then
        --Delay one frame in case we are about to be removed
        inst:DoTaskInTime(0, PlayHitSound)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst:DoTaskInTime(.5, inst.Remove)

    return inst
end

local function riftmaker_lightfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.Light:SetColour(222 / 255, 52 / 255, 244 / 255)
    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.8)
    inst.Light:SetRadius(2)
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("riftmaker_weapon", weapon_fn, weapon_assets, weapon_prefabs),
    Prefab("riftmaker_amulet", amulet_fn, amulet_assets),
    Prefab("riftmaker_charge", fx_fn, fx_assets),
    Prefab("riftmaker_charge_hit", fx_hit_fn),
    Prefab("riftmaker_light",riftmaker_lightfn)