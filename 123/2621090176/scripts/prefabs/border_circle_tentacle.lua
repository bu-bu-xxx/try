local assets = {
    Asset("ANIM", "anim/border_circle.zip"),
}

local scale = {near = {0.85, 1.45, 0.85}, far = {0.65, 1.25, 0.65}, cave = {1, 1.8, 1}}

local function fn_tentacle()
    local inst = CreateEntity()
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.persists = false
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.AnimState:SetBank("border_circle")
    inst.AnimState:SetBuild("border_circle")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetMultColour(0, 0, 0, 0.9) --1 makes the circle jagged
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGroundFixed)
    inst.AnimState:SetSortOrder(3)

    inst.Transform:SetScale(unpack(scale.cave))

    return inst
end

return Prefab("border_circle_tentacle", fn_tentacle, assets)