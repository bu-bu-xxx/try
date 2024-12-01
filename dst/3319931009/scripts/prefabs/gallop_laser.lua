local assets = {
  Asset("ANIM", "anim/gallop_laser_ring_fx.zip")
  -- Asset("ANIM", "anim/gallop_laser_explosion.zip")
}

local prefabs = {}

local function scorchfn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  inst.AnimState:SetBuild("gallop_laser_ring_fx")
  inst.AnimState:SetBank("gallop_laser_ring_fx")
  inst.AnimState:PlayAnimation("idle")
  inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
  inst.AnimState:SetLayer(LAYER_BACKGROUND)
  inst.AnimState:SetSortOrder(3)
  inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

  inst:AddTag("NOCLICK")
  inst:AddTag("NOBLOCK")
  inst:AddTag("FX")
  inst:AddTag("laser")
  inst.Transform:SetRotation(math.random() * 360)

  inst.entity:SetPristine()
  if not TheWorld.ismastersim then return inst end
  inst.persists = false

  inst:ListenForEvent("animover", inst.Remove)
  return inst
end
local spellcast_assets = {Asset("ANIM", "anim/hf_spellcast_fx.zip")}
local function spellcast_fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()
  inst.entity:SetCanSleep(false)

  inst.AnimState:SetBuild("hf_spellcast_fx")
  inst.AnimState:SetBank("hf_spellcast_fx")
  inst.AnimState:PlayAnimation("slowcast") -- spellcast
  inst.AnimState:SetFinalOffset(-5)
  inst.Transform:SetScale(1.5, 1.5, 1.5)

  inst:AddTag("NOCLICK")
  inst:AddTag("NOBLOCK")
  inst:AddTag("FX")
  inst.entity:SetPristine()
  if not TheWorld.ismastersim then return inst end

  inst.persists = false
  inst:ListenForEvent("animover", inst.Remove)

  return inst
end
local function spellcast() end

return Prefab("gallop_laser_ring", scorchfn, assets, prefabs),
       Prefab("gallop_spellcast_fx", spellcast_fn, spellcast_assets, prefabs)
