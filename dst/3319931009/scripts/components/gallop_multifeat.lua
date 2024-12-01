local MultiFeat = Class(function(self, inst)
  self.inst = inst
  self.features = {}
  self.enabled = {}
  self.modifiers = {}
end)

function MultiFeat:OnRemoveFromEntity() self:DisableAllFeatures() end
function MultiFeat:AddFeature(data, override)
  if self:HasFeature(data.name) and not override then return end
  self.features[data.name] = data
  if data.modifier then self.modifiers[data.name] = {} end
end
function MultiFeat:AddFeatures(data, override)
  if type(data[1]) == "table" then
    for i, v in ipairs(data) do self:AddFeature(data, override) end
  else
    for k, v in pairs(data) do
      v.name = v.name or k
      self:AddFeature(v, override)
    end
  end
end
function MultiFeat:RemoveFeature(name)
  if type(name) == "string" then
    if self:HasFeature(name) then
      self:Disable(name)
      self.features[name] = nil
    end
  elseif type(name) == "table" then
    return self:RemoveFeature(name.name)
  end
end
function MultiFeat:HasFeature(name)
  if name == nil then return false end
  return self.features[name]
end
MultiFeat.Has = MultiFeat.HasFeature
function MultiFeat:IsEnabled(name)
  if name == nil then return false end
  return self.enabled[name] == true
end
function MultiFeat:_Enable(name)
  local data = self.features[name]
  if data.enable then data.enable(self, self.inst, data) end
  self.enabled[name] = true
  self.inst:PushEvent("multifeature_enable", name)
end
function MultiFeat:Enable(name, source)
  if not self:HasFeature(name) then return false end
  if self:IsEnabled(name) then return true end
  if self.modifiers[name] then
    -- this is a modifier
    self:SetModifier(name, source, true)
    if self:GetModifier(name) then self:_Enable(name) end
  else
    self:_Enable(name)
  end
  return true
end
function MultiFeat:SetModifier(name, source, b)
  self.modifiers[name] = self.modifiers[name] or {}
  if source == nil then source = self.inst end
  self.modifiers[name][source] = b
end
function MultiFeat:GetModifier(name)
  if not self.modifiers[name] then return false end
  for k, v in pairs(self.modifiers[name]) do if v then return true end end
  return false
end
MultiFeat.EnableFeature = MultiFeat.Enable
function MultiFeat:Disable(name, source)
  if not self:HasFeature(name) then return false end
  if not self:IsEnabled(name) then return true end
  if source then
    -- this is a modifier
    self:SetModifier(name, source, false)
    if not self:GetModifier(name) then self:_Disable(name) end
  else
    self:_Disable(name)
  end
  return true
end
MultiFeat.DisableFeature = MultiFeat.Disable
function MultiFeat:_Disable(name)
  local data = self.features[name]
  if data.disable then data.disable(self, self.inst, data) end
  self.enabled[name] = false
  self.inst:PushEvent("multifeature_disable", name)
end
function MultiFeat:GetData(name)
  if name == nil then return nil end
  return self.features[name]
end
function MultiFeat:DisableAllFeatures()
  for feature, _ in pairs(self.enabled) do self:Disable(feature) end
end
function MultiFeat:EnableAllFeatures()
  for feature, _ in pairs(self.features) do self:Enable(feature) end
end
-- function MultiFeat:OnSave()
--  local data = table.getkeys(self.enabled)
--  if next(data) then return {enabled = data} end
-- end
-- function MultiFeat:OnLoad(data)
--  if data and data.enabled then
--    for _, v in pairs(data.enabled) do self:Enable(v) end
--  end
-- end
function MultiFeat:ForEachEnabled(fn)
  if not fn then return end
  for name, _ in pairs(self.enabled) do
    local data = self.features[name]
    if data then fn(name, data) end
  end
end
function MultiFeat:ForEach(fn)
  if not fn then return end
  for name, data in pairs(self.features) do if data then fn(name, data) end end
end
function MultiFeat:ForEachDisabled(fn)
  if not fn then return end
  for name, data in pairs(self.features) do
    if not self:IsEnabled(name) and data then fn(name, data) end
  end
end
return MultiFeat
