local lol_wp_s7_tearsofgoddess = Class(function(self, inst)
    self.inst = inst
    self.val = net_ushortint(inst.GUID, "lol_wp_s7_tearsofgoddess.val",'lol_wp_s7_tearsofgoddess_change')
end)

function lol_wp_s7_tearsofgoddess:SetVal(num)
    if self.inst.components.lol_wp_s7_tearsofgoddess then
        num = num or 0
        self.val:set(num)
    end
end

function lol_wp_s7_tearsofgoddess:GetVal()
    return self.val:value()
end

return lol_wp_s7_tearsofgoddess