---@diagnostic disable: undefined-global, trailing-space

local LOL_WP_TERRAPRISMA_NUMBER = 3

local prefab_id = "lol_wp_trinity"

local assets =
{
    Asset( "ANIM", "anim/"..prefab_id..".zip"),
    Asset("ANIM","anim/swap_"..prefab_id..".zip"),
    Asset( "ATLAS", "images/inventoryimages/"..prefab_id..".xml" ),
}

local prefabs =
{
    prefab_id,
}

local function trinity_heal(inst,owner,heal_or_stop)
    if heal_or_stop then
        if inst.taskintime_lol_wp_trinity_regen == nil then 
            inst.taskintime_lol_wp_trinity_regen = inst:DoPeriodicTask(TUNING.MOD_LOL_WP.TRINITY.HEAL_INTERVAL,function()
                if owner and owner:IsValid() and owner.components.health and not owner.components.health:IsDead() then
                    owner.components.health:DoDelta(TUNING.MOD_LOL_WP.TRINITY.HEAL_HP)
                end
            end)
        end
    else
        if inst.taskintime_lol_wp_trinity_regen then
            inst.taskintime_lol_wp_trinity_regen:Cancel()
            inst.taskintime_lol_wp_trinity_regen = nil
        end
    end
end


local function playeronattackother(inst,data)
    
    -- 玩家不维持攻击则飞刃停止持续攻击,但是要筛选掉飞刃的攻击
    local stimuli = data and data.stimuli
    if stimuli == nil or stimuli ~= 'lol_wp_trinity_terraprisma' then
        
        inst.lol_wp_trinity_keepatking = true
        if inst.taskintime_lol_wp_trinity_cancel_keepatk then
            inst.taskintime_lol_wp_trinity_cancel_keepatk:Cancel()
            inst.taskintime_lol_wp_trinity_cancel_keepatk = nil
        end
        inst.taskintime_lol_wp_trinity_cancel_keepatk = inst:DoTaskInTime(.5,function ()
            inst.lol_wp_trinity_keepatking = false
        end)

        -- 启动飞刃
        local target = data and data.target
        if target and target:IsValid() and target.components.health and not target.components.health:IsDead() and target.components.combat then
            if inst.isequip_lol_wp_trinity_weapon then
                local wp = inst.isequip_lol_wp_trinity_item_weapon
                if wp then
                    for index, value in ipairs(wp.summons or {}) do
                        if value and value:IsValid() then
                            value.components.summon_controller:PlzKeepAtk()
                            value:Shoot(target)
                        end
                    end
                end
            end
            
            if inst.isequip_lol_wp_trinity_item_amulet then
                local amulet = inst.isequip_lol_wp_trinity_item_amulet
                if amulet then
                    for index, value in ipairs(amulet.summons or {}) do
                        if value and value:IsValid() then
                            value.components.summon_controller:PlzKeepAtk()
                            value:Shoot(target)
                        end
                    end
                end
            end
            
        end
    end

    

    
end

local function whenequip(inst, owner)
    --避免未知原因导致的重复召唤
    if inst.summons then
        for index, value in ipairs(inst.summons) do
            if value and value:IsValid() then
                value:Remove()
            end
        end
    end

    --初始化召唤物
    inst.summons={}
    for i = 1, LOL_WP_TERRAPRISMA_NUMBER, 1 do
        -- local colour_i = (i%6 == 0 and 6) or i%6
        inst.summons[i]=SpawnPrefab('lol_wp_terraprisma')
        if inst.lol_wp_trinity_type then
            if inst.lol_wp_trinity_type == 'weapon' then
                inst.summons[i].custom_dmg = TUNING.MOD_LOL_WP.TRINITY.DMG
            elseif inst.lol_wp_trinity_type == 'amulet' then
                inst.summons[i].custom_dmg = TUNING.MOD_LOL_WP.TRINITY.DMG_WHEN_AMULET
            end
        end
        
        -- if inst.lol_wp_trinity_type then
        --     if inst.lol_wp_trinity_type == 'weapon' then
        --         if LOL_WP_TERRAPRISMA_NUMBER == 3 then
        --             inst.summons[i].custom_dmg = TUNING.MOD_LOL_WP.TRINITY.DMG
        --         elseif LOL_WP_TERRAPRISMA_NUMBER == 6 then
        --             if i <= 3 then
        --                 inst.summons[i].custom_dmg = TUNING.MOD_LOL_WP.TRINITY.DMG
        --             else
        --                 inst.summons[i].custom_dmg = TUNING.MOD_LOL_WP.TRINITY.DMG_WHEN_AMULET
        --             end
        --         end
        --     elseif inst.lol_wp_trinity_type == 'amulet' then
        --         if LOL_WP_TERRAPRISMA_NUMBER == 3 then
        --             inst.summons[i].custom_dmg = TUNING.MOD_LOL_WP.TRINITY.DMG_WHEN_AMULET
        --         elseif LOL_WP_TERRAPRISMA_NUMBER == 6 then
        --             if i <= 3 then
        --                 inst.summons[i].custom_dmg = TUNING.MOD_LOL_WP.TRINITY.DMG
        --             else
        --                 inst.summons[i].custom_dmg = TUNING.MOD_LOL_WP.TRINITY.DMG_WHEN_AMULET
        --             end
        --         end
        --     end
        -- end
        --Init(player,offset,weapon,id)
        inst.summons[i].components.summon_controller:Init(owner,inst,i)
    end
    --用于ui刷新
    -- if owner._equip_terraprisma then
    --     owner._equip_terraprisma:set(true)
    -- end
    --某些情况下，装备者不是玩家，那就默认自动攻击
    if owner.terraprisma_auto==nil then
        owner.terraprisma_auto=false
    end
end

local function whenunequip(inst,owner)
    --移除召唤物
    for index, value in ipairs(inst.summons or {}) do
        if value and value:IsValid() then
            value:Remove()
        end
    end
    --用于ui刷新
    if owner._equip_terraprisma then
        owner._equip_terraprisma:set(false)
    end
end

local function onequip(inst, owner)
    if inst.lol_wp_trinity_type and inst.lol_wp_trinity_type == 'weapon' then
        owner.AnimState:OverrideSymbol("swap_object", "swap_"..prefab_id, "swap_"..prefab_id)
        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")
    end

    
    if inst.lol_wp_trinity_type == 'weapon' then
        owner.isequip_lol_wp_trinity_weapon = true 
        owner.isequip_lol_wp_trinity_item_weapon = inst
    elseif inst.lol_wp_trinity_type == 'amulet' then
        owner.isequip_lol_wp_trinity_amulet = true 
        owner.isequip_lol_wp_trinity_item_amulet = inst
    end
    
    owner:RemoveEventCallback('onhitother',playeronattackother)
    inst:DoTaskInTime(0,function()
        owner:ListenForEvent('onhitother',playeronattackother) -- 用onhitother,不要用onattackother,因为后者会miss
    end)
  

    -- inst.Light:Enable(true)
   
    if inst.lol_wp_trinity_type and inst.lol_wp_trinity_type == 'amulet' then
        trinity_heal(inst,owner,true)
    end
    

    -- inst.components.lol_wp_trinity_parts:genParts()
    -- inst.components.lol_wp_trinity_parts:faceDown()
    -- inst.components.lol_wp_trinity_parts:setState('surround')

    if owner.lol_wp_trinity_equip_num == nil then
        owner.lol_wp_trinity_equip_num = 1
    else
        owner.lol_wp_trinity_equip_num = owner.lol_wp_trinity_equip_num + 1
    end

    -- LOL_WP_TERRAPRISMA_NUMBER = owner.lol_wp_trinity_equip_num == 1 and 3 or 6


    inst.lol_wp_trinity_prisma_num = LOL_WP_TERRAPRISMA_NUMBER

    inst:DoTaskInTime(0, function()
        whenequip(inst, owner)
    end)
    
    
end

local function onunequip(inst, owner)
    if inst.lol_wp_trinity_type == 'weapon' then
        owner.AnimState:Hide("ARM_carry")
        owner.AnimState:Show("ARM_normal")
    end

    if inst.lol_wp_trinity_type == 'weapon' then
        owner.isequip_lol_wp_trinity_weapon = false
    elseif inst.lol_wp_trinity_type == 'amulet' then
        owner.isequip_lol_wp_trinity_amulet = false
    end

    -- 两件都移除才移除监听
    if not owner.isequip_lol_wp_trinity_weapon and not owner.isequip_lol_wp_trinity_amulet then
        owner:RemoveEventCallback('onhitother',playeronattackother)
    end
    

    if owner.lol_wp_trinity_equip_num then
        owner.lol_wp_trinity_equip_num = owner.lol_wp_trinity_equip_num - 1
    end

    -- inst.Light:Enable(false)

    if inst.lol_wp_trinity_type == 'amulet' then
        trinity_heal(inst,owner,false)
    end
    

    -- inst.components.lol_wp_trinity_parts:removeParts()
    whenunequip(inst,owner)
end



local function onattack(inst,attacker,target)
    local fx = SpawnPrefab("crab_king_shine")
    fx.Transform:SetScale(.7,.7,.7)
    fx.Transform:SetPosition(target:GetPosition():Get())

    -- flag: let parts know should do attack
    -- inst.flag_lol_wp_trinity_attack = true
    -- inst.lol_wp_trinity_attack_tar = target


    -- for index, value in ipairs(inst.summons) do
    --     if value and value:IsValid() then
    --         value:Shoot(target)
    --     end
    -- end
end


--实际负责攻击的挂名武器
local function real_weapon_fn()
    local inst = CreateEntity()

    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")
    inst:AddTag("weapon")
    inst:AddTag("lol_wp_terraprisma_real_weapon")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.MOD_LOL_WP.TRINITY.DMG)

    -- inst:AddComponent("planardamage")
	-- inst.components.planardamage:SetBaseDamage(TUNING.LOL_WP_TERRAPRISMA_PLANARDAMAGE)

	-- inst:AddComponent("damagetypebonus")
	-- inst.components.damagetypebonus:AddBonus("shadow_aligned", inst, 2)
    return inst
end

local function onfinished(inst)

    if inst.components.equippable ~= nil and inst.components.equippable:IsEquipped() then
        local owner = inst.components.inventoryitem.owner
        if owner ~= nil and owner.components.inventory ~= nil then
            local item = owner.components.inventory:Unequip(inst.components.equippable.equipslot)
            if item ~= nil then
                owner.components.inventory:GiveItem(item, nil, owner:GetPosition())
            end
        end
    end

    inst:AddTag('lol_wp_trinity_nofiniteuses')

end

local function onsave(inst,data)
    data.lol_wp_trinity_type = inst.lol_wp_trinity_type 
end

local function onpreload(inst,data)
    inst.lol_wp_trinity_type = data and data.lol_wp_trinity_type
    if inst.lol_wp_trinity_type then
        if inst.lol_wp_trinity_type == 'weapon' then
            if inst.components.equippable then

                if inst.components.lol_wp_trinity_enemyselect then
                    inst.components.lol_wp_trinity_enemyselect.type = 'weapon'
                end

                inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
                inst:RemoveTag('amulet')
                inst.components.equippable.walkspeedmult = 1
                -- inst.components.equippable.dapperness = 0
            end
        elseif inst.lol_wp_trinity_type == 'amulet' then
            if inst.components.equippable then

                if inst.components.lol_wp_trinity_enemyselect then
                    inst.components.lol_wp_trinity_enemyselect.type = 'amulet'
                end

                inst.components.equippable.equipslot = EQUIPSLOTS.NECK or EQUIPSLOTS.BODY
                inst:AddTag("amulet") 
                inst.components.equippable.walkspeedmult = TUNING.MOD_LOL_WP.TRINITY.WALKSPEEDMULT
                -- inst.components.equippable.dapperness = TUNING.MOD_LOL_WP.TRINITY.DARPPERNESS/54
            end
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    -- inst.entity:AddLight()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(prefab_id)
    inst.AnimState:SetBuild(prefab_id)
    inst.AnimState:PlayAnimation("idle",true)

    MakeInventoryFloatable(inst, "med", nil, 0.75)

    -- inst.Light:SetFalloff(0.5)
    -- inst.Light:SetIntensity(.8)
    -- inst.Light:SetRadius(TUNING.MOD_LOL_WP.TRINITY.LIGHT_RADIUS)
    -- inst.Light:SetColour(252/255, 212/255, 28/255)
    -- inst.Light:Enable(false)

    inst.entity:SetPristine()

    inst:AddTag("nosteal")

    

    -- inst.MiniMapEntity:SetIcon(prefab_id..".tex")
    inst.Transform:SetScale(.7,.7,.7)

    if not TheWorld.ismastersim then 
        return inst 
    end

    inst.lol_wp_trinity_prisma_num = 3 
    inst.lol_wp_trinity_type = 'weapon' -- or 'amulet'

    inst.real_weapon = SpawnPrefab("lol_wp_terraprisma_real_weapon")
    inst.real_weapon.entity:SetParent(inst.entity)

    --用于非手部栏位时的攻击目标选择
    inst:AddComponent("lol_wp_trinity_enemyselect")

    -- inst:AddComponent("talker")
    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = prefab_id
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..prefab_id..".xml"
    -- inst.components.inventoryitem:SetOnDroppedFn(function()
    -- end)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
    -- inst.components.equippable.equipslot = EQUIPSLOTS.NECK or EQUIPSLOTS.BODY
    
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    -- inst.components.equippable.walkspeedmult = 1
    inst.components.equippable.dapperness = TUNING.MOD_LOL_WP.TRINITY.DARPPERNESS/54

    inst:AddComponent("weapon")
    -- inst.components.weapon:SetDamage(TUNING.MOD_LOL_WP.TRINITY.DMG)
    inst.components.weapon:SetDamage(0.00000000000001)
    inst.components.weapon:SetRange(TUNING.MOD_LOL_WP.TRINITY.RANGE,TUNING.MOD_LOL_WP.TRINITY.RANGE)
    -- inst.components.weapon:SetOnProjectileLaunched(OnProjectileLaunched)
    -- inst.components.weapon:SetProjectile('blowdart_walrus')
    inst.components.weapon:SetOnAttack(onattack)

    -- inst:AddComponent("lol_wp_trinity_parts")

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.MOD_LOL_WP.TRINITY.FINITEUSE)
    inst.components.finiteuses:SetUses(TUNING.MOD_LOL_WP.TRINITY.FINITEUSE)
    inst.components.finiteuses:SetOnFinished(onfinished)

    -- local planardamage = inst:AddComponent("planardamage")
    -- planardamage:SetBaseDamage(data_prefab.planardamage)

    inst.OnSave = onsave
    -- inst.OnLoad = onload
    inst.OnPreLoad = onpreload

    return inst
end

return Prefab("common/inventory/"..prefab_id, fn, assets, prefabs),Prefab("lol_wp_terraprisma_real_weapon", real_weapon_fn)


