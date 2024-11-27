
local Widget = require("widgets/widget")
local Image = require("widgets/image")
local ImageButton = require("widgets/imagebutton")
local Easing = require("easing")
local Text = require("widgets/text")

local positions = {
    {0,60},  --above
    {0,0}, --on top
    {0,-60},  --below
    {-65,0},  --left
    {0,-65},  --right
}

local pos_key = positions[TUNING.WORMHOLE_ICONS_SERVER.ICON_PLACEMENT] or {0,0}

local function WorldPosToScreenPos(x, z)
    if x == nil or z == nil then return end
    local half_x, half_y = RESOLUTION_X / 2, RESOLUTION_Y / 2
    local screen_width, screen_height = TheSim:GetScreenSize()
    local map_x, map_y = TheWorld.minimap.MiniMap:WorldPosToMapPos(x, z, 0)
    local screen_x = ((map_x * half_x) + half_x) / RESOLUTION_X * screen_width
    local screen_y = ((map_y * half_y) + half_y) / RESOLUTION_Y * screen_height
    return screen_x, screen_y
end

local PersistentMapIcons = Class(Widget, function(self, mapwidget, scale, owner)
    Widget._ctor(self, "PersistentMapIcons")
    --print("PersistentMapIcons",self, mapwidget, scale, owner)
    self.root = self:AddChild(Widget("root"))
    self.mapicons = {}
    self.uvscale = 1
    self.owner = owner
    scale = scale * TUNING.WORMHOLE_ICONS_SERVER.MAPSCALE

    local MapWidgetOnUpdate = mapwidget.OnUpdate
    mapwidget.OnUpdate = function(mapwidget, ...)
        MapWidgetOnUpdate(mapwidget, ...)
        local scale = scale - Easing.outExpo(TheWorld.minimap.MiniMap:GetZoom() - 1,0, math.max(0,scale - 0.25), 8)
        for _, mapicon in ipairs(self.mapicons) do
            local x, y = WorldPosToScreenPos(mapicon.pos.x, mapicon.pos.z)
            if x ~= nil and y ~= nil then
                mapicon.icon:SetPosition(x, y)
            end
            if scale ~= nil then
                mapicon.icon:SetScale(scale)
            end
        end
    end

end)

local atlases = {
    ["images/tentapillar_icons.xml"] = "tentapillar", 
    ["images/wormhole_icons.xml"] = "wormhole", 
    ["images/sinkhole_down.xml"] = "cave_entrance_open",
    ["images/sinkhole_up.xml"] = "cave_exit",
}

local title = {
    tentapillar = "Tentapillar",
    wormhole = "Wormhole",
    cave_entrance_open = "Sinkhole",
    cave_exit = "Sinkhole",
}


function PersistentMapIcons:AddMapIcon(atlas, image, pos, tint, key)
    --print("PersistentMapIcons:AddMapIcon",atlas, image, pos, tint, key)
    local icon
    if TUNING.WORMHOLE_ICONS_SERVER.RENAME_FROM_MAP then
        icon = self.root:AddChild(ImageButton(atlas, image))
        local function getWritableWidget(typ, pos)
            return {
                prompt = "Rename the "..title[typ],
                animbank = "ui_board_5x3",
                animbuild = "ui_board_5x3",
                menuoffset = Vector3(6, -70, 0),
                cancelbtn = { text = "Cancel", cb = nil, control = CONTROL_CANCEL },
                acceptbtn = {   
                    text = "Accept",
                    cb = function(inst, doer, widget)
                        local text = widget:GetText()
                        SendModRPCToServer(MOD_RPC["Wormhole_Icons_Server"]["ChangeNameAll"], typ, pos.x, pos.y, pos.z, text)
                        if text then
                            if TUNING.WORMHOLE_ICONS_SERVER.ICON_PLACEMENT == 0 then
                                icon:SetHoverText(key, {colour = tint, font_size = 25})
                            else
                                if icon.num then
                                    icon.num:SetString(text)
                                else
                                    icon.num = icon:AddChild(Text(NEWFONT_OUTLINE,60,text,tint or nil))
                                    icon.num:SetPosition(unpack(pos_key))
                                end
                            end
                        end
                    end,
                    control = CONTROL_ACCEPT 
                },
            }
        end
        icon:SetOnClick(function()
            local typ = atlases[atlas]
            if typ ~= nil then
                if ThePlayer and ThePlayer.HUD then
                    local isSinkhole = typ == "cave_entrance_open" or typ == "cave_exit" 
                    if isSinkhole and
                        --Check if Sinkholes can be renamed
                         (TUNING.WORMHOLE_ICONS_SERVER.RENAMING_SINKHOLE == 1 or 
                                (TUNING.WORMHOLE_ICONS_SERVER.RENAMING_SINKHOLE == 2 and 
                                    TheNet:GetIsServerAdmin() == true))  then
                        ThePlayer.HUD:ShowWriteableWidget(ThePlayer,getWritableWidget(typ, pos))
                    --Check if Wormholes can be renamed
                    elseif (TUNING.WORMHOLE_ICONS_SERVER.RENAMING == 1 or 
                                (TUNING.WORMHOLE_ICONS_SERVER.RENAMING == 2 and 
                                    TheNet:GetIsServerAdmin() == true)) then
                        --Send the writable widget to the player
                        ThePlayer.HUD:ShowWriteableWidget(ThePlayer,getWritableWidget(typ, pos))
                    end
                end
            end
        end)
        if tint then
            icon.image:SetTint(unpack(tint))
        end
    else
        icon = self.root:AddChild(Image(atlas, image))
        if tint then
            icon:SetTint(unpack(tint))
        end
    end

    if key then
        if TUNING.WORMHOLE_ICONS_SERVER.ICON_PLACEMENT == 0 then
            icon:SetHoverText(key, {colour = tint, font_size = 25})
        else
            icon.num = icon:AddChild(Text(NEWFONT_OUTLINE,60,key,tint or nil))
            icon.num:SetPosition(unpack(pos_key))
        end
    end
    
    table.insert(self.mapicons, {icon = icon, pos = pos})
end


return PersistentMapIcons
