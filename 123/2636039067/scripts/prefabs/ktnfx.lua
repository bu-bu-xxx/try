local assets =
{
}
local function OnUpdate(inst)
    inst._value:set_local(inst._value:value() + 1)

    if inst._value:value() < inst._duration:value() then
        local k = inst._value:value() / inst._duration:value()
        k = k * k * k * k * k
            inst.Light:SetRadius((.1 + 2 * k)*inst._lightvalue:value())
            inst.Light:SetIntensity((.3 - .2 * k)*inst._lightvalue:value())
            inst.Light:SetFalloff((1.1 + .2 * k)*inst._lightvalue:value())
    else
        inst.Light:Enable(false)
        inst.lighttask:Cancel()
        inst.lighttask = nil
        if TheWorld.ismastersim then
            inst:DoTaskInTime(2 * FRAMES, inst.Remove)
        end
    end
end

local function OnSetUpDirty(inst)
    inst.lighttask = inst:DoPeriodicTask(FRAMES, OnUpdate)
    OnUpdate(inst)
end

local function SetUpLight(inst, colour, duration, delay, rangebt)
    inst.Light:SetColour(colour[1], colour[2], colour[3], 1)
    inst.Light:EnableClientModulation(true)
    inst.Light:Enable(true)
    if rangebt and type(rangebt)=="number" then 
    inst._lightvalue:set(rangebt) end
    inst._duration:set(math.floor(duration / FRAMES + .9))
    inst.lighttask = inst:DoPeriodicTask(FRAMES, OnUpdate, delay or 0)
end
local function OnSave(inst, data)
    data.shouldremove = true
end
local function OnLoad(inst, data)
    if data ~=nil then
    inst:Remove()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    MakeFlyingCharacterPhysics(inst, 1, .5)

    inst.entity:SetPristine()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.Light:SetRadius(.3)
    inst.Light:SetIntensity(.8)
    inst.Light:SetFalloff(.9)
    inst.Light:Enable(false)

    inst._duration = net_smallbyte(inst.GUID, "staff_castinglight._duration", "setupdirty")
    inst._value = net_smallbyte(inst.GUID, "staff_castinglight._value")
    inst._lightvalue = net_float(inst.GUID, "_lightvalue")
    inst._lightvalue:set(1) 

    if not TheWorld.ismastersim then
        inst:ListenForEvent("setupdirty", OnSetUpDirty)
        return inst
    end

    --inst:AddComponent("inspectable")

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.SetUpLight = SetUpLight

    return inst
end

return Prefab("ktnfx", fn, assets)