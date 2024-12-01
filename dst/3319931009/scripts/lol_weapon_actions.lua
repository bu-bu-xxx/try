local function spawn_riftmaker(doer,invobject, prefab)
    local item = SpawnPrefab(prefab)
    if item then
        if item.components.finiteuses and invobject.components.finiteuses then 
            item.components.finiteuses:SetUses(invobject.components.finiteuses.current)
            if item.components.finiteuses.current == 0 then 
                item.components.equippable.restrictedtag = "别看了我就是不让你装备的"
            end
        end
        doer.components.inventory:GiveItem(item)
        return true
    end
    return false
end

local RIFTMAKER_CHANGEFORM = Action()
RIFTMAKER_CHANGEFORM.id = "RIFTMAKER_CHANGEFORM"
RIFTMAKER_CHANGEFORM.fn = function(act)
    local doer = act.doer
    local invobject = act.invobject
    local form = invobject.components.riftmaker.form

    invobject:Remove()
    if form == "weapon" then
        return spawn_riftmaker(doer,invobject, "riftmaker_amulet")
    end
    return spawn_riftmaker(doer,invobject, "riftmaker_weapon")
end
AddAction(RIFTMAKER_CHANGEFORM)

STRINGS.ACTIONS.RIFTMAKER_CHANGEFORM = "改变形态"

-------------------------------------------------------------------

AddComponentAction("INVENTORY", "riftmaker", function(inst, doer, actions, right)
    if inst.prefab == "riftmaker_amulet" and 
        ((inst.components.equippable and inst.components.equippable:IsEquipped()) or 
        (inst.replica.equippable and inst.replica.equippable:IsEquipped())) then 
        table.insert(actions, ACTIONS.RIFTMAKER_CHANGEFORM)
    elseif inst.prefab == "riftmaker_weapon" and 
        ((inst.components.equippable and inst.components.equippable:IsEquipped()) or 
        (inst.replica.equippable and inst.replica.equippable:IsEquipped())) then 
        table.insert(actions, ACTIONS.RIFTMAKER_CHANGEFORM)
    end
end)

-------------------------------------------------------------------

local riftmaker_actionhanler = ActionHandler(ACTIONS.RIFTMAKER_CHANGEFORM, function(inst, action)
    return "give"
end)
AddStategraphActionHandler("wilson", riftmaker_actionhanler) -- 主机
AddStategraphActionHandler("wilson_client", riftmaker_actionhanler) -- 客机

AddPrefabPostInit("horrorfuel",function(inst)
    inst:AddComponent("lol_useitem")
end)

AddPrefabPostInit("nightmarefuel",function(inst)
    inst:AddComponent("lol_useitem")
end)

local function removeItem(item,num)
	if item.components.stackable then
		item.components.stackable:Get(num):Remove()
	else
		item:Remove()
	end
end

local LOL_MEND = Action({priority = 5, mount_valid = false})
LOL_MEND.id = 'LOL_MEND'
LOL_MEND.str = "添加燃料"
LOL_MEND.fn = function(act)
    if act.invobject.prefab == "horrorfuel" then 
        removeItem(act.invobject, 1)
        act.target.components.finiteuses:Repair(200)
        act.target.components.equippable.restrictedtag = nil
        return true
    end
    if act.invobject.prefab == "nightmarefuel" then 
        removeItem(act.invobject, 1)
        act.target.components.finiteuses:Repair(40)
        act.target.components.equippable.restrictedtag = nil
        return true
    end
    return false
end
AddAction(LOL_MEND)

AddComponentAction(
    'USEITEM',
    'lol_useitem',
    function(inst, doer, target, actions, right)
        if doer:HasTag("player") and (target.prefab == 'riftmaker_weapon' or target.prefab == 'riftmaker_amulet')  then
            table.insert(actions, GLOBAL.ACTIONS.LOL_MEND)
        end
    end
)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(LOL_MEND, 'give'))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(LOL_MEND, 'give'))
