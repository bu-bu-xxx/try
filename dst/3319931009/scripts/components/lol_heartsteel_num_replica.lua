local lol_heartsteel_num = Class(function(self, inst)
    self.inst = inst
    self._num = net_uint(inst.GUID, "lol_heartsteel_num._num",'lol_heartsteel_num_change')
end)

function lol_heartsteel_num:SetNum(num)
    if self.inst.components.lol_heartsteel_num then
        num = num or 0
        self._num:set(num)
    end
end

function lol_heartsteel_num:GetNum()
    if self.inst.components.lol_heartsteel_num ~= nil then
        return self.inst.components.lol_heartsteel_num.num
    else
        return self._num:value()
    end
end

return lol_heartsteel_num