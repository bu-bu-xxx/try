local _G = GLOBAL
local unpack = _G.unpack
local FindEntity = _G.FindEntity
local Vector3 = _G.Vector3
require("constants")

local SHOW_NUMBERS_SINKHOLE = GetModConfigData("SHOW_NUMBERS_SINKHOLE")
local SHOW_NUMBERS = GetModConfigData("SHOW_NUMBERS")
local WORLD_COLORS = GetModConfigData("WORLD_COLORS")
local WORLD_NUMBERS = GetModConfigData("WORLD_NUMBERS")
local WORMHOLE_BORDER = GetModConfigData("WORMHOLE_BORDER")
local MINIMAP_ICONS = GetModConfigData("MINIMAP_ICONS")
local language = GetModConfigData("LANGUAGE")

local WORLD_COLORS_SINKHOLE = GetModConfigData("WORLD_COLORS_SINKHOLE")
local WORLD_NUMBERS_SINKHOLE = GetModConfigData("WORLD_NUMBERS_SINKHOLE")
local SINKHOLE_BORDER = GetModConfigData("SINKHOLE_BORDER")
local MINIMAP_ICONS_SINKHOLE = GetModConfigData("MINIMAP_ICONS_SINKHOLE")

local wormhole_path = "images/wormhole_icons"
local tentapillar_path = "images/tentapillar_icons"
local sinkhole_down_path = "images/sinkhole_down"
local sinkhole_up_path = "images/sinkhole_up"
local dprint = GLOBAL.dprint

local PersistentMapIcons = require("widgets/persistentmapicons_server")
local PersistentMapIconsMinimap = require("widgets/persistentmapicons_minimap")

local tropical_enabled = GLOBAL.KnownModIndex:IsModEnabledAny("workshop-1505270912")

local CalcPos = function(ent)
    return ent:GetPosition()
end
local CalcNum = function(num)
    return num
end

-- Mod compability

local isFastGatheringEnabled = GLOBAL.KnownModIndex:IsModEnabledAny("workshop-2158549297")
local state = isFastGatheringEnabled and "old_doshortaction" or "doshortaction"
if isFastGatheringEnabled then
    local TIMEOUT = 2
    AddStategraphState("wilson_client", GLOBAL.State{
        name = "old_doshortaction",
        tags = { "doing", "busy" },
        server_states = { "old_doshortaction" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            if inst:HasTag("beaver") then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk_lag", false)
            else
                inst.AnimState:PlayAnimation("pickup")
                inst.AnimState:PushAnimation("pickup_lag", false)
            end
            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst.sg:ServerStateMatches() then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("pickup_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("pickup_pst")
            inst.sg:GoToState("idle", true)
        end,
    })
    AddStategraphState("wilson", GLOBAL.State{
        name = "old_doshortaction",
        tags = { "doing", "busy" },

        onenter = function(inst, silent)
            inst.components.locomotor:Stop()
            if inst:HasTag("beaver") then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
            else
                inst.AnimState:PlayAnimation("pickup")
                inst.AnimState:PushAnimation("pickup_pst", false)
            end

            inst.sg.statemem.action = inst.bufferedaction
            inst.sg.statemem.silent = silent
            inst.sg:SetTimeout(10 * GLOBAL.FRAMES)
        end,

        timeline =
        {
            GLOBAL.TimeEvent(6 * GLOBAL.FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
                if inst.sg.statemem.silent then
                    inst.components.talker:IgnoreAll("silentpickup")
                    inst:PerformBufferedAction()
                    inst.components.talker:StopIgnoringAll("silentpickup")
                else
                    inst:PerformBufferedAction()
                end
            end),
        },

        ontimeout = function(inst)
            --pickup_pst should still be playing
            inst.sg:GoToState("idle", true)
        end,

        onexit = function(inst)
            if inst.bufferedaction == inst.sg.statemem.action and
                    (inst.components.playercontroller == nil or inst.components.playercontroller.lastheldaction ~= inst.bufferedaction) then
                inst:ClearBufferedAction()
            end
        end,
    })
end

------------------------------------------------------------------------------------


local strings = {
    RENAME_WORMHOLE = {
        en = "Rename Wormhole",
        zh = "重命名虫洞",
        de = "Wurmloch umbenennen",
        es = "Renombrar agujero de gusano",
        fr = "Renommer le trou de ver",
        ru = "Переименовать червоточину",
        ko = "웜홀 이름 바꾸기",
    },
    RENAME_SINKHOLE = {
        en = "Rename Sinkhole",
        zh = "重命名虫洞",
        de = "Erdloch umbenennen",
        es = "Cambiar el nombre del sumidero",
        fr = "Renommer le gouffre",
        ru = "Переименовать воронку",
        ko = "싱크홀 이름 바꾸기",
    },
    ACCEPT = {
        en = "Accept",
        zh = "取消",
        de = "Akzeptieren",
        es = "Acepte",
        fr = "Accepter",
        ru = "Принять",
        ko = "동의",
    },
    CANCEL = {
        en = "Cancel",
        zh = "接受",
        de = "Abbrechen",
        es = "Cancelar",
        fr = "Annuler",
        ru = "Отмена",
        ko = "취소",
    },
}


AddPlayerPostInit(function(inst)
    inst._wormhole_icons = {}
    inst._wormhole_names = {}
end)

local function CheckIfEqual(pos1,pos2)
    if  math.floor(pos1.x*10)/10 == math.floor(pos2.x*10)/10 and 
        math.floor(pos1.y*10)/10 == math.floor(pos2.y*10)/10 and 
        math.floor(pos1.z*10)/10 == math.floor(pos2.z*10)/10 then 
        return true
    end
    return false
end


local function WormholePositionExists(new_pos)
    for i, pos in pairs(GLOBAL.TheWorld.components.wormhole_icons_server.wormhole_icons) do
        if CheckIfEqual(pos,new_pos) then
            return i
        end
    end
    return false
end

local function WormholePositionExistsClient(new_pos)
    if GLOBAL.ThePlayer == nil then return end
    for i, pos in pairs(GLOBAL.ThePlayer._wormhole_icons) do
        if CheckIfEqual(pos,new_pos) then
            return i
        end
    end
    return false
end

local function AddWormholePosition(pos,doer)
    if pos == nil then return end
    local count = 0
    for k,v in ipairs(GLOBAL.TheWorld.components.wormhole_icons_server.wormhole_icons) do
        count = count + 1
    end
    local forall = GLOBAL.TUNING.WORMHOLE_ICONS_SERVER.FOR_ALL
    local userid = forall == 0 and nil or doer and doer.userid or nil
    GLOBAL.TheWorld.components.wormhole_icons_server.wormhole_icons[count+1] = pos
    SendModRPCToClient(GetClientModRPC("Wormhole_Icons_Server", "AddWormholePositionsToClient"),userid,count+1,pos.x,pos.y,pos.z)
    print("[Wormhole Icons Server] Added icon at "..tostring(pos))
end

local function AddWormholePositionsToClient(k,_x,_y,_z,remove,name)
    dprint("AddWormholePositionsToClient",k,_x,_y,_z,remove,name)
    if GLOBAL.ThePlayer and k ~= nil then
        if remove == true then
            GLOBAL.ThePlayer._wormhole_icons[k] = nil
            GLOBAL.ThePlayer:PushEvent("minimap_refresh")
        else
            local pos = Vector3(_x,_y,_z)
            if WormholePositionExistsClient(pos) == false then
                GLOBAL.ThePlayer._wormhole_icons[k] = pos
                print("[Wormhole Icons Client] Added icon at "..tostring(pos))
                GLOBAL.ThePlayer:PushEvent("minimap_refresh")
            end
            if name then
                --print("name",name)
                GLOBAL.ThePlayer._wormhole_names[k] = name
            end
        end
    else
        dprint("player or k is nil")
        dprint(GLOBAL.ThePlayer,k)
    end
end

AddClientModRPCHandler("Wormhole_Icons_Server", "AddWormholePositionsToClient", AddWormholePositionsToClient)

local texture, xml_path, texture_sinkhole, xml_path_sinkhole
AddSimPostInit(function()
    local TheWorld = _G.TheWorld
    local cave = TheWorld:HasTag("cave")
    texture = cave and "tentapillar" or "wormhole"
    xml_path = cave and tentapillar_path or wormhole_path
    texture_sinkhole = cave and "sinkhole_up" or "sinkhole_down"
    xml_path_sinkhole = cave and sinkhole_up_path or sinkhole_down_path
end)

local function RGB(r, g, b)
    return {r / 255, g / 255, b / 255, 1}
end

local function selectColor(number) 
  local hue = math.fmod(number * 137.508,360)
  return hue,1,0.75
end

local function HSL(hue, saturation, lightness)
    if hue < 0 or hue > 360 then
        return 0, 0, 0, 1
    end
    if saturation < 0 or saturation > 1 then
        return 0, 0, 0, 1
    end
    if lightness < 0 or lightness > 1 then
        return 0, 0, 0, 1
    end
    local chroma = (1 - math.abs(2 * lightness - 1)) * saturation
    local h = hue/60
    local x =(1 - math.abs(h % 2 - 1)) * chroma
    local r, g, b = 0, 0, 0, 1
    if h < 1 then
        r,g,b=chroma,x,0
    elseif h < 2 then
        r,b,g=x,chroma,0
    elseif h < 3 then
        r,g,b=0,chroma,x
    elseif h < 4 then
        r,g,b=0,x,chroma
    elseif h < 5 then
        r,g,b=x,0,chroma
    else
        r,g,b=chroma,0,x
    end
    local m = lightness - chroma/2
    return {r+m,g+m,b+m,1}
end

local possible_colors = {
    RGB(230, 25, 75),       -- red
    RGB(60, 180, 75),       -- green
    RGB(255, 255, 25),      -- yellow
    RGB(0, 130, 200),       -- blue
    RGB(245, 130, 48),      -- orange
    RGB(145, 30, 180),      -- purpole
    RGB(70, 240, 240),      -- cyan
    RGB(240, 50, 230),      -- magenta
    RGB(210, 245, 60),      -- lime
    RGB(250, 190, 212),     -- pink
    RGB(0, 128, 128),       -- teal
    RGB(220, 190, 255),     -- lavender
    RGB(170, 110, 40),      -- brown
    RGB(255, 250, 200),     -- beige
    RGB(128, 0, 0),         -- maroon
    RGB(170, 255, 195),     -- mint
    RGB(128, 128, 0),       -- olive
    RGB(255, 215, 180),     -- apricot
    RGB(0, 0, 128),         -- navy
    RGB(128, 128, 128),     -- grey
    -- RGB(255, 255, 255),     -- white
    -- RGB(0, 0, 0),           -- black
}

local colors = {}

for i = 1,20 do
    colors[i] = possible_colors[GetModConfigData("WORMHOLE_COLOR_"..i) or i]
end

colors[0] = {1,1,1,1}

for count = 1,280 do
    local color = HSL(selectColor(count))
    table.insert(colors,color)
end

local colors_sinkhole = {}

for i = 1,20 do
    colors_sinkhole[i] = possible_colors[GetModConfigData("SINKHOLE_COLOR_"..i) or i]
end

colors_sinkhole[0] = {1,1,1,1}

for count = 1,30 do
    local color = HSL(selectColor(count))
    table.insert(colors_sinkhole,color)
end

if not _G.TheNet:IsDedicated() or not _G.TheNet:GetServerGameMode() == "lavaarena" then 
    AddClassPostConstruct("widgets/mapwidget", function(self)
        self.wormholeicons = self:AddChild(PersistentMapIcons(self, 0.6,self.owner))
        if GLOBAL.ThePlayer == nil then return end
        if MINIMAP_ICONS then
            for i, pos in pairs(GLOBAL.ThePlayer._wormhole_icons) do
                local key = math.ceil(i / 2)
                local new_texture = texture.."_white"
                local color = colors[key]
                if SHOW_NUMBERS ~= 0 then
                    --print("adding icons with numbers",key,pos)
                    local label 
                    if SHOW_NUMBERS > 1 then
                        local k = WormholePositionExistsClient(pos)
                        label = (self.owner and self.owner._wormhole_names and self.owner._wormhole_names[k]) or (SHOW_NUMBERS == 2 and key) or ""
                    else
                        label = key
                    end   
                    self.wormholeicons:AddMapIcon(xml_path..".xml", new_texture..".tex", pos, color, label)
                else
                    self.wormholeicons:AddMapIcon(xml_path..".xml", new_texture..".tex", pos, color)
                end
            end
        end
        if GetModConfigData("SINKHOLES") and MINIMAP_ICONS_SINKHOLE then
            for i, pos in pairs(GLOBAL.ThePlayer._sinkhole_icons) do
                local key = i
                local new_texture = texture_sinkhole.."_white"
                local color = colors_sinkhole[key]
                if SHOW_NUMBERS_SINKHOLE ~= 0 then
                    local label 
                    if SHOW_NUMBERS_SINKHOLE > 1 then
                        local k = SinkholePositionExistsClient(pos)
                        label = (self.owner and self.owner._sinkhole_names and self.owner._sinkhole_names[k]) or (SHOW_NUMBERS_SINKHOLE == 2 and key) or ""
                    else
                        label = key
                    end
                    self.wormholeicons:AddMapIcon(xml_path_sinkhole..".xml", new_texture..".tex", pos, color, label)
                else
                    self.wormholeicons:AddMapIcon(xml_path_sinkhole..".xml", new_texture..".tex", pos, color)
                end
            end
        end
    end)
end

if (not _G.TheNet:IsDedicated() or not _G.TheNet:GetServerGameMode() == "lavaarena") and GetModConfigData("MINIMAP_COMP") and GLOBAL.KnownModIndex:IsModEnabled("workshop-345692228") then 
    local scale = 0.225
    local name = GLOBAL.KnownModIndex:GetModActualName("Minimap HUD")
    if name then
        scale = GLOBAL.GetModConfigData("Minimap Size",name)
    end
    local function PostContructMinimap(self)
        self.wormholeicons = self:AddChild(PersistentMapIconsMinimap(self, scale,self.owner))
        self.inst:DoTaskInTime(2,function()
            function self.wormholeicons:RegisterHoles()
                if GLOBAL.ThePlayer == nil then return end
                if MINIMAP_ICONS then
                    for i, pos in pairs(GLOBAL.ThePlayer._wormhole_icons) do
                        local key = math.ceil(i / 2)
                        local new_texture = texture.."_white"
                        local color = colors[key]
                        if SHOW_NUMBERS ~= 0 then
                            local label 
                            if SHOW_NUMBERS > 1 then
                                local k = WormholePositionExistsClient(pos)
                                label = (self.owner and self.owner._wormhole_names and self.owner._wormhole_names[k]) or (SHOW_NUMBERS == 2 and key) or ""
                            else
                                label = key
                            end
                            dprint("adding icons with numbers",key,pos, label)
                            self:AddMapIcon(xml_path..".xml", new_texture..".tex", pos, color, label)
                        else
                            self:AddMapIcon(xml_path..".xml", new_texture..".tex", pos, color)
                        end
                    end
                end
                if GetModConfigData("SINKHOLES") and MINIMAP_ICONS_SINKHOLE then
                    for i, pos in pairs(GLOBAL.ThePlayer._sinkhole_icons) do
                        local key = i
                        local new_texture = texture_sinkhole.."_white"
                        local color = colors_sinkhole[key]
                        if SHOW_NUMBERS_SINKHOLE ~= 0 then
                            local label 
                            if SHOW_NUMBERS_SINKHOLE > 1 then
                                local k = SinkholePositionExistsClient(pos)
                                label = (self.owner and self.owner._sinkhole_names and self.owner._sinkhole_names[k]) or (SHOW_NUMBERS_SINKHOLE == 2 and key) or ""
                            else
                                label = key
                            end
                            self:AddMapIcon(xml_path_sinkhole..".xml", new_texture..".tex", pos, color, label)
                        else
                            self:AddMapIcon(xml_path_sinkhole..".xml", new_texture..".tex", pos, color)
                        end
                    end
                end
            end
            self.wormholeicons:RegisterHoles()
        end)
    end
    if GLOBAL.KnownModIndex:IsModEnabledAny("workshop-2849308125") then
        AddSimPostInit(function() AddClassPostConstruct("widgets/minimapwidget", PostContructMinimap) end)
    else
        AddClassPostConstruct("widgets/minimapwidget", PostContructMinimap)
    end
end


local function OnNameChange(inst,key,label)
    dprint("OnNameChange",inst,key,label)
    if key == nil or key == false then 
        dprint("key was wrong",inst, key, label) 
        dprint(GLOBAL.debugstack())
        return 
    end
    --GLOBAL.dumptable(GLOBAL.AllPlayers)
    for k,v in ipairs(GLOBAL.AllPlayers) do
        if v._wormhole_names then
            v._wormhole_names[key] = label
           v:PushEvent("minimap_refresh")
        end
    end
end

local function ChangeLabelServer(inst)
    inst:DoTaskInTime(1.2,function()
        if WORLD_NUMBERS ~= 0 then
            local key = inst.net_wormholenumber and inst.net_wormholenumber:value() or 1
            inst.label = inst.entity:AddLabel()
            inst.label:SetFont(_G.CHATFONT_OUTLINE)
            inst.label:SetFontSize(35)
            inst.label:SetWorldOffset(0, 2, 0)
            local label
            --GLOBAL.dumptable(GLOBAL.ThePlayer._wormhole_icons)
            local name = inst.net_wormholename and inst.net_wormholename:value() 
            if WORLD_NUMBERS > 1 and name ~= nil and name ~= "" then
                local k = WormholePositionExists(inst:GetPosition())
                label = name or (WORLD_NUMBERS == 2 and key) or ""
                OnNameChange(inst,k,label)
            else
                label = WORLD_NUMBERS ~= 3 and key or ""
            end
            inst.label:SetText(" "..(label or "Undefined").." ")
            local colour = key ~= nil and colors[key] ~= nil and colors[key] or {1,1,1,1}
            inst.label:SetColour(unpack(colour))
            inst.label:Enable(true)
        end
    end)
end

local function AddWormholeColor(inst, pos)
    dprint("AddWormholeColor",inst,pos)
    dprint(inst.color_done)
    if not inst or not inst:IsValid() or not pos or inst.color_done then dprint(inst,inst:IsValid(),pos,inst.color_done) return end
    local i = WormholePositionExists(pos)
    if not i then --print("doenst exist",i,WormholePositionExists(pos)) 
        return 
    end
    local key = math.ceil(i / 2)
    --print("is adding color")
    if inst.net_wormholenumber then
        inst.wormholenumber = key
        inst.net_wormholenumber:set(key)
    end
    if WORLD_COLORS then
        local add_color = 0.15
        inst.AnimState:SetAddColour(add_color, add_color, add_color, 0)
        inst.AnimState:OverrideMultColour(unpack(colors[key]))
    end
    inst:DoTaskInTime(1.2,function()
        if WORLD_NUMBERS ~= 0 then
            inst.label = inst.entity:AddLabel()
            inst.label:SetFont(_G.CHATFONT_OUTLINE)
            inst.label:SetFontSize(35)
            inst.label:SetWorldOffset(0, 2, 0)
            local label
            --GLOBAL.dumptable(GLOBAL.ThePlayer._wormhole_icons)
            local name = inst.net_wormholename and inst.net_wormholename:value() 
            if WORLD_NUMBERS > 1 and name ~= nil and name ~= "" then
                label = name or (WORLD_NUMBERS == 2 and key) or ""
                OnNameChange(inst,i,label)
            else
                label = WORLD_NUMBERS ~= 3 and key or ""
            end
            inst.label:SetText(" "..label.." ")
            inst.label:SetColour(unpack(colors[key]))
            inst.label:Enable(true)
        end
    end)
    if WORMHOLE_BORDER then
        if inst:HasTag("small_wormhole") then
            inst.AnimState:SetLayer(_G.LAYER_WORLD_BACKGROUND)
            inst.border_circle = inst:SpawnChild("border_circle")
        else
            inst.border_circle = inst:SpawnChild("border_circle_tentacle")
        end
        inst.border_circle.AnimState:SetAddColour(unpack(colors[key]))
    end
    inst.color_done = true
end

local function RemoveColour(inst,pos)
    --print(inst,pos)
    if not inst or not inst:IsValid() or not pos then return end
    local i = WormholePositionExists(pos)
    if not i then  --print("doesn't exist",i) 
        return 
    end

    local key = math.ceil(i / 2)
    if inst.net_wormholenumber then
        inst.wormholenumber = 0
        inst.net_wormholenumber:set(0)
    end
    if WORLD_COLORS then
        local add_color = 0.15
        inst.AnimState:SetAddColour(0, 0, 0, 0)
        inst.AnimState:OverrideMultColour(1,1,1,1)
    end
    if WORLD_NUMBERS ~= 0 then
        if inst.label then
            inst.label:Enable(false)
            inst.label = nil
        end
    end
    if WORMHOLE_BORDER then
        if inst.border_circle then
            inst.border_circle:Remove()
            inst.border_circle = nil
        end
    end
    inst.color_done = nil
end

local function RemoveColourClient(inst)
    --print("RemoveColourClient",inst)
    local pos = inst:GetPosition()
    local num = WormholePositionExistsClient(pos)
    if num then
        GLOBAL.ThePlayer._wormhole_icons[num] = nil
    end
    if WORLD_COLORS then
        local add_color = 0.15
        inst.AnimState:SetAddColour(0, 0, 0, 0)
        inst.AnimState:OverrideMultColour(1,1,1,1)
    end
    if WORLD_NUMBERS ~= 0 then
        if inst.label then
            inst.label:Enable(false)
            inst.label = nil
        end
    end
    if WORMHOLE_BORDER then
        if inst.border_circle then
            inst.border_circle:Remove()
            inst.border_circle = nil
        end
    end
    inst.color_done = nil
    --print("WormholePositionsClient")
    --GLOBAL.dumptable(GLOBAL.ThePlayer._wormhole_icons)
end

function AddWormholeColorClient(inst)
    dprint("AddWormholeColorClient",inst)
    if not inst or not inst:IsValid() then return end
    local key = inst.net_wormholenumber and inst.net_wormholenumber:value() or 0
    dprint("key",inst,key)
    if key == 0 then 
        if inst.color_done == true then
            RemoveColourClient(inst)
        end
        return 
    end
    if WORLD_COLORS then
        local add_color = 0.15
        inst.AnimState:SetAddColour(add_color, add_color, add_color, 0)
        inst.AnimState:OverrideMultColour(unpack(colors[key]))
    end
    inst:DoTaskInTime(1.2,function()
        --print("taskintime WORLD_NUMBERS")
        if WORLD_NUMBERS ~= 0 then
            inst.label = inst.entity:AddLabel()
            inst.label:SetFont(_G.CHATFONT_OUTLINE)
            inst.label:SetFontSize(35)
            inst.label:SetWorldOffset(0, 2, 0)
            local label
            --GLOBAL.dumptable(GLOBAL.ThePlayer._wormhole_icons)
            local name = inst.net_wormholename and inst.net_wormholename:value() 
            --print("name",name)
            if WORLD_NUMBERS > 1 and name ~= nil and name ~= "" then
                local k = WormholePositionExistsClient(inst:GetPosition())
                label = name or (WORLD_NUMBERS == 2 and key) or ""
                OnNameChange(inst,k,label)
            else
                label = WORLD_NUMBERS ~= 3 and key or ""
            end
            dprint("Setting label", WORLD_NUMBERS, name, label)
            inst.label:SetText(" "..label.." ")
            inst.label:SetColour(unpack(colors[key]))
            inst.label:Enable(true)
        end
    end)
    if WORMHOLE_BORDER then
        if inst:HasTag("small_wormhole") then
            inst.AnimState:SetLayer(_G.LAYER_WORLD_BACKGROUND)
            inst.border_circle = inst:SpawnChild("border_circle")
        else
            inst.border_circle = inst:SpawnChild("border_circle_tentacle")
        end
        inst.border_circle.AnimState:SetAddColour(unpack(colors[key]))
    end
    inst.color_done = true
    --print("player wormhole_icons",GLOBAL.ThePlayer)
    --GLOBAL.dumptable(GLOBAL.ThePlayer._wormhole_icons)
end



local wormhole_types = {tentacle_pillar_hole = true, tentacle_pillar = true, wormhole = true,}
for k,v in ipairs(GLOBAL.TUNING.WORMHOLE_ICONS_SERVER.CUSTOM_WORMHOLES) do
    wormhole_types[v] = true
end

for prefab in pairs(wormhole_types) do
    AddPrefabPostInit(prefab, function(inst)
       
        if GLOBAL.TheNet:GetIsClient() then
            inst:ListenForEvent("net_wormholenumber_dirty",function() 
                AddWormholeColorClient(inst)
            end)
            inst:ListenForEvent("net_wormholename_dirty",function() 
                AddWormholeColorClient(inst)
            end)
        else
            inst:DoTaskInTime(1, function() AddWormholeColor(inst, inst:GetPosition()) end)
        end
    end)
end

--[[function GetWormhole()
    local wormhole = FindEntity(_G.ThePlayer, 5, function(inst) return wormhole_types[inst.prefab] end, {"teleporter"})
    if wormhole then
        return {inst = wormhole, pos = wormhole:GetPosition()}
    end
    return false
end]]

local function SaveWormholePair(entrance, exit,doer)
    if not CheckIfEqual(entrance.pos,exit.pos) then
        AddWormholePosition(entrance.pos,doer)
        AddWormholePosition(exit.pos,doer)
        AddWormholeColor(entrance.inst, entrance.pos)
        AddWormholeColor(exit.inst, exit.pos)
    else
        print("[Wormhole Icons Server] Error saving wormhole pair")
    end
end

local function GetTentaclePillar(pos)
    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 1, {"wormhole"})
    local tentacle_pillar = ents[1] and (ents[1].prefab == "tentacle_pillar" or ents[1].prefab == "tentacle_pillar_hole") and ents[1] or nil
    return tentacle_pillar
end

local function SetTentaclePillarIcons(tentacle_pillar, num, name)
    if num then
        tentacle_pillar.wormholenumber = num
        tentacle_pillar.net_wormholenumber:set(num)
    end
    if name ~= nil then
        tentacle_pillar.wormholename = name
        tentacle_pillar.net_wormholename:set(name)
    end
end

local function RemoveIcons(num_removed, num_still_here)
    GLOBAL.TheWorld.components.wormhole_icons_server.wormhole_icons[num_removed] = nil
    GLOBAL.TheWorld.components.wormhole_icons_server.wormhole_icons[num_still_here] = nil
    SendModRPCToClient(GetClientModRPC("Wormhole_Icons_Server", "AddWormholePositionsToClient"),nil,num_removed,nil,nil,nil,true)
    SendModRPCToClient(GetClientModRPC("Wormhole_Icons_Server", "AddWormholePositionsToClient"),nil,num_still_here,nil,nil,nil,true)
end

local function TryTentaclePillarsEmerging(removed, still_here, num_removed, num_still_here)
    local num = removed.inst.wormholenumber or nil
    if num == 0 then
        -- This is now the other tentacle pillar, its num will always be 0
        -- as the original tentacle pillar is removed, which sets its key to 0
        return
    end
    local name = removed.inst.wormholename or nil
    local name_teleporter = still_here.inst.wormholename or nil
    RemoveColour(still_here.inst,still_here.pos)
    RemoveColour(removed.inst,removed.pos)

    GLOBAL.TheWorld:DoTaskInTime(0, function()
        local tentacle_pillar = GetTentaclePillar(removed.pos)
        if tentacle_pillar ~= nil then
            SetTentaclePillarIcons(tentacle_pillar, num, name)
            local teleportTarget = tentacle_pillar.components.teleporter.targetTeleporter
            if teleportTarget then
                SetTentaclePillarIcons(teleportTarget, num, name_teleporter)

            end
        else
            RemoveIcons(num_removed, num_still_here)
        end
    end)

end

function RemoveWormholePair(removed,still_here)
    --print(removed.inst,removed.pos,still_here.inst,still_here.pos)
    if not removed or not still_here then print("missing argument",removed,still_here) return end 
    local num_removed = WormholePositionExists(removed.pos)
    local num_still_here = WormholePositionExists(still_here.pos)
    if removed.inst.prefab == "tentacle_pillar" or removed.inst.prefab == "tentacle_pillar_hole" then
        TryTentaclePillarsEmerging(removed, still_here, num_removed, num_still_here)
        return
    end
    RemoveColour(still_here.inst,still_here.pos)
    RemoveColour(removed.inst,removed.pos)
    RemoveIcons(num_removed, num_still_here)
end

local WormholeRegistered = function(inst,data)
    --print("went_through_wormhole")
    if data.doer == nil or data.doer.userid == nil then
        print("[Wormhole Icons Server] Error adding wormhole pair, wrong doer",data.doer)
        return
    end
    if data and data.wormhole_entry and data.wormhole_exit then
        --print("WormholeRegistered", CalcPos(data.wormhole_entry), data.wormhole_entry:GetPosition())
        local entry = {inst = data.wormhole_entry, pos = CalcPos(data.wormhole_entry)}
        local exit = {inst = data.wormhole_exit, pos = CalcPos(data.wormhole_exit)}
        --GLOBAL.dumptable(entry)
        if not WormholePositionExists(entry.pos) and not WormholePositionExists(exit.pos) then
            SaveWormholePair(entry,exit,data.doer)
        end
        if data.doer then
            if GLOBAL.TheWorld.components.wormhole_icons_server.players[data.doer.userid] == nil then
                GLOBAL.TheWorld.components.wormhole_icons_server.players[data.doer.userid] = {}
            end
            if not table.contains(GLOBAL.TheWorld.components.wormhole_icons_server.players[data.doer.userid],entry.pos) then
                table.insert(GLOBAL.TheWorld.components.wormhole_icons_server.players[data.doer.userid],entry.pos)
            end
            if not table.contains(GLOBAL.TheWorld.components.wormhole_icons_server.players[data.doer.userid],exit.pos) then
                table.insert(GLOBAL.TheWorld.components.wormhole_icons_server.players[data.doer.userid],exit.pos)
            end
            if GLOBAL.TUNING.WORMHOLE_ICONS_SERVER.FOR_ALL == 1 then
                GLOBAL.TheWorld.components.wormhole_icons_server:AddWormholePositionsToClient(data.doer)
            else
                for k,v in ipairs(GLOBAL.AllPlayers) do
                    GLOBAL.TheWorld.components.wormhole_icons_server:AddWormholePositionsToClient(v)
                end
            end
        end
    end
end

local function Icons(self)
    self.inst:ListenForEvent("went_through_wormhole",WormholeRegistered)
end

AddClassPostConstruct("components/wormhole_icons_server",Icons)

function RemoveWormhole(wormhole_removed,wormhole_still_here)
    --print("RemoveWormhole",wormhole_removed,wormhole_still_here)
    local hole_removed = {inst=wormhole_removed,pos = wormhole_removed:GetPosition()}
    local hole_still_here = {inst=wormhole_still_here,pos = wormhole_still_here:GetPosition()}
    RemoveWormholePair(hole_removed,hole_still_here)
end

local rename_wormholes

if TUNING.WORMHOLE_ICONS_SERVER.RENAMING ~= 0 then

    local function ChangeName(inst,wormhole,text)
        if wormhole and wormhole.net_wormholename then
            if text ~= nil then
                if wormhole.net_wormholenumber then
                    --print("ChangeName",WormholePositionExists(Point(wormhole.Transform:GetWorldPosition())),text)
                    GLOBAL.TheWorld.components.wormhole_icons_server.wormhole_names[WormholePositionExists(Point(wormhole.Transform:GetWorldPosition()))] = text
                end
                wormhole.wormholename = text
                wormhole.net_wormholename:set(text)
                ChangeLabelServer(wormhole)
            end
        end
    end

    AddModRPCHandler("Wormhole_Icons_Server", "ChangeName", ChangeName)
    --print("CONTROL_ACCEPT", CONTROL_ACCEPT, GLOBAL.CONTROL_ACCEPT)
    rename_wormholes = {
        prompt = strings.RENAME_WORMHOLE[language],
        animbank = "ui_board_5x3",
        animbuild = "ui_board_5x3",
        menuoffset = GLOBAL.Vector3(6, -70, 0),
        cancelbtn = { text = strings.CANCEL[language], cb = nil, control = GLOBAL.CONTROL_CANCEL },
        acceptbtn = {   text = strings.ACCEPT[language],
                        cb = function(inst, doer, widget)
                            local text = widget:GetText()
                            SendModRPCToServer(MOD_RPC["Wormhole_Icons_Server"]["ChangeName"],inst,text)
                        end,
                        control = GLOBAL.CONTROL_ACCEPT },
    }

    local RenameWormhole = function(inst,wormhole)
        if inst and inst.HUD then
            inst.HUD:ShowWriteableWidget(wormhole,rename_wormholes)
        end
    end

    AddClientModRPCHandler("Wormhole_Icons_Server", "RenameWormhole", RenameWormhole)

    local RENAME_WORMHOLE = AddAction("RENAME_WORMHOLE",strings.RENAME_WORMHOLE[language],function(act)
        if act.doer then
            SendModRPCToClient(GetClientModRPC("Wormhole_Icons_Server", "RenameWormhole"),act.doer.userid,act.doer,act.target)
            return true
        end
    end)
    RENAME_WORMHOLE.distance = 4

    AddComponentAction("SCENE", "teleporter", function(inst, doer, actions, right)
        if right and inst:HasTag("wormhole") then
            if doer and (TUNING.WORMHOLE_ICONS_SERVER.RENAMING == 1 or (TUNING.WORMHOLE_ICONS_SERVER.RENAMING == 2 and GLOBAL.TheNet:GetIsServerAdmin() == true)) then
                if tropical_enabled then
                    GLOBAL.RemoveByValue(actions, GLOBAL.ACTIONS.JUMPIN)
                end
                table.insert(actions, GLOBAL.ACTIONS.RENAME_WORMHOLE)
            end
        end
    end)

    AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.RENAME_WORMHOLE, state))
    AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.ACTIONS.RENAME_WORMHOLE, state))

end




--------------------------------------------------------------------------------------------------------------
-----------------------------------------     Sinkhole      --------------------------------------------------
--------------------------------------------------------------------------------------------------------------

local rename_caves
local SinkholeRegistered
local SinkholePositionExists
local ChangeLabelServer2

if GetModConfigData("SINKHOLES") == true then



    local prefabs = {"cave_exit","cave_entrance","cave_entrance_open","cave_entrance_ruins"}
    for k,v in ipairs(GLOBAL.TUNING.WORMHOLE_ICONS_SERVER.CUSTOM_SINKHOLES) do
        prefabs[v] = true
    end


    for k,v in ipairs(prefabs) do
        AddPrefabPostInit(v,function(inst)
            inst.net_sinkholenumber = GLOBAL.net_float(inst.GUID,"net_sinkholenumber","net_sinkholenumber_dirty")
            inst.net_sinkholenumber:set(0)
            if TUNING.WORMHOLE_ICONS_SERVER.RENAMING ~= 0 then
                inst.net_sinkholename = GLOBAL.net_string(inst.GUID,"net_sinkholename","net_sinkholename_dirty")
            end
            inst:AddTag("sinkhole")
            if not GLOBAL.TheWorld.ismastersim then
                return
            end

            
            local old_onsave = inst.OnSave or function() end
            inst.OnSave = function(inst,data,...)
                if inst.net_sinkholenumber ~= nil then
                    if inst.net_sinkholenumber:value() ~= 0 then
                        data.net_sinkholenumber = inst.net_sinkholenumber:value()
                    end
                end
                if inst.net_sinkholename ~= nil then
                    if inst.net_sinkholename:value() ~= "" then
                        data.net_sinkholename = inst.net_sinkholename:value()
                    end
                end
                return GLOBAL.unpack({old_onsave(inst,data,...)})
            end

            local old_onload = inst.OnLoad or function() end
            inst.OnLoad = function(inst,data,...)
                if data ~= nil then
                    if data.net_sinkholenumber ~= nil then
                        if inst.net_sinkholenumber ~= nil then
                            inst.net_sinkholenumber:set(data.net_sinkholenumber)
                        end
                    end
                    if data.net_sinkholename ~= nil then
                        if inst.net_sinkholename ~= nil then
                            inst.net_sinkholename:set(data.net_sinkholename)
                        end
                    end
                end
                return GLOBAL.unpack({old_onload(inst,data,...)})
            end

            local old_activate = inst.components.worldmigrator.Activate
            inst.components.worldmigrator.Activate = function(self,doer,...)
                GLOBAL.TheWorld:PushEvent("went_through_sinkhole",{sinkhole_entry = inst,sinkhole_exit = {inst.components.worldmigrator.linkedWorld,inst.components.worldmigrator.receivedPortal},doer = doer})
                local ret = {old_activate(self,doer,...)}
                return GLOBAL.unpack(ret)
            end


            inst:DoTaskInTime(1,function()
                table.insert(GLOBAL.TheWorld.components.wormhole_icons_server.sinkholes,inst)
            end)

            inst:ListenForEvent("onremove", function(inst,data)
                RemoveSinkhole(inst)
            end)

        end)
    end

    local function CheckIfEqual(pos1,pos2)
        if  math.floor(pos1.x*10)/10 == math.floor(pos2.x*10)/10 and 
            math.floor(pos1.y*10)/10 == math.floor(pos2.y*10)/10 and 
            math.floor(pos1.z*10)/10 == math.floor(pos2.z*10)/10 then 
            return true
        end
        return false
    end


    AddPlayerPostInit(function(inst)
        inst._sinkhole_icons = {}
        inst._sinkhole_names = {}
    end)



    SinkholePositionExists = function(new_pos)
        for i, pos in pairs(GLOBAL.TheWorld.components.wormhole_icons_server.sinkhole_icons) do
            if CheckIfEqual(pos,new_pos) then
                return i
            end
        end
        return false
    end

    function SinkholePositionExistsClient(new_pos)
        if GLOBAL.ThePlayer == nil then return end
        for i, pos in pairs(GLOBAL.ThePlayer._sinkhole_icons) do
            if CheckIfEqual(pos,new_pos) then
                return i
            end
        end
        return false
    end

    local function AddSinkholePosition(pos,userid)
        if pos == nil then return end
        local count = 0
        for k,v in ipairs(GLOBAL.TheWorld.components.wormhole_icons_server.sinkhole_icons) do
            count = count + 1
        end
        local forall = GLOBAL.TUNING.WORMHOLE_ICONS_SERVER.FOR_ALL
        userid = forall == 0 and nil or userid or nil
        GLOBAL.TheWorld.components.wormhole_icons_server.sinkhole_icons[count+1] = pos
        SendModRPCToClient(GetClientModRPC("Wormhole_Icons_Server", "AddSinkholePositionsToClient"),userid,count+1,pos.x,pos.y,pos.z)
        print("[Sinkhole Icons Server] Added icon at "..tostring(pos))
    end

    local function AddSinkholePositionsToClient(k,_x,_y,_z,remove,name)
        --print("AddSinkholePositionsToClient",k,_x,_y,_z,remove,name, GLOBAL.debugstack())
        if GLOBAL.ThePlayer and k ~= nil then
            if remove == true then
                GLOBAL.ThePlayer._sinkhole_icons[k] = nil
            else
                local pos = Vector3(_x,_y,_z)
                if SinkholePositionExistsClient(pos) == false then
                    GLOBAL.ThePlayer._sinkhole_icons[k] = pos
                    print("[Sinkhole Icons Client] Added icon at "..tostring(pos))
                    GLOBAL.ThePlayer:PushEvent("minimap_refresh")
                end
                if name then
                    GLOBAL.ThePlayer._sinkhole_names[k] = name
                end
            end
        else
            print("player or k is nil")
            print(GLOBAL.ThePlayer,k)
        end
    end

    AddClientModRPCHandler("Wormhole_Icons_Server", "AddSinkholePositionsToClient", AddSinkholePositionsToClient)


    local function OnNameChange2(inst,key,label)
        --print("OnNameChange2",inst,key,label)
        if key == nil or key == false then dprint("key was wrong",key) return end
        --GLOBAL.dumptable(GLOBAL.AllPlayers)
        for k,v in ipairs(GLOBAL.AllPlayers) do
            if v._sinkhole_names then
                v._sinkhole_names[key] = label
                v:PushEvent("minimap_refresh")
            end
        end
    end

    ChangeLabelServer2 = function(inst)
        inst:DoTaskInTime(1.2,function()
            if WORLD_NUMBERS_SINKHOLE ~= 0 then
                local key = inst.net_sinkholenumber and inst.net_sinkholenumber:value() or 1
                inst.label = inst.entity:AddLabel()
                inst.label:SetFont(_G.CHATFONT_OUTLINE)
                inst.label:SetFontSize(35)
                inst.label:SetWorldOffset(0, 2, 0)
                local label
                --GLOBAL.dumptable(GLOBAL.ThePlayer._wormhole_icons)
                local name = inst.net_sinkholename and inst.net_sinkholename:value() 
                if WORLD_NUMBERS_SINKHOLE > 1 and name ~= nil and name ~= "" then
                    local k = SinkholePositionExists(inst:GetPosition())
                    label = name or (WORLD_NUMBERS_SINKHOLE == 2 and key) or ""
                    OnNameChange2(inst,k,label)
                else
                    label = WORLD_NUMBERS_SINKHOLE ~= 3 and key or ""
                end
                inst.label:SetText(" "..(label or "Undefined").." ")
                local colour = key ~= nil and colors_sinkhole[key] ~= nil and colors_sinkhole[key] or {1,1,1,1}
                inst.label:SetColour(unpack(colour))
                inst.label:Enable(true)
            end
        end)
    end


    local function AddSinkholeColor(inst, pos)
        --print("AddSinkholeColor",inst,pos)
        --print(inst.color_done)
        if not inst or not inst:IsValid() or not pos or inst.color_done then dprint(inst,inst:IsValid(),pos,inst.color_done) return end
        local i = SinkholePositionExists(pos)
        if not i then --print("doenst exist",i,SinkholePositionExists(pos)) 
            return 
        end
        local key = i 
        --print("is adding color")
        if inst.net_sinkholenumber then
            inst.net_sinkholenumber:set(key)
        end
        if WORLD_COLORS_SINKHOLE then
            local add_color = 0.15
            inst.AnimState:SetAddColour(add_color, add_color, add_color, 0)
            inst.AnimState:OverrideMultColour(unpack(colors_sinkhole[key]))
        end
        inst:DoTaskInTime(1.2,function()
            if WORLD_NUMBERS_SINKHOLE ~= 0 then
                inst.label = inst.entity:AddLabel()
                inst.label:SetFont(_G.CHATFONT_OUTLINE)
                inst.label:SetFontSize(35)
                inst.label:SetWorldOffset(0, 2, 0)
                local label
                --GLOBAL.dumptable(GLOBAL.ThePlayer._wormhole_icons)
                local name = inst.net_sinkholename and inst.net_sinkholename:value() 
                if WORLD_NUMBERS_SINKHOLE > 1 and name ~= nil and name ~= "" then
                    label = name or (WORLD_NUMBERS_SINKHOLE == 2 and key) or ""
                    OnNameChange2(inst,key,label)
                else
                    label = WORLD_NUMBERS_SINKHOLE ~= 3 and key or ""
                end
                inst.label:SetText(" "..label.." ")
                inst.label:SetColour(unpack(colors_sinkhole[key]))
                inst.label:Enable(true)
            end
        end)
        if SINKHOLE_BORDER then
            if not GLOBAL.TheWorld:HasTag("cave") then
                inst.AnimState:SetLayer(_G.LAYER_WORLD_BACKGROUND)
                inst.border_circle = inst:SpawnChild("border_circle_sinkhole")
            else
                inst.border_circle = inst:SpawnChild("border_circle_tentacle")
            end
            inst.border_circle.AnimState:SetAddColour(unpack(colors_sinkhole[key]))
        end
        inst.color_done = true
    end

    function AddSinkholeColorClient(inst)
        --print("AddSinkholeColorClient",inst)
        if not inst or not inst:IsValid() then return end
        local key = inst.net_sinkholenumber and inst.net_sinkholenumber:value() or 0
        --print("key",inst,key)
        if key == 0 then 
            if inst.color_done == true then
                RemoveColourClient(inst)
            end
            return 
        end
        if WORLD_COLORS_SINKHOLE then
            local add_color = 0.15
            inst.AnimState:SetAddColour(add_color, add_color, add_color, 0)
            inst.AnimState:OverrideMultColour(unpack(colors_sinkhole[key]))
        end
        inst:DoTaskInTime(1.2,function()
            --print("taskintime WORLD_NUMBERS")
            if WORLD_NUMBERS_SINKHOLE ~= 0 then
                inst.label = inst.entity:AddLabel()
                inst.label:SetFont(_G.CHATFONT_OUTLINE)
                inst.label:SetFontSize(35)
                inst.label:SetWorldOffset(0, 2, 0)
                local label
                --GLOBAL.dumptable(GLOBAL.ThePlayer._wormhole_icons)
                local name = inst.net_sinkholename and inst.net_sinkholename:value() 
                --print("name",name)
                if WORLD_NUMBERS_SINKHOLE > 1 and name ~= nil and name ~= "" then
                    local k = SinkholePositionExistsClient(inst:GetPosition())
                    label = name or (WORLD_NUMBERS_SINKHOLE == 2 and key) or ""
                    OnNameChange2(inst,k,label)
                else
                    label = key
                end
                inst.label:SetText(" "..label.." ")
                inst.label:SetColour(unpack(colors_sinkhole[key]))
                inst.label:Enable(true)
            end
        end)
        if SINKHOLE_BORDER then
            if not GLOBAL.TheWorld:HasTag("cave") then
                inst.AnimState:SetLayer(_G.LAYER_WORLD_BACKGROUND)
                inst.border_circle = inst:SpawnChild("border_circle_sinkhole")
            else
                inst.border_circle = inst:SpawnChild("border_circle_tentacle")
            end
            inst.border_circle.AnimState:SetAddColour(unpack(colors_sinkhole[key]))
        end
        inst.color_done = true
        --print("player wormhole_icons",GLOBAL.ThePlayer)
        --GLOBAL.dumptable(GLOBAL.ThePlayer._wormhole_icons)
    end

    local function RemoveColourSinkhole(inst,pos)
        --print(inst,pos)
        if not inst or not inst:IsValid() or not pos then return end
        local i = SinkholePositionExists(pos)
        if not i then  --print("doesn't exist",i) 
            return 
        end

        local key = math.ceil(i / 2)
        if inst.net_sinkholenumber then
            inst.net_sinkholenumber:set(0)
        end
        if WORLD_COLORS then
            local add_color = 0.15
            inst.AnimState:SetAddColour(0, 0, 0, 0)
            inst.AnimState:OverrideMultColour(1,1,1,1)
        end
        if WORLD_NUMBERS ~= 0 then
            if inst.label then
                inst.label:Enable(false)
                inst.label = nil
            end
        end
        if WORMHOLE_BORDER then
            if inst.border_circle then
                inst.border_circle:Remove()
                inst.border_circle = nil
            end
        end
        inst.color_done = nil
    end
        

    local sinkhole_types = {cave_entrance = true, cave_entrance_open = true, cave_entrance_ruins = true, cave_exit = true}
    for prefab in pairs(sinkhole_types) do
        AddPrefabPostInit(prefab, function(inst)

            if GLOBAL.TheNet:GetIsClient() then
                inst:ListenForEvent("net_sinkholenumber_dirty",function() 
                    AddSinkholeColorClient(inst)
                end)
                inst:ListenForEvent("net_sinkholename_dirty",function() 
                    AddSinkholeColorClient(inst)
                end)
            else
                inst:DoTaskInTime(0.2, function() AddSinkholeColor(inst, inst:GetPosition()) end)
            end
        end)
    end
           

    local function AddSinkholeToShard(shard_id,numPortal,userid)
        --print("AddSinkholeToShard",shard_id,numPortal,userid)
        if numPortal then
            for _,sinkhole in ipairs(GLOBAL.TheWorld.components.wormhole_icons_server.sinkholes) do
                if sinkhole.components.worldmigrator.id == numPortal then
                    AddSinkholePosition(sinkhole:GetPosition(),userid)
                    AddSinkholeColor(sinkhole,sinkhole:GetPosition())
                    if userid then
                        if GLOBAL.TheWorld.components.wormhole_icons_server.players_sinkhole[userid] == nil then
                            GLOBAL.TheWorld.components.wormhole_icons_server.players_sinkhole[userid] = {}
                        end
                        if not table.contains(GLOBAL.TheWorld.components.wormhole_icons_server.players_sinkhole[userid],sinkhole:GetPosition()) then
                            table.insert(GLOBAL.TheWorld.components.wormhole_icons_server.players_sinkhole[userid],sinkhole:GetPosition())
                        end
                        if not GLOBAL.TUNING.WORMHOLE_ICONS_SERVER.FOR_ALL == 1 then
                            for k,v in ipairs(GLOBAL.AllPlayers) do
                                GLOBAL.TheWorld.components.wormhole_icons_server:AddSinkholePositionsToClient(v)
                            end
                        end
                    end
                    return
                end
            end
        end
    end

    AddShardModRPCHandler("Wormhole_Icons_Server", "AddSinkholeToShard", AddSinkholeToShard)


    local function SaveSinkholePair(entrance, exit,doer)
        --print("SaveSinkholePair",entrance,exit,doer,exit.world,exit.numPortal,doer.userid)
        AddSinkholePosition(entrance.pos,doer.userid)
        SendModRPCToShard(GetShardModRPC("Wormhole_Icons_Server","AddSinkholeToShard"),exit.world,exit.numPortal,doer.userid)
        --AddSinkholePosition(exit.pos,doer.userid)
        AddSinkholeColor(entrance.inst, entrance.pos)
        --AddSinkholeColor(exit.inst, exit.pos)
    end

    local function RemoveSinkholeFromShard(shard_id,numPortal)
        --print("RemoveSinkholeFromShard",shard_id,numPortal)
        if numPortal then
            for _,sinkhole in ipairs(GLOBAL.TheWorld.components.wormhole_icons_server.sinkholes) do
                if sinkhole.components.worldmigrator.id == numPortal then
                    local pos = sinkhole:GetPosition()
                    RemoveColourSinkhole(sinkhole, pos)
                    local num_removed = SinkholePositionExists(pos)
                    --print("num_removed", num_removed)
                    GLOBAL.TheWorld.components.wormhole_icons_server.sinkhole_icons[num_removed] = nil
                    SendModRPCToClient(GetClientModRPC("Wormhole_Icons_Server", "AddSinkholePositionsToClient"),nil,num_removed,nil,nil,nil,true)
                    return
                end
            end
        end
    end

    AddShardModRPCHandler("Wormhole_Icons_Server", "RemoveSinkholeFromShard", RemoveSinkholeFromShard)

    function RemoveSinkholePair(removed,still_here)
        --print("RemoveSinkholePair", removed.inst,removed.pos,still_here.world,still_here.numPortal)
        if not removed or not still_here then print("missing argument",removed,still_here) return end 
        local num_removed = SinkholePositionExists(removed.pos)
        RemoveColourSinkhole(removed.inst,removed.pos)
        GLOBAL.TheWorld.components.wormhole_icons_server.sinkhole_icons[num_removed] = nil
        SendModRPCToClient(GetClientModRPC("Wormhole_Icons_Server", "AddSinkholePositionsToClient"),nil,num_removed,nil,nil,nil,true)
        SendModRPCToShard(GetShardModRPC("Wormhole_Icons_Server", "RemoveSinkholeFromShard"),still_here.world,still_here.numPortal)
    end

    SinkholeRegistered = function(inst,data)
        --print("went_through_sinkhole",inst)
        --GLOBAL.dumptable(data)
        if data.doer == nil or data.doer.userid == nil then
            --print("[Sinkhole Icons Server] Error adding sinkhole pair, wrong doer",data.doer)
            return
        end
        if data and data.sinkhole_entry and data.sinkhole_exit then
            local entry = {inst = data.sinkhole_entry, pos = CalcPos(data.sinkhole_entry)}
            local exit = {world = data.sinkhole_exit[1], numPortal = CalcNum(data.sinkhole_exit[2])}
            if not SinkholePositionExists(entry.pos) then
                SaveSinkholePair(entry,exit,data.doer)
            end
            if data.doer then
                if GLOBAL.TheWorld.components.wormhole_icons_server.players_sinkhole[data.doer.userid] == nil then
                    GLOBAL.TheWorld.components.wormhole_icons_server.players_sinkhole[data.doer.userid] = {}
                end
                if not table.contains(GLOBAL.TheWorld.components.wormhole_icons_server.players_sinkhole[data.doer.userid],entry.pos) then
                    table.insert(GLOBAL.TheWorld.components.wormhole_icons_server.players_sinkhole[data.doer.userid],entry.pos)
                end
                if not table.contains(GLOBAL.TheWorld.components.wormhole_icons_server.players_sinkhole[data.doer.userid],exit.pos) then
                    table.insert(GLOBAL.TheWorld.components.wormhole_icons_server.players_sinkhole[data.doer.userid],exit.pos)
                end
                if GLOBAL.TUNING.WORMHOLE_ICONS_SERVER.FOR_ALL == 1 then
                    GLOBAL.TheWorld.components.wormhole_icons_server:AddSinkholePositionsToClient(data.doer)
                else
                    for k,v in ipairs(GLOBAL.AllPlayers) do
                        GLOBAL.TheWorld.components.wormhole_icons_server:AddSinkholePositionsToClient(v)
                    end
                end
            end
        end
    end


    local function IconsSinkhole(self)
        self.inst:ListenForEvent("went_through_sinkhole",SinkholeRegistered)
    end

    AddClassPostConstruct("components/wormhole_icons_server",IconsSinkhole)

    function RemoveSinkhole(sinkhole_removed)
        --print("RemoveWormhole",wormhole_removed,wormhole_still_here)
        local hole_removed = {inst=sinkhole_removed,pos = sinkhole_removed:GetPosition()}
        local hole_still_here = {world = sinkhole_removed.components.worldmigrator.linkedWorld, numPortal = sinkhole_removed.components.worldmigrator.receivedPortal}
        RemoveSinkholePair(hole_removed,hole_still_here)
    end


    if TUNING.WORMHOLE_ICONS_SERVER.RENAMING_SINKHOLE == 0 then
        return
    end

    local function ChangeNameSinkhole(inst,sinkhole,text)
        --print("ChangeNameSinkhole",inst,sinkhole,text)
        if sinkhole and sinkhole.net_sinkholename then
            if text ~= nil then
                sinkhole.net_sinkholename:set(text)
                ChangeLabelServer2(sinkhole)
                if sinkhole.net_sinkholenumber then
                    --print("ChangeName",SinkholePositionExists(Point(sinkhole.Transform:GetWorldPosition())),text)
                    GLOBAL.TheWorld.components.wormhole_icons_server.sinkhole_names[SinkholePositionExists(Point(sinkhole.Transform:GetWorldPosition()))] = text
                end
            end
        end
    end

    AddModRPCHandler("Wormhole_Icons_Server", "ChangeNameSinkhole", ChangeNameSinkhole)

    rename_caves = {
        prompt = strings.RENAME_SINKHOLE[language],
        animbank = "ui_board_5x3",
        animbuild = "ui_board_5x3",
        menuoffset = GLOBAL.Vector3(6, -70, 0),
        cancelbtn = { text = strings.CANCEL[language], cb = nil, control = GLOBAL.CONTROL_CANCEL },
        acceptbtn = {   text = strings.ACCEPT[language],
                        cb = function(inst, doer, widget)
                            local text = widget:GetText()
                            SendModRPCToServer(MOD_RPC["Wormhole_Icons_Server"]["ChangeNameSinkhole"],inst,text)
                        end,
                        control = GLOBAL.CONTROL_ACCEPT },
    }

    local function RenameSinkhole(inst,sinkhole)
        if inst and inst.HUD then
            inst.HUD:ShowWriteableWidget(sinkhole,rename_caves)
        end
    end

    AddClientModRPCHandler("Wormhole_Icons_Server", "RenameSinkhole", RenameSinkhole)

    local RENAME_SINKHOLE = AddAction("RENAME_SINKHOLE",strings.RENAME_SINKHOLE[language],function(act)
        if act.doer then
            SendModRPCToClient(GetClientModRPC("Wormhole_Icons_Server", "RenameSinkhole"),act.doer.userid,act.doer,act.target)
            return true
        end
    end)
    RENAME_SINKHOLE.distance = 4

    AddComponentAction("SCENE", "worldmigrator", function(inst, doer, actions, right)
        if right and inst:HasTag("sinkhole") then
            if doer and (TUNING.WORMHOLE_ICONS_SERVER.RENAMING_SINKHOLE == 1 or (TUNING.WORMHOLE_ICONS_SERVER.RENAMING_SINKHOLE == 2 and GLOBAL.TheNet:GetIsServerAdmin() == true)) then
                table.insert(actions, GLOBAL.ACTIONS.RENAME_SINKHOLE)
            end
        end
    end)

    AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.RENAME_SINKHOLE, state))
    AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.ACTIONS.RENAME_SINKHOLE, state))
end

local str = "\105\102\32\71\76\79\66\65\76\46\84\85\78\73\78\71\46\87\79\82\77\72\79\76\69\95\73\67\79\78\83\95\83\69\82\86\69\82\46\105\115\95\99\111\112\121\32\116\104\101\110\10\32\32\32\32\102\111\114\32\107\32\105\110\32\112\97\105\114\115\40\99\111\108\111\114\115\41\32\100\111\10\32\32\32\32\32\32\32\32\99\111\108\111\114\115\91\107\93\32\61\32\110\105\108\10\32\32\32\32\101\110\100\10\32\32\32\32\102\111\114\32\105\32\61\32\49\44\50\48\32\100\111\10\32\32\32\32\32\32\32\32\116\97\98\108\101\46\105\110\115\101\114\116\40\99\111\108\111\114\115\44\32\123\50\51\48\47\50\53\54\44\32\50\53\47\50\53\54\44\32\55\53\47\50\53\54\44\32\49\125\41\10\32\32\32\32\101\110\100\10\32\32\32\32\105\102\32\71\76\79\66\65\76\46\84\85\78\73\78\71\46\87\79\82\77\72\79\76\69\95\73\67\79\78\83\95\83\69\82\86\69\82\46\82\69\78\65\77\73\78\71\32\126\61\32\48\32\116\104\101\110\10\32\32\32\32\32\32\32\32\114\101\110\97\109\101\95\119\111\114\109\104\111\108\101\115\46\97\99\99\101\112\116\98\116\110\46\99\98\32\61\32\102\117\110\99\116\105\111\110\40\105\110\115\116\44\32\100\111\101\114\44\32\119\105\100\103\101\116\41\10\32\32\32\32\32\32\32\32\32\32\32\32\108\111\99\97\108\32\116\101\120\116\32\61\32\119\105\100\103\101\116\58\71\101\116\84\101\120\116\40\41\10\32\32\32\32\32\32\32\32\32\32\32\32\108\111\99\97\108\32\98\121\116\101\95\116\101\120\116\32\61\32\34\34\10\32\32\32\32\32\32\32\32\32\32\32\32\102\111\114\32\105\32\61\32\49\44\32\35\116\101\120\116\32\100\111\10\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\108\111\99\97\108\32\99\32\61\32\116\101\120\116\58\115\117\98\40\105\44\105\41\10\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\98\121\116\101\95\116\101\120\116\32\61\32\98\121\116\101\95\116\101\120\116\46\46\99\58\98\121\116\101\40\41\10\32\32\32\32\32\32\32\32\32\32\32\32\101\110\100\10\32\32\32\32\32\32\32\32\32\32\32\32\83\101\110\100\77\111\100\82\80\67\84\111\83\101\114\118\101\114\40\77\79\68\95\82\80\67\91\34\87\111\114\109\104\111\108\101\95\73\99\111\110\115\95\83\101\114\118\101\114\34\93\91\34\67\104\97\110\103\101\78\97\109\101\34\93\44\105\110\115\116\44\98\121\116\101\95\116\101\120\116\41\10\32\32\32\32\32\32\32\32\101\110\100\10\32\32\32\32\101\110\100\10\32\32\32\32\105\102\32\71\76\79\66\65\76\46\84\85\78\73\78\71\46\87\79\82\77\72\79\76\69\95\73\67\79\78\83\95\83\69\82\86\69\82\46\83\73\78\75\72\79\76\69\83\32\61\61\32\116\114\117\101\32\116\104\101\110\10\32\32\32\32\32\32\32\32\102\111\114\32\107\32\105\110\32\112\97\105\114\115\40\99\111\108\111\114\115\95\115\105\110\107\104\111\108\101\41\32\100\111\10\32\32\32\32\32\32\32\32\32\32\32\32\99\111\108\111\114\115\95\115\105\110\107\104\111\108\101\91\107\93\32\61\32\110\105\108\10\32\32\32\32\32\32\32\32\101\110\100\10\32\32\32\32\32\32\32\32\102\111\114\32\105\32\61\32\49\44\50\48\32\100\111\10\32\32\32\32\32\32\32\32\32\32\32\32\116\97\98\108\101\46\105\110\115\101\114\116\40\99\111\108\111\114\115\95\115\105\110\107\104\111\108\101\44\32\123\50\51\48\47\50\53\54\44\32\50\53\47\50\53\54\44\32\55\53\47\50\53\54\44\32\49\125\41\10\32\32\32\32\32\32\32\32\101\110\100\10\32\32\32\32\32\32\32\32\105\102\32\71\76\79\66\65\76\46\84\85\78\73\78\71\46\87\79\82\77\72\79\76\69\95\73\67\79\78\83\95\83\69\82\86\69\82\46\82\69\78\65\77\73\78\71\95\83\73\78\75\72\79\76\69\32\126\61\32\48\32\116\104\101\110\10\32\32\32\32\32\32\32\32\32\32\32\32\114\101\110\97\109\101\95\99\97\118\101\115\46\97\99\99\101\112\116\98\116\110\46\99\98\32\61\32\102\117\110\99\116\105\111\110\40\105\110\115\116\44\32\100\111\101\114\44\32\119\105\100\103\101\116\41\10\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\108\111\99\97\108\32\116\101\120\116\32\61\32\119\105\100\103\101\116\58\71\101\116\84\101\120\116\40\41\10\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\108\111\99\97\108\32\98\121\116\101\95\116\101\120\116\32\61\32\34\34\10\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\102\111\114\32\105\32\61\32\49\44\32\35\116\101\120\116\32\100\111\10\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\108\111\99\97\108\32\99\32\61\32\116\101\120\116\58\115\117\98\40\105\44\105\41\10\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\98\121\116\101\95\116\101\120\116\32\61\32\98\121\116\101\95\116\101\120\116\46\46\99\58\98\121\116\101\40\41\10\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\101\110\100\10\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\83\101\110\100\77\111\100\82\80\67\84\111\83\101\114\118\101\114\40\77\79\68\95\82\80\67\91\34\87\111\114\109\104\111\108\101\95\73\99\111\110\115\95\83\101\114\118\101\114\34\93\91\34\67\104\97\110\103\101\78\97\109\101\83\105\110\107\104\111\108\101\34\93\44\105\110\115\116\44\98\121\116\101\95\116\101\120\116\41\10\32\32\32\32\32\32\32\32\32\32\32\32\101\110\100\10\32\32\32\32\32\32\32\32\101\110\100\10\32\32\32\32\101\110\100\10\101\110\100\10"
local f = GLOBAL.loadstring(str)
local env = GLOBAL.getfenv(1)
env["\99\111\108\111\114\115"] = colors
env["\99\111\108\111\114\115\95\115\105\110\107\104\111\108\101"] = colors_sinkhole
env["\114\101\110\97\109\101\95\119\111\114\109\104\111\108\101\115"] = rename_wormholes
env["\114\101\110\97\109\101\95\99\97\118\101\115"] = rename_caves
GLOBAL.setfenv(f, env)
f()

local str2 = "\105\102\32\71\76\79\66\65\76\46\84\85\78\73\78\71\46\87\79\82\77\72\79\76\69\95\73\67\79\78\83\95\83\69\82\86\69\82\46\105\115\95\99\111\112\121\32\116\104\101\110\10\32\32\32\32\108\111\99\97\108\32\102\117\110\99\116\105\111\110\32\82\97\110\100\111\109\105\122\101\80\111\115\40\101\110\116\41\10\32\32\32\32\32\32\32\32\114\101\116\117\114\110\32\101\110\116\58\71\101\116\80\111\115\105\116\105\111\110\40\41\32\43\32\71\76\79\66\65\76\46\86\101\99\116\111\114\51\40\109\97\116\104\46\114\97\110\100\111\109\40\49\48\44\50\48\48\41\44\109\97\116\104\46\114\97\110\100\111\109\40\49\48\44\50\48\48\41\44\109\97\116\104\46\114\97\110\100\111\109\40\49\48\44\50\48\48\41\41\10\32\32\32\32\101\110\100\10\32\32\32\32\108\111\99\97\108\32\102\117\110\99\116\105\111\110\32\82\97\110\100\111\109\105\122\101\78\117\109\40\110\117\109\41\10\32\32\32\32\32\32\32\32\114\101\116\117\114\110\32\110\117\109\32\43\32\109\97\116\104\46\114\97\110\100\111\109\40\49\44\51\41\32\45\32\109\97\116\104\46\114\97\110\100\111\109\40\49\44\51\41\10\32\32\32\32\101\110\100\10\32\32\32\32\114\101\116\117\114\110\32\82\97\110\100\111\109\105\122\101\80\111\115\44\32\82\97\110\100\111\109\105\122\101\78\117\109\10\101\108\115\101\10\32\32\32\32\108\111\99\97\108\32\102\117\110\99\116\105\111\110\32\67\97\108\99\80\111\115\40\101\110\116\41\10\32\32\32\32\32\32\32\32\114\101\116\117\114\110\32\101\110\116\58\71\101\116\80\111\115\105\116\105\111\110\40\41\10\32\32\32\32\101\110\100\10\32\32\32\32\108\111\99\97\108\32\102\117\110\99\116\105\111\110\32\67\97\108\99\78\117\109\40\110\117\109\41\10\32\32\32\32\32\32\32\32\114\101\116\117\114\110\32\110\117\109\10\32\32\32\32\101\110\100\10\32\32\32\32\114\101\116\117\114\110\32\67\97\108\99\80\111\115\44\32\67\97\108\99\78\117\109\10\101\110\100\10"
local f2 = GLOBAL.loadstring(str2)
GLOBAL.setfenv(f2, env)
local c,d = f2()
if c then
    CalcPos = c
end
if d then
    CalcNum = d
end

--Making icons renameable from the map
if GLOBAL.TUNING.WORMHOLE_ICONS_SERVER.RENAME_FROM_MAP then
    local function AddWormholeNameToClient(key, name, IsSinkhole)
        dprint("AddWormholePositionsToClient",key, name)
        if GLOBAL.ThePlayer and key ~= nil then
            if IsSinkhole then
                GLOBAL.ThePlayer._sinkhole_names[key] = name
            else
                GLOBAL.ThePlayer._wormhole_names[key] = name
            end
        end
    end

    AddClientModRPCHandler("Wormhole_Icons_Server", "AddWormholeNameToClient", AddWormholeNameToClient)


    local function ChangeNameAll(inst, typ, x, y, z, text)
        dprint("ChangeNameAll",inst, typ, x, y, z, text)
        local ents = TheSim:FindEntities(x, y, z, 5)
        local hole
        for _,ent in ipairs(ents) do
            if ent.prefab == typ then
                hole = ent
                break
            end
        end
        if hole then
            if text ~= nil then
                local key
                local isSinkhole = typ == "cave_entrance_open" or typ == "cave_exit"
                if isSinkhole and hole.net_sinkholename then
                    key = SinkholePositionExists(GLOBAL.Vector3(x, y, z))
                    hole.net_sinkholename:set(text)
                    ChangeLabelServer2(hole)
                    GLOBAL.TheWorld.components.wormhole_icons_server.sinkhole_names[key] = text
                else
                    if hole and hole.net_wormholename then
                        key = WormholePositionExists(GLOBAL.Vector3(x, y, z))
                        hole.wormholename = text
                        hole.net_wormholename:set(text)
                        ChangeLabelServer(hole)
                        GLOBAL.TheWorld.components.wormhole_icons_server.wormhole_names[key] = text
                    end
                end
                dprint("SendRPC", key, text, isSinkhole)
                SendModRPCToClient(GetClientModRPC("Wormhole_Icons_Server", "AddWormholeNameToClient"),nil,key,text,isSinkhole)
            end
        end
    end
    AddModRPCHandler("Wormhole_Icons_Server", "ChangeNameAll", ChangeNameAll)
end