local added = {}
local function InsertLoot(loottable, loots)
  for i, v in ipairs(loots) do table.insert(loottable, v) end
end
local function InsertChanceLoot(lootdropper, loots)
  for i, v in ipairs(loots) do lootdropper:AddChanceLoot(unpack(v)) end
end
local function AddLoot(loots)
  return function(inst)
    -- prefab post init
    local hash = inst.prefab
    if added[hash] then return end
    local LootTables = rawget(_G, "LootTables")
    local loottable = LootTables and LootTables[inst.prefab]
    if loottable then
      added[hash] = true
      InsertLoot(loottable, loots)
    else
      print("Error finding loottable for inst", inst, inst.prefab)
    end
  end
end
local function AddChanceLoot(loots)
  return function(inst)
    -- prefab post init
    local lootdropper = inst.components.lootdropper
    if not lootdropper then return end
    InsertChanceLoot(lootdropper, loots)
  end
end
local function AppendLoot(lootdropper, loots)
  local GenerateLoot = lootdropper.GenerateLoot
  function lootdropper:GenerateLoot(...)
    local loot = GenerateLoot(self, ...)
    loot = loot or {}
    for i, v in ipairs(loots) do
      -- c_announce("插入" .. v[2] .. "个" .. v[1])
      for j = 1, v[2] do table.insert(loot, v[1]) end
    end
    return loot
  end
end
local function AddLootDuringCombat(loots, cb)
  local function fn(inst, data)
    if cb(inst, data) then
      local lootdropper = inst.components.lootdropper
      if not lootdropper then return end
      AppendLoot(lootdropper, loots)
      inst:RemoveEventCallback("attacked", fn)
    end
  end
  return function(inst)
    -- prefab post init
    inst:ListenForEvent("attacked", fn)
  end
end
return {
  AddLoot = AddLoot,
  AddChanceLoot = AddChanceLoot,
  AddLootDuringCombat = AddLootDuringCombat
}
