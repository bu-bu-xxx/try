if GLOBAL.TUNING.WORMHOLE_ICONS_SERVER == nil or type(GLOBAL.TUNING.WORMHOLE_ICONS_SERVER) ~= "table" then
    GLOBAL.TUNING.WORMHOLE_ICONS_SERVER = {}
end
if GLOBAL.TUNING.WORMHOLE_ICONS_SERVER.ENABLED == false then
    print("[INFO] Wormhole/Sinkhole Icons For Server was disabled by another mod that set it's enabled flag to false")
    print("If you want to find out which one it was, search in all mods for WORMHOLE_ICONS_SERVER.ENABLED")
    return
end

--[[if GLOBAL.KnownModIndex:IsModEnabledAny("workshop-2524038682") or GLOBAL.KnownModIndex:IsModEnabledAny("Craftable Wormholes") then
    GLOBAL.TUNING.WORMHOLE_CRAFTER = GLOBAL.TUNING.WORMHOLE_CRAFTER or {}
    GLOBAL.TUNING.WORMHOLE_CRAFTER.ENABLED = false
end]]

--[[if GLOBAL.TUNING.WORMHOLE_CRAFTER and GLOBAL.TUNING.WORMHOLE_CRAFTER.ENABLED ~= false then
    print("[INFO] Wormhole/Sinkhole Icons For Server was disabled by Craftable Wormholes as it has it's own icons enabled")
    print("If you want to rather use this mod, disable wormhole icons in Craftable Wormholes")
    return 
end]]

TUNING.WORMHOLE_ICONS_SERVER["\105\115\95\99\111\112\121"] = false

local str = "\105\102\32\77\79\68\82\79\79\84\58\102\105\110\100\40\34\119\111\114\107\115\104\111\112\45\34\41\32\116\104\101\110\10\32\32\32\32\105\102\32\110\111\116\32\77\79\68\82\79\79\84\58\102\105\110\100\40\34\50\54\50\49\48\57\48\49\55\54\34\41\32\116\104\101\110\10\32\32\32\32\32\32\32\32\45\45\32\68\105\115\97\98\108\101\32\116\104\101\32\109\111\100\32\114\101\97\108\32\113\117\105\99\107\44\32\115\105\110\99\101\32\73\32\100\111\110\39\116\32\119\97\110\116\32\111\116\104\101\114\32\112\101\111\112\108\101\32\117\112\108\111\97\100\105\110\103\32\109\121\32\109\111\100\115\32\119\105\116\104\111\117\116\32\112\101\114\109\105\115\115\105\111\110\33\10\32\32\32\32\32\32\32\32\45\45\32\89\101\115\32\73\39\109\32\108\111\111\107\105\110\103\32\97\116\32\121\111\117\33\10\32\32\32\32\32\32\32\32\45\45\108\111\99\97\108\32\110\97\109\101\32\61\32\34\87\111\114\109\104\111\108\101\115\47\83\105\110\107\104\111\108\101\115\32\73\99\111\110\115\32\70\111\114\32\83\101\114\118\101\114\34\10\32\32\32\32\32\32\32\32\45\45\102\111\114\32\95\44\109\111\100\32\105\110\32\105\112\97\105\114\115\40\71\76\79\66\65\76\46\77\111\100\77\97\110\97\103\101\114\46\109\111\100\115\41\32\100\111\10\32\32\32\32\32\32\32\32\32\32\32\32\45\45\105\102\32\109\111\100\32\97\110\100\32\109\111\100\105\110\102\111\32\97\110\100\32\109\111\100\46\109\111\100\105\110\102\111\46\105\100\32\61\61\32\110\97\109\101\32\116\104\101\110\10\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32\45\45\71\76\79\66\65\76\46\75\110\111\119\110\77\111\100\73\110\100\101\120\58\68\105\115\97\98\108\101\40\110\97\109\101\41\10\32\32\32\32\32\32\32\32\32\32\32\32\45\45\101\110\100\10\32\32\32\32\32\32\32\32\45\45\101\110\100\10\32\32\32\32\32\32\32\32\84\85\78\73\78\71\46\87\79\82\77\72\79\76\69\95\73\67\79\78\83\95\83\69\82\86\69\82\46\105\115\95\99\111\112\121\32\61\32\116\114\117\101\10\32\32\32\32\101\110\100\10\101\110\100\10"
local f = GLOBAL.loadstring(str)
local env = GLOBAL.getfenv(1)
GLOBAL.setfenv(f, env)
f()


local _G = GLOBAL
local require = GLOBAL.require
local Ingredient = GLOBAL.Ingredient
local RECIPETABS = GLOBAL.RECIPETABS
local TECH = GLOBAL.TECH
local TUNING = GLOBAL.TUNING
local TheWorld = GLOBAL.TheWorld
local dprint = GLOBAL.dprint

if not MODROOT:find("workshop-") then
    GLOBAL.CHEATS_ENABLED = true
    GLOBAL.CHEATS_ENABLE_DPRINT = true
    --GLOBAL.DPRINT_PRINT_SOURCELINE = true
end

PrefabFiles = {
    "border_circle",
    "border_circle_tentacle",
    "border_circle_sinkhole",
}

Assets = {

    Asset("IMAGE", "images/tentapillar_icons.tex"),
    Asset("ATLAS", "images/tentapillar_icons.xml"),
    Asset("IMAGE", "images/wormhole_icons.tex"),
    Asset("ATLAS", "images/wormhole_icons.xml"),

    Asset("ATLAS", "images/sinkhole_down.xml"),
    Asset("ATLAS", "images/sinkhole_up.xml"),

}

AddMinimapAtlas("images/tentapillar_icons.xml")
AddMinimapAtlas("images/wormhole_icons.xml")
AddMinimapAtlas("images/sinkhole_up.xml")
AddMinimapAtlas("images/sinkhole_down.xml")


TUNING.WORMHOLE_ICONS_SERVER.FOR_ALL = GetModConfigData("FOR_ALL")
TUNING.WORMHOLE_ICONS_SERVER.RENAMING = GetModConfigData("RENAMING")
TUNING.WORMHOLE_ICONS_SERVER.RENAMING_SINKHOLE = GetModConfigData("RENAMING_SINKHOLE")
TUNING.WORMHOLE_ICONS_SERVER.SANITY = GetModConfigData("SANITY")
TUNING.WORMHOLE_ICONS_SERVER.MAPSCALE = GetModConfigData("MAPSCALE")
TUNING.WORMHOLE_ICONS_SERVER.MINIMAPSCALE = GetModConfigData("MINIMAPSCALE")

TUNING.WORMHOLE_ICONS_SERVER.SINKHOLES = GetModConfigData("SINKHOLES")

TUNING.WORMHOLE_ICONS_SERVER.ICON_PLACEMENT = GetModConfigData("ICON_PLACEMENT")
TUNING.WORMHOLE_ICONS_SERVER.RENAME_FROM_MAP = GetModConfigData("RENAME_FROM_MAP")

--Here you can add custom wormholes/sinkholes so that they can also be be used.
if TUNING.WORMHOLE_ICONS_SERVER.CUSTOM_WORMHOLES == nil then
    TUNING.WORMHOLE_ICONS_SERVER.CUSTOM_WORMHOLES = {}
end
if TUNING.WORMHOLE_ICONS_SERVER.CUSTOM_SINKHOLES == nil then
    TUNING.WORMHOLE_ICONS_SERVER.CUSTOM_SINKHOLES = {}
end

local num_to_name = {
    [1295277999] = "Wormhole Icons [Fixed]",
    [2831613121] = "Wormhole Icons + Custom Colors",
}

if GetModConfigData("DISABLE") and not GLOBAL.TheNet:IsDedicated() or not GLOBAL.TheNet:GetServerGameMode() == "lavaarena" then
    for id, name in pairs(num_to_name) do    
        if GLOBAL.KnownModIndex:IsModEnabled("workshop-"..id) then
            name = GLOBAL.KnownModIndex:GetModActualName(name)
            local WORMHOLE_MARKS_DISABLE = GLOBAL.GetModConfigData("WORMHOLE_MARKS_DISABLE",name)
            if WORMHOLE_MARKS_DISABLE == true then
                local old_IsModEnabled = GLOBAL.KnownModIndex.IsModEnabled
                GLOBAL.KnownModIndex.IsModEnabled = function(self,mod_name,...)
                    -- Set that Wormhole Marks is active (even though it's not)
                    if mod_name == "workshop-362175979" then
                        return true
                    end
                    return GLOBAL.unpack({old_IsModEnabled(self,mod_name,...)})
                end
                break
            end
        end
    end
end

AddPrefabPostInit("world",function(inst)

    if not inst.ismastersim then
        return
    end

    inst:AddComponent("wormhole_icons_server")

end)


local function OnActivate(inst, doer)
    if doer:HasTag("player") then
        GLOBAL.ProfileStatsSet("wormhole_used", true)
        GLOBAL.AwardPlayerAchievement("wormhole_used", doer)

        local other = inst.components.teleporter.targetTeleporter
        if other ~= nil then
            GLOBAL.DeleteCloseEntsWithTag({"WORM_DANGER"}, other, 15)
        end

        if doer.components.talker ~= nil then
            doer.components.talker:ShutUp()
        end
        if doer.components.sanity ~= nil and not doer:HasTag("nowormholesanityloss") and not inst.disable_sanity_drain then
            doer.components.sanity:DoDelta(-TUNING.WORMHOLE_ICONS_SERVER.SANITY)
        end

        --Sounds are triggered in player's stategraph
    elseif inst.SoundEmitter ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve/common/teleportworm/swallow")
    end
end

local function OnRemoved(inst)
    if inst.components.teleporter.targetTeleporter ~= nil then
        RemoveWormhole(inst,inst.components.teleporter.targetTeleporter)
    end
end

local prefabs = {"wormhole","tentacle_pillar","tentacle_pillar_hole"}
for k,v in ipairs(GLOBAL.TUNING.WORMHOLE_ICONS_SERVER.CUSTOM_WORMHOLES) do
    table.insert(prefabs,v)
end

if GLOBAL.KnownModIndex:IsModEnabledAny("workshop-1467214795") then
    table.insert(prefabs,"bermudatriangle")
end

for k,v in ipairs(prefabs) do
    AddPrefabPostInit(v,function(inst)
        inst.wormholenumber = 0
        inst.net_wormholenumber = GLOBAL.net_float(inst.GUID,"wormhole_icons_server.net_wormholenumber","net_wormholenumber_dirty")
        inst.net_wormholenumber:set(0)
        if TUNING.WORMHOLE_ICONS_SERVER.RENAMING ~= 0 then
            inst.wormholename = ""
            inst.net_wormholename = GLOBAL.net_string(inst.GUID,"wormhole_icons_server.net_wormholename","net_wormholename_dirty")
        end
        inst:AddTag("wormhole")
        if not (v == "tentacle_pillar" or v == "tentacle_pillar_hole") then
            inst:AddTag("small_wormhole")
        end
        if not GLOBAL.TheWorld.ismastersim then
            return
        end

        --inst:ListenForEvent("workfinished", OnHammered)

        local old_onsave = inst.OnSave or function() end
        inst.OnSave = function(inst,data,...)
            if inst.net_wormholenumber ~= nil then
                if inst.net_wormholenumber:value() ~= 0 then
                    data.net_wormholenumber = inst.net_wormholenumber:value()
                end
            end
            if inst.net_wormholename ~= nil then
                if inst.net_wormholename:value() ~= "" then
                    data.net_wormholename = inst.net_wormholename:value()
                end
            end
            return GLOBAL.unpack({old_onsave(inst,data,...)})
        end

        local old_onload = inst.OnLoad or function() end
        inst.OnLoad = function(inst,data,...)
            if data ~= nil then
                if data.net_wormholenumber ~= nil then
                    if inst.net_wormholenumber ~= nil then
                        inst.net_wormholenumber:set(data.net_wormholenumber)
                    end
                end
                if data.net_wormholename ~= nil then
                    if inst.net_wormholename ~= nil then
                        inst.net_wormholename:set(data.net_wormholename)
                    end
                end
            end
            return GLOBAL.unpack({old_onload(inst,data,...)})
        end

        local old_activate = inst.components.teleporter.onActivate
        inst.components.teleporter.onActivate = function(inst,doer,...)
            GLOBAL.TheWorld:PushEvent("went_through_wormhole",{wormhole_entry = inst,wormhole_exit = inst.components.teleporter.targetTeleporter,doer = doer})
            local ret
            if inst.prefab == "wormhole" and TUNING.WORMHOLE_ICONS_SERVER.SANITY ~= 15 then
                ret = {OnActivate(inst,doer,...)}
            else
                ret = {old_activate(inst,doer,...)}
            end
            return GLOBAL.unpack(ret)
        end

        inst:ListenForEvent("onremove", OnRemoved)


        inst:DoTaskInTime(1,function()
            local is_in_list = false
            for k,v in ipairs(GLOBAL.TheWorld.components.wormhole_icons_server.wormholes) do
                if inst == v  then
                    is_in_list = true
                    break
                end
            end
            if is_in_list == false then
                table.insert(GLOBAL.TheWorld.components.wormhole_icons_server.wormholes,inst)
            end
        end)
    end)
end

modimport("wormhole_sinkhole_icons.lua")

