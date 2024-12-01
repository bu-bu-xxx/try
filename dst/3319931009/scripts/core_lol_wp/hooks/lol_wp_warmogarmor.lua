---@diagnostic disable: undefined-global

-- cant equip when nofiniteuse
AddComponentPostInit('equippable',function (self)
    local old_IsRestricted = self.IsRestricted
    function self:IsRestricted(target,...)
        if self.inst.prefab == 'lol_wp_warmogarmor' then
            if self.inst:HasTag('lol_wp_warmogarmor_nofiniteuses') then
                return true
            end
        end
        return old_IsRestricted(self,target,...)
    end
end)

AddClassPostConstruct("components/equippable_replica", function(self)
    local old_IsRestricted = self.IsRestricted
    function self:IsRestricted(target,...)
        if self.inst.prefab == 'lol_wp_warmogarmor' then
            if self.inst:HasTag('lol_wp_warmogarmor_nofiniteuses') then
                return true
            end
        end
        return old_IsRestricted(self,target,...)
    end
end)

-- 蓝图
for k,v in pairs(TUNING.MOD_LOL_WP.WARMOGARMOR.BLUEPRINTDROP_CHANCE) do
    AddPrefabPostInit(string.lower(k), function(inst)
        if not TheWorld.ismastersim then
            return inst
        end
        if not inst.components.lootdropper then
            inst:AddComponent('lootdropper')
        end
        local old_lootsetupfn = inst.components.lootdropper.lootsetupfn
        inst.components.lootdropper:SetLootSetupFn(function (...)
            local res = old_lootsetupfn ~= nil and {old_lootsetupfn(...)} or {}
            inst.components.lootdropper:AddChanceLoot('lol_wp_warmogarmor_blueprint',v)
            return unpack(res)
        end)
    end)
end