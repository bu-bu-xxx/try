---@diagnostic disable: undefined-global
AddComponentPostInit("combat", function(self)
    local old_GetAttacked = self.GetAttacked
    function self:GetAttacked(attacker,damage,weapon,stimuli,spdamage,...)
        local equip_amulet = attacker and attacker.components.inventory and attacker.components.inventory:GetEquippedItem(EQUIPSLOTS.NECK or EQUIPSLOTS.BODY)
        if equip_amulet and equip_amulet.prefab == 'lol_wp_trinity' and equip_amulet.lol_wp_trinity_type == 'amulet' then
            if damage then
                damage = damage * TUNING.MOD_LOL_WP.TRINITY.DMGMULT
            end
        end 
        return old_GetAttacked(self,attacker,damage,weapon,stimuli,spdamage,...)
    end
end)


AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then return inst end

    if inst.components.combat then
        local old_CanHitTarget = inst.components.combat.CanHitTarget
        function inst.components.combat:CanHitTarget(...)
            if self.inst.lol_wp_trinity_terraprisma_canhittarget then
                return true
            end
            return old_CanHitTarget(self,...)
        end
    end

end)

-- cant equip when nofiniteuse
AddComponentPostInit('equippable',function (self)
    local old_IsRestricted = self.IsRestricted
    function self:IsRestricted(target,...)
        if self.inst.prefab == 'lol_wp_trinity' then
            if self.inst:HasTag('lol_wp_trinity_nofiniteuses') then
                return true
            end
        end
        return old_IsRestricted(self,target,...)
    end
end)

AddClassPostConstruct("components/equippable_replica", function(self)
    local old_IsRestricted = self.IsRestricted
    function self:IsRestricted(target,...)
        if self.inst.prefab == 'lol_wp_trinity' then
            if self.inst:HasTag('lol_wp_trinity_nofiniteuses') then
                return true
            end
        end
        return old_IsRestricted(self,target,...)
    end
end)