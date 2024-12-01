
local Widget = require("widgets/widget")
local Image = require("widgets/image")
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

local function IsShown(mapsize,x,y)
    --print("IsShown",mapsize.w,mapsize.h,x,x,y)
    --print(x < mapsize.w/2, x > -mapsize.w/2, y < mapsize.h/2, y > -mapsize.h/2)
    if x < mapsize.w/2 and x > -mapsize.w/2 and y < mapsize.h/2 and y > -mapsize.h/2 then 
        return true
    end
end


local scale_uv = {
    [1] = 1,
    [1.5] = 2,
    [1.75] = 4,
    [1.875] = 8,
}

local scale_icon_uv = {
    [1] = 1,
    [1.5] = 1.5,
    [1.75] = 2,
    [1.875] = 4,
}

local PersistentMapIcons = Class(Widget, function(self, mapwidget, scale, owner) --need to get scale from config options of minimap mod
    Widget._ctor(self, "PersistentMapIcons")
    dprint("PersistentMapIconsMinimap",self, self.inst.GUID, mapwidget, scale, owner)
    self.root = self:AddChild(Widget("root"))
    self.mapicons = {}
    self.uvscale = 1
    self.owner = owner

    local first_update = true

    local MapWidgetOnUpdate = mapwidget.OnUpdate
    mapwidget.OnUpdate = function(mapwidget, ...)
        MapWidgetOnUpdate(mapwidget, ...)
        local orig_scale = scale - Easing.outExpo(TheWorld.minimap.MiniMap:GetZoom() - 1,0,scale - 0.25,8)
        local _scale = (scale_icon_uv[mapwidget.uvscale] or 1) * orig_scale * TUNING.WORMHOLE_ICONS_SERVER.MINIMAPSCALE * 0.5
        --print("scale",scale,mapwidget.uvscale)
        for _, mapicon in ipairs(self.mapicons) do
            if first_update then
                first_update = false
                mapicon.icon:Show()
            end
            local map_x, map_y = TheWorld.minimap.MiniMap:WorldPosToMapPos(mapicon.pos.x, mapicon.pos.z, 0)
            local size_scale = scale_uv[mapwidget.uvscale] or 1
            --print("size_scale",size_scale,mapwidget.uvscale)
            local x = map_x * mapwidget.mapsize.w/2 * size_scale
            local y = map_y * mapwidget.mapsize.h/2 * size_scale
            --print(x,y)
            if x ~= nil and y ~= nil and IsShown(mapwidget.mapsize,x,y) then
                mapicon.icon:SetPosition(x, y)
                mapicon.icon:Show()
            else
                mapicon.icon:Hide()
            end
            if _scale ~= nil then
                mapicon.icon:SetScale(_scale)
            end
        end
    end

    --Override the onshow/onhide functions to hide or show the icons
    local img = mapwidget.img 
    if img then
        local old_OnShow = img.OnShow or function() end
        local old_OnHide = img.OnHide or function() end
        img.OnShow = function(img, was_hidden, ...)
            old_OnShow(img, was_hidden, ...)
            if was_hidden then
                self.root:Show()
            end
        end
        img.OnHide = function(img, was_visible, ...)
            old_OnHide(img, was_visible, ...)
            if was_visible then
                self.root:Hide()
            end
        end
    end

    if self.owner then
        local function OnRefresh()
            for k,v in ipairs(self.mapicons) do
                v.icon:Kill()
            end
            self.mapicons = {}
            if self.RegisterHoles then
                self:RegisterHoles()
            end
        end
        self.owner:DoTaskInTime(2,function()
            self.owner:ListenForEvent("minimap_refresh",OnRefresh)
        end)
    end

end)


function PersistentMapIcons:AddMapIcon(atlas, image, pos, tint, key, no_image)
    --print("PersistentMapIcons:AddMapIcon",atlas, image, pos, tint, key)
    local icon
    if no_image then
        icon = self.root:AddChild(Widget("icon"))
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
            local num = icon:AddChild(Text(NEWFONT_OUTLINE,60,key,tint or nil))
            num:SetPosition(unpack(pos_key))
        end
    end
    icon:Hide()
    table.insert(self.mapicons, {icon = icon, pos = pos})
end


return PersistentMapIcons
