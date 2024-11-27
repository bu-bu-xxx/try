    local qrclist = {0}
    local qrclistn = 0
    while qrclistn < 1 do
    qrclistn = qrclistn+.01
    table.insert(qrclist,qrclistn)
    end
local function removealltag( inst)
    for k,v in pairs(qrclist) do
        if inst:HasTag("ktnqr_"..v.."") then
           inst:RemoveTag("ktnqr_"..v.."")
   end end
end

local function oncurrent(self)
    self.inst.currentQrPercent:set(self.qiren)
end

local Edgerank = Class(function(self, inst)
    self.inst = inst
    self.qractive = nil
    self.qiren = 0
    self.rank = 0
    self.maxwork = -1
    self.damagebt = 1
    self.updatetask = self.inst:DoPeriodicTask(6*FRAMES,function()

    self.owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
    if self.owner then
    local sp = self.inst.components.sharpness
    local spbt = (sp and sp:GetTimes()) or 1
    self.inst.components.weapon.damage = TUNING.KTNDAMAGE* self.damagebt * spbt
    self.owner.ktnlevel = self.rank
    self.owner.ktnqrn = self.qiren

        if self.rank == 1 then 
            self.damagebt = 1.05
            self.owner:AddTag("rankwhite")
            self.owner:RemoveTag("rankyellow")
            self.owner:RemoveTag("rankred")         
            elseif self.rank == 2 then 
            self.damagebt = 1.1
            self.owner:AddTag("rankyellow")
            self.owner:RemoveTag("rankwhite")
            self.owner:RemoveTag("rankred")   
                 elseif self.rank == 3 then 
            self.damagebt = 1.2
            self.owner:AddTag("rankred")
            self.owner:RemoveTag("rankwhite")
            self.owner:RemoveTag("rankyellow")   
        else  
            self.damagebt = 1
            self.owner:RemoveTag("rankwhite")
            self.owner:RemoveTag("rankyellow")   
            self.owner:RemoveTag("rankred")   
        end

        if self.qractive then 
        self.owner:AddTag("ktnactive")
        self.owner.ktnactive = true
        if self.qiren < 1 then
        self.qiren = self.qiren +0.01 else self.qiren = 1 end
        local str = string.format("%.2f", self.qiren)
        self.qiren = tonumber(str)

        else 
             self.owner:RemoveTag("ktnactive")
             self.owner.ktnactive = nil
        end
        removealltag(self.owner)
        self.owner:AddTag("ktnqr_"..self.qiren.."")

    end

     end)
end)



function Edgerank:ActiveQr(time)
    self.qractive = true
    if self.cancelqr then self.cancelqr:Cancel() self.cancelqr = nil end
    self.cancelqr = self.inst:DoTaskInTime(time or 12,function() self.qractive = nil
    self.cancelqr:Cancel() self.cancelqr = nil end)
end

function Edgerank:GetRankLevel()
    return self.rank
end

function Edgerank:ClearQr()
   self.qiren = 0
end
function Edgerank:LevelUp(num)
    if not self.owner then return end
    num = num or 1
    local rank = self.rank
    local result = self.rank +num
    if result <0 then 
    self.rank = 0 
    elseif result <= 3 then
    self.rank = result
    else
    self.rank = 3
    end
    if not (self.rank == 0 and rank == 0) then
      if self.rank>=rank then  self:ClearQr() end
        local tag = (self.rank>=rank and "ktnlevelup") or "ktnleveldown"
    self.owner:AddTag(tag) self.owner.ktnlevelup = true
    local player = self.owner
    player:DoTaskInTime(1,function() player:RemoveTag(tag) player.ktnlevelup = nil end)
    self.owner:PushEvent("levelchange", { rank = self.rank, qiren = self.qiren}) end
end

function Edgerank:QrDoDelta(num)
    local qr = self.qiren 
    num = num or 0
        if self.inst:HasTag("noqrdelta") and num>0 then return end
    local result = self.qiren +num
    if result < 0 then
    self.qiren = 0    
    elseif result <= 1 then
    self.qiren = result
    else
    self.qiren = 1
    end
    local str = string.format("%.2f", self.qiren)
    self.qiren = tonumber(str)
    if qr ~= self.qiren and self.owner then 
        removealltag(self.owner)
        self.owner:AddTag("ktnqr_"..self.qiren.."") end
end

function Edgerank:GetQrLevel()
    return self.qiren
end

function Edgerank:OnUpdate(dt)
    local time = GetTime()

    if time then
    end
end

function Edgerank:OnSave()
    return {
                rank = tostring(self.rank),
                qiren = tostring(self.qiren),
                active = self.qractive
            }
end

function Edgerank:OnLoad(data)

    if data.active then
    self:ActiveQr(math.random()*12) --Thats Fine
    end

    --oncurrent(self) 

    if data.qiren and type(data.qiren) == "string" then
       local str = string.format("%.2f", data.qiren)
       self.qiren = tonumber(str)
    end

    if data.rank and type(data.rank) == "string" then
       local str = string.format("%.2f", data.rank)
       self.rank = tonumber(str)
    end
end

return Edgerank
