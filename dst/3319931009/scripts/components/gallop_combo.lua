local combo = Class(function(self, inst)
  self.inst = inst
  self.current = 0
  self.max = 3
  self.maxtime = 10
  self:Init()
end)
local function onequip(self, inst, data)
  local owner = data and data.owner
  if owner and owner:IsValid() and owner.components.combat then
    owner:ListenForEvent("onattackother", self.onattack)
  end
end
local function onunequip(self, inst, data)
  local owner = data and data.owner
  if owner then owner:RemoveEventCallback("onattackother", self.onattack) end
  if owner and self.preparefn then
    owner:RemoveEventCallback("newstate", self.preparefn)
  end
  self.preparefn = nil
end
function combo:OnAttack(owner, data)
  local target = data and data.target
  if owner and target then
    if self:Depleted() then return end
    if not self:IsAttacking() then
      self:FirstAttack()
      return
    end
    self:DoAttack(owner, target)
  end
end
function combo:DoAttack(owner, target)
  self.current = self.current + 1
  self.lastattacktime = self.time
  self.time = GetTime()
  if self.current <= self.max then return end
  if self.oncombo then self.oncombo(self.inst, owner, target) end
  self.inst:PushEvent("gallop_combo", {owner = owner, target = target})
  self:Reset()
  self:PrepareComboAttack(owner)
end
function combo:Reset() self.current = 0 end
function combo:CanReplaceCombo(owner)
  return not (owner.components.health:IsDead() or
           owner.sg:HasStateTag("sleeping") or
           (owner.components.freezable ~= nil and
             owner.components.freezable:IsFrozen()) or
           (owner.components.pinnable ~= nil and
             owner.components.pinnable:IsStuck()))
end
-- substitute next normal attack with combo attack
function combo:PrepareComboAttack(owner)
  local function fn(inst, data)
    if data and data.statename == "attack" then
      if inst:IsValid() and self:CanReplaceCombo(owner) then
        owner:RemoveEventCallback("newstate", fn)
        self:ReplaceWithComboAttack(owner)
        self.preparefn = nil
      end
    end
  end
  if not self.preparefn then
    owner:ListenForEvent("newstate", fn)
    self.preparefn = fn
  end
end
function combo:GetTarget(owner)
  local target
  if owner.components.combat then
    target = target or owner.components.combat.target
  end
  local ba = owner:GetBufferedAction()
  if ba and not target then target = target or ba.target end
  return target
end
function combo:ReplaceWithComboAttack(owner)
  self.inst:PushEvent("gallop_replace_combo",
                      {owner = owner, target = self:GetTarget(owner)})
end
local cant_tags = {"depleted", "usesdepleted"}
function combo:Depleted() return self.inst:HasOneOfTags(cant_tags) end
function combo:Init()
  self.onequip = function(...) onequip(self, ...) end
  self.onunequip = function(...) onunequip(self, ...) end
  self.onattack = function(...) return self:OnAttack(...) end
  self.inst:ListenForEvent("equipped", self.onequip)
  self.inst:ListenForEvent("unequipped", self.onunequip)
end
function combo:OnRemoveFromEntity()
  local owner = self.inst.components.inventoryitem.owner
  if owner then self.onunequip(self.inst, {owner = owner}) end
  self.inst:RemoveEventCallback("equipped", self.onequip)
  self.inst:RemoveEventCallback("unequipped", self.onunequip)
end
function combo:IsAttacking()
  return self.lastattacktime and (GetTime() - self.lastattacktime) <
           self.maxtime
end
function combo:FirstAttack()
  self.current = 1
  self.time = GetTime()
  self.lastattacktime = self.time
end
function combo:Trace()
  for k, v in pairs(combo) do
    if type(v) == "function" then
      local old = v
      combo[k] = function(self, ...)
        local ret = {old(self, ...)}
        return unpack(ret)
      end
    end
  end
end
return combo
