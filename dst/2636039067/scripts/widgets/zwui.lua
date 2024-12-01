local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"

local SharpValueBadge =  Class(Widget, function(self, owner)
    Widget._ctor(self, "SharpValueBadge", owner)
    self.owner = owner
    self.percent = 1

    self.zwAnim = self:AddChild(UIAnim())
    self.zwAnim:GetAnimState():SetBank("sharpness")
    self.zwAnim:GetAnimState():SetBuild("sharpness")
    self.zwAnim:GetAnimState():PlayAnimation("consume_white")
    self.zwAnim:SetClickable(true)
    --self.zwAnim:SetPosition(0, 0, 0) 

    self:StartUpdating()
end)

local states = {"white","blue","green","yellow","red"}

function SharpValueBadge:OnUpdate(dt)
    local weapon = self.owner.replica and self.owner.replica.inventory and self.owner.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    local x = (self.owner:HasTag("ktnsharp_leveldown") and 1) or (self.owner:HasTag("ktnsharp_recover") and 0) or nil
    if weapon ~= nil and weapon:HasTag("Ktn_Sharpness")then 
        self:Show()

    if x then 
       if not self.zwplayanim then
          local anim = (x > 0 and "broke") or "recover"
          self.zwplayanim = true
          self.zwAnim:GetAnimState():PlayAnimation(anim,nil) 
       end
    else
    self.zwplayanim = nil
        self.percent = weapon.currentSharpPercent:value()
      for k,v in pairs(states) do
        if self.owner:HasTag("ktn_sharp_"..v) then
        self.zwAnim:GetAnimState():SetPercent("consume_"..v, self.percent)
        end
      end
    end
    else
            self:Hide()
    end
end

return SharpValueBadge