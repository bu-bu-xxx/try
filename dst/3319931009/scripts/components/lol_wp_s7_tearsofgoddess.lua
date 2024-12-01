---@diagnostic disable: trailing-space

local function on_val(self, value)
    self.inst.replica.lol_wp_s7_tearsofgoddess:SetVal(value)
end

local lol_wp_s7_tearsofgoddess = Class(function(self, inst)
    self.inst = inst
    self.val = 0
end,
nil,
{
    val = on_val,
})

function lol_wp_s7_tearsofgoddess:OnSave()
    return {
        val = self.val
    }
end

function lol_wp_s7_tearsofgoddess:OnLoad(data)
    self.val = data.val or 0
end

function lol_wp_s7_tearsofgoddess:DoDelta(delta,owner)
    if not self:IsMax() then
        self.val = math.clamp(self.val + delta,0,TUNING.MOD_LOL_WP.TEARSOFGODDESS.SKILL_SPELLFLOW.SAN_LIMIT_MAX)
     
        if owner:HasTag('player') and owner.components.sanity then
            local san = delta*TUNING.MOD_LOL_WP.TEARSOFGODDESS.SKILL_SPELLFLOW.SAN_LIMIT_PER_NUM
            local maxsan = owner.components.sanity.max
            owner.components.sanity.max = maxsan + san
        end

    end
end

function lol_wp_s7_tearsofgoddess:IsMax()
    return self.val >= TUNING.MOD_LOL_WP.TEARSOFGODDESS.SKILL_SPELLFLOW.SAN_LIMIT_MAX
end

function lol_wp_s7_tearsofgoddess:WhenEquip(owner)
    if owner:HasTag('player') and owner.components.sanity then
        local san = self.val*TUNING.MOD_LOL_WP.TEARSOFGODDESS.SKILL_SPELLFLOW.SAN_LIMIT_PER_NUM
        local maxsan = owner.components.sanity.max
        owner.components.sanity.max = maxsan + san
    end
end

function lol_wp_s7_tearsofgoddess:WhenUnEquip(owner)
    if owner:HasTag('player') and owner.components.sanity then
        local san = self.val*TUNING.MOD_LOL_WP.TEARSOFGODDESS.SKILL_SPELLFLOW.SAN_LIMIT_PER_NUM
        local maxsan = owner.components.sanity.max
        owner.components.sanity.max = math.max(0,maxsan - san)
    end
end


return lol_wp_s7_tearsofgoddess