---@diagnostic disable: undefined-global, trailing-space

AddComponentPostInit('combat',function (self)
    local old_GetAttacked = self.GetAttacked
    function self:GetAttacked(attacker,damage,weapon,stimuli,spdamage,...)
        -- 当玩家穿着 恶魔之拥 时
        if attacker and attacker:HasTag("player") and attacker.components.inventory then
            local hat = attacker.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
            if hat and hat:IsValid() and hat.prefab == 'lol_wp_demonicembracehat' then
                -- 被动：【黑暗契约】将玩家5%的最大生命值转化为额外的位面伤害。
                local attacker_maxhp = attacker.components.health and attacker.components.health.maxhealth
                if attacker_maxhp then
                    local extra_planardmg = attacker_maxhp * TUNING.MOD_LOL_WP.DEMONICEMBRACEHAT.SKILL_DARKCONVENANT.TRANSFER_MAXHP_PERCENT
                    if spdamage == nil then
                        spdamage = {}
                    end
                    spdamage['planar'] = (spdamage['planar'] or 0) + extra_planardmg
                end
                -- 被动：【亚扎卡纳的凝视】对一名敌人造成伤害时，会造成相当于其1%最大生命值的额外位面伤害，冷却10秒。
                if hat.components.rechargeable and hat.components.rechargeable:IsCharged() then
                    local victim_maxhp = self.inst.components.health and self.inst.components.health.maxhealth
                    if victim_maxhp then
                        local extra_planardmg_2 = victim_maxhp * TUNING.MOD_LOL_WP.DEMONICEMBRACEHAT.SKILL_STARE.MAXHP_PERCENT
                        if spdamage == nil then
                            spdamage = {}
                        end
                        spdamage['planar'] = (spdamage['planar'] or 0) + extra_planardmg_2

                        hat.components.rechargeable:Discharge(TUNING.MOD_LOL_WP.DEMONICEMBRACEHAT.SKILL_STARE.CD)

                    end
                end
            end
        end
        return old_GetAttacked(self,attacker,damage,weapon,stimuli,spdamage,...)
    end
end)



-- 蓝图
for k,v in pairs(TUNING.MOD_LOL_WP.DEMONICEMBRACEHAT.BLUEPRINTDROP_CHANCE) do
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
            inst.components.lootdropper:AddChanceLoot('lol_wp_demonicembracehat_blueprint',v)
            return unpack(res)
        end)
    end)
end

AddComponentPostInit('equippable',function (self)
    local old_IsRestricted = self.IsRestricted
    function self:IsRestricted(target,...)
        if self.inst.prefab == 'lol_wp_demonicembracehat' then
            if self.inst:HasTag('lol_wp_demonicembracehat_nofiniteuses') then
                return true
            end
        end
        return old_IsRestricted(self,target,...)
    end
end)

AddClassPostConstruct("components/equippable_replica", function(self)
    local old_IsRestricted = self.IsRestricted
    function self:IsRestricted(target,...)
        if self.inst.prefab == 'lol_wp_demonicembracehat' then
            if self.inst:HasTag('lol_wp_demonicembracehat_nofiniteuses') then
                return true
            end
        end
        return old_IsRestricted(self,target,...)
    end
end)