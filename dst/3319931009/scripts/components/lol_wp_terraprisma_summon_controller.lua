-- 摘自工坊mod: 光棱剑


---@diagnostic disable: undefined-global, trailing-space

local LOL_WP_TERRAPRISMA_CIRCLE = true
local LOL_WP_TERRAPRISMA_PLANARDAMAGE = 0
local LOL_WP_TERRAPRISMA_DAMAGE = TUNING.MOD_LOL_WP.TRINITY.DMG
local LOL_WP_TERRAPRISMA_DURABILITY = 1

local function is_in_table(testtable,entry)
    --要求键连续，不处理哈希表
    for i,data in ipairs(testtable)do
        if data == entry then
            return true
        end
    end
end

local function no_tail_in_time(inst, time)
    inst:AddTag("NoTail")
    inst:DoTaskInTime(time,function (inst)
        inst:RemoveTag("NoTail")
    end)
end

local function is_target_invalid(target)
    return target==nil or not target:IsValid() or target.components.health==nil or
    target.components.health:IsDead() or
    target.components.health.currenthealth==target.components.health.minhealth
end

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

local function set_velocity_world_coordinate(inst, angle, velocity)
    local face_angle = inst.Transform:GetRotation()
    local theta = (angle - face_angle)*DEGREES
    local vx = velocity * math.cos(theta)
    local vz = velocity * (-math.sin(theta))
    inst.Physics:SetMotorVel(vx, 0, vz)
end

local function is_included_angle_less_than(angle1,angle2,limit)
    local included_angle = math.abs(angle1-angle2)
    while (included_angle > -180) do
        if math.abs(included_angle) <= limit then
            return true
        end
        included_angle = included_angle -360
    end
    return false
end

local function get_nearest_rotation_direction(start_angle,dest_angle)
    local included_theta = (dest_angle-start_angle)*DEGREES
    if math.sin(included_theta)>0 then
        return 1--顺时针
    else
        return -1--逆时针
    end
end

local function old_circle_runtime_update_fn(self, dt)--backup 2024/10/21
    self.inst.Physics:SetMotorVel(15, 0, 0)
    self.circle_angle=self.circle_angle+dt*300*self.clockwise
    self.inst.Transform:SetRotation(self.circle_angle)
    local pos = self.inst:GetPosition()
    local dest
    --判断是去攻击还是返回
    if self.circle_to_back then
        dest = self.player:GetPosition()
    else
        dest = self.target:GetPosition()
    end
    local to_dest_angle = cal_angle(pos, dest)
    if is_included_angle_less_than(self.circle_angle, to_dest_angle, 12) then
        --判断是去攻击还是返回
        if self.circle_to_back then
            self:GoToState(self.SG.back)
        else
            self:GoToState(self.SG.shoot)
        end
    end
end

local function new_circle_runtime_update_fn(self, dt)
    local pos = self.inst:GetPosition()
    local dest
    --判断是去攻击还是返回
    if self.circle_to_back then
        dest = self.player:GetPosition()
    else
        dest = self.target:GetPosition()
    end
    local to_dest_angle = cal_angle(pos, dest)
    --target可能改变，因此clockwise也会变(1/-1)
    local clockwise = get_nearest_rotation_direction(self.rotation_angle, to_dest_angle)
    self.inst.Transform:SetRotation(self.rotation_angle)
    self.rotation_angle = self.rotation_angle + clockwise*500*dt
    set_velocity_world_coordinate(self.inst,self.speed_angle,20)
    if is_included_angle_less_than(self.rotation_angle, to_dest_angle, 12) then
        --判断是去攻击还是返回
        if self.circle_to_back then
            self:GoToState(self.SG.back)
        else
            self:GoToState(self.SG.shoot)
        end
    end
end

local function pass(state, self, dt) end
local stategraph = {
    idle = {
        name = "idle",
        onenter_fn = function(state, self)
            self.inst.AnimState:PlayAnimation("idle")
            self.inst.AnimState:SetOrientation(ANIM_ORIENTATION.BillBoard)
            local dest = self:GetFollowPosition()
            self.inst.Physics:Stop()
            self.inst.Transform:SetPosition(dest:Get())
        end,
        delay_update_fn = pass,
        runtime_update_fn = function(state, self, dt)
            if LOL_WP_TERRAPRISMA_CIRCLE then
                self:GoToState(self.SG.follow)
                return
            end
            -- local pos = self.inst:GetPosition()
            -- local dest = self:GetFollowPosition()
            -- if pos:DistSq(dest) >= 0.2 then
            --     self:GoToState(self.SG.follow)
            -- end
        end,
        onexit_fn = pass,
        from_state = nil,
        enter_time = 0,
        delay_time = 0,
        exit_time = 0,
    },
    follow = {
        name = "follow",
        onenter_fn = pass,
        delay_update_fn = pass,
        runtime_update_fn = function(state, self, dt)
            local pos = self.inst:GetPosition()
            local dest = self:GetFollowPosition()
            local distsq = pos:DistSq(dest)
            if LOL_WP_TERRAPRISMA_CIRCLE then
                local speed = distsq*5
                self.inst.Physics:SetMotorVel(speed,0,0)
                self.inst:FacePoint(dest)
            -- else
            --     local speed = self.player.components.locomotor:GetRunSpeed()
            --     self.inst.Physics:SetMotorVel(speed,0,0)
            --     self.inst:FacePoint(dest)
            --     if distsq <= 0.1 then
            --         self:GoToState(self.SG.idle)
            --     end
            end
        end,
        onexit_fn = pass,
        from_state = nil,
        enter_time = 0,
        delay_time = 0.1,--0.1秒延迟
        exit_time = 0,
    },
    pre_shoot = {
        name = "pre_shoot",
        onenter_fn = function(state, self)
            state.random_time_in_shoot = math.random()*0.1+0.3--0.3-0.4
            self.inst.Physics:SetMotorVel(40, 0, 0)
            self.inst.AnimState:SetOrientation( ANIM_ORIENTATION.OnGround)
            self.inst.AnimState:PlayAnimation("shoot")
            self.weapon.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_shoot", nil, nil, true)
            --发射前0.1秒屏蔽尾迹
            no_tail_in_time(self.inst, 0.1)
        end,
        delay_update_fn = function(state, self, dt)
            self.inst.Physics:SetMotorVel(40, 0, 0)
        end,
        runtime_update_fn = function(state, self, dt)
            self.inst.Physics:SetMotorVel(5, 0, 0)
            local Dt = GetTime() - state.enter_time
            if Dt >= state.random_time_in_shoot then
                self:GoToState(self.SG.shoot)
            end
        end,
        onexit_fn = pass,
        from_state = nil,
        enter_time = 0,
        delay_time = 0.25,--0.25秒延迟
        exit_time = 0,
    },
    shoot = {
        name = "shoot",
        onenter_fn = pass,
        delay_update_fn = pass,
        runtime_update_fn = function(state, self, dt)

            self:PlzGoBackBeforeCheckTargetIsValid()

            self.inst.Physics:SetMotorVel(60, 0, 0)
            local dest = self.target:GetPosition()
            self.inst:FacePoint(dest)
            if self:CheckHit() then
                self:GoToState(self.SG.circle)
            end
        end,
        onexit_fn = function(state, self)
            -- if self.player.terraprisma_auto then
            --     self.try_change_target = true
            -- end
            -- self.try_back = true
        end,
        from_state = nil,
        enter_time = 0,
        delay_time = 0,
        exit_time = 0,
    },
    circle = {
        name = "circle",
        onenter_fn = function(state, self)
            self.clockwise = math.random() > 0.5 and 1 or -1
            self.rotation_angle = self.inst:GetRotation() + self.clockwise*20
            self.circle_angle = self.inst:GetRotation() --for old version
            self.speed_angle = self.inst:GetRotation() + self.clockwise*105
            -- state.delay_time = math.random()*0.05 + 0.2 --0.2-0.25
            --这里尝试返回
            -- if math.random()<1/3 then
            --     -- self.circle_to_back = true
            -- else
            --     if math.random()<1/2 and self.player.terraprisma_auto then--自动攻击开启，1/3概率更换攻击目标
            --         --这里尝试更换攻击目标
            --         local target = self:FindEnemy(true)
            --         if target then
            --             self.target = target
            --         end
            --     end
            -- end
        end,
        onexit_fn = pass,
        delay_update_fn = function(state,self, dt)
            self.inst.Physics:SetMotorVel(60, 0, 0)
        end,
        runtime_update_fn = function(state, self, dt)
            -- new_circle_runtime_update_fn(self, dt)
            old_circle_runtime_update_fn(self, dt)
        end,
        from_state = nil,
        enter_time = 0,
        delay_time = 0.2,--写在onenter_fn
        exit_time = 0,
    },
    back = {
        name = "back",
        onenter_fn = pass,
        delay_update_fn = pass,
        runtime_update_fn = function(state, self, dt)
            if self:CheckBack() then
                no_tail_in_time(self.inst, 0.1)
                self:GoToState(self.SG.idle)
            end
            local pos = self.inst:GetPosition()
            local dest = self:GetFollowPosition()
            self.inst:FacePoint(dest)
            local distsq = pos:DistSq(dest)
            if distsq <= 16 then
                self.inst.Physics:SetMotorVel(20,0,0)
            else
                self.inst.Physics:SetMotorVel(40,0,0)
            end
        end,
        onexit_fn = function(state, self)
            --从环绕状态返回重新攻击
            self.inst:DoTaskInTime(0.25,function ()
                -- @lan: .
                if self.has_attacked_once then
                    return
                end

                if self.circle_to_back then
                    self.circle_to_back = false
                    self:Shoot(self.target)
                end
            end)
        end,
        from_state = nil,
        enter_time = 0,
        delay_time = 0,
        exit_time = 0,
    }
}

local SummonController = Class(function (self,inst)
    self.inst=inst
    self.player=nil
    self.weapon=nil
    self.target=nil

    self.SG = nil
    self.state = nil

    -- self.try_change_target=false--尝试切换攻击目标的flag，用于单次执行
    -- self.try_back=false--尝试返回的flag，用于单次执行
    self.circle_to_back=false--环绕模式下的返回

    self.rotation_angle=0--自转角度，剑的指向
    self.speed_angle=0--速度方向的角度

    self.circle_angle=0
    self.offset=0
    self.circle_angle=0
    self.clockwise=1

    -- self.last_auto=nil--上一轮OnUpdate的自动攻击状态
    self.last_auto=false

    self.has_attacked_once = false
end)

function SummonController:Init(player,weapon,id)
    self.inst:DoTaskInTime(0,function ()
        self.offset=-0.5+0.25*id
        self.player=player
        self.weapon=weapon
        self.id=id
        self.SG = deepcopy(stategraph)
        self:GoToState(self.SG.idle)
        --生成前0.1秒屏蔽尾迹
        no_tail_in_time(self.inst, 0.1)
        self.inst:StartUpdatingComponent(self)
    end)
end

function SummonController:OnUpdate(dt)
    -- if self.target == nil then
    --     self:PlzGoBack()
    --     return
    -- end
    -- if self.target then
    --     if not self.target:IsValid() then
    --         self:PlzGoBack()
    --         return
    --     end
    --     if self.target:IsValid() and self.target.components and self.target.components.health:IsDead() then
    --         self:PlzGoBack()
    --         return
    --     end
    -- end

    -- if self.has_attacked_once then
    --     return -- 如果已经完成了一次攻击，不再执行任何进一步的动作
    -- end

    if  self.player==nil or not self.player:IsValid() or
        self.weapon==nil or not self.weapon:IsValid() then
        self.inst:Remove()
        return
    end

    -- if self.state.name ~= "idle" and self.state.name ~= "follow" then
    --     if is_target_invalid(self.target) then
    --         self:GoToState(self.SG.back, true)
    --     end
    --     if self.player.terraprisma_auto == false and self.last_auto == true then
    --         self:GoToState(self.SG.back, true)
    --         self.circle_to_back = false
    --     end
    -- else
    --     if self.player.terraprisma_auto TheNet:Announce(msg)
    --         local target = self:FindEnemy()
    --         self:Shoot(target)
    --     end
    --     if self.player.terraprisma_auto == false and self.last_auto == true then
    --         self.circle_to_back = false
    --     end
    -- end

    -- print(state.name,state.from_state and state.from_state.name,self.player)
    if  self.state.delay_time > 0 and 
        GetTime() < (self.state.enter_time + self.state.delay_time) then
        self.state:delay_update_fn(self, dt)
    else

        self.state:runtime_update_fn(self, dt)
    end

    self:DetectDistance()

    if self.state.name ~= "idle" and self.state.name ~= "follow" then
        local vx,vy,vz = self.inst.Physics:GetMotorVel()
        local x,y,z = self.inst.Transform:GetWorldPosition()
        local height = 1.5
        self.inst.Physics:SetMotorVel(vx, (height - y) * 32, vz)
    end

    self.last_auto = self.player.terraprisma_auto
    -- self.last_auto = false
end

function SummonController:GoToState(state, force)
    local old_state = self.state
    if old_state == state then
        return
    end
    local function run()
        if old_state ~= nil then
            old_state.exit_time = GetTime()
            old_state:onexit_fn(self)
        end
        self.state = state
        state.enter_time = GetTime()
        state.from_state = old_state
        state:onenter_fn(self)
    end
    if force then
        if self.task then
            self.task:Cancel()
        end
        run()
    else
        if GetTaskRemaining(self.task) == -1 then
            self.task = self.inst:DoTaskInTime(0,function()
                run()
            end)
        end
    end
end

function SummonController:GetFollowPosition()
    if LOL_WP_TERRAPRISMA_CIRCLE then
        local pos = self.weapon.components.lol_wp_trinity_enemyselect.positions[self.id]
        return Vector3(pos.x,0,pos.z)
    else
        local x,_,z = self.player.Transform:GetWorldPosition()
        local angle = self.player.Transform:GetRotation()
        local x1=x-math.cos(angle*DEGREES)*(1+self.offset)
        local z1=z+math.sin(angle*DEGREES)*(1+self.offset)
        return Vector3(x1,0,z1)
    end
end

function SummonController:Shoot(target)
    if is_target_invalid(target) then
        return false
    end
    --如果是idle或follow状态，执行攻击前的准备
    if self.state.name=="idle" or self.state.name=="follow" then
        --攻击冷却
        if GetTime() < (self.SG.back.exit_time + 0.2) then
            return false
        end
        self.target = target

        --计算玩家到目标的角度
        local start_pos = self.player:GetPosition()
        local dest_pos = self.target:GetPosition()
        local angle = cal_angle(start_pos,dest_pos)
        local offset_angle = math.random()*30+135--135-165
        --根据id的奇偶性，从左右两侧发射
        if self.id%2==0 then
            self.inst.Transform:SetRotation(angle+offset_angle)
        else
            self.inst.Transform:SetRotation(angle-offset_angle)
        end
        self:GoToState(self.SG.pre_shoot, true)
    else
        --如果不是idle或follow状态，切换攻击目标即可
        self.target = target
    end
end

function SummonController:CheckHit()
    local start = self.inst:GetPosition()
    local dest = self.target:GetPosition()
    local real_weapon = self.weapon.real_weapon
    --如果距离小于4，判定为攻击到
    if start:DistSq(dest)<=16 then
        local v = self.target

        if v and v:IsValid() and v.components.health and not v.components.health:IsDead() and v.components.combat and v.components.combat:CanBeAttacked(self.player) then
            local fix_dmg = self.inst.custom_dmg or LOL_WP_TERRAPRISMA_DAMAGE
            --是玩家的话，走DoAttack吃各种伤害加成
            if self.player.components.combat then
                -- 标志位 防止 doattack中的判断失败, 详见hooks\lol_wp_trinity.lua
                if real_weapon.components.weapon then
                    real_weapon.components.weapon:SetDamage(fix_dmg)
                end

                self.player.lol_wp_trinity_terraprisma_canhittarget = true
                self.player.components.combat:DoAttack(v, real_weapon, nil, 'lol_wp_trinity_terraprisma')
                self.player.lol_wp_trinity_terraprisma_canhittarget = false
            else--假人没有combat组件，直接用GetAttacked
                local spdamage = {['planar']=LOL_WP_TERRAPRISMA_PLANARDAMAGE}
                local custom_dmg = self.inst.custom_dmg or LOL_WP_TERRAPRISMA_DAMAGE    
                v.components.combat:GetAttacked(self.player, custom_dmg,nil,nil,spdamage)
            end

            ---
            self:PlzGoBack()
            

            if LOL_WP_TERRAPRISMA_DURABILITY~=-1 then
                if self.weapon.components.finiteuses then
                    self.weapon.components.finiteuses:Use(1)
                end
            end
            local x,_,z = v:GetPosition():Get()
            SpawnPrefab("crab_king_shine").Transform:SetPosition(x,_,z)
            return true
        end
    end
end

function SummonController:PlzGoBack()
    if not self.player.lol_wp_trinity_keepatking then
        self.has_attacked_once = true
        self.circle_to_back = true
        self:GoToState(self.SG.back,true)
    end
end

function SummonController:PlzKeepAtk()
    self.has_attacked_once = false
    self.circle_to_back = false
end

function SummonController:PlzGoBackBeforeCheckTargetIsValid()
    if self.target == nil then
        self:PlzGoBack()
        return
    end
    if self.target then
        if not self.target:IsValid() then
            self:PlzGoBack()
            return
        end
        if self.target:IsValid() and self.target.components and self.target.components.health:IsDead() then
            self:PlzGoBack()
            return
        end
    end
end

function SummonController:CheckBack()
    local pos = self.inst:GetPosition()
    local dest = self:GetFollowPosition()
    local distsq = pos:DistSq(dest)
    if distsq <= 6 then
        self.has_attacked_once = true -- 设置标志变量
        return true
    end
    return false
end

function SummonController:DetectDistance()
    local pos = self.inst:GetPosition()
    local dest = self.player:GetPosition()
    local distsq = pos:DistSq(dest)
    if distsq >= 1600 then
        -- print('too far')
        self:GoToState(self.SG.back)
        if distsq >= 3600 then
            self.inst.Transform:SetPosition(dest:Get())
        end
    end
end

function SummonController:FindEnemy(ignore_current_target)
    if ignore_current_target == nil then
        ignore_current_target = false
    end
    local x,_,z = self.player.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,0,z,16,{"_combat","_health" }, { "playerghost", "INLIMBO", "player","companion","wall","abigail","shadowminion" })
    local legal_targets = {}
    for i, v in ipairs(ents) do
        if  v.components.combat and
            --这里or判断是为了兼容self.player是假人/人偶的情况
            (v.components.combat.target == self.player or is_in_table(AllPlayers, v.components.combat.target)) and
            v.components.health and not v.components.health:IsDead() then
            --这里判断是否排除当前目标
            if v ~= self.target or not ignore_current_target then
                table.insert(legal_targets,v)
            end
        end
    end
    if #legal_targets>0 then
        local target = legal_targets[math.random(#legal_targets)]
        return target
    end
    return nil
end

return SummonController