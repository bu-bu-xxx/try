---@diagnostic disable: undefined-global
local LOL_WP_TERRAPRISMA_CIRCLE = true
local LOL_WP_TERRAPRISMA_NUMBER = 3
local R = 3

local function cal_velocity(old_pos,pos,dt)
    local dx = pos.x - old_pos.x
    local dz = pos.z - old_pos.z
    local speed = math.sqrt(dx*dx+dz*dz)/dt
    return speed
end

local function cal_angle(start, dest)
    local x1 = start.x
    local z1 = start.z
    local x2 = dest.x
    local z2 = dest.z
    local angle=math.atan2(z1-z2,x2-x1)/DEGREES
    return angle--角度制单位
end

--组件用于召唤物环绕控制，以及攻击目标选择
local EnemySelect = Class(function (self,inst)
    self.inst=inst
    --环绕控制,客机端不需要
    if not TheWorld.ismastersim then
        return
    end
    if LOL_WP_TERRAPRISMA_CIRCLE then
        -- local cur_type = self.inst.lol_wp_trinity_type

        -- self.num=LOL_WP_TERRAPRISMA_NUMBER
        -- self.circle=cur_type == 'weapon' and 0 or 180
        -- self.circle_angle=self.circle*DEGREES
        -- self.per_angle= (2*math.pi/self.num)
        -- local positions={}
        -- for i = 1, self.num do
        --     table.insert(positions,{x=0,z=0})
        -- end
        -- self.positions=positions
        self:Init()
  
    end
end)

function EnemySelect:OnSave()
    return {
        -- val = self.val
        per_angle = self.per_angle,
    }
end

function EnemySelect:OnLoad(data)

    self:Init()
end

function EnemySelect:Init()
    local cur_type = self.inst.lol_wp_trinity_type

    self.num=LOL_WP_TERRAPRISMA_NUMBER
    -- self.circle=cur_type == 'weapon' and 0 or 60
    self.circle = 0
    self.circle_angle=self.circle*DEGREES
    self.per_angle= 120 
    local positions={}
    for i = 1, self.num do
        table.insert(positions,{x=0,z=0})
    end
    self.positions=positions

    local x,_,z=self.inst.Transform:GetWorldPosition()
    self.last_pos = {x=x,z=z}

    self.delta_per_angle = cur_type == 'weapon' and 0 or (self.per_angle + 60)
    for i = 0, self.num-1 do
        self.positions[i+1].x=x+R*math.sin(self.circle_angle+ math.rad(self.per_angle*i + self.delta_per_angle))
        self.positions[i+1].z=z+R*math.cos(self.circle_angle+math.rad(self.per_angle*i + self.delta_per_angle))
    end
    self.inst:StartUpdatingComponent(self)
end

function EnemySelect:OnUpdate(dt)
    --根据速度预测环绕中心点，减少落后
    local x,_,z=self.inst.Transform:GetWorldPosition()
    local speed = cal_velocity(self.last_pos, {x=x,z=z}, dt)
    speed = math.min(speed, 30)
    local angle = cal_angle(self.last_pos, {x=x,z=z})
    local x1=x+math.cos(angle*DEGREES)*speed*dt*4.5
    local z1=z-math.sin(angle*DEGREES)*speed*dt*4.5
    --更新旋转基准
    self.circle=self.circle+dt*120
    if self.circle>180 then
        self.circle=self.circle-360
    end
    self.circle_angle=self.circle*DEGREES
    --更新环绕位置
    for i = 0, self.num-1 do
        self.positions[i+1].x=x1+R*math.sin(self.circle_angle+math.rad(self.per_angle*i + self.delta_per_angle))
        self.positions[i+1].z=z1+R*math.cos(self.circle_angle+math.rad(self.per_angle*i + self.delta_per_angle))
    end
    --记录位置，用于下一帧
    self.last_pos = {x=x,z=z}
end

function EnemySelect:OnEquip()
    -- if LOL_WP_TERRAPRISMA_CIRCLE then
    --     self:Init()
    --     self.inst:StartUpdatingComponent(self)
    -- end
end

function EnemySelect:OnUnequip()
    -- if LOL_WP_TERRAPRISMA_CIRCLE then
    --     self.inst:StopUpdatingComponent(self)
    -- end
end

return EnemySelect