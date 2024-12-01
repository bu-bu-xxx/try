---@diagnostic disable: undefined-global
AddComponentPostInit('combat',function (self)
    local old_GetAttacked = self.GetAttacked
    function self:GetAttacked(attacker,damage,weapon,stimuli,spdamage,...)
        if weapon and weapon.prefab and weapon.prefab == 'lol_wp_sheen' then
            if self.inst:HasTag("shadow_aligned") then
                if damage then
                    damage = damage * TUNING.MOD_LOL_WP.SHEEN.DMGMULT_TO_SHADOW
                end
            end

            if weapon.components.rechargeable then
                if weapon.components.rechargeable:IsCharged() then
                    local fx = SpawnPrefab("crab_king_shine")
                    fx.Transform:SetScale(.7,.7,.7)
                    fx.Transform:SetPosition(self.inst:GetPosition():Get())

                    if damage then
                        damage = damage * TUNING.MOD_LOL_WP.SHEEN.DMGMULT
                    end

                    weapon.components.rechargeable:Discharge(TUNING.MOD_LOL_WP.SHEEN.CD)
                end
            end
            
        end
        return old_GetAttacked(self,attacker,damage,weapon,stimuli,spdamage,...)
    end
end)