local old_validfn = ACTIONS.SCYTHE.validfn
ACTIONS.SCYTHE.validfn = function(act,...)
    if act.invobject and act.invobject.prefab and act.invobject.prefab == 'lol_wp_s7_cull' then
        if not act.invobject:HasTag('lol_wp_s7_cull_iscd') then
            return true
        end
    end
    if old_validfn ~= nil then
        return old_validfn(act,...)
    end
    return true
end

-- 物品下放会显示累计击杀的次数。
local Text = require 'widgets/text'
AddClassPostConstruct("widgets/itemtile", function(self, invitem)
    self.set_lol_wp_s7_cull = function(self, num)
        if self.item.prefab == 'lol_wp_s7_cull' then
            if not self.lol_wp_s7_cull_val then
                self.lol_wp_s7_cull_val = self:AddChild(Text(NUMBERFONT, 42))
                if JapaneseOnPS4() then
                    self.lol_wp_s7_cull_val:SetHorizontalSqueeze(0.7)
                end
                self.lol_wp_s7_cull_val:SetPosition(5, -32 + 15, 0)
            end

            local val_to_show = num or 0
            if self.item.replica.lol_wp_s7_cull_counter then
                val_to_show = self.item.replica.lol_wp_s7_cull_counter:GetVal()
            end
            -- self.lol_wp_s7_cull_val:SetColour({1,0,0,1})
            self.lol_wp_s7_cull_val:SetString(val_to_show)

            if not self.dragging and self.item:HasTag("show_broken_ui") then
                if self.lol_wp_s7_cull_val > 0 then
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

    if self.item.prefab == 'lol_wp_s7_cull' then
        if self.item.replica.lol_wp_s7_cull_counter then
            self:set_lol_wp_s7_cull(self.item.replica.lol_wp_s7_cull_counter:GetVal())
        end
    end

    self.inst:ListenForEvent("lol_wp_s7_cull_counter_change",function(invitem, data)
        self:set_lol_wp_s7_cull(self.item.replica.lol_wp_s7_cull_counter:GetVal())
    end, invitem)

end)