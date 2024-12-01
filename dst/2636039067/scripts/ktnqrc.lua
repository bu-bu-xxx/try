GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

local function Exist(tar,candeath)
  return tar and tar:IsValid() and ((tar.components.health and not tar.components.health:IsDead() and not tar:HasTag("playerghost")) or candeath)
end
local function IsLife(tar,nowalk)
  return tar.components.combat and tar.Physics and(nowalk or tar.components.locomotor) and tar.components.health
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
local function IsDefaultScreen()
    local screen = GLOBAL.TheFrontEnd:GetActiveScreen()
    return ((screen and type(screen.name) == "string") and screen.name or ""):find("HUD") ~= nil
    and ThePlayer and not(ThePlayer.HUD:IsControllerCraftingOpen() or ThePlayer.HUD:IsControllerInventoryOpen())
end
local function GetWorldControllerVector()
    local xdir = TheInput:GetAnalogControlValue(CONTROL_MOVE_RIGHT) - TheInput:GetAnalogControlValue(CONTROL_MOVE_LEFT)
    local ydir = TheInput:GetAnalogControlValue(CONTROL_MOVE_UP) - TheInput:GetAnalogControlValue(CONTROL_MOVE_DOWN)
    local deadzone = .3
    if math.abs(xdir) >= deadzone or math.abs(ydir) >= deadzone then
        local dir = TheCamera:GetRightVec() * xdir - TheCamera:GetDownVec() * ydir
        local dir = dir:GetNormalized()
        return (-math.atan2(dir.z, dir.x) / DEGREES )
    end
end

local qrcui = require "widgets/qrcui"
local sharpui = require("widgets/zwui")

local function AddQrc(self)
    self.hud_qrc = self.topleft_root:AddChild(qrcui(self.owner))
    --self.hud_qrc:SetPosition(1420, -233, 0)
    self.hud_qrc:SetHAnchor(2)
    self.hud_qrc:SetVAnchor(0)    
    self.hud_qrc:SetPosition(-300, 270, 0)

    self.sharpui = self.topleft_root:AddChild(sharpui(self.owner))
    --self.sharpui:SetScale(5, 5, 5)
    --self.sharpui:SetPosition(1420, -200, 0) 
    self.sharpui:SetHAnchor(2)
    self.sharpui:SetVAnchor(0)    
    self.sharpui:SetPosition(-300, 300, 0)

    local old_update = self.OnUpdate
    function self:OnUpdate(...)
    old_update(self, ...)
    if not self.owner:HasTag("taidaoxia") then self.hud_qrc:Hide() else self.hud_qrc:Show() end
    local per = self.hud_qrc.qrc.percent
    local per = ((per and per>=0) and per) or 0
    local per = ((per and per<=1) and per) or 1
    local per = per - per % 0.01
    self.hud_qrc:SetPercent(per, 100)
    end


end
AddClassPostConstruct("widgets/controls", AddQrc)

local function ChangeUi(inst ,ent)
  local ui = ThePlayer.HUD.controls.hud_qrc.qrc
  if ui then
    ui:GetAnimState():SetPercent("idle_active",.5)
  end

end
AddClientModRPCHandler('qrc', 'qruichange', ChangeUi) -- use this no more 'cause already been fixed

local function OnControlHeading(inst, ent)
    if ent ~= nil then
        inst.ktn_rotchange = true inst:DoTaskInTime(.2,function() inst.ktn_rotchange = nil end)
        inst.td_heading = ent
    end
    return true
end

AddModRPCHandler('ktn', 'changeheading', OnControlHeading)

local function KeydownSpace(inst)
    if inst then
       inst.td_space = true
       niltask(inst,"removekeyspace")
       inst.removekeyspace = inst:DoTaskInTime(.1,function()inst.td_space =nil end)
    end
    return true
end
AddModRPCHandler('ktn', 'keydownspace', KeydownSpace)

local function OnKeyCtrl(inst, ent)
    inst.td_qrz = ent
    return true
end

AddModRPCHandler('ktn', 'keyctrl', OnKeyCtrl)

local function OnKeyAttack(inst, ent)
    inst.td_atk = ent
    return true
end

AddModRPCHandler('ktn', 'keyatk', OnKeyAttack)

local function keyshowindex(inst, ent)
    inst.showdirectindex = ent
    return true
end
AddModRPCHandler('ktn', 'keyshowindex', keyshowindex)

local function keymousel(inst, ent)
    if inst.replica.inventory and inst.replica.inventory:GetActiveItem() then return end
    inst.ktnmousel = ent
    if ent then inst:DoTaskInTime(.15,function() inst.ktnmousel = false end) end
    return true
end

AddModRPCHandler('ktn', 'keymousel', keymousel)
local function keymouser(inst, ent)
    if inst.replica.inventory and inst.replica.inventory:GetActiveItem() then return end
    inst.ktnmouser = ent
    return true
end

AddModRPCHandler('ktn', 'keymouser', keymouser)
local function ktnlocked(inst, ent)
    inst.lockktn = ent
    return true
end
AddModRPCHandler('ktn', 'ktnlocked', ktnlocked)

local function ktnsharpen(inst, ent)
    inst.wanttosharpktn = ent
    return true
end

AddModRPCHandler('ktn', 'ktnsharpen', ktnsharpen)

local function jszhankey(inst, ent)
    inst.jszhankey = ent
    return true
end

AddModRPCHandler('ktn', 'jszhankey', jszhankey)


---------------------Moving----------------------
local function IsWalkButtonDown()
    return (TheInput:IsControlPressed(CONTROL_MOVE_UP) or TheInput:IsControlPressed(CONTROL_MOVE_DOWN) or TheInput:IsControlPressed(CONTROL_MOVE_LEFT) or TheInput:IsControlPressed(CONTROL_MOVE_RIGHT)) and true or nil
end
--[[
local function ismoveleft(inst, ent)
    inst.ismoveleft = ent
    return true
end
AddModRPCHandler('ktn', 'ismoveleft', ismoveleft)

local function ismoveright(inst, ent)
    inst.ismoveright = ent
    return true
end
AddModRPCHandler('ktn', 'ismoveright', ismoveright)

local function ismoveup(inst, ent)
    inst.ismoveup = ent
    return true
end
AddModRPCHandler('ktn', 'ismoveup', ismoveup)

local function ismovedown(inst, ent)
    inst.ismovedown = ent
    return true
end
AddModRPCHandler('ktn', 'ismovedown', ismovedown) ]]

local function ismove(inst, ent)
    inst.ktn_iswalking = ent
    return true
end
AddModRPCHandler('ktn', 'ismove', ismove)
--------------------------------------------------


AddPlayerPostInit(function(inst) 

--if type(KEYTYPE) ~= "number" then

    --KEYX = "X" KEYX = KEYX:lower():byte()
    TheInput:AddKeyDownHandler(KEY_X, function()
      if GLOBAL.TheWorld.ismastersim then 
      if ThePlayer then 
         ThePlayer.showdirectindex = true end
    else SendModRPCToServer( GLOBAL.MOD_RPC.ktn.keyshowindex,true) end
    end)
     TheInput:AddKeyUpHandler(KEY_X, function()
      if GLOBAL.TheWorld.ismastersim then 
      if ThePlayer then 
         ThePlayer.showdirectindex = nil end
    else SendModRPCToServer( GLOBAL.MOD_RPC.ktn.keyshowindex,false) end
    end)
if KTN_JSZHAN then 
    TheInput:AddKeyDownHandler(KTN_JSZHAN, function()
      if GLOBAL.TheWorld.ismastersim then 
      if ThePlayer then 
         ThePlayer.jszhankey = true end
    else SendModRPCToServer( GLOBAL.MOD_RPC.ktn.jszhankey,true) end
    end)
     TheInput:AddKeyUpHandler(KTN_JSZHAN, function()
      if GLOBAL.TheWorld.ismastersim then 
      if ThePlayer then 
         ThePlayer.jszhankey = nil end
    else SendModRPCToServer( GLOBAL.MOD_RPC.ktn.jszhankey,false) end
    end)
end

if KTN_KEYLK then 
    TheInput:AddKeyDownHandler(KTN_KEYLK, function()
      if GLOBAL.TheWorld.ismastersim then 
      if ThePlayer then 
         ThePlayer.lockktn = true end
    else SendModRPCToServer( GLOBAL.MOD_RPC.ktn.ktnlocked,true) end
    end)
     TheInput:AddKeyUpHandler(KTN_KEYLK, function()
      if GLOBAL.TheWorld.ismastersim then 
      if ThePlayer then 
         ThePlayer.lockktn = nil end
    else SendModRPCToServer( GLOBAL.MOD_RPC.ktn.ktnlocked,false) end
    end)
end

if KTN_KEYZW then 
     TheInput:AddKeyDownHandler(KTN_KEYZW, function()
      if GLOBAL.TheWorld.ismastersim then 
      if ThePlayer then 
         ThePlayer.wanttosharpktn = true end
    else SendModRPCToServer( GLOBAL.MOD_RPC.ktn.ktnsharpen,true) end
    end)
     TheInput:AddKeyUpHandler(KTN_KEYZW, function()
      if GLOBAL.TheWorld.ismastersim then 
      if ThePlayer then 
         ThePlayer.wanttosharpktn = nil end
    else SendModRPCToServer( GLOBAL.MOD_RPC.ktn.ktnsharpen,false) end
    end)
end

if KTN_KEYQR then 
    TheInput:AddKeyDownHandler(KTN_KEYQR, function()
      if GLOBAL.TheWorld.ismastersim then 
      if ThePlayer then 
         ThePlayer.td_qrz = true end
    else SendModRPCToServer( GLOBAL.MOD_RPC.ktn.keyctrl,true) end
    end)

     TheInput:AddKeyUpHandler(KTN_KEYQR, function()
      if GLOBAL.TheWorld.ismastersim then 
      if ThePlayer then 
         ThePlayer.td_qrz = nil end
    else SendModRPCToServer( GLOBAL.MOD_RPC.ktn.keyctrl,false) end
    end)
end

    KTN_SPACE = KTN_SPACE or KEY_SPACE
    TheInput:AddKeyDownHandler(KTN_SPACE, function()
      if GLOBAL.TheWorld.ismastersim then 
      if ThePlayer then 
         ThePlayer.td_space = true 
         if ThePlayer.removekeyspace then ThePlayer.removekeyspace:Cancel() end
         ThePlayer.removekeyspace = ThePlayer:DoTaskInTime(.1,function()ThePlayer.td_space =nil end)
      end
    else SendModRPCToServer( GLOBAL.MOD_RPC.ktn.keydownspace) end
    end)


     KEYATK = "F" KEYATK = KEYATK:lower():byte()
     KTN_KEYATK = KTN_KEYATK or KEYATK
     TheInput:AddKeyDownHandler(KTN_KEYATK,function() 
      if TheWorld.ismastersim then
      if ThePlayer then 
         ThePlayer.td_atk = true end
          else
         SendModRPCToServer( MOD_RPC.ktn.keyatk, true) 
        end
     end)
     TheInput:AddKeyUpHandler(KTN_KEYATK, function()
      if TheWorld.ismastersim then
      if ThePlayer then 
         ThePlayer.td_atk = false end
          else
         SendModRPCToServer( MOD_RPC.ktn.keyatk, false) 
        end
     end)

    TheInput:AddMouseButtonHandler(function(key,down)
        if key == KTN_KEYQR then 
                  if GLOBAL.TheWorld.ismastersim then 
                     if ThePlayer then 
                        ThePlayer.td_qrz = down 
                     end
                  else SendModRPCToServer( GLOBAL.MOD_RPC.ktn.keyctrl,down) 
                  end
        end
    end)


--else
if type(KEYTYPE) == "number" then 
--For Controller
  if KTN_KEYLK then
     TheInput:AddControlHandler(KTN_KEYLK, function(down) 
        if TheWorld.ismastersim then
              if ThePlayer then 
        ThePlayer.lockktn = down end
        else SendModRPCToServer( GLOBAL.MOD_RPC.ktn.ktnlocked, down) end
     end)
  end
end
          TheInput:AddControlHandler(KTN_KEYQR, function(down) 
        if TheWorld.ismastersim then
              if ThePlayer then 
         ThePlayer.td_qrz = down end
    else SendModRPCToServer( GLOBAL.MOD_RPC.ktn.keyctrl, down) end
     end)
               TheInput:AddControlHandler(57, function(down) 
        if TheWorld.ismastersim then
              if ThePlayer and down then 
                 ThePlayer.td_space = true 
                 if ThePlayer.removekeyspace then ThePlayer.removekeyspace:Cancel() end
                     ThePlayer.removekeyspace = ThePlayer:DoTaskInTime(.1,function()ThePlayer.td_space =nil end)
              end
       else SendModRPCToServer( GLOBAL.MOD_RPC.ktn.keydownspace) end
     end)
                    TheInput:AddControlHandler(CONTROL_INVENTORY_USEONSCENE, function(down) 
        if TheWorld.ismastersim then
              if ThePlayer then 
           ThePlayer.wanttosharpktn = down end
        else SendModRPCToServer( GLOBAL.MOD_RPC.ktn.ktnsharpen, down) end
     end) 



     TheInput:AddControlHandler(CONTROL_SECONDARY, function(down) 
        if TheWorld.ismastersim then
              if ThePlayer and not (ThePlayer.replica.inventory and ThePlayer.replica.inventory:GetActiveItem()) then 
        ThePlayer.ktnmouser = down end
        else  SendModRPCToServer( MOD_RPC.ktn.keymouser, down) end
     end)  
     TheInput:AddControlHandler( CONTROL_PRIMARY, function(down) 
        if TheWorld.ismastersim then
                  if ThePlayer and not (ThePlayer.replica.inventory and ThePlayer.replica.inventory:GetActiveItem()) then 
        ThePlayer.ktnmousel = down end
        if down and ThePlayer then ThePlayer:DoTaskInTime(.15,function() ThePlayer.ktnmousel = false end) end
        else  SendModRPCToServer( MOD_RPC.ktn.keymousel, down) end
     end)
          TheInput:AddControlHandler( CONTROL_CONTROLLER_ALTACTION , function(down) 
        if TheWorld.ismastersim then
              if ThePlayer and not (ThePlayer.replica.inventory and ThePlayer.replica.inventory:GetActiveItem()) then 
        ThePlayer.ktnmouser = down end
        else  SendModRPCToServer( MOD_RPC.ktn.keymouser, down) end
     end)  
     TheInput:AddControlHandler( 59 , function(down) 
        if TheWorld.ismastersim then
                  if ThePlayer and not (ThePlayer.replica.inventory and ThePlayer.replica.inventory:GetActiveItem()) then 
        ThePlayer.ktnmousel = down end
        if down and ThePlayer then ThePlayer:DoTaskInTime(.15,function() ThePlayer.ktnmousel = false end) end
        else  SendModRPCToServer( MOD_RPC.ktn.keymousel, down) end
     end)

--[[
     TheInput:AddControlHandler(CONTROL_MOVE_RIGHT, function(down) 
        if TheWorld.ismastersim then
                  if ThePlayer then 
        ThePlayer.ismoveright = down end
        else  SendModRPCToServer( MOD_RPC.ktn.ismoveright, down) end
     end)  
     TheInput:AddControlHandler(CONTROL_MOVE_LEFT, function(down) 
        if TheWorld.ismastersim then
                  if ThePlayer then 
        ThePlayer.ismoveleft = down end
        else  SendModRPCToServer( MOD_RPC.ktn.ismoveleft, down) end
     end) 
     TheInput:AddControlHandler(CONTROL_MOVE_UP, function(down) 
        if TheWorld.ismastersim then
                  if ThePlayer then 
        ThePlayer.ismoveup = down end
        else  SendModRPCToServer( MOD_RPC.ktn.ismoveup, down) end
     end)  
     TheInput:AddControlHandler(CONTROL_MOVE_DOWN, function(down) 
        if TheWorld.ismastersim then
                  if ThePlayer then 
        ThePlayer.ismovedown = down end
        else  SendModRPCToServer( MOD_RPC.ktn.ismovedown, down) end
     end)    ]]

end)

AddClassPostConstruct("screens/playerhud", function(self)
    local player = self.owner
    local old_openinv = self.OpenControllerInventory

    function self:OpenControllerInventory(...)
       if ThePlayer:HasTag("controllerktnlock") then return 
          else old_openinv(self,...) 
       end
    end

        local old_opencraft = self.OpenCrafting

    function self:OpenCrafting(...)
       if ThePlayer:HasTag("taidaoxia") and (KEYTYPE and KEYTYPE == 1) then return 
          else old_opencraft(self,...)
       end
    end
            local old_inspect = self.InspectSelf

    function self:InspectSelf(...)
       if ThePlayer:HasTag("controllerktnlock") then return 
          else old_inspect(self,...)
       end
    end
end)

AddComponentPostInit('playercontroller', function(self)
    local old_update = self.OnUpdate
    local player = self.inst
    local old_contar = self.DoControllerActionButton
    local old_inspect = self.DoInspectButton
    local iswalk

    function self:DoControllerActionButton(...)
       if player:HasTag("controllerktnlock") then return 
          else old_contar(self,...)
       end
    end
        function self:DoInspectButton(...)
       if player:HasTag("controllerktnlock") then return 
          else old_inspect(self,...)
       end
    end

    function self:OnUpdate(...)
        old_update(self, ...)  

       -- if KEYTYPE then GLOBAL.KEYTYPE = TheInput:ControllerAttached() and 1 or true end

        if iswalk ~= IsWalkButtonDown() then  
            iswalk = IsWalkButtonDown()
      if TheWorld.ismastersim then
        player.ktn_iswalking = IsWalkButtonDown()
      else  SendModRPCToServer( MOD_RPC.ktn.ismove, IsWalkButtonDown())
      end
    end

      local hddt = player.td_heading 
            if hddt ~= GetWorldControllerVector() then  
      if GLOBAL.TheWorld.ismastersim then
        player.td_heading = GetWorldControllerVector() 
        player.ktn_rotchange = true player:DoTaskInTime(.2,function() player.ktn_rotchange = nil end)
      else  SendModRPCToServer( MOD_RPC.ktn.changeheading, GetWorldControllerVector())
      end
    end

    end
end)

AddComponentPostInit('thief', function(self)
    local old_StealItem = self.StealItem
    function self:StealItem(victim, itemtosteal, attack)
             if victim:HasTag("ktninvincible") then return end
             old_StealItem(self,victim, itemtosteal, attack)
    end
end)

local function addinv(player)
        if player:HasTag("player")then 
           local pt = Vector3(player.Transform:GetWorldPosition() )local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, 5)
           for k,v in pairs(ents) do
               if v:HasTag("ktninvincible") then
                  v:PushEvent("ktnblocked", { attacker = attacker })
               end
            end
        end
end

AddGlobalClassPostConstruct("stategraph", "StateGraphInstance", function(self)
    local old_sg = self.GoToState
    function self:GoToState(statename, params)
       if statename and (statename == "knockback"or statename == "devoured" ) and (self.inst.ktninvincible or self.inst:HasTag("ktninvincible")) then return end
       old_sg(self,statename, params)
    end
end)

--[[
AddGlobalClassPostConstruct("input","Input", function(self)
    local old_con = self.OnMouseButton
    function self:OnMouseButton(...)
        print(...) print("woc")
        old_con(self,...)
    end
end)]]


AddComponentPostInit('combat', function(self)
    local player = self.inst

 if player:HasTag("player") then
   TheWorld.rewriteatkeddelay = TheWorld:DoTaskInTime(2*FRAMES,function() --make sure its priority
    local old_getzgattacked = self.Zg_GetAttacked
    local old_getzgokattacked = self.Zg_OK_GetAttacked
    local old_getattacked = self.GetAttacked
    if old_getzgattacked and old_getzgokattacked then
        function self:Zg_GetAttacked(...)
           if player:HasTag("ktninvincible") then
            player:PushEvent("ktnblocked", { attacker = attacker }) return end
            addinv(player)
            old_getzgattacked(self, ...)
        end
        function self:Zg_OK_GetAttacked(...)
        if player:HasTag("ktninvincible") then
           player:PushEvent("ktnblocked", { attacker = attacker }) return end
           addinv(player)
           old_getzgokattacked(self, ...)
        end
    end

    function self:GetAttacked(attacker,...)
        if player:HasTag("ktninvincible") then
           player:PushEvent("ktnblocked", { attacker = attacker }) return end 
        addinv(player)
        if player.sg and (player.sg:HasStateTag("ktnsg")and not player.sg:HasStateTag("modao")) then 
            if Exist(attacker,true) and (attacker:HasTag("insect") or attacker:HasTag("smallcreature"))and not (attacker:HasTag("largecreature") or attacker:HasTag("epic") )then
                if not player.sg:HasStateTag("drowning") then
                   player.sg.statemem.btbyxg = true
                   player.sg:AddStateTag("drowning")
                end
            elseif player.sg.statemem and player.sg.statemem.btbyxg then
                player.sg.statemem.btbyxg = nil 
                player.sg:RemoveStateTag("drowning")
           end
        end
        old_getattacked(self,attacker,...)
    end  
   end)
 end
end)


