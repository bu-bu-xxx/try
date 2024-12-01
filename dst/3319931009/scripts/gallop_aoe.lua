local aoe_cant_tags = {
  "playerghost", "INLIMBO", "FX", "NOCLICK", "DECOR", "notarget", "noattack",
  "structure", "wall", "boat", "invincible", "invisible", "spawnprotection"
}
local aoe_must_tags = {"_health"}
local benign_tags = {"companion", "friendlyfruitfly", "lightflier", "glommer"}
local hate_tags = {"hostile", "epic"}
local monstertags = {"monster", "playermonster"}
local pvp = TheNet:GetPVPEnabled()
if not pvp then
  table.insert(aoe_cant_tags, "player")
  table.insert(aoe_cant_tags, "domesticated")
end
local launch_must_tags = {"_inventoryitem"}
local launch_cant_tags = {
  "playerghost", "INLIMBO", "FX", "NOCLICK", "DECOR", "structure", "wall",
  "boat"
}
local function CanAOEAttack(doer, target)
  -- 自己
  if doer == target then return false end
  -- 死亡或消失
  if not (target and target:IsValid() and target.entity:IsVisible()) then
    return false
  end
  -- 战斗或者生命值
  if IsEntityDeadOrGhost(target, true) and not target.components.combat then
    return false
  end
  -- 标签
  if target:HasOneOfTags(aoe_cant_tags) then return false end
  if not target:HasTags(aoe_must_tags) then return false end
  -- if not target:HasOneOfTags(aoe_oneof_tags) then return false end
  -- 官方接口
  if not doer.components.combat:IsValidTarget(target) then return false end
  -- 敌对
  if target.components.combat and target.components.combat:TargetIs(doer) then
    return true
  end
  -- 温顺的
  local benign = target:HasOneOfTags(benign_tags)
  if benign then return false end
  -- 随从
  local follower = target.replica.follower
  local leader = follower and follower:GetLeader()
  if leader then
    if leader == doer then return false end
    -- 间接随从（跟随物品或者其他人）
    while leader.components.inventoryitem and
      leader.components.inventoryitem.owner do
      leader = leader.components.inventoryitem.owner
    end
    if leader == doer then return false end
    if leader.components.combat then
      local indirect_attack = CanAOEAttack(doer, leader)
      if not indirect_attack then return false end
    end
  end
  -- 牛牛，要求有一定的驯化度
  local domesticated = target.components.domesticatable and
                         (target.components.domesticatable.domestication or 0) >
                         0.2
  if domesticated then return false end
  -- 可恶的东西
  if target:HasOneOfTags(hate_tags) then return true end
  -- 魔鬼检测
  if doer:HasOneOfTags(monstertags) ~= target:HasOneOfTags(monstertags) then
    return true
  end
  return true
end
local function canattack(params, target)
  return params.target ~= target and CanAOEAttack(params.doer, target)
end
local function Destroy(inst, target, actions, postfn)
  if not target:IsValid() or not target.components.workable then return end
  if not actions then actions = {target.components.workable:GetWorkAction()} end
  if actions[1] and type(actions[1]) == "table" then
    local a = {}
    for i, v in ipairs(actions) do table.insert(a, v.id) end
    actions = a
  end
  -- multiple times
  for i = 1, 10 do
    if target:IsValid() and target.components.workable and
      target.components.workable:CanBeWorked() then
      local action = target.components.workable:GetWorkAction()
      if action and table.contains(actions, action.id) then
        target.components.workable:Destroy(inst)
      else
        break
      end
    else
      break
    end
  end
  if postfn then postfn(inst, target, actions) end
end
local function CanDestroy(target, actions)
  if not target:IsValid() or not target.components.workable or
    not target.components.workable:CanBeWorked() then return end
  if not actions then actions = {target.components.workable:GetWorkAction()} end
  if actions[1] and type(actions[1]) == "table" then
    local a = {}
    for i, v in ipairs(actions) do table.insert(a, v.id) end
    actions = a
  end
  local action = target.components.workable:GetWorkAction()
  if action and table.contains(actions, action.id) then return true end
  return false
end
--[[
  doer - attacker/owner       the player who is attacking
  inst - weapon               the weapon used
  target                      the single target that is in combat, will ignore by default
  damage                      fixed damage
  damagemult                  an instancemultiplier applied to damage
  radius
  must_tags
  cant_tags
  oneof_tags
  onattack                    called when acutally attacked
  canattack                   called to check ability to attack
]]
local function Attack(params)
  local iselec = false
  local stimuli = iselec and "electric" or nil
  local spdamage = nil -- special damage {}
  local x, y, z = params.position:Get()
  local ents = TheSim:FindEntities(x, y, z, params.radius, params.must_tags,
                                   params.cant_tags, params.oneof_tags) or {}
  local count = 0
  for i, v in ipairs(ents) do
    if params.canattack(params, v) then
      local dmg = FunctionOrValue(params.damage, params, v) or
                    params.doer.components.combat:CalcDamage(v, params.inst)
      dmg = dmg * FunctionOrValue(params.damagemult, params, v)
      count = count + 1
      params.doer:PushEvent("onareaattackother", {
        target = v,
        weapon = params.inst,
        stimuli = stimuli,
        damage = dmg
      })
      if params.onpreattack then params.onpreattack(params, v, dmg) end
      if v.components.combat then
        v.components.combat:GetAttacked(params.doer, dmg, params.inst, stimuli,
                                        spdamage)
      elseif v.components.health then
        v.components.health:DoDelta(-dmg)
      else
        print(params.doer, params.inst, "try to attack", v)
        dumptable(v, 1, 2)
      end
      if params.onattack then params.onattack(params, v) end
    end
  end
  if params.postattack then params.postattack(params, count) end
end
local SPEED = 3 -- 击飞速度
local Y_SPEED = 8 -- y轴初速度
local X_RATIO = 1 -- x轴比例
local Z_RATIO = 1 -- z轴比例
local DEGREES = DEGREES
local INITIAL_HEIGHT = .1
local function launch_away(inst, position, speed, yspeed, height)
  height = height or INITIAL_HEIGHT
  speed = speed or SPEED
  yspeed = yspeed or Y_SPEED
  local ix, iy, iz = inst.Transform:GetWorldPosition()
  inst.Physics:Teleport(ix, iy + height, iz)
  local px, py, pz = position:Get()
  local angle = (180 - inst:GetAngleToPoint(px, py, pz)) * DEGREES
  local sina, cosa = math.sin(angle), math.cos(angle)
  inst.Physics:SetVel(X_RATIO * speed * cosa, yspeed + speed,
                      Z_RATIO * speed * sina)
  inst.components.inventoryitem:SetLanded(false, true)
end
local masks = {}
local thread = nil
local function wait_for_launch()
  while next(masks) do
    for k, v in pairs(masks) do
      local ent = Ents[k]
      if ent then
        local x, y, z = ent.Transform:GetWorldPosition()
        if y > 1e-3 then
        else
          ent.Physics:SetCollisionMask(v)
          masks[k] = nil
        end
      else
        masks[k] = nil
      end
    end
    Sleep(FRAMES)
  end
  thread = nil
end
--[[
  height                      initial height to add to
  speed                       vertical and horizontal speed distributed by angle
  yspeed                      vertical speed added to speed
  position                    the source of the force to push items away to calculate an angle
  radius
  must_tags
  cant_tags
  oneof_tags
  onlaunch                    called when acutally launched
  canlaunch                   called to check ability to launch
]]
local function launch_single(params, inst)
  if inst and inst:IsValid() and inst.components.inventoryitem and inst.Physics then
  else
    return
  end
  launch_away(inst, FunctionOrValue(params.position, params, inst),
              FunctionOrValue(params.speed, params, inst),
              FunctionOrValue(params.yspeed, params, inst),
              FunctionOrValue(params.height, params, inst))
  if params.passthrough then
    masks[inst.GUID] = masks[inst.GUID] or inst.Physics:GetCollisionMask()
    inst.Physics:SetCollisionMask(COLLISION.GROUND)
  end
  if params.onlaunch then params.onlaunch(params, inst) end
end
local function Launch(params)
  local inst = params.inst
  local x, y, z = inst.Transform:GetWorldPosition()
  local ents = TheSim:FindEntities(x, y, z, params.radius, params.must_tags,
                                   params.cant_tags, params.oneof_tags) or {}
  local count = 0
  for i, v in ipairs(ents) do
    if params.canlaunch(params, v) then
      count = count + 1
      launch_single(params, v)
    end
  end
  if params.passthrough then thread = thread or StartThread(wait_for_launch) end
  if params.postlaunch then params.postlaunch(params, count) end
end
local function canlaunch(params) return true end
local function processparams_launch(params)
  if type(params) ~= "table" then return false end
  local p = {
    radius = params.radius or 5,
    inst = params.inst or params.doer or params.weapon,
    position = params.position or params.pos,
    must_tags = params.must_tags or launch_must_tags,
    cant_tags = params.cant_tags or launch_cant_tags,
    oneof_tags = params.oneof_tags or nil,
    passthrough = params.passthrough,
    onlaunch = params.onlaunch,
    canlaunch = params.canlaunch or canlaunch,
    postlaunch = params.postlaunch,
    height = params.height or INITIAL_HEIGHT,
    yspeed = params.yspeed or Y_SPEED,
    speed = params.speed or SPEED
  }
  p.position = p.position or (p.inst and p.inst:GetPosition())
  return p
end
local function processparams_attack(params)
  if type(params) ~= "table" then return false end
  local p = {
    inst = params.weapon or params.inst,
    doer = params.doer or params.attacker or params.owner,
    target = params.target,
    position = params.position or params.pos or nil,
    radius = params.radius or 5,
    damage = params.damage or params.dmg,
    damagemult = params.damagemult or 1,
    must_tags = params.must_tags or aoe_must_tags,
    cant_tags = params.cant_tags or aoe_cant_tags,
    oneof_tags = params.oneof_tags or nil,
    onattack = params.onattack,
    canattack = params.canattack or canattack,
    postattack = params.postattack
  }
  p.position = p.position or
                 ((p.inst or p.doer) and (p.inst or p.doer):GetPosition())
  return p
end
local function attack(params)
  params = processparams_attack(params)
  if params then return Attack(params) end
end
local function launch(params)
  params = processparams_launch(params)
  if params then return Launch(params) end
end
return {
  can = CanAOEAttack,
  destroy = Destroy,
  candestroy = CanDestroy,
  attack = attack,
  _canattack = canattack,
  launch = launch,
  launch_single = launch_single,
  params_launch = processparams_launch,
  params_attack = processparams_attack,
  _masks = masks,
  aoe_cant_tags = aoe_cant_tags,
  aoe_must_tags = aoe_must_tags
}
