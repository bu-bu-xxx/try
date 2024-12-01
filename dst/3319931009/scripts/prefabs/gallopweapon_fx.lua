local function GroundOrientation(inst)
  inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
  inst.AnimState:SetLayer(LAYER_BACKGROUND)
end
local fxs = {
  {
    name = "gallop_spawnfx",
    bank = "spawnprotectionbuff",
    build = "spawnprotectionbuff",
    anim = "buff_pre",
    persists = true,
    fn = function(inst)
      inst:AddTag("DECOR") -- "FX" will catch mouseover
      inst:AddTag("NOCLICK")
      GroundOrientation(inst)
      inst.AnimState:PlayAnimation("buff_pre")
      inst.AnimState:PushAnimation("buff_idle")
      inst.AnimState:SetMultColour(1, 1, 1, 0.25)
    end
  },{
    name = "gallop_impact_fx",
    bank = "deer_ice_circle",
    build = "deer_ice_circle",
    anim = {"impact", "pst"},

    fn = function(inst)
      GroundOrientation(inst)
      inst.AnimState:SetSortOrder(3)
      local s = 1
      inst.AnimState:SetScale(s, s)
    end
  }
}
local function PlaySound(inst, sound) inst.SoundEmitter:PlaySound(sound) end

local function MakeFx(t)
  local assets = {Asset("ANIM", "anim/" .. t.build .. ".zip")}

  local function startfx(proxy)
    -- print ("SPAWN", debugstack())
    local inst = CreateEntity(t.name)
    proxy.subfx = inst

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    local parent = proxy.entity:GetParent()
    if parent ~= nil then inst.entity:SetParent(parent.entity) end

    if t.nameoverride == nil and t.description == nil then inst:AddTag("FX") end
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false
    if t.network then
      inst.entity:SetParent(proxy.entity)
    else
      inst.Transform:SetFromProxy(proxy.GUID)
    end

    if t.autorotate and parent ~= nil then
      inst.Transform:SetRotation(parent.Transform:GetRotation())
    end

    if t.sound ~= nil then
      inst.entity:AddSoundEmitter()
      if t.update_while_paused then
        inst:DoStaticTaskInTime(t.sounddelay or 0, PlaySound, t.sound)
      else
        inst:DoTaskInTime(t.sounddelay or 0, PlaySound, t.sound)
      end
    end

    if t.sound2 ~= nil then
      if inst.SoundEmitter == nil then inst.entity:AddSoundEmitter() end
      if t.update_while_paused then
        inst:DoStaticTaskInTime(t.sounddelay2 or 0, PlaySound, t.sound2)
      else
        inst:DoTaskInTime(t.sounddelay2 or 0, PlaySound, t.sound2)
      end
    end

    inst.AnimState:SetBank(t.bank)
    inst.AnimState:SetBuild(t.build)
    if type(t.anim) == "table" then
      local first = false
      for i, v in ipairs(t.anim) do
        local func = first and "PlayAnimation" or "PushAnimation"
        local param2 = first and t.persists or nil
        first = true
        inst.AnimState[func](inst.AnimState, FunctionOrValue(v), param2) -- THIS IS A CLIENT SIDE FUNCTION
      end
    else
      inst.AnimState:PlayAnimation(FunctionOrValue(t.anim), t.persists) -- THIS IS A CLIENT SIDE FUNCTION
    end
    if t.update_while_paused then inst.AnimState:AnimateWhilePaused(true) end
    if t.tint ~= nil then
      inst.AnimState:SetMultColour(t.tint.x, t.tint.y, t.tint.z,
                                   t.tintalpha or 1)
    elseif t.tintalpha ~= nil then
      inst.AnimState:SetMultColour(1, 1, 1, t.tintalpha)
    end
    -- print(inst.AnimState:GetMultColour())
    if t.transform ~= nil then inst.AnimState:SetScale(t.transform:Get()) end

    if t.nameoverride ~= nil then
      if inst.components.inspectable == nil then
        inst:AddComponent("inspectable")
      end
      inst.components.inspectable.nameoverride = t.nameoverride
      inst.name = t.nameoverride
    end

    if t.description ~= nil then
      if inst.components.inspectable == nil then
        inst:AddComponent("inspectable")
      end
      inst.components.inspectable.descriptionfn = t.description
    end

    if t.bloom then inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh") end

    if t.animqueue or type(t.anim) == "table" then
      inst:ListenForEvent("animqueueover", inst.Remove)
    elseif not t.persists then
      inst:ListenForEvent("animover", inst.Remove)
    end

    if t.fn ~= nil then
      if t.fntime ~= nil then
        if t.update_while_paused then
          inst:DoStaticTaskInTime(t.fntime, t.fn)
        else
          inst:DoTaskInTime(t.fntime, t.fn)
        end
      else
        t.fn(inst)
      end
    end

    if TheWorld then TheWorld:PushEvent("fx_spawned", inst) end
  end

  local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:AddFollower()
    if t.network then
    else
      -- Dedicated server does not need to spawn the local fx
      if not TheNet:IsDedicated() then
        -- Delay one frame so that we are positioned properly before starting the effect
        -- or in case we are about to be removed
        if t.update_while_paused then
          inst:DoStaticTaskInTime(0, startfx, inst)
        else
          inst:DoTaskInTime(0, startfx, inst)
        end
      end
    end

    if t.twofaced then
      inst.Transform:SetTwoFaced()
    elseif t.eightfaced then
      inst.Transform:SetEightFaced()
    elseif t.sixfaced then
      inst.Transform:SetSixFaced()
    elseif not t.nofaced then
      inst.Transform:SetFourFaced()
    end

    inst:AddTag("FX")
    if t.persists then
      -- manual remove irrelevant fx
      inst:ListenForEvent("onremove", function()
        if inst.subfx and inst.subfx:IsValid() and inst ~=
          inst.subfx.entity:GetParent() then inst.subfx:Remove() end
      end)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    if t.network then
      startfx(inst)
    else
    end
    if t.persists then
    else
      inst:DoTaskInTime(1, inst.Remove)
    end
    inst.persists = false

    return inst
  end

  return Prefab(t.name, fn, assets)
end

local prefs = {}

for k, v in pairs(fxs) do table.insert(prefs, MakeFx(v)) end

return unpack(prefs)
