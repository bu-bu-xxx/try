------斩味系统------ --liximi大大的我看不懂 重新写了个 --

local function oncurrent(self)
    self.inst.currentSharpPercent:set(self.percent)
end

local function OnHitOther(self,owner,targ,slot)
       local gen = 20 
       local stiff = 0 local allit = 0 
    for k,v in pairs(slot) do
        if PrefabExists(v) then
        local vp = SpawnPrefab(v)
        local eat = vp.components.edible
            if vp and ((eat and (eat.foodtype == FOODTYPE.ELEMENTAL or eat.foodtype == FOODTYPE.GEARS)) ) then
                stiff = stiff +1 allit = allit+1
            elseif vp then 
                allit = allit+1
            end
            if vp then vp:Remove() end
        end
    end
        local absorb = targ.components.health.absorb >0 and(1-targ.components.health.absorb) or 1
        gen = gen/absorb
        if targ:HasTag("epic") then gen = gen + 80 
           elseif targ:HasTag("largecreature") then gen = gen + 30 
                  elseif targ:HasTag("smallcreature") then gen = gen - 30 
                         elseif targ:HasTag("insect") then gen = gen - 80 
        end
        gen = gen + 100*(stiff/allit)
        local nowhard = self.gen_state[self.current_state].hard
        --owner.components.talker:Say(stiff.." , "..allit.." ,,, "..gen.." , "..nowhard)
        if nowhard < gen then 
           local bit = gen*math.random()/nowhard
                   --owner.components.talker:Say(stiff.." , "..allit.." ,,, "..gen.." , "..nowhard.." ? "..bit)
           if bit > 1 then
              self:Consume()
              if owner.sg:HasStateTag("notandao") then owner.SoundEmitter:PlaySound("dontstarve_DLC001/common/iceboulder_hit") return end
                 owner.sg:GoToState("tandao") 
           end
        end
end

local Sharpness = Class(function(self, inst)
    self.inst = inst
    self.max_state = "white"
    self.current_state = "white"

    self.gen_state = {
    white ={
    damagebt = 1.1, maxvalue = 150, hard = 200 },
        blue ={
    damagebt = 1, maxvalue = 250, hard = 120 },
        green ={
    damagebt = 0.8, maxvalue = 150, hard = 85 },
        yellow ={
    damagebt = 0.7, maxvalue = 120, hard = 50 },
        red ={
    damagebt = 0.5, maxvalue = 100, hard = 1 },
    } 

    self.current_value = self.gen_state[self.current_state].maxvalue

    self.percent = 1            
    self.consume_rate = 2       
    self.inst:AddTag("Ktn_Sharpness")
   
    self.inst:StartUpdatingComponent(self)
end)

function Sharpness:OnRemoveFromEntity()

    self.inst:RemoveTag("Ktn_Sharpness")
end

function Sharpness:OnSave()
    return {
        current_value = self.current_value,
        current_state = self.current_state,
    }
end

function Sharpness:OnLoad(data)
    if type(data) == "table" then
        for k,v in pairs (data) do
            self[k] = v
        end
    end

end

function Sharpness:TryingToSharpen(inst)
    local act = inst:GetBufferedAction()
    return act ~= nil
        and act.target == self.inst
        and act.action == ACTIONS.SHARPEN 
end


function Sharpness:SetStatesInit(state)   
    self.max_state = state
end

function Sharpness:IsBestState()   
    return self.current_state == self.best_state and self.current_value == self.gen_state[self.current_state].maxvalue
end


function Sharpness:GetTimes()             --获取锐利提供的攻击倍率
    return self.gen_state[self.current_state].damagebt
end

function Sharpness:LevelDown()            --锐利度降级函数

if self.owner then
    local owner = self.owner
    owner:AddTag("ktnsharp_leveldown") 
    owner:DoTaskInTime(.7,function() owner:RemoveTag("ktnsharp_leveldown") end)
end

   if self.current_state == "white" then
      self.current_state = "blue" 
      elseif self.current_state == "blue" then
             self.current_state = "green" 
         elseif self.current_state == "green" then
                self.current_state = "yellow" 
             elseif self.current_state == "yellow" then
                    self.current_state = "red" 
   end
       self.current_value = self.gen_state[self.current_state].maxvalue

end

function Sharpness:DoSharp(doer,object) 
    local isequip = self.inst.components.equippable.isequipped
   if doer and doer.sg and object then
    if not (object.prefab == "redgem" or object.prefab == "goldnugget") then  return end
    if doer.sg and (doer.sg:HasStateTag("busy") or doer.sg:HasStateTag("modao")) then return end
      if not isequip then self.inst.components.equippable:Equip(doer) end
      doer.ktnmds = object
      doer.sg:GoToState("sharpen_pre")
   end  
end

function Sharpness:CheckTD(player,targ,slot)
   if player and targ and targ.components.health and slot then 
      if not player.sg:HasStateTag("attack") or self.inst:HasTag("nosharpconsume") then return end
      OnHitOther(self,player,targ,slot)
   end
end
function Sharpness:Consume()              
    local rate = (((self.current_state == "red" and self.current_value<= 15) or self.inst:HasTag("nosharpconsume")) and 0) or self.consume_rate
    self.current_value = self.current_value - rate
    if self.current_value<=0 then
       self:LevelDown()
    end
end

function Sharpness:Recover()            

   self.current_state = self.max_state
   self.current_value = self.gen_state[self.current_state].maxvalue

    if self.owner then
       local owner = self.owner
       owner:AddTag("ktnsharp_recover") 
       owner:DoTaskInTime(.6,function() owner:RemoveTag("ktnsharp_recover") end)
    end
end

local states = {"blue","green","yellow","red"}

function Sharpness:OnUpdate(dt)

    self.percent = 1-self.current_value/self.gen_state[self.current_state].maxvalue
    self.percent = math.max(self.percent,0)
    oncurrent(self) 
    
    self.owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner
    if self.owner then
    for k,v in pairs(states) do
        if self.owner:HasTag("ktn_sharp_"..v) then
           self.owner:RemoveTag("ktn_sharp_"..v) 
        end
    end
    self.owner:AddTag("ktn_sharp_"..self.current_state)
    end
    

end

return Sharpness