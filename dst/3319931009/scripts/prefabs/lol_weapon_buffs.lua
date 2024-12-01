-------------------------------------------------------------------------
---------------------- Attach and dettach functions ---------------------
-------------------------------------------------------------------------

local function slow_attach(inst, target)
    if target.components.locomotor ~= nil then
        target.components.locomotor:SetExternalSpeedMultiplier(inst, inst.prefab, .7)
    end
end

local function slow_detach(inst, target)
    if target.components.locomotor ~= nil then
        target.components.locomotor:RemoveExternalSpeedMultiplier(inst, inst.prefab)
    end
end
-------------------------------------------------------------------------
----------------------- Prefab building functions -----------------------
-------------------------------------------------------------------------

local function OnTimerDone(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
    end
end

local function MakeBuff(name, onattachedfn, onextendedfn, ondetachedfn, duration, priority, prefabs)
    local ATTACH_BUFF_DATA = {
        buff = "ANNOUNCE_ATTACH_BUFF_"..string.upper(name),
        priority = priority
    }
    local DETACH_BUFF_DATA = {
        buff = "ANNOUNCE_DETACH_BUFF_"..string.upper(name),
        priority = priority
    }

    local function OnAttached(inst, target)
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0) --in case of loading
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)

        target:PushEvent("lolweaponbuffattached", ATTACH_BUFF_DATA)
        if onattachedfn ~= nil then
            onattachedfn(inst, target)
        end
    end

    local function OnExtended(inst, target)
        if duration ~= nil then
            inst.components.timer:StopTimer("buffover")
            inst.components.timer:StartTimer("buffover", duration)
        end

        target:PushEvent("lolweaponbuffattached", ATTACH_BUFF_DATA)
        if onextendedfn ~= nil then
            onextendedfn(inst, target)
        end
    end

    local function OnDetached(inst, target)
        if ondetachedfn ~= nil then
            ondetachedfn(inst, target)
        end

        target:PushEvent("lolweaponbuffdetached", DETACH_BUFF_DATA)
        inst:Remove()
    end

    local function fn()
        local inst = CreateEntity()

        if not TheWorld.ismastersim then
            --Not meant for client!
            inst:DoTaskInTime(0, inst.Remove)
            return inst
        end

        inst.entity:AddTransform()

        --[[Non-networked entity]]
        --inst.entity:SetCanSleep(false)
        inst.entity:Hide()
        inst.persists = false

        inst:AddTag("CLASSIFIED")

        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(OnAttached)
        inst.components.debuff:SetDetachedFn(OnDetached)
        inst.components.debuff:SetExtendedFn(OnExtended)
        inst.components.debuff.keepondespawn = true

        if duration ~= nil then
            inst:AddComponent("timer")
            inst.components.timer:StartTimer("buffover", duration)
            inst:ListenForEvent("timerdone", OnTimerDone)
        end

        return inst
    end

    return Prefab("lol_weapon_"..name.."_buff", fn, nil, prefabs)
end

return MakeBuff("slow", slow_attach, nil, slow_detach, 1, 1)