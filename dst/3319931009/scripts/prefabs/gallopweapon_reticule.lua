local s = 2
local s2 = 1.3 / s
local doubles = 1 / s2
local SCALE = 1.5
local function MakePing(anim, s, mult, add, duration)
  local inst = CreateEntity()

  inst:AddTag("FX")
  inst:AddTag("NOCLICK")
  --[[Non-networked entity]]
  inst.entity:SetCanSleep(false)
  inst.persists = false

  inst.entity:AddTransform()
  inst.entity:AddAnimState()

  inst.AnimState:SetBank("reticuleaoe")
  inst.AnimState:SetBuild("reticuleaoe")
  inst.AnimState:PlayAnimation(anim)
  inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGroundFixed)
  inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
  inst.AnimState:SetSortOrder(3)
  inst.AnimState:SetScale(SCALE, SCALE)
  inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

  if s then inst.Transform:SetScale(s, s, s) end
  inst:AddComponent("colourtweener")
  if mult then inst.AnimState:SetMultColour(unpack(mult)) end
  if add then inst.AnimState:SetAddColor(unpack(add)) end

  mult = {inst.AnimState:GetMultColour()}
  mult[4] = 0
  inst.components.colourtweener:StartTween(mult, duration or .5)
  inst:ListenForEvent("colourtweener_end", inst.Remove)

  return inst
end
local breaker_colour = {91 / 255, 172 / 255, 216 / 355, 1}
local s3 = 1.1
local prefs = {
  Prefab("gallop_reticule_bloodaxe", function()
    local inst = Prefabs.reticuleaoe.fn()
    inst.Transform:SetScale(s3, s3, s3)
    return inst
  end, nil, {"reticuleaoe"}), Prefab("gallop_reticule_bloodaxeping", function()
    local inst = MakePing("idle", s3)
    return inst
  end), Prefab("gallop_reticuleaoe", function()
    local inst = Prefabs.reticuleaoe.fn()
    local inst2 = Prefabs.reticuleaoe.fn()
    inst:AddChild(inst2)
    inst.Transform:SetScale(1, 1, 1)
    inst.AnimState:SetMultColour(unpack(breaker_colour))
    inst2.Transform:SetScale(doubles, doubles, doubles)
    if inst.children then
      for k, v in pairs(inst.children) do
        if v then k.AnimState:SetMultColour(unpack(breaker_colour)) end
      end
    end
    return inst
  end, nil, {"reticuleaoe"}), Prefab("gallop_reticuleaoeping", function()
    local inst = MakePing("idle", 1, breaker_colour)
    local inst2 = MakePing("idle", doubles, breaker_colour)
    inst:AddChild(inst2)
    return inst
  end)
}
return unpack(prefs)
