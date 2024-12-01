local Wormhole_Icons_Server = Class(function(self, inst)

	self.inst = inst
	self.wormholes = {}
	self.wormhole_icons = {}
	self.wormhole_names = {}
	self.players = {}

	self.sinkholes = {}
	self.sinkhole_icons = {}
	self.sinkhole_names = {}
	self.players_sinkhole = {}

	local _AddWormholePositionsToClient = function(player)
		self.inst:DoTaskInTime(1,function(world)
			self:AddWormholePositionsToClient(player)
		end)
	end
	local _AddSinkholePositionsToClient = function() end
	if TUNING.WORMHOLE_ICONS_SERVER.SINKHOLES then
		_AddSinkholePositionsToClient = function(player)
			self.inst:DoTaskInTime(1,function(world)
				self:AddSinkholePositionsToClient(player)
			end)
		end
	end
	self._activateplayer = function(inst,player) 
        if player then
            _AddWormholePositionsToClient(player) 
            _AddSinkholePositionsToClient(player)
        end
    end
    self.inst:ListenForEvent("ms_playerjoined",self._activateplayer)

end)


function Wormhole_Icons_Server:AddWormholePositionsToClient(player)
	--print("Wormhole_Icons_Server:AddWormholePositionsToClient",player)
	--dumptable(self.wormhole_icons)
	--dumptable(self.wormhole_names)
	local userid = player and player.userid or nil
	local forall = TUNING.WORMHOLE_ICONS_SERVER.FOR_ALL
	for k,v in pairs(self.wormhole_icons) do
		if v ~= nil then
			local success = true
			if forall ~= 0 then
				success = false
				if player and self.players[player.userid] then
					for kk,vv in pairs(self.players[player.userid]) do
						if vv.x == v.x and vv.y == v.y and vv.z == v.z then
							success = true
						end
					end
				end
			end
			if success == true then
				SendModRPCToClient(GetClientModRPC("Wormhole_Icons_Server", "AddWormholePositionsToClient"),userid,k,v.x,v.y,v.z,nil,self.wormhole_names[k])
			end
		end
	end
end

function Wormhole_Icons_Server:AddSinkholePositionsToClient(player)
	--print("Wormhole_Icons_Server:AddSinkholePositionsToClient",player)
	--dumptable(self.sinkhole_icons)
	--dumptable(self.sinkhole_names)
	local userid = player and player.userid or nil
	local forall = TUNING.WORMHOLE_ICONS_SERVER.FOR_ALL
	for k,v in pairs(self.sinkhole_icons) do
		if v ~= nil then
			local success = true
			if forall ~= 0 then
				success = false
				if player and self.players_sinkhole[player.userid] then
					for kk,vv in pairs(self.players_sinkhole[player.userid]) do
						if vv.x == v.x and vv.y == v.y and vv.z == v.z then
							success = true
						end
					end
				end
			end
			if success == true then
				--print("sending rpc",userid,k,v.x,v.y,v.z,self.sinkhole_names[k])
				SendModRPCToClient(GetClientModRPC("Wormhole_Icons_Server", "AddSinkholePositionsToClient"),userid,k,v.x,v.y,v.z,nil,self.sinkhole_names[k])
			end
		end
	end
end

function Wormhole_Icons_Server:OnLoad(data)
	--print("Wormhole_Icons_Server:OnLoad")
	if data then
		if data.wormhole_icons then
			self.wormhole_icons = data.wormhole_icons
		end
		if data.wormhole_names then
			self.wormhole_names = data.wormhole_names
		end
		if data.sinkhole_icons then
			self.sinkhole_icons = data.sinkhole_icons
		end
		if data.sinkhole_names then
			self.sinkhole_names = data.sinkhole_names
		end
		if data.players then
			self.players = data.players
		end
		if data.players_sinkhole then
			self.players_sinkhole = data.players_sinkhole
		end
	end
	--dumptable(data)
end

function Wormhole_Icons_Server:OnSave()
	--print("Wormhole_Icons_Server:OnSave")
	local data = {}
	data.wormhole_icons = self.wormhole_icons
	data.wormhole_names = self.wormhole_names
	data.sinkhole_icons = self.sinkhole_icons
	data.sinkhole_names = self.sinkhole_names
	data.players = self.players
	data.players_sinkhole = self.players_sinkhole
	--dumptable(data)
	return data
end

return Wormhole_Icons_Server