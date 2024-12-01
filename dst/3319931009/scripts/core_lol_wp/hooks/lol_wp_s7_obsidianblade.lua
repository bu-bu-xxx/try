---@diagnostic disable: trailing-space

local LANS = require('core_lol_wp/utils/sugar')

AddComponentPostInit("combat", function(self)
    local old_GetAttacked = self.GetAttacked
    function self:GetAttacked(attacker,damage,weapon,stimuli,spdamage,...)
        if weapon and weapon.prefab == 'lol_wp_s7_obsidianblade' then
            if self.inst.components.health and self.inst.components.combat and not self.inst:HasTag("structure") and not self.inst:HasTag("wall") and not self.inst:HasTag("hostile") and not self.inst:HasTag("monster") then
                -- 攻击中立生物会造成双倍伤害，并提供6点吸血
                if damage then
                    damage = damage * TUNING.MOD_LOL_WP.OBSIDIANBLADE.DMGMULT_TO_NEUTRAL
                end
                if attacker and attacker.components.health and not attacker.components.health:IsDead() then
                    attacker.components.health:DoDelta(TUNING.MOD_LOL_WP.OBSIDIANBLADE.DRAIN)
                end
            end
        end
        return old_GetAttacked(self,attacker,damage,weapon,stimuli,spdamage,...)
    end
end)


local filterLootPrefab = LANS:stringNotInclude('sketch','blueprint')


-- 被动：【狩猎人】击杀生物后，会使掉落物中概率最高的掉落物额外掉落一个,,并使所有掉落物概率提高10%。
AddComponentPostInit("health", function(self)
    local old_SetVal = self.SetVal
    function self:SetVal(val,cause,afflicter,...)
        local res = {old_SetVal(self,val,cause,afflicter,...)}
        if self:IsDead() then
            if afflicter and afflicter.last_atk_weapon and afflicter.last_atk_weapon.prefab and afflicter.last_atk_weapon.prefab == 'lol_wp_s7_obsidianblade' then
                -- 这里写一些限制条件
                local allow_to_continue = true
                if self.inst.prefab == 'klaus' then
                    if not self.inst:IsUnchained() then
                        allow_to_continue = false
                    end
                end
                
                if allow_to_continue then
                    if self.inst.components.lootdropper then
                        local victim_lootdrop = self.inst.components.lootdropper
                        local old_lootsetupfn = self.inst.components.lootdropper.lootsetupfn
                        
                        victim_lootdrop:SetLootSetupFn(function(...)
                            -- 创建一个临时表
                            local rank_loots = {}

                            local lootsetupfn_res = old_lootsetupfn ~= nil and {old_lootsetupfn(victim_lootdrop,...)} or {}
                            -- backup
                            self.inst._lol_wp_s7_obsidianblade_loot_backup = {}
                            self.inst._lol_wp_s7_obsidianblade_loot_backup.chanceloot = deepcopy(victim_lootdrop.chanceloot or {})
                            self.inst._lol_wp_s7_obsidianblade_loot_backup.sharedloottable = deepcopy(victim_lootdrop.chanceloottable and LootTables[victim_lootdrop.chanceloottable] or {})
                            self.inst._lol_wp_s7_obsidianblade_loot_backup.loot = deepcopy(victim_lootdrop.loot or {})
                            -- chanceloot
                            
                            for k,v in pairs(victim_lootdrop.chanceloot or {}) do
                                if filterLootPrefab(v.prefab) then
                                    table.insert(rank_loots,{v.prefab,v.chance})
                                    -- 并使所有掉落物概率提高10%。(加算)
                                    v.chance = math.min(1,v.chance+TUNING.MOD_LOL_WP.OBSIDIANBLADE.SKILL_HUNTER.CHANCE_UP)
                                end
                            end
                            -- sharedloottable
                            
                            if victim_lootdrop.chanceloottable then
                                local loot_table = LootTables[victim_lootdrop.chanceloottable]
                                if loot_table then
                                    for i, entry in ipairs(loot_table) do
                                        local prefab = entry[1]
                                        local chance = entry[2]
                                        if filterLootPrefab(prefab) then
                                            table.insert(rank_loots,{prefab,chance})
                                            -- 并使所有掉落物概率提高10%。(加算)
                                            entry[2] = math.min(1,entry[2]+TUNING.MOD_LOL_WP.OBSIDIANBLADE.SKILL_HUNTER.CHANCE_UP)
                                        end
                                    end
                                end
                            end
                            -- weighted loot 权重表只要挑最高的一个
                            
                            if victim_lootdrop.numrandomloot then
                                if victim_lootdrop.totalrandomweight and victim_lootdrop.totalrandomweight > 0 then
                                    if victim_lootdrop.randomloot then
                                        local randomloot_no_blueprint = {}
                                        for i,v in ipairs(victim_lootdrop.randomloot) do
                                            if filterLootPrefab(v.prefab) then
                                                
                                                table.insert(randomloot_no_blueprint,{v.prefab,v.weight})
                                            end
                                        end
                                        table.sort(randomloot_no_blueprint, function(a,b) return a[2] > b[2] end)
                                        local top_weight = randomloot_no_blueprint[1] and randomloot_no_blueprint[1][2]
                                        if top_weight then
                                            local to_chance = top_weight/victim_lootdrop.totalrandomweight
                                            for i,v in ipairs(randomloot_no_blueprint) do
                                                if v[2] == top_weight then
                                                    table.insert(rank_loots,{v[1],to_chance})
                                                end
                                            end
                                        end
                                    end
                                end
                            end
    
                            -- 降序排序
                            table.sort(rank_loots, function(a,b) return a[2] > b[2] end)
                            -- 概率最高为多少
                            local top_chance = rank_loots[1] and rank_loots[1][2]
                            
                            -- 找出概率最高的物品
                            local topchance_items = {}
                            if top_chance then
                                for i,v in ipairs(rank_loots) do
                                    
                                    if v[2] == top_chance then
                                        table.insert(topchance_items,v[1])
                                    end
                                end
                            end
                            -- 百分百掉落表也要计入
                            for i,v in ipairs(victim_lootdrop.loot or {}) do
                                if filterLootPrefab(v) then
                                    table.insert(topchance_items,v)
                                end
                            end
    
                            -- 概率最高且概率相同的物品 随机选一个
                            local num_of_topchance_items = #topchance_items
                            local select_one = num_of_topchance_items>0 and topchance_items[math.random(num_of_topchance_items)]
                            
                            
                            -- 将这个物品添加到掉落表中
                            if select_one then
                                
                                victim_lootdrop.loot = deepcopy(victim_lootdrop.loot or {})
                                table.insert(victim_lootdrop.loot,select_one)
                            end
    
                            return unpack(lootsetupfn_res)
                        end)
                    end
                end
            end
        end
        return unpack(res)
    end
end)


AddComponentPostInit('lootdropper', function(self)
    local old_GenerateLoot = self.GenerateLoot
    function self:GenerateLoot(...)
        local res = {old_GenerateLoot(self,...)}
        if self.inst._lol_wp_s7_obsidianblade_loot_backup then
            if self.inst._lol_wp_s7_obsidianblade_loot_backup.sharedloottable and self.chanceloottable then
                LootTables[self.chanceloottable] = deepcopy(self.inst._lol_wp_s7_obsidianblade_loot_backup.sharedloottable)
            end
        end
        return unpack(res)
    end
end)