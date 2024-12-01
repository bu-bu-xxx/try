
local prefab_name = 'fx_lol_heartsteel'

local assets =
{
    Asset( 'ANIM', 'anim/'..prefab_name..'.zip'),

}

local prefabs = 
{

}
-------

local function onload(inst, data)
    if inst and inst:IsValid() then inst:Remove() end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    -- MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(prefab_name)
    inst.AnimState:SetBuild(prefab_name)
    -- inst.AnimState:SetDeltaTimeMultiplier(0.2)


    inst.AnimState:PlayAnimation('charge_1',true)
    -- inst.AnimState:PlayAnimation('out_idle',true)

    -- inst.AnimState:PushAnimation('loop',true)

    -- inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    -- inst.AnimState:SetLayer(LAYER_WORLD_BACKGROUND)
    inst.AnimState:SetSortOrder(4)
    -- inst.AnimState:SetScale(1.5, 1.5)
    inst.Transform:SetScale(1.5,1.5,1.5)
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    if not TheWorld.ismastersim then 
        return inst 
    end

    inst.lifetime = 4
    inst.stage = 1

    inst.task_period_life = inst:DoPeriodicTask(1,function(inst)
        -- if inst.lifetime <= 0 then 
        --     if inst.task_period_life then 
        --         inst.task_period_life:Cancel() 
        --         inst.task_period_life = nil 
        --         inst:Remove()
        --     end
        -- end
        inst.lifetime = inst.lifetime - 1
        if inst.lifetime >= 3 then 
            return 
        end
        if inst.stage > 1 then
            inst.stage = inst.stage - 1
        else
            if inst.task_period_life then 
                inst.task_period_life:Cancel() 
                inst.task_period_life = nil 
                if inst and inst:IsValid() then inst:Remove() end
            end
        end
        inst.AnimState:PlayAnimation('charge_'..inst.stage, true)
    end)



    
    inst.OnLoad = onload

    return inst
end

return Prefab('common/inventory/'..prefab_name, fn, assets, prefabs)
