local AddUserCommand = AddUserCommand
GLOBAL.setfenv(1, GLOBAL)

PingMute = {}

local function GetPlayerUserid(num)
    local client_table = TheNet:GetClientTable() or {}
    if client_table[num] then
        return client_table[num].userid, client_table[num].name
    end
end

local ImageButton = require("widgets/imagebutton")
local PlayerStatusScreen = require("screens/playerstatusscreen")
local _DoInit = PlayerStatusScreen.DoInit
PlayerStatusScreen.DoInit = function(self, ClientObjs, ...)  -- 客机玩家在Tab单独屏蔽信号
    _DoInit(self, ClientObjs, ...)

    for i, playerListing in pairs(self.scroll_list.static_widgets) do
        if PingMute[playerListing.userid] then
            playerListing.mute_ping = playerListing:AddChild(ImageButton("images/lolpingtab.xml", "mute_ping_down.tex"))
        else
            playerListing.mute_ping = playerListing:AddChild(ImageButton("images/lolpingtab.xml", "mute_ping.tex", "mute_ping_focus.tex", "mute_ping_down.tex", "mute_ping_down.tex"))
        end

        playerListing.mute_ping:SetPosition(-60, 3, 0)

        playerListing.mute_ping:SetOnClick(function()
            if PingMute[playerListing.userid] then
                playerListing.mute_ping:SetTextures("images/lolpingtab.xml", "mute_ping.tex", "mute_ping_focus.tex", "mute_ping_down.tex", "mute_ping_down.tex")
                PingMute[playerListing.userid] = false
            else
                playerListing.mute_ping:SetTextures("images/lolpingtab.xml", "mute_ping_down.tex")
                PingMute[playerListing.userid] = true
            end

            playerListing.mute_ping:_RefreshImageState()
        end)

        if playerListing.userid == self.owner.userid then
            playerListing.mute_ping:Hide()
        end
    end
end


local mute_all = false
AddUserCommand("mute", {  -- 按Y指令
    prettyname = nil, --default to STRINGS.UI.BUILTINCOMMANDS.MUTE.PRETTYNAME
    desc = "输入/mute player_num 静音该玩家的信号\nplayer_num为按下Tab时玩家头像左侧的数字\n如果为all则禁言所有玩家", --default to STRINGS.UI.BUILTINCOMMANDS.MUTE.DESC
    permission = COMMAND_PERMISSION.USER,
    slash = true,
    usermenu = false,
    servermenu = false,
    params = {"player_num"},
    vote = false,
    localfn = function(params, caller)
        local id, name = GetPlayerUserid(tonumber(params.player_num))
        if params.player_num == "all" then
            mute_all = not mute_all
            for userid, muted in pairs(PingMute) do
                PingMute[userid] = mute_all
            end

            local message =  mute_all and "所有的用户的标记已被静音" or "所有的用户的标记不再被静音"
            Say(message)
        elseif id and id ~= caller.userid then
            PingMute[id] = not PingMute[id]
            local message = PingMute[id] and "用户的标记已被静音" or "用户的标记不再被静音"
            Say(message .. "(" .. name .. ")")
        end
    end,
})

scheduler:ExecutePeriodic(1, function()
    if not ThePlayer then
        return
    end

    local client_table = TheNet:GetClientTable() or {}
    for i, client in ipairs(client_table) do
        if client.userid ~= ThePlayer.userid then
            PingMute[client.userid] = mute_all or PingMute[client.userid]
        end
    end
end)