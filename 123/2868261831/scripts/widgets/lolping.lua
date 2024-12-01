local UIAnim = require("widgets/uianim")
local Widget = require("widgets/widget")

local camera_default_distance = 30

local ping_scale = {
    ["MapScreen"] = {
        default = 0.4,
        help = 0.5,
    },
    ["HUD"] = {
        default = 0.8,
        help = 1,
    }
}

local updatafns = {
    ["MapScreen"] = function(self)
        if not self.parent or not self.parent.minimap or not self.world_pos then
            return
        end

        local scale_multiple = self.parent.minimap:GetZoom()
        local scale = (ping_scale["MapScreen"][self.type] or ping_scale["MapScreen"].default) / scale_multiple
        self:SetScale(scale, scale, scale)

        local x, y, z = self.world_pos:Get()
        local map_x, map_y = self.parent.minimap:WorldPosToMapPos(x, z, 0)
        local screen_width, screen_height = TheSim:GetScreenSize()
        local screen_x = (map_x + 1) * screen_width / 2
        local screen_y = (map_y + 1) * screen_height / 2
        self:SetPosition(screen_x, screen_y)
    end
}

local Ping = Class(UIAnim, function(self, updatafn)
    UIAnim._ctor(self)

    self.OnUpdate = updatafn
    self:Hide()

    self.inst:ListenForEvent("animover", function()
        self:StopUpdating()
        self:Hide()
    end)
end)

function Ping:SetAnim(type, time)
    self.type = type
    self.inst.AnimState:SetBank(type)
    self.inst.AnimState:SetBuild(type)
    self.inst.AnimState:PlayAnimation("idle")

    if time then
        self.inst.AnimState:SetTime(time)
    end

    self:Show()
end

function Ping:PingWithWorldPos(x, y, z, type, time)
    self.world_pos = Vector3(x, y, z)

    self:SetAnim(type, time)
    self:StartUpdating()
end


local WorldPing = Class(Ping, function(self, ping_widgets)
    Ping._ctor(self)
    self.ping_widgets = ping_widgets
end)

function WorldPing:OnUpdate(dt)
    if not self.world_pos then
        return
    end

    local camera_multiple = 1
    if TheCamera then
        camera_multiple = camera_default_distance / TheCamera.distance
    end

    local scale = (ping_scale["HUD"][self.type] or ping_scale["HUD"].default) * camera_multiple
    self:SetScale(scale, scale, scale)

    local x, y, z = self.world_pos:Get()
    local screen_x, screen_y = TheSim:GetScreenPos(x, y, z)
    self:SetPosition(screen_x, screen_y)

    for name, widget in pairs(self.ping_widgets) do
        if not widget[self] then
            widget[self] = widget:AddChild(Ping(updatafns[name]))
        end

        if not widget[self].shown then
            local time = self.inst.AnimState:GetCurrentAnimationTime()
            widget[self]:PingWithWorldPos(x, y, z, self.type, time)
        end
    end
end


local LoLPing = Class(Widget, function(self, ping_widgets)
    Widget._ctor(self, "LoLPing")

    self.pings = {}
    self.ping_widgets = ping_widgets or {}
end)

function LoLPing:GetPing()
    for _, ping in ipairs(self.pings) do
        if not ping.shown then
            return ping
        end
    end

    local ping = self:AddChild(WorldPing(self.ping_widgets))
    table.insert(self.pings, ping)
    return ping
end

function LoLPing:PingAtWorld(x, y, z, type)
    local ping = self:GetPing()
    PlayPingMusic(x, y, z, type)
    ping:PingWithWorldPos(x, y, z, type)
end

return LoLPing