---@diagnostic disable: undefined-global

local prefab_name = 'fx_lol_wp_trinity'

local assets =
{
    Asset( 'ANIM', 'anim/'..prefab_name..'.zip'),

}

local prefabs =
{

}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    -- MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(prefab_name)
    inst.AnimState:SetBuild(prefab_name)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(1)
    -- inst.AnimState:SetDeltaTimeMultiplier(0.2)

    inst.AnimState:PlayAnimation('idle',true)
    -- inst.AnimState:PushAnimation('idle_loop',true)
    -- inst.AnimState:PlayAnimation('out_idle',true)

    -- inst.AnimState:PushAnimation('loop',true)

    -- inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    -- inst.AnimState:SetOrientation(ANIM_ORIENTATION.Default)
    -- inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
    -- inst.AnimState:SetSortOrder(1)

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")

    -- inst.Transform:SetScale(1.5,1.5,1.5)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab(prefab_name, fn, assets, prefabs)
