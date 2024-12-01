local lol_wp_s7_cull_counter = Class(function(self, inst)
    self.inst = inst
    self.val = net_byte(inst.GUID, "lol_wp_s7_cull_counter.val",'lol_wp_s7_cull_counter_change')
end)

function lol_wp_s7_cull_counter:SetVal(num)
    if self.inst.components.lol_wp_s7_cull_counter then
        num = num or 0
        self.val:set(num)
    end
end

function lol_wp_s7_cull_counter:GetVal()
    return self.val:value()
end

return lol_wp_s7_cull_counter