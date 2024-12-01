local AddClientModRPCHandler = AddClientModRPCHandler
local AddModRPCHandler = AddModRPCHandler
GLOBAL.setfenv(1, GLOBAL)

AddModRPCHandler("LoL Ping", "Ping", function(player, x, y, z, choose, pingerid)
    for _, _player in ipairs(AllPlayers) do
        SendModRPCToClient(CLIENT_MOD_RPC["LoL Ping"]["PingClient"], _player.userid, x, y, z, choose, pingerid)
    end
end)

AddClientModRPCHandler("LoL Ping", "PingClient", function(x, y, z, choose, pingerid)
    if PingMute[pingerid] or not ThePlayer then
        return
    end

    ThePlayer.HUD.lolping:PingAtWorld(x, y, z, choose)
end)