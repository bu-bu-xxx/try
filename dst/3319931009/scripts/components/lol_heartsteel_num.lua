local function on_num(self, num)
    self.inst.replica.lol_heartsteel_num:SetNum(num)
end
local max_num,per_hp = 40,10

local EQUIPSPEED_MIN = 0.5
local EQUIPSPEED_REDUCE_DY_SCALE = .5 -- SPEEDMULT = (SCLAE-1)*EQUIPSPEED_REDUCE_DY_SCALE

local lol_heartsteel_num = Class(function(self, inst)
    self.inst = inst
    self.num = 0
    self.old_num = 0
end,
nil,
{
    num = on_num,
})
-----save load
function lol_heartsteel_num:OnSave()
    local data = {
        num = self.num,
        old_num = self.old_num,
    }
    return data
end
function lol_heartsteel_num:OnLoad(data)
    self.num = data.num or 0
    self.old_num = data.old_num or 0
    self:ChangeScaleSelf()
end

--

function lol_heartsteel_num:DoDelta(delta)
    if TUNING.CONFIG_LIMIT_LOL_HEARTSTEEL then 
        if self.num >= max_num then
            return
        end
    end
    self.old_num = self.num
    self.num = math.max(self.num + delta,0)
    -- if TUNING.CONFIG_LIMIT_LOL_HEARTSTEEL then 
    --     if self.num > max_num then self.num = max_num end
    -- end
    self.inst:PushEvent('lol_heartsteel_num_changed',{num = self.num})
end

function lol_heartsteel_num:GetNum()
    return self.num
end

function lol_heartsteel_num:SetNum(num) 
    self.num = num
end

function lol_heartsteel_num:TouchSound()
    if self.inst.SoundEmitter then 
        self.inst.SoundEmitter:PlaySound('soundfx_lol_heartsteel/lol_heartsteel/atk')
    end
end


function lol_heartsteel_num:FindMob()
    -- if self.inst.components and self.inst.components.rechargeable then 
    --     if not self.inst.components.rechargeable:IsCharged() then 
    --         return 
    --     end
    -- end
    local x,y,z = self.inst:GetPosition():Get()
    if x and y and z then 
        -- print('---------------------------')
        local ents = TheSim:FindEntities(x,y,z,5,{'_combat'}, {'INLIMBO','player','fx'})
        for _,v in pairs(ents) do 
            -- print(v)
            if v:IsValid() and v.components and v.components.health and not v.components.health:IsDead() and v:HasTag('epic') then 
                -- local allow_to_continue = true
                if v.lol_heartsteel_hited == nil then 
                    v.lol_heartsteel_hited = false 
                end

                if not v.lol_heartsteel_hited then
                    -- 没有特效时才生成
                    if v.fx_lol_heartsteel == nil or not v.fx_lol_heartsteel:IsValid() then 
                        v.fx_lol_heartsteel = SpawnPrefab('fx_lol_heartsteel')
                        v.fx_lol_heartsteel.entity:AddFollower()
                        v.fx_lol_heartsteel.Follower:FollowSymbol(v.GUID, nil, 0, -400, 0)
                        if v.fx_lol_heartsteel.SoundEmitter then 
                            v.fx_lol_heartsteel.SoundEmitter:PlaySound('soundfx_lol_heartsteel/lol_heartsteel/charge_1')
                        end
                    else
                        if v.fx_lol_heartsteel.lifetime then v.fx_lol_heartsteel.lifetime = 4 end -- 重置生命周期
                        if v.fx_lol_heartsteel.stage then 
                            if v.fx_lol_heartsteel.stage < 5 then 
                                v.fx_lol_heartsteel.stage = v.fx_lol_heartsteel.stage + 1 
                                v.fx_lol_heartsteel.AnimState:PlayAnimation('charge_'..v.fx_lol_heartsteel.stage, true)
                                if v.fx_lol_heartsteel.SoundEmitter then 
                                    v.fx_lol_heartsteel.SoundEmitter:PlaySound('soundfx_lol_heartsteel/lol_heartsteel/charge_'..(v.fx_lol_heartsteel.stage<=4 and v.fx_lol_heartsteel.stage or 'done'))
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function lol_heartsteel_num:AddHP(player)

    if TUNING.CONFIG_LIMIT_LOL_HEARTSTEEL then 
        if self.num > max_num then return end
    end

    if player and player:IsValid() and player.components.health and not player.components.health:IsDead() then 
        player.components.health.maxhealth = player.components.health.maxhealth + per_hp
        player.components.health:ForceUpdateHUD(true)
        -- self:ChangeScale(player)
        self:DeltaScale(player)
    end

end

function lol_heartsteel_num:UpdateHP(player,back)
    if back then 
        if player and player:IsValid() and player.components.health then 
            local after = player.components.health.maxhealth - per_hp*self:GetNum()
            -- player.Transform:SetScale(1,1,1)

            self:BackToNormalScale(player)

            if after > 0 then
                player.components.health.maxhealth = after
                player.components.health:ForceUpdateHUD(true)
                
            end
        end
    else
        if player and player:IsValid() and player.components.health then 
            player.components.health.maxhealth = player.components.health.maxhealth + per_hp*self:GetNum()
            player.components.health:ForceUpdateHUD(true)
            -- self:ChangeScale(player)
            self:LoadScale(player)
        end
    end
end


function lol_heartsteel_num:ChangeScale(player)
    -- 自身缩放
    self:ChangeScaleSelf()

    -- 玩家缩放
    local config = TUNING.CONFIG_LIMIT_LOL_HEARTSTEEL_TRANSFORM_SCALE
    if config == 0 then 
        return 
    end

    local size = math.floor(self.num/per_hp)*.1 + 1
    if config == 1 then
        size = math.min(size, 1.4)
    end
    -- local orig_scale = player.Transform:GetScale()
    -- local new_scale = (size-1) + orig_scale
    player.Transform:SetScale(size,size,size)

    self:ChangeEquipSpeedByScale(size)
end

function lol_heartsteel_num:IsScaleMax(player)
    -- 玩家缩放
    local config = TUNING.CONFIG_LIMIT_LOL_HEARTSTEEL_TRANSFORM_SCALE
    if config == 0 then 
        return true
    end

    local size = math.floor(self.num/per_hp)*.1 + 1
    if config == 1 then
        if size >= 1.4 then return true end
    end

    return false
end

function lol_heartsteel_num:DeltaScale(player)
    self:ChangeScaleSelf()
    if not self:IsScaleMax(player) then 
        local orig_scale = player.Transform:GetScale()

        local last_scale = math.floor(self.old_num/per_hp)*.1 + 1
        local new_scale = math.floor(self.num/per_hp)*.1 + 1
        local config = TUNING.CONFIG_LIMIT_LOL_HEARTSTEEL_TRANSFORM_SCALE
        if config == 1 then
            new_scale = math.min(new_scale, 1.4)
        end
        local delta = new_scale - last_scale
        local cur_scale = orig_scale + delta
        player.Transform:SetScale(cur_scale,cur_scale,cur_scale)

        self:ChangeEquipSpeedByScale(cur_scale)
    end
end

function lol_heartsteel_num:LoadScale(player)
    self:ChangeScaleSelf()
    local config = TUNING.CONFIG_LIMIT_LOL_HEARTSTEEL_TRANSFORM_SCALE
    if config == 0 then
        return
    end

    local size = math.floor(self.num/per_hp)*.1 + 1
    if config == 1 then
        size = math.min(size, 1.4)
    end

    local orig_scale = player.Transform:GetScale()
    local new = size-1 + orig_scale
    player.Transform:SetScale(new,new,new)

    self:ChangeEquipSpeedByScale(new)

end

function lol_heartsteel_num:BackToNormalScale(player)
    local config = TUNING.CONFIG_LIMIT_LOL_HEARTSTEEL_TRANSFORM_SCALE
    if config == 0 then 
        return
    end
    local size = math.floor(self.num/per_hp)*.1 + 1
    if config == 1 then
        size = math.min(size, 1.4)
    end

    local orig_scale = player.Transform:GetScale()
    local new = orig_scale - (size-1)
    player.Transform:SetScale(new,new,new) 

    self:ChangeEquipSpeedByScale(new)
end

function lol_heartsteel_num:ChangeScaleSelf()
    local size = math.floor(self.num/per_hp)*.1 + 1
    self.inst.Transform:SetScale(size,size,size)
end

function lol_heartsteel_num:ChangeEquipSpeed(val)
    if self.inst.components.equippable then
        self.inst.components.equippable.walkspeedmult = val
    end
end

local function roundToTwoDecimalPlaces(value)
    return tonumber(string.format("%.2f", value))
end

function lol_heartsteel_num:ChangeEquipSpeedByScale(scale)
    local fix_scale = math.max(1,scale)
    local newspeedmult = math.clamp(1-(fix_scale-1)*EQUIPSPEED_REDUCE_DY_SCALE,EQUIPSPEED_MIN,1)
    newspeedmult = roundToTwoDecimalPlaces(newspeedmult)
    self:ChangeEquipSpeed((newspeedmult))
end

---------
return lol_heartsteel_num