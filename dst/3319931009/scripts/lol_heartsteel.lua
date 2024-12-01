table.insert(PrefabFiles, "prefab_lol_heartsteel")
table.insert(PrefabFiles, "fx_lol_heartsteel")

local lol_heartsteel_asset = {
    Asset('SOUNDPACKAGE', 'sound/soundfx_lol_heartsteel.fev'),
    Asset("SOUND", "sound/soundfx_lol_heartsteel.fsb")
}

for _, v in pairs(lol_heartsteel_asset) do table.insert(Assets, v) end

-- RegisterInventoryItemAtlas("images/gallop_inventoryimages_h_t.xml", "gallop_hydra.tex")

-- lang
-- local cur_lang = GetModConfigData('language')
if currentlang == 'zh' then
    STRINGS.NAMES.LOL_HEARTSTEEL = '心之钢'
    STRINGS.CHARACTERS.GENERIC.DESCRIBE.LOL_HEARTSTEEL =
        '别走，快让我钢一下！'
    STRINGS.RECIPE_DESC.LOL_HEARTSTEEL =
        '叮叮当，叮叮当，快出心之钢！'
    STRINGS.CHARACTERS.GALLOP.DESCRIBE.LOL_HEARTSTEEL =
        '它让我有了和boss正面碰一碰的勇气。'

    STRINGS.LOL_HEARTSTEEL = {
        ACTIONS = {ACTION_LOL_HEARTSTEEL_TOUCH = '钢一下'}
    }
else
    STRINGS.NAMES.LOL_HEARTSTEEL = 'Heart Steel'
    STRINGS.CHARACTERS.GENERIC.DESCRIBE.LOL_HEARTSTEEL =
        'Don\'t go, let me touch you!'
    STRINGS.RECIPE_DESC.LOL_HEARTSTEEL =
        'Ding ding dong, ding ding dong, let\'s get the Heart Steel!'
    STRINGS.CHARACTERS.GALLOP.DESCRIBE.LOL_HEARTSTEEL =
        'It made me have the courage to face the boss head-on.'

    STRINGS.LOL_HEARTSTEEL = {ACTIONS = {ACTION_LOL_HEARTSTEEL_TOUCH = 'Touch'}}
end

--
TUNING.CONFIG_LIMIT_LOL_HEARTSTEEL = GetModConfigData('limit_lol_heartsteel')
TUNING.CONFIG_LIMIT_LOL_HEARTSTEEL_TRANSFORM_SCALE = GetModConfigData('limit_lol_heartsteel_transform_scale')
TUNING.CONFIG_LIMIT_LOL_HEARTSTEEL_EQUIPSLOT = GetModConfigData('limit_lol_heartsteel_equipslot')
TUNING.CONFIG_LIMIT_LOL_HEARTSTEEL_BLUEPRINT_DROPBY = GetModConfigData('limit_lol_heartsteel_blueprint_dropby')
--

modimport('scripts/util/lol_heartsteel_recipes.lua')
modimport('scripts/util/lol_heartsteel_actions.lua')

AddReplicableComponent("lol_heartsteel_num")
-- 克劳斯掉落
local function spawnprefabs(x, y, z, prefabname, prefabnum)
    for i = 1, (prefabnum or 1) do
        local itm = SpawnPrefab(prefabname)
        if not itm then return end
        local down = TheCamera:GetDownVec()
        local angle = math.atan2(down.z, down.x) + (math.random() * 60 - 30) *
                          DEGREES
        local sp = math.random() * 4 + 2
        itm.Transform:SetPosition(x, y, z)
        itm.Physics:SetVel(sp * math.cos(angle), math.random() * 2 + 8,
                           sp * math.sin(angle))
    end
end
AddPrefabPostInit('klaus', function(inst)
    if not TheWorld.ismastersim then return inst end
    inst:ListenForEvent("death", function(inst)
        if inst:IsUnchained() then 
            if TUNING.CONFIG_LIMIT_LOL_HEARTSTEEL_BLUEPRINT_DROPBY == 1 then 
                local x, y, z = inst:GetPosition():Get()
                spawnprefabs(x, y, z, 'lol_heartsteel_blueprint', 1) 
            elseif inst.enraged then
                local x, y, z = inst:GetPosition():Get()
                spawnprefabs(x, y, z, 'lol_heartsteel_blueprint', 1)
            end
        end
    end)
end)

-- AddPrefabPostInit('spear',function(inst)
--     if not TheWorld.ismastersim then
--         return inst
--     end
--     inst.components.weapon:SetDamage(12000)
-- end)
-- 心智刚的层数显示
local Text = require 'widgets/text'
AddClassPostConstruct("widgets/itemtile", function(self, invitem)
    self.SetHeartSteel = function(self, num)
        if self.item.prefab == 'lol_heartsteel' then
            if not self.heartsteel then
                self.heartsteel = self:AddChild(Text(NUMBERFONT, 42))
                if JapaneseOnPS4() then
                    self.heartsteel:SetHorizontalSqueeze(0.7)
                end
                self.heartsteel:SetPosition(5, -32 + 15, 0)
            end

            local val_to_show = num * 10 or 0
            if self.item.replica.lol_heartsteel_num then
                val_to_show = self.item.replica.lol_heartsteel_num:GetNum() * 10
            end
            -- self.heartsteel:SetColour({1,0,0,1})
            self.heartsteel:SetString(val_to_show)

            if not self.dragging and self.item:HasTag("show_broken_ui") then
                if heartsteel > 0 then
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
    -- self:SetHeartSteel(0)
    -- if not self.ismastersim then
        if self.item.prefab == 'lol_heartsteel' then
            if self.item.replica.lol_heartsteel_num then
                self:SetHeartSteel(self.item.replica.lol_heartsteel_num:GetNum())
            end
        end
    -- end

    self.inst:ListenForEvent("lol_heartsteel_num_change",
                             function(invitem, data)
        self:SetHeartSteel(self.item.replica.lol_heartsteel_num:GetNum())
    end, invitem)

end)

local function PhysicsPaddedRangeCheck(doer, target, space)
    if target == nil then return end
    local target_x, target_y, target_z = target.Transform:GetWorldPosition()
    local doer_x, doer_y, doer_z = doer.Transform:GetWorldPosition()
    local target_r = target:GetPhysicsRadius(0) + space
    local dst = distsq(target_x, target_z, doer_x, doer_z)

    return dst <= target_r * target_r
end
local oldrangecheckfn = ACTIONS.PICK.rangecheckfn
ACTIONS.PICK.rangecheckfn = function(doer, target)

    local mindist = 4
    local cur_scale = doer.Transform:GetScale()

    if cur_scale > 1 then
        return PhysicsPaddedRangeCheck(doer, target, cur_scale * mindist * 1.5)
    end
    return oldrangecheckfn(doer, target)
end
