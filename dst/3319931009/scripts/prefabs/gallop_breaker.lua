local assets = {
  Asset("ANIM", "anim/gallop_breaker.zip"),
  Asset("SOUND", "sound/zombie.fsb"),
  Asset("SOUNDPACKAGE", "sound/zombie.fev")
}
local prefabs = {"gallop_reticuleaoe", "gallop_reticuleaoeping"}
local fns = require("common_handfn")
local function onequip(inst, owner)
  fns._onequip(inst, owner, "gallop_breaker", "swap_object")
  owner:ListenForEvent("performaction", inst.Boom)
  owner:ListenForEvent("newstate", inst.OnNewState)
  owner:ListenForEvent("onattackother", inst._weaponused_callback)
  if inst.components.gallop_multifeat:IsEnabled("boardingparty") then
    local data = inst.components.gallop_multifeat:GetData("boardingparty")
    if data.onequip then data.onequip(inst, owner) end
  end
  inst:PlayZombieSound(owner, true)
end

local function onunequip(inst, owner)
  fns._onunequip(inst, owner)
  owner:RemoveEventCallback("performaction", inst.Boom)
  owner:RemoveEventCallback("newstate", inst.OnNewState)
  owner:RemoveEventCallback("onattackother", inst._weaponused_callback)
  if inst.components.gallop_multifeat:IsEnabled("boardingparty") then
    local data = inst.components.gallop_multifeat:GetData("boardingparty")
    if data.onequip then data.onunequip(inst, owner) end
  end
  inst:PlayZombieSound(owner, false)
end
local actions = {"CHOP", "MINE", "HAMMER", "DIG", "HACK"}
local efficiency = 3
local function SetupActions(inst)
  if not inst.components.tool then
    inst:AddComponent("tool")
    inst.components.tool:EnableToughWork(true)
  end
  for k, v in pairs(actions) do
    local act = ACTIONS[v]
    if act then inst.components.tool:SetAction(act, efficiency) end
  end
  -- hammer
  inst.components.tool:SetAction(ACTIONS.HAMMER, 999)
  -- till
  if not inst.components.farmtiller then inst:AddComponent("farmtiller") end
  inst:AddInherentAction(ACTIONS.TILL)
end
local function DisableActions(inst)
  if inst.components.tool then inst:RemoveComponent("tool") end
  if inst.components.farmtiller then inst:RemoveComponent("farmtiller") end
  inst:RemoveInherentAction(ACTIONS.TILL)
end
local function EnableAOE(inst, mode, charge)
  local a = inst.components.aoetargeting
  if mode ~= nil then a.modeenable = mode end
  if charge ~= nil then a.chargeenable = charge end
  a:SetEnabled(not not (a.modeenable and a.chargeenable))
end
local function onstopuse(inst)
  if inst.stopuseitemtask ~= nil then
    inst.stopuseitemtask:Cancel()
    inst.stopuseitemtask = nil
  end
  inst.components.useableitem.inuse = false
end
local function onuse(inst)
  local val = not inst._mode:value()
  inst._mode:set(val)
  if val then
    DisableActions(inst)
    EnableAOE(inst, true)
    inst.components.gallop_multifeat:DisableFeature("boardingparty")
  else
    SetupActions(inst)
    EnableAOE(inst, false)
    inst.components.gallop_multifeat:EnableFeature("boardingparty")
  end
  if inst.stopuseitemtask == nil then
    inst.stopuseitemtask = inst:DoStaticTaskInTime(0, onstopuse)
  end
end
local function onload(inst, data) if data and data.using then onuse(inst) end end
local function onsave(inst, data) data.using = inst._mode:value() end
local function GetEquipOwner(inst)
  return inst.components.equippable:IsEquipped() and
           inst.components.inventoryitem.owner
end
local maxvol = 0.5
local function ToggleSound2(inst)
  if not TUNING.GALLOPBREAKMUSIC_ENABLED then return end
  local val = inst._mode:value()
  local owner = GetEquipOwner(inst)
  if not owner then return end
  inst = owner
  if inst.SoundEmitter then
    if val then
      inst.SoundEmitter:SetVolume('zombie', 0)
    else
      inst.SoundEmitter:SetVolume('zombie', maxvol)
    end
  end
end
local easing = require("easing")
local function ChangeSound(sound, val, mute)
  if not sound then return end
  if not TUNING.GALLOPBREAKMUSIC_ENABLED then return end
  -- local val = inst._equip:value()
  -- local mute = inst._mode:value()
  if val then
    sound.SoundEmitter:PlaySound("zombie/zombie/zombie", "zombie",
                                 easing.outQuad(mute and 0 or maxvol, 0, 1, 1))
  elseif not val then
    sound.SoundEmitter:KillSound("zombie")
  end
end
local function PlayZombieSound(inst, owner, val)
  ChangeSound(owner, val, inst._mode:value())
end
local function setequip(inst)
  -- inst._equip:set(inst.components.equippable:IsEquipped())
  local owner = GetEquipOwner(inst)
  if not owner then return end
  ChangeSound(owner, true, inst._mode:value())
end
local CanAOEAttack = require("gallop_aoe").can
local function ReticuleTargetFn()
  local player = ThePlayer
  local ground = TheWorld.Map
  local pos = Vector3()
  -- Cast range is 8, leave room for error
  -- 4 is the aoe range
  for r = 7, 0, -.25 do
    pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
    if ground:IsPassableAtPoint(pos:Get()) and
      not ground:IsGroundTargetBlocked(pos) then return pos end
  end
  return pos
end
local function SetupPoundAOE(inst)
  inst.components.aoetargeting:SetAllowRiding(true)
  inst.components.aoetargeting:SetAllowWater(true)
  inst.components.aoetargeting.reticule.reticuleprefab = "gallop_reticuleaoe"
  inst.components.aoetargeting.reticule.pingprefab = "gallop_reticuleaoeping"
  inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
  inst.components.aoetargeting.reticule.validcolour = {
    91 / 255,
    172 / 255,
    216 / 355,
    1
  }
  inst.components.aoetargeting.reticule.invalidcolour = {
    91 / 255,
    172 / 255,
    216 / 355,
    0.5
  }
  inst.components.aoetargeting.reticule.ease = true
  inst.components.aoetargeting.reticule.mouseenabled = true
  if TheWorld.ismastersim then
    inst:DoTaskInTime(0, function()
      EnableAOE(inst, inst._mode:value(),
                inst.components.rechargeable:IsCharged())
    end)
  end
end
local function Yell(inst)
  local str = GetString(inst, "ANNOUNCE_BREAKER")
  if inst.components.talker and str and str ~= "" then
    inst.components.talker:Say(str)
  end
end
local chance = .25
local function Lucky() return math.random() < chance end
local fxname = "explode_small"
local function SpawnFX(inst) local fx = SpawnAt(fxname, inst) end
local boom_actions = {"CHOP", "MINE"}
local destroy = require("gallop_aoe").destroy
local candestroy = require("gallop_aoe").candestroy
local function Boom(doer, tool, item)
  -- destroy item
  if item and item.components.workable then
    if candestroy(item, boom_actions) then destroy(doer, item, actions) end
  end
  -- yell
  if doer and doer:IsValid() then Yell(doer) end
  -- fx
  SpawnFX(item and item:IsValid() and item or doer)
end
local function TryBoom(inst, data)
  local ba = data.action
  local action = ba.action
  if (action == ACTIONS.CHOP or action == ACTIONS.MINE) and Lucky() then
    ba:AddSuccessAction(function() Boom(ba.doer, ba.invobject, ba.target) end)
  end
end
local function OnNewState(inst)
  local sg = inst.sg
  local as = inst.AnimState
  if not sg or not as then return end
  local chop = sg.statemem.chopping or sg:HasStateTag("chopping")
  local dig = sg.statemem.digging or sg:HasStateTag("digging") or
                sg:HasStateTag("predig")
  if as then
    if dig then
      as:OverrideSymbol("swap_object", "gallop_breaker", "swap_object_shovel")
    else
      as:OverrideSymbol("swap_object", "gallop_breaker", "swap_object")
    end
  end
end
local function OnCharged(inst) EnableAOE(inst, nil, true) end

local function OnDischarged(inst) EnableAOE(inst, nil, false) end
local DoUndefendedATK = require("legion_calcdamage").DoUndefendedATK
local function OnRealAttackPlayAnimation(inst, target)
  -- 呐喊
  Yell(inst)
  -- 爆炸
  local fx = SpawnAt("explode_small", target or inst)
end
local function onattack(inst, owner, target)
  if inst.shouldplayreallattack then
    inst.shouldplayreallattack = nil
    OnRealAttackPlayAnimation(owner, target)
    DoUndefendedATK(owner, target, inst, TUNING.GALLOP_BREAKER_DAMAGE_MULTIPLIER)
  end
  if target then SpawnAt("waterballoon_splash", target) end
end
local function OnRealAttack(inst, owner)
  -- 第五次普攻造成140%额外真实伤害
  local target
  local ba = owner:GetBufferedAction()
  if ba then target = ba.target end
  if not target then
    target = owner.components.combat and owner.components.combat.target
  end
  if target and target:IsValid() and inst:IsValid() and
    not IsEntityDeadOrGhost(target) and owner:IsValid() and
    owner.components.combat:IsValidTarget(target) then
    inst.shouldplayreallattack = true
  end
end
local SPEED = 8
local MUST_HAVE_SPELL_TAGS = nil
local CANT_HAVE_SPELL_TAGS = {
  "INLIMBO",
  "outofreach",
  "DECOR",
  "structure",
  'FX',
  'shadowcreature',
  'invisible',
  'spawnprotection',
  'noattack'
}
local MUST_HAVE_ONE_OF_SPELL_TAGS = {
  '_combat',
  '_inventoryitem',
  '_health',
  'locomotor',
  'tendable_farmplant',
  'CHOP_workable',
  'MINE_workable',
  'oceanfishable'
}
local launch = require("gallop_aoe").launch_single
local aoe_actions = {"CHOP", "MINE"}
-- 破坏岩石、树木，不破坏植物、建筑，水上时造成双倍技能伤害
local addwetness = TUNING.GALLOP_BREAKER_WETNESS
local function do_water_explosion_effect(doer, inst, target, position, inner)
  local launchparams = require("gallop_aoe").params_launch({
    passthrough = true,
    speed = 5,
    yspeed = 10,
    position = position
  })
  -- 人物专门加一下潮湿度（物品潮湿度由wateryprotection加满）
  if inner and target.components.moisture ~= nil and target:HasTag("player") then
    local waterproofness = target.components.moisture:GetWaterproofness()
    target.components.moisture:DoDelta(addwetness * (1 - waterproofness))
  end
  local c = target.components.combat
  if c and doer ~= target and CanAOEAttack(doer, target) then
    local mult = target:IsOnOcean() and 2 or 1
    mult = mult * (inner and TUNING.GALLOP_BREAKER_AOE_DAMAGE_INNER_MULT or 1)
    c:GetAttacked(doer, TUNING.GALLOP_BREAKER_AOE_DAMAGE * mult, inst)
  end
  if inner and target:IsValid() then
    if target.components.oceanfishable ~= nil then
      if target.components.weighable ~= nil then
        target.components.weighable:SetPlayerAsOwner(inst)
      end
      local projectile = target.components.oceanfishable:MakeProjectile()
      local cp = projectile.components.complexprojectile
      if cp then
        cp:SetHorizontalSpeed(16)
        cp:SetGravity(-30)
        cp:SetLaunchOffset(Vector3(0, 0.5, 0))
        cp:SetTargetOffset(Vector3(0, 0.5, 0))
        local v_position = target:GetPosition()
        local launch_position =
          v_position + (v_position - position):Normalize() * SPEED
        cp:Launch(launch_position, projectile, cp.owningweapon)
      end
    elseif target.components.inventoryitem ~= nil then
      launch(launchparams, target)
    elseif target.waveactive then
      target:DoSplash()
    elseif candestroy(target, aoe_actions) then
      destroy(inst, target, actions)
    end
  end
end
local function spawn_water_ball(doer, inst, pos, offset)
  local range = 10
  local x, y, z = pos:Get()
  local projectile = SpawnPrefab("waterstreak_projectile")
  projectile.Transform:SetPosition(x, 5, z)

  local dx = offset.x
  local dz = offset.z
  local targetpos = pos + offset
  local rangesq = dx * dx + dz * dz
  local speed = easing.linear(rangesq, 15, 3, range * range)
  projectile.components.complexprojectile:SetHorizontalSpeed(speed)
  projectile.components.complexprojectile:SetGravity(-25)
  projectile.components.complexprojectile:Launch(targetpos, doer, inst)

end

local function create_water_explosion(inst, doer, position)
  local x, y, z = position:Get()
  local distsqinner = TUNING.GALLOP_BREAKER_AOE_RADIUS_INNER
  distsqinner = distsqinner * distsqinner
  -- Do gameplay effects.
  local ents = TheSim:FindEntities(x, y, z, TUNING.GALLOP_BREAKER_AOE_RADIUS,
                                   MUST_HAVE_SPELL_TAGS, CANT_HAVE_SPELL_TAGS,
                                   MUST_HAVE_ONE_OF_SPELL_TAGS)
  for _, v in ipairs(ents) do
    if v ~= inst and v ~= doer then
      do_water_explosion_effect(doer, inst, v, position,
                                v:GetDistanceSqToPoint(position) < distsqinner)
    end
  end
  -- create projectile
  -- local range = 10
  -- for i = 1, 20 do
  --  local offset = Point(UnitRand() * range, 0, UnitRand() * range)
  --  spawn_water_ball(doer, inst, position, offset)
  -- end
  -- spawn_water_ball(doer, inst, position, position)
  -- Spawn visual fx.
  local o = 2
  local offset = {
    Point(0, o, 0),
    Point(-o, 0, 0),
    Point(o, 0, 0),
    Point(0, -o, 0)
  }
  -- for _, off in ipairs(offset) do
  --  local fx = SpawnAt("crab_king_waterspout", position + off)
  --  fx.Transform:SetScale(2, 2, 2)
  -- end
  local fx = SpawnAt("crab_king_waterspout", position)
  fx.Transform:SetScale(2, 2, 2)
end
local BURN_MUST_TAGS = {"fire"}
local extinguish_radius = TUNING.GALLOP_BREAKER_AOE_RADIUS
local function StopBurning(pos)
  local x, y, z = pos:Get()
  local ents = TheSim:FindEntities(x, y, z, extinguish_radius, BURN_MUST_TAGS)
  for k, v in ipairs(ents) do
    if v.components.burnable and v.components.burnable:IsBurning() and
      not v.components.fueled then v.components.burnable:Extinguish() end
  end
end
local water_dist = TUNING.GALLOP_BREAKER_AOE_RADIUS
local function DoAOEAttack(inst, doer, pos)
  -- 三叉戟（小范围）
  create_water_explosion(inst, doer, pos)
  -- 理智值
  local s = doer.components.sanity
  if s then s:DoDelta(TUNING.GALLOP_BREAKER_AOE_SANITY) end
  -- 灭火
  StopBurning(pos)
  -- 浇水
  local x, y, z = pos:Get()
  SpawnAt("gallop_breaker_water", pos).components.wateryprotection:SpreadProtectionAtPoint(
    x, y, z, water_dist)
  -- cd
  inst.components.rechargeable:Discharge(TUNING.GALLOP_BREAKER_COOLDOWN)
  -- 特效
  local fx = SpawnAt("crabking_ring_fx", pos)
end
-- 每4次攻击，下次攻击触发重击
local function onreplacecombo(inst, data)
  local owner, target = data.owner, data.target
  OnRealAttack(inst, owner)
end
local function verifyplayer(inst, player) return player ~= GetEquipOwner(inst) end
local function playernear(inst, player)
  local owner = GetEquipOwner(inst)
  if owner then owner.canboard = false end
end

local function playerfar(inst)
  local owner = GetEquipOwner(inst)
  if owner then owner.canboard = true end
end
local function stroverridefn(inst, act)
  if act.action == ACTIONS.USEITEM then
    return STRINGS.ACTIONS[inst.prefab:upper()]
  elseif act.action == ACTIONS.CASTAOE then
    return STRINGS.ACTIONS.CASTAOE[inst.prefab:upper()]
  end
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
local function AddEfficiency(inst)
  if not inst.components.workmultiplier then
    inst:AddComponent("workmultiplier")
  end
  for k, v in pairs(actions) do
    local act = ACTIONS[v]
    if act then
      inst.components.workmultiplier:AddMultiplier(act,
                                                   TUNING.GALLOP_BREAKER_ACTION_MULTIPLIER,
                                                   inst)
    end
  end
end
local function RemoveEfficiency(inst)
  if inst.components.workmultiplier then
    for k, v in pairs(actions) do
      local act = ACTIONS[v]
      if act then
        inst.components.workmultiplier:RemoveMultiplier(act, inst)
      end
    end
  end
end
local function AddDamageTakenMultiplier(inst)
  if inst.components.inventory then
    inst.components.inventory.gallop_breaker_absorb = 0.8
  end
end
local function RemoveDamageTakenMultiplier(inst)
  if inst.components.inventory then
    inst.components.inventory.gallop_breaker_absorb = nil
  end
end
local fxname = "gallop_spawnfx"
local fxkey = "gallop_breaker_fx"
local function AddFX(inst)
  if not inst[fxkey] or not inst[fxkey]:IsValid() then
    local fx = SpawnPrefab(fxname)
    inst[fxkey] = fx
    inst:AddChild(fx)
  end
end
local function RemoveFX(inst)
  if inst[fxkey] then
    if inst[fxkey]:IsValid() then inst[fxkey]:Remove() end
    inst[fxkey] = nil
  end
end
local LEAVE = 0
local JOIN = 1
local function JoinParty(inst)
  if inst:IsValid() then
    AddEfficiency(inst)
    AddDamageTakenMultiplier(inst)
    AddFX(inst)
  end
end
local function LeaveParty(inst)
  if inst:IsValid() then
    RemoveEfficiency(inst)
    RemoveDamageTakenMultiplier(inst)
    RemoveFX(inst)
  end
end
local function DismissBoardingParty(inst)
  LeaveParty(inst)
  if inst.boardingparty then
    for ent, state in pairs(inst.boardingparty) do
      if state then
        LeaveParty(ent)
        inst.boardingparty[ent] = nil
      end
    end
  end
end
local function SummonBoardingParty(inst)
  if not inst.canboard then return DismissBoardingParty(inst) end
  JoinParty(inst)
  local party = inst.boardingparty
  local ents = inst.components.leader and inst.components.leader.followers or {}
  -- remove all old members
  for ent, state in pairs(party) do party[ent] = LEAVE end
  -- add new members
  for ent, _ in pairs(ents) do
    -- this member is new
    if not party[ent] and ent:IsNear(inst, TUNING.GALLOP_BREAKER_BOARDING_DIST) then
      party[ent] = JOIN
      JoinParty(ent)
    end
    -- this member is old
    if party[ent] == LEAVE and
      ent:IsNear(inst, TUNING.GALLOP_BREAKER_BOARDING_DIST) then
      party[ent] = JOIN
    end
  end
  -- remove members
  for ent, state in pairs(party) do
    if state == LEAVE then
      LeaveParty(ent)
      party[ent] = nil
    end
  end
end
local custom_fn = {
  boardingparty = {
    enable = function(comp, inst, self) common_fn.enable(comp, inst, self) end,
    disable = function(comp, inst, self) common_fn.disable(comp, inst, self) end,
    onequip = function(inst, owner)
      -- 自身和身边的雇佣单位效率提升至2倍，80%防御
      if owner.components.leader and owner.components.combat then
        owner.boardingparty = {}
        owner.canboard = true
        inst.components.gallop_playerprox:Schedule()
        owner.boardingtask = owner.boardingtask or
                               owner:DoPeriodicTask(1, SummonBoardingParty)
      end
    end,
    onunequip = function(inst, owner)
      inst.components.gallop_playerprox:Stop()
      owner.canboard = nil
      if owner.boardingtask then
        owner.boardingtask:Cancel()
        owner.boardingtask = nil
      end
      DismissBoardingParty(owner)
    end
  }
}
local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)

  inst.AnimState:SetBank("gallop_breaker")
  inst.AnimState:SetBuild("gallop_breaker")
  inst.AnimState:PlayAnimation("idle")

  inst:AddTag("sharp")
  inst:AddTag("play_strum")
  inst:AddTag("play_till_anim")

  -- tool (from tool component) added to pristine state for optimization
  inst:AddTag("tool")
  -- weapon (from weapon component) added to pristine state for optimization
  inst:AddTag("weapon")
  -- shadowlevel (from shadowlevel component) added to pristine state for optimization
  inst:AddTag("shadowlevel")

  inst:AddComponent("aoetargeting")
  SetupPoundAOE(inst)

  MakeInventoryFloatable(inst, "med", 0.05, {1.1, 0.8, 1.1}, true, -9, {
    sym_build = "gallop_breaker",
    sym_name = "swap_object"
  })

  inst._mode = net_bool(inst.GUID, "gallop_breaker.mode", "modedirty")
  inst._mode:set(false)
  inst.stroverridefn = stroverridefn

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then return inst end
  inst.PlayZombieSound = PlayZombieSound
  inst:ListenForEvent("modedirty", ToggleSound2)

  inst:AddComponent("weapon")
  inst.components.weapon:SetDamage(TUNING.GALLOP_BREAKER_DAMAGE)
  inst._weaponused_callback = function(owner, data)
    return onattack(inst, owner, data.target)
  end

  inst:AddComponent("farmtiller")

  SetupActions(inst)

  inst:AddComponent("inspectable")

  inst:AddComponent("inventoryitem")

  inst:AddComponent("equippable")
  inst.components.equippable:SetOnEquip(onequip)
  inst.components.equippable:SetOnUnequip(onunequip)
  inst.components.equippable.walkspeedmult = TUNING.GALLOP_BREAKER_SPEED_MULT
  inst:ListenForEvent("equipped", setequip)
  inst:ListenForEvent("unequipped", setequip)
  inst.Boom = TryBoom
  inst.OnNewState = OnNewState

  inst:AddComponent("gallop_playerprox")
  inst.components.gallop_playerprox:SetDist(TUNING.GALLOP_BREAKER_BOARDING_DIST,
                                            TUNING.GALLOP_BREAKER_BOARDING_DIST)
  inst.components.gallop_playerprox:SetOnPlayerNear(playernear)
  inst.components.gallop_playerprox:SetOnPlayerFar(playerfar)
  inst.components.gallop_playerprox.verifyplayer = function(player)
    return verifyplayer(inst, player)
  end
  -- shadowlevel
  -- in gallop_main.lua

  inst:AddComponent("useableitem")
  inst.components.useableitem:SetOnUseFn(onuse)
  inst.components.useableitem:SetOnStopUseFn(onstopuse)
  inst.components.useableitem.inuse = false

  inst:AddComponent("rechargeable")
  inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
  inst.components.rechargeable:SetOnChargedFn(OnCharged)
  inst.components.rechargeable:SetMaxCharge(TUNING.GALLOP_BREAKER_COOLDOWN)

  inst:AddComponent("aoespell")
  inst.components.aoespell:SetSpellFn(DoAOEAttack)

  inst:AddComponent("gallop_multifeat")
  inst.components.gallop_multifeat:AddFeatures(custom_fn)
  inst.components.gallop_multifeat:EnableAllFeatures()

  inst:AddComponent("gallop_combo")
  inst.components.gallop_combo.max = 4
  inst:ListenForEvent("gallop_replace_combo", onreplacecombo)

  MakeHauntableLaunch(inst)

  inst.OnLoad = onload
  inst.OnSave = onsave

  return inst
end
local function DoWater(inst, x, z)
  if TheWorld.components.farming_manager ~= nil then
    TheWorld.components.farming_manager:AddSoilMoistureAtPoint(x, 0, z, 100)
  end
end
local function OnWater(inst, x, y, z)
  for i = 2, 16, 2 do
    for j = 2, 16, 2 do
      local ox, oz = i, j
      local tx, tz = x + ox, z + oz
      DoWater(inst, tx, tz)
      ox, oz = -i, j
      tx, tz = x + ox, z + oz
      DoWater(inst, tx, tz)
      ox, oz = i, -j
      tx, tz = x + ox, z + oz
      DoWater(inst, tx, tz)
      ox, oz = -i, -j
      tx, tz = x + ox, z + oz
      DoWater(inst, tx, tz)
    end
  end
end
local function fn_water()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst:AddTag("NOCLICK")
  inst:AddTag("NOBLOCK")
  inst.persists = false

  inst:AddComponent("wateryprotection")

  inst.components.wateryprotection.witherprotectiontime = 1
  inst.components.wateryprotection:AddIgnoreTag("player")
  inst.components.wateryprotection.temperaturereduction = 1
  inst.components.wateryprotection.addcoldness = 0
  inst.components.wateryprotection.addwetness = 100
  inst.components.wateryprotection.applywetnesstoitems = true
  inst.components.wateryprotection.extinguish = true
  inst.components.wateryprotection.extinguishheatpercent = 1
  inst.components.wateryprotection.onspreadprotectionfn = OnWater
  return inst
end
return Prefab("gallop_breaker", fn, assets, prefabs),
       Prefab("gallop_breaker_water", fn_water)
