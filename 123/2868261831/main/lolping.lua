local PingKey = GetModConfigData("PingKey")
local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)
local LoLPingWheel = require("widgets/lolpingwheel")
local LoLPing = require("widgets/lolping")
local ping_widgets = {}

local function DownPingKey()
    if not PingKey then
        return TheInput:IsKeyDown(KEY_LALT) or TheInput:IsKeyDown(KEY_LCTRL)
    end

    local key = rawget(_G, PingKey)
    if key then
        return TheInput:IsKeyDown(key)
    end
end

AddClassPostConstruct("screens/playerhud", function(self)
    self.lolpingwheel = self:AddChild(LoLPingWheel())
    self.lolping = self:AddChild(LoLPing(ping_widgets))
end)

local PlayerController = require("components/playercontroller")  -- 游戏界面右键
local _OnRightClick = PlayerController.OnRightClick
PlayerController.OnRightClick = function(self, down, ...)
    if ThePlayer and ThePlayer.HUD.lolpingwheel then
        if down then
            if not ThePlayer.HUD.lolpingwheel.choicing and not TheInput:GetWorldEntityUnderMouse() and DownPingKey() then
                ThePlayer.HUD.lolpingwheel:StartChoose()
                return
            end
        elseif ThePlayer.HUD.lolpingwheel.choicing then
            ThePlayer.HUD.lolpingwheel:StopChoose()
            return
        end
    end

    return _OnRightClick(self, down, ...)
end

AddClassPostConstruct("screens/mapscreen", function(self)  -- 小地图右键
    self.lolpingwheel = self:AddChild(LoLPingWheel())
    ping_widgets[self.name] = self
    self.inst:ListenForEvent("onremove", function()
        ping_widgets[self.name] = nil
    end)

    local _OnMouseButton = self.OnMouseButton
    self.OnMouseButton = function(self, button, down, ...)
        if button == MOUSEBUTTON_RIGHT then
            if down and DownPingKey() and not self.lolpingwheel.choicing then
                local world_pos = Vector3(self:GetWorldPositionAtCursor())
                self.lolpingwheel:StartChoose(world_pos)
                return
            elseif not down and self.lolpingwheel.choicing then
                self.lolpingwheel:StopChoose()
                return
            end
        end

        if _OnMouseButton then
            return _OnMouseButton(self, button, down, ...)
        end
    end
end)

local MapScreen = require("screens/mapscreen")
local _UpdateMapActions = MapScreen.UpdateMapActions
MapScreen.UpdateMapActions = function(...)   -- 按住alt或者ctrl时小恶魔不能跳地图
    if DownPingKey() then
        return nil, nil
    end

    return _UpdateMapActions(...)
end