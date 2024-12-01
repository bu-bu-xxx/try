GLOBAL.setfenv(1, GLOBAL)

function MergeTbale(target, new, soft)
	if not target then target = {} end
	for k,v in pairs(new) do
		if type(v) == "table" then
			target[k] = type(target[k]) == "table" and target[k] or {}
			MergeTbale(target[k], v)
		else
			if target[k] then
				if not soft then
					target[k] = v
				end
			else
				target[k] = v
			end
		end
	end
	return target
end

function Say(string)
	if ThePlayer and ThePlayer.components.talker then
        ThePlayer.components.talker:Say(string)
    end
end