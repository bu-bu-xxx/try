AddComponentPostInit("combat", function(self)
    local old_GetAttacked = self.GetAttacked
    function self:GetAttacked(attacker,damage,weapon,stimuli,spdamage,...)
        local itm = attacker and attacker:HasTag("player") and attacker.components.inventory and attacker.components.inventory:GetEquippedItem(EQUIPSLOTS.NECK or EQUIPSLOTS.BODY)
        if itm and itm.prefab == 'lol_wp_s7_tearsofgoddess' and itm.components.lol_wp_s7_tearsofgoddess then
            if itm.components.rechargeable and itm.components.rechargeable:IsCharged() then
                itm.components.lol_wp_s7_tearsofgoddess:DoDelta(TUNING.MOD_LOL_WP.TEARSOFGODDESS.SKILL_SPELLFLOW.NUM_PER_HIT,attacker)
                itm.components.rechargeable:Discharge(TUNING.MOD_LOL_WP.TEARSOFGODDESS.SKILL_SPELLFLOW.CD)
            end
        end
        return old_GetAttacked(self,attacker,damage,weapon,stimuli,spdamage,...)
    end
end)


local Text = require 'widgets/text'
AddClassPostConstruct("widgets/itemtile", function(self, invitem)
    self.set_lol_wp_s7_tearsofgoddess = function(self, num)
        if self.item.prefab == 'lol_wp_s7_tearsofgoddess' then
            if not self.lol_wp_s7_tearsofgoddess_val then
                self.lol_wp_s7_tearsofgoddess_val = self:AddChild(Text(NUMBERFONT, 42))
                if JapaneseOnPS4() then
                    self.lol_wp_s7_tearsofgoddess_val:SetHorizontalSqueeze(0.7)
                end
                self.lol_wp_s7_tearsofgoddess_val:SetPosition(5, -32 + 15, 0)
            end

            local val_to_show = num or 0
            if self.item.replica.lol_wp_s7_tearsofgoddess then
                val_to_show = self.item.replica.lol_wp_s7_tearsofgoddess:GetVal()
            end
            -- self.lol_wp_s7_tearsofgoddess_val:SetColour({1,0,0,1})
            self.lol_wp_s7_tearsofgoddess_val:SetString(val_to_show)

            if not self.dragging and self.item:HasTag("show_broken_ui") then
                if self.lol_wp_s7_tearsofgoddess_val > 0 then
                    self.bg:Hide()
                    -- self.spoilage:Hide()
                else
                    self.bg:Show()
                    -- self:SetPerishPercent(0)
                end
            end
            -- return
        end
    end

    if self.item.prefab == 'lol_wp_s7_tearsofgoddess' then
        if self.item.replica.lol_wp_s7_tearsofgoddess then
            self:set_lol_wp_s7_tearsofgoddess(self.item.replica.lol_wp_s7_tearsofgoddess:GetVal())
        end
    end

    self.inst:ListenForEvent("lol_wp_s7_tearsofgoddess_change",function(invitem, data)
        self:set_lol_wp_s7_tearsofgoddess(self.item.replica.lol_wp_s7_tearsofgoddess:GetVal())
    end, invitem)

end)


-- 物品栏也回san且有箭头
AddComponentPostInit("sanity", function(self)
    local old_custom_rate_fn = self.custom_rate_fn
    function self.custom_rate_fn(inst,dt,...)
        local res = old_custom_rate_fn ~= nil and old_custom_rate_fn(inst,dt,...) or 0
        if inst.components.inventory then
            local _,num = inst.components.inventory:Has('lol_wp_s7_tearsofgoddess',1,false)
            if num and num>0 then
                res = res + num*(TUNING.MOD_LOL_WP.TEARSOFGODDESS.DAPPERNESS/54)
            end
        end
        return res
    end
end)