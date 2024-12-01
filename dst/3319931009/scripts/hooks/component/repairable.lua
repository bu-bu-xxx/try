AddComponentPostInit("repairable", function(self)
    if self.inst:HasTag("lol_weapon") then
        function self:Repair(doer, repair_item)
            if self.testvalidrepairfn and not self.testvalidrepairfn(self.inst, repair_item) then
                return false
            end
        
            local repair_item_repairer = repair_item.components.repairer
            if not repair_item_repairer or self.repairmaterial ~= repair_item_repairer.repairmaterial then
                --wrong material
                return false
            elseif self.checkmaterialfn then
                local success, reason = self.checkmaterialfn(self.inst, repair_item)
                if not success then
                    return false, reason
                end
            end
        
            if repair_item_repairer.boatrepairsound then
                self.inst.SoundEmitter:PlaySound(repair_item.components.repairer.boatrepairsound)
            end
        
            if repair_item.components.stackable then
                repair_item.components.stackable:Get():Remove()
            else
                repair_item:Remove()
            end
        
            if self.onrepaired then
                self.onrepaired(self.inst, doer, repair_item)
            end
        
            return true
        end
    end
end)