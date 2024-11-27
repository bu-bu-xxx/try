local assets=
{
    Asset("ANIM", "anim/LongSword.zip"),
    Asset("ANIM", "anim/swap_LongSword.zip"),
    Asset("ANIM", "anim/swap_LSnadao.zip"),
    Asset("ANIM", "anim/swap_LongSword_n.zip"),
    Asset("ANIM", "anim/swap_LSnadao_n.zip"),

    Asset("ATLAS", "images/inventoryimages/LongSword.xml"),
    Asset("IMAGE", "images/inventoryimages/LongSword.tex"),
}
prefabs = {
    "LongSword",
}
local function Exist(tar,candeath)
  return tar and tar:IsValid() and ((tar.components.health and not tar.components.health:IsDead() and not tar:HasTag("playerghost")) or candeath)
end
local function onfinished(inst)
    inst:Remove()
end
local function niltask(inst,task)
 if inst[task] then inst[task]:Cancel() inst[task] = nil end
end
local function isay(it,world,t)
    if it.components.talker then  t = t or 2
     it.components.talker:Say(world,t) 
    end
end
local function ThIsInList(th, list)
    if list then 
    for k,v in pairs(list) do
        if v == th or k == th then
            return true
          end
        end
    end
end
local function Inserttable(intab,tab,isprefab)
        if intab and tab then 
    for k,v in pairs(tab) do
        local th = (isprefab and v.prefab) or v
        if th then
            table.insert(intab,th)
          end
        end
    end
end
local function Insertlist(intab, list)
    if list then 
    local loot_table =  LootTables[list]
     if loot_table then 
    for i,v in ipairs(loot_table) do
      local prefab = v[1]
        if prefab then
           table.insert(intab,prefab) 
             end
           end
        end
    end
end
local function removeallbench(owner)
      if owner.ktnbench and owner.ktnbench:IsValid() then owner.ktnbench:Remove() owner.ktnbench = nil end
      if owner.ktnbench_far and owner.ktnbench_far:IsValid() then owner.ktnbench_far:Remove() owner.ktnbench_far = nil end
      if owner.ktnbench_l and owner.ktnbench_l:IsValid() then owner.ktnbench_l:Remove() owner.ktnbench_l = nil end
      if owner.ktnbench_r and owner.ktnbench_r:IsValid() then owner.ktnbench_r:Remove() owner.ktnbench_r = nil end
      if owner.ktnbench_index and owner.ktnbench_index:IsValid() then owner.ktnbench_index:Remove() owner.ktnbench_index = nil end
end
local function KtnBeAttacked(owner,data)
    niltask(owner,"abouttoqrz") 
    local cbt = data.attacker and data.attacker.components.combat
    if cbt and data.attacker.cbt_range then cbt.hitrange = data.attacker.cbt_range data.attacker.cbt_range = nil end
    owner.needue = true owner:DoTaskInTime(.1,function() owner.needue = nil end)
    if owner.components.health:IsDead() then return end
        if owner.sg:HasStateTag('denlong') then
        owner.sg:GoToState("hitfall")
        elseif owner.sg:HasStateTag('edgeing') then niltask(owner,"juherot") owner.sg:GoToState("hit") end 
end
local function tagenemy(owner,targ)
    if targ then 
       niltask(targ,"beentagedbyktn")
       targ:AddTag("ktn_tagenemy") targ.beentagedbyktn = targ:DoTaskInTime(7,function() targ:RemoveTag("ktn_tagenemy") end)
    end
end

local Ice = {"bluegem", "deerclops_eyeball","ice","trunk_winter","feather_robin_winter"}
local Fire = {"redgem", "houndfire","dragon_scales"}
local function KtnHitOtherForK(owner,data)
    local td = owner.taidao
    local tar = data.target
    local tarcp = tar.components
    if td and owner.sg and not owner.sg:HasStateTag('ktnsg') and owner.sg.currentstate.name == "attack" then
        td.components.edgerank:QrDoDelta(.05) 
    end
end
local function KtnHitOther(owner,data)

    local td = owner.taidao
    local tar = data.target
    local tarcp = tar.components
    if td then  --Fire Attribute ,,consider to make a component
    
    if tar.sg and tar.sg.mem and tar.sg.mem.noice == 1 and not tar.components.burnable:IsBurning() then tar.components.burnable:Ignite() end

    local dp = tar.components.lootdropper 
    local GenerateLoot = {}
    tagenemy(owner,tar)
  if dp then
    Inserttable(GenerateLoot,dp.loot)Inserttable(GenerateLoot,dp.chanceloot,true)
    Inserttable(GenerateLoot,dp.randomloot,true)Inserttable(GenerateLoot,dp.randomhauntedloot,true)
    Insertlist(GenerateLoot,dp.chanceloottable)
    local burn = 0 local inbust = 0 local iceab = nil local fireab = nil
    for k,v in pairs(GenerateLoot) do
        if ThIsInList(v,Ice) and not fireab then
            iceab = true
        end
        if ThIsInList(v,Fire) then
            iceab = nil fireab = true
        end

        if PrefabExists(v) then
        local vp = SpawnPrefab(v)
            if vp and vp.components and vp.components.burnable then
                burn = burn +1
            elseif vp then 
                inbust = inbust+1
            end
            if vp then vp:Remove() end
        end
    end

    if td.components.sharpness then
       if data.damage > 10 then owner.modaot = 4 end
       td.components.sharpness:Consume() 
       td.components.sharpness:CheckTD(owner,tar,GenerateLoot or {}) end

    local cause = data.weapon or owner
    local extraforice = iceab or (tar.gem and tar.gem == "blue") or (tar.countgems and tar.countgems(tar).blue and tar.countgems(tar).blue>=3)
    if tarcp.health then
       if (burn > inbust) or (burn>0 and inbust <1) then 
    --owner.components.talker:Say("extra damage, "..burn.." , "..inbust.." , "..0.1*data.damage)
    tarcp.health:DoDelta(-0.1*data.damage, nil, cause ~= nil and (cause.nameoverride or cause.prefab) or "NIL", nil, cause)
       elseif extraforice  then 
    --owner.components.talker:Say("extra for ice, "..0.2*data.damage)
    tarcp.health:DoDelta(-0.2*data.damage, nil, cause ~= nil and (cause.nameoverride or cause.prefab) or "NIL", nil, cause)
       end
    end

  end

    if owner.sg:HasStateTag('jszhan') then
        td.components.edgerank:QrDoDelta(.25)
     elseif owner.sg:HasStateTag('tcst') or (owner.sg:HasStateTag('qrz') and not owner.sg:HasStateTag('notandao')) then
        td.components.edgerank:QrDoDelta(.1)
     elseif owner.sg:HasStateTag('tabuz') or owner.sg:HasStateTag('zhiz') then
        td.components.edgerank:QrDoDelta(.2)
     elseif not owner.sg:HasStateTag('ktnsg') and data.damage > 10 then
        td.components.edgerank:QrDoDelta(.05) end
    end


end

local nilallktn = function(owner) owner.ktndlable = nil owner.ktnjhable = nil owner.ktnjqable = nil owner.aftdoatk = nil owner.canuseevade=nil niltask(owner,"abouttoqrz") end

local function doqrz(inst,sg,extra,frame)
    if inst.abouttoqrz then return end
    local frame = frame or 3
    inst.abouttoqrz = inst:DoTaskInTime(frame*FRAMES,function()
    if inst.components.health:IsDead() then return end
    inst.sg:GoToState(sg,extra)
    nilallktn(inst) end)
end

local jqcondition = function(owner) return (not KEYTYPE and (owner.td_atk and owner.td_space)) or (KEYTYPE and owner.td_qrz and owner.ktnmouser) end
local dlcondition = function(owner) return (not KEYTYPE and (owner.td_atk and owner.td_qrz)) or (KEYTYPE and owner.td_qrz and owner.ktnmousel) end


local function tdcontrol(owner,inst)
       if owner.components.health:IsDead() or owner.components.rider:IsRiding() or owner.karoustop then return end
       local withqr = inst.components.edgerank.qiren>=0.15
       local withqrlevel = inst.components.edgerank.rank > 0

        if not inst.locked then

-------------Specified ------------

            if owner.ktndlable then
                if dlcondition(owner) then --dl
                   owner.sg:GoToState("qrdg_pre2") nilallktn(owner)
                end   
            end
            if owner.ktnjhable then
                if owner.td_qrz and owner.td_space then --jh
                   owner.sg:GoToState("nadao",owner.sg:HasStateTag("ndaftedg")) nilallktn(owner)
                end
            end
            if owner.ktnjqable then
                if jqcondition(owner) then -- jq
                   owner.sg:GoToState("kanpo") nilallktn(owner)
                end
            end
            if owner.sg:HasStateTag("tuci") and not owner.sg:HasStateTag("abouttoattack") then
                if ((KEYTYPE and owner.ktnmousel and not owner.ktnmouser ) or (not KEYTYPE and owner.td_atk and not owner.td_space)) then
                   doqrz(owner,"shangtiao")
                end
            end
            if owner.sg:HasStateTag("tabuz") and owner.aftdoatk then
                if ((KEYTYPE and owner.ktnmousel and not owner.ktnmouser ) or (not KEYTYPE and owner.td_atk and not owner.td_space)) then
                   doqrz(owner,"zhiz")
                elseif owner.ktnmouser then 
                   doqrz(owner,"tuci",true)
                end
            end
            if owner.sg:HasStateTag("zhiz") and owner.aftdoatk then
                if ((KEYTYPE and (owner.ktnmouser and not owner.ktnmousel) or (owner.ktnmousel and not owner.ktnmouser) ) or (not KEYTYPE and owner.td_atk and not owner.td_space)) then
                   doqrz(owner,"tuci")
                end
            end
            if (owner.sg:HasStateTag("shangtiao") or owner.canusetc) and not owner.sg:HasStateTag("abouttoattack") then
                if ((KEYTYPE and owner.ktnmouser and not owner.ktnmousel) or (not KEYTYPE and owner.td_atk and not owner.td_space)) then
                   doqrz(owner,"tuci") owner.canusetc = nil
                elseif owner.ktnmousel then 
                   doqrz(owner,"zhiz") owner.canusetc = nil
                end
            end
            if owner.canedged and inst.components.edgerank.qiren>=0.25 then
                if owner.td_qrz then
                   doqrz(owner,"qrdhx") 
                end
            end

--------------------------------For the sutation you have done a atk-----------------------------------------
                 if owner.sg:HasStateTag("attack") and owner.aftdoatk and not owner.sg:HasStateTag("juheL") then
                    if owner.td_qrz and owner.td_space and not owner.sg:HasStateTag("juheS") then --jh
                        owner.sg:GoToState("nadao") niltask(owner,"abouttoqrz") nilallktn(owner)
                    elseif jqcondition(owner) and not owner.sg:HasStateTag("jianqie") then --jq 
                        owner.sg:GoToState("kanpo") nilallktn(owner) niltask(owner,"abouttoqrz") 
                    elseif dlcondition(owner) and not (not withqrlevel and owner.sg:HasStateTag("shangtiao")) then --dl
                        owner.sg:GoToState("qrdg_pre2") niltask(owner,"abouttoqrz")   
                    elseif (owner.jszhankey or (owner.ktnmouser and owner.ktnmousel)) and not owner.sg:HasStateTag("jszhan") then
                          owner.jszaftatk = true owner.sg:GoToState("jszhan_pre") niltask(owner,"abouttoqrz")  
                    elseif not owner.sg:HasStateTag("tuci") and not owner.sg:HasStateTag("qrz") and owner.ktnmouser and not owner.sg:HasStateTag("jszhan") then
                        doqrz(owner,"tuci") 
                    elseif owner.ktnmousel and not owner.sg:HasStateTag("tabuz") and not owner.sg:HasStateTag("zhiz")
                    and not owner.sg:HasStateTag("qrz") and not owner.sg:HasStateTag("jszhan") and not owner.sg:HasStateTag("qrz1") then 
                        doqrz(owner,"tabuz") 

                    elseif owner.td_qrz and not owner.abouttoqrz and not owner.sg:HasStateTag("jianqie") then --Press Qr
                        if (owner.sg:HasStateTag("qrz3") or owner.canedged) and inst.components.edgerank.qiren>=0.25 then
                        doqrz(owner,"qrdhx") 
                    elseif owner.sg:HasStateTag("qrz2") and withqr then
                        doqrz(owner,"qrz_3") 
                      elseif (owner.sg:HasStateTag("qrz1")) and withqr then
                        doqrz(owner,"qrz_2") 
                      elseif owner.sg:HasStateTag("jszhan") then
                        doqrz(owner,"njszhan") 
                      elseif not owner.sg:HasStateTag("qrz") and not owner.sg.statemem.stqrz then 
                        owner.heaveqrz = owner.sg:HasStateTag("juheS")
                        doqrz(owner,"qrz_1")
                        end 
------------------------------------------------------And for atk aft qrz---------------------------------------------------------------
                    elseif ((KEYTYPE and (owner.ktnmousel or owner.ktnmouser)) or (not KEYTYPE and owner.td_atk)) and not owner.abouttoqrz and not owner.sg:HasStateTag("tcst") then 
                        if owner.sg:HasStateTag("qrz1") or owner.sg:HasStateTag("noqrqrz") or owner.sg:HasStateTag("jszhan") then
                           doqrz(owner,"tuci",(not owner.sg:HasStateTag("jszhan")))
                    elseif owner.sg:HasStateTag("qrz2") then
                           doqrz(owner,"shangtiao",true)
                        end
                    end

                 end
--------------------------------------------------------------In idle state---------------------------------------------------------------------
             if not (owner.sg:HasStateTag("busy") or owner.sg:HasStateTag("frozen")
                or owner.sg:HasStateTag("doing")or owner.sg:HasStateTag("working")
                or owner.sg:HasStateTag("busy")or owner.sg:HasStateTag("busy")or owner.sg:HasStateTag("busy")or owner.aftdoatk) then
                if owner.jszhankey or (owner.ktnmouser and owner.ktnmousel) then
                   owner.sg:GoToState("jszhan",true) niltask(owner,"abouttoqrz") 
                elseif dlcondition(owner) then --dl
                   owner.sg:GoToState("qrdg_pre") niltask(owner,"abouttoqrz") 
                elseif (owner.td_atk or (KEYTYPE and KEYTYPE == 1)) and owner.ktnmousel then
                       owner.sg:GoToState("tabuz") niltask(owner,"abouttoqrz") 
                elseif owner.td_qrz and not owner.abouttoqrz then --Press Qr
                        doqrz(owner,"qrz_1",true)
                elseif ((KEYTYPE and owner.ktnmouser) or (not KEYTYPE and owner.td_atk and owner.td_space)) then 
                        owner.sg:GoToState("tuci")
                elseif owner.wanttosharpktn then  --sharpen
                owner.ktnmds = owner.components.inventory:FindItem(function(v) return v.prefab == "redgem" or v.prefab == "goldnugget" end)
                if owner.ktnmds then 
                       owner.sg:GoToState("sharpen_pre")
                else isay(owner,(MOD_KTN_LANGUAGE_SETTING and '需要金子或者红宝石')or "I need Redgem or gold") end
                end
             end
    end
--------------------------------------------------------------Evade---------------------------------------------------------------------
            if owner.components.hunger and owner.components.hunger.current>=-1 and owner.td_space
               and not owner.sg:HasStateTag("evading")and not owner.sg:HasStateTag("juheL") then
               if owner.sg:HasStateTag("modao") or (owner.components.burnable and owner.components.burnable:IsBurning() and not owner.sg:HasStateTag("busy")) then
                  owner.sg:GoToState("evade",true)
               elseif (owner.aftdoatk or owner.canuseevade or string.match(owner.sg.currentstate.name,"_pst")) then
                  doqrz(owner,"evade_pre",nil,2) owner.aftdoatk = nil
     
               end
            end

end


    local function OnEquip(inst, owner)
        if type(KEYTYPE) == "number" then  
            inst.locked = true 
            owner:RemoveTag("controllerktnlock")
        end

        owner.AnimState:OverrideSymbol("swap_object", "swap_LongSword", "swap_Katana")
        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")
        if not owner.sg then return end
        niltask(owner,"taidaoxia")
        owner.ktnmousel = nil

        if not owner:HasTag("stronggrip") then
            --owner:AddTag("stronggrip")
            --inst.stronggrip = true
        end
        if not owner:HasTag("yurri") then
            owner:AddTag("yurri")
            inst.yurri = true
        end

        owner:AddTag("ktn_"..owner.name)
        owner:AddTag("taidaoxia")
        owner.taidao = inst
        --if owner.components.playeractionpicker then
        --owner.components.playeractionpicker:PushActionFilter(tdcontrol, 999) end

       owner.taidaoxia = owner:DoPeriodicTask(FRAMES,function()

       if not (owner.ktnbench and owner.ktnbench:IsValid()) then 
       owner.ktnbench = CreateEntity() owner.ktnbench.entity:AddTransform()
       owner.ktnbench.Transform:SetPosition(1.6, 0, 0) 
       owner.ktnbench:AddTag("INLIMBO")
       owner:AddChild(owner.ktnbench) 
       --owner.ktnbench.entity:AddFollower()
       --owner.ktnbench.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -180, 0) --cool idea 
       --owner.ktnbench:AddChild(SpawnPrefab("flower"))
       end
       if not (owner.ktnbench_far and owner.ktnbench_far:IsValid()) then 
       owner.ktnbench_far = CreateEntity() owner.ktnbench_far.entity:AddTransform()
       owner.ktnbench_far.Transform:SetPosition(2.3, 0, 0)
       owner.ktnbench_far:AddTag("INLIMBO")
       owner:AddChild(owner.ktnbench_far) 

       owner.ktnbench_index = CreateEntity() owner.ktnbench_index.entity:AddTransform()
       local index = owner.ktnbench_index
       index:AddTag("INLIMBO")
       index.entity:AddFollower()
       index.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -295, 0) 
       local index = owner.dhxbenchit or index
       index:AddComponent("knownlocations")
       local pos = index:GetPosition() 
       index.components.knownlocations:RememberLocation("home", {x=pos.x,y=0,z=pos.z})
       index:DoPeriodicTask(FRAMES,function() 
             local pt = index:GetPosition() 
             if (pt.y < 0.1 and owner.sg:HasStateTag("attack")) or Exist(owner.dhxbenchit,true) then 
                local pos = index:GetPosition() 
                local homepos = index.components.knownlocations:GetLocation("home")
                --local hadspawned = FindEntity(index, 2, function(a) return a:HasTag("hitgroundfx") end) 
                local hadspawned = distsq(pos, homepos) <= 3
                if not hadspawned then
                   if TheWorld.Map:IsOceanAtPoint(pos.x, 0, pos.z, nil) then
                      local indexfx = SpawnPrefab("crab_king_waterspout")
                      local bt = math.random()*0.1
                      indexfx.Transform:SetScale(.35+bt, .15+bt, .35+bt)
                      indexfx:AddTag("hitgroundfx")  
                      indexfx.Transform:SetPosition(pos.x,0,pos.z) 
                      index.components.knownlocations:RememberLocation("home", {x=pos.x,y=0,z=pos.z})
                    else
                      local indexfx = SpawnPrefab("burnt_marsh_bush_erode")
                      indexfx:AddTag("hitgroundfx")  
                      indexfx:FacePoint(owner.Transform:GetWorldPosition())
                      indexfx.Transform:SetPosition(pos.x,0,pos.z) 
                      index.components.knownlocations:RememberLocation("home", {x=pos.x,y=0,z=pos.z})
                   end
                end
             end
       end)
       --owner.ktnbench_index:AddChild(SpawnPrefab("flower"))
       end
       if not (owner.ktnbench_l and owner.ktnbench_l:IsValid()) then 
       owner.ktnbench_l = CreateEntity() owner.ktnbench_l.entity:AddTransform()
       owner.ktnbench_l.Transform:SetPosition(0, 0, -1)
       owner.ktnbench_l:AddTag("INLIMBO")
       owner:AddChild(owner.ktnbench_l) 
       end
       if not (owner.ktnbench_r and owner.ktnbench_r:IsValid()) then 
       owner.ktnbench_r = CreateEntity() owner.ktnbench_r.entity:AddTransform()
       owner.ktnbench_r.Transform:SetPosition(0, 0, 1)
       owner.ktnbench_r:AddTag("INLIMBO")
       owner:AddChild(owner.ktnbench_r) 
       end

       local setoutfit = inst.components.edgerank and inst.components.edgerank.rank>2 and "_n" or ''
       if owner.sg:HasStateTag("nadao_done") or inst.locked then
       owner.AnimState:OverrideSymbol("swap_object", "swap_LSnadao"..setoutfit, "swap_Katana")
       else owner.AnimState:OverrideSymbol("swap_object", "swap_LongSword"..setoutfit, "swap_Katana")
       end
       
       if inst.gonnalockit and not owner.lockktn then 
          inst.gonnalockit = nil
          if inst.locked then
               removeallbench(owner) owner:AddTag("controllerktnlock")
               inst.locked = nil inst.SoundEmitter:PlaySound("longsword/katana/ding2")
          else inst.locked = true inst.SoundEmitter:PlaySound("longsword/katana/dlz_last") 
               owner:RemoveTag("controllerktnlock") end
       elseif owner.lockktn then inst.gonnalockit = true end


       if KEYTYPE and owner.td_atk then niltask(owner,"abouttoqrz")  end
            
                if owner.aftdoatk and not (owner.sg:HasStateTag("attack")or owner.td_atk) then --when u stop atk 
                owner.aftdoatk = nil
                elseif not owner.aftdoatk2 and owner.sg:HasStateTag("abouttoattack") then --prove u r atking
                owner.aftdoatk2 = true 
                elseif owner.aftdoatk2 and not owner.sg:HasStateTag("abouttoattack") and owner.sg:HasStateTag("attack") then --prove ur atk is done
                owner.aftdoatk = true 
                end

        tdcontrol(owner,inst)

        end)

        owner:ListenForEvent( "attacked", KtnBeAttacked)
        owner:ListenForEvent( "onKTNhitother", KtnHitOther)    
        owner:ListenForEvent( "onhitother", KtnHitOtherForK)

        local player = owner 
        if not player.dlindex then 
               player.dlindex = SpawnPrefab("ktnfx")
               player:AddChild(player.dlindex) player.dlindex.Transform:SetPosition(.6, 0, 0)
                   local ixa = player.dlindex.AnimState player.dlindex.Transform:SetScale(.2, .5, .5)
                         ixa:SetBank("archive_resonator")ixa:SetBuild("archive_resonator")
                         ixa:PlayAnimation("idle_marker", true)  ixa:SetDeltaTimeMultiplier(0.3)
                         ixa:SetOrientation( ANIM_ORIENTATION.OnGround )
                         ixa:SetBloomEffectHandle("shaders/anim.ksh")
               player.dlindex:Hide()
            player.dlindex:DoPeriodicTask(FRAMES,function()
                    if not Exist(player) then 
                           player.dlindex:Remove() player.dlindex = nil 
                    return end
                         local rot = player.Transform:GetRotation()
                if player.dlindex then 
                   player.dlindex.Transform:SetRotation(math.abs((rot)*0.01)-90)

                    if inst.showktnindex and not owner.showdirectindex then 
                       inst.showktnindex = nil
                       --player.components.talker:Say(player.sg.currentstate.name)
                        if player.dlindex.shown then
                           player.dlindex:Hide() player.dlindex.shown = nil 
                        else
                           player.dlindex:Show() player.dlindex.shown = true 
                        end
                    elseif owner.showdirectindex then inst.showktnindex = true 
                    end
                end
            end) 
        end
    end

    local function OnUnequip(inst, owner)
        owner:RemoveTag("controllerktnlock")
        owner.AnimState:Hide("ARM_carry")
        owner.AnimState:Show("ARM_normal")
        if not owner.sg then return end
        niltask(owner,"taidaoxia")
        owner:AddTag("ktn_"..owner.name)
        owner:RemoveTag("taidaoxia")
        owner.taidao = nil
        --if owner.components.playeractionpicker then
           --owner.components.playeractionpicker:PopActionFilter(tdcontrol)end

        if inst.stronggrip then
            --owner:RemoveTag("stronggrip")
            --inst.stronggrip = nil
        end
        if inst.yurri then
            owner:RemoveTag("yurri")
            inst.yurri = nil
        end

        removeallbench(owner)

        owner:RemoveEventCallback( "attacked", KtnBeAttacked)
        owner:RemoveEventCallback( "onKTNhitother", KtnHitOther)    
        owner:RemoveEventCallback( "onhitother", KtnHitOtherForK)

    if owner.dlindex then owner.dlindex:Remove() owner.dlindex = nil end
    if owner.sg:HasStateTag("ktnsg") and not inst.needue then

        if not owner.sg:HasStateTag("modao")then
        inst:DoTaskInTime(.1,function()
            if owner == inst.components.inventoryitem.owner then
        --havnt come out a idle about punishment
        isay(owner,(MOD_KTN_LANGUAGE_SETTING and '那是个严重的错误')or "That's a serious mistake")
            end
          end)
        end
        if owner.sg:HasStateTag("denlong") then
        owner.sg:GoToState("hitfall")
        else owner.sg:GoToState("hit") end 

    end
        inst.needue = nil
    end

    local function onattack(inst, owner, target)  
        if inst ~= nil then
            if inst.components.sharpness then
                inst.components.sharpness:Consume()
            end
        end
    end

local function fn(sim)
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()


    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", nil, 0.75)

    anim:SetBank("LongSword")
    anim:SetBuild("LongSword")
    anim:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("LongSword")

    inst.currentSharpPercent = net_float(inst.GUID, "currentSharpPercent")
    inst.currentSharpPercent:set(0)      
    inst.currentQrPercent = net_float(inst.GUID, "currentQrPercent")
    inst.currentQrPercent:set(0)   

    if not TheWorld.ismastersim then
       return inst
    end
    inst.entity:SetPristine()

    inst:AddComponent("sharpness")
    inst.components.sharpness:SetStatesInit("white")

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.KTNDAMAGE) --always change

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "LongSword"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/LongSword.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    inst:AddComponent("edgerank")

inst:DoPeriodicTask(.1,function() local player = inst.components.inventoryitem.owner  
    if player and player.components.inventory then
    local other = player.components.inventory:FindItem(function(item) return item.components.edgerank and item ~= inst end)
    if other then  player.components.inventory:DropItem(inst) isay(player,(MOD_KTN_LANGUAGE_SETTING and '我已经有一把了')or "I already got one")
       end
    end
 end)


    MakeHauntableLaunch(inst)

    return inst
end
return  Prefab("common/inventory/longsword", fn, assets, prefabs)
