local tool = {}

----------------------------------
-- GAME
----------------------------------

---实体是存活的
---@param ent any
---@return boolean
---@nodiscard
function tool:checkAlive(ent)
    if ent and ent:IsValid() and ent.components.health and not ent.components.health:IsDead() then
        return true
    end
    return false
end

---卸下已装备的物品
---@param equipment any 欲卸下的装备
function tool:unequipItem(equipment)
    if equipment.components.equippable ~= nil and equipment.components.equippable:IsEquipped() then
        local owner = equipment.components.inventoryitem.owner
        if owner ~= nil and owner.components.inventory ~= nil then
            local item = owner.components.inventory:Unequip(equipment.components.equippable.equipslot)
            if item ~= nil then
                owner.components.inventory:GiveItem(item, nil, owner:GetPosition())
            end
        end
    end
end

---大概率能成功添加掉落物lootdrop的方法,这个方法是勾lootsetupfn的
---@param inst ent
---@param fn function 这里写添加lootdrop掉落物的逻辑
function tool:addLootDropAlwaysSuccess(inst,fn)
    if not inst.components.lootdropper then
        inst:AddComponent('lootdropper')
    end
    local old_lootsetupfn = inst.components.lootdropper.lootsetupfn
    inst.components.lootdropper:SetLootSetupFn(function (...)
        local res = old_lootsetupfn ~= nil and {old_lootsetupfn(...)} or {}
        fn(...)
        return unpack(res)
    end)
end

---抛物品
---@param loot ent 预制物
---@param pt Vector3 坐标
function tool:flingItem(loot, pt)
    if loot ~= nil then
        loot.Transform:SetPosition(pt:Get())

        local min_speed = 0
        local max_speed = 2
        local y_speed = 8
        local y_speed_variance = 4

        if loot.Physics ~= nil then
            local angle = math.random() * TWOPI
            local speed = min_speed + math.random() * (max_speed - min_speed)

            local sinangle = math.sin(angle)
            local cosangle = math.cos(angle)
            loot.Physics:SetVel(speed * cosangle, GetRandomWithVariance(y_speed, y_speed_variance), speed * -sinangle)

            local radius = loot:GetPhysicsRadius(1)
            radius = radius * math.random()
            loot.Transform:SetPosition(pt.x + cosangle * radius,pt.y + 0.5,pt.z - sinangle * radius)
        end
    end
end

----------------------------------
-- OTHERS
----------------------------------


---闭包: 判断字符串是否不包含指定的所有字符串
---@param ... string 需要判断的字符串长参
---@return fun(string_needcheck:string):boolean
function tool:stringNotInclude(...)
    local arg = {...}
    return function (string_needcheck)
        for i,v in ipairs(arg) do
            if string.find(string_needcheck,v) then
                return false
            end
        end
        return true
    end
end

return tool