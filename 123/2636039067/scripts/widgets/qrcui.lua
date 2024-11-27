local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"

local qrclist = {0}
local qrclistn = 0
while qrclistn < 1 do
qrclistn = qrclistn+.01
table.insert(qrclist,qrclistn)
end

local QrcUI = Class(Badge, function(self, owner)
    Badge._ctor(self, "qrc", owner)


	self.qrc = self:AddChild(UIAnim())
    self.qrc.animstate = self.qrc:GetAnimState()
	self.qrc.animstate:SetBank("qrc")
	self.qrc.animstate:SetBuild("qrc")
	self.qrc.animstate:PlayAnimation("idle")
    --local s = .7 self.qrc.uianim:SetScale(s, s, s)
    --self.qrc:SetPosition(0, 0, 0) 
	
    self:StartUpdating()
end)

function QrcUI:SetPercent(val, max)
    Badge.SetPercent(self, val, max)
end

function QrcUI:OnUpdate(dt)
    local player = self.owner
        local x = (self.owner:HasTag("ktnlevelup") and 1) or (self.owner:HasTag("ktnleveldown") and 0) or nil
    local active = (player:HasTag("ktnactive") and "_active") or ""
    local level = (player:HasTag("rankwhite") and "_1") or(player:HasTag("rankyellow") and "_2") or(player:HasTag("rankred") and "_3") or""
            if x then 
                if not self.qrcplayanim then
    local anim = (x > 0 and "levelup") or "leveldown"
    self.qrcplayanim = true
    self.qrc.animstate:PlayAnimation(anim) end
    else 
    self.qrcplayanim = nil
    for k,v in ipairs(qrclist) do
        if player:HasTag("ktnqr_"..v.."") then
    self.qrc.percent = v
    self.qrc.animstate:SetPercent("idle"..active..""..level.."",v) end 
        end
    end       
end

return QrcUI