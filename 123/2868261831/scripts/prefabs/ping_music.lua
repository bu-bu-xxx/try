local assets = {
    Asset("SOUNDPACKAGE", "sound/lolping.fev"),
    Asset("SOUND", "sound/lolping.fsb")
}

function PlayPingMusic(x, y, z, type)
    local ping_music = SpawnPrefab("ping_music")
    ping_music.Transform:SetPosition(x, y, z)
    ping_music.SoundEmitter:PlaySound("lolping/ping_music/" .. type, nil, 0.03)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()

    inst:AddTag("FX")

    inst:DoTaskInTime(3, inst.Remove)

    inst.entity:SetCanSleep(false)
    inst.persists = false

    return inst
end

return Prefab("ping_music", fn, assets)