local function FindPlayer(x, y, z, radius, alive, fn)
  local ents = TheSim:FindEntities(x, y, z, radius, {"player"},
                                   alive and {"playerghost"} or nil)
  for i, v in ipairs(ents) do if not fn or fn(v) then return v end end
end
local function AnyPlayer(inst, self)
  local x, y, z = inst.Transform:GetWorldPosition()
  local player = FindPlayer(x, y, z, self.near, self.alivemode,
                              self.verifyplayer)
  if not self.isclose then
    if player ~= nil then -- changed
      self.isclose = true
      if self.onnear ~= nil then self.onnear(inst, player) end
    end
  elseif not player then
    self.isclose = false
    if self.onfar ~= nil then self.onfar(inst) end
  end
end
local PlayerProx = Class(function(self, inst)
  self.inst = inst
  self.near = 2
  self.far = 3
  self.isclose = false
  self.period = 1
  self.onnear = nil
  self.onfar = nil
  self.task = nil
  self.target = nil
  self.losttargetfn = nil
  self.verifyplayer = function(player) return true end
  self.alivemode = nil
  self.closeplayers = {}
  self.targetmode = AnyPlayer
end)
function PlayerProx:SetOnPlayerNear(fn) self.onnear = fn end

function PlayerProx:SetOnPlayerFar(fn) self.onfar = fn end

function PlayerProx:IsPlayerClose() return self.isclose end

function PlayerProx:SetDist(near, far)
  self.near = near
  self.far = far
end
function PlayerProx:Schedule(new_period)
  if new_period ~= nil then self.period = new_period end
  self:Stop()
  self.task = self.inst:DoPeriodicTask(self.period, self.targetmode, nil, self)
end

function PlayerProx:ForceUpdate()
  if self.task ~= nil and self.targetmode ~= nil then
    self.targetmode(self.inst, self)
  end
end

function PlayerProx:Stop()
  if self.task ~= nil then
    self.task:Cancel()
    self.task = nil
  end
end

function PlayerProx:OnEntitySleep()
  self:ForceUpdate()
  self:Stop()
end

PlayerProx.OnRemoveEntity = PlayerProx.Stop
PlayerProx.OnRemoveFromEntity = PlayerProx.Stop

return PlayerProx
