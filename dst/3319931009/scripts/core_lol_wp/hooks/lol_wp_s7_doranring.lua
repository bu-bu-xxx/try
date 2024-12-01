AddComponentPostInit('combat',function (self)
    local old_GetAttacked = self.GetAttacked
    function self:GetAttacked(attacker,damage,weapon,stimuli,spdamage,...)
        if attacker and attacker.components.inventory and attacker.components.inventory:EquipHasTag('lol_wp_s7_doranring') then
            if spdamage == nil then
                spdamage = {}
            end
            spdamage['planar'] = (spdamage['planar'] or 0) + TUNING.MOD_LOL_WP.DORANRING.PLANAR_DMG_WHEN_EQUIP
        end
        return old_GetAttacked(self,attacker,damage,weapon,stimuli,spdamage,...)
    end
end)