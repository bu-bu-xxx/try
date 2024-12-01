
local old_stroverridefn = ACTIONS.CASTAOE.stroverridefn
ACTIONS.CASTAOE.stroverridefn = function(act, ...)
	if act.invobject ~= nil and act.invobject.prefab == 'lol_wp_s7_doranshield' then
		return STRINGS.MOD_LOL_WP.ACTIONS.REPLACE_ACTION_SHIELD_BLOCK
	end
    if old_stroverridefn ~= nil then
        return old_stroverridefn(act, ...)
    end
    return
end