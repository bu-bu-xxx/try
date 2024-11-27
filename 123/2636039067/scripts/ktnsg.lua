
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

local function Exist(tar,candeath)
  return tar and tar:IsValid() and ((tar.components.health and not tar.components.health:IsDead() and not tar:HasTag("playerghost")) or candeath)
end
local function IsLife(tar,nowalk)
  return tar.components.combat and tar.Physics and(nowalk or tar.components.locomotor) and tar.components.health and not tar.components.health:IsDead()
end
local function niltask(inst,task)
 if inst[task] then inst[task]:Cancel() inst[task] = nil end
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
local function createlight(inst,color,speed,delay,rangebt)
        local stafflight = SpawnPrefab("ktnfx")
              inst:AddChild(stafflight)
              stafflight:SetUpLight({ color.x / 255, color.y / 255, color.z / 255 }, speed, delay, rangebt)
              stafflight:PushEvent("setupdirty")
end
local function OnchangeQrc(player,qrc)
    local active = (player:HasTag("ktnactive") and "_active") or ""
    local level = (player:HasTag("rankwhite") and "_1") or(player:HasTag("rankyellow") and "_2") or(player:HasTag("rankred") and "_3") or""
    local n = player.qrnum or .5
    qrc.animstate:SetPercent("idle"..active..""..level.."",n)
end

local function changerot(inst,limit,back)
    niltask(inst,"rotchanget")
    inst.rcautoshutdown = inst:DoTaskInTime(.16,function() niltask(inst,"rotchanget") end)
    inst.rotchanget = inst:DoPeriodicTask(.01,function()
	if inst.td_heading then
	   inst.ktn_rotchange = false 
	   local n = (back and 180) or 0
	   limit = limit or 360
	   local er = inst.td_heading
	   er = (er< 0 and er+360) or er
	   local cr = inst.Transform:GetRotation() +n
	   cr = (cr< 0 and cr+360) or cr
	   local dtrot = cr-er

	   if (dtrot)^2<=(limit)^2 then
	   inst.Transform:SetRotation(er+n) 
	   else
       local res_dt = ((dtrot<=0 and limit )or(-limit)) or 0
       res_dt = (((cr>265 and er<95 )or (er>265 and cr<95)) and -res_dt) or res_dt --because 1>360
       inst.Transform:SetRotation(cr+n+res_dt) 
       	   	   --inst.components.talker:Say(''..cr..', , ,'..er..', , ,'..res_dt..'')
	   end
	   niltask(inst,"rcautoshutdown")
       niltask(inst,"rotchanget")
	end
  end)
end

local function sizev(targ)
    return (Exist(targ,true) and (targ:HasTag("insect") and 0.25) or (targ:HasTag("smallcreature") and 0.5) or (targ:HasTag("largecreature") and 1.25) or (targ:HasTag("epic") and 1.5)) or 1
end

local function crefx(target,bank,build,idle,s,child,rot,fn,ongorund,ptrevise)
	    local pt = target:GetPosition()
        local rot = rot or 0
	    local ptrevise = ptrevise or Vector3(0,0,0)
        local ab = SpawnPrefab("ktnfx") ab.Transform:SetPosition(pt.x+ptrevise.x, pt.y+ptrevise.y, pt.z+ptrevise.z)
              ab.AnimState:SetBank(bank) ab.AnimState:SetBuild(build) ab.AnimState:PlayAnimation(idle)
        local s = s or Vector3(1,1,1)
              ab.Transform:SetScale(s.x, s.y, s.z)     
              ab.AnimState:SetFinalOffset(3)
              if child then
              target:AddChild(ab) ab.Transform:SetPosition(0+ptrevise.x,0+ptrevise.y, 0+ptrevise.z)	end
              if ongorund then
              ab.AnimState:SetOrientation(GLOBAL.ANIM_ORIENTATION.OnGround) 
              ab.AnimState:SetLayer(GLOBAL.LAYER_BACKGROUND) end
              ab:ListenForEvent("animover", ab.Remove)
              ab.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
              local rota = target.Transform:GetRotation()
              if ongorund then
                ab.Transform:SetRotation(math.abs(rota*0.01)+rot)
            else
                ab.Transform:SetRotation(rota+rot) end
              if fn then fn(ab) end
end

    local function flash(inst,bt)
        local bt = bt or 1
        for i, v in ipairs(AllPlayers) do
            local distSq = v:GetDistanceSqToInst(inst)
            local k = math.max(0, math.min(1, distSq / 400))
            local intensity = k * 0.5 * bt * (k - 2) + 0.75 
            if intensity > 0 then
                v:ScreenFlash(intensity)
            end
        end
    end

    local function spawndlzhitfx(inst,target,dlz)
            if not IsLife(target,true) then return end
            createlight(target,Vector3(248,248,255),.25)  
            local si = target.Transform and target.Transform:GetScale() or 1
            local ab = SpawnPrefab("ktnfx") target:AddChild(ab) 
            local extrabt = dlz and 9 or 3
            if type(target:GetPhysicsRadius(0)) == "number" and target:GetPhysicsRadius(0)>0 then 
             ab.Transform:SetPosition(.5,math.random(0.1 + extrabt*target:GetPhysicsRadius(0)^0.5/si),0)
            else
             ab.Transform:SetPosition(.5,math.random(extrabt*0.5/si),0)
            end
              ab.AnimState:SetBank("moonglass_charged") ab.AnimState:SetBuild("moonglass_charged_tile") ab.AnimState:PlayAnimation("explosion")
              ab.Transform:SetScale(.23/si, 6/si, .23/si)     
              ab.AnimState:SetFinalOffset(1)
              ab.AnimState:SetDeltaTimeMultiplier(.7)  
              ab.AnimState:SetOrientation(GLOBAL.ANIM_ORIENTATION.OnGround)
              --ab.AnimState:SetLayer(GLOBAL.LAYER_BACKGROUND)
              ab:ListenForEvent("animover", ab.Remove)
              ab.AnimState:SetMultColour(233/255,23/255,0/255,1)
              ab.Transform:SetRotation(math.abs(target.Transform:GetRotation()*0.01)+math.random(45) - math.random(45))
                  if target.SoundEmitter then
                     local n = {1,2,3,4,5}
                     if target.SoundEmitter then
                        target.SoundEmitter:PlaySound("longsword/katana/ktnhit_"..n[math.random(#n)]) 
                     end
                  end
end

local doatttack = function(player,targ,bt,special) --from component.combat
      local bt = bt or 1
if not Exist(targ) then return end
local kls = FindEntity(targ, 7, function(a) local ac = a.components return IsLife(a) and a.prefab == "klaus" and ((ac.combat.target and ac.combat.target:HasTag("player")) or not ac.combat.target) end) 
if kls and  (targ.prefab == "deer_red" or targ.prefab == "deer_blue") then return end
if targ.prefab == "lavae" and not (special and special>1) then
   targ.components.health:Kill()  
   local fx = SpawnPrefab("explode_small")
   fx.Transform:SetPosition(targ.Transform:GetWorldPosition())
   fx:AddComponent("explosive")
   fx.components.explosive.explosivedamage = 10
   fx.components.explosive:OnBurnt()
 return end

  local self = player.components.combat
  if not (targ.components and targ.components.health) then return end

      self.inst:PushEvent("onattackother", { target = targ, weapon = weapon, projectile = nil, stimuli = stimuli })
      spawndlzhitfx(inst,targ,special and special>2)

        local weapon = self:GetWeapon() local stimuli = nil
        if weapon ~= nil and weapon.components.weapon ~= nil and weapon.components.weapon.overridestimulifn ~= nil then
            stimuli = weapon.components.weapon.overridestimulifn(weapon, player, targ)
        end
        if stimuli == nil and player.components.electricattacks ~= nil then
            stimuli = "electric"
        end
    local reflected_dmg = 0 local reflect_list = {}
    if targ.components.combat ~= nil then
        local mult =
            (stimuli == "electric" or
                (weapon ~= nil and weapon.components.weapon ~= nil and weapon.components.weapon.stimuli == "electric")
            )
            and not (targ:HasTag("electricdamageimmune") or(targ.components.inventory ~= nil and targ.components.inventory:IsInsulated()))
            and TUNING.ELECTRIC_DAMAGE_MULT + TUNING.ELECTRIC_WET_DAMAGE_MULT * (targ.components.moisture ~= nil and targ.components.moisture:GetMoisturePercent() or (targ:GetIsWet() and 1 or 0))
            or 1
        local dmg = self:CalcDamage(targ, weapon, mult) * (instancemult or 1) *bt *1.2 --now ktn has extra 1.2 damage
        local shakebt = dmg/(72*bt)
        local shakebt = shakebt <3 and shakebt*bt or 3*bt
 if not player.sg:HasStateTag("noshakesg") then
    ShakeAllCameras(CAMERASHAKE.VERTICAL, .1*shakebt, .1, .1*shakebt, player, .5) end
 if not (player.sg:HasStateTag("nokarousg") or (special and special == 7)) then
    local recordsg = player.sg.currentstate.name
  player:DoTaskInTime(1*FRAMES,function()
    niltask(player,"sghitexcite")  
    local tk = GetTime()
    player.karoustop = true
    player.AnimState:SetDeltaTimeMultiplier(.01)  --first hit it,slow down
    player.sghitexcite = player:DoPeriodicTask(FRAMES,function()
        if player.karoustop and player.sg then 
           player.Physics:ClearMotorVelOverride() 
           player.Physics:Stop()
           player.sg.lastupdatetime = player.sg.lastupdatetime+FRAMES
        end
     if player.sg.currentstate.name == recordsg then  
        if GetTime() - tk >9*shakebt*FRAMES then --auto stop
        niltask(player,"sghitexcite") player.karoustop = nil
        player.AnimState:SetDeltaTimeMultiplier(1)      
        elseif GetTime() - tk >3*shakebt*FRAMES then --aft .15 sec
        player.karoustop = nil
        player.AnimState:SetDeltaTimeMultiplier(1)  
        end
     else niltask(player,"sghitexcite") player.AnimState:SetDeltaTimeMultiplier(1)player.karoustop = nil
     end  
    end)
   end)
  end

        targ.components.combat:GetAttacked(player, dmg, weapon, stimuli)
        player:PushEvent("onKTNhitother", { damage = dmg,target = targ,weapon = weapon,attacker = player })
    end
    if weapon and weapon.components.weapon.onattack ~= nil  then
        weapon.components.weapon.onattack(weapon, player, targ)
    end
    if self.areahitrange ~= nil and not self.areahitdisabled then
        self:DoAreaAttack(targ, self.areahitrange, weapon, self.areahitcheck, stimuli, AREA_EXCLUDE_TAGS)
    end
    self.lastdoattacktime = GetTime()
    if reflected_dmg > 0 and player.components.health ~= nil and not player.components.health:IsDead() then
        self:GetAttacked(targ, reflected_dmg)
        for i, v in ipairs(reflect_list) do
            if Exist(v.inst,true) then
                v.inst:PushEvent("onreflectdamage", v)
            end
        end
    end
    return reflected_dmg
end

local function rangeatk(inst,range,time,bt,other) 
	inst.ktnatktar = {}
	local bench = other or inst.ktnbench
	local td = inst.taidao
	inst.rangeatktime = GetTime() 
    local recordsg = inst.sg.currentstate.name
	niltask(inst,"continuityatk")
	if not Exist(bench,true) then return end

    inst.continuityatk = inst:DoPeriodicTask(FRAMES,function()
    if inst.karoustop then inst.rangeatktime = inst.rangeatktime+FRAMES return end
  	   local checktime = GetTime()-inst.rangeatktime 
        if inst.sg.currentstate.name ~= recordsg then niltask(inst,"continuityatk") return end
        if checktime >= time then niltask(inst,"continuityatk") return end

		local pt = Vector3(bench.Transform:GetWorldPosition() )local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, 7)
        for k,v in ipairs(ents) do 
        local fr = v.components.follower local wb = v.components.workable local cb = v.components.combat
        local newrange = v:GetPhysicsRadius(0) + range
        --if distsq(v:GetPosition(), bench:GetPosition()) <= range^2 then 
        	if wb and wb.action == ACTIONS.CHOP and not ThIsInList(v,inst.ktnatktar) and not v:HasTag("gesplant") and Exist(bench,true) and bench:IsNear(v, newrange) and not inst.karoustop then
        		local rk = (td and td.components.edgerank.rank) or 0
        		wb:WorkedBy(inst,rk) table.insert(inst.ktnatktar,v)
                if v:HasTag("mushroomsprout") then SpawnPrefab("channel_absorb_fire").Transform:SetPosition(v.Transform:GetWorldPosition()) wb:Destroy(inst) v.AnimState:PlayAnimation("burnt_chop") end
                if td and td.components.sharpness then 
                   inst.modaot = 4 
                   td.components.sharpness:Consume() 
                end
        	end
            local itemfollower = inst.components.inventory:FindItem(function(a)return fr and fr.leader and fr == a end)
            if (cb and cb.target and cb.target==inst) or not(fr and fr.leader and fr.leader:HasTag("player")) and not (v.prefab == "beefalo" and v.components.follower:GetLeader())
       and not v:HasTag("wall") and not v:HasTag("abigail") and not v:HasTag("player")and not v:HasTag("companion") then
             if not itemfollower and not (cb and cb.target and cb.target:HasTag("ktn_tagenemy")) then
               if IsLife(v,true) and inst.components.combat:CanTarget(v) and Exist(bench,true) and bench:IsNear(v, newrange) then
         	      if not ThIsInList(v,inst.ktnatktar) and not (cb.target and cb.target.components.combat and cb.target.components.combat.target and 
      (cb.target.components.combat.target:HasTag("player") or cb.target.components.combat.target:HasTag("companion"))) then

                     table.insert(inst.ktnatktar,v)
                     doatttack(inst,v,bt)

                     if inst.sg:HasStateTag("juheS") then --xjh
                        if Exist(td,true) then 
                           if td.components.edgerank.qiren<.1 then td.components.edgerank:QrDoDelta(.04) end
                           td.components.edgerank:ActiveQr() end
                     end
         	               if inst.sg:HasStateTag("edgeing") then --qrdhx
                              inst.qrdhxhit = true
         	               	  if v.sg and (v.sg:HasStateTag("attack")or v.sg:HasStateTag("charge") or v.sg.statemem.target or v.sg:HasStateTag("atk_pre")) then v.sg:GoToState("hit") end
         	                  v.components.combat:RestartCooldown()
         	               end
         	      	       if inst.sg:HasStateTag("juheL") then --djh need more damage
                              local penh = (Exist(inst.djhpt,true) and inst.djhpt.components.health and inst.djhpt.components.health.maxhealth) or 0
                              if (v.components.health and v.components.health.maxhealth) > penh then
      	                	      inst.djhpt = v end
                               v.djhmoredam = true
      	                   end
                    end
                  end
               end
            end
        end
    end)

end

local function ktnatk(inst,range,bt,other)
	local bench = other or inst.ktnbench
	if not bench then return end
	local pt = Vector3(bench.Transform:GetWorldPosition() )local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, 7)
    for k,v in pairs(ents) do local fr = v.components.follower local cb = v.components.combat
      if (cb and cb.target and cb.target==inst) or not(fr and fr.leader and fr.leader:HasTag("player"))and not (v.prefab == "beefalo" and v.components.follower:GetLeader())
      and not v:HasTag("wall") and not v:HasTag("abigail") and not v:HasTag("player")and not v:HasTag("companion") then 
         if not (cb and cb.target and cb.target.components.combat and cb.target.components.combat.target and 
      (cb.target.components.combat.target:HasTag("player") or cb.target.components.combat.target:HasTag("companion"))) then --enmey's enmey is my friend

         local newrange = v:GetPhysicsRadius(0) + range

        if IsLife(v,true) and inst.components.combat:CanTarget(v) and Exist(bench,true) and bench:IsNear(v, newrange) then
         local t = (inst.sg:HasStateTag("denlongzhan") and .9) or 0  
         local times = (inst.sg:HasStateTag("denlongzhan") and 7) or 1
        inst:DoTaskInTime(t,function()
            inst:StartThread(function()
                for k = 1, times do
      	    doatttack(inst,v,bt,times) 
            if times == 7 then  end
                 Sleep(2*FRAMES)
                end
            end) 
      	end)
      		    local td =inst.taidao
      	       if inst.jqdodgeit then --jq need kr
      	       	  inst.jqhitit = true inst.jqdodgeit = nil
      	       	  if Exist(td,true) then td.components.edgerank:QrDoDelta(.8) end
      	       end
               if inst.noqrjq then
                  if Exist(td,true)  then td.components.edgerank:QrDoDelta(.1) end
               end
               if inst.sg:HasStateTag("denlongzhan") then
               if Exist(td,true)  then td.components.edgerank:ActiveQr() end 
        --local s = sizev(v) crefx(v,"qr_fx","qr_fx","dlz",Vector3(s, s, s),true,0,function(ab) 
        --ab.AnimState:SetDeltaTimeMultiplier(1.6)end,nil,Vector3(0, .6, 0)) 
                  inst.taidao.components.edgerank:QrDoDelta(.07) 
                  local penh = (Exist(inst.dlzpt,true) and inst.dlzpt.components.health and inst.dlzpt.components.health.maxhealth) or 0
                  if (v.components.health and v.components.health.maxhealth) > penh then
                     inst.dlzpt = v end
                  end
               end
      	end
      end
    end
end

local ding = function(inst,sg,bt,type,tar)
     if type == 0 then return end
     if inst.hasbocked then return end
     local pt = Vector3(inst.Transform:GetWorldPosition() )local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, 12)
          for k,v in pairs(ents) do
            if v.jqothercon and v~=inst then v.areading = true end
          end
        inst.hasbocked = true
        inst.components.health.externalabsorbmodifiers:SetModifier(inst, .8,"ktn_jiahu")
        inst.sg.statemem.btbyxg = nil
        inst.sg:AddStateTag("drowning")
        inst.sg:AddStateTag("transform") --to suit 智能敌对
        inst:AddTag("fat_gang") -- to suit 永不妥协
        inst.removedrownoutinv = nil
        if inst.removefatgoutinv then inst.delayremovefatg = true end
        inst.SoundEmitter:PlaySound("longsword/katana/ding")
        local sh = SpawnPrefab("ktnfx")
        local str = tar and tar.entity and tar.entity:GetDebugString()
    if str then
        local sh2 = SpawnPrefab("ktnfx")
        local bank,build,anim = str:match("bank: (.+) build: (.+) anim: .+:(.+) Frame")
        if bank and build and anim then
        sh2.AnimState:SetBank(bank) 
        sh2.AnimState:SetBuild(build)
        sh2.AnimState:SetPercent(anim,.6+math.random()*.2) 
        sh2.Transform:SetRotation(tar.Transform:GetRotation())   
        sh2.Transform:SetPosition(tar.Transform:GetWorldPosition())
        sh2.Transform:SetScale(tar.Transform:GetScale())
        sh2.Transform:SetFourFaced()
        sh2:AddComponent("colourtweener") 
        sh2.components.colourtweener:StartTween({0,0,0,0},1,sh2.Remove) 
        end
    end
        sh.AnimState:SetBank("wilson")         
        sh.AnimState:SetBuild(inst.prefab)
        sh.AnimState:OverrideSymbol("swap_object", "swap_LongSword", "swap_Katana")
        sh.AnimState:Show("ARM_carry")
        sh.AnimState:Hide("ARM_normal")
        sh.AnimState:SetPercent(sg,bt) 
        sh.Transform:SetRotation(inst.Transform:GetRotation())   

        if Exist(inst.setenity,true) then
        sh.Transform:SetPosition(inst.setenity.Transform:GetWorldPosition()) 
        else sh.Transform:SetPosition(inst.Transform:GetWorldPosition()) end
        sh.Transform:SetFourFaced()
        sh.AnimState:SetMultColour(0/255, 0/255, 0/255, .7)
        sh:AddComponent("colourtweener") 
        sh.components.colourtweener:StartTween({0,0,0,0},1.6,sh.Remove) 


        if type == 1 then --jq
        inst.jqdodgeit = true
        --inst.components.sanity:DoDelta(1) 
        elseif type == 2 then  --djh
        if inst.djhqrlevel and inst.djhqrlevel > 2 then flash(inst) end
        inst.djhdodgeit = true
        --inst.components.sanity:DoDelta(2) 
        elseif type == 3 then  --xjh
        inst.components.sanity:DoDelta(3) 
        end
end
local function ktnding(inst,tar)
        local type = inst.ktninvtype
        sg = (type==1 and "jianqie_pre" ) or (type==2 and "juheqiren") or "juhetabu"
        bt = (type==1 and .9 ) or (type==2 and .5) or .3
    ding(inst,sg,bt,type,tar)
end
local function Yawnding(inst,tar)
     ktnding(inst,tar)
end
local function fx_hitktn(inst,data) 
     ktnding(inst,data.attacker)
end 

local function canceljq(inst)
    inst.ktninvtype = nil inst:RemoveTag("ktninvincible")
    if inst.removefatgoutinv then
       inst.removefatgoutinv = nil
       if not inst.delayremovefatg then 
          inst:RemoveTag("fat_gang")  end end
    if inst.removedrownoutinv then inst.sg:RemoveStateTag("drowning") inst.removedrownoutinv = nil end
    if inst.removesmallcre then inst:RemoveTag("smallcreature") inst.removesmallcre = nil end
    inst.sg:RemoveStateTag("sleeping")
    if inst.sleepingbag then inst.sleepingbag:Remove() inst.sleepingbag = nil end
    inst:RemoveEventCallback("ktnblocked", fx_hitktn)
    inst:RemoveEventCallback("yawn", Yawnding)
          local pt = Vector3(inst.Transform:GetWorldPosition() )local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, 16)
    for k,v in pairs(ents) do local cbt = v.components.combat
       if cbt and v.cbt_range then 
           cbt.hitrange = v.cbt_range v.cbt_range = nil
           
       end
    end

        local inv = inst.components.inventory
        if inv and inv.equipslots then 
          for k,v in pairs(inv.equipslots) do local am = v.components.armor
            if am and v.amabsorb_percent then
             am.absorb_percent = v.amabsorb_percent v.amabsorb_percent = nil
            end
            if v.retgf then v:RemoveTag("forcefield") v.retgf = nil end
           end
         end
                 if Exist(inst.setenity,true) then 
                 inst.setenity:Remove() inst.setenity = nil end
                 if inst.ktnunfreez then 
                 inst.components.freezable:SetResistance(inst.ktnunfreez)
                 inst.ktnunfreez = nil end
                 if inst.ktnunsleep then 
                 inst.components.grogginess:SetResistance(inst.ktnunsleep)
                 inst.components.grogginess.isgroggy = false
                 inst.ktnunsleep = nil  end
                 if inst.ktninvincible then inst.ktninvincible = nil end
                 if inst.ktncantbepine then inst.ktncantbepine = nil
                 inst.components.pinnable.canbepinned = true  end
                 if inst.jqothercon then inst.jqothercon:Cancel() inst.jqothercon = nil end   
                 if inst.ktnindex then inst.ktnindex:Remove() inst.ktnindex = nil end
end

local function tdinvincible(inst,type)
        inst.ktninvtype = type
        sg = (type==1 and "jianqie_pre" ) or (type==2 and "juheqiren") or "juhetabu"
        bt = (type==1 and .9 ) or (type==2 and .5) or .27

        inst.ktninvincible = true 
        inst:AddTag("ktninvincible")
        inst:ListenForEvent("ktnblocked", fx_hitktn, inst)

	    inst.alldebuffs = {} 
        for k,v in pairs(inst.components.debuffable.debuffs) do 
        if v then table.insert(inst.alldebuffs,v) end end 
        inst.ktnnowtemp = inst.components.temperature:GetCurrent() or 15

        if type == 1 then --jq
        --inst.components.sanity:DoDelta(-5)
        elseif type == 2 then --djh

        elseif type == 3 then --xjh

        end
        local nowfreezcold = inst.components.freezable.coldness or 0
        local nowsleep = inst.components.grogginess.grog_amount or 0

        inst:ListenForEvent("yawn",Yawnding)


        inst.startwithbrunt = inst.components.burnable and inst.components.burnable:IsBurning()
        if inst.components.freezable.resistance then --for freez
        inst.ktnunfreez = inst.components.freezable.resistance or 1
        inst.components.freezable:SetResistance(99)
        inst.sg:AddStateTag("nofreeze") end
        if inst.components.grogginess.resistance then --for sleep
        inst.ktnunsleep = inst.components.grogginess.resistance or 1
        inst.components.grogginess.isgroggy = true
        inst.components.grogginess:SetResistance(99)
        inst.sg.statemem.btbyxg = nil
        if not inst:HasTag("smallcreature") then inst:AddTag("smallcreature") inst.removesmallcre = true end
        if not inst:HasTag("fat_gang") then inst:AddTag("fat_gang") inst.removefatgoutinv = true end
        if not inst.sg:HasStateTag("drowning") then inst.sg:AddStateTag("drowning") inst.removedrownoutinv = true end
        inst.sleepingbag = CreateEntity() inst.sleepingbag:AddComponent("sleepingbag") --Genius 
        inst.sg:AddStateTag("sleeping") end

        inst.hasbocked = nil
        if inst.components.pinnable.canbepinned then 
        inst.ktncantbepine = true inst.components.pinnable.canbepinned = false end

        local inv = inst.components.inventory
        if inv and inv.equipslots then 
          for k,v in pairs(inv.equipslots) do local am = v.components.armor
            if am then
             v.amabsorb_percent = am.absorb_percent am.absorb_percent = 0 
            end
            if not v:HasTag("forcefield") then 
             v:AddTag("forcefield") v.retgf = true 
            end
          end
        end

        if Exist(inst.setenity,true) then inst.setenity:Remove() inst.setenity = nil end     
        local ab = SpawnPrefab("ktnfx") ab.Transform:SetPosition(inst.Transform:GetWorldPosition())
        ab:AddComponent("health") ab.components.health:SetMaxHealth(100) 
        ab:AddComponent("combat") ab:AddComponent("locomotor") 
        ab:AddTag("companion")ab:AddTag("monster")ab:AddTag("character") ab:AddTag("_combat") 
        ab:RemoveTag("FX") ab:RemoveTag("NOCLICK") ab:RemoveTag("INLIMBO") ab:SetStateGraph('SGcattoy_mouse')
        inst.setenity = ab --ab:AddChild(SpawnPrefab("flower"))
        ab.Physics:ClearCollisionMask() ab:AddTag("smallcreature")
        ab:DoPeriodicTask(.1,function() 
           local projec = FindEntity(ab, 1, function(a) local ac = a.components return ac.projectile or ac.complexprojectile end) 
              if projec then projec:Remove() ding(inst,sg,bt,type) end 
           local curse = FindEntity(ab, 3, function(a) local ac = a.components return a.prefab == "cursed_monkey_token" and ac.inventoryitem and not ac.inventoryitem.owner end) 
              if curse then curse:Remove() ding(inst,sg,bt,type) end 
        end)
        ab:ListenForEvent("attacked", function() ding(inst,sg,bt,type) end)

        if not inst.ktnindex then 
        local ab = CreateEntity() ab:AddTag("FX")
        ab.entity:AddTransform() ab.entity:AddAnimState()
        inst:AddChild(ab) ab:Hide() 
        ab.Transform:SetPosition(1, 0, 0) inst.ktnindex = ab         

        end

        if not inst.jqothercon then 
            inst.jqothercon = inst:DoPeriodicTask(FRAMES,function()
        if inst.components.inkable and inst.components.inkable.inktime > 0 then inst.components.inkable.inktime = 0 ding(inst,sg,bt,type) end
        if inst.areading then inst.areading = nil if not inst.hasbocked then ding(inst,sg,bt,type) end end

        if not inst.startwithbrunt and inst.components.burnable and inst.components.burnable:IsBurning() then inst.components.burnable:Extinguish()ding(inst,sg,bt,type) end --cant burning

        if inst.components.temperature:GetCurrent() > inst.ktnnowtemp+15 or inst.components.temperature:GetCurrent() < inst.ktnnowtemp-15 then  
        inst.components.temperature:SetTemperature(inst.ktnnowtemp)ding(inst,sg,bt,type) end --temperature changes dramatically

        if inst.components.freezable.coldness > nowfreezcold then inst.components.freezable.coldness = nowfreezcold ding(inst,sg,bt,type) end -- cant be freeze

        if inst.components.grogginess.grog_amount > nowsleep then inst.components.grogginess.grog_amount = nowsleep ding(inst,sg,bt,type) end -- cant sleep

local pt = Vector3(inst.Transform:GetWorldPosition() )local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, 12)
          for k,v in pairs(ents) do local cbt = v.components.combat
            if cbt and cbt.target and cbt.target == inst then 

              if v.sg and v.sg.currentstate.name == "snare" and v.sg.statemem.targets then -- stalker snare
              for p,i in pairs(v.sg.statemem.targets) do if i == inst then table.remove(v.sg.statemem.targets,p) end end
              v:DoTaskInTime(0.1,function() ding(inst,sg,bt,type) end)  
              end
              if v.sg and v.sg.currentstate.name == "attack_chomp" and v.sg.statemem.target and v.sg.statemem.target == inst then -- klaus chomp
                 if v.sg.statemem.jump then v.doajump = true 
                    if not v.checkclosedoajump then
                       v.checkclosedoajump = v:DoPeriodicTask(.1,function() if not(v.sg and v.sg.currentstate.name == "attack_chomp") or not v.doajump then v.doajump =nil niltask(v,"checkclosedoajump") end end)
                    end
                 end
              end
              if v.doajump and not (v.sg and v.sg.statemem and v.sg.statemem.jump) then 
                 ding(inst,sg,bt,type) v.doajump = nil
              end

              if v.CanDisarm and v.sg and v.sg.currentstate.name == "disarm" and cbt.target then -- guess moose
              cbt:SetTarget(nil) 
              v:DoTaskInTime(0.1,function() ding(inst,sg,bt,type)
              if not cbt.target then cbt:SetTarget(inst) end end)  
              end

              if v.sg and v.sg:HasStateTag("snare") and cbt.target then -- For Uncompromise mod's leif
                 v.sg.statemem.target = nil
                 ding(inst,sg,bt,type)
                 if v.oldrange then v.components.combat:SetRange(v.oldrange) end
              end

              inst.nowalldebuffs = {}  --To deal with toadstool
              for k,x in pairs(inst.components.debuffable.debuffs) do 
              inst.nowalldebuffs[x] = k end 
              for k,z in pairs(inst.alldebuffs) do 
              inst.nowalldebuffs[z] = nil end
              for k,y in pairs(inst.nowalldebuffs) do 
                if y then ding(inst,sg,bt,type) 
              local debuff = inst.components.debuffable.debuffs[y]
              debuff.inst:Remove() 
              --inst.components.debuffable:RemoveDebuff(y) 
                end
              end
            end
          end
        end) end

end

local function qichangcool(inst,range,bt,where)
    local bt = bt or 1  local range = range or 2  local where = where or inst
    local tdn = inst.taidao and inst.taidao.components.edgerank.rank
    if not tdn then return end
    if tdn<3 and range <4 then return end --if u are not red edge, range must up to 4
    local tdbt = (1+tdn)/4
    local pt = Vector3(where.Transform:GetWorldPosition() )local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, range*math.sqrt(tdbt))
    for k,item in pairs(ents) do
     if item.components.inventoryitem and not item.components.inventoryitem.owner and item.components.inventoryitem.canbepickedup then
        if item and item.Physics and not item.isinblowaway then
        item.isinblowaway = true item:DoTaskInTime(1.4,function()item.isinblowaway=nil end)
        local dissq = math.sqrt(item:GetDistanceSqToInst(inst))
        item:DoTaskInTime(dissq*.1*bt^2,function()
        local x, y, z = item:GetPosition():Get()
        y = .1
        item.Physics:Teleport(x,y,z)
        local hp = item:GetPosition()
        local pt = inst:GetPosition()
        local vel = (hp - pt):GetNormalized()
        local speed = 2+(4-dissq*.75)*bt*tdbt
        local angle = math.atan2(vel.z, vel.x) 
        item.Physics:SetVel(math.cos(angle) * speed, speed*1.5, math.sin(angle) * speed) end)
        end
      end
    end
end

local function jqsptk(inst,wt,sta,dt,m,pf,lorr) -- wt默认inst 无wt则取消位移； sta 一开始的速度 ； dt 增减矢量默认+； m 取1或-1决定速度方向；pf 对速度次方；
   if wt then
     niltask(inst,"jqbk") --覆盖
     local dt = dt/3
     local pf = pf or 1 local m = m or 1
     inst.jqsp = sta
     if not inst.jqbk then inst.jqbk = inst:DoPeriodicTask(FRAMES,function()
        if inst.karoustop then 
        inst.Physics:ClearMotorVelOverride() 
        else
     local n = inst.jqsp inst.jqsp = n+dt
     local speed = m*((n)^pf)
     local x = (not lorr and speed) or 0
     local z = (lorr and speed*lorr) or 0
     inst.Physics:SetMotorVelOverride(x,0,z)
        end
     end) end
        else 
      if inst.jqbk then inst.jqbk:Cancel() inst.jqbk = nil end 
         inst.Physics:ClearMotorVelOverride()
   end
end
AddStategraphState('wilson', 
  State{
    name = 'tandao',
    tags = {"nopredict",'busy',"tandao","ktnsg"},
    onenter = function(inst)
        inst.Physics:Stop()
        inst.components.locomotor:Clear()
        inst.AnimState:SetDeltaTimeMultiplier(1)  
        inst.AnimState:PlayAnimation("tandao")
        inst.SoundEmitter:PlaySound("dontstarve/wilson/use_pick_rock")
        createlight(inst.ktnbench_far,Vector3(248,248,255),.2,0)
        if inst.taidao then inst.taidao.components.edgerank:QrDoDelta(.1) end
    end,
    timeline={
            TimeEvent(0*FRAMES, function(inst) 
            jqsptk(inst,inst,3,-0.7,-1,2)
            end),
            TimeEvent(5*FRAMES, function(inst) 
            inst.SoundEmitter:PlaySound("longsword/katana/zayin2","ktnzayin")
            end), 
            TimeEvent(12*FRAMES, function(inst) 
            jqsptk(inst)
            inst.Physics:ClearMotorVelOverride() 
            end), 
    },     
                events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    onexit = function(inst) 
    jqsptk(inst)
    inst.AnimState:SetDeltaTimeMultiplier(1)  
    end,
})
AddStategraphState('wilson', 
  State{
    name = 'sharpen_pre',
    tags = {"nopredict",'busy',"modao","ktnsg"},
    onenter = function(inst)
        inst.Physics:Stop()
        inst.components.locomotor:Clear()
        inst.AnimState:SetDeltaTimeMultiplier(1.4)  
        inst.AnimState:PlayAnimation("modao_pre")
        inst.SoundEmitter:PlaySound("longsword/katana/zayin2","ktnzayin")
    end,
    timeline={
    },     
                events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("sharpen")
                end
            end),
        },
    onexit = function(inst) 
    inst.AnimState:SetDeltaTimeMultiplier(1)  
    end,
})
AddStategraphState('wilson', 
  State{
    name = 'sharpen',
    tags = {"nopredict",'busy',"modao","ktnsg"},
    onenter = function(inst)
        inst.canuseevade = true
        inst.AnimState:SetDeltaTimeMultiplier(1.23)
        if not inst.modaot then inst.modaot = 4 end
        inst.AnimState:PlayAnimation("modao")
                    if Exist(inst.ktnmds,true) and inst.components.inventory:FindItem(function(v) return v== inst.ktnmds end) then 
                    else  inst.components.talker:Say((MOD_KTN_LANGUAGE_SETTING and '磨刀石不见了')or "WhetStone Disappear") 
                          inst.sg:GoToState("hit")
                    end
    end,
    timeline={
            TimeEvent(3*FRAMES, function(inst) 
            inst.modaot = (inst.modaot or 4) -1
            local n = {1,2}
            inst.SoundEmitter:PlaySound("longsword/katana/sharp_"..n[math.random(#n)])
            end),       
            TimeEvent(14*FRAMES, function(inst) 
            createlight(inst,Vector3(248,248,255),.25,.9)     
            end), 
            TimeEvent(16*FRAMES, function(inst) 
            local fx = SpawnPrefab("weaponsparks")
            fx.Transform:SetScale(.5, .4, .5)
            fx.entity:AddFollower()
            fx.Follower:FollowSymbol(inst.GUID, "swap_object", 0, -175, 0)
            end),
    },     
                events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.modaot and inst.modaot <= 0 then
                    inst.sg:GoToState("sharpen_noevadepst")
                    else
                    inst.sg:GoToState("sharpen") end
                end
            end),
        },
    onexit = function(inst) 
    inst.AnimState:SetDeltaTimeMultiplier(1)
    inst.canuseevade = nil
    end,
})
AddStategraphState('wilson', 
  State{
    name = 'sharpen_noevadepst',
    tags = {"autopredict",'busy',"modao","ktnsg"},
    onenter = function(inst)
        inst.modaot = nil
        inst.AnimState:PlayAnimation("modao_pst")
        crefx(inst,"crab_king_shine","crab_king_shine","shine",Vector3(.4,.4,.4),true,0,function(ab)
        ab.entity:AddFollower()
        ab.Follower:FollowSymbol(inst.GUID, "swap_object", 0, -270, 0) end)
        inst.SoundEmitter:PlaySound("longsword/katana/sharp_down")
    end,
    timeline={
            TimeEvent(4*FRAMES, function(inst) 
            end),
    },     
                events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    onexit = function(inst) 
            local td = inst.taidao
            if Exist(inst.ktnmds,true) and inst.components.inventory:FindItem(function(v) return v == inst.ktnmds end) then 
                if inst.ktnmds.prefab == "redgem" and math.random()<.8 then  
                else inst.ktnmds.components.stackable:Get():Remove() inst.ktnmds = nil end 
                if td and td.components.sharpness then td.components.sharpness:Recover() end 
                else  inst.components.talker:Say((MOD_KTN_LANGUAGE_SETTING and '磨刀石不见了')or "WhetStone Disappear") 
                      --inst.sg:GoToState("hit")
            end
    end,
})

local function juhelatk(inst,item)
    --createlight(item,Vector3(150,46,46),.5,0,1.5)
    local pt = Vector3(item.Transform:GetWorldPosition() )local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, 4.7)
              for k,v in pairs(ents) do 
                local wb = v.components.workable
            if wb and wb.action == ACTIONS.CHOP and not ThIsInList(v,inst.juheltar) and not v:HasTag("gesplant") then
                table.insert(inst.juheltar,v)
                wb:WorkedBy(inst,inst.djhqrlevel*3)
            end
                 if (v.djhmoredam or (v.components.combat and v.components.combat.target and v.components.combat.target == inst)) 
                and not ThIsInList(v,inst.juheltar) then v.djhmoredam = nil
                    local wpdm =(inst.taidao and inst.taidao.components.weapon.damage) or 36
                    local bt = (inst.djhtddg/wpdm)*(inst.djhqrdgbt^5)*1.35
                    doatttack(inst,v,bt,2) 
                    table.insert(inst.juheltar,v)
                 end
              end
end

AddStategraphState('wilson', 
  State{
    name = 'juhe_l',
    tags = {"busy", "juheL", "attack","nopredict","ktnsg","noshakesg","notandao"},
    onenter = function(inst)
        inst.juherotn = 0
        inst.Physics:Stop()
        inst.juheltar = {}
        inst.components.locomotor:Clear()
        changerot(inst,90)
        inst.AnimState:SetDeltaTimeMultiplier(1)  
        inst.AnimState:PlayAnimation("juheqiren")
        tdinvincible(inst,2)
        qichangcool(inst,7)
        inst.djhqrlevel = (inst.taidao and inst.taidao.components.edgerank.rank) or 0
        inst.djhtddg = (inst.taidao and inst.taidao.components.weapon.damage) or 36
        inst.djhqrdgbt = (inst.taidao and inst.taidao.components.edgerank.damagebt) or 1
        local s = math.sqrt(inst.djhqrlevel+1)/2
        inst.SoundEmitter:PlaySound("longsword/katana/djh")
        crefx(inst,"halloween_embers","halloween_embers","puff_2",Vector3(.2*inst.djhqrlevel,.2*inst.djhqrlevel,.2*inst.djhqrlevel),true,0,function(ab) 
            createlight(ab,Vector3(150,46,46),.1*inst.djhqrlevel) ab.AnimState:SetMultColour(255/255,0/255,0/255,.7) end)
    end,
    timeline={
    	TimeEvent(5*FRAMES, function(inst)
        qichangcool(inst,6)
        createlight(inst,Vector3(150,46,46),.6,0.1)
        local s = (inst.djhqrlevel >2 and .5) or 0
        crefx(inst,"qr_fx","qr_fx","hit",Vector3(s, s, s),nil,0,function(ab) 
        ab.entity:AddFollower()
        ab.Follower:FollowSymbol(inst.GUID, "swap_object", 0, -150, 0)
        ab.AnimState:SetFinalOffset(1)
        ab.Transform:SetTwoFaced()
        ab:FacePoint(inst.Transform:GetWorldPosition())
        end)
        inst.jhltime = 0
        niltask(inst,"juherot")
        local rot = inst.Transform:GetRotation()
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.WORLD)
        local t = 5.2
        inst.juherot = inst:DoPeriodicTask(2*FRAMES,function()
        if inst.juherotn >= 180 then
           niltask(inst,"juherot")
           inst.Physics:ClearMotorVelOverride()
           else
              if inst.karoustop then inst.Physics:ClearMotorVelOverride() 
              else
           inst.juherotn = inst.juherotn + 30
           t =t - .52
           local bit = inst.juherotn/90
           local bt = 1-bit
           local b = (bit<1 and bit) or 2-bit
           inst.Transform:SetRotation(rot+inst.juherotn)  
           inst.Physics:SetMotorVelOverride(6*bt*t,1,6*b*t) 
              end
           end
        end)
    	end),
    	TimeEvent(6*FRAMES, function(inst)
    	inst.djhpt = inst.ktnbench or inst
    	rangeatk(inst,4.2,.23,1.7,inst,2)
    	local pt = inst.djhpt:GetPosition()
    	GLOBAL.ShakeAllCameras(CAMERASHAKE.VERTICAL, .2*inst.djhqrlevel, .1, .27*inst.djhqrlevel, inst, 7*inst.djhqrlevel) 
        end), 
        TimeEvent(8*FRAMES, function(inst)
        canceljq(inst)
        end),
    	TimeEvent(9*FRAMES, function(inst)
        qichangcool(inst,5)
        if inst.djhdodgeit then local s = 0 crefx(inst,"qr_fx","qr_fx","dlz",Vector3(s, s, s),true,0,function(ab) 
        ab.AnimState:SetDeltaTimeMultiplier(1.6)
        end,nil,Vector3(0, .6, 0)) end
        end),  
        TimeEvent(18*FRAMES, function(inst)
        inst.sg:AddStateTag("nokarousg")
        if inst.djhqrlevel> 0 then  
        local qrtar = (Exist(inst.djhpt,true) and inst.djhpt) or inst
        local pt = inst.djhpt:GetPosition()
        local ab = SpawnPrefab("ktnfx") ab.Transform:SetPosition(pt.x, pt.y+2, pt.z)
              local bank = "moonglass_charged"  
              local build = "moonglass_charged_tile" 
              local idle = "explosion" 
              ab.AnimState:SetBank(bank) ab.AnimState:SetBuild(build) ab.AnimState:PlayAnimation(idle)
              ab.scals = 1 ab.Transform:SetScale(.27, 1, .27)
              ab:DoPeriodicTask(FRAMES,function() if ab.scals < 23 then ab.scals = ab.scals + 2 ab.Transform:SetScale(.27, ab.scals, .27)  else  end end)     
              ab.AnimState:SetFinalOffset(3)
              ab.AnimState:SetOrientation(GLOBAL.ANIM_ORIENTATION.OnGround)
              ab.AnimState:SetLayer(GLOBAL.LAYER_BACKGROUND)
              ab:ListenForEvent("animover", ab.Remove)
              ab.SoundEmitter:PlaySound("longsword/katana/djh_din")
              ab.AnimState:SetMultColour(255/255,0/255,0/255,1)
              ab.Transform:SetRotation(inst.Transform:GetRotation())
              qichangcool(inst,9,1,ab)
        local r1 = CreateEntity() r1.entity:AddTransform() r1.Transform:SetPosition(0, 0, 9)ab:AddChild(r1)r1:AddTag("FX")
        local r2 = CreateEntity() r2.entity:AddTransform() r2.Transform:SetPosition(0, 0, 23)ab:AddChild(r2)r2:AddTag("FX")
        local r3 = CreateEntity() r3.entity:AddTransform() r3.Transform:SetPosition(0, 0, 39)ab:AddChild(r3)r3:AddTag("FX")
        local l1 = CreateEntity() l1.entity:AddTransform() l1.Transform:SetPosition(0, 0, -9)ab:AddChild(l1)l1:AddTag("FX")
        local l2 = CreateEntity() l2.entity:AddTransform() l2.Transform:SetPosition(0, 0, -23)ab:AddChild(l2)l2:AddTag("FX")
        local l3 = CreateEntity() l3.entity:AddTransform() l3.Transform:SetPosition(0, 0, -39)ab:AddChild(l3)l3:AddTag("FX")
        juhelatk(inst,r1) juhelatk(inst,r2) juhelatk(inst,r3) juhelatk(inst,l1) juhelatk(inst,l2) juhelatk(inst,l3) 
           if inst.djhqrlevel == 3 then 
                    crefx(ab,"deer_fire_charge","deer_fire_charge","pre",Vector3(2, 2, 2),true,0,function(fx) 
                    fx.AnimState:SetMultColour(255/255,69/255,0/255,1)
                    end,true)
                    local l4 = CreateEntity() l4.entity:AddTransform() l4.Transform:SetPosition(0, 0, -50)ab:AddChild(l4) l4:AddTag("FX")
                    local r4 = CreateEntity() r4.entity:AddTransform() r4.Transform:SetPosition(0, 0, 50)ab:AddChild(r4) r4:AddTag("FX")
                    juhelatk(inst,r4) juhelatk(inst,l4)
           end
        end

        end),  
    	TimeEvent(19*FRAMES, function(inst)
    	inst.Physics:ClearMotorVelOverride()jqsptk(inst)
    	ChangeToCharacterPhysics(inst)
        jqsptk(inst,inst,4.5,-.25,-1) 
        end),  
        TimeEvent(34*FRAMES, function(inst)
        inst.qgaftjh = true
        end),  
        TimeEvent(42*FRAMES, function(inst)
        inst.Physics:ClearMotorVelOverride()jqsptk(inst)	
        end),  
        TimeEvent(59*FRAMES, function(inst)
        if inst.djhdodgeit then 
           inst.canuseevade = true
           inst.sg:RemoveStateTag("drowning")
           inst.sg:RemoveStateTag("transform")
        end
        if inst.delayremovefatg then
        inst:RemoveTag("fat_gang") end
        end),  
        TimeEvent(72*FRAMES, function(inst)
        inst.canuseevade = true
        inst.sg:RemoveStateTag("drowning")
        inst.sg:RemoveStateTag("transform")
        end),  
    },     
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                   jqsptk(inst) inst.sg:GoToState("idle")
                end
            end),
        },

        onupdate = function(inst)
        if inst.jhltime and type(inst.jhltime) == "number" then 
           if inst.jhltime < .4 then 
              inst.jhltime = inst.jhltime + FRAMES
           else
               if not inst.djhdodgeit then 
                  inst.jhltime = nil inst.djhdodgeit = true
                  if inst.taidao then inst.taidao.components.edgerank:LevelUp(-1) end
               end
           end
        end
        local dlcondition = function(inst) return (not KEYTYPE and (inst.td_atk and inst.td_qrz)) or (KEYTYPE and inst.td_qrz and inst.ktnmousel) end
                 if inst.qgaftjh then 
                 	if dlcondition(inst) then 
                 	inst.qgaftjh = nil 
                if inst.djhdodgeit then inst.doquickdl = true inst.donohitdl = true end
                 	inst.sg:GoToState("qrdg_pre")
                    end
                 end
            if inst.canuseevade and inst.td_space then inst.canuseevade = nil inst.sg:GoToState("evade_pre") end
        end,

    onexit = function(inst)
    jqsptk(inst)
    canceljq(inst)
    inst.components.health.externalabsorbmodifiers:RemoveModifier(inst,"ktn_jiahu")
    inst.jhltime = nil
    inst.qgaftjh = nil
    if inst.djhdodgeit then
    inst.djhdodgeit = nil
    else 
    if inst.taidao then inst.taidao.components.edgerank:LevelUp(-1) end
    end
    inst.canuseevade = nil
    if inst.delayremovefatg then
       inst:RemoveTag("fat_gang") end
    niltask(inst,"juherot")
    niltask(inst,"continuityatk")
    ChangeToCharacterPhysics(inst)
    inst.AnimState:SetDeltaTimeMultiplier(1)
    end,
})

AddStategraphState('wilson', 
  State{
    name = 'juhe_s_pst',
    tags = {"autopredict","juheS",'attack',"busy"},
    onenter = function(inst,bati)
        inst.Physics:Stop()
        if bati then inst.sg.statemem.btbyxg = nil inst.sg:AddStateTag("drowning") end
        inst.AnimState:PlayAnimation("juhetabu_pst")
        --inst.sg:SetTimeout(.9)
    end,
    timeline={
    },     
        ontimeout = function(inst)       
            inst.sg:GoToState("idle") 
        end,
            events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    onexit = function(inst) 
    inst.Physics:ClearMotorVelOverride()
    end,
})

AddStategraphState('wilson', 
  State{
    name = 'juhe_s',
    tags = {"busy", "juheS","attack","abouttoattack","nopredict","ktnsg","notandao"},
    onenter = function(inst)
        
        inst.Physics:Stop()
        inst.components.locomotor:Clear()
        tdinvincible(inst,3)
        --inst.AnimState:SetDeltaTimeMultiplier(1.23)  
        inst.AnimState:PlayAnimation("juhetabu")
        inst.Physics:ClearMotorVelOverride()
        jqsptk(inst,inst,7,-.15) 
        changerot(inst,60)
        local s = 1
        crefx(inst,"hx_fx","hx_fx","djh",Vector3(s, s, s),true,180,function(ab) 
        ab.AnimState:SetDeltaTimeMultiplier(1.32)
        end,true,Vector3(0, 0, 0))

        --inst.sg:SetTimeout(1) 
    end,
    timeline={
    	TimeEvent(2*FRAMES, function(inst)
        jqsptk(inst,inst,8,-.15) 
        inst.SoundEmitter:PlaySound("longsword/katana/xjh")
        end),  
        TimeEvent(4*FRAMES, function(inst)
        canceljq(inst)
        GLOBAL.PlayFootstep(inst, 1, true)
        end),
    	TimeEvent(7*FRAMES, function(inst)
        rangeatk(inst,2.3,.15,1.25)
        jqsptk(inst)
        inst.Physics:ClearMotorVelOverride()
        end),  
        TimeEvent(12*FRAMES, function(inst)
        GLOBAL.PlayFootstep(inst, 1, true)
        jqsptk(inst,inst,7,-.23) 
        end),  
        TimeEvent(19*FRAMES, function(inst)
        rangeatk(inst,2.5,.15,1.25)
        end),  
        TimeEvent(22*FRAMES, function(inst)
        jqsptk(inst)
        inst.Physics:ClearMotorVelOverride()
        if inst.delayremovefatg then
        inst:RemoveTag("fat_gang") end
        end),  
        TimeEvent(25*FRAMES, function(inst)
        inst.sg:GoToState("juhe_s_pst",inst.sg:HasStateTag("drowning"))
        end),
    },     
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },


    onexit = function(inst)
    jqsptk(inst)
    canceljq(inst)
        if inst.delayremovefatg then
        inst:RemoveTag("fat_gang") end
    inst.components.health.externalabsorbmodifiers:RemoveModifier(inst,"ktn_jiahu")
    inst.AnimState:SetDeltaTimeMultiplier(1)
    end,
})
AddStategraphState('wilson', 
  State{
    name = 'zhiz',
    tags = {'busy',"zhiz","abouttoattack","nopredict",'attack',"ktnsg"},
    onenter = function(inst)
        inst.Physics:Stop()
        inst.components.locomotor:Clear()
        inst.AnimState:SetDeltaTimeMultiplier(1) 
        inst.AnimState:PlayAnimation("zhiz")
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()
        changerot(inst,60) 

    end,
    timeline={
        TimeEvent(0*FRAMES, function(inst)
        jqsptk(inst,inst,1,-.07,1) 
        end),  
        TimeEvent(7*FRAMES, function(inst) 
        jqsptk(inst)inst.Physics:ClearMotorVelOverride()
        end),
        TimeEvent(9*FRAMES, function(inst) 
        inst.SoundEmitter:PlaySound("longsword/katana/qrz_3_pst","zhiz")
        end),  
        TimeEvent(17*FRAMES, function(inst) 
        rangeatk(inst,3,.15,1.35)
        end), 
        TimeEvent(19*FRAMES, function(inst) 
        inst.SoundEmitter:KillSound("zhiz")
        end), 
        TimeEvent(25*FRAMES, function(inst)
        inst.canuseevade = true
        inst.sg:RemoveStateTag("abouttoattack")
         end),  
    },     
            events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },


    onexit = function(inst) 
    jqsptk(inst)
    inst.SoundEmitter:KillSound("zhiz")
    inst.canuseevade = nil
    inst.Physics:ClearMotorVelOverride()
    inst.AnimState:SetDeltaTimeMultiplier(1) 
    end,
})
AddStategraphState('wilson', 
  State{
    name = 'tabuz',
    tags = {'busy',"tabuz","abouttoattack","nopredict",'attack',"ktnsg"},
    onenter = function(inst)
        inst.Physics:Stop()
        inst.components.locomotor:Clear()
        inst.AnimState:SetDeltaTimeMultiplier(1) 
        inst.AnimState:PlayAnimation("tbz")
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()
        changerot(inst,60) 

    end,
    timeline={
        TimeEvent(0*FRAMES, function(inst)
        jqsptk(inst,inst,4.2,-.3) 
        end),  
        TimeEvent(6*FRAMES, function(inst)
        jqsptk(inst,inst,1.6,.2) 
        end),
        TimeEvent(12*FRAMES, function(inst) 
        inst.SoundEmitter:PlaySound("longsword/katana/tuci","tabuz")
        jqsptk(inst) 
        end),
        TimeEvent(21*FRAMES, function(inst) 
        rangeatk(inst,3.2,.17,1.4)
        jqsptk(inst)inst.Physics:ClearMotorVelOverride()
        end),  
        TimeEvent(21*FRAMES, function(inst) 
        inst.SoundEmitter:KillSound("tabuz")
        end), 
        TimeEvent(30*FRAMES, function(inst)
        inst.sg:RemoveStateTag("abouttoattack")
        end),  
    },     
            events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

    onexit = function(inst) 
    jqsptk(inst)
    inst.SoundEmitter:KillSound("tabuz")
    inst.Physics:ClearMotorVelOverride()
    inst.AnimState:SetDeltaTimeMultiplier(1) 
    end,
})

AddStategraphState('wilson', 
  State{
    name = 'tuci_pst',
    tags = {"autopredict","qrz1","tuci",'attack',"tcst","busy","ktnsg"},
    onenter = function(inst,stqrzpst)
        inst.sg.statemem.stqrz = stqrzpst
        if not stqrzpst then inst.sg:RemoveStateTag("qrz1")  end
        inst.AnimState:PlayAnimation("tuci_pst")
        local n = {"",2,3,4}
                if math.random() <.6 then
        inst.SoundEmitter:PlaySound("longsword/katana/zayin"..n[math.random(#n)],"ktnzayin") end
    end,
    timeline={
    },     
            events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

    onexit = function(inst) 
    inst.SoundEmitter:KillSound("ktnzayin")
    inst.canusetc = nil
    end,
})
AddStategraphState('wilson', 
  State{
    name = 'shangtiao_pst',
    tags = {"autopredict","qrz2","shangtiao",'attack',"tcst","busy","ktnsg"},
    onenter = function(inst,stqrzpst)
        inst.sg.statemem.stqrz = stqrzpst
        if not stqrzpst then inst.sg:RemoveStateTag("qrz2") end
        inst.AnimState:PlayAnimation("shangtiao_pst")
        local n = {"",2,3,4}
        if math.random() <.6 then
        inst.SoundEmitter:PlaySound("longsword/katana/zayin"..n[math.random(#n)],"ktnzayin") end
    end,
    timeline={
    },     
                events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    onexit = function(inst) 
    inst.SoundEmitter:KillSound("ktnzayin")
    end,
})

AddStategraphState('wilson', 
  State{
    name = 'tuci',
    tags = {'busy',"qrz1","tuci","abouttoattack","nopredict",'attack',"tcst","ktnsg","nokarousg"},
    onenter = function(inst,stqrz)
        inst.aftdoatk = nil
        if stqrz then 
           inst.sg.statemem.stqrz = true
        else inst.sg:RemoveStateTag("qrz1") jqsptk(inst,inst,2,-.1,1) end
        inst.Physics:Stop()
        inst.components.locomotor:Clear()
        inst.AnimState:SetDeltaTimeMultiplier(1) 
        local sg = (stqrz and "") or "_idle"
        inst.AnimState:PlayAnimation("tuci"..sg)
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()
        inst.sg:SetTimeout(1.5)
        changerot(inst,60) 

    end,
    timeline={
        TimeEvent(0*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("longsword/katana/tuci")
        end),  
        TimeEvent(7*FRAMES, function(inst) 
        ktnatk(inst,2.7,nil,inst.ktnbench_far)
        if not inst.sg.statemem.stqrz then
        jqsptk(inst,inst,1,-.07,-1) end
        end),
        TimeEvent(15*FRAMES, function(inst) 
        jqsptk(inst)inst.Physics:ClearMotorVelOverride()
        inst.sg:RemoveStateTag("abouttoattack") end),  
        TimeEvent(18*FRAMES, function(inst)
        inst.sg:GoToState("tuci_pst",inst.sg.statemem.stqrz)
         end),  
    },     
            events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        ontimeout = function(inst)       
            inst.sg:GoToState("idle") 
        end,
    onexit = function(inst) 
    jqsptk(inst)
    inst.Physics:ClearMotorVelOverride()
    inst.AnimState:SetDeltaTimeMultiplier(1) 
    end,
})
AddStategraphState('wilson', 
  State{
    name = 'shangtiao',
    tags = {'busy',"shangtiao","qrz2","abouttoattack","nopredict",'attack',"tcst","ktnsg","nokarousg"},
    onenter = function(inst,stqrz)
        inst.aftdoatk = nil
        if stqrz then 
           inst.sg.statemem.stqrz = true
           else inst.sg:RemoveStateTag("qrz2") jqsptk(inst,inst,2.3,-.1,1) 
        end
        inst.Physics:Stop()
        inst.components.locomotor:Clear()
        inst.AnimState:SetDeltaTimeMultiplier(1) 
        inst.AnimState:PlayAnimation("shangtiao")
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()
        inst.sg:SetTimeout(1.5)
        changerot(inst,60) 

    end,
    timeline={
        TimeEvent(0*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("longsword/katana/shangtiao")
        end),  
        TimeEvent(7*FRAMES, function(inst) 
        ktnatk(inst,2.4)
        if not inst.sg.statemem.stqrz then
        jqsptk(inst,inst,1,-.07,-1) end end),
        TimeEvent(19*FRAMES, function(inst) 
        jqsptk(inst)inst.Physics:ClearMotorVelOverride()
        inst.sg:RemoveStateTag("abouttoattack") end),  
        TimeEvent(20*FRAMES, function(inst)
        inst.sg:GoToState("shangtiao_pst",inst.sg.statemem.stqrz)
         end),  
    },     
            events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        ontimeout = function(inst)       
            inst.sg:GoToState("idle") 
        end,
    onexit = function(inst) 
    jqsptk(inst)
    inst.Physics:ClearMotorVelOverride()
    inst.AnimState:SetDeltaTimeMultiplier(1) 
    end,
})

AddStategraphState('wilson', 
  State{
    name = 'qrz_1_pst',
    tags = {"autopredict",'attack',"qrz","qrz1","busy","notandao"},
    onenter = function(inst)
        inst.AnimState:PlayAnimation("qrz1_pst")
        --inst.sg:SetTimeout(1.2)
    end,
    timeline={
    },     
        ontimeout = function(inst)       
            inst.sg:GoToState("idle") 
        end,
                events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    onexit = function(inst) 
    inst.canusetc = nil
    end,
})

AddStategraphState('wilson', 
  State{
    name = 'qrz_2_pst',
    tags = {"autopredict",'attack',"qrz","qrz2","busy","notandao"},
    onenter = function(inst)
        inst.AnimState:PlayAnimation("qrz2_pst")
        --inst.sg:SetTimeout(.9)
    end,
    timeline={
    },     
        ontimeout = function(inst)       
            inst.sg:GoToState("idle") 
        end,
                events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    onexit = function(inst) 
    end,
})

AddStategraphState('wilson', 
  State{
    name = 'qrz_1',
    tags = {"busy", "qrz1","qrz","attack","abouttoattack","nopredict","ktnsg","notandao"},
    onenter = function(inst,qrzmoving)
        
        inst.Physics:Stop()
        inst.components.locomotor:Clear()
        local tn =  (inst.heaveqrz and .6) or 1
        inst.AnimState:SetDeltaTimeMultiplier(tn)  
        local qrzmoving = qrzmoving and inst.ktn_iswalking
        inst.sg.statemem.qrzmoving = qrzmoving 
        local moving = (qrzmoving and "_tabu") or ""
        inst.AnimState:PlayAnimation("qrz1"..moving)
        inst.Physics:ClearMotorVelOverride()
        changerot(inst,60)

        inst.sg:SetTimeout((inst.heaveqrz and 2.3) or 2) 
    end,
    timeline={
    	TimeEvent(0*FRAMES, function(inst)
        local spd = (inst.sg.statemem.qrzmoving and 3.7) or 1.4
    	jqsptk(inst,inst,spd,-.15) 
     if inst.taidao and inst.taidao.components.edgerank.qiren>=0.15 then
        crefx(inst,"halloween_embers","halloween_embers","puff_2",Vector3(.7,.7,.7),true,0,function(ab) createlight(ab,Vector3(150,46,46),.4) ab.AnimState:SetMultColour(255/255,0/255,0/255,.7) end)
        inst.SoundEmitter:PlaySound("longsword/katana/qrz") 
        inst.sg.statemem.isqrz = true
        inst.taidao.components.edgerank:QrDoDelta(-.15) 
    else inst.sg:RemoveStateTag("notandao") inst.sg:AddStateTag("noqrqrz")
    end
        end),  
    	TimeEvent(10*FRAMES, function(inst)
        if not inst.sg.statemem.qrzmoving then
    	jqsptk(inst) inst.Physics:ClearMotorVelOverride() end
        end),  
        TimeEvent(12*FRAMES, function(inst)
        if inst.heaveqrz then inst.AnimState:SetDeltaTimeMultiplier(1.2) end
        inst.SoundEmitter:PlaySound("longsword/katana/qrz_1")
        end),  
        TimeEvent(17*FRAMES, function(inst)
        jqsptk(inst) inst.Physics:ClearMotorVelOverride()
        if not inst.heaveqrz then
        local bt = inst.sg.statemem.isqrz and 1.5 or 1.2
        rangeatk(inst,3.2,.14,bt) end
        end),  
        TimeEvent(23*FRAMES, function(inst)
        local bt = inst.sg.statemem.isqrz and 1.6 or 1.23
        if not inst.heaveqrz then
        --inst.sg:RemoveStateTag("abouttoattack")
        else rangeatk(inst,3.2,.16,bt) end
        end),  
        TimeEvent(25*FRAMES, function(inst)
        if not inst.heaveqrz then
        inst.sg:GoToState("qrz_1_pst")
        --else inst.sg:RemoveStateTag("abouttoattack") 
        end
        end),  
        TimeEvent(27*FRAMES, function(inst)
        inst.sg:GoToState("qrz_1_pst")
        end),  

    },     
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    ontimeout = function(inst)
    inst.sg:GoToState("idle")
    end,
    onexit = function(inst)
    inst.heaveqrz = nil
    jqsptk(inst) 
    inst.AnimState:SetDeltaTimeMultiplier(1)
    end,
})
AddStategraphState('wilson', 
  State{
    name = 'qrz_2',
    tags = {"busy", "qrz2","qrz","attack","abouttoattack","nopredict","ktnsg","notandao"},
    onenter = function(inst)
        
        inst.Physics:Stop()
        inst.components.locomotor:Clear()
        local td = inst.taidao
        if td then td.components.edgerank:QrDoDelta(-.15) end
        --inst.AnimState:SetDeltaTimeMultiplier(1)  
        inst.AnimState:PlayAnimation("qrz2")
        inst.Physics:ClearMotorVelOverride()
        changerot(inst,60)
        crefx(inst,"halloween_embers","halloween_embers","puff_1",Vector3(.7,.7,.7),true,0,function(ab) createlight(ab,Vector3(150,46,46),.4) ab.AnimState:SetMultColour(255/255,0/255,0/255,.7) end)

        inst.sg:SetTimeout(1.7) 
    end,
    timeline={
    	TimeEvent(0*FRAMES, function(inst)
    	jqsptk(inst,inst,1,-.1,-1) 
        inst.SoundEmitter:PlaySound("longsword/katana/qrz2")
        end),  
    	TimeEvent(5*FRAMES, function(inst)
    	jqsptk(inst) inst.Physics:ClearMotorVelOverride()
        end),  
        TimeEvent(9*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("longsword/katana/qrz_2")
        end),  
        TimeEvent(14*FRAMES, function(inst)
        rangeatk(inst,2.3,.14,1.45)
        end),  
        TimeEvent(21*FRAMES, function(inst)
        inst.sg:RemoveStateTag("abouttoattack")
        end),  
        TimeEvent(25*FRAMES, function(inst)
        inst.sg:GoToState("qrz_2_pst")
        end),  
    },     
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    ontimeout = function(inst)
    inst.sg:GoToState("idle")
    end,
    onexit = function(inst)
    jqsptk(inst) 
    inst.AnimState:SetDeltaTimeMultiplier(1)
    end,
})

AddStategraphState('wilson', 
  State{
    name = 'qrz_3',
    tags = {"busy", "qrz3","qrz","attack","abouttoattack","nopredict","ktnsg","notandao"},
    onenter = function(inst)
        local td = inst.taidao
        if td then td.components.edgerank:QrDoDelta(-.15) end
        inst.Physics:Stop()
        inst.components.locomotor:Clear()
        --inst.AnimState:SetDeltaTimeMultiplier(1)  
        inst.AnimState:PlayAnimation("qrz3")
        changerot(inst,60)
        crefx(inst,"halloween_embers","halloween_embers","puff_3",Vector3(.7,.7,.7),true,0,function(ab) createlight(ab,Vector3(150,46,46),.4) ab.AnimState:SetMultColour(255/255,0/255,0/255,.7) end)
        inst.sg:SetTimeout(3.5) 
    end,
    timeline={
    	TimeEvent(0*FRAMES, function(inst)
    	jqsptk(inst,inst,2,-0.1,1,2)
        inst.SoundEmitter:PlaySound("longsword/katana/qrz")
        end),  
        TimeEvent(2*FRAMES, function(inst)
        GLOBAL.PlayFootstep(inst, 1, true)
        end),
    	TimeEvent(6*FRAMES, function(inst)
    	jqsptk(inst)
    	inst.SoundEmitter:PlaySound("longsword/katana/qrz_3")
        rangeatk(inst,2.3,.1,.85)
        end),  
        TimeEvent(17*FRAMES, function(inst)
        rangeatk(inst,2.3,.1,.85)
        jqsptk(inst,inst,1,-0.1,1,2)
        end),  
        TimeEvent(23*FRAMES, function(inst)
        jqsptk(inst)
        end),
        TimeEvent(32*FRAMES, function(inst)
        jqsptk(inst,inst,1,-0.1,1,2)
        inst.SoundEmitter:PlaySound("longsword/katana/qrz_3_pst")
        end),
        TimeEvent(45*FRAMES, function(inst)
        rangeatk(inst,2.5,.15,1.6)
        jqsptk(inst)
        end),  
        TimeEvent(54*FRAMES, function(inst)
        inst.canedged = true
        inst.sg:RemoveStateTag("abouttoattack")
        end),  
        TimeEvent(66*FRAMES, function(inst)
        inst.sg:RemoveStateTag("nopredict")
        end),  
        TimeEvent(69*FRAMES, function(inst)
        inst.canedged = nil
        inst.aftdoatk = false
        end),  
    },     
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    ontimeout = function(inst)
    inst.sg:GoToState("idle")
    end,
    onexit = function(inst)
    inst.canuseevade = nil
    inst.canedged = nil
    jqsptk(inst)
    inst.AnimState:SetDeltaTimeMultiplier(1)
    end,
})

AddStategraphState('wilson', 
  State{
    name = 'qrdhx',
    tags = {"busy", "canrotate","nopredict","edgeing","ktnsg","notandao","drowning"},
    onenter = function(inst)
        
        inst.Physics:Stop()
        local td = inst.taidao
        if td then td.components.edgerank:QrDoDelta(-.25) end
        inst.components.locomotor:Clear()
        inst.AnimState:SetDeltaTimeMultiplier(1)
        inst.AnimState:PlayAnimation("qrdhx")
        inst.SoundEmitter:PlaySound("longsword/katana/qrz") 
        inst.SoundEmitter:PlaySound("longsword/katana/qrdhx")	
        changerot(inst,90)
        inst.dhxbenchit = CreateEntity()
        inst.dhxbenchit.entity:AddTransform()
        inst.dhxbenchit.Transform:SetPosition(2.1, 0, 0) 
        inst:AddChild(inst.dhxbenchit) 
        --local foll = SpawnPrefab("flower")
        --foll:DoPeriodicTask(FRAMES,function() if inst.dhxbenchit and inst.dhxbenchit:IsValid() then foll.Transform:SetPosition(inst.dhxbenchit.Transform:GetWorldPosition()) else foll:Remove() end end)
        --spawnqrfx(inst,true,"deer_ice_flakes","pst",Vector3(.6,.8,.6))
        crefx(inst,"halloween_embers","halloween_embers","puff_2",Vector3(.7,.7,.7),true,0,function(ab) createlight(ab,Vector3(150,46,46),.5) ab.AnimState:SetMultColour(255/255,0/255,0/255,.7) end)
    end,
    timeline={
    	TimeEvent(1*FRAMES, function(inst)
        inst:SetCameraZoomed(true)
        niltask(inst,"juherot") inst.juherotn = 0
        local rot = inst.Transform:GetRotation()
        local t = 3
        inst.juherot = inst:DoPeriodicTask(1*FRAMES,function()
            if Exist(inst.dhxbenchit,true) then
                local picktar = FindEntity(inst.dhxbenchit, 2.3, function(a) return a.components.pickable and a.components.pickable.canbepicked and a.components.pickable.cycles_left end)
               if picktar then
                inst.dhxbenchit:AddComponent("inventory") picktar.components.pickable:Pick(inst.dhxbenchit)
                if picktar.components.pickable.product then 
                    local picktarpd = SpawnPrefab(picktar.components.pickable.product)
                    local x0, y0, z0 = inst.Transform:GetWorldPosition()
                    local x1, y1, z1 = picktar.Transform:GetWorldPosition()
                    local dx, dz = x1 - x0, z1 - z0
                    local dsq = dx * dx + dz * dz
                    local angle
                    if dsq > 0 then local dist = math.sqrt(dsq) angle = math.atan2(dz / dist, dx / dist) + (math.random() * 20 - 10) * DEGREES
                        else angle = 2 * PI * math.random() 
                    end
    local speed = 4 + math.random()
    picktarpd.Physics:Teleport(x1, .1, z1)
    picktarpd.Physics:SetVel(math.cos(angle) * speed, speed * 2 + math.random() * 2, math.sin(angle) * speed)
                end
              end
            end
        if inst.juherotn >= 390 then
           inst.Physics:ClearMotorVelOverride()
           if inst.qrdhxfx then inst.qrdhxfx.startrot = true end
           inst.Transform:SetRotation(inst.Transform:GetRotation()+30)
                inst.dhxbencht = 0
                inst.dhxbench = inst:DoPeriodicTask(FRAMES,function() 
                if inst.karoustop then return end
                   if Exist(inst.dhxbenchit,true) and inst.dhxbencht < 1.7 then 
                      inst.dhxbencht = inst.dhxbencht + 0.8
                      inst.dhxbenchit.Transform:SetPosition(1.7-inst.dhxbencht, 0, inst.dhxbencht) 
                   else niltask(inst,"dhxbench")  end
                end)
           niltask(inst,"juherot") 
           else
           if inst.karoustop then inst.Physics:ClearMotorVelOverride() 
              else
           inst.juherotn = inst.juherotn + 30
           t =t - .15
           local bit = inst.juherotn/90
           local bt =(bit<2 and 1-bit) or bit-3
           local b = (bit<1 and bit) or (bit<3 and 2-bit) or bit-4
           inst.Transform:SetRotation(rot-inst.juherotn)  
           inst.Physics:SetMotorVelOverride(5*bt*t,0,-5*b*t) 
              end
           end 
        end)
        end),
    	TimeEvent(4*FRAMES, function(inst) 
        local s = 2
        crefx(inst,"hx_fx","hx_fx","idle",Vector3(s, s, s),nil,180,function(ab) 
        inst.qrdhxfx = ab
        ab:DoPeriodicTask(FRAMES,function() if not Exist(inst) then ab:Remove() return end 
        if inst.karoustop then  ab.AnimState:SetDeltaTimeMultiplier(0) else ab.AnimState:SetDeltaTimeMultiplier(1.0) end
           ab.Transform:SetPosition(inst.Transform:GetWorldPosition())
           if ab.startrot and not inst.karoustop then
              ab.Transform:SetRotation(ab.Transform:GetRotation() -8)
              else local rot = inst.Transform:GetRotation()
                   ab.Transform:SetRotation(rot+200)
           end  
        end)
        end,true) 
    	rangeatk(inst,2.3,.6,1.65,inst.dhxbenchit)
        end),
        TimeEvent(9*FRAMES, function(inst) 
        inst:SetCameraZoomed(false)
        end),
        TimeEvent(18*FRAMES, function(inst)
        inst.Physics:ClearMotorVelOverride()
        inst.Physics:SetMotorVelOverride(-.5,0,0) 
        end), 
    	TimeEvent(23*FRAMES, function(inst)
        if inst.qrdhxhit then inst.qrdhxhit = nil
        --inst.dhxbenchit.Transform:SetPosition(0, 0, 1.8)
        if inst.taidao then inst.taidao.components.edgerank:LevelUp() end end
        end),  
        TimeEvent(27*FRAMES, function(inst)
        inst.ktnjhable = true
        if inst.dhxbenchit then inst.dhxbenchit:Remove() inst.dhxbenchit = nil end
        inst.Physics:ClearMotorVelOverride()
        end),  
        TimeEvent(37*FRAMES, function(inst)
        inst.Physics:ClearMotorVelOverride()
        changerot(inst,90)
        end),  
        TimeEvent(39*FRAMES, function(inst)
        niltask(inst,"juherot") inst.juherotn = 0
        local rot = inst.Transform:GetRotation()
        jqsptk(inst,inst,3.4,-.55,1,2) 
        inst.rotatend = true
        inst.sg:AddStateTag("ndaftedg")
        end),  

         TimeEvent(60*FRAMES, function(inst)
            local td = inst.taidao
            if td then td.needue = true inst.components.inventory:GiveItem(td) end
        end),  
        
    },     
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.rotatend = nil
                    inst.sg:GoToState("idle")
                end
            end),
        },

    onexit = function(inst)
    jqsptk(inst)
    inst:SetCameraZoomed(false)
    niltask(inst,"dhxbench")
    inst:DoTaskInTime(5*FRAMES,function()if not inst.sg.currentstate.name == "nadao" then inst.rotatend = nil end end)
    if inst.dhxbenchit then inst.dhxbenchit:Remove() inst.dhxbenchit = nil end
    inst.ktnjhable = nil
        if inst.qrdhxhit then inst.qrdhxhit = nil
        if inst.taidao then inst.taidao.components.edgerank:LevelUp() end end
    niltask(inst,"continuityatk")
    inst.Physics:ClearMotorVelOverride()
    inst.AnimState:SetDeltaTimeMultiplier(1)
    end,
})

AddStategraphState('wilson', 
  State{
    name = 'jszhan_pre',
    tags = {"busy","tent","jszhan","nopredict","ktnsg"},
    onenter = function(inst)
        inst.Physics:Stop()
        inst.components.locomotor:Clear()
        inst.AnimState:SetDeltaTimeMultiplier(1.23)  
        local jsg = inst.jszaftatk and "_atk" or ""
        inst.AnimState:PlayAnimation("jsz_pre"..jsg)
        inst.aftdoatk = nil
        inst.jszhanr = nil
        inst.jszhanl = nil
        inst.jszhanindex = CreateEntity()
        local ab = inst.jszhanindex ab:AddTag("FX")
        ab.entity:AddTransform() MakeInventoryPhysics(ab)
        ab.Transform:SetPosition(inst.Transform:GetWorldPosition())
        ab.Transform:SetRotation(inst.td_heading or inst.Transform:GetRotation())
        ab.Physics:SetMotorVelOverride(2,0,0)
        ab:DoTaskInTime(2*FRAMES,function() 
        ab.Transform:SetRotation(inst.td_heading or inst.Transform:GetRotation()) 
        ab:DoTaskInTime(1*FRAMES,function() 
        local distor = math.sqrt(ab:GetDistanceSqToInst(inst.ktnbench_r or inst)) 
        local distol = math.sqrt(ab:GetDistanceSqToInst(inst.ktnbench_l or inst))
        if distor > distol+.1 then inst.jszhanl = true elseif distor < distol-.1 then inst.jszhanr = true end
        ab.Physics:ClearMotorVelOverride() end) end)
        inst.Physics:ClearMotorVelOverride()
    end,
    timeline={
        TimeEvent(4*FRAMES, function(inst) 
        inst.sg:GoToState("jszhan")
        end),  
    },     
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("jszhan")
                end
            end),
        },
    onexit = function(inst)
    jqsptk(inst) 
    inst.aftdoatk = nil
    inst.jszaftatk = nil
    if inst.jszhanindex then inst.jszhanindex:Remove() end
    inst.AnimState:SetDeltaTimeMultiplier(1)
    end,
})

AddStategraphState('wilson', 
  State{
    name = 'jszhan',
    tags = {"busy","tent","jszhan","attack","abouttoattack","nopredict","ktnsg"},
    onenter = function(inst,jszrot)
        inst.Physics:Stop()
        inst.components.locomotor:Clear()
        if jszrot then changerot(inst) end
        --inst.AnimState:SetDeltaTimeMultiplier(1) 
        local lorr = (inst.jszhanr and "_r") or (inst.jszhanl and "_l") or ""
        inst.AnimState:PlayAnimation("jsz"..lorr) 
        inst.Physics:ClearMotorVelOverride()
    end,
    timeline={
        TimeEvent(4*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("longsword/katana/qrz_2","jsz") -- so lazy
        end),  
        TimeEvent(7*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("longsword/katana/jq_noqr")
        end),  
        TimeEvent(14*FRAMES, function(inst)
        inst.SoundEmitter:KillSound("jsz")
        end),
        TimeEvent(10*FRAMES, function(inst)
        local lorr = (inst.jszhanr and -1) or (inst.jszhanl and 1) or nil
        jqsptk(inst,inst,4.3,-0.72,-1,2,lorr)
        end),  
        TimeEvent(13*FRAMES, function(inst)
        rangeatk(inst,4.1,.2,1.6)
        end),  
        TimeEvent(27*FRAMES, function(inst)
        inst.sg:RemoveStateTag("abouttoattack")
        end),  
        TimeEvent(28*FRAMES, function(inst)
        jqsptk(inst) inst.Physics:ClearMotorVelOverride()
        local lorr = (inst.jszhanr and -1) or (inst.jszhanl and 1) or nil
        jqsptk(inst,inst,1.2,-.2,-1,lorr) 
        end),  
    },     
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    onexit = function(inst)
    jqsptk(inst) 
    inst.jszhanr = nil
    inst.jszhanl = nil
    inst.SoundEmitter:KillSound("jsz")
    inst.AnimState:SetDeltaTimeMultiplier(1)
    end,
})

AddStategraphState('wilson', 
  State{
    name = 'njszhan_pst',
    tags = {"autopredict",'attack',"qrz","qrz2","busy"},
    onenter = function(inst)
        inst.AnimState:PlayAnimation("njsz_pst")
    end,
    timeline={
    },     
        ontimeout = function(inst)       
            inst.sg:GoToState("idle") 
        end,
                events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    onexit = function(inst) 
    end,
})

AddStategraphState('wilson', 
  State{
    name = 'njszhan',
    tags = {"busy", "qrz2","qrz","attack","abouttoattack","nopredict","ktnsg","notandao"},
    onenter = function(inst)
        
        inst.Physics:Stop()
        inst.components.locomotor:Clear()
        --inst.AnimState:SetDeltaTimeMultiplier(1)  
        inst.AnimState:PlayAnimation("njsz")
        inst.Physics:ClearMotorVelOverride()
        changerot(inst,45)

    end,
    timeline={
        TimeEvent(1*FRAMES, function(inst)
        jqsptk(inst,inst,3.2,-.4,1,2) 
        if inst.taidao and inst.taidao.components.edgerank.qiren>=0.15 then
        inst.taidao.components.edgerank:QrDoDelta(-.15)
        inst.sg.statemem.isqrz = true
        inst.SoundEmitter:PlaySound("longsword/katana/qrz") 
        crefx(inst,"halloween_embers","halloween_embers","puff_1",Vector3(.7,.7,.7),true,0,function(ab) createlight(ab,Vector3(150,46,46),.4) ab.AnimState:SetMultColour(255/255,0/255,0/255,.7) end)
        else inst.sg:RemoveStateTag("qrz2") inst.sg:RemoveStateTag("notandao")
        end
        end),  
        TimeEvent(5*FRAMES, function(inst)
        end),  
        TimeEvent(4*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("longsword/katana/djh","njsz")
        end),  
        TimeEvent(19*FRAMES, function(inst)
        local bt = inst.sg.statemem.isqrz and 1.5 or 1.2
        rangeatk(inst,2.7,.14,bt,inst.ktnbench)
        end),  
        TimeEvent(23*FRAMES, function(inst)
        jqsptk(inst) inst.Physics:ClearMotorVelOverride()
        end),  
        TimeEvent(26*FRAMES, function(inst)
        inst.SoundEmitter:KillSound("njsz")
        inst.sg:RemoveStateTag("abouttoattack")
        end),  
    },     
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("njszhan_pst")
                end
            end),
        },
    onexit = function(inst)
    jqsptk(inst) 
    inst.SoundEmitter:KillSound("njsz")
    inst.AnimState:SetDeltaTimeMultiplier(1)
    end,
})

AddStategraphState('wilson', 
  State{
    name = 'nadao',
    tags = {"busy", "tent", "canrotate","nopredict","ktnsg"},
    onenter = function(inst,aftdhx)
        inst.Physics:Stop()
        inst.components.locomotor:Clear()
        changerot(inst)
        inst.ktnjhable = nil
        inst.AnimState:SetDeltaTimeMultiplier(1.05)
        canceljq(inst)
        local ifhx = aftdhx and "_aftdhx" or ""
        inst.AnimState:PlayAnimation("nadao"..ifhx)
        inst.sg.statemem.aftdhx = aftdhx
        inst.SoundEmitter:PlaySound("longsword/katana/nadao_pre")	
        if not inst.rotatend then inst.Physics:SetMotorVelOverride(-2.7,0,0) end
    end,
    timeline={
        TimeEvent(1*FRAMES, function(inst) 
if inst.rotatend then 
        inst.juherotn = 0
        local rot = inst.Transform:GetRotation()
        local t = 4
        inst.juherot = inst:DoPeriodicTask(1*FRAMES,function()
        if inst.juherotn >= 360 then
            if inst.rotatendofjhr then
               inst.Transform:SetRotation(inst.rotatendofjhr)
               inst.rotatendofjhr = nil
             end
           niltask(inst,"juherot")
           inst.Physics:ClearMotorVelOverride()
           else
           local bt = 45
           inst.juherotn = inst.juherotn + bt
           t =t - .2
           local bit = inst.juherotn/90
           local bt =(bit<2 and 1-bit) or bit-3
           local b = (bit<1 and bit) or (bit<3 and 2-bit) or bit-4
           inst.Transform:SetRotation(rot+inst.juherotn)  
           inst.Physics:SetMotorVelOverride(-2*bt*t,0,-2*b*t) 
           end 
        end)
else 
            inst.Physics:SetMotorVelOverride(-3.2,0,0)   end
        end),
    	TimeEvent(4*FRAMES, function(inst)
        GLOBAL.PlayFootstep(inst, .6, true)
        if not inst.rotatend then inst.Physics:ClearMotorVelOverride() end
        end), 
        TimeEvent(7*FRAMES, function(inst)
        jqsptk(inst,inst,2.3,-0.5,-1,2)
        end),
        TimeEvent(18*FRAMES, function(inst)
        jqsptk(inst)
        inst.Physics:ClearMotorVelOverride()
        end),  
        TimeEvent(29*FRAMES, function(inst)
        local s = 1
        local td = inst.taidao
        if td then local rank = td.components.edgerank.rank
        if rank > 0 then
        crefx(inst,"qr_fx","qr_fx","nadao",Vector3(s,s,s),true,0,function(ab)ab.entity:AddFollower()
        local colour = (rank == 3 and Vector3(220/255,20/255,60/255)) or (rank == 2 and Vector3(255/255,215/255,0/255)) or Vector3(1,1,1)
        if rank == 3 then ab.AnimState:SetMultColour(220/255,20/255,60/255,1) elseif rank == 2 then ab.AnimState:SetMultColour(255/255,215/255,0/255,1)
        else ab.AnimState:SetMultColour(1,1,1,1) end
        ab.Follower:FollowSymbol(inst.GUID, "swap_object", 0, -123, 0) end) end end
        end),
        TimeEvent(32*FRAMES, function(inst)
    	inst.SoundEmitter:PlaySound("longsword/katana/nadao_pst")	
        end),
        TimeEvent(42*FRAMES, function(inst)
        qichangcool(inst,3.5,0.5)
        --inst.sg:AddStateTag("nadao_done")
        end),
    },     
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("nadao_ready")
                end
            end),
        },

    onexit = function(inst)
    jqsptk(inst)
    inst.rotatend = nil
    niltask(inst,"juherot")
    inst.AnimState:SetDeltaTimeMultiplier(1)
    end,
})

AddStategraphState('wilson', 
  State{
    name = 'nadao_ready',
    tags = {"nadao_done","busy","doing","working","ktnsg"},
    onenter = function(inst)
        local level = (inst.taidao and inst.taidao.components.edgerank.rank) or 0
        if level>2 then
        SpawnPrefab("fishingnetvisualizerfx").Transform:SetPosition(inst.Transform:GetWorldPosition()) end
        --local sc = (level+1)/3
        --crefx(inst,"splash_weregoose_fx","splash_water_drop","no_splash",Vector3(sc,sc,sc),true,0,function(ab) ab.AnimState:SetMultColour(224/255,255/255,255/255,.7) end)
        inst.Physics:Stop()
        inst.components.locomotor:Clear()
        inst.AnimState:SetDeltaTimeMultiplier(.7)  
        inst.AnimState:PlayAnimation("nadao_loop",true)
        inst.sg:SetTimeout(5)
        jqsptk(inst)
    end,
    timeline={

    },     
        onupdate = function(inst)
            if inst.td_atk or (KEYTYPE and inst.ktnmousel) then inst.sg:GoToState("juhe_s")  end
            if inst.td_qrz then inst.sg:GoToState("juhe_l")  end
        end,
        ontimeout = function(inst)
            inst.Physics:ClearMotorVelOverride()
            local td = inst.taidao
            if td then td.needue = true inst.components.inventory:GiveItem(td) end
            inst.sg:GoToState("heavylifting_item_hat")
        end,

    onexit = function(inst)
    inst.AnimState:SetDeltaTimeMultiplier(1)
    end,
})
AddStategraphState('wilson', 
  State{
    name = 'evade_pre',
    tags = {"busy","tent","evading","nopredict","ktnsg","nofreeze"},
    onenter = function(inst)
        inst.Physics:Stop()
        --inst.components.hunger:DoDelta(-5)
        inst.components.locomotor:Clear()
        inst:AddTag("ktninvincible")
        inst.ktninvincible = true
        if inst.components.pinnable.canbepinned then 
        inst.ktncantbepine = true inst.components.pinnable.canbepinned = false end
        inst.canuseevade = nil 
        inst.AnimState:SetDeltaTimeMultiplier(1.25)
        inst.AnimState:PlayAnimation("evade_pre")
        inst.evade_right = nil
        inst.evade_back = nil
        inst.evade_left = nil
        inst.evade_index = CreateEntity()
        --tdinvincible(inst,0)
        local ab = inst.evade_index ab:AddTag("FX") ab:AddTag("INLIMBO")
        ab.entity:AddTransform() MakeInventoryPhysics(ab)
        ab.Transform:SetPosition(inst.Transform:GetWorldPosition())
        ab.Transform:SetRotation(inst.td_heading or inst.Transform:GetRotation())
        ab.Physics:SetMotorVelOverride(36,0,0)
        ab:DoTaskInTime(1*FRAMES,function() 
        ab.Transform:SetRotation(inst.td_heading or inst.Transform:GetRotation()) 
        ab:DoTaskInTime(1*FRAMES,function() 
        local distor = math.sqrt(ab:GetDistanceSqToInst(inst.ktnbench_r or inst)) 
        local distol = math.sqrt(ab:GetDistanceSqToInst(inst.ktnbench_l or inst))
        local distoi = math.sqrt(ab:GetDistanceSqToInst(inst))
        local distof = math.sqrt(ab:GetDistanceSqToInst(inst.ktnbench or inst))
        if distor > distol+.6 then inst.evade_left = true 
           elseif distor < distol-.6 then inst.evade_right = true 
             elseif distoi<distof then inst.evade_back = true
        end 
        ab.Physics:ClearMotorVelOverride() end) end)
        inst.Physics:ClearMotorVelOverride()
    end,
    timeline={
        TimeEvent(1*FRAMES, function(inst) 
           if inst.components.burnable and inst.components.burnable:IsBurning() then 
              if inst.evadefire then 
                 if inst.evadefire>0 then 
                 inst.evadefire = inst.evadefire -1 
                 else inst.evadefire = nil 
                 inst.components.burnable:Extinguish()
                 end
              else inst.evadefire = 2
              end
            else inst.evadefire = nil 
            end
        end),  
    },     
        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("evade")
                end
            end),
        },
    onexit = function(inst)
    --canceljq(inst) 
    if inst.ktncantbepine then 
       inst.ktncantbepine = nil inst.components.pinnable.canbepinned = true end
    inst.ktninvincible = nil
    inst:RemoveTag("ktninvincible")
    if inst.evade_index then inst.evade_index:Remove() end
    inst.AnimState:SetDeltaTimeMultiplier(1)
    end,
})
AddStategraphState('wilson', 
  State{
    name = 'evade',
    tags = {"nopredict","busy","evading","notalking","ktnsg"},
    onenter = function(inst,inidle)
        if inidle then changerot(inst) inst.evade_right = nil inst.evade_left = nil inst.evade_back = nil end
        inst.Physics:Stop()
        inst.AnimState:SetDeltaTimeMultiplier(1.6) 
        local lorr = (inst.evade_right and "_l") or (inst.evade_left and "_r") or (inst.evade_back and "_back") or ""
        inst.AnimState:PlayAnimation("evade"..lorr)
        local spd = (inst.evade_right and 1) or (inst.evade_left and -1) or nil
        local fob = inst.evade_back and -1 or 1
        jqsptk(inst,inst,3.6,-0.5,fob,2,spd)
    end,
    timeline={
        TimeEvent(2*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
        end),
        TimeEvent(16*FRAMES, function(inst)
        inst.canusejszaftevade = true
        end),
        TimeEvent(23*FRAMES, function(inst)
        if not inst.evade_back then
        inst.sg:RemoveStateTag("busy") end
        end),
    },     
            events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle") --ThePlayer.sg:GoToState("evade")
                end
            end),
        },
    onupdate = function(inst)     
        if (inst.evade_right or inst.evade_left) and inst.canusejszaftevade then
            if (inst.jszhankey or (inst.ktnmouser and inst.ktnmousel)) then 
                --inst.jszhanr = inst.evade_right inst.jszhanl = inst.evade_left 
                inst.sg:GoToState("jszhan_pre")
            end
        end
    end,
    onexit = function(inst) 
    jqsptk(inst)
    inst.canusejszaftevade = nil
    inst.AnimState:SetDeltaTimeMultiplier(1) 
    inst.Physics:ClearMotorVelOverride()
    end,
})
AddStategraphState('wilson', 
  State{
    name = 'kanpo_pst',
    tags = {"autopredict","abouttoattack","jianqie","busy",'attack'},
    onenter = function(inst)
        inst.Physics:Stop()
        --if not KEYTYPE then inst.sg:RemoveStateTag("busy") end
        inst.AnimState:PlayAnimation("jianqie_pst")
    end,
    timeline={
                TimeEvent(2*FRAMES, function(inst)
                if inst.jqhitit then
                   inst.canedged = true end
                   inst.sg:RemoveStateTag("abouttoattack")
                end),
    },     
            events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    onexit = function(inst) 

    inst.jqhitit=nil inst.canedged = nil 
    inst.Physics:ClearMotorVelOverride()
    end,
})
AddStategraphState('wilson', 
  State{
    name = 'kanpo',
    tags = {'busy',"jianqie","attack","abouttoattack","nopredict","ktnsg","pausepredict","notandao"},
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()
        changerot(inst,nil,nil)
        inst.jqhitit=nil
        local td = inst.taidao
        if td and td.components.edgerank.qiren >= 0.1 then

        tdinvincible(inst,1)
        inst.jqinvincible = true
        inst.SoundEmitter:PlaySound("longsword/katana/jq_dodge") 
                local ab = inst.ktnindex
local pt = Vector3(ab.Transform:GetWorldPosition() )local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, 7)
    for k,v in pairs(ents) do local cbt = v.components.combat
        if cbt and not cbt.areahitrange and cbt.target and cbt.target == inst and not v.cbt_range then 
           v.cbt_range = cbt.hitrange cbt.hitrange = 10 --hit me      
           if not v.cbt_range_autosd then v.cbt_range_autosd= v:DoPeriodicTask(.2,function() 
            if not v.cbt_range then niltask(v,"cbt_range_autosd") return end
            if cbt and cbt.target and cbt.target ~= inst then 
            cbt.hitrange=v.cbt_range niltask(v,"cbt_range_autosd") v.cbt_range = nil  end end)
           end      
        end
    end
else         inst.SoundEmitter:PlaySound("longsword/katana/jq_noqr")  inst.noqrjq = true
end
        if td then
           td.components.edgerank:ClearQr() end
        inst.sg:SetTimeout(1.6) 
        jqsptk(inst,inst,3.6,0.2,-1,2)
        inst.ktnjqable = nil
        inst.AnimState:SetDeltaTimeMultiplier(1)
        inst.AnimState:PlayAnimation("jianqie_pre")

    end,
    timeline={
        TimeEvent(1*FRAMES, function(inst)
        jqsptk(inst)
        jqsptk(inst,inst,3.7,0.42,-1,2)
        end),
    	TimeEvent(7*FRAMES, function(inst)
        if inst.jqinvincible then local s = 2
        crefx(inst,"qr_fx","qr_fx","kanpo",Vector3(s, s, s),nil,0,function(ab) 
        local rota = inst.Transform:GetRotation()
        ab.Transform:SetRotation(rota+180)
        ab.AnimState:SetDeltaTimeMultiplier(1.2) ab.AnimState:SetFinalOffset(1)
        end,true,Vector3(0, 0, 0)) end
        jqsptk(inst)
        inst.Physics:ClearMotorVelOverride()
        jqsptk(inst,inst,2.7,-0.2,-1,2)
        end),  
        TimeEvent(18*FRAMES, function(inst)
        inst.ktnjhable = true inst.ktndlable = true    
        end),  
        TimeEvent(17*FRAMES, function(inst)
        jqsptk(inst)  
        inst.Physics:ClearMotorVelOverride()
        jqsptk(inst,inst,1.2,-0.1,1,3)
        end),  
        TimeEvent(23*FRAMES, function(inst)
        changerot(inst,60)  
        canceljq(inst) 
        end),  
        TimeEvent(25*FRAMES, function(inst)

        inst.ktnjhable = nil inst.ktndlable = nil
        inst.SoundEmitter:PlaySound("longsword/katana/jq_atk")       
        end),          
        TimeEvent(27*FRAMES, function(inst)
        inst.Physics:SetMotorVelOverride(16,0,0)
        jqsptk(inst) 
        inst.sg:RemoveStateTag("transform")
        inst.Physics:ClearMotorVelOverride()
        jqsptk(inst,inst,4,-0.42,1,2)
        inst.AnimState:SetDeltaTimeMultiplier(1)
        inst.AnimState:PlayAnimation("jianqie")
        end),  
        TimeEvent(39*FRAMES, function(inst) 
        if inst.delayremovefatg then
        inst:RemoveTag("fat_gang") end
        ktnatk(inst,3.4) 
        end),
        TimeEvent(41*FRAMES, function(inst)
        jqsptk(inst)
        inst.Physics:ClearMotorVelOverride()
        end),  
        TimeEvent(47*FRAMES, function(inst)
        inst.sg:RemoveStateTag("drowning")--delay the inv time
        end),  
    },     
        onupdate = function(inst)      
        end,

        ontimeout = function(inst)
            inst.Physics:ClearMotorVelOverride()
            inst.sg:GoToState("kanpo_pst") 
        end,

    onexit = function(inst)    
    jqsptk(inst) 
    niltask(inst,"juherot")
        if inst.delayremovefatg then
        inst:RemoveTag("fat_gang") end
    inst.jqinvincible = nil
    inst.noqrjq = nil
    inst.jqdodgeit = nil
    inst.AnimState:SetDeltaTimeMultiplier(1)
    canceljq(inst)
    inst.components.health.externalabsorbmodifiers:RemoveModifier(inst,"ktn_jiahu")
    end,
})



AddStategraphState('wilson', 
  State{
    name = 'dlz',
    tags = {'busy',"denlong","denlongzhan","nokarousg","abouttoattack","nopredict","attack","ktnsg","notandao"},
    onenter = function(inst)
        inst.dlzjqt = nil
        inst.components.locomotor:Stop()
        inst.DynamicShadow:Enable(false)
        inst.AnimState:SetDeltaTimeMultiplier(inst.autodlz and 2.3 or 1.2) 
        inst.AnimState:PlayAnimation("dlz")  
        inst.Physics:SetMotorVelOverride(0,inst.autodlz and 0 or 15,0)

        --[[if not inst.ifonsea then inst.ifonsea = SpawnPrefab("ktnfx") 
        inst.ifonsea:DoPeriodicTask(.1,function()local pt = inst:GetPosition() if pt then 
        inst.ifonsea.Transform:SetPosition(pt.x,0,pt.z) end end) end --]]

        inst.sg:SetTimeout(3.4)
    end,
    timeline={
        TimeEvent(1*FRAMES, function(inst)
   local t = inst.autodlz and -25 or 30
  if not inst.dl3 then inst.dl3 = inst:DoPeriodicTask(FRAMES,function()
   t = t - 25
   local xspeed = 0
   inst.Physics:SetMotorVelOverride(xspeed,t<-60 and -60 or t,0)
     end) end
        end),
        TimeEvent(16*FRAMES, function(inst)
        end),  
        
    },     
        onupdate = function(inst)
        --[[
        if inst.ifonsea and inst.ifonsea:IsValid() and not inst.ifonsea:IsOnPassablePoint() then 
           local posi = inst.ifonsea:GetPosition() local dest = GLOBAL.FindNearbyLand(posi, 12)
        if dest ~= nil then inst.components.talker:Say((MOD_KTN_LANGUAGE_SETTING and '我会掉到海里的 ！')or "I will fall into the ocean !")
           local pt = dest local pos = inst:GetPosition()
           inst.Transform:SetPosition(pt.x,pos.y,pt.z) end end ]]

        local x = nil
        if inst.dlzjqt then
        x = GetTime() - inst.dlzjqt
       if x>= 1.8 then
       inst.canuseevade = true
       elseif x >= 1.3 and not inst.playdlpst then
             inst.playdlpst = true
             --inst.SoundEmitter:PlaySound("longsword/katana/dlz_last")   
             inst.AnimState:SetDeltaTimeMultiplier(1.2) 
             inst.AnimState:PlayAnimation("dlz_pst") 
         elseif x > 0.9 then
           --inst.sg:RemoveStateTag("abouttoattack")
           inst.canuseevade = true
           inst.ktnjqable = true 
         elseif x>= 0.36 then 
           inst.ktnjhable = true
           end
        end
 
             local x, y, z = inst.Transform:GetWorldPosition() 
             if y <= 0.25 and not inst.dlzdone then 
                inst.DynamicShadow:Enable(true)
                local td = inst.taidao
                local rk = (td and td.components.edgerank.rank) or 1
                local bt = (td and (td.components.edgerank.damagebt^7)*.5) or .5
             	    if inst.taidao then 
       inst.taidao.components.edgerank:LevelUp(-1) end
             	inst.dlzdone = true 
             	inst.sg:SetTimeout(2.3)
                inst.dlzjqt = GetTime()
             	inst.sg:RemoveStateTag("denlong")
             	inst.AnimState:PlayAnimation("dlz_land")     
             	niltask(inst,"dl3")
             	inst.Physics:ClearMotorVelOverride() 
             	inst.Physics:SetMotorVelOverride(0,0,0) 
             	local ab = SpawnPrefab("ktnfx") 
             	ab.Transform:SetPosition(inst.ktnbench_far.Transform:GetWorldPosition())
                createlight(ab,Vector3(150,46,46),.3,.2,1.5)
                inst.SoundEmitter:PlaySound("longsword/katana/dlz_din")
                qichangcool(inst,5,1,ab)
                ktnatk(inst,2.3,bt,ab) 
                if td then
                td:AddTag("nosharpconsume") td:AddTag("noqrdelta")
                td:DoTaskInTime(1.5,function()td:RemoveTag("nosharpconsume") td:RemoveTag("noqrdelta") end) end

             	inst:DoTaskInTime(.2,function()
                --if inst.dlzpt and inst.dlzpt:IsValid() then
                --ab.Transform:SetPosition(inst.dlzpt.Transform:GetWorldPosition()) end
                ab.AnimState:SetBank("abigail_shield") ab.AnimState:SetBuild("abigail_shield") ab.AnimState:PlayAnimation("shield_retaliation")
                ab.Transform:SetScale(.05, 6, .05)
                ab:ListenForEvent("animover", ab.Remove)          
                ab.AnimState:SetMultColour(255/255,0/255,0/255,1) 
            inst:StartThread(function()
                for k = 1, 7 do
        local pt = Vector3(ab.Transform:GetWorldPosition() )
        local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, 1+rk)
        local ents2 = TheSim:FindEntities(pt.x,pt.y,pt.z, (1+rk)^2)
        for k,v in ipairs(ents) do local wb = v.components.workable
            if wb and (wb.action == ACTIONS.CHOP or wb.action == ACTIONS.MINE) and wb.workleft > 0 and not v:HasTag("gesplant") then
                wb:WorkedBy(inst,rk)
            end
        end
            for k,v in ipairs(ents2) do local wb = v.components.workable
            if wb and wb.workleft > 0 and v:HasTag("mushroomsprout") then
                wb:WorkedBy(inst,rk+1)
            end
        end
            Sleep(.1)
                end
            end)
                end)
             end
               if inst.dlzdone and inst.td_qrz and inst.td_space then 
                   inst.sg:GoToState("nadao") 
               end

        end,


        ontimeout = function(inst)    
            inst.sg:GoToState("idle") 
               niltask(inst,"checkaftdlzjq")
               inst.setjqaftdlzt = inst:DoTaskInTime(1,function() inst.ktnjqable = nil niltask(inst,"checkaftdlzjq") niltask(inst,"setjqaftdlzt") end)
               inst.checkaftdlzjq = inst:DoPeriodicTask(FRAMES,function() 
                    local sgne = inst.sg.currentstate.name
                    if not(sgne == "idle" or sgne == "dlz") or inst.ktn_iswalking then niltask(inst,"checkaftdlzjq") niltask(inst,"setjqaftdlzt") inst.ktnjqable = nil else inst.ktnjqable = true end 
               end)
        end,

    onexit = function(inst)    
    inst.DynamicShadow:Enable(true)
    ChangeToCharacterPhysics(inst)
    inst.checkifmovedlz = nil
    inst.playdlpst = nil
    inst.dlzdone = nil
    inst.ktnjqable = nil
    inst.dlzpt = nil
    inst.autodlz = nil
    inst.canuseevade = nil
    if inst.ifonsea then inst.ifonsea:Remove() inst.ifonsea = nil end
    niltask(inst,"dl3")
      inst.Physics:ClearMotorVelOverride()
      inst.AnimState:SetDeltaTimeMultiplier(1)
    end,
})

AddStategraphState('wilson', 
  State{
    name = 'dlz_pre',
    tags = {"moving", "busy", "drowning","denlong","ktnsg"},
    onenter = function(inst,walk)
        inst.sg.statemem.walkdl = walk
        inst.DynamicShadow:Enable(false)
        inst.AnimState:SetDeltaTimeMultiplier(1) 
        inst.AnimState:PushAnimation("dlz_loop")
        inst.dl2t = -1 inst.dl2bt = -.2
        inst.Physics:SetMotorVelOverride(walk and 2 or 0,-1.2,0)  
    end,
    timeline={
        TimeEvent(2*FRAMES, function(inst)
        end),  
        TimeEvent(5*FRAMES, function(inst)  
        inst.dlzpermission = true
        end),
    },     

        onupdate = function(inst)
         inst.dl2t = inst.dl2t+inst.dl2bt
         local yspeed = (inst.dl2t^3)/1.2
         inst.Physics:SetMotorVelOverride(inst.sg.statemem.walkdl and 2 or 0,yspeed<-8 and -8 or yspeed,0)  
        local x, y, z = inst.Transform:GetWorldPosition() 

        if inst.dlzpermission and (inst.td_qrz or (not KEYTYPE and inst.td_atk ) or (KEYTYPE and inst.ktnmousel)) then
           inst.sg:GoToState("dlz") 
           changerot(inst) 
        end

        if y <= 1 then 
           inst.autodlz = true
           inst.sg:GoToState("dlz")
           end
        end,
        ontimeout = function(inst)
            
        end,

    onexit = function(inst)    
    inst.dlzpermission = nil
    inst.DynamicShadow:Enable(true)
    inst.AnimState:SetDeltaTimeMultiplier(1)
    end,
})


AddStategraphState('wilson', 
  State{
    name = 'dl_jump',
    tags = {"moving", "busy", "canrotate", "drowning","denlong","ktnsg"},
    onenter = function(inst)
        local randombt = math.random()*0.05
        inst.AnimState:SetDeltaTimeMultiplier(inst.jumpquickdl and 1.23-randombt or 1) 
        inst.AnimState:PlayAnimation("dlz_jump")
        inst.sg:SetTimeout(inst.jumpquickdl and 1.2+randombt or 1.35)
        inst.dl2t = 1.2 inst.dl2bt = .05 inst.dl2horz = 2.5 inst.dl2horzbt = 0
        inst.Physics:SetMotorVelOverride(2,1.2,0)  
    end,
    timeline={
        TimeEvent(9*FRAMES, function(inst)
        inst.DynamicShadow:Enable(false)
        end),  
        TimeEvent(18*FRAMES, function(inst)
        inst.SoundEmitter:PlaySound("longsword/katana/dlz_rot")    
        end),
        TimeEvent(22*FRAMES, function(inst)
        changerot(inst,90) 
        local w = inst.ktn_iswalking
        inst.sg.statemem.walkdl = inst.ktn_iswalking
        inst.dl2t = 3.5 inst.dl2bt = -.25 inst.dl2horz = w and 5 or 0 inst.dl2horzbt = w and -.1 or 0
        end),  
    },     

        onupdate = function(inst)
         inst.dl2t = inst.dl2t+inst.dl2bt
         inst.dl2horz = inst.dl2horz + inst.dl2horzbt 
         inst.Physics:SetMotorVelOverride(inst.dl2horz < 2 and 2 or inst.dl2horz,(inst.dl2t^3)*1,0)
        end,
        ontimeout = function(inst)
            inst.sg:GoToState("dlz_pre",inst.sg.statemem.walkdl)
        end,

    onexit = function(inst)    
    inst.DynamicShadow:Enable(true)
    inst.AnimState:SetDeltaTimeMultiplier(1)
    inst.qrdghit = nil
    end,
})

AddStategraphState('wilson', 
  State{
    name = 'qrdg_pre2',
    tags = {'busy',"jianqie","nopredict",'qrdg',"ktnsg"},
    onenter = function(inst)
        inst.Physics:Stop()
        inst.components.locomotor:Clear()
        local speed = inst.slowdlpre and 0.9-math.random()*0.15 or 1.1
        inst.AnimState:SetDeltaTimeMultiplier(speed) 
        inst.AnimState:PlayAnimation("douge_pre2",false) 
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()
        inst.sg:SetTimeout(1.8-speed)
 if inst.taidao and inst.taidao.components.edgerank.rank>0 then
        if inst.taidao.components.edgerank.rank>2 and not inst.slowdlpre then inst:SetCameraZoomed(true) end
        crefx(inst,"halloween_embers","halloween_embers","puff_3",Vector3(.6,.6,.6),true,0,function(ab) createlight(ab,Vector3(150,46,46),.4) ab.AnimState:SetMultColour(255/255,0/255,0/255,.7) end)
        inst.SoundEmitter:PlaySound("longsword/katana/qrdg_pre")
        inst.SoundEmitter:PlaySound("longsword/katana/qrdg_sec")   
 else   inst.SoundEmitter:PlaySound("longsword/katana/zayin","ktnzayin") 
 end
        changerot(inst,60)

    end,
    timeline={
        TimeEvent(1*FRAMES, function(inst)inst.Physics:SetMotorVelOverride(-2.7,0,0) end),  
        TimeEvent(12*FRAMES, function(inst)inst.Physics:ClearMotorVelOverride() end),  

        
    },     

                events =
        {
            --EventHandler("animover", function(inst)
            --inst.sg:GoToState("qrdg")
            --end),
        },
        ontimeout = function(inst)    
            inst.sg:GoToState("qrdg") 
        end,
    onexit = function(inst) jqsptk(inst)
    inst:DoTaskInTime(2*FRAMES,function()if not inst.sg:HasStateTag("qrdg") then inst:SetCameraZoomed(false) end end)
    inst.Physics:ClearMotorVelOverride()
    inst.AnimState:SetDeltaTimeMultiplier(1) 
    inst.slowdlpre = nil
    end,
})
AddStategraphState('wilson', 
  State{
    name = 'qrdg_pre',
    tags = {'busy',"jianqie","nopredict",'qrdg',"ktnsg"},
    onenter = function(inst)
        inst.Physics:Stop()
        inst.components.locomotor:Clear()
        local n = (inst.doquickdl and 3) or 1
        local t = (inst.doquickdl and 3-math.random()) or 1+math.random()*0.5
        inst.AnimState:SetDeltaTimeMultiplier(1.1*math.pow(t,1/4)) 
        inst.AnimState:PlayAnimation("douge_pre"..n.."",false)
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()
        --inst.sg:SetTimeout(.8)
        GLOBAL.PlayFootstep(inst, 1, true)
        if not inst.doquickdl then changerot(inst) else changerot(inst,60) 
            if inst.donohitdl then 
            inst:SetCameraZoomed(true)
            inst.sg.statemem.btbyxg = nil
            inst.sg:AddStateTag("drowning")
            inst.sg:AddStateTag("transform")  
            if not inst:HasTag("fat_gang") then inst:AddTag("fat_gang") inst.newfatgremove = true end
            inst.components.health.externalabsorbmodifiers:SetModifier(inst, .8,"ktn_jiahu")end end

    end,
    timeline={
        TimeEvent(2*FRAMES, function(inst)
        if inst.taidao and inst.taidao.components.edgerank.rank>0 then
            crefx(inst,"halloween_embers","halloween_embers","puff_3",Vector3(.6,.6,.6),true,0,function(ab) createlight(ab,Vector3(150,46,46),.4) ab.AnimState:SetMultColour(255/255,0/255,0/255,.7) end)
        	inst.SoundEmitter:PlaySound("longsword/katana/qrdg_pre")
        	inst.SoundEmitter:PlaySound("longsword/katana/qrdg_sec")   
        else        inst.SoundEmitter:PlaySound("longsword/katana/zayin","ktnzayin") 
        end
        inst.Physics:SetMotorVelOverride(-2.3,0,0) end),  
        TimeEvent(12*FRAMES, function(inst)inst.Physics:ClearMotorVelOverride() end),  

        
    },     

                events =
        {
            EventHandler("animover", function(inst)
            inst.sg:GoToState("qrdg")
            end),
        },
        ontimeout = function(inst)       
            inst.sg:GoToState("qrdg") 
        end,
    onexit = function(inst) 
    inst.components.health.externalabsorbmodifiers:RemoveModifier(inst,"ktn_jiahu")
    inst:DoTaskInTime(2*FRAMES,function()if not inst.sg:HasStateTag("qrdg") then inst:SetCameraZoomed(false) end end)
    jqsptk(inst)inst.doquickdl = nil
    if inst.newfatgremove then inst:RemoveTag("fat_gang") inst.newfatgremove = nil end
    inst.Physics:ClearMotorVelOverride()
    inst.AnimState:SetDeltaTimeMultiplier(1) 
    end,
})

local qrdg1= function(inst)
    
        inst.SoundEmitter:PlaySound("longsword/katana/qrdg_hit","dghit")
        inst.SoundEmitter:PlaySound("longsword/katana/qrdg_pst","dgpst")
        local tdhaslevel = inst.taidao and inst.taidao.components.edgerank.rank>0
        if tdhaslevel then local s = 2
        crefx(inst,"hx_fx","hx_fx","qrdg",Vector3(s, s, s),true,0,function(ab) 
        --ab.entity:AddFollower()
        --ab.Follower:FollowSymbol(inst.GUID, "swap_object", 0, -230, 0)
        ab.AnimState:SetDeltaTimeMultiplier(1.23) ab.AnimState:SetFinalOffset(1)
        ab.AnimState:SetMultColour(255/255,0/255,0/255,1)
        end,true,Vector3(2.3, .9, .1))
        end
end
local qrdg2= function(inst)
        inst.sg:RemoveStateTag("drowning")
        if inst.newfatgremove then inst:RemoveTag("fat_gang") inst.newfatgremove = nil end
            inst.AnimState:SetDeltaTimeMultiplier(1)  
        local tdhaslevel = inst.taidao and inst.taidao.components.edgerank.rank>0
        local bench = inst.ktnbench_far or inst
        local eny = FindEntity(bench, 7, function(a)  local range = a:GetPhysicsRadius(0) + 3
         local ac = a.components return distsq(a:GetPosition(), bench:GetPosition()) <= range^2 and IsLife(a,true)and a ~= inst and not (ac.follower and ac.follower.leader == inst )
        and not a:HasTag("wall") and not a:HasTag("player")and not a:HasTag("companion") end) 
        local stone = FindEntity(bench, 2, function(a) local ac = a.components return ac.workable and ac.workable.action == ACTIONS.MINE end) 
        if not eny then 
        local eny = FindEntity(inst, 3, function(a) local ac = a.components return IsLife(a,true)and a ~= inst and (not (ac.follower and ac.follower.leader == inst )
                and not a:HasTag("wall") and not a:HasTag("player")) or (ac.combat and ac.combat.target and ac.combat.target == inst)  end)   
        end
            if (eny or stone) and inst.taidao then inst.taidao.components.edgerank:QrDoDelta(.1)
                 if ((stone and stone.components.workable.workleft > 0) or not stone) and tdhaslevel then inst.qrdghit = eny or stone end
                if eny then
                if inst.donohitdl then
                if eny.sg and eny.sg:HasStateTag("attack") then eny.sg:GoToState("hit") end
                eny.components.combat:RestartCooldown() end
                doatttack(inst,eny,1.5)
                elseif stone then
                local frozen = stone:HasTag("frozen")
                local moonglass = stone:HasTag("moonglass")
                if stone.Transform ~= nil then
                local mine_fx = (frozen and "mining_ice_fx") or (moonglass and "mining_moonglass_fx") or "mining_fx"
                SpawnPrefab(mine_fx).Transform:SetPosition(stone.Transform:GetWorldPosition())
                end
                inst.SoundEmitter:PlaySound((frozen and "dontstarve_DLC001/common/iceboulder_hit") or (moonglass and "turnoftides/common/together/moon_glass/mine") or "dontstarve/wilson/use_pick_rock")
                stone.components.workable:WorkedBy(inst,2) 
                    if inst.taidao.components.sharpness then inst.modaot = 4 
                       inst.taidao.components.sharpness:Consume() end
                end
                inst.SoundEmitter:KillSound("dgpst")
        local ab = SpawnPrefab("ktnfx") inst:AddChild(ab) ab.Transform:SetPosition(.5,2,0)
              ab.AnimState:SetBank("moonglass_charged") ab.AnimState:SetBuild("moonglass_charged_tile") ab.AnimState:PlayAnimation("explosion")
              ab.Transform:SetScale(.27, 7, .27)     
              ab.AnimState:SetFinalOffset(2)
              ab.AnimState:SetOrientation(GLOBAL.ANIM_ORIENTATION.OnGround)
              ab.AnimState:SetLayer(GLOBAL.LAYER_BACKGROUND)
              ab:ListenForEvent("animover", ab.Remove)
              ab.AnimState:SetMultColour(255/255,0/255,0/255,1)
              ab.Transform:SetRotation(math.abs(inst.Transform:GetRotation()*0.01)+90)

            else         
                inst.SoundEmitter:KillSound("dghit")
             end
end

local qrdg3= function(inst)
         if inst.qrdghit then 
         inst.AnimState:SetDeltaTimeMultiplier(0.3) end
         jqsptk(inst)
         inst.Physics:ClearMotorVelOverride()
         inst.Physics:SetMotorVelOverride(-1.5,0,0)
end
local qrdg4= function(inst)
         jqsptk(inst)
         inst.Physics:ClearMotorVelOverride()
        if inst.qrdghit then
        inst.jumpquickdl = inst.donohitdl
        inst.sg:GoToState("dl_jump") end
end

AddStategraphState('wilson', 
  State{
    name = 'qrdg',
    tags = {'busy',"nopredict",'qrdg',"ktnsg","notandao"},
    onenter = function(inst)
        local nohit = inst.donohitdl
           if nohit then 
           inst.sg.statemem.btbyxg = nil
           inst.sg:AddStateTag("drowning")
           inst.sg:AddStateTag("transform")
           if not inst:HasTag("fat_gang") then inst:AddTag("fat_gang") inst.newfatgremove = true end
           inst.components.health.externalabsorbmodifiers:SetModifier(inst, .8,"ktn_jiahu") end
        inst.Physics:Stop()
        inst.components.locomotor:Clear()
        inst.qrdghit = nil
        inst.AnimState:SetDeltaTimeMultiplier((nohit and 2.2) or 1.6)  
        inst.AnimState:PlayAnimation("douge")
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()
    end,
    timeline={
        TimeEvent(1*FRAMES, function(inst)
        jqsptk(inst)
        qichangcool(inst,1,.2)
        GLOBAL.PlayFootstep(inst, 1, true)
        inst.Physics:ClearMotorVelOverride()
        jqsptk(inst,inst,0.7,inst.donohitdl and 1.4 or .9,1,2) end), 

        TimeEvent(10*FRAMES, function(inst)
        inst:SetCameraZoomed(false)
        qichangcool(inst,1.5,.25)
        GLOBAL.PlayFootstep(inst, 1, true)
        jqsptk(inst)
        inst.Physics:ClearMotorVelOverride()
        jqsptk(inst,inst,3.7,-0.2,1,2) end),  
        TimeEvent(12*FRAMES, function(inst)
        end),

        TimeEvent(7*FRAMES, function(inst) 
        if inst.donohitdl then
        qrdg1(inst) end
        end),    
        TimeEvent(16*FRAMES, function(inst) 
        qichangcool(inst,2,.3)
        if inst.donohitdl then
        qrdg2(inst) end
         end),  
         TimeEvent(19*FRAMES, function(inst)
        qichangcool(inst,2,.35)
        if inst.donohitdl then
        qrdg3(inst) end
         end),
        TimeEvent(20*FRAMES, function(inst)
        qichangcool(inst,2,.35)
        if inst.donohitdl and not inst.qrdghit then
           qrdg2(inst) end
         end),
        TimeEvent(21*FRAMES, function(inst)
        if inst.donohitdl then
        qrdg4(inst) end
         end), 
        ----------------------------------
        TimeEvent(12*FRAMES, function(inst) 
        if not inst.donohitdl then
        qrdg1(inst) end
        end),    
        TimeEvent(23*FRAMES, function(inst) 
        if not inst.donohitdl then
        qrdg2(inst) end
         end),  
         TimeEvent(27*FRAMES, function(inst)
        qichangcool(inst,2,.4)
        if not inst.donohitdl then
        qrdg3(inst) end
         end),
        TimeEvent(28*FRAMES, function(inst)
        if not inst.donohitdl and not inst.qrdghit then
           qrdg2(inst) end
         end),
        TimeEvent(30*FRAMES, function(inst)
        if not inst.donohitdl then
        qrdg4(inst)else inst.canuseevade = true end
         end), 
        TimeEvent(45*FRAMES, function(inst)
        inst.canuseevade = true
         end), 
        
    },     
            onupdate = function(inst)

        end,

                events =
        {
            EventHandler("animover", function(inst)
                   inst.sg:GoToState("idle")
            end),
        },

    onexit = function(inst) jqsptk(inst)
    inst.SoundEmitter:KillSound("dgpst")
    inst.SoundEmitter:KillSound("dghit")
    inst.components.health.externalabsorbmodifiers:RemoveModifier(inst,"ktn_jiahu")
    jqsptk(inst)
    inst.donohitdl = nil
    inst.canuseevade = nil
    if inst.newfatgremove then inst:RemoveTag("fat_gang") inst.newfatgremove = nil end
    inst:SetCameraZoomed(false)
    inst.Physics:ClearMotorVelOverride()
    inst.AnimState:SetDeltaTimeMultiplier(1) 
    end,
})

AddStategraphState('wilson', 
  State{
    name = 'hitfall',
    tags = {"busy","drowning"},
    onenter = function(inst)
        inst.haslanded = nil
        niltask(inst,"checkbeenhit")
        inst.components.locomotor:Stop()
        inst.AnimState:SetPercent("buck_pst",0.3)
        inst.Physics:SetMotorVelOverride(1,-23,0)
        inst.sg:SetTimeout(2.5)
        inst.components.hunger:DoDelta(-5)
        inst.ktninvincible = true
        inst:AddTag("ktninvincible")
    end,
    timeline={
    },     

        onupdate = function(inst)
      if not inst.haslanded then 
        local pt = inst:GetPosition()
          if pt.y< .5 then 
        inst.haslanded = true inst.playrbn = 0.3 inst.Physics:ClearMotorVelOverride()
        inst.canuseevade = true
        if not inst.playrbth then inst.playrbth = inst:DoPeriodicTask(.01,function() 
         local n = inst.playrbn inst.playrbn = n+0.023 
         if n<1 then inst.AnimState:SetPercent("buck_pst",n)
        else inst.sg:GoToState("idle") niltask(inst,"playrbth") end end) end
          end
      end
 
        end,
        ontimeout = function(inst)

        inst.sg:GoToState("idle")
        end,

    onexit = function(inst)    
    inst.ktninvincible = nil
    inst:RemoveTag("ktninvincible")
    niltask(inst,"playrbth")
    inst.Physics:ClearMotorVelOverride()
    inst.AnimState:SetDeltaTimeMultiplier(1)
    
    end,
})






























