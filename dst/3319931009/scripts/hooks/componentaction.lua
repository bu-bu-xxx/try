local function GetUpValue(fn, name)
    for i = 1, 99 do
        local upname,upvalue = debug.getupvalue(fn,i)
        if upname and upname == name then
            return upvalue
        end
    end
end

local componentactions = GetUpValue(EntityScript.CollectActions, "COMPONENT_ACTIONS")

local old_spellcaster = componentactions.POINT.spellcaster
componentactions.POINT.spellcaster = function(inst, ...)
    if inst._can_cast then
        return inst._can_cast:value() and old_spellcaster(inst, ...) or nil
    end
    return old_spellcaster(inst, ...)
end