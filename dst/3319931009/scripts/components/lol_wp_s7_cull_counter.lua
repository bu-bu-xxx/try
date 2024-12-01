local LANS = require('core_lol_wp/utils/sugar')

local function on_val(self, value)
    self.inst.replica.lol_wp_s7_cull_counter:SetVal(value)
end

local lol_wp_s7_cull_counter = Class(function(self, inst)
    self.inst = inst
    self.val = 0
end,
nil,
{
    val = on_val,
})

function lol_wp_s7_cull_counter:OnSave()
    return {
        val = self.val
    }
end

function lol_wp_s7_cull_counter:OnLoad(data)
    self.val = data.val or 0
end

function lol_wp_s7_cull_counter:DoDelta(num)
    self.val = self.val + num
end

function lol_wp_s7_cull_counter:Add()
    if not self:IsMax() then
        self.val = math.min(self.val + 1,TUNING.MOD_LOL_WP.CULL.SKILL_LOOT.FINISHED)
    end
end

function lol_wp_s7_cull_counter:IsMax()
    return self.val >= TUNING.MOD_LOL_WP.CULL.SKILL_LOOT.FINISHED
end

function lol_wp_s7_cull_counter:CheckMax(owner)
    if self:IsMax() then
        -- local gold = SpawnPrefab("goldnugget")
        -- gold.components.stackable:SetStackSize(TUNING.MOD_LOL_WP.CULL.SKILL_LOOT.GOLD_WHEN_FINISHED)
        -- LANS:flingItem(gold,self.inst:GetPosition())
        -- 萃取爆掉后掉出的20金块可以直接进入物品栏里
        if owner:HasTag("player") and owner.components.inventory then
            local gold = SpawnPrefab("goldnugget")
            gold.components.stackable:SetStackSize(TUNING.MOD_LOL_WP.CULL.SKILL_LOOT.GOLD_WHEN_FINISHED)
            owner.components.inventory:GiveItem(gold)
        end
        self.inst:Remove()
    end
end

return lol_wp_s7_cull_counter