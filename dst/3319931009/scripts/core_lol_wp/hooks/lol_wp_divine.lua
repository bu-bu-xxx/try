---@diagnostic disable: undefined-global, trailing-space
AddComponentPostInit('combat',function (self)
    local old_GetAttacked = self.GetAttacked
    function self:GetAttacked(attacker,damage,weapon,stimuli,spdamage,...)
        if weapon and weapon.prefab and weapon.prefab == 'lol_wp_divine' and not weapon.lol_wp_divine_isuseingholyskill then -- 判断武器不是在用技能
            if self.inst:HasTag("shadow_aligned") then
                if damage then
                    damage = damage * TUNING.MOD_LOL_WP.DIVINE.DMGMULT_TO_SHADOW
                end
            end
            -- if weapon.components.rechargeable then
            --     if weapon.components.rechargeable:IsCharged() then
            --         local fx = SpawnPrefab("crab_king_shine")
            --         fx.Transform:SetScale(.7,.7,.7)
            --         fx.Transform:SetPosition(self.inst:GetPosition():Get())

            --         if damage then
            --             damage = damage * TUNING.MOD_LOL_WP.DIVINE.DMGMULT
            --         end

            --         weapon.components.rechargeable:Discharge(TUNING.MOD_LOL_WP.DIVINE.CD)
                    

            --     end

            -- end

            -- 普攻特效
            local x,y,z = self.inst:GetPosition():Get()
            local fx_2 = SpawnPrefab('winters_feast_depletefood')
            fx_2.Transform:SetPosition(x,y,z)
            -- 咒刃
            if weapon.lol_wp_divine_cd == nil or weapon.lol_wp_divine_cd then
                if damage then
                    damage = damage * TUNING.MOD_LOL_WP.DIVINE.DMGMULT
                end

                local fx = SpawnPrefab("crab_king_shine")
                fx.Transform:SetScale(.7,.7,.7)
                fx.Transform:SetPosition(x,y,z)
                
                -- 咒刃触发时回血, 不对建筑生效
                if not self.inst:HasTag("structure") and not self.inst:HasTag("wall") and attacker:HasTag("player") and attacker.components.health and not attacker.components.health:IsDead() then
                    attacker.components.health:DoDelta(TUNING.MOD_LOL_WP.DIVINE.ATK_HEAL)
                end
                

                weapon.lol_wp_divine_cd = false
                if weapon.taskintime_lol_wp_divine_cd == nil then
                    weapon.taskintime_lol_wp_divine_cd = weapon:DoTaskInTime(TUNING.MOD_LOL_WP.SHEEN.CD,function()
                        weapon.lol_wp_divine_cd = true
                        if weapon.taskintime_lol_wp_divine_cd ~= nil then weapon.taskintime_lol_wp_divine_cd:Cancel() weapon.taskintime_lol_wp_divine_cd = nil end
                    end)
                end
            end
        end
        return old_GetAttacked(self,attacker,damage,weapon,stimuli,spdamage,...)
    end
end)

AddComponentPostInit('equippable',function (self)
    local old_IsRestricted = self.IsRestricted
    function self:IsRestricted(target,...)
        if self.inst.prefab == 'lol_wp_divine' then
            if self.inst:HasTag('lol_wp_divine_nofiniteuses') then
                return true
            end
        end
        return old_IsRestricted(self,target,...)
    end
end)

AddClassPostConstruct("components/equippable_replica", function(self)
    local old_IsRestricted = self.IsRestricted
    function self:IsRestricted(target,...)
        if self.inst.prefab == 'lol_wp_divine' then
            if self.inst:HasTag('lol_wp_divine_nofiniteuses') then
                return true
            end
        end
        return old_IsRestricted(self,target,...)
    end
end)