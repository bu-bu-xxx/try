local Image = require("widgets/image")
local Widget = require("widgets/widget")

local center_radius = 15
local deg_lower = {-135, -45}
local deg_right = {-45, 45}
local deg_upper = {45, 135}

local choice_ping = {
    ["lower"] = "help",
    ["right"] = "ontheway",
    ["upper"] = "danger",
    ["left"] = "question",
}

local line_length = 2  -- 单位图像像素长度
local offset = 4  -- 箭头偏移

local LoLPingLine = Class(Widget, function(self)
    Widget._ctor(self, "LoLPingLine")

    self.arrow = self:AddChild(Image("images/lolpingwheel.xml", "arrow.tex"))
    self.line = self:AddChild(Image("images/lolpingwheel.xml", "line.tex"))
end)

function LoLPingLine:DrawLine(radius, angle)
    self.arrow:SetPosition(radius + offset, 0)
    self.line:SetPosition(radius/line_length, 0)
    self.line:SetScale(radius/line_length, 1)
    self:SetRotation(angle)
end


local LoLPingWheel = Class(Widget, function(self)
    Widget._ctor(self, "LoLPingWheel")

    self.pingwheel = self:AddChild(Image("images/lolpingwheel.xml", "choice_center.tex"))
    self.pingline = self:AddChild(LoLPingLine())

    self.center_pos = self:GetPosition()
    self.choicing = false
    self.choice = "center"

    self:Hide()
end)

function LoLPingWheel:OnUpdate(dt)
    local input_pos = TheInput:GetScreenPosition()
    local r = self.center_pos:Dist(input_pos)

    local deg_angle = math.deg(math.atan2(input_pos.y - self.center_pos.y,  input_pos.x - self.center_pos.x))

    self.pingline:DrawLine(r, -deg_angle)  -- 顺时针

    self.choice = "center"
    if r <= center_radius then
    elseif deg_lower[1] <= deg_angle and deg_angle <= deg_lower[2] then
        self.choice = "lower"
    elseif deg_right[1] <= deg_angle and deg_angle <= deg_right[2] then
        self.choice = "right"
    elseif deg_upper[1] <= deg_angle and deg_angle <= deg_upper[2] then
        self.choice = "upper"
    else
        self.choice = "left"
    end

    self.pingwheel:SetTexture("images/lolpingwheel.xml", "choice_" .. self.choice .. ".tex")
end

function LoLPingWheel:StartChoose(world_pos)
    self.choicing = true

    self.center_pos = TheInput:GetScreenPosition()
    self.center_world_pos = world_pos or TheInput:GetWorldPosition()

    self:SetPosition(self.center_pos)
    self:StartUpdating()
    self:Show()
end

function LoLPingWheel:StopChoose()
    self.choicing = false
    self:StopUpdating()
    self:Hide()

    if choice_ping[self.choice] and self.center_world_pos then
        local x, y, z = self.center_world_pos:Get()
        local pingerid = ThePlayer and ThePlayer.userid or nil
        SendModRPCToServer(MOD_RPC["LoL Ping"]["Ping"], x, y, z, choice_ping[self.choice], pingerid)
    end
end

return LoLPingWheel