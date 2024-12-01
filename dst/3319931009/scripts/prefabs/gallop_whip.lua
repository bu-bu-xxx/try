local NOPRISTINE = "NOPRISTINE"
local assets = {
  Asset("ANIM", "anim/pocketwatch_weapon.zip"),
  Asset("ANIM", "anim/gallop_whip.zip")
}
local prefabs = {}
local function IsOld(inst)
  do return true end
  if inst and inst.age_state == "old" then return true end
  if inst.components.health and inst.components.health:GetPercent() < 0.2 then
    return true
  end
end
local function IsYoung(inst)
  do return false end
  if inst and inst.age_state == "young" then return true end
  if inst.components.health and inst.components.health:GetPercent() > 0.6 then
    return true
  end
end
local fns = require("common_handfn")
local function ShadowWeaponFx(inst, target, damage, stimuli, weapon,
                              damageresolved)
  if weapon ~= nil and target ~= nil and target:IsValid() and weapon:IsValid() and
    weapon:HasTag("shadow_item") then
    local fx_prefab = IsOld(inst) and
                        (weapon:HasTag("pocketwatch") and
                          "wanda_attack_pocketwatch_old_fx" or
                          "wanda_attack_shadowweapon_old_fx") or
                        (not IsYoung(inst)) and
                        (weapon:HasTag("pocketwatch") and
                          "wanda_attack_pocketwatch_normal_fx" or
                          "wanda_attack_shadowweapon_normal_fx") or nil

    if fx_prefab ~= nil then
      local fx = SpawnPrefab(fx_prefab)

      local x, y, z = target.Transform:GetWorldPosition()
      local radius = target:GetPhysicsRadius(.5)
      local angle = (inst.Transform:GetRotation() - 90) * DEGREES
      fx.Transform:SetPosition(x + math.sin(angle) * radius, 0,
                               z + math.cos(angle) * radius)
    end
  end
end

local function TryStartFx(inst, owner)
  owner = owner or inst.components.equippable:IsEquipped() and
            inst.components.inventoryitem.owner or nil

  if owner == nil then return end

  if not inst:HasTag("usesdepleted") then
    if inst._vfx_fx_inst ~= nil and inst._vfx_fx_inst.entity:GetParent() ~=
      owner then
      inst._vfx_fx_inst:Remove()
      inst._vfx_fx_inst = nil
    end

    if inst._vfx_fx_inst == nil then
      inst._vfx_fx_inst = SpawnPrefab("gallop_bloodaxe_fx")
      inst._vfx_fx_inst.entity:AddFollower()
      inst._vfx_fx_inst.entity:SetParent(owner.entity)
      inst._vfx_fx_inst.Follower:FollowSymbol(owner.GUID, "swap_object", 15, 70,
                                              0)
    end
  end
end

local function StopFx(inst)
  if inst._vfx_fx_inst ~= nil then
    inst._vfx_fx_inst:Remove()
    inst._vfx_fx_inst = nil
  end
end

local function onequip(inst, owner)
  fns._onequip(inst, owner)
  if inst.components.gallop_multifeat and
    inst.components.gallop_multifeat:IsEnabled("shadowfx") then
    inst:TryStartFx(owner)
  end
  if inst.hit_callback then
    owner:ListenForEvent("onhitother", inst.hit_callback)
  end
  if inst.UpdateFunction then inst:UpdateFunction() end
end

local function onunequip(inst, owner)
  fns._onunequip(inst, owner)
  inst:StopFx(owner)
  if inst.hit_callback then
    owner:RemoveEventCallback("onhitother", inst.hit_callback)
  end
  if inst.UpdateFunction then inst:UpdateFunction() end
end

local function onequiptomodel(inst, owner, from_ground) inst:StopFx(owner) end

local CanAOEAttack = require("gallop_aoe")._canattack
local AOEAttack = require("gallop_aoe").attack
local function CanFanAttack(owner, target, angle, maxdeg, neardist)
  local deg = math.abs(anglediff(angle or owner.Transform:GetRotation(),
                                 owner:GetAngleToPoint(
                                   target.Transform:GetWorldPosition())))
  -- print(deg, maxdeg)
  if target:GetDistanceSqToInst(owner) > neardist and deg > maxdeg then
    return false
  end
  return true
end
local function CanAbsorb(inst)
    return inst and inst.components.health and not inst:HasOneOfTags(NON_LIFEFORM_TARGET_TAGS)
end
local aoe_cant_tags = {}
shallowcopy(require("gallop_aoe").aoe_cant_tags, aoe_cant_tags)
ConcatArrays(aoe_cant_tags, {"flying"})
local function DoAOEAttack(inst, target, owner, healthgain, healthlose, maxgain,
                           radius, canattack, pos)
  maxgain = maxgain or 10
  healthgain = healthgain or 1
  healthlose = healthlose or (-TUNING.BLOODAXE_HEALTH_DELTA - 1)
  if not CanAbsorb(target) then healthlose=0 end
  local angle = target and
                  owner:GetAngleToPoint(target.Transform:GetWorldPosition())
  local count=0
  AOEAttack({
    inst = inst,
    position = pos,
    target = target,
    owner = owner,
    radius = radius or ((inst.components.weapon.hitrange or 1.5) +
      TUNING.GALLOP_WHIP_AOE_COMPENSATE_RADIUS),
    canattack = function(params, v)
      return CanAOEAttack(params, v) and
               (not angle or CanFanAttack(owner, v, angle, 90, .2)) and
               (not canattack or canattack(params, v))
    end,
    onattack=function(params,v)
        if CanAbsorb(v) then count=count+1 end
    end,
    postattack = function(params, _count)
      if inst.components.gallop_multifeat:IsEnabled("bloodhungry") then
        local health = math.min(count * healthgain, maxgain) - healthlose
        if health ~= 0 and not owner.components.health:IsDead() then
          owner.components.health:DoDelta(health, false, inst.prefab)
        end
      end
    end
  })
end

local function CLIENT_PlayFuelSound(inst)
  local parent = inst.entity:GetParent()
  local container = parent ~= nil and
                      (parent.replica.inventory or parent.replica.container) or
                      nil
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
    -- Dedicated server does not need to trigger sfx
    if not TheNet:IsDedicated() then CLIENT_PlayFuelSound(inst) end
  end
end
local chance = .1
local function Lucky() return math.random() < chance end

local function ReleasePrison(inst, doer, target)
  local pos = target:GetPosition()
  local spell = SpawnPrefab("gallop_shadow_pillar_spell")
  inst.components.timer:StartTimer("shadow_pillar", 10)
  spell.caster = doer
  spell.item = inst
  local platform = TheWorld.Map:GetPlatformAtPoint(pos.x, pos.z)
  if platform ~= nil then
    spell.entity:SetParent(platform.entity)
    spell.Transform:SetPosition(platform.entity:WorldToLocalSpace(pos:Get()))
  else
    spell.Transform:SetPosition(pos:Get())
  end
end
local function TryReleasePrison(inst, attacker, target)
  if attacker and attacker:IsValid() and target and target:IsValid() then
  else
    return
  end
  if not Lucky() or inst.components.timer:TimerExists("shadow_pillar") then
    return
  end
  ReleasePrison(inst, attacker, target)
end
local function onattack(inst, attacker, target)
  if not target or not target:IsValid() then return end
  local age = inst.components.gallop_multifeat:IsEnabled("agewise")
  if age then
    if IsYoung(attacker) then
      inst.SoundEmitter:PlaySound(
        "wanda2/characters/wanda/watch/weapon/shadow_attack")
    else
      -- fx will handle sounds
    end
  else
    inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/weapon/attack")
  end
  if not inst:HasTag("usesdepleted") then
    DoAOEAttack(inst, target, attacker)
    if inst.components.gallop_multifeat:IsEnabled("shadowprison") then
      TryReleasePrison(inst, attacker, target)
    end
  end
  SpawnAt("balloon_pop_head", target)
end
local fuelvalue = {flint = 0.2, nightmarefuel = 0.2, horrorfuel = 1}
local function OnRepaired(inst, doer, repair_item)
  local f = inst.components.finiteuses
  if f then
    local fuel = fuelvalue[repair_item.prefab] or 0
    f:Repair(fuel * f.total)
    inst:PushEvent("refueled")
  end
  if inst.PlayFuelSound then inst:PlayFuelSound() end
end
local function GetEquipOwner(inst)
  return inst.components.equippable:IsEquipped() and
           inst.components.inventoryitem.owner
end

local common_fn = {
  enable = function(comp, inst, self)
    if self.onequip then
      local owner = GetEquipOwner(inst)
      if owner and owner:IsValid() then self.onequip(inst, owner) end
    end
  end,
  disable = function(comp, inst, self)
    if self.onunequip then
      local owner = GetEquipOwner(inst)
      if owner and owner:IsValid() then self.onunequip(inst, owner) end
    end
  end
}
local custom_fn = {
  shadowfx = {},
  bloodhungry = {},
  shadowprison = {},
  agewise = {},
  damage = {
    enable = function(comp, inst, self)
      inst:AddTag("shadow_item")
      common_fn.enable(comp, inst, self)
    end,
    disable = function(comp, inst, self)
      inst:RemoveTag("shadow_item")
      common_fn.disable(comp, inst, self)
    end,
    onequip = function(inst, owner)
      -- inst:UpdateDamage()
      -- owner:ListenForEvent("healthdelta", inst.UpdateDamage)
    end,
    onunequip = function(inst, owner)
      -- inst:UpdateDamage()
      -- owner:RemoveEventCallback("healthdelta", inst.UpdateDamage)
    end
  }
}
local function master1(inst)
  inst:AddComponent("gallop_multifeat")

  inst.scrapbook_fueled_rate = TUNING.TINY_FUEL
  inst.scrapbook_fueled_uses = true

  inst.build = "gallop_whip"

  inst:AddComponent("inventoryitem")
  inst:AddComponent("lootdropper")

  inst:AddComponent("inspectable")

  inst:AddComponent("equippable")
  inst.components.equippable:SetOnEquip(onequip)
  inst.components.equippable:SetOnUnequip(onunequip)
  inst.components.equippable:SetOnEquipToModel(onequiptomodel)
  inst.components.equippable.equipslot = EQUIPSLOTS.HANDS

  inst:AddComponent("weapon")
  inst.components.weapon:SetDamage(TUNING.GALLOP_WHIP_DAMAGE)
  inst.components.weapon:SetRange(TUNING.GALLOP_WHIP_RANGE)
  inst.components.weapon:SetOnAttack(onattack)

  inst:AddComponent("finiteuses")
  inst.components.finiteuses:SetMaxUses(TUNING.GALLOP_WHIP_USES)
  inst.components.finiteuses:SetUses(TUNING.GALLOP_WHIP_USES)
  inst.components.finiteuses:SetOnFinished(inst.Remove)

  inst:AddComponent("repairable")
  inst.components.repairable.repairmaterial = MATERIALS.FLINT
  inst.components.repairable.onrepaired = OnRepaired
  function inst.components.repairable:Repair(doer, repair_item)
    if self.testvalidrepairfn and
      not self.testvalidrepairfn(self.inst, repair_item) then
      return false
    elseif repair_item.components.repairer == nil or self.repairmaterial ~=
      repair_item.components.repairer.repairmaterial then
      -- wrong material
      return false
    elseif self.checkmaterialfn ~= nil then
      local success, reason = self.checkmaterialfn(self.inst, repair_item)
      if not success then return false, reason end
    end

    if repair_item.components.repairer.boatrepairsound then
      self.inst.SoundEmitter:PlaySound(repair_item.components.repairer
                                         .boatrepairsound)
    end

    if repair_item.components.stackable ~= nil then
      repair_item.components.stackable:Get():Remove()
    else
      repair_item:Remove()
    end

    if self.onrepaired ~= nil then
      self.onrepaired(self.inst, doer, repair_item)
    end

    return true
  end

  inst.TryStartFx = TryStartFx
  inst.StopFx = StopFx
  inst.hasshadowfx = false

  MakeHauntableLaunch(inst)

  return inst
end
local function common1()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)

  inst:AddTag("pocketwatch")
  inst:AddTag("repairable_any") -- referenced in gallop_main.lua

  inst.AnimState:SetBank("pocketwatch_weapon")
  inst.AnimState:SetBuild("gallop_whip")
  inst.AnimState:OverrideSymbol("pocketwatch_weapon01", "gallop_whip", "whip")
  inst.AnimState:PlayAnimation("idle", true)

  MakeInventoryFloatable(inst, "small", 0.05, {1.2, 0.75, 1.2})
  return inst
end
local function fn()
  local inst = common1()
  inst.entity:SetPristine()
  if not TheWorld.ismastersim then return inst end
  master1(inst)
  return inst
end

local assets2 = {
  Asset("ANIM", "anim/pocketwatch_weapon.zip"),
  Asset("ANIM", "anim/gallop_whip.zip"),
  Asset("ANIM", "anim/gallop_bloodaxe.zip")
}

local prefabs2 = {"gallop_bloodaxe_fx", "gallop_shadow_pillar_spell"}
local function DoRegen(inst, owner)
  if owner:IsValid() and owner.components.sanity ~= nil and
    owner.components.sanity:IsInsanityMode() then
    local setbonus = -- inst.components.setbonus ~= nil and
    --  inst.components.setbonus:IsEnabled(
    --    EQUIPMENTSETNAMES.DREADSTONE) and
    --  TUNING.ARMOR_DREADSTONE_REGEN_SETBONUS or
    1
    local rate = 1 / Lerp(1 / TUNING.GALLOP_DREADCLUB_REGEN_MAXRATE,
                          1 / TUNING.GALLOP_DREADCLUB_REGEN_MINRATE,
                          owner.components.sanity:GetPercent())
    inst.components.finiteuses:Repair(inst.components.finiteuses.total * rate *
                                        setbonus)
  end
end
local function StopRegen(inst)
  if inst.regentask ~= nil then
    inst.regentask:Cancel()
    inst.regentask = nil
  end
end
local function StartRegen(inst)
  local owner = GetEquipOwner(inst)
  if owner then
    inst.regentask = inst.regentask or
                       inst:DoPeriodicTask(TUNING.ARMOR_DREADSTONE_REGEN_PERIOD,
                                           DoRegen, nil, owner)
  else
    StopRegen(inst)
  end
end
local function Unequip(inst)
  if inst.components.equippable:IsEquipped() then
    ---@type Instance
    local owner = inst.components.inventoryitem.owner
    if owner then
      local item = owner.components.inventory:Unequip(
      inst.components.equippable.equipslot)
      if item then owner.components.inventory:GiveItem(item) end
    end
  end
  inst.components.equippable.restrictedtag = "xxxxxxxx"
end
local function Equip(inst) inst.components.equippable.restrictedtag = nil end
local function UpdateFunction(inst)
  local use = inst.components.finiteuses and
                inst.components.finiteuses:GetPercent() or 1

  inst:EnableAOE()
  if use <= 0 then
    inst.components.gallop_multifeat:DisableAllFeatures()
    Unequip(inst)
    StartRegen(inst)
  else
    inst.components.gallop_multifeat:EnableAllFeatures()
    Equip(inst)
    if use >= 1 then
      StopRegen(inst)
    else
      StartRegen(inst)
    end
  end
end
local function CalcDapperness(inst, owner)
  local insanity = owner.components.sanity ~= nil and
                     owner.components.sanity:IsInsanityMode()
  local other = nil -- GetSetBonusEquip(inst, owner)
  if other ~= nil then
    return (insanity and (inst.regentask ~= nil or other.regentask ~= nil) and
             TUNING.GALLOP_BLOODAXE_CRAZINESS or 0) * 0.5
  end
  return
    insanity and inst.regentask ~= nil and TUNING.GALLOP_BLOODAXE_CRAZINESS or 0
end

local function UpdateDamage(inst)
  local owner = GetEquipOwner(inst)
  local depleted = inst:HasTag("usesdepleted")
  local normal_damage = TUNING.GALLOP_BLOODAXE_NORMAL_DAMAGE
  local planar_damage = TUNING.GALLOP_BLOODAXE_PLANAR_DAMAGE
  local dmg = normal_damage.young
  local pdmg = planar_damage.young
  if owner then
    dmg = IsYoung(owner) and dmg or
            (IsOld(owner) and normal_damage.old or normal_damage.prime)
  end
  if owner then
    pdmg = IsYoung(owner) and pdmg or
             (IsOld(owner) and planar_damage.old or planar_damage.prime)
  end
  if depleted then
    dmg = TUNING.GALLOP_BLOODAXE_DEPLETE_DAMAGE
    pdmg = 0
  end
  inst.components.weapon:SetDamage(dmg)
  inst.components.planardamage:SetBaseDamage(pdmg)
end
local function hit_callback(owner, data)
  ShadowWeaponFx(owner, data.target, data.damage, data.stimuli, data.weapon,
                 data.damageresolved)
end
local function ReticuleMouseTargetFn(inst, mousepos)
  if mousepos == nil then return nil end
  return ThePlayer:GetPosition()
end

local function ReticuleTargetFn(inst)
  if ThePlayer and ThePlayer.components.playercontroller ~= nil and
    ThePlayer.components.playercontroller.isclientcontrollerattached then
    return ThePlayer:GetPosition()
  end
end
local function InitAOE(inst)
  inst.components.aoetargeting:SetEnabled(not inst:HasTag("usesdepleted"))
end

local function SetupRingAOE(inst)
  inst.components.aoetargeting:SetAlwaysValid(true)
  inst.components.aoetargeting:SetAllowRiding(true)
  inst.components.aoetargeting.reticule.reticuleprefab =
    "gallop_reticule_bloodaxe"
  inst.components.aoetargeting.reticule.pingprefab =
    "gallop_reticule_bloodaxeping"
  inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
  inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
  inst.components.aoetargeting.reticule.validcolour = {1, 0, 0, 1}
  inst.components.aoetargeting.reticule.invalidcolour = {.5, 0, 0, 1}
  inst.components.aoetargeting.reticule.ease = true
  inst.components.aoetargeting.reticule.mouseenabled = true
  if TheWorld.ismastersim then inst:DoTaskInTime(0, InitAOE) end
end
local function ShootLaser(inst, doer, minrad, maxrad, hitted, pos)
  -- print("ShootLaser", inst, doer, minrad, maxrad)
  DoAOEAttack(inst, nil, doer, 5, 0, math.max(20 - GetTableSize(hitted), 0),
              maxrad, function(params, v)
    -- print("hit", v, dist, not hitted[v.GUID])
    if not hitted[v.GUID] then
      hitted[v.GUID] = true
      return true
    end
    return false
  end, pos)
end
local function DoRingLaser(inst, doer, pos)
  doer:ForceFacePoint(pos)
  local fx = SpawnAt("gallop_laser_ring", doer)
  local t = fx.AnimState:GetCurrentAnimationLength() or 1
  local begin = GetTime()
  local maxradius = fx.Transform:GetScale() * 5.1
  local lastradius = 0
  local hitted = {}
  inst._lasertask = inst._lasertask or inst:DoPeriodicTask(0, function()
    local now = GetTime()
    local pct = math.clamp(now - begin, 0, t) / t
    local radius = pct * maxradius
    ShootLaser(inst, doer, lastradius, radius, hitted, pos)
    lastradius = radius
    if pct >= 1 then
      if inst._lasertask then
        inst._lasertask:Cancel()
        inst._lasertask = nil
      end
    end
  end)
  -- health
  if doer.components.health then
    doer.components.health:DoDelta(-3, nil, inst.prefab)
  end
  -- cd
  inst.components.rechargeable:Discharge(TUNING.GALLOP_BLOODAXE_COOLDOWN)
  -- use
  if inst.components.finiteuses and not inst:HasTag("usesdepleted") then
    inst.components.finiteuses:Use(5)
  end
  return true
end
local function EnableAOE(inst, charge)
  local a = inst.components.aoetargeting
  if charge ~= nil then a.chargeenable = charge end
  a:SetEnabled(not not (a.chargeenable) and not inst:HasTag("usesdepleted"))
end
local function OnCharged(inst) EnableAOE(inst, true) end
local function OnDischarged(inst) EnableAOE(inst, false) end
-- local function fixsg(inst, data)
--  local name = data.state
--  if name == "dojostleaction" then
--    local owner = GetEquipOwner(inst)
--    if owner then
--      local ba = owner:GetBufferedAction()
--      if ba and ba.pos then owner:ForceFacePoint(ba:GetActionPoint()) end
--    end
--  end
-- end
local function stroverridefn(inst, act)
  if act.action == ACTIONS.CASTAOE then
    return STRINGS.ACTIONS.CASTAOE[inst.prefab:upper()]
  end
end
local function checkfn(inst, owner) return owner:HasTag("gallop_shadow_aligned") end
local function announce(inst, data)
  local talker = data and data.owner and data.owner.components.talker
  if talker then talker:Say(STRINGS.GALLOP_SHADOW_WEAPON_ANNOUNCE) end
end
local function fn2()
  local inst = common1()
  inst:AddTag("cast_like_pocketwatch")
  -- inst:ListenForEvent("willenternewstate", fixsg)
  inst:AddComponent("aoetargeting")
  inst.components.aoetargeting:SetAllowRiding(false)
  SetupRingAOE(inst)
  inst.playfuelsound = net_event(inst.GUID, "pocketwatch_weapon.playfuelsound")
  inst.AnimState:SetBuild("gallop_bloodaxe")
  inst.AnimState:ClearOverrideSymbol("pocketwatch_weapon01")
  inst.stroverridefn = stroverridefn
  inst.entity:SetPristine()
  if not TheWorld.ismastersim then
    -- delayed because we don't want any old events
    inst:DoTaskInTime(0, inst.ListenForEvent,
                      "pocketwatch_weapon.playfuelsound", CLIENT_PlayFuelSound)

    return inst
  end
  master1(inst)
  inst.build = "gallop_bloodaxe"
  inst.components.gallop_multifeat:AddFeatures(custom_fn)

  inst:AddComponent("timer")

  inst.components.weapon:SetDamage(TUNING.GALLOP_BLOODAXE_NORMAL_DAMAGE.young)
  inst.components.weapon:SetRange(TUNING.GALLOP_BLOODAXE_RANGE)

  inst:AddComponent("rechargeable")
  inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
  inst.components.rechargeable:SetOnChargedFn(OnCharged)
  inst.components.rechargeable:SetMaxCharge(TUNING.GALLOP_BREAKER_COOLDOWN)
  OnCharged(inst)

  inst:AddComponent("planardamage")
  inst.components.planardamage:SetBaseDamage(
    TUNING.GALLOP_BLOODAXE_PLANAR_DAMAGE.young)
  inst:AddComponent("damagetypebonus")
  inst.components.damagetypebonus:AddBonus("lunar_aligned", inst, 1.1)

  inst.components.equippable:SetOnEquip(onequip)
  inst.components.equippable:SetOnUnequip(onunequip)
  inst.components.equippable.dapperfn = CalcDapperness
  inst.components.equippable.is_magic_dapperness = true
  -- inst.components.equippable.restrictedtag = "gallop"

  -- local ui = inst:AddComponent("gallop_uniqueitem")
  -- ui.checkfn = checkfn
  -- inst:ListenForEvent("onuniqueunequip", announce)

  inst.StartRegen = StartRegen
  inst.StopRegen = StopRegen
  inst.components.finiteuses:SetMaxUses(TUNING.GALLOP_BLOODAXE_USES)
  inst.components.finiteuses:SetUses(TUNING.GALLOP_BLOODAXE_USES)
  inst.components.finiteuses:SetOnFinished(nil)

  inst.components.repairable.repairmaterial = MATERIALS.NIGHTMARE
  inst.UpdateFunction = function() return UpdateFunction(inst) end
  inst:ListenForEvent("percentusedchange", UpdateFunction)
  inst:DoTaskInTime(0, UpdateFunction)
  inst.UpdateDamage = function() UpdateDamage(inst) end

  inst.PlayFuelSound = SERVER_PlayFuelSound
  inst.hit_callback = function(...)
    if inst.components.gallop_multifeat:IsEnabled("agewise") then
      return hit_callback(...)
    end
  end

  inst:AddComponent("aoespell")
  -- just to mute actionfail speech
  inst.components.aoespell:SetSpellFn(DoRingLaser)
  
  inst.EnableAOE=EnableAOE

  return inst
end

return Prefab("gallop_whip", fn, assets, prefabs),
       Prefab("gallop_bloodaxe", fn2, assets2, prefabs2)
