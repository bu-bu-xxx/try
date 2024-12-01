---@diagnostic disable: undefined-global, trailing-space

local LOL_WP_TERRAPRISMA_LIGHT = true
local LOL_WP_TERRAPRISMA_SHINING = true

local assets =
{
    Asset("ANIM", "anim/lol_wp_terraprisma.zip"),
    -- Asset("ANIM", "anim/terraprisma_red.zip"),
    -- Asset("ANIM", "anim/terraprisma_green.zip"),
    -- Asset("ANIM", "anim/terraprisma_yellow.zip"),
    -- Asset("ANIM", "anim/terraprisma_purple.zip"),
    -- Asset("ANIM", "anim/terraprisma_orange.zip"),
    Asset("ANIM", "anim/lol_wp_terraprisma_projectile_tail.zip"),
    -- Asset("SHADER", "shaders/rainbow.ksh"),
    -- Asset("SHADER", "shaders/red.ksh"),
    -- Asset("SHADER", "shaders/green.ksh"),
    -- Asset("SHADER", "shaders/blue.ksh"),
    -- Asset("SHADER", "shaders/yellow.ksh"),
    -- Asset("SHADER", "shaders/orange.ksh"),
    -- Asset("SHADER", "shaders/purple.ksh"),
}

local colours =
{
    ["red"] = {200/255, 100/255, 100/255},
    ["green"] = {100/255, 200/255, 100/255},
    ["blue"] = {100/255, 100/255, 200/255},
    ["yellow"] = {200/255, 200/255, 0/255},
    ["orange"] = {255/255, 145/255, 0/255},
    ["purple"] = {200/255, 0/255, 200/255}
}

local WEIGHTED_TAIL_FXS =
{
    ["idle1"] = 1,
    ["idle2"] = .5,
}

local function Projectile_CreateTailFx(colour)
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    -- inst.AnimState:SetBank("lavaarena_blowdart_attacks")
    -- inst.AnimState:SetBuild("lavaarena_blowdart_attacks")
    inst.AnimState:SetBank("lol_wp_terraprisma_projectile_tail")
    inst.AnimState:SetBuild("lol_wp_terraprisma_projectile_tail")
    inst.AnimState:PlayAnimation(weighted_random_choice(WEIGHTED_TAIL_FXS))
    -- inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

    inst.AnimState:SetLightOverride(0.3)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    -- local alpha = 0.75
    -- local r, g, b = unpack(colours[colour])
    -- inst.AnimState:SetMultColour(r, g, b, alpha)
    -- inst.AnimState:OverrideMultColour(r, g, b, alpha)

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end

local function CalVelocity(pos,old_pos,dt)
    local dx = pos.x - old_pos.x
    local dz = pos.z - old_pos.z
    local speed = math.sqrt(dx*dx+dz*dz)/dt
    return speed
end

local function CalAngle(pos,old_pos)
    local x1 = old_pos.x
    local z1 = old_pos.z
    local x2 = pos.x
    local z2 = pos.z
    local angle=math.atan2(z1-z2,x2-x1)/DEGREES
    return angle
end

local function Projectile_UpdateTail(inst)
    local x,_,z = inst.Transform:GetWorldPosition()
    local time = GetTime()
    if not inst:HasTag('NoTail') then
        --客机无法通过Physics获取速度
        local speed = CalVelocity({x=x,z=z}, inst.last_pos, time-inst.last_time)
        speed = math.min(speed, 65)
        local scale = (speed > 5) and ((speed/30-1)*0.6+1.2) or 0
        local tail_1 = inst:CreateTailFx()
        --速度越大，尾迹越长
        tail_1.Transform:SetScale(scale, scale, scale)
        tail_1.Transform:SetPosition(inst.Transform:GetWorldPosition())
        -- 不使用inst.Transform:GetRotation()，以提升尾迹连贯性
        local angle = CalAngle({x=x,z=z}, inst.last_pos)
        tail_1.Transform:SetRotation(angle)
    end
    inst.last_pos = {x=x,z=z}
    inst.last_time = time
end


local function makesword(colour,RGB)

    local function fn()
        local inst = CreateEntity()
    
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        if LOL_WP_TERRAPRISMA_LIGHT then
            inst.entity:AddLight()
            inst.Light:SetFalloff(0.5)
            inst.Light:SetIntensity(0.8)
            inst.Light:SetRadius(TUNING.MOD_LOL_WP.TRINITY.LIGHT_RADIUS)
            inst.Light:SetColour(unpack(RGB))
            inst.Light:Enable(true)
            inst.Light:EnableClientModulation(true)
        end

        --强加载，否则玩家传送会出问题
        inst.entity:SetCanSleep(false)
    
        MakeInventoryPhysics(inst)
    
        inst.Physics:ClearCollidesWith(COLLISION.LIMITS)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.GROUND)
        
        -- inst.AnimState:SetBank("terraprisma_"..colour)
        -- inst.AnimState:SetBuild("terraprisma_"..colour)
        inst.AnimState:SetBank('lol_wp_terraprisma')
        inst.AnimState:SetBuild('lol_wp_terraprisma')
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetLightOverride(0.3)
        --炫光
        if LOL_WP_TERRAPRISMA_SHINING then
            inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        end
        
        --彩虹
        -- if LOL_WP_TERRAPRISMA_DISPLAY==1 then
        --     inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/rainbow.ksh"))
        -- --透明
        -- elseif LOL_WP_TERRAPRISMA_DISPLAY==2 then
        --     inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/"..colour..".ksh"))
        -- end
    
        inst:AddTag("NOCLICK")
        inst:AddTag("NOBLOCK")
    
        MakeInventoryFloatable(inst, "med", 0.05, {1.1, 0.5, 1.1}, true, -9)

        --尾迹,非专用服务器
        if not TheNet:IsDedicated() then
            local x,_,z = inst.Transform:GetWorldPosition()
            inst.last_pos = {x=x,z=z}
            inst.last_time = GetTime()
            inst.CreateTailFx  = function(inst) return Projectile_CreateTailFx(colour) end
            inst.UpdateTail    = Projectile_UpdateTail
            inst:DoPeriodicTask(0, inst.UpdateTail)
        end

        inst.entity:SetPristine()
    
        if not TheWorld.ismastersim then
            return inst
        end
        inst.persists = false
    
        --旧版组件summon_controller已弃用
        inst:AddComponent("lol_wp_terraprisma_summon_controller")
        inst.components.summon_controller = inst.components.lol_wp_terraprisma_summon_controller
        inst:RegisterComponentActions("summon_controller")

        inst.Shoot = function(inst, target)
            inst.components.summon_controller:Shoot(target)
        end

        inst.PlzGoBackBeforeCheckTargetIsValid = function (inst)
            inst.components.summon_controller:PlzGoBackBeforeCheckTargetIsValid()
        end

    
        MakeHauntableLaunch(inst)
    
        return inst
    end

    return Prefab('lol_wp_terraprisma',fn,assets)
end

local prefabs = {}
-- for k,v in pairs(colours) do
--     table.insert(prefabs,makesword(k,v))
-- end
table.insert(prefabs,makesword('blue',{200/255, 200/255, 0/255}))

return  unpack(prefabs)